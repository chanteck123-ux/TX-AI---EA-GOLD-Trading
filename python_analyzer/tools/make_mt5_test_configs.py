#!/usr/bin/env python3
"""Generate paired MT5 research configurations, without running any terminal."""
from __future__ import annotations

import argparse
from datetime import date, datetime, timezone
from decimal import Decimal, InvalidOperation
import hashlib
import json
from pathlib import Path
import re
import sys

FIXED_DELAYS = (0, 10, 25, 50)
PERIODS = ("M1", "M5", "M15", "M30", "H1", "H4", "D1")
REFERENCE = "scripts/Run-Candidate.ps1 at 8326fbab6ee8beb2a0db77aa1f1663e08c4bff41"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_input(path: Path, extension: str) -> tuple[bytes, dict]:
    path = path.expanduser().resolve(strict=True)
    if path.suffix.lower() != extension or not path.is_file():
        raise ValueError(f"需要实际存在的 {extension} 文件：{path}")
    data = path.read_bytes()
    if not data:
        raise ValueError(f"输入文件不能为空：{path.name}")
    return data, {"name": path.name, "sha256": sha256(data), "bytes": len(data)}


def read_set_inputs(data: bytes) -> dict[str, str]:
    """Observe differences only; never reserialize or change the supplied SET."""
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        text = data.decode("utf-16")
    else:
        try:
            text = data.decode("utf-8-sig")
        except UnicodeError:
            return {}  # Unknown encoding is disclosed rather than guessed.
    values = {}
    for line in text.splitlines():
        if line.startswith("Inp") and "=" in line:
            key, value = line.split("=", 1)
            values[key] = value.split("||", 1)[0]
    return values


def display_parameter_value(key: str, value: str | None) -> str | None:
    if value is not None and re.search(
            r"password|passwd|secret|token|api.?key|licen[cs]e|credential|account.?(?:number|login|id)|^InpLogin$",
            key, re.IGNORECASE):
        return "<REDACTED_CREDENTIAL_VALUE>"
    return value


def make_ini(role: str, label: str, common: dict) -> bytes:
    expert = f"GSMAnalyzer\\{label}\\{role}.ex5"
    parameter_file = f"GSMAnalyzer_{label}_{role}.set"
    lines = [
        "[Experts]", "AllowLiveTrading=0", "AllowDllImport=0", "Enabled=0",
        "[StartUp]", "Expert=", "Script=", "[Tester]",
        f"Expert={expert}", f"ExpertParameters={parameter_file}",
        f"Symbol={common['symbol']}", f"Period={common['period']}",
        "Model=4", f"ExecutionMode={common['fixed_delay_ms']}", "Optimization=0",
        f"FromDate={common['from_date_ini']}", f"ToDate={common['to_date_ini']}",
        "ForwardMode=0", f"Deposit={common['deposit_usd']}", "Currency=USD",
        f"Leverage={common['leverage']}", f"Report=GSMAnalyzer_{label}_{role}.htm",
        "ReplaceReport=0", "ShutdownTerminal=1", "Visual=0",
        "UseLocal=1", "UseRemote=0", "UseCloud=0", "",
    ]
    return "\r\n".join(lines).encode("utf-8")


def generate_configs(*, baseline_set: Path, candidate_set: Path, baseline_ex5: Path,
                     candidate_ex5: Path, output_dir: Path, run_label: str, symbol: str,
                     from_date: str, end_exclusive: str, deposit: str = "2000",
                     leverage: int = 100, period: str = "M5", delay_ms: int = 0,
                     server_timezone: str = "UNKNOWN", cost_assumptions: str = "UNKNOWN",
                     baseline_source: Path | None = None,
                     candidate_source: Path | None = None) -> dict:
    if not re.fullmatch(r"[A-Za-z0-9_]{1,64}", run_label):
        raise ValueError("run-label 只允许 1–64 个英文字母、数字或下划线。")
    if not re.fullmatch(r"[A-Za-z0-9_.#-]{1,64}", symbol) or not any(
            token in symbol.upper() for token in ("GOLD", "XAUUSD")):
        raise ValueError("symbol 必须是明确提供的黄金/USD 品种别名，如 GOLD 或 XAUUSD。")
    if period not in PERIODS or delay_ms not in FIXED_DELAYS:
        raise ValueError("不支持的周期或固定延迟；本工具仅生成 0/10/25/50 ms。")
    if not isinstance(leverage, int) or isinstance(leverage, bool) or not 1 <= leverage <= 10000:
        raise ValueError("杠杆必须为实际终端支持的正整数，工具范围 1–10000。")
    try:
        capital = Decimal(str(deposit))
    except InvalidOperation as exc:
        raise ValueError("资金必须为有效数值。") from exc
    if not capital.is_finite() or capital <= 0:
        raise ValueError("资金必须为有限正数。")
    start, end = date.fromisoformat(from_date), date.fromisoformat(end_exclusive)
    if start >= end:
        raise ValueError("日期必须满足开始日 < 排他结束日。")
    output_dir = output_dir.expanduser().resolve()
    if output_dir.exists():
        raise ValueError("输出目录已存在，拒绝覆盖；请使用全新目录。")
    common = {
        "broker_target": "FxPro", "symbol": symbol, "period": period,
        "deposit_usd": format(capital, "f"), "leverage": leverage,
        "fixed_delay_ms": delay_ms, "delay_mode": "FIXED_MILLISECONDS",
        "tester_model": 4, "currency": "USD",
        "from_date_ini": start.strftime("%Y.%m.%d"),
        "to_date_ini": end.strftime("%Y.%m.%d"),
        "analysis_interval": {"start_inclusive": start.isoformat(), "end_exclusive": end.isoformat()},
        "server_timezone_declared": server_timezone, "cost_assumptions_declared": cost_assumptions,
    }
    files: dict[str, bytes] = {}
    inputs, parameter_sets = {}, {}
    for role, set_path, ex5_path, source_path in (
        ("baseline", baseline_set, baseline_ex5, baseline_source),
        ("candidate", candidate_set, candidate_ex5, candidate_source),
    ):
        set_data, set_meta = read_input(set_path, ".set")
        ex5_data, ex5_meta = read_input(ex5_path, ".ex5")
        parameter_sets[role] = read_set_inputs(set_data)
        inputs[role] = {"set": set_meta, "ex5": ex5_meta,
                        "binary_validation": "EXISTING_FILE_HASHED_NOT_COMPILE_PROOF"}
        if source_path is not None:
            _, inputs[role]["source"] = read_input(source_path, ".mq5")
        files[f"MQL5/Experts/GSMAnalyzer/{run_label}/{role}.ex5"] = ex5_data
        files[f"MQL5/Profiles/Tester/GSMAnalyzer_{run_label}_{role}.set"] = set_data
        files[f"{role}.ini"] = make_ini(role, run_label, common)
    keys = sorted(set(parameter_sets["baseline"]) | set(parameter_sets["candidate"]))
    diffs = [{"parameter": key, "baseline": display_parameter_value(key, parameter_sets["baseline"].get(key)),
              "candidate": display_parameter_value(key, parameter_sets["candidate"].get(key))}
             for key in keys if parameter_sets["baseline"].get(key) != parameter_sets["candidate"].get(key)]
    manifest = {
        "schema_version": 1, "tool": "GSM Gold Python Analyzer MT5 config generator",
        "created_at_utc": datetime.now(timezone.utc).isoformat(), "run_label": run_label,
        "status": "GENERATED_NOT_RUN_PENDING_NATIVE_MT5_VALIDATION",
        "configuration_reference": REFERENCE, "common_conditions": common, "inputs": inputs,
        "set_parameter_differences": diffs,
        "set_parse_status": {key: "PARSED_INPUT_VALUES_ONLY" if value else "UNKNOWN_OR_NO_INPUT_VALUES"
                             for key, value in parameter_sets.items()},
        "source_binary_correspondence": "UNVERIFIED_REQUIRES_MATCHING_COMPILE_LOG_AND_DEPENDENCY_HASHES",
        "risk_budget_parity": "UNVERIFIED_CHECK_ACTUAL_SETS_AND_EA_BEFORE_RUN",
        "cost_parity": "UNVERIFIED_CHECK_BROKER_TERMINAL_AND_EA_BEFORE_RUN",
        "tick_coverage": "UNVERIFIED_MODEL_4_SETTING_IS_NOT_COVERAGE_EVIDENCE",
        "date_boundary": "INI dates written literally; verify actual tester boundaries and warm-up in native logs",
        "champion_status": "BASELINE_PENDING_VALIDATION",
        "terminal_started": False, "original_inputs_modified": False,
        "native_random_delay": "NOT_GENERATED_SELECT_NATIVE_RANDOM_IN_GUI_SAVE_SEPARATE_CONFIG_AND_HASH",
        "warnings": [
            "EX5 existence and hash do not prove a valid compilation or its source version.",
            "SET bytes are unchanged; run-label/file-export names inside SET may collide. Archive first run exports before the second.",
            "Account costs, contract, Hedging mode and actual risk budgets cannot be guaranteed by these INIs.",
            "Final OOS must be frozen and preregistered separately; these configs do not certify an untouched interval.",
        ],
    }
    instructions = (
        "# MT5 待验证测试包\n\n"
        "此包只生成配置，未编译、未运行、未连接账户、未发单。\n\n"
        f"批次：`{run_label}`；黄金品种：`{symbol}`；固定延迟：`{delay_ms} ms`。\n\n"
        "1. 先阅读项目 `docs/MT5_TESTING_CN.md`，核实同一隔离 FxPro 测试终端、合约、费用、实际风险预算、Hedging 模式及真实 Tick 覆盖。\n"
        "2. 确认真实 MetaEditor 编译证据与两份 EX5/源文件/依赖哈希一致；本工具仅证明文件实际存在及字节哈希。\n"
        "3. 将此包 MQL5 下的四个文件按相对目录复制到隔离终端的数据目录；先检查目的路径均不存在，禁止覆盖。\n"
        "4. 按测试说明手动运行 baseline.ini，保存全部报告、原生日志、公共目录导出和终端哈希后，再手动运行 candidate.ini。\n"
        "5. SET 原样保留，原 SET 内日志/CSV 文件名可能相同；必须在两次运行之间归档，不能把后一次覆盖的文件当作前一次证据。\n"
        "6. 两个 INI 使用相同外部条件。费用、风险预算、行情数据及日期边界仍须核实；通过校验前不能宣布 Candidate 胜出或 PASS。\n\n"
        "Windows PowerShell 手动执行示例（先替换为实际隔离测试路径，每次只运行一份）：\n\n"
        "```powershell\n"
        "$terminalRoot = 'C:\\MT5-FxPro-Research'\n"
        "$packageRoot = 'C:\\Research\\current_test_package'\n"
        "& (Join-Path $terminalRoot 'terminal64.exe') /portable ('/config:' + (Join-Path $packageRoot 'baseline.ini'))\n"
        "# 等终端完全退出并归档结果后，再执行下一行。\n"
        "& (Join-Path $terminalRoot 'terminal64.exe') /portable ('/config:' + (Join-Path $packageRoot 'candidate.ini'))\n"
        "```\n"
    )
    files["RUN_IN_MT5_CN.md"] = instructions.encode("utf-8")
    manifest["files"] = {name: sha256(data) for name, data in sorted(files.items())}
    files["test_manifest.json"] = (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    output_dir.mkdir(parents=True, exist_ok=False)
    for relative, data in files.items():
        target = output_dir / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("xb") as handle:
            handle.write(data)
    return manifest


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="仅生成基准/Candidate 配对 MT5 配置，不编译、不启动 MT5。")
    for role in ("baseline", "candidate"):
        parser.add_argument(f"--{role}-set", type=Path, required=True)
        parser.add_argument(f"--{role}-ex5", type=Path, required=True)
        parser.add_argument(f"--{role}-source", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--run-label", required=True)
    parser.add_argument("--symbol", required=True)
    parser.add_argument("--from-date", required=True, help="包含开始日，YYYY-MM-DD")
    parser.add_argument("--end-exclusive", required=True, help="不包含的结束日，YYYY-MM-DD")
    parser.add_argument("--deposit", default="2000")
    parser.add_argument("--leverage", type=int, default=100)
    parser.add_argument("--period", choices=PERIODS, default="M5")
    parser.add_argument("--delay-ms", type=int, choices=FIXED_DELAYS, default=0)
    parser.add_argument("--server-timezone", default="UNKNOWN")
    parser.add_argument("--cost-assumptions", default="UNKNOWN")
    try:
        args = parser.parse_args(argv)
        manifest = generate_configs(**vars(args))
    except (OSError, ValueError, UnicodeError) as exc:
        print(f"生成失败：{exc}", file=sys.stderr)
        return 2
    print(f"已生成两组待验证配置：{args.output_dir.resolve()}")
    print(f"状态：{manifest['status']}；未启动 MT5。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
