"""Frozen temporal partitions and conservative baseline/candidate comparison."""
from __future__ import annotations

import hashlib
import json
import math
import re
from pathlib import Path

from .analytics import moment, number


def canonical_hash(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False, allow_nan=False).encode("utf-8")).hexdigest()


def valid_sha(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-fA-F]{64}", value) is not None


def _has_unknown(value):
    """Matching placeholders do not establish matching known conditions."""
    if value is None:
        return True
    if isinstance(value, str):
        return value.strip().casefold() in {
            "", "unknown", "server_unknown", "unverified", "unconfirmed", "n/a", "none", "null",
            "未知", "未提供", "待核实", "待确认",
        }
    if isinstance(value, dict):
        return not value or any(_has_unknown(item) for item in value.values())
    if isinstance(value, (list, tuple)):
        return not value or any(_has_unknown(item) for item in value)
    return isinstance(value, float) and not math.isfinite(value)


def _test_window(manifest):
    window = manifest.get("test")
    if not isinstance(window, dict):
        raise ValueError("INVALID_TEST_WINDOW：必须声明test.start/end。")
    start, end = moment(window.get("start")), moment(window.get("end"))
    if not start or not end:
        raise ValueError("INVALID_TEST_WINDOW：test.start/end必须为有效时间。")
    try:
        if start >= end:
            raise ValueError("INVALID_TEST_WINDOW：必须start < end，采用[start,end)。")
    except TypeError as exc:
        raise ValueError("TEST_TIMEZONE_MISMATCH：测试起止时区不一致。") from exc
    return start, end


def validate_splits(manifest):
    windows = manifest.get("splits", [])
    if not isinstance(windows, list):
        raise ValueError("INVALID_SPLIT：splits必须为区间列表。")
    parsed = []
    seen = set()
    for window in windows:
        if not isinstance(window, dict):
            raise ValueError("INVALID_SPLIT：每段必须含name/start/end。")
        name = window.get("name")
        start, end = moment(window.get("start")), moment(window.get("end"))
        if name not in ("development", "validation", "final") or name in seen or not start or not end:
            raise ValueError("INVALID_SPLIT：分段名称需唯一且为development/validation/final，时间必须完整。")
        try:
            if start >= end:
                raise ValueError("INVALID_SPLIT：必须start < end，采用[start,end)。")
        except TypeError as exc:
            raise ValueError("SPLIT_TIMEZONE_MISMATCH：分段时区不一致。") from exc
        seen.add(name)
        parsed.append((start, end, name))
    try:
        parsed.sort()
        for left,right in zip(parsed,parsed[1:]):
            if left[1] > right[0]:
                raise ValueError("SPLIT_OVERLAP：开发、验证、最终样本外不可重叠。")
        order = {"development": 0, "validation": 1, "final": 2}
        if [order[w[2]] for w in parsed] != sorted(order[w[2]] for w in parsed):
            raise ValueError("SPLIT_ORDER：开发、验证、最终样本外须按时间排列。")
    except TypeError as exc:
        raise ValueError("SPLIT_TIMEZONE_MISMATCH：不能混排有/无时区时间。") from exc
    return parsed


def annotate_splits(result):
    windows = validate_splits(result["metadata"])
    for trade in result["trades"]:
        start, end = moment(trade.get("time_open")), moment(trade.get("time_close"))
        trade["segment"] = "UNREGISTERED"
        if not windows or not start or not end:
            continue
        for left,right,name in windows:
            try:
                contained = left <= start < right and left <= end < right
                crosses = start < right and end >= right and end >= left
            except TypeError:
                trade["segment"] = "TIMEZONE_UNKNOWN"
                break
            if contained:
                trade["segment"] = name
                break
            if crosses:
                trade["segment"] = "CROSSES_BOUNDARY_NOT_IN_OOS_SAMPLE"
    result["metadata"]["split_note"] = "半开区间；跨边界完整仓不用于某段样本凑数；历史已阅区间不可重命名为盲测。"
    return result


def guard_final(manifest, manifest_path, allow_final):
    """Record deliberate final-data exposure. This is an audit aid, not DRM."""
    parsed = validate_splits(manifest)
    final_window = next(((left, right) for left, right, name in parsed if name == "final"), None)
    final_start = final_window[0] if final_window else None
    test = manifest.get("test")
    test_end = moment(test.get("end")) if isinstance(test, dict) else None
    touches_final = manifest.get("segment") == "final"
    if final_start and test_end:
        try:
            touches_final |= test_end > final_start
        except TypeError as exc:
            raise ValueError("FINAL_TIMEZONE_UNKNOWN：无法确认测试区间是否触及最终段。") from exc
    if not touches_final:
        return None
    if not allow_final:
        raise ValueError("FINAL_DATA_LOCKED：最终区间默认不读取；候选冻结后才可显式使用 --allow-final。")
    test_start, test_end = _test_window(manifest)
    if final_window is None:
        raise ValueError("FINAL_WINDOW_UNREGISTERED：必须先预登记final半开区间。")
    if (test_start, test_end) != final_window:
        raise ValueError("FINAL_WINDOW_MISMATCH：test.start/end必须与预登记final区间完全匹配，不混入训练或截取最终样本。")
    if not valid_sha(manifest.get("market_data_sha256")):
        raise ValueError("FINAL_MARKET_HASH_INVALID：最终段需有效的市场数据SHA256指纹。")
    if manifest.get("prior_use", "unknown") != "unseen":
        raise ValueError("FINAL_ALREADY_USED：最终段需明确prior_use=unseen，已阅资料不能再次用于最终验证。")
    experiment = manifest.get("experiment")
    frozen = experiment.get("frozen_at") if isinstance(experiment, dict) else None
    frozen_at = moment(frozen)
    if not frozen_at or not (valid_sha(manifest.get("ea_sha256")) and valid_sha(manifest.get("set_sha256"))):
        raise ValueError("CANDIDATE_NOT_FROZEN：读取最终段前需源码/参数SHA256及experiment.frozen_at。")
    try:
        if frozen_at > final_start:
            raise ValueError("LATE_FREEZE：冻结时间晚于预登记最终段开始。")
    except TypeError as exc:
        raise ValueError("FREEZE_TIMEZONE_MISMATCH") from exc
    parent = Path(manifest_path).resolve().parent
    ledger = parent / "final_exposure_ledger.jsonl"
    identity = canonical_hash({"symbol": manifest.get("symbol"), "broker": manifest.get("broker"),
                               "data": manifest.get("market_data_sha256"), "test": manifest.get("test"), "splits": manifest.get("splits")})
    if ledger.exists():
        for line in ledger.read_text(encoding="utf-8").splitlines():
            if line.strip() and json.loads(line).get("exposure_id") == identity:
                raise ValueError("FINAL_REUSE_BLOCKED：此最终区间已记录曝光；查看已有输出，不重复调参评估。")
    # Reserve before reading; an interrupted read still counts as possible exposure.
    with ledger.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps({"exposure_id": identity, "run_id": manifest.get("run_id"), "manifest_sha256": canonical_hash(manifest),
                                 "frozen_at": frozen, "status": "EXPOSURE_RESERVED"}, ensure_ascii=False)+"\n")
    return str(ledger)


def compare_results(baseline, candidate):
    left, right = baseline["metadata"], candidate["metadata"]
    required = ("broker", "symbol", "timezone", "account_currency", "initial_capital", "data_type", "strategy_scope",
                "risk", "costs", "contract", "test", "market_data_sha256", "splits", "segment")
    differences, missing = [], []
    for label, result in (("baseline", baseline), ("candidate", candidate)):
        if any(row.get("severity") == "error" or row.get("code") in (
                   "NATIVE_NET_MISMATCH", "OBSERVED_WINDOW_TIMEZONE_UNVERIFIED",
                   "OBSERVED_WINDOW_UNDECLARED", "OBSERVED_RECORD_TIME_UNVERIFIED")
               for row in result.get("issues", [])):
            missing.append(label + ".unresolved_data_errors")
    for key in required:
        a,b = left.get(key), right.get(key)
        if _has_unknown(a) or _has_unknown(b):
            missing.append(key)
        if a != b:
            differences.append(key)
    for meta in (left, right):
        capital = number(meta.get("initial_capital"))
        if isinstance(meta.get("initial_capital"), bool) or capital is None or capital <= 0:
            missing.append("initial_capital")
        for key in ("risk", "costs", "contract", "test"):
            if not isinstance(meta.get(key), dict):
                missing.append(key)
        try:
            _test_window(meta)
        except ValueError:
            missing.append("test")
        try:
            if not validate_splits(meta):
                missing.append("splits")
        except ValueError:
            missing.append("splits")
    for key in ("ea_sha256", "set_sha256", "market_data_sha256"):
        if not valid_sha(left.get(key)) or not valid_sha(right.get(key)):
            missing.append(key)
    experiment = right.get("experiment")
    experiment = experiment if isinstance(experiment, dict) else {}
    modules = experiment.get("changed_modules", [])
    if not isinstance(modules, list) or len(modules) != 1 or not isinstance(modules[0], str) or not modules[0].strip():
        missing.append("exactly_one_changed_module")
    for field,key in (("baseline_ea_sha256", "ea_sha256"), ("baseline_set_sha256", "set_sha256")):
        if experiment.get(field) != left.get(key) or not experiment.get(field):
            differences.append(field)
    compatible = not differences and not missing
    deltas = []
    by_strategy = {m["strategy"]: m for m in candidate["metrics"]}
    for a in baseline["metrics"]:
        b = by_strategy.get(a["strategy"], {})
        row = {"strategy": a["strategy"]}
        for key in ("net_profit", "win_rate", "profit_factor", "complete_trades", "equity_dd_pct", "expected_payoff"):
            av,bv = number(a.get(key)), number(b.get(key))
            row[key+"_baseline"] = av
            row[key+"_candidate"] = bv
            row[key+"_delta"] = bv-av if av is not None and bv is not None else None
        row["interpretation"] = "同条件描述差异，仍须MT5确认" if compatible else "条件不足/不一致，差值仅供核对，不得归因于改进"
        deltas.append(row)
    return {"status": "CONDITIONS_MATCH_MT5_VERIFICATION_PENDING" if compatible else "NOT_COMPARABLE",
            "same_conditions": compatible, "different_fields": differences, "missing_fields": sorted(set(missing)),
            "deltas": deltas, "verdict": "待验证；Python不宣布PASS或Champion",
            "notes": "条件一致仅依赖所提供元数据与数据指纹；不能替代检查真实回测配置和市场数据原件。"}
