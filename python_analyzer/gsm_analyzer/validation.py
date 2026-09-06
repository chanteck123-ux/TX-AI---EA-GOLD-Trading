"""Check observed records after import and before computing research results.

This check detects falsely declared windows; it does not physically isolate a
holdout because input files have already been read. Split files externally before
import and keep the pre-read final-exposure guard. Never filter a bad window into
an apparently better result. Unknown timezone relationships stay unverified.
"""
from __future__ import annotations

from datetime import timedelta
import re

from .analytics import moment
from .ingest import _number, _offset


def _issue(dataset, code, message, record=None, severity="warning"):
    item = {"severity": severity, "code": code, "message": message}
    if record:
        item.update(source=record.get("_source", "unknown"), row=record.get("_row", "unknown"))
    if item not in dataset.setdefault("issues", []):
        dataset["issues"].append(item)


def _location(kind, record, field=""):
    return f"kind={kind} source={record.get('_source', 'unknown')} row={record.get('_row', 'unknown')} field={field}"


def _boundary(value, zone):
    stamp = moment(value)
    offset = _offset(zone)
    if stamp and stamp.tzinfo is None and offset is not None:
        stamp = stamp.replace(tzinfo=offset)
    return stamp


def _window(dataset, entry, label):
    manifest = dataset["manifest"]
    start = _boundary(entry.get("start"), manifest.get("timezone"))
    end = _boundary(entry.get("end"), manifest.get("timezone"))
    if start is None or end is None:
        _issue(dataset, "OBSERVED_WINDOW_UNDECLARED", f"{label} 缺少完整有效 start/end，实际时间范围未核实。")
        return None
    try:
        if start >= end:
            raise ValueError(f"INVALID_OBSERVED_WINDOW：{label} 必须 start < end，采用 [start,end)。")
    except TypeError:
        _issue(dataset, "OBSERVED_WINDOW_TIMEZONE_UNVERIFIED", f"{label} 边界时区不一致，未虚构偏移。")
        return None
    return start, end


def _same_naive_clock(manifest, record):
    """Unknown but identical source clock labels can be compared as wall clocks."""
    source = str(record.get("_source", "")).replace("\\", "/")
    main = manifest.get("timezone")
    for item in manifest.get("inputs", []):
        path = str(item.get("path", "")).replace("\\", "/")
        if path and (source == path or source.endswith("/" + path)):
            return item.get("timezone", main) == main
    return True


def _comparable(stamp, window, manifest, record):
    start, end = window
    if (stamp.tzinfo is None) != (start.tzinfo is None):
        return False
    if (stamp.tzinfo is None) != (end.tzinfo is None):
        return False
    return stamp.tzinfo is not None or _same_naive_clock(manifest, record)


def _bar_end(record, manifest):
    start = moment(record.get("time"))
    text = str(record.get("timeframe") or manifest.get("bar_timeframe") or "").upper().replace("PERIOD_", "")
    match = re.fullmatch(r"([MHDW])(\d+)", text)
    if start and match and int(match[2]) > 0:
        return start + timedelta(minutes=int(match[2]) * {"M": 1, "H": 60, "D": 1440, "W": 10080}[match[1]])
    return None


def _clocks(kind, record, manifest):
    fields = ("time_open", "time_close") if kind == "trades" else ("time",)
    clocks = [(field, moment(record.get(field))) for field in fields]
    if kind == "bars":
        for field in ("time_close", "available_at"):
            if record.get(field) not in (None, ""):
                clocks.append((field, moment(record[field])))
        # Even a falsely early explicit availability cannot hide the natural end.
        inferred = _bar_end(record, manifest)
        if inferred is not None:
            clocks.append(("timeframe_close", inferred))
    return clocks


def _native_conditions(dataset):
    manifest = dataset["manifest"]
    expected_symbol = manifest.get("symbol")
    aliases = manifest.get("symbol_aliases", [])
    allowed = set(aliases if isinstance(aliases, list) else aliases.keys()) | {expected_symbol}
    expected_capital = _number(manifest.get("initial_capital"))
    symbol_keys = {"symbol", "交易品种", "品种"}
    capital_keys = {"initialdeposit", "initialcapital", "初始入金", "初始资金", "初始本金"}
    for report in dataset.get("reports", []):
        for key, raw in report.get("raw_summary", {}).items():
            normalized = re.sub(r"[\s_:：]+", "", str(key)).casefold()
            if normalized in symbol_keys and expected_symbol and raw not in (None, ""):
                actual = str(raw).strip()
                if _number(actual) is not None:
                    _issue(dataset, "NATIVE_SYMBOL_UNVERIFIED", "报告品种字段是数字，可能为品种数量；未猜测实际代码。", report)
                elif actual not in allowed:
                    raise ValueError(f"NATIVE_SYMBOL_MISMATCH：{_location('reports', report, key)} actual={actual!r} manifest={expected_symbol!r}")
            if normalized in capital_keys and expected_capital is not None:
                actual = _number(raw)
                if actual is None:
                    _issue(dataset, "NATIVE_INITIAL_CAPITAL_UNVERIFIED", "报告初始资金无法解析，未猜测数值格式。", report)
                elif abs(actual - expected_capital) > 0.005:
                    raise ValueError(f"NATIVE_INITIAL_CAPITAL_MISMATCH：{_location('reports', report, key)} actual={actual} manifest={expected_capital}")


def check_observed_window(dataset, allow_final=False):
    """Raise on an observed contradiction; return the original, unfiltered data.

    Naive timestamps in the same declared server clock support only a local-clock
    window check. Aware/naive or different unknown-clock mismatches add issues;
    with a registered locked final window, unresolved alignment fails closed.
    ``allow_final`` authorizes this check only; the caller still must perform its
    freeze/provenance/exposure-ledger checks before opening final input files.
    """
    manifest = dataset["manifest"]
    _native_conditions(dataset)
    window = _window(dataset, manifest.get("test") or {}, "test")
    registered_final = [entry for entry in manifest.get("splits", []) if entry.get("name") == "final"]
    if len(registered_final) > 1:
        raise ValueError("INVALID_FINAL_WINDOW：不能登记多个 final 区间。")
    final = _window(dataset, registered_final[0], "final") if registered_final else None
    if registered_final and final is None and not allow_final:
        raise ValueError("FINAL_TIMEZONE_OR_WINDOW_UNVERIFIED：无法核实最终区间边界，拒绝分析已读取记录。")
    if manifest.get("segment") == "final" and not allow_final:
        raise ValueError("FINAL_DATA_LOCKED_OBSERVED：最终区间没有显式授权，拒绝分析。")
    count = 0
    for kind in ("trades", "deals", "events", "funnel", "equity", "ticks", "bars"):
        for record in dataset.get(kind, []):
            clocks = _clocks(kind, record, manifest)
            # Check the holdout before test-window validation. A forged development
            # label or a smaller declared test window does not hide final records.
            if final is not None and not allow_final:
                for field, stamp in clocks:
                    if stamp is None or not _comparable(stamp, final, manifest, record):
                        _issue(dataset, "FINAL_TIMEZONE_UNVERIFIED", "实际记录时间/时区无法与 final 对齐，不能排除最终数据曝光。", record)
                        raise ValueError(f"FINAL_TIMEZONE_UNVERIFIED：{_location(kind, record, field)}；先外部分文件并核实来源时区。")
                    closes_before_final = (kind == "bars" and field != "time" and
                                           stamp == final[0] and moment(record.get("time")) < final[0])
                    if final[0] <= stamp < final[1] and not closes_before_final:
                        raise ValueError(f"FINAL_DATA_LOCKED_OBSERVED：{_location(kind, record, field)} time={stamp.isoformat()}；实际记录落入已登记 final。")
                if kind == "trades" and len(clocks) == 2 and clocks[0][1] < final[1] and clocks[1][1] >= final[0]:
                    raise ValueError(f"FINAL_DATA_LOCKED_OBSERVED：{_location(kind, record)}；持仓期间跨入 final。")
                if kind == "bars" and clocks[0][1] < final[1] and any(
                        field != "time" and stamp > final[0] for field, stamp in clocks):
                    raise ValueError(f"FINAL_DATA_LOCKED_OBSERVED：{_location(kind, record)}；K线覆盖或可用信息跨入 final，非恰好在边界收盘的上一根。")
            for field, stamp in clocks:
                if stamp is None:
                    _issue(dataset, "OBSERVED_RECORD_TIME_UNVERIFIED", f"{kind}.{field} 没有有效时间，无法完整核验范围。", record)
                    continue
                count += 1
                if window is None:
                    continue
                if not _comparable(stamp, window, manifest, record):
                    _issue(dataset, "OBSERVED_WINDOW_TIMEZONE_UNVERIFIED", f"{kind}.{field} 与 test 的时区不一致，时间范围未核实；未虚构偏移。", record)
                    continue
                # A bar opening before end and closing exactly at end contains
                # only [open,end) observations. Its close/availability timestamp
                # marks completion, not an observation from the next interval.
                is_bar_completion = kind == "bars" and field != "time"
                outside = (stamp > window[1] if is_bar_completion else stamp >= window[1]) or (kind != "bars" and stamp < window[0])
                if outside:
                    raise ValueError(f"OBSERVED_TIME_OUTSIDE_TEST：{_location(kind, record, field)} time={stamp.isoformat()} declared=[{window[0].isoformat()},{window[1].isoformat()})；未筛掉越界记录。")
                if kind == "bars" and field == "available_at" and stamp == window[1]:
                    _issue(dataset, "BAR_AVAILABLE_AT_TEST_END", "上一根K线在窗口结束时才可用；允许完整行情记录，但不能把其收盘信息用于更早进场。", record)
            if kind == "bars" and not any(field != "time" and stamp is not None for field, stamp in clocks):
                _issue(dataset, "BAR_CLOSE_WINDOW_UNVERIFIED", "K线缺收盘/可用时点及可识别周期，不能完整核实尾部未来信息。", record)
                if final is not None and not allow_final:
                    raise ValueError(f"FINAL_BAR_AVAILABILITY_UNVERIFIED：{_location(kind, record)}；无法排除K线已包含最终段信息。")
    if window is not None and window[0].tzinfo is None:
        _issue(dataset, "OBSERVED_WINDOW_LOCAL_CLOCK_ONLY", "仅按相同声明的服务器本地时钟核对窗口；绝对时区/DST未核实。")
    _issue(dataset, "OBSERVED_WINDOW_POST_READ_CHECK", f"已检查导入后的 {count} 个时间字段；这是分析前核验，不是读取前物理隔离，最终样本需预先外部分文件。", severity="info")
    return dataset
