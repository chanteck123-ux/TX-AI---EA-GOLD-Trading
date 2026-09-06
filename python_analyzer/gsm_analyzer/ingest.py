"""Read-only, provenance-preserving importers for GSM/MT5 research evidence.

No broker connection, network request, strategy execution, or implicit timezone or
contract conversion is performed here. Missing numeric values remain None.
"""
from __future__ import annotations

import csv
import hashlib
import io
import json
import math
import re
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.parse import unquote

KINDS = ("trades", "deals", "events", "funnel", "equity", "bars", "ticks", "reports")
STRATEGIES = ("Scalping", "Intraday", "Swing", "Combined", "Unknown")


def _key(value: Any) -> str:
    return re.sub(r"[\s_\-:：<>/%().]+", "", str(value)).casefold()


ALIASES = {
    "position_id": ["PositionID", "Position", "PositionIdentifier", "持仓ID"],
    "exit_deal": ["ExitDeal"], "deal_id": ["Deal", "Ticket", "成交"],
    "order_id": ["Order", "订单"], "strategy": ["SOP", "StrategyName"],
    "symbol": ["Symbol", "交易品种", "品种"], "side": ["Direction", "Type", "类型"],
    "time_open": ["EntryTime", "OpenTime", "开仓时间"],
    "time_close": ["ExitTime", "CloseTime", "BarEnd", "BarEndTime", "BarCloseTime", "EndTime", "平仓时间", "结束时间"],
    "available_at": ["AvailableAt", "AvailableTime", "IndicatorAvailableAt", "DataAvailableAt", "可用时间", "指标可用时间"],
    "time": ["Time", "Timestamp", "DateTime", "TimeMsc", "EndTime", "时间"],
    "volume": ["Volume", "Lots", "交易量", "手数", "VOL", "TICKVOL"],
    "entry_price": ["Entry", "OpenPrice", "开仓价"],
    "exit_price": ["Exit", "ClosePrice", "平仓价"],
    "price": ["Price", "价位"], "initial_sl": ["InitialSL", "SL", "S/L"],
    "initial_tp": ["InitialTP", "TP", "T/P"],
    "gross_profit": ["GrossProfit"], "net_profit": ["NetProfit", "NetUSD"],
    "profit": ["Profit", "盈利", "利润"], "commission": ["Commission", "手续费", "佣金"],
    "swap": ["Swap", "库存费", "隔夜费"], "fee": ["Fee", "其他费用"],
    "mfe_money": ["MFE_Money", "MFEUSD", "MFE"],
    "mae_money": ["MAE_Money", "MAEUSD", "MAE"],
    "risk_pct": ["ActualSLRiskPercent", "SLRiskPct"],
    "risk_money": ["ActualSLRiskMoney", "SLRiskMoney"],
    "setup_id": ["SetupID", "ZoneID"], "cluster_id": ["ClusterID"],
    "spread_money": ["SpreadMoney", "SpreadUSD"],
    "slippage_money": ["SlippageMoney", "SlippageUSD"],
    "spread_points": ["SpreadPoints", "Spread"], "atr": ["ATR"],
    "regime": ["MarketRegime", "Regime"], "chase_entry": ["ChaseEntry", "Chase"],
    "false_break": ["FalseBreak"], "loss_classification": ["LossClassification"],
    "exit_reason": ["ExitReason"], "confidence": ["Confidence"],
    "entry": ["Entry", "趋势", "Direction"], "magic": ["Magic", "MagicNumber"],
    "event_id": ["EventID"], "stage": ["Stage", "阶段"], "reason": ["RejectReason", "Reason", "原因"],
    "decision": ["Decision", "Accepted", "Result"],
    "balance": ["Balance", "结余", "余额"], "equity": ["Equity", "净值"],
    "open": ["Open", "开盘"], "high": ["High", "最高"],
    "low": ["Low", "最低"], "close": ["Close", "收盘"],
    "bid": ["Bid"], "ask": ["Ask"], "last": ["Last"],
    "timeframe": ["Timeframe", "Period", "TF"], "run_id": ["Run", "RunID"],
}
NUMERIC = {
    "volume", "entry_price", "exit_price", "price", "initial_sl", "initial_tp",
    "gross_profit", "net_profit", "profit", "commission", "swap", "fee",
    "mfe_money", "mae_money", "risk_pct", "risk_money", "spread_money",
    "slippage_money", "spread_points", "atr", "confidence", "balance", "equity",
    "open", "high", "low", "close", "bid", "ask", "last",
}
FIELDS = {
    "trades": ["position_id", "exit_deal", "strategy", "symbol", "side", "time_open", "time_close", "volume", "entry_price", "exit_price", "initial_sl", "initial_tp", "gross_profit", "commission", "swap", "fee", "net_profit", "mfe_money", "mae_money", "risk_pct", "risk_money", "setup_id", "cluster_id", "spread_money", "slippage_money", "spread_points", "atr", "regime", "chase_entry", "false_break", "loss_classification", "exit_reason", "confidence", "magic", "run_id"],
    "deals": ["time", "deal_id", "position_id", "order_id", "entry", "side", "volume", "price", "profit", "commission", "swap", "fee", "magic", "strategy", "symbol", "run_id"],
    "events": ["time", "strategy", "stage", "reason", "setup_id", "decision", "symbol", "magic", "side", "run_id", "event_id"],
    "funnel": ["time", "strategy", "magic", "run_id"],
    "equity": ["time", "balance", "equity", "strategy", "run_id"],
    "bars": ["time", "time_close", "available_at", "open", "high", "low", "close", "volume", "timeframe", "symbol", "run_id"],
    "ticks": ["time", "bid", "ask", "last", "volume", "symbol", "run_id"],
}


def _issue(dataset: dict, severity: str, code: str, message: str,
           source: str | None = None, row: int | None = None) -> None:
    item = dict(severity=severity, code=code, message=message)
    if source is not None:
        item["source"] = source
    if row is not None:
        item["row"] = row
    dataset["issues"].append(item)


def _number(value: Any) -> float | None:
    if value is None or str(value).strip().lower() in ("", "none", "null", "n/a", "na", "-", "--"):
        return None
    cleaned = str(value).strip().replace("\u00a0", "").replace("\u202f", "").replace(" ", "")
    cleaned = cleaned.replace("%", "").replace("−", "-")
    if cleaned.startswith("(") and cleaned.endswith(")"):
        cleaned = "-" + cleaned[1:-1]
    if "," in cleaned:
        if not re.fullmatch(r"[-+]?\d{1,3}(?:,\d{3})+(?:\.\d+)?", cleaned):
            return None  # Decimal-comma locale requires an explicit conversion.
        cleaned = cleaned.replace(",", "")
    try:
        result = float(cleaned)
    except (ValueError, TypeError):
        return None
    return result if math.isfinite(result) else None


def _decode(raw: bytes, dataset: dict, source: str, declared: str | None = None) -> tuple[str, str]:
    if declared:
        return raw.decode(declared), declared
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16"), "utf-16"
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw.decode("utf-8-sig"), "utf-8-sig"
    if b"\x00" in raw[:500]:
        for candidate in ("utf-16-le", "utf-16-be"):
            try:
                value = raw.decode(candidate)
                if "\x00" not in value and any(c in value for c in (",", "\t", "<", ";")):
                    _issue(dataset, "warning", "ENCODING_INFERRED", f"无 BOM，推定 {candidate}；请核对中文。", source)
                    return value, candidate
            except UnicodeDecodeError:
                pass
    try:
        return raw.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        for candidate in ("gb18030", "cp1252"):
            try:
                value = raw.decode(candidate)
                _issue(dataset, "warning", "ENCODING_INFERRED", f"非 UTF-8，推定 {candidate}；可在 input.encoding 显式指定。", source)
                return value, candidate
            except UnicodeDecodeError:
                pass
    raise UnicodeDecodeError("utf-8", raw, 0, min(len(raw), 1), "无法确定编码，请指定 input.encoding")


def _offset(value: Any) -> timezone | None:
    if str(value).upper() in ("UTC", "Z", "UTC+00:00", "+00:00"):
        return timezone.utc
    match = re.fullmatch(r"(?:UTC)?([+-])(\d{2}):?(\d{2})", str(value).upper())
    if not match:
        return None
    minutes = int(match[2]) * 60 + int(match[3])
    if int(match[2]) > 23 or int(match[3]) > 59:
        return None
    return timezone(timedelta(minutes=minutes if match[1] == "+" else -minutes))


def _time(value: Any, zone: Any, dataset: dict, source: str, row: int,
          numeric_unit: str | None = None) -> str | None:
    if value is None or not str(value).strip():
        return None
    original = str(value).strip()
    try:
        if numeric_unit or re.fullmatch(r"\d{13}", original):
            amount = float(original)
            divisor = 1000 if numeric_unit != "unix_seconds_utc" else 1
            parsed = datetime.fromtimestamp(amount / divisor, timezone.utc)
            if numeric_unit not in ("unix_ms_utc", "unix_seconds_utc"):
                # MT5 TimeMsc is a server-clock field; do not invent UTC.
                parsed = parsed.replace(tzinfo=None)
        else:
            normalized = re.sub(r"^(\d{4})\.(\d{2})\.(\d{2})", r"\1-\2-\3", original)
            parsed = datetime.fromisoformat(normalized.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            local_zone = _offset(zone)
            if local_zone is not None:
                parsed = parsed.replace(tzinfo=local_zone)
        if parsed.tzinfo is not None:
            return parsed.astimezone(timezone.utc).isoformat()
        return parsed.isoformat()
    except (ValueError, OverflowError, OSError):
        _issue(dataset, "error", "INVALID_TIME", f"无法解析时间 {original!r}；未猜测日期/时区。", source, row)
        return None


def _strategy(value: Any, magic: Any, item: dict, manifest: dict) -> str:
    value = value or item.get("strategy") or manifest.get("magic_map", {}).get(str(magic))
    if isinstance(value, dict):
        value = value.get("strategy")
    lowered = str(value or "").casefold()
    for strategy in STRATEGIES[:-1]:
        if strategy.casefold() in lowered:
            return strategy
    # A single-engine manifest is explicit source attribution, not an inference
    # from a trade's BUY/SELL, timeframe, profit, or filename.
    scope = manifest.get("strategy_scope")
    if not value and isinstance(scope, list) and len(scope) == 1 and scope[0] in STRATEGIES[:-1]:
        return scope[0]
    if not value and isinstance(scope, str) and scope in STRATEGIES[:-1]:
        return scope
    return "Unknown"


def _mapped(raw: dict, canonical: str, columns: dict) -> Any:
    if canonical in columns:
        return raw.get(columns[canonical])
    indexed = {_key(k): v for k, v in raw.items() if k is not None}
    for alias in [canonical] + ALIASES.get(canonical, []):
        if _key(alias) in indexed:
            return indexed[_key(alias)]
    return None


def _csv_rows(content: str, dataset: dict, source: str, item: dict) -> list[tuple[int, dict]]:
    first = next((line for line in content.splitlines() if line.strip()), "")
    delimiter = item.get("delimiter")
    if delimiter == "\\t":
        delimiter = "\t"
    if not delimiter:
        delimiter = max((",", ";", "\t"), key=lambda c: first.count(c))
    reader = csv.DictReader(io.StringIO(content), delimiter=delimiter)
    if not reader.fieldnames:
        _issue(dataset, "warning", "EMPTY_INPUT", "没有 CSV 表头或记录。", source)
        return []
    if len(reader.fieldnames) != len(set(reader.fieldnames)):
        _issue(dataset, "error", "DUPLICATE_COLUMNS", "CSV 列名重复，文件隔离，避免覆盖列值。", source)
        return []
    result = []
    for raw in reader:
        row = reader.line_num
        if not any(str(v or "").strip() for v in raw.values()):
            continue
        if None in raw:
            _issue(dataset, "error", "CSV_EXTRA_COLUMNS", "行字段多于表头，已隔离；请检查分隔符和引号。", source, row)
            continue
        result.append((row, raw))
    return result


def _normalize(raw: dict, kind: str, item: dict, dataset: dict,
               source: str, row: int) -> dict | None:
    manifest = dataset["manifest"]
    columns = item.get("columns", {})
    record = {field: _mapped(raw, field, columns) for field in FIELDS[kind]}
    record.update(_source=source, _row=row, raw=dict(raw))
    if "run_id" in record and not record["run_id"]:
        record["run_id"] = item.get("run_id")
    if kind == "deals" and "side" not in columns:
        indexed_side = {_key(k): v for k, v in raw.items()}
        record["side"] = indexed_side.get("side", indexed_side.get("type", indexed_side.get("类型", record["side"])))
    for field in NUMERIC.intersection(record):
        value = record[field]
        record[field] = _number(value)
        if value not in (None, "", "-", "--", "N/A", "null") and record[field] is None:
            _issue(dataset, "warning", "INVALID_NUMBER", f"{field}={value!r} 不是有限数值，保留为空。", source, row)
    if "time" in record:
        indexed_clock = {_key(k): v for k, v in raw.items()}
        if indexed_clock.get("date") and indexed_clock.get("time"):
            record["time"] = f"{indexed_clock['date']} {indexed_clock['time']}"
    for field in ("time", "time_open", "time_close", "available_at"):
        if field in record:
            unit = item.get("time_unit")
            if _mapped(raw, "time", columns) == raw.get("TimeMsc") and raw.get("TimeMsc"):
                unit = unit or "mt5_server_ms"
            record[field] = _time(record[field], item.get("timezone", manifest.get("timezone")), dataset, source, row, unit)
    if "time" in record and not record["time"]:
        # Native MT5 bar/tick exports split <DATE> and <TIME>.
        indexed = {_key(k): v for k, v in raw.items()}
        date = indexed.get("date")
        clock = indexed.get("time")
        if date and clock:
            record["time"] = _time(f"{date} {clock}", item.get("timezone", manifest.get("timezone")), dataset, source, row)
    if "strategy" in record:
        record["strategy"] = _strategy(record.get("strategy"), record.get("magic"), item, manifest)
        if kind == "equity" and record["strategy"] == "Unknown":
            record["strategy"] = item.get("strategy", "Combined")
    if "symbol" in record:
        expected = manifest.get("symbol")
        actual = record.get("symbol")
        aliases = manifest.get("symbol_aliases", [])
        allowed = set(aliases if isinstance(aliases, list) else aliases.keys()) | {expected}
        if actual and actual not in allowed:
            _issue(dataset, "error", "SYMBOL_MISMATCH", f"品种 {actual!r} 不在声明 {expected!r} 及显式别名中；记录已隔离。", source, row)
            return None
        if not actual:
            record["_symbol_from_manifest"] = True
            record["symbol"] = expected
        else:
            record["source_symbol"] = actual
            record["symbol"] = expected or actual
    if "side" in record:
        value = str(record["side"] or "").strip().upper()
        if value in ("BUY", "LONG", "买入", "多", "0"):
            record["side"] = "BUY"
        elif value in ("SELL", "SHORT", "卖出", "空") or (kind == "deals" and value == "1") or value == "-1":
            record["side"] = "SELL"
        elif kind != "deals" and value == "1":
            record["side"] = "BUY"
        else:
            record["side"] = "Unknown"
    if kind == "trades":
        adapter = item.get("adapter", "auto")
        is_gsm = adapter in ("gsm_trade_review", "trade_review") or (adapter == "auto" and "MFE_Money" in raw and "ExitDeal" in raw and "SOP" in raw)
        if record["net_profit"] is None and is_gsm:
            record["net_profit"] = _number(raw.get("Profit"))
            record["_net_profit_basis"] = "GSM PositionLifetimeProfit: Profit+Commission+Swap+Fee; components unavailable unless independently exported"
        if record["net_profit"] is None and all(record.get(k) is not None for k in ("gross_profit", "commission", "swap", "fee")):
            record["net_profit"] = sum(record[k] for k in ("gross_profit", "commission", "swap", "fee"))
        if record["net_profit"] is None:
            _issue(dataset, "error", "NET_PROFIT_MISSING", "缺少净利润或完整费用分项；该交易不能进入净绩效统计。通用 Profit 不默认等于净利润。", source, row)
        if not record["time_open"] or not record["time_close"]:
            _issue(dataset, "warning", "TRADE_TIME_MISSING", "交易缺少有效开/平仓时间，不能完整分析时段/持仓时间。", source, row)
        elif record["time_close"] < record["time_open"]:
            _issue(dataset, "error", "NEGATIVE_HOLDING_TIME", "平仓时间早于开仓，交易已隔离。", source, row)
            return None
        record["_mfe_basis"] = "gross_price_excursion_original_volume" if is_gsm else item.get("mfe_basis", "unknown")
        for name in ("chase_entry", "false_break"):
            if record.get(name) is not None:
                record[name] = str(record[name]).upper() in ("YES", "TRUE", "1")
        if is_gsm:
            record["_classification_basis"] = "source_heuristic_not_proven_cause"
    elif kind == "deals":
        entry = str(record.get("entry") or "").strip().lower()
        record["entry"] = {"0": "in", "1": "out", "2": "inout", "3": "out_by", "out by": "out_by"}.get(entry, entry)
        if record["side"] == "Unknown":
            _issue(dataset, "info", "NON_TRADE_DEAL", "非 BUY/SELL 成交（可能为出入金/余额调整），未混入交易成交。", source, row)
            return None
        if record["entry"] not in ("in", "out", "inout", "out_by"):
            _issue(dataset, "error", "DEAL_ENTRY_UNKNOWN", "成交缺少明确 IN/OUT，不能重建完整仓位。", source, row)
        if not record.get("position_id"):
            record["_position_link_missing"] = True
        if not record.get("time") or record.get("volume") is None or record["volume"] <= 0:
            _issue(dataset, "error", "INVALID_DEAL", "成交时间/正手数缺失，记录已隔离。", source, row)
            return None
    elif kind == "events":
        is_audit = "RawCore" in raw and "Accepted" in raw
        if is_audit:
            record["stage"] = "signal_audit"
            record["decision"] = "accepted" if str(raw.get("Accepted", "")).upper() == "YES" else "blocked"
            record["flags"] = {name: str(raw[name]).upper() == "YES" for name in ("RawCore", "IndicatorPassed", "MACDPassed", "BollingerPassed", "ConfidencePassed", "GatePassed", "Accepted") if name in raw}
            record["_stage_semantics"] = "one_source_signal_row; accepted is not proof of a fill"
        else:
            decision = str(record.get("decision") or "").lower()
            record["decision"] = {"yes": "accepted", "no": "blocked", "true": "accepted", "false": "blocked"}.get(decision, decision or "unknown")
        record["stage"] = record.get("stage") or "unclassified"
    elif kind == "funnel":
        excluded = {_key(k) for k in ("Run", "RunID", "EndTime", "Time", "SOP", "Strategy", "Magic", "ZeroTradeDiagnosis")}
        record["counts"] = {}
        for key, value in raw.items():
            if _key(key) not in excluded:
                numeric = _number(value)
                if numeric is not None:
                    if numeric < 0 or not numeric.is_integer():
                        _issue(dataset, "warning", "INVALID_FUNNEL_COUNT", f"{key} 不是非负整数，计数未纳入。", source, row)
                    else:
                        record["counts"][key] = int(numeric)
                        record[key] = int(numeric)
        record["diagnosis"] = raw.get("ZeroTradeDiagnosis")
        record["_semantics"] = "cumulative_snapshot_not_unique_signals"
    elif kind == "bars":
        for clock_field in ("available_at", "time_close"):
            if _mapped(raw, clock_field, columns) not in (None, "") and record[clock_field] is None:
                _issue(dataset, "error", "INVALID_BAR_AVAILABILITY", "明确声明的K线结束/指标可用时间无法解析；K线隔离，避免回退推定时间造成未来泄漏。", source, row)
                return None
        record["timeframe"] = record.get("timeframe") or item.get("timeframe")
        prices = [record.get(k) for k in ("open", "high", "low", "close")]
        if not record["time"] or any(x is None or x <= 0 for x in prices) or record["high"] < max(prices) or record["low"] > min(prices):
            _issue(dataset, "error", "INVALID_OHLC", "时间或 OHLC 不合法，K 线已隔离。", source, row)
            return None
    elif kind == "ticks":
        if not record["time"] or record.get("bid") is None or record.get("ask") is None or record["bid"] <= 0 or record["ask"] < record["bid"]:
            _issue(dataset, "error", "INVALID_TICK", "Tick 必须有时间和合法 bid/ask；未用期货 last 冒充报价。", source, row)
            return None
    elif kind == "equity":
        if not record["time"] or (record["balance"] is None and record["equity"] is None):
            _issue(dataset, "error", "INVALID_EQUITY", "记录缺少时间或余额/净值，已隔离。", source, row)
            return None
    return record


class _Tables(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.rows: list[tuple[int, list[str]]] = []
        self.current: list[str] | None = None
        self.cell: list[str] | None = None
        self.line = 1

    def handle_starttag(self, tag, attrs):
        if tag == "tr":
            self.current = []
            self.line = self.getpos()[0]
        elif tag in ("td", "th") and self.current is not None:
            self.cell = []
        elif tag == "br" and self.cell is not None:
            self.cell.append(" ")

    def handle_data(self, data):
        if self.cell is not None:
            self.cell.append(data)

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self.cell is not None:
            if self.current is not None:
                self.current.append(" ".join("".join(self.cell).split()))
            self.cell = None
        elif tag == "tr" and self.current is not None:
            self.rows.append((self.line, self.current))
            self.current = None
            self.cell = None


SUMMARY_ALIASES = {
    "net_profit": ["Total Net Profit", "总净盈利", "总净利润", "净盈利", "净利润", "NetProfitUSD"],
    "gross_profit": ["Gross Profit", "毛利"], "gross_loss": ["Gross Loss", "毛损"],
    "profit_factor": ["Profit Factor", "盈利因子", "获利因子"],
    "initial_capital": ["Initial Deposit", "初始入金", "初始存款", "首次入金"],
    "total_trades": ["Total Trades", "总交易", "交易总计", "NativeTrades"],
    "total_deals": ["Total Deals", "总成交", "成交总计", "NativeDeals"],
    "expected_payoff": ["Expected Payoff", "预期收益", "预期回报"],
    "recovery_factor": ["Recovery Factor", "恢复因子", "采收率", "恢复系数", "NativeBalanceRecovery"],
    "history_quality_pct": ["History Quality", "历史质量", "质量历史"],
    "min_margin_level": ["Margin Level", "保证金水平", "预付款维持率", "MinMarginLevel"],
    "balance_drawdown_money": ["Balance Drawdown Maximal", "最大结余亏损", "最大余额回撤"],
    "balance_drawdown_pct": ["Balance Drawdown Relative", "相对结余亏损", "相对余额回撤"],
    "equity_drawdown_money": ["Equity Drawdown Maximal", "最大净值亏损", "最大净值回撤", "MaxEquityDDUSD"],
    "equity_drawdown_pct": ["Equity Drawdown Relative", "相对净值亏损", "相对净值回撤", "MaxEquityDDPct"],
    "profit_trades": ["Profit Trades (% of total)", "盈利交易 (% 全部)"],
    "loss_trades": ["Loss Trades (% of total)", "亏损交易 (% 全部)"],
    "average_profit": ["Average profit trade", "平均 获利交易", "平均盈利交易"],
    "average_loss": ["Average loss trade", "平均 亏损交易", "平均亏损交易"],
    "max_consecutive_losses": ["Maximum consecutive losses ($)", "最大 连续亏损 ($)", "最大连续亏损", "最大值 连败 ($)"],
    "long_trades": ["Long Trades (won %)", "买入交易 (赢得 %)"],
    "short_trades": ["Short Trades (won %)", "卖出交易 (赢得 %)"],
    "all_requests": ["AllRequests"], "management_requests": ["ManagementRequests"],
    "all_request_rejects": ["AllRequestRejects"],
}
SUMMARY_LOOKUP = {_key(alias): key for key, aliases in SUMMARY_ALIASES.items() for alias in aliases}


def _summary(raw: dict) -> dict:
    result = {}
    for label, value in raw.items():
        name = SUMMARY_LOOKUP.get(_key(label))
        if not name:
            continue
        matches = re.findall(r"[-+]?\d[\d\s,]*(?:\.\d+)?", str(value))
        number = _number(matches[0]) if matches else None
        if number is not None:
            result[name] = number
        if name in ("profit_trades", "long_trades", "short_trades"):
            percentage = re.search(r"([-+]?\d+(?:\.\d+)?)\s*%", str(value))
            if percentage:
                result[{"profit_trades": "win_rate", "long_trades": "long_win_rate", "short_trades": "short_win_rate"}[name]] = float(percentage[1])
    return result


def _html_report(content: str, item: dict, dataset: dict, source: str) -> int:
    parser = _Tables()
    parser.feed(content)
    raw_summary = {}
    table_header = None
    table_kind = None
    imported = 0
    for rowno, cells in parser.rows:
        for i, cell in enumerate(cells[:-1]):
            if cell.endswith((":", "：")):
                # The settings symbol can reappear later as a numeric symbol count.
                # Preserve the first setting instead of replacing GOLD with "1".
                raw_summary.setdefault(cell.rstrip(":："), cells[i + 1])
        keys = {_key(c) for c in cells}
        has_time = bool(keys & {_key("Time"), _key("时间")})
        has_deal = bool(keys & {_key("Deal"), _key("成交")})
        has_side = bool(keys & {_key("Type"), _key("类型")})
        if has_time and has_deal and has_side:
            table_header, table_kind = cells, "deals"
            continue
        # Position reports from third parties must explicitly contain both clocks.
        if {_key("time_open"), _key("time_close"), _key("net_profit")}.issubset(keys):
            table_header, table_kind = cells, "trades"
            continue
        if table_header and len(cells) == len(table_header) and cells and re.match(r"\d{4}[.\-/]\d{2}[.\-/]\d{2}", cells[0]):
            record = _normalize(dict(zip(table_header, cells)), table_kind, item, dataset, source, rowno)
            if record:
                record["_from_report"] = True
                dataset[table_kind].append(record)
                imported += 1
    summary = _summary(raw_summary)
    report = {"_source": source, "_row": 1, "format": "mt5_html" if summary else "generic_html", "summary": summary, "raw_summary": raw_summary,
              "strategy": _strategy(None, None, item, dataset["manifest"]), "_coverage_verified": False}
    dataset["reports"].append(report)
    if not summary:
        _issue(dataset, "warning", "UNSUPPORTED_REPORT_SUMMARY", "未识别 MT5 汇总字段；已保留来源，未把其他 HTML 数字当 MT5 成绩。", source)
    if imported and any(d.get("_source") == source and not d.get("position_id") for d in dataset["deals"]):
        _issue(dataset, "warning", "HTML_POSITION_ID_MISSING", "原生 HTML 成交没有 PositionID；不把订单号当仓位号，完整仓位需 DEALS.csv 或独立成交关联证据。", source)
    return len(parser.rows)


def _native_stats(content: str, dataset: dict, source: str, item: dict) -> int:
    rows = _csv_rows(content, dataset, source, item)
    values = {}
    for _, row in rows:
        if "Metric" not in row or "Value" not in row:
            _issue(dataset, "error", "NATIVE_STATS_COLUMNS", "原生统计文件需要 Metric,Value 列。", source)
            break
        values[row["Metric"]] = row["Value"]
    dataset["reports"].append(dict(_source=source, _row=1, format="native_stats", summary=_summary(values), raw_summary=values,
                                   strategy=_strategy(None, None, item, dataset["manifest"]), _coverage_verified=False))
    return len(rows)


def _log(content: str, dataset: dict, source: str, item: dict) -> int:
    count = 0
    for rowno, line in enumerate(content.splitlines(), 1):
        count += 1
        # Structured records only. Arbitrary terminal prose is not a measured gate.
        marker = re.search(r"(?:GSM_ANALYZER|GSM_DIAG|STUDY_REQUEST|SIGNAL_AUDIT|TRADE_REVIEW_START|TRADE_REVIEW_END|SIGNAL_REJECT|RISK_REJECT)\|", line)
        if not marker:
            continue
        raw = {}
        payload = line[marker.start():]
        pieces = payload.split("|")
        raw["Stage"] = pieces[0]
        for piece in pieces[1:]:
            if "=" in piece:
                key, value = piece.split("=", 1)
                raw[key.strip()] = unquote(value.strip()) if pieces[0] == "GSM_ANALYZER" else value.strip()
        if not any(k in raw for k in ("Time", "time", "Timestamp")):
            clocks = re.findall(r"\d{4}[.-]\d{2}[.-]\d{2}[ T]\d{2}:\d{2}:\d{2}(?:\.\d+)?", line[:marker.start()])
            if len(clocks) == 1:
                raw["Time"] = clocks[0]
            elif len(clocks) > 1:
                _issue(dataset, "warning", "LOG_MULTIPLE_CLOCKS", "日志含多个时钟，未猜测模拟时间；请使用含 Time= 的诊断日志。", source, rowno)
        if pieces[0] == "GSM_ANALYZER" and raw.get("Stage") == "ACCOUNT_SAMPLE":
            snapshot = _normalize(raw, "equity", item, dataset, source, rowno)
            if snapshot:
                snapshot["_equity_sampling"] = "periodic_account_snapshot_not_native_tick_maximum"
                snapshot["sample_seconds"] = _number(raw.get("SampleSeconds"))
                dataset["equity"].append(snapshot)
            continue
        record = _normalize(raw, "events", item, dataset, source, rowno)
        if record:
            if pieces[0] == "GSM_ANALYZER":
                record["_stage_semantics"] = raw.get("DecisionMeaning", "existing_audit_call_only_not_complete_funnel")
                record["_decision_is_fill"] = False
                record["flags"] = {name: str(raw[name]) == "1" for name in ("RawCore", "Indicator", "MACD", "Confidence", "Gate", "AcceptedObserved") if name in raw}
            if pieces[0] == "STUDY_REQUEST":
                record["stage"] = "execution_request"
                record["reason"] = record["reason"] or ("Retcode=" + raw.get("Retcode", "unknown"))
                record["_request_semantics"] = "includes_management; accepted does not imply new position filled"
            dataset["events"].append(record)
    if not any(e.get("_source") == source for e in dataset["events"]):
        _issue(dataset, "warning", "LOG_NO_STRUCTURED_EVENTS", "没有可识别的结构化诊断事件；不能从普通文字推断未开单原因。", source)
    return count


def _deduplicate(dataset: dict) -> None:
    for kind in ("trades", "deals", "events", "funnel", "equity", "bars", "ticks"):
        seen: dict[Any, dict] = {}
        conflicts: set[Any] = set()
        output = []
        for record in dataset[kind]:
            if kind == "trades" and record.get("position_id"):
                identity = (record.get("run_id"), record.get("strategy"), record["position_id"])
            elif kind == "deals" and record.get("deal_id"):
                identity = (record.get("run_id"), record["deal_id"])
            elif kind == "equity":
                identity = (record.get("run_id"), record.get("strategy"), record.get("time"))
            elif kind == "bars":
                identity = (record.get("run_id"), record.get("symbol"), record.get("timeframe"), record.get("time"))
            elif kind == "funnel":
                identity = (record.get("run_id"), record.get("strategy"), record.get("time"))
            else:
                # Multiple ticks and events at one instant are legitimate. Only
                # identical business records are deduplicated in those streams.
                identity = json.dumps({k: v for k, v in record.items() if not k.startswith("_") and k != "raw"}, sort_keys=True, ensure_ascii=False)
            signature = {k: v for k, v in record.items() if not k.startswith("_") and k != "raw"}
            if identity in conflicts:
                _issue(dataset, "error", "DUPLICATE_CONFLICT", "同一标识已有冲突，后续记录也隔离。", record["_source"], record["_row"])
                continue
            if identity in seen:
                before = {k: v for k, v in seen[identity].items() if not k.startswith("_") and k != "raw"}
                if before == signature:
                    _issue(dataset, "info", "DUPLICATE_REMOVED", "重复记录已去重，未重复计入成绩。", record["_source"], record["_row"])
                elif kind == "deals" and all(before.get(key) in (None, "", "Unknown") or signature.get(key) in (None, "", "Unknown") or before.get(key) == signature.get(key) for key in set(before) | set(signature)):
                    # The same DealID in HTML and DEALS.csv may provide complementary
                    # position/magic/fee fields; merge only when known fields agree.
                    existing = seen[identity]
                    for key, value in record.items():
                        if not key.startswith("_") and key != "raw" and existing.get(key) in (None, "", "Unknown") and value not in (None, "", "Unknown"):
                            existing[key] = value
                    existing.setdefault("_merged_sources", []).append({"source": record["_source"], "row": record["_row"]})
                    _issue(dataset, "info", "DUPLICATE_DEAL_MERGED", "同一 DealID 的已知字段一致；只补缺失字段，计数仍为一笔成交。", record["_source"], record["_row"])
                else:
                    _issue(dataset, "error", "DUPLICATE_CONFLICT", "同一标识值冲突，两份记录均隔离；不能任选一份计算成绩。", record["_source"], record["_row"])
                    output.remove(seen[identity])
                    conflicts.add(identity)
                continue
            seen[identity] = record
            output.append(record)
        dataset[kind] = output


def _checks(dataset: dict) -> None:
    manifest = dataset["manifest"]
    if not manifest.get("symbol"):
        _issue(dataset, "error", "SYMBOL_UNDECLARED", "manifest 未声明目标品种。")
    for field in ("broker", "account_currency", "ea_version", "ea_sha256", "set_sha256"):
        if not manifest.get(field) or str(manifest.get(field)).casefold() in ("unknown", "未提供", "待验证"):
            _issue(dataset, "warning", "METADATA_MISSING", f"{field} 未证实，报告不能完整追溯。")
    if manifest.get("data_type") not in ("backtest", "demo", "live", "synthetic", "unknown"):
        _issue(dataset, "error", "DATA_TYPE_UNKNOWN", "data_type 必须显式区分 backtest/demo/live/synthetic/unknown。")
    elif manifest.get("data_type") == "unknown":
        _issue(dataset, "warning", "DATA_TYPE_UNKNOWN", "数据性质未确认，不视为实盘或真实 Tick 回测。")
    if _offset(manifest.get("timezone")) is None:
        _issue(dataset, "warning", "TIMEZONE_UNKNOWN", "服务器时区未知/不支持固定偏移，保留无时区时间；不会猜测 UTC 或夏令时。")
    contract = manifest.get("contract", {})
    for field in ("contract_size", "volume_min", "volume_step", "tick_size"):
        if _number(contract.get(field)) is None:
            _issue(dataset, "warning", "CONTRACT_MISSING", f"合约规格 {field} 未提供；不能可靠把点/手数转换为金额。")
    for kind in ("trades", "events", "bars", "ticks"):
        inherited = {r["_source"] for r in dataset[kind] if r.get("_symbol_from_manifest")}
        for source in sorted(inherited):
            _issue(dataset, "warning", "SYMBOL_DECLARED_ONLY", "源行没有品种列，按 manifest 的单品种声明归属，尚无逐行品种核验。", source)
    for source in {p["path"] for p in dataset["provenance"]}:
        for kind in ("bars", "ticks", "equity", "deals"):
            times = [r["time"] for r in dataset[kind] if r["_source"] == source and r.get("time")]
            if times != sorted(times):
                _issue(dataset, "warning", "TIME_NOT_SORTED", f"{kind} 时间未递增；分析必须按时间排序。", source)
    if not dataset["equity"] or not any(r.get("equity") is not None for r in dataset["equity"]):
        _issue(dataset, "warning", "EQUITY_SERIES_MISSING", "缺少权益时序；不能由余额曲线冒充净值回撤。报告原生净值汇总可单独保留。")
    if not dataset["ticks"]:
        _issue(dataset, "warning", "REAL_TICK_COVERAGE_UNVERIFIED", "未导入有效原始 Tick，无法核实自 2024-03 起的实际覆盖；测试报告日期/质量不等于原始 Tick 覆盖证据。")
    if any(not r.get("position_id") for r in dataset["deals"]):
        _issue(dataset, "warning", "POSITION_ID_MISSING", "部分成交缺少 PositionID，不能据此完整重建仓位及分批平仓交易数。")
    if dataset["funnel"]:
        _issue(dataset, "info", "FUNNEL_COUNTER_SEMANTICS", "原生 funnel 为累计计数，图形扫描、触碰、拒绝与成交未必同分母，不能相加或直接计算统一转化率。")


def load_dataset(manifest_path: str | Path, allow_final: bool = False) -> dict:
    """Load one immutable run manifest. Paths are relative to its directory.

    Invalid input files produce issues while independent files continue. A final
    segment is intentionally gated *before* opening any input file.
    """
    path = Path(manifest_path).resolve()
    manifest = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(manifest, dict) or manifest.get("schema_version") != 1:
        raise ValueError("manifest 必须为 schema_version=1 的 JSON 对象")
    if manifest.get("segment") == "final" and not allow_final:
        raise ValueError("最终样本外区间已锁定；候选冻结后，显式 --allow-final 才可首次读取，且不得再用于调参。")
    dataset = {kind: [] for kind in KINDS}
    dataset.update(manifest=manifest, provenance=[], issues=[])
    if manifest.get("segment") == "final":
        _issue(dataset, "warning", "FINAL_SEGMENT_OPENED", "已显式读取最终区间；应登记冻结版本与首次使用，不能再把本区间称为未见样本。")
    for item in manifest.get("inputs", []):
        if not isinstance(item, dict) or not item.get("path"):
            _issue(dataset, "error", "INVALID_INPUT", "input 必须含 kind/path。")
            continue
        source_path = (path.parent / item["path"]).resolve()
        source = str(source_path)
        kind = item.get("kind")
        if kind == "reports":
            kind = "report"
        if kind not in (*FIELDS, "report", "log", "evidence"):
            _issue(dataset, "error", "UNSUPPORTED_KIND", f"不支持 kind={kind!r}；文件未误读。", source)
            continue
        try:
            raw = source_path.read_bytes()
        except OSError as exc:
            _issue(dataset, "error", "INPUT_MISSING", f"无法读取文件：{exc}", source)
            continue
        provenance = dict(path=source, declared_path=item["path"], sha256=hashlib.sha256(raw).hexdigest(), kind=kind, encoding=None, row_count=0, size_bytes=len(raw), adapter=item.get("adapter", "auto"))
        dataset["provenance"].append(provenance)
        if item.get("sha256") and str(item["sha256"]).lower() != provenance["sha256"]:
            _issue(dataset, "error", "SHA256_MISMATCH", "输入文件哈希与登记不符；文件已隔离。", source)
            continue
        if kind == "evidence":
            continue
        if item.get("data_type") and item["data_type"] != manifest.get("data_type"):
            _issue(dataset, "error", "MIXED_DATA_TYPE", "单次运行不能混合模拟/实盘/合成数据；文件已隔离。", source)
            continue
        try:
            content, encoding = _decode(raw, dataset, source, item.get("encoding"))
            provenance["encoding"] = encoding
            if kind == "report":
                if source_path.suffix.lower() in (".htm", ".html"):
                    provenance["row_count"] = _html_report(content, item, dataset, source)
                elif source_path.suffix.lower() == ".csv" or item.get("adapter") == "native_stats":
                    provenance["row_count"] = _native_stats(content, dataset, source, item)
                else:
                    _issue(dataset, "warning", "UNSUPPORTED_REPORT_FORMAT", "第一版支持 MT5 HTML 与 NATIVE_STATS.csv；其他报告保留哈希待适配。", source)
            elif kind == "log":
                provenance["row_count"] = _log(content, dataset, source, item)
            else:
                rows = _csv_rows(content, dataset, source, item)
                provenance["row_count"] = len(rows)
                for row, record in rows:
                    normalized = _normalize(record, kind, item, dataset, source, row)
                    if normalized is not None:
                        dataset[kind].append(normalized)
        except (UnicodeError, LookupError, csv.Error, ValueError, TypeError) as exc:
            _issue(dataset, "error", "IMPORT_FAILED", f"文件导入失败：{type(exc).__name__}: {exc}；其余文件继续。", source)
    _deduplicate(dataset)
    _checks(dataset)
    return dataset
