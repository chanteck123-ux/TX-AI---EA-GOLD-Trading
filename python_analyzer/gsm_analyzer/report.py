"""Offline Chinese HTML/CSV reports; no third-party libraries or network calls.

This module displays analysis evidence. It deliberately does not infer missing
equity, certify a trading strategy, or turn imported reports into a Champion.
"""

from __future__ import annotations

import csv
import html
import json
import math
from collections.abc import Mapping
from pathlib import Path
from typing import Any


LABELS = {
    "strategy": "策略", "complete_trades": "完整交易数", "total_trades": "交易数",
    "net_profit": "净利润", "win_rate": "胜率 %", "profit_factor": "获利因子 PF",
    "avg_win": "平均盈利", "avg_loss": "平均亏损", "max_consecutive_losses": "最大连续亏损",
    "balance_dd_money": "余额最大回撤金额", "balance_dd_pct": "余额最大相对回撤 %",
    "equity_dd_money": "净值最大回撤金额", "equity_dd_pct": "净值最大相对回撤 %",
    "expected_payoff": "每笔净期望值", "return_pct": "收益率 %",
    "dimension": "分组维度", "value": "分组值", "stage": "阶段", "reason": "原因",
    "count": "计数", "unit": "计数单位", "id": "编号", "kind": "证据类型",
    "severity": "严重程度", "category": "问题分类", "message": "说明", "evidence": "证据",
    "module": "唯一变更模块", "experiment": "验证实验", "status": "状态",
    "start": "起始时间", "end": "结束时间", "rows": "记录数", "source": "来源",
    "path": "路径", "sha256": "SHA256", "hash": "哈希", "encoding": "编码",
    "row_count": "记录数", "code": "问题代码", "row": "原始行号",
    "direction": "方向", "symbol": "品种", "open_time": "开仓时间",
    "close_time": "平仓时间", "volume": "手数", "profit": "交易损益",
    "commission": "佣金", "swap": "隔夜费", "fee": "其他费用",
    "spread": "点差", "slippage": "滑点", "holding_minutes": "持仓分钟",
    "format": "格式", "field": "字段", "native_value": "原生值", "summary": "原生摘要",
    "_source": "原始来源", "time": "时间", "balance": "余额", "equity": "净值",
    "metric_basis": "指标计算口径", "balance_dd_source": "余额回撤来源",
    "equity_dd_source": "净值回撤来源", "cost_note": "成本说明",
    "wins": "盈利交易数", "losses": "亏损交易数", "breakeven_trades": "零损益交易数",
    "profit_factor_status": "PF 可计算状态", "realized_reward_risk": "实际平均盈亏比",
    "balance_recovery": "余额恢复因子", "equity_recovery": "净值恢复因子",
    "spread_money": "点差成本金额", "slippage_money": "滑点成本金额",
    "balance_dd_pct_at_max_money": "余额金额最大回撤时对应 %",
    "reconstructed_balance_dd_money": "重建余额回撤金额", "side": "方向",
    "time_open": "开仓时间", "time_close": "平仓时间", "position_id": "持仓 ID",
    "price_open": "开仓价格", "price_close": "平仓价格", "magic": "Magic 标识",
    "hour": "开仓小时", "session": "时段", "holding_bucket": "持仓时长分组",
    "market_regime": "行情状态", "initial_sl": "初始止损", "initial_tp": "初始止盈",
}

SECTIONS = {
    "metrics": "分策略基础指标", "breakdowns": "方向、时段、持仓时间及行情状态",
    "trades": "交易分析明细", "funnel": "为什么不开单：诊断计数",
    "findings": "已确认问题、假设及缺项", "candidates": "下一轮候选改进（最多三项）",
    "coverage": "数据覆盖检查", "issues": "数据质量问题", "provenance": "来源与文件哈希",
    "native_reports": "MT5 原生报告摘要（独立口径）",
}

CSV_FILES = {
    "metrics": "metrics.csv", "trades": "trade_analysis.csv", "breakdowns": "breakdowns.csv",
    "funnel": "signal_funnel.csv", "findings": "findings.csv", "candidates": "candidates.csv",
    "coverage": "coverage.csv", "issues": "data_issues.csv", "provenance": "provenance.csv",
    "native_reports": "native_report_summary.csv",
}

STAGE_LABELS = {
    "candidate": "产生候选", "gate": "条件检查", "signal": "策略信号",
    "blocked": "拦截", "block": "拦截", "passed": "条件通过", "pass": "条件通过",
    "order_request": "申请下单", "order_sent": "已发送请求", "request_sent": "已发送请求",
    "order_rejected": "订单被拒绝", "rejected": "订单被拒绝", "order_filled": "成交确认",
    "filled": "成交确认", "execution": "交易执行", "cooldown": "冷却检查",
    "risk": "风险检查", "risk_check": "风险检查", "score": "评分检查",
    "spread": "点差检查", "news": "新闻检查", "sop": "SOP 条件检查",
}

DEFAULT_COLUMNS = {
    "metrics": ["strategy", "complete_trades", "net_profit", "win_rate", "profit_factor",
                "avg_win", "avg_loss", "max_consecutive_losses", "balance_dd_money",
                "balance_dd_pct", "equity_dd_money", "equity_dd_pct", "expected_payoff", "return_pct"],
    "trades": ["strategy", "symbol", "side", "time_open", "time_close", "volume", "net_profit"],
    "breakdowns": ["strategy", "dimension", "value", "complete_trades", "net_profit", "win_rate"],
    "funnel": ["strategy", "stage", "reason", "count", "unit"],
    "findings": ["id", "kind", "severity", "category", "strategy", "message", "evidence"],
    "candidates": ["id", "module", "reason", "evidence", "experiment", "status"],
    "coverage": ["kind", "start", "end", "rows", "status"],
    "issues": ["severity", "code", "message", "source", "row"],
    "provenance": ["path", "sha256", "kind", "encoding", "row_count"],
    "native_reports": ["format", "_source", "field", "native_value"],
}


def _clean(value: Any) -> Any:
    """Produce strict JSON values while keeping missing numbers missing."""
    if isinstance(value, Mapping):
        return {str(k): _clean(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_clean(v) for v in value]
    if isinstance(value, float) and not math.isfinite(value):
        return None
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    return str(value)


def _text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (dict, list, tuple)):
        return json.dumps(_clean(value), ensure_ascii=False, allow_nan=False)
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def _escape(value: Any) -> str:
    return html.escape(_text(value), quote=True)


def _csv_cell(value: Any) -> Any:
    """Neutralize spreadsheet formula injection, preserving true numeric cells.

    CSV quoting alone does not stop Excel interpreting =, +, -, @ or controls.
    A leading apostrophe forces source-controlled strings to remain text.
    """
    if value is None:
        return ""
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return value if not isinstance(value, float) or math.isfinite(value) else ""
    text = _text(value)
    stripped = text.lstrip(" \t\r\n\ufeff\x00\v\f")
    if stripped.startswith(("=", "+", "-", "@")) or text.startswith(("\t", "\r", "\n")):
        return "'" + text
    return text


def _rows(value: Any) -> list[dict[str, Any]]:
    if isinstance(value, list):
        return [dict(v) for v in value if isinstance(v, Mapping)]
    return []


def _columns(rows: list[dict[str, Any]], preferred: list[str]) -> list[str]:
    present = {str(k) for row in rows for k in row}
    ordered = [k for k in preferred if k in present]
    ordered += sorted(present - set(ordered))
    return ordered or preferred


def _native_rows(reports: Any) -> list[dict[str, Any]]:
    rows = []
    for report in _rows(reports):
        fields = report.get("summary")
        if not isinstance(fields, Mapping) or not fields:
            fields = report.get("raw_summary")
        if isinstance(fields, Mapping) and fields:
            for name, value in fields.items():
                rows.append({"format": report.get("format"), "_source": report.get("_source"),
                             "field": name, "native_value": value})
        else:
            rows.append({"format": report.get("format"), "_source": report.get("_source"),
                         "field": "摘要", "native_value": fields})
    return rows


def _write_csv(path: Path, rows: list[dict[str, Any]], columns: list[str]) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow([_csv_cell(column) for column in columns])
        for row in rows:
            writer.writerow([_csv_cell(row.get(column)) for column in columns])


def _number(value: Any) -> float | None:
    if value is None or isinstance(value, bool):
        return None
    try:
        number = float(value)
        return number if math.isfinite(number) else None
    except (ValueError, TypeError):
        return None


def _stage_label(value: Any) -> Any:
    if isinstance(value, str) and value.lower() in STAGE_LABELS:
        return f"{STAGE_LABELS[value.lower()]} ({value})"
    return value


def _display(value: Any, key: str = "") -> str:
    if value is None:
        return '<span class="missing">未提供 / 无法计算</span>'
    if isinstance(value, float):
        return _escape(f"{value:,.4f}".rstrip("0").rstrip("."))
    if isinstance(value, (dict, list)):
        return f'<pre>{_escape(json.dumps(value, ensure_ascii=False, indent=2))}</pre>'
    return _escape(_stage_label(value) if key == "stage" else value)


def _table(rows: list[dict[str, Any]], preferred: list[str], *, limit: int = 250) -> str:
    if not rows:
        return '<p class="empty">未提供可用记录；请查看数据缺项及来源说明。不会推测不存在的结果。</p>'
    columns = _columns(rows, preferred)
    head = "".join(f"<th>{_escape(LABELS.get(key, key))}</th>" for key in columns)
    body = []
    for row in rows[:limit]:
        attr = f' data-strategy="{_escape(row.get("strategy"))}"' if row.get("strategy") else ""
        cells = "".join(f"<td>{_display(row.get(key), key)}</td>" for key in columns)
        body.append(f"<tr{attr}>{cells}</tr>")
    clipped = f'<p class="muted">HTML 展示前 {limit} 行；全部 {len(rows)} 行见 CSV / analysis.json。策略筛选仅作用于已展示行。</p>' if len(rows) > limit else ""
    return f'<div class="table-wrap"><table><thead><tr>{head}</tr></thead><tbody>{"".join(body)}</tbody></table></div>{clipped}'


def _curve_rows(points: Any) -> list[dict[str, Any]]:
    result = []
    if not isinstance(points, list):
        return result
    for point in points:
        if isinstance(point, Mapping):
            result.append(dict(point))
        elif isinstance(point, (tuple, list)):
            result.append(dict(zip(("time", "balance", "equity", "drawdown"), point)))
    return result


def _line_svg(points: list[dict[str, Any]], key: str, title: str, color: str) -> str:
    values = [_number(point.get(key)) for point in points]
    finite = [value for value in values if value is not None]
    if not finite:
        suffix = "缺少净值数据，不能由余额推算，也不能据此计算净值回撤。" if key == "equity" else "缺少可用序列。"
        return f'<div class="chart"><h4>{_escape(title)}</h4><p class="empty">{suffix}</p></div>'
    width, height = 800, 250
    left, right, top, bottom = 83, 22, 22, 45
    low, high = min(finite), max(finite)
    padding = (high - low) * 0.06 or max(abs(high) * 0.02, 1.0)
    low, high = low - padding, high + padding
    x = lambda index: left + index * (width - left - right) / max(len(points) - 1, 1)
    y = lambda value: height - bottom - (value - low) * (height - top - bottom) / (high - low)
    paths, current, dots = [], [], []
    for index, value in enumerate(values):
        if value is None:
            if current:
                paths.append(" ".join(current))
                current = []
            continue
        current.append(("M" if not current else "L") + f"{x(index):.2f},{y(value):.2f}")
        timestamp = points[index].get("time", points[index].get("timestamp", index))
        # Individual points expose the exact supplied timestamp via a tooltip.
        dots.append(f'<circle cx="{x(index):.2f}" cy="{y(value):.2f}" r="2" fill="{color}"><title>{_escape(timestamp)}: {_escape(value)}</title></circle>')
    if current:
        paths.append(" ".join(current))
    grid = []
    for tick in range(5):
        value = low + tick * (high - low) / 4
        yy = y(value)
        grid.append(f'<line x1="{left}" y1="{yy:.2f}" x2="{width-right}" y2="{yy:.2f}" stroke="#e1e7ef"/><text x="{left-9}" y="{yy+4:.2f}" text-anchor="end">{value:,.2f}</text>')
    labels = []
    endpoints = ((0, "start"), (len(points) - 1, "end")) if len(points) > 1 else ((0, "start"),)
    for index, anchor in endpoints:
        timestamp = points[index].get("time", points[index].get("timestamp", index))
        labels.append(f'<text x="{x(index):.2f}" y="{height-14}" text-anchor="{anchor}">{_escape(timestamp)}</text>')
    strokes = "".join(f'<path d="{path}" fill="none" stroke="{color}" stroke-width="2"/>' for path in paths)
    return f'<div class="chart"><h4>{_escape(title)}</h4><svg viewBox="0 0 {width} {height}" role="img" aria-label="{_escape(title)}"><title>{_escape(title)}</title>{"".join(grid)}{strokes}{"".join(dots)}{"".join(labels)}</svg><p class="muted">横轴按已提供观测点顺序等距显示，非连续时长；缺值处断线。悬停查看时间与数值。</p></div>'


def _bar_svg(rows: list[dict[str, Any]], title: str, label_key: str, value_key: str = "net_profit") -> str:
    pairs = [(row, _number(row.get(value_key))) for row in rows]
    pairs = [(row, value) for row, value in pairs if value is not None]
    if not pairs:
        return f'<div class="chart"><h4>{_escape(title)}</h4><p class="empty">缺少该维度的可用数据。</p></div>'
    pairs = pairs[:60]
    width, label_width, height = 800, 220, 34 * len(pairs) + 24
    low = min(0, min(value for _, value in pairs))
    high = max(0, max(value for _, value in pairs))
    span = high - low or 1
    scale = lambda value: label_width + (value - low) / span * (width - label_width - 120)
    zero = scale(0)
    shapes = [f'<line x1="{zero:.2f}" y1="7" x2="{zero:.2f}" y2="{height-7}" stroke="#78869a"/>']
    for index, (row, value) in enumerate(pairs):
        yy = index * 34 + 10
        xx = min(zero, scale(value))
        bar_width = abs(scale(value) - zero)
        color = "#19755b" if value >= 0 else "#c34949"
        label = _text(row.get(label_key))
        shapes.append(f'<text x="8" y="{yy+17}">{_escape(label[:30])}<title>{_escape(label)}</title></text>')
        shapes.append(f'<rect x="{xx:.2f}" y="{yy}" width="{bar_width:.2f}" height="23" rx="3" fill="{color}"><title>{_escape(label)}: {_escape(value)}</title></rect>')
        shapes.append(f'<text x="{width-10}" y="{yy+17}" text-anchor="end">{value:,.2f}</text>')
    clipped = '<p class="muted">图表最多展示前 60 项，全部记录见 CSV。</p>' if len(rows) > 60 else ""
    return f'<div class="chart"><h4>{_escape(title)}</h4><svg viewBox="0 0 {width} {height}" role="img" aria-label="{_escape(title)}"><title>{_escape(title)}</title>{"".join(shapes)}</svg>{clipped}</div>'


def _charts(result: dict[str, Any]) -> str:
    curves = result.get("curves") or {}
    if not isinstance(curves, Mapping):
        curves = {}
    breakdowns = _rows(result.get("breakdowns"))
    funnel = _rows(result.get("funnel"))
    strategies = sorted({str(r.get("strategy")) for key in ("metrics", "breakdowns", "funnel") for r in _rows(result.get(key)) if r.get("strategy")} | {str(k) for k in curves})
    if not strategies:
        return '<p class="empty">没有可用于绘图的交易或诊断序列；请导入真实来源并补齐缺项。</p>'
    charts = []
    for strategy in strategies:
        points = _curve_rows(curves.get(strategy))
        direction = [row for row in breakdowns if str(row.get("strategy")) == strategy and str(row.get("dimension", "")).lower() in ("direction", "side", "buy_sell", "方向")]
        sessions = [row for row in breakdowns if str(row.get("strategy")) == strategy and str(row.get("dimension", "")).lower() in ("hour", "session", "time_of_day", "entry_hour", "hour_of_day", "时段")]
        counts = [dict(row, label=" / ".join(_text(_stage_label(row.get(key)) if key == "stage" else row.get(key)) for key in ("stage", "reason", "unit") if row.get(key))) for row in funnel if str(row.get("strategy")) == strategy]
        figures = _line_svg(points, "balance", "余额曲线", "#2870b8")
        figures += _line_svg(points, "equity", "净值曲线（仅使用已提供净值）", "#198060")
        figures += _bar_svg(direction, "多空方向净利润", "value")
        figures += _bar_svg(sessions, "时段净利润（采用清单记录的时区）", "value")
        figures += _bar_svg(counts, "诊断事件计数（不同计数单位不能直接算转化率）", "label", "count")
        charts.append(f'<article class="strategy-charts" data-strategy="{_escape(strategy)}"><h3>{_escape(strategy)}</h3><div class="chart-grid">{figures}</div></article>')
    return "".join(charts)


CSS = """
:root{color-scheme:light;--ink:#192536;--muted:#5c6b7d;--line:#dbe3ee;--blue:#205d96}
*{box-sizing:border-box}body{margin:0;background:#edf2f7;color:var(--ink);font:15px/1.65 system-ui,'Microsoft YaHei','PingFang SC',sans-serif}
main{max-width:1500px;margin:auto;padding:24px}header{padding:28px 32px;background:#183650;color:white;border-radius:14px}
h1{font-size:30px;margin:0 0 9px}h2{font-size:22px;margin:0 0 14px}h3{font-size:18px}h4{margin:0 0 8px;font-size:15px}p{margin:8px 0}
section{padding:24px;margin-top:20px;border:1px solid var(--line);border-radius:12px;background:white}a{color:#205d96;overflow-wrap:anywhere}
header a{color:#e4f0ff}.badge{display:inline-block;padding:4px 10px;margin:5px 8px 5px 0;border-radius:6px;background:#e9f2fc;color:#1b476e;font-weight:650}
.warn{padding:14px 18px;background:#fff5df;border-left:4px solid #c68b1e;color:#594216}.sample{background:#ffe6d8;color:#6b351c}.muted,.empty,.missing{color:var(--muted)}
.empty{padding:20px;border:1px dashed #becbd9;border-radius:8px;background:#f8fafc}.table-wrap{overflow-x:auto;max-height:640px}
table{border-collapse:collapse;width:100%;font-size:13px}th,td{padding:10px 12px;text-align:left;vertical-align:top;border-bottom:1px solid var(--line);min-width:105px;max-width:480px;overflow-wrap:anywhere}
th{background:#eaf0f7;position:sticky;top:0;z-index:1;white-space:nowrap}tbody tr:nth-child(even){background:#f7f9fc}
pre{white-space:pre-wrap;overflow-wrap:anywhere;font:12px/1.5 ui-monospace,Consolas,monospace;margin:0;max-height:250px;overflow:auto}
.chart-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}.chart{border:1px solid var(--line);padding:16px;border-radius:9px;min-width:0}.chart svg{width:100%;height:auto;display:block}.chart svg text{font:12px system-ui,'Microsoft YaHei',sans-serif;fill:#415268}
.toolbar{position:sticky;top:0;z-index:3;background:#f8fbff;padding:12px 18px;border-bottom:1px solid var(--line);display:flex;gap:20px;align-items:center;flex-wrap:wrap}
select{padding:7px 12px;border:1px solid #aebed0;border-radius:6px;font:inherit}.links{display:flex;gap:12px;flex-wrap:wrap}.strategy-charts{margin-bottom:22px}[hidden]{display:none!important}
@media(max-width:850px){main{padding:12px}header,section{padding:18px}.chart-grid{grid-template-columns:1fr}h1{font-size:24px}}
@media print{body{background:white}main{max-width:none;padding:0}.toolbar{position:static}.table-wrap{max-height:none;overflow:visible}section{break-inside:auto}header{background:white;color:#192536;border:1px solid #dbe3ee}.chart{break-inside:avoid}}
"""


def _data_label(metadata: Any) -> str:
    data_type = ""
    if isinstance(metadata, Mapping):
        manifest = metadata.get("manifest") if isinstance(metadata.get("manifest"), Mapping) else metadata
        data_type = _text(manifest.get("data_type") or manifest.get("dataset_type") or manifest.get("data_kind"))
    if data_type.lower() in ("synthetic", "sample", "合成示例", "演示数据"):
        return "合成示例数据｜仅验证分析器功能，不能代表 EA 收益或真实 Tick 覆盖"
    names = {"backtest": "历史回测数据", "live": "实盘历史导入（离线分析）", "demo": "模拟账户历史", "paper": "模拟账户历史", "mixed": "混合来源，须按记录分别核验"}
    return names.get(data_type.lower(), data_type or "数据类型未明确：不得默认为实盘或真实 Tick")


def _html_report(result: dict[str, Any], exports: dict[str, str], tables: dict[str, list[dict[str, Any]]]) -> str:
    metadata = result.get("metadata") or {}
    data_label = _data_label(metadata)
    strategies = sorted({str(row["strategy"]) for rows in tables.values() for row in rows if row.get("strategy")})
    options = '<option value="">全部策略</option>' + "".join(f'<option value="{_escape(strategy)}">{_escape(strategy)}</option>' for strategy in strategies)
    links = "".join(f'<a href="{_escape(Path(path).name)}">{_escape(Path(path).name)}</a>' for key, path in exports.items() if key != "report_html")
    metadata_rows = [{"field": key, "value": value} for key, value in metadata.items()] if isinstance(metadata, Mapping) else [{"field": "metadata", "value": metadata}]
    primary_fields = {"run_id", "ea_version", "broker", "symbol", "initial_capital", "account_currency", "test", "status"}
    identity_rows = [row for row in metadata_rows if row["field"] in primary_fields]
    parts = [f'<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>GSM Gold Python Analyzer · 中文分析报告</title><style>{CSS}</style></head><body><main>',
             '<header><h1>GSM Gold Python Analyzer</h1><p>离线研发分析 · MT5 黄金 EA · 可追溯证据报告</p><span class="badge">待验证基准 / 研究候选</span><p>分析器不授予 Champion 或实盘批准；交易行为与改善结论须另经同条件 MT5 真实 Tick 验证。</p></header>',
             f'<div class="toolbar"><label for="strategy-filter">查看策略 <select id="strategy-filter">{options}</select></label><span class="muted">筛选展示内容，不重新计算组合成绩。</span><a href="#candidates">下一轮改进</a><a href="#provenance">数据来源</a></div>',
             f'<section><h2>数据身份与使用范围</h2><p class="warn sample">{_escape(data_label)}</p><p>工具只读取文件，不连接实盘下单，不调用付费 AI API。数据缺项和样本不足保持“待验证”。</p><p class="muted">净利润与成本采用导入清单和分析结果中的口径；未知成本不按零处理。余额回撤与净值回撤分别展示，分策略权益归属不明时不分摊账户权益。</p>{_table(identity_rows, ["field", "value"])}<details><summary>展开完整配置、文件哈希与时间分段</summary>{_table(metadata_rows, ["field", "value"])}</details><h3>导出文件</h3><div class="links">{links}</div></section>',
             '<section id="metrics"><h2>分策略基础指标</h2><p class="muted">统计完整交易的口径与原生 MT5 Trades / Deals 可能不同；分批平仓不应重复计为完整交易。空值表示未提供、不可计算或不适用。胜率采用百分比（0—100）；成本定义以清单和指标来源说明为准。</p>' + _table(tables["metrics"], DEFAULT_COLUMNS["metrics"]) + '</section>',
             '<section id="charts"><h2>曲线与诊断图表</h2>' + _charts(result) + '</section>']
    for key in ("findings", "candidates", "funnel", "breakdowns", "coverage", "issues", "native_reports", "provenance", "trades"):
        notes = ""
        if key == "findings":
            notes = '<p class="muted">confirmed = 数据确认；hypothesis = 待验证假设；missing = 缺少证据。假设不能写成已确认的亏损原因。</p>'
        elif key == "candidates":
            notes = '<p class="muted">最多选择三个有依据的候选；每个候选相对基准只改变一个模块。验证前不能认定过滤器无效或宣布改善。</p>'
        elif key == "funnel":
            notes = '<p class="warn">成交记录本身无法还原被拦截的候选。日志事件数不一定等于唯一信号数；缺少候选 ID 或阶段日志时，不计算虚构的漏斗转化率，也不推测错失机会本可盈利。</p>'
        elif key == "native_reports":
            notes = '<p class="muted">以下保留原生摘要及来源，与自行计算的完整交易指标分开。原生余额回撤、原生净值回撤、项目净值恢复因子不可相互替换；没有净值序列时不绘制虚构净值曲线。</p>'
        parts.append(f'<section id="{key}"><h2>{SECTIONS[key]}</h2>{notes}{_table(tables[key], DEFAULT_COLUMNS[key])}</section>')
    if result.get("comparison") is not None:
        comparison = result["comparison"]
        parts.append('<section id="comparison"><h2>Candidate 与基准同条件比较</h2><p class="muted">只比较已验证一致的数据、资金、风险预算、成本和测试区间；不一致时仅展示差异，不宣布优胜。</p>' + _table([comparison] if isinstance(comparison, dict) else [{"comparison": comparison}], []) + '</section>')
    # Keep machine-readable context embedded safely even for a malicious source
    # containing </script>, U+2028, quotes, or source-controlled HTML.
    embedded = json.dumps({"metadata": metadata, "status": "待验证", "exports": {k: Path(v).name for k, v in exports.items()}}, ensure_ascii=False, allow_nan=False)
    embedded = embedded.replace("&", "\\u0026").replace("<", "\\u003c").replace(">", "\\u003e").replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
    parts.append(f'<script id="report-context" type="application/json">{embedded}</script>')
    parts.append('''<script>
"use strict";
document.getElementById("strategy-filter").addEventListener("change", function () {
  const selected = this.value;
  document.querySelectorAll("[data-strategy]").forEach(function (element) {
    element.hidden = selected !== "" && element.getAttribute("data-strategy") !== selected;
  });
});
</script><footer><p class="muted">GSM Gold Python Analyzer · 离线报告 · 保留失败和缺项 · 分析与回测均不保证未来收益或绝不爆仓</p></footer></main></body></html>''')
    return "\n".join(parts)


def write_report(result: dict, output_dir: Path | str) -> dict[str, str]:
    """Write strict analysis.json, ten CSV exports and a self-contained HTML report.

    Returns absolute paths under ``output_dir``; ``report_html`` and
    ``analysis_json`` are stable keys. Other keys use the CSV filename stem.
    All rows are exported to CSV. HTML tables show their first 250 rows.
    No writes occur outside the requested output directory.
    """
    if not isinstance(result, dict):
        raise TypeError("result 必须是分析结果字典")
    destination = Path(output_dir).expanduser().resolve()
    destination.mkdir(parents=True, exist_ok=True)
    cleaned = _clean(result)
    candidates = _rows(cleaned.get("candidates"))
    if len(candidates) > 3:
        raise ValueError("候选改进最多三项；请先在分析阶段按证据筛选")
    exports = {"report_html": str(destination / "report.html"), "analysis_json": str(destination / "analysis.json")}
    tables = {key: (_native_rows(cleaned.get(key)) if key == "native_reports" else _rows(cleaned.get(key))) for key in CSV_FILES}
    for key, filename in CSV_FILES.items():
        path = destination / filename
        rows = tables[key]
        _write_csv(path, rows, _columns(rows, DEFAULT_COLUMNS[key]))
        exports[Path(filename).stem] = str(path)
    (destination / "analysis.json").write_text(json.dumps(cleaned, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    (destination / "report.html").write_text(_html_report(cleaned, exports, tables), encoding="utf-8")
    return exports
