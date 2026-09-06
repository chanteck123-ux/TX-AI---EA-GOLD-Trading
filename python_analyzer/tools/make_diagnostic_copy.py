#!/usr/bin/env python3
"""Build a separate, hash-pinned MQL5 observation copy; never compile or trade."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

SOURCE_COMMIT = "8326fbab6ee8beb2a0db77aa1f1663e08c4bff41"
SOURCE_SHA256 = "554b61976a0b04a152c22b33767d264d4b42925b02375702bf69608326946185"
DEPENDENCY_SHA256 = {
    "StrictRiskResearch.mqh": "efef850586c4019f893a1f83a24c390f7049c93ed48d315fd81a0703368fd6b2",
    "IntradayRunner.mqh": "945608f6ab895e422a51bd8243eddb211c5cc1032ea0bc2a007af7b92b36f9f9",
    "StudyEvidence.mqh": "7972469f2e73cab8cb6dc09453cf0adbe667f376504cd7627a5ac0cb344bfb10",
    "FeeRiskMath.mqh": "90e6d9d521c2ba62982d2b219f817cf0b8228d5012eab88d4791a8a668427482",
    "RunnerRules.mqh": "02dc48d5ce9dd5341993ad7744469dea57964f8d3b5f35d07cd6658954f1bdd1",
    "RiskMath.mqh": "e3f453fc321f5ebdffbdab9061c6380f93f4b100aa5689444ccd48eb5a289e22",
}
MARKER = "GSM_ANALYZER_DIAGNOSTIC_COPY_V1"
OUTPUT_NAME = "GSM_FxPro_RESEARCH_ANALYZER.mq5"
INCLUDE_ANCHOR = '#include <Trade/Trade.mqh>\n'
FILTER_ANCHOR = (
    "void PrintFilterAudit(StrategyId strategy,int direction,string zoneId,bool rawCore,bool indicatorPassed,\n"
    "                      bool macdPassed,bool confidencePassed,bool gatePassed,bool finalAccepted,string reason)\n{\n"
)
TICK_ANCHOR = "void OnTick()\n{\n"
INSERTIONS = {
    INCLUDE_ANCHOR: f'// {MARKER}\n#include "AnalyzerDiagnostics.mqh"\n',
    FILTER_ANCHOR: (
        "   AnalyzerObserveFilter(InpAuditRunLabel,g_runtime[(int)strategy].name,\n"
        "                         DirectionName(direction),zoneId,rawCore,indicatorPassed,\n"
        "                         macdPassed,confidencePassed,gatePassed,finalAccepted,reason,\n"
        '                         (strategy==STRATEGY_SCALPING?"PRE_REQUEST_FILTER":"FILTER_OR_ORDER_RESULT"));\n'
    ),
    TICK_ANCHOR: "   AnalyzerObserveAccount(InpAuditRunLabel,g_symbol);\n",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def inject_observers(source: str) -> str:
    """Insert calls at unique complete function anchors, preserving all old text."""
    if MARKER in source or '#include "AnalyzerDiagnostics.mqh"' in source:
        raise ValueError("源文件已经注入 Analyzer，拒绝重复处理。")
    for anchor in INSERTIONS:
        if source.count(anchor) != 1:
            raise ValueError(f"函数/包含锚点必须唯一且完整匹配：{anchor.splitlines()[0]}")
    result = source
    for anchor, addition in INSERTIONS.items():
        result = result.replace(anchor, anchor + addition, 1)
    # Removing our additions must restore the complete original byte sequence.
    restored = result
    for anchor, addition in INSERTIONS.items():
        restored = restored.replace(anchor + addition, anchor, 1)
    if restored != source:
        raise ValueError("原文保留校验失败，未生成文件。")
    return result


def collect_dependencies(source: Path, raw_source: bytes) -> dict[str, bytes]:
    """Copy only the reviewed local include closure, validating every full hash."""
    result: dict[str, bytes] = {}
    pending = [raw_source]
    while pending:
        content = pending.pop().decode("utf-8")
        for name in re.findall(r'^\s*#include\s+"([^"\r\n]+)"', content, re.MULTILINE):
            if name not in DEPENDENCY_SHA256 or Path(name).name != name:
                raise ValueError(f"未核实的本地依赖，停止生成：{name}")
            if name in result:
                continue
            path = source.parent / name
            if not path.is_file() or path.is_symlink():
                raise ValueError(f"依赖缺失或为符号链接：{name}")
            raw = path.read_bytes()
            if sha256(raw) != DEPENDENCY_SHA256[name]:
                raise ValueError(f"依赖 SHA256 不匹配：{name}")
            result[name] = raw
            pending.append(raw)
    if set(result) != set(DEPENDENCY_SHA256):
        raise ValueError("实际依赖闭包与已审阅清单不符。")
    return result


def build_copy(source: Path, output_dir: Path, expected_sha256: str = SOURCE_SHA256) -> dict:
    source = source.expanduser().resolve(strict=True)
    output_dir = output_dir.expanduser().resolve()
    if expected_sha256 != SOURCE_SHA256:
        raise ValueError("本版只支持已审阅的完整源 SHA256；不能用命令行绕过版本限制。")
    if output_dir.exists():
        raise ValueError("输出目录已存在，拒绝覆盖；请指定全新的目录。")
    if output_dir == source.parent or output_dir == source:
        raise ValueError("输出不能是原源码路径。")
    raw = source.read_bytes()
    source_text = raw.decode("utf-8")
    if MARKER in source_text or '#include "AnalyzerDiagnostics.mqh"' in source_text:
        raise ValueError("源文件已经注入 Analyzer，拒绝重复处理。")
    if sha256(raw) != SOURCE_SHA256:
        raise ValueError(f"源 SHA256 不匹配：实际 {sha256(raw)}；需要 {SOURCE_SHA256}")
    dependencies = collect_dependencies(source, raw)
    generated = inject_observers(source_text).encode("utf-8")
    header_path = Path(__file__).resolve().parents[1] / "mql5" / "AnalyzerDiagnostics.mqh"
    header = header_path.read_bytes()
    files = {OUTPUT_NAME: generated, "AnalyzerDiagnostics.mqh": header, **dependencies}
    manifest = {
        "schema_version": 1,
        "tool": "GSM Gold Python Analyzer diagnostic-copy generator",
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "reference_commit": SOURCE_COMMIT,
        "source": {"name": source.name, "sha256": sha256(raw)},
        "generated_source": {"name": OUTPUT_NAME, "sha256": sha256(generated)},
        "files": {name: sha256(content) for name, content in sorted(files.items())},
        "added_include": "AnalyzerDiagnostics.mqh",
        "injection_points": ["PrintFilterAudit entry before original log switch", "OnTick entry"],
        "original_text_preserved": True,
        "diagnostic_defaults": {"InpAnalyzerDiagnostics": False, "InpAnalyzerEquitySamples": False,
                                "InpAnalyzerSampleSeconds": 60},
        "validation_status": "UNCOMPILED_UNVERIFIED_MT5_REGRESSION_REQUIRED",
        "account_sample_scope": "whole account; sampled equity drawdown is not tick-maximum drawdown",
        "coverage": "Only existing PrintFilterAudit calls; earlier branches without a call remain unobserved.",
        "execution_note": "Scalping filter pass occurs before request; no audit pass proves a fill.",
        "original_files_modified": False,
        "settings_copied_or_modified": False,
        "network_calls_added": False,
    }
    files["diagnostic_manifest.json"] = (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    # Validate everything before creating anything. mkdir and xb both refuse overwrite.
    output_dir.mkdir(parents=True, exist_ok=False)
    for name, content in files.items():
        with (output_dir / name).open("xb") as handle:
            handle.write(content)
    return manifest


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="生成独立 MQL5 观察副本；不编译、不运行、不下单。")
    parser.add_argument("--source", type=Path,
                        default=Path(__file__).resolve().parents[2] / "src" / "GSM_FxPro_RESEARCH.mq5")
    parser.add_argument("--output-dir", type=Path, required=True, help="必须是全新且不存在的目录")
    parser.add_argument("--expected-sha256", default=SOURCE_SHA256, help="完整已审阅源 SHA256；不能换成其他版本")
    args = parser.parse_args(argv)
    try:
        manifest = build_copy(args.source, args.output_dir, args.expected_sha256)
    except (OSError, ValueError, UnicodeError) as exc:
        print(f"生成失败：{exc}", file=sys.stderr)
        return 2
    print(f"已生成独立观察副本：{args.output_dir.resolve()}")
    print(f"原文件 SHA256：{manifest['source']['sha256']}")
    print(f"新文件 SHA256：{manifest['generated_source']['sha256']}")
    print("状态：未编译、未验证。两个观察开关默认关闭；须在 MT5 测试器回归。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
