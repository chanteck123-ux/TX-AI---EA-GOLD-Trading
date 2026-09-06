"""Evidence-oriented analysis. Unknown values stay unknown; no trade simulation."""
from __future__ import annotations

from collections import Counter, defaultdict
from datetime import datetime, timedelta
import bisect
import math
import statistics

STRATEGIES = ("Scalping", "Intraday", "Swing", "Combined")


def number(value):
    try:
        value = float(value)
        return value if math.isfinite(value) else None
    except (ValueError, TypeError):
        return None


def moment(value):
    if not value:
        return None
    if isinstance(value, datetime):
        return value
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        for fmt in ("%Y.%m.%d %H:%M:%S", "%Y.%m.%d", "%Y-%m-%d"):
            try:
                return datetime.strptime(str(value), fmt)
            except ValueError:
                pass
    return None


def strategy_name(value):
    text = str(value or "").lower()
    for name in STRATEGIES:
        if name.lower() in text:
            return name
    return "Unassigned"


def issue(issues, code, message, source="", severity="warning"):
    item = {"severity": severity, "code": code, "message": message, "source": source}
    if item not in issues:
        issues.append(item)


def _sum_known(records, key):
    values = [number(r.get(key)) for r in records]
    return round(sum(values), 8) if values and all(x is not None for x in values) else None


def complete_positions(dataset):
    """Prefer explicit complete-position audit. Deal reconstruction requires real IDs."""
    issues = dataset["issues"]
    explicit = []
    by_id = defaultdict(list)
    for index, raw in enumerate(dataset.get("trades", [])):
        t = dict(raw)
        t["strategy"] = strategy_name(t.get("strategy"))
        if number(t.get("net_profit")) is None:
            if all(number(t.get(k)) is not None for k in ("gross_profit", "commission", "swap", "fee")):
                t["net_profit"] = sum(float(t[k]) for k in ("gross_profit", "commission", "swap", "fee"))
            else:
                issue(issues, "NET_PROFIT_UNKNOWN", "缺净利润或完整费用，记录不纳入净绩效。", t.get("_source", ""))
                continue
        opened, closed = moment(t.get("time_open")), moment(t.get("time_close"))
        if not opened or not closed:
            issue(issues, "TRADE_TIME_MISSING", "开平仓时间缺失，不能确认为完整交易。", t.get("_source", ""))
            continue
        try:
            duration = (closed - opened).total_seconds()
        except TypeError:
            issue(issues, "MIXED_TIMEZONE", "开平仓时区不一致，隔离记录。", t.get("_source", ""))
            continue
        if duration < 0 or t.get("is_complete") is False:
            issue(issues, "TRADE_NOT_COMPLETE", "负持仓时间或未完整平仓，不纳入完整交易。", t.get("_source", ""))
            continue
        t["holding_minutes"] = duration / 60
        t["net_profit"] = float(t["net_profit"])
        t["position_id"] = str(t.get("position_id") or t.get("trade_id") or "")
        if not t["position_id"]:
            issue(issues, "POSITION_ID_MISSING", "交易缺唯一持仓ID，不能确认分批去重；该行隔离。", t.get("_source", ""))
            continue
        by_id[t["position_id"]].append(t)
    for pid, rows in by_id.items():
        if len(rows) != 1:
            issue(issues, "AMBIGUOUS_POSITION_ROWS", f"持仓{pid}有{len(rows)}行完整仓记录，未猜测分批或累积利润。")
        else:
            explicit.append(rows[0])
    if explicit:
        if dataset.get("deals"):
            issue(issues, "AUDIT_PRIMARY_DEALS_AUXILIARY", "使用完整持仓审计计算绩效；成交明细作为辅助，不重复相加。", severity="info")
        return explicit
    groups = defaultdict(list)
    for row in dataset.get("deals", []):
        pid = row.get("position_id")
        if not pid:
            issue(issues, "DEAL_POSITION_ID_MISSING", "原生成交缺PositionID，无法可靠重建对冲/分批完整仓位。", row.get("_source", ""))
            continue
        groups[str(pid)].append(row)
    complete = []
    for pid, rows in groups.items():
        ownership = {(r.get("symbol"), str(r.get("magic", "")), strategy_name(r.get("strategy"))) for r in rows}
        if len(ownership) != 1:
            issue(issues, "MIXED_POSITION_OWNERSHIP", f"持仓{pid}的品种/Magic/策略归属冲突，已隔离。")
            continue
        entries = [r for r in rows if str(r.get("entry", "")).lower() in ("in", "0")]
        exits = [r for r in rows if str(r.get("entry", "")).lower() in ("out", "out_by", "1", "3")]
        if len(entries) + len(exits) != len(rows):
            issue(issues, "REVERSAL_UNSUPPORTED", f"持仓{pid}含INOUT/未知成交类型，V1不猜测反转分仓。")
            continue
        if any(number(r.get("volume")) is None or number(r.get("volume")) <= 0 for r in rows):
            issue(issues, "INVALID_DEAL_VOLUME", f"持仓{pid}含不合法成交量。")
            continue
        vin = sum(float(r["volume"]) for r in entries)
        vout = sum(float(r["volume"]) for r in exits)
        if not entries or not exits or abs(vin-vout) > 1e-8:
            issue(issues, "OPEN_OR_INCOMPLETE_POSITION", f"持仓{pid}入量{vin:g}/出量{vout:g}，未计为完整交易。")
            continue
        times = [moment(r.get("time")) for r in rows]
        if any(t is None for t in times):
            issue(issues, "DEAL_TIME_MISSING", f"持仓{pid}缺成交时间。")
            continue
        try:
            ordered = sorted(rows, key=lambda r: moment(r["time"]))
        except TypeError:
            issue(issues, "MIXED_TIMEZONE", f"持仓{pid}时间戳时区不一致。")
            continue
        outstanding = 0.0
        valid = True
        for r in ordered:
            outstanding += float(r["volume"]) * (1 if r in entries else -1)
            if outstanding < -1e-8:
                valid = False
        entry_sides = {str(r.get("side") or "").upper() for r in entries}
        exit_sides = {str(r.get("side") or "").upper() for r in exits}
        opposite = {"SELL"} if entry_sides == {"BUY"} else {"BUY"} if entry_sides == {"SELL"} else set()
        if not valid or not opposite or exit_sides != opposite:
            issue(issues, "DEAL_LIFECYCLE_INVALID", f"持仓{pid}开平仓次序/方向矛盾，已隔离。")
            continue
        sums = {k: _sum_known(rows, k) for k in ("profit", "commission", "swap", "fee")}
        if any(v is None for v in sums.values()):
            issue(issues, "DEAL_COSTS_UNKNOWN", f"持仓{pid}缺利润/费用字段，不能构造成本后绩效。")
            continue
        first, last = entries[0], ordered[-1]
        t = {"position_id": pid, "strategy": strategy_name(first.get("strategy")), "symbol": first.get("symbol"),
             "side": first.get("side"), "volume": vin, "time_open": min(r["time"] for r in entries),
             "time_close": last["time"], "entry_price": None, "exit_price": None,
             "gross_profit": sums.pop("profit"), **sums, "deal_count": len(rows), "exit_deal_count": len(exits),
             "_source": ";".join(sorted({r.get("_source", "") for r in rows})), "_row": first.get("_row")}
        t["net_profit"] = round(t["gross_profit"] + t["commission"] + t["swap"] + t["fee"], 8)
        for key, group in (("entry_price", entries), ("exit_price", exits)):
            if all(number(r.get("price")) is not None for r in group):
                t[key] = sum(float(r["price"])*float(r["volume"]) for r in group)/vin
        t["holding_minutes"] = (moment(t["time_close"])-moment(t["time_open"])).total_seconds()/60
        complete.append(t)
    return complete


def drawdown(values):
    peak = None
    max_money = max_pct = 0.0
    pct_at_money = 0.0
    for value in values:
        value = number(value)
        if value is None:
            continue
        peak = value if peak is None else max(peak, value)
        loss = peak-value
        pct = 100*loss/peak if peak > 0 else None
        if loss > max_money:
            max_money, pct_at_money = loss, pct
        if pct is not None:
            max_pct = max(max_pct, pct)
    if peak is None:
        return {"money": None, "pct": None, "pct_at_max_money": None}
    return {"money": round(max_money, 8), "pct": max_pct, "pct_at_max_money": pct_at_money}


def metrics_for(rows):
    values = [float(r["net_profit"]) for r in rows]
    wins = [v for v in values if v > 0]
    losses = [v for v in values if v < 0]
    streak = longest = 0
    for r in sorted(rows, key=lambda r: r.get("time_close") or ""):
        streak = streak+1 if r["net_profit"] < 0 else 0
        longest = max(longest, streak)
    net = sum(values)
    return {"complete_trades": len(values), "net_profit": round(net, 8), "wins": len(wins), "losses": len(losses),
            "breakeven_trades": len(values)-len(wins)-len(losses),
            "win_rate": 100*len(wins)/len(values) if values else None,
            "profit_factor": sum(wins)/abs(sum(losses)) if losses else None,
            "profit_factor_status": "finite" if losses else "no_losses_undefined" if wins else "no_profit_or_loss",
            "avg_win": statistics.mean(wins) if wins else None, "avg_loss": statistics.mean(losses) if losses else None,
            "realized_reward_risk": statistics.mean(wins)/abs(statistics.mean(losses)) if wins and losses else None,
            "max_consecutive_losses": longest if values else None, "expected_payoff": net/len(values) if values else None}


def _bar_minutes(value):
    text = str(value or "").upper().replace("PERIOD_", "")
    try:
        return int(text[1:]) * {"M": 1, "H": 60, "D": 1440}[text[0]]
    except (KeyError, ValueError, IndexError):
        return None


def enrich_trades(trades, dataset):
    """Regime tags are closed-bar research proxies, never claimed EA indicators."""
    issues = dataset["issues"]
    bars = []
    for bar in dataset.get("bars", []):
        b = dict(bar)
        start = moment(b.get("time"))
        minutes = _bar_minutes(b.get("timeframe") or dataset["manifest"].get("bar_timeframe"))
        available = moment(b.get("available_at") or b.get("time_close"))
        if available is not None and start and minutes:
            try:
                premature = available < start + timedelta(minutes=minutes)
            except TypeError:
                premature = True
            if premature:
                issue(issues, "BAR_AVAILABLE_BEFORE_CLOSE", "K线声明可用时间早于收盘或时区冲突，已隔离以避免未来泄漏。", b.get("_source", ""))
                continue
        if available is None and start and minutes:
            available = start + timedelta(minutes=minutes)
        if available is None:
            issue(issues, "BAR_AVAILABILITY_UNKNOWN", "行情K线缺周期/可用时点，未用于进场状态识别。", b.get("_source", ""))
            continue
        if not all(number(b.get(k)) is not None for k in ("high", "low", "close")):
            continue
        b["_available"] = available
        bars.append(b)
    try:
        bars.sort(key=lambda b: b["_available"])
    except TypeError:
        bars = []
        issue(issues, "MIXED_TIMEZONE", "行情时区混用，暂停行情状态联结。")
    # Never combine heterogeneous intervals into a fictitious indicator.
    periods = {b.get("timeframe") or dataset["manifest"].get("bar_timeframe") for b in bars}
    if len(periods) > 1:
        issue(issues, "MIXED_BAR_TIMEFRAMES", "一批多种K线周期，V1不混算代理ATR/趋势，请分别导入。")
        bars = []
    available_times = [b["_available"] for b in bars]
    for t in trades:
        opened = moment(t.get("time_open"))
        t["hour"] = opened.hour if opened else None
        t["session"] = f"{opened.hour//6*6:02d}–{opened.hour//6*6+5:02d}时" if opened else "未知"
        duration = t.get("holding_minutes", 0)
        t["holding_bucket"] = "<15分钟" if duration < 15 else "15–60分钟" if duration < 60 else "1–24小时" if duration < 1440 else "≥24小时"
        t["market_regime"] = "UNKNOWN_NO_CAUSAL_BARS"
        t["regime_available_at"] = None
        if not bars or not opened:
            continue
        try:
            index = bisect.bisect_right(available_times, opened)
        except TypeError:
            issue(issues, "TIMEZONE_JOIN_BLOCKED", "行情与交易时区不能可靠对齐，未贴行情状态标签。")
            continue
        if index < 21:
            continue
        window = bars[index-21:index]
        tr = [max(float(b["high"])-float(b["low"]), abs(float(b["high"])-float(prev["close"])), abs(float(b["low"])-float(prev["close"]))) for prev,b in zip(window,window[1:])]
        atr = sum(tr[-14:])/14
        move = float(window[-1]["close"])-float(window[0]["close"])
        t["market_regime"] = "上涨代理" if move > 2*atr else "下跌代理" if move < -2*atr else "震荡代理"
        t["regime_available_at"] = window[-1]["_available"].isoformat()
        t["proxy_atr_sma_tr14"] = atr
        t["regime_definition"] = "21根已收盘K线净位移与2×SMA(TR,14)；研究代理，不等于EA指标"
    return trades


def coverage_rows(dataset):
    manifest, issues = dataset["manifest"], dataset["issues"]
    result = []
    for kind, key in (("ticks", "time"), ("bars", "time"), ("equity", "time"), ("trades", "time_open"), ("events", "time")):
        rows = dataset.get(kind, [])
        timestamps = sorted(str(r[key]) for r in rows if r.get(key))
        unique_days = len({t[:10] for t in timestamps})
        result.append({"kind": kind, "rows": len(rows), "start": timestamps[0] if timestamps else None,
                       "end": timestamps[-1] if timestamps else None, "observed_days": unique_days,
                       "status": "OBSERVED_ROWS_ONLY_NOT_CONTINUOUS_COVERAGE" if timestamps else "MISSING"})
        if kind in ("ticks", "bars") and timestamps:
            dates = sorted({t[:10] for t in timestamps})
            gaps = []
            for left,right in zip(dates,dates[1:]):
                try:
                    d = (datetime.fromisoformat(right)-datetime.fromisoformat(left)).days
                except ValueError:
                    continue
                if d > 1:
                    gaps.append({"from": left, "to": right, "days": d-1})
            result[-1]["calendar_gaps"] = gaps
            result[-1]["gap_note"] = "包含周末/休市，缺交易日历时不能判定每个空档均丢失数据。"
    tick_data = result[0]
    if not tick_data["rows"]:
        issue(issues, "RAW_TICK_COVERAGE_UNVERIFIED", "没有原始FxPro Tick，不能核实从2024-03开始的真实Tick覆盖；报告质量百分比不替代原始档案。")
    elif manifest.get("data_type") == "synthetic":
        tick_data["status"] = "SYNTHETIC_NOT_BROKER_COVERAGE"
    else:
        tick_data["status"] = "OBSERVED_TICKS_ORIGIN_REQUIRES_SOURCE_EVIDENCE"
    return result


def funnel_rows(dataset):
    result = []
    # Cumulative snapshots use the latest row per strategy and file, not sum snapshots.
    latest = {}
    for row in dataset.get("funnel", []):
        key = strategy_name(row.get("strategy") or row.get("SOP"))
        previous = latest.get(key)
        if previous is None or str(row.get("time") or "") > str(previous.get("time") or ""):
            latest[key] = row
        elif str(row.get("time") or "") == str(previous.get("time") or "") and row.get("counts") != previous.get("counts"):
            issue(dataset["issues"], "FUNNEL_SNAPSHOT_CONFLICT", f"{key}同一时点累计漏斗内容冲突，请核对输入来源。")
    for strategy, row in latest.items():
        source = row.get("_source")
        counts = row.get("counts", {})
        for stage,count in counts.items():
            if number(count) is not None:
                result.append({"strategy": strategy, "stage": stage, "reason": stage if "reject" in stage.lower() else "",
                               "count": number(count), "unit": "原始累计计数；各门控可能重叠", "source": source})
    events = Counter()
    for row in dataset.get("events", []):
        events[(strategy_name(row.get("strategy")), str(row.get("stage") or "DECISION_RECORD"), str(row.get("reason") or "UNKNOWN"))] += 1
    for (strategy,stage,reason), count in sorted(events.items()):
        result.append({"strategy": strategy, "stage": stage, "reason": reason, "count": count,
                       "unit": "事件记录数；非独立候选转化率"})
    return result


def analyze(dataset):
    manifest = dataset["manifest"]
    dataset.setdefault("issues", [])
    run_ids = set()
    for kind in ("trades", "deals", "events", "funnel", "equity", "bars", "ticks"):
        for row in dataset.get(kind, []):
            raw = row.get("raw", row.get("_raw", {}))
            value = row.get("run_id") or row.get("run") or row.get("Run") or raw.get("Run")
            if value:
                run_ids.add(str(value))
    expected_run = manifest.get("source_run_id") or manifest.get("run_id")
    if len(run_ids) > 1 or (run_ids and expected_run and run_ids != {str(expected_run)}):
        raise ValueError("RUN_ID_MISMATCH：同一分析只能导入同一次运行，不能将独立策略结果相加冒充组合。")
    trades = enrich_trades(complete_positions(dataset), dataset)
    # Repeated complete trades from separate runs must not be pooled by the caller.
    trades.sort(key=lambda r: r.get("time_close") or "")
    native = dataset.get("reports", [])
    metrics, curves, breakdowns, findings = [], {}, [], []
    capital = number(manifest.get("initial_capital"))
    if not capital or capital <= 0:
        capital = None
        issue(dataset["issues"], "CAPITAL_UNKNOWN", "初始资金缺失/非正，不计算收益率或虚构余额起点。")
    for strategy in STRATEGIES:
        group = trades if strategy == "Combined" else [r for r in trades if r["strategy"] == strategy]
        metric = {"strategy": strategy, **metrics_for(group), "metric_basis": "完整持仓净损益", "status": "待验证基准"}
        has_complete_evidence = bool(trades)
        if not group and not has_complete_evidence:
            metric.update({k: None for k in ("complete_trades", "net_profit", "wins", "losses", "breakeven_trades", "max_consecutive_losses")})
            metric["status"] = "缺完整持仓证据"
        metric["return_pct"] = 100*metric["net_profit"]/capital if capital and metric["net_profit"] is not None else None
        metric["commission"] = _sum_known(group, "commission")
        metric["swap"] = _sum_known(group, "swap")
        metric["fee"] = _sum_known(group, "fee")
        metric["spread_money"] = _sum_known(group, "spread_money")
        metric["slippage_money"] = _sum_known(group, "slippage_money")
        spread = [number(t.get("spread_points")) for t in group if number(t.get("spread_points")) is not None]
        metric["avg_spread_points"] = statistics.mean(spread) if spread else None
        metric["spread_points_observations"] = len(spread)
        metric["cost_note"] = "费用分项缺失保持未知；净值成交不得再次扣点差/滑点。"
        curve, balance = [], capital
        if balance is not None and has_complete_evidence:
            curve.append({"time": manifest.get("test", {}).get("start") or "初始", "balance": balance, "equity": None})
            for r in group:
                balance += r["net_profit"]
                curve.append({"time": r["time_close"], "balance": round(balance, 8), "equity": None})
        dd = drawdown([r["balance"] for r in curve])
        metric.update(balance_dd_money=dd["money"], balance_dd_pct=dd["pct"], balance_dd_pct_at_max_money=dd["pct_at_max_money"],
                      balance_dd_source="完整仓平仓时点贡献曲线；不含逐成交费用时序及外部现金流",
                      equity_dd_money=None, equity_dd_pct=None, equity_dd_source="MISSING")
        observations = [r for r in dataset.get("equity", []) if strategy_name(r.get("strategy") or "Combined") == strategy]
        if observations:
            observations.sort(key=lambda r: str(r.get("time") or ""))
            eqdd = drawdown([r.get("equity") for r in observations])
            if eqdd["money"] is not None:
                metric.update(equity_dd_money=eqdd["money"], equity_dd_pct=eqdd["pct"], equity_dd_source="输入净值采样；采样间风险不可见")
            # Display both real series; never fill an absent equity with balance.
            curves[strategy] = [{"time": r.get("time"), "balance": r.get("balance"), "equity": r.get("equity")} for r in observations]
        else:
            curves[strategy] = curve
        applicable = strategy == str(manifest.get("strategy_scope", "Combined"))
        if applicable:
            if dataset.get("deals"):
                for cost in ("commission", "swap", "fee"):
                    metric["observed_deals_"+cost] = _sum_known(dataset["deals"], cost)
                metric["observed_deals_count"] = len(dataset["deals"])
                metric["observed_deals_cost_note"] = "该批已提供成交的费用合计；无逐持仓可靠连接时不分摊给策略，不重复扣净利润。"
            for report in native:
                summary = report.get("summary", {})
                for key,value in summary.items():
                    metric["native_"+key] = value
                if not group and summary:
                    metric["metric_basis"] = "只有原生报告摘要；完整持仓未重建"
                    metric["complete_trades"] = None
                    curves[strategy] = []
                    for key in ("net_profit", "win_rate", "profit_factor"):
                        metric[key] = summary.get(key)
                    metric["return_pct"] = 100*number(metric["net_profit"])/capital if capital and number(metric.get("net_profit")) is not None else None
                if number(summary.get("equity_drawdown_money")) is not None:
                    metric["equity_dd_money"] = summary["equity_drawdown_money"]
                    metric["equity_dd_pct"] = summary.get("equity_drawdown_relative_pct", summary.get("equity_drawdown_pct"))
                    metric["equity_dd_source"] = "MT5原生报告摘要；无时序不生成净值曲线"
                if number(summary.get("balance_drawdown_money")) is not None:
                    metric["reconstructed_balance_dd_money"] = metric["balance_dd_money"]
                    metric["balance_dd_money"] = summary["balance_drawdown_money"]
                    metric["balance_dd_pct"] = summary.get("balance_drawdown_relative_pct", summary.get("balance_drawdown_pct"))
                    metric["balance_dd_source"] = "MT5原生报告摘要"
                if group and number(summary.get("net_profit")) is not None and abs(summary["net_profit"]-metric["net_profit"]) > .011:
                    issue(dataset["issues"], "NATIVE_NET_MISMATCH", "完整仓净利润与原生摘要不一致，检查费用、遗漏和测试身份。", report.get("_source", ""))
                if group and number(summary.get("profit_factor")) is not None and metric["profit_factor"] is not None and abs(summary["profit_factor"]-metric["profit_factor"]) > .011:
                    issue(dataset["issues"], "NATIVE_PF_BASIS_DIFFERENCE", "原生PF与完整仓成本后PF有差异；保留两种，不覆盖。", report.get("_source", ""), "info")
        for denom,key in (("balance_dd_money", "balance_recovery"), ("equity_dd_money", "equity_recovery")):
            value, net = number(metric.get(denom)), number(metric.get("net_profit"))
            metric[key] = net/value if value and value > 0 and net is not None else None
        metrics.append(metric)
        for dimension in ("side", "hour", "session", "holding_bucket", "market_regime"):
            subgroups = defaultdict(list)
            for t in group:
                subgroups[str(t.get(dimension) if t.get(dimension) is not None else "未知")].append(t)
            for value,rows in sorted(subgroups.items()):
                breakdowns.append({"strategy": strategy, "dimension": dimension, "value": value, **metrics_for(rows)})
    for metric in metrics:
        if metric["equity_dd_source"] == "MISSING":
            findings.append({"kind": "missing", "severity": "warning", "category": "equity", "strategy": metric["strategy"],
                             "message": "缺少该策略净值时序或明确归属的原生净值DD；不能用余额DD替代。", "evidence": "equity_dd_source=MISSING"})
        native_recovery = number(metric.get("native_recovery_factor"))
        balance_recovery = number(metric.get("balance_recovery"))
        if native_recovery is not None and balance_recovery is not None and abs(native_recovery-balance_recovery) > max(.02, abs(balance_recovery)*.02):
            issue(dataset["issues"], "NATIVE_RECOVERY_DEFINITION_MISMATCH", f"{metric['strategy']}原生Recovery与余额分母重算不同；保留原值、余额比、净值比分列。")
    risk_rows = [t for t in trades if number(t.get("risk_pct")) is not None and float(t["risk_pct"]) > float(manifest.get("risk", {}).get("single_pct", 1)) + 1e-8]
    if risk_rows:
        findings.append({"kind": "confirmed", "severity": "high", "category": "risk", "strategy": "Combined",
                         "message": f"{len(risk_rows)}笔审计记录初始风险超过本次预算；不代表已核实最坏实际成交损失。",
                         "evidence": ",".join(t["position_id"] for t in risk_rows)})
    for t in trades:
        raw = t.get("raw", t.get("_raw", {}))
        chase = t.get("chase_entry", raw.get("ChaseEntry"))
        label = t.get("loss_classification", raw.get("LossClassification"))
        if str(chase).upper() in ("YES", "TRUE", "1") or (label and label not in ("PROFIT", "UNKNOWN")):
            findings.append({"kind": "hypothesis", "severity": "info", "category": "entry", "strategy": t["strategy"],
                             "message": "源码启发式入场标签，不能据此确认亏损因果或删除过滤。", "evidence": f"position={t['position_id']};ChaseEntry={chase};LossClassification={label}"})
        entry, sl = number(t.get("entry_price")), number(t.get("initial_sl"))
        atr = number(t.get("proxy_atr_sma_tr14") or t.get("atr") or raw.get("ATR"))
        if entry is not None and sl is not None and atr and atr > 0:
            t["sl_atr_ratio"] = abs(entry-sl)/atr
            if t["sl_atr_ratio"] < .5 or t["sl_atr_ratio"] > 3:
                findings.append({"kind": "hypothesis", "severity": "info", "category": "stop_distance", "strategy": t["strategy"],
                                 "message": "止损/ATR处于研究阈值外；需结合区域结构验证过近或过远，不自动改SL。", "evidence": f"position={t['position_id']};ratio={t['sl_atr_ratio']:.3f}"})
        mfe = number(t.get("mfe_money"))
        if mfe is not None:
            t["mfe_minus_net_profit"] = mfe-t["net_profit"]
            t["mfe_note"] = "毛报价MFE与净收益差额，非已证实可锁定利润"
            if mfe > 0 and t["net_profit"] < .5*mfe:
                findings.append({"kind": "hypothesis", "severity": "info", "category": "profit_protection", "strategy": t["strategy"],
                                 "message": "观测浮盈明显高于最终净损益；可能有回吐，也含费用与采样口径差异。", "evidence": f"position={t['position_id']};MFE={mfe};net={t['net_profit']}"})
    setups = defaultdict(list)
    for t in trades:
        if t.get("setup_id"):
            setups[(t["strategy"], t["setup_id"])].append(t)
    for (strategy,setup), rows in setups.items():
        if len(rows) > 1:
            findings.append({"kind": "confirmed", "severity": "warning", "category": "duplicate_entry", "strategy": strategy,
                             "message": "同一Setup标识关联多个完整仓，需核对其生命周期与是否重复下单。", "evidence": f"setup={setup};positions={','.join(r['position_id'] for r in rows)}"})
    funnel = funnel_rows(dataset)
    if not funnel:
        findings.append({"kind": "missing", "severity": "high", "category": "no_trade", "strategy": "Combined",
                         "message": "缺候选/门控日志，成交记录无法解释为什么未开单。", "evidence": "events=0;funnel=0"})
    else:
        for f in funnel:
            if f["count"] > 0 and any(s in (f["stage"]+f["reason"]).lower() for s in ("reject", "blocked", "risk", "spread", "news", "cooldown", "limit")):
                findings.append({"kind": "confirmed", "severity": "info", "category": "logged_block", "strategy": f["strategy"],
                                 "message": f"原日志记录{f['count']:g}次：{f['reason'] or f['stage']}；不证明放行会盈利。", "evidence": f.get("source", "事件日志")})
    if not dataset.get("bars"):
        findings.append({"kind": "missing", "severity": "info", "category": "market_regime", "strategy": "Combined",
                         "message": "缺可对齐的行情，行情状态与追价判断未独立验证。", "evidence": "bars=0"})
    coverage = coverage_rows(dataset)
    for index, finding in enumerate(findings, 1):
        finding["id"] = f"F{index:04d}"
    candidates = propose_candidates(findings)
    return {"metadata": {**manifest, "analyzer_version": "1.0.0", "status": "待验证基准；Python分析不授予Champion", "mt5_verification": "PENDING",
                          "sample_warning": "明确合成示例，不是券商数据或回测成绩" if manifest.get("data_type") == "synthetic" else "历史资料分析，本次未运行MT5",
                          "time_note": "时段按归一时间戳；未知服务器时区不推断伦敦/纽约或马来西亚时间"},
            "metrics": metrics, "trades": trades, "breakdowns": breakdowns, "curves": curves, "native_reports": native,
            "findings": findings, "candidates": candidates, "funnel": funnel, "coverage": coverage,
            "issues": dataset["issues"], "provenance": dataset.get("provenance", [])}


def propose_candidates(findings):
    proposals = []
    configs = [
        ("risk", {"risk", "logged_block"}, "风险计算与最小手数可执行性", "保持进场和退出不变，只核对/修正费用预算与向下手数适配；逐仓初始风险和拒单与控制组比较。"),
        ("entry_position", {"entry", "stop_distance", "duplicate_entry"}, "进场位置与候选去重", "一次仅改变入场定位或候选去重模块；冻结方向、风险、初始SL/TP及保护，检验追价标签是否具有解释力。"),
        ("profit_protection", {"profit_protection"}, "Intraday/Swing利润保护状态", "保持入场与风险不变，只验证保本确认/追踪持久状态；Scalping不加入利润保护，必须真实Tick重测。"),
        ("diagnostic_logging", {"no_trade"}, "补齐候选与拦截日志", "只开启新增诊断，先验证关闭时成交签名与原版一致；不删除保护。"),
        ("market_regime", {"market_regime"}, "行情状态标注", "先补同源FxPro行情并用已收盘数据标注，检验状态间差异；V1不添加硬过滤。"),
    ]
    for module,categories,title,experiment in configs:
        evidence = [f for f in findings if f["category"] in categories and (module != "profit_protection" or f["strategy"] in ("Intraday", "Swing"))]
        if module == "risk":
            evidence = [f for f in evidence if f["category"] == "risk" or any(x in f.get("message", "").lower() for x in ("risk", "minimumlot", "margin"))]
        if evidence:
            proposals.append({"id": f"C{len(proposals)+1:02d}", "module": module, "reason": title,
                              "evidence": ",".join(f["id"] for f in evidence[:10]), "experiment": experiment,
                              "status": "待验证假设；未修改策略，未运行候选回测"})
        if len(proposals) == 3:
            break
    return proposals
