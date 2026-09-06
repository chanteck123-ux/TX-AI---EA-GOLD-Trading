"""Command line interface; deliberately has no broker/API credentials or order path."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import webbrowser

from .analytics import analyze
from .ingest import load_dataset
from .report import write_report, _write_csv
from .research import annotate_splits, compare_results, guard_final
from .validation import check_observed_window


def run_analysis(manifest_path, output_dir, allow_final=False):
    manifest_path = Path(manifest_path).resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    exposure = guard_final(manifest, manifest_path, allow_final)
    dataset = load_dataset(manifest_path, allow_final=allow_final)
    check_observed_window(dataset, allow_final=allow_final)
    result = annotate_splits(analyze(dataset))
    result["metadata"]["manifest_sha256"] = hashlib.sha256(manifest_path.read_bytes()).hexdigest()
    result["metadata"]["final_exposure_ledger"] = exposure
    result["metadata"]["metric_definitions"] = {"win_rate": "盈利完整仓/全部完整仓×100；保本单保留在分母", "profit_factor": "完整仓净盈利之和/净亏损绝对值之和",
         "drawdown_pct": "遍历所有观测点的最大相对回撤，与最大金额DD所在时点百分比独立",
         "costs": "已是净利润的输入不重复扣成本；分项缺失不填零", "combined": "仅同一次运行的账户合计；不能合并独立策略回测"}
    return result, write_report(result, output_dir)


def main(argv=None):
    parser = argparse.ArgumentParser(prog="GSM Gold Python Analyzer", description="离线分析MT5黄金EA；不连接实盘、不下单、不使用付费AI。")
    sub = parser.add_subparsers(dest="command", required=True)
    analyze_cmd = sub.add_parser("analyze", help="分析manifest指定的真实或示例资料")
    analyze_cmd.add_argument("--manifest", required=True)
    analyze_cmd.add_argument("--output", default="output/current")
    analyze_cmd.add_argument("--allow-final", action="store_true", help="候选冻结后显式读取最终段，并记曝光记录")
    analyze_cmd.add_argument("--open-report", action="store_true")
    demo = sub.add_parser("demo", help="运行明确标记的合成示例")
    demo.add_argument("--output", default="output/demo")
    demo.add_argument("--open-report", action="store_true")
    compare = sub.add_parser("compare", help="比较两份analysis.json的条件与指标")
    compare.add_argument("--baseline", required=True)
    compare.add_argument("--candidate", required=True)
    compare.add_argument("--output", default="output/comparison")
    args = parser.parse_args(argv)
    try:
        if args.command == "compare":
            baseline = json.loads(Path(args.baseline).read_text(encoding="utf-8-sig"))
            candidate = json.loads(Path(args.candidate).read_text(encoding="utf-8-sig"))
            comparison = compare_results(baseline, candidate)
            candidate["comparison"] = comparison
            candidate["metadata"]["status"] = comparison["verdict"]
            paths = write_report(candidate, args.output)
            output = Path(args.output)
            (output/"comparison.json").write_text(json.dumps(comparison, ensure_ascii=False, indent=2, allow_nan=False), encoding="utf-8")
            if comparison["deltas"]:
                _write_csv(output/"comparison.csv", comparison["deltas"], list(comparison["deltas"][0]))
            print(comparison["status"])
        else:
            manifest = Path(__file__).resolve().parents[1]/"examples"/"synthetic"/"manifest.json" if args.command == "demo" else args.manifest
            result,paths = run_analysis(manifest, args.output, getattr(args, "allow_final", False))
            print(f"分析完成：{result['metadata'].get('run_id')}；数据类型={result['metadata'].get('data_type')}；问题记录={len(result['issues'])}")
            print("研究分析结果，不代表MT5验证通过或可实盘。")
        print(f"中文报告：{Path(paths['report_html']).resolve()}")
        if getattr(args, "open_report", False):
            webbrowser.open(Path(paths["report_html"]).resolve().as_uri())
        return 0
    except (ValueError, OSError, KeyError, TypeError) as exc:
        print(f"分析未完成：{exc}", file=sys.stderr)
        return 2
