"""Regression checks for misleading success after invalid or mismatched inputs."""
from contextlib import redirect_stdout, redirect_stderr
from copy import deepcopy
import io
import json
from pathlib import Path
import tempfile
import unittest

from gsm_analyzer.analytics import analyze
from gsm_analyzer.cli import main
from gsm_analyzer.ingest import load_dataset
from gsm_analyzer.research import compare_results
from test_research import comparison_pair

ROOT = Path(__file__).resolve().parents[1]


class DeliveryGuards(unittest.TestCase):
    def test_synthetic_prices_directions_and_gross_pnl_agree(self):
        data = load_dataset(ROOT / "examples/synthetic/manifest.json")
        contract = data["manifest"]["contract"]["contract_size"]
        for row in data["trades"]:
            sign = 1 if row["side"] == "BUY" else -1
            gross = sign * (row["exit_price"]-row["entry_price"]) * row["volume"] * contract
            self.assertAlmostEqual(gross, row["gross_profit"], places=6)

    def test_all_invalid_positions_are_unknown_not_zero_profit(self):
        data = load_dataset(ROOT / "examples/synthetic/manifest.json")
        data["trades"] = [{**data["trades"][0], "position_id": "", "trade_id": ""}]
        data["equity"] = []
        result = analyze(data)
        self.assertTrue(all(row["net_profit"] is None for row in result["metrics"]))
        self.assertTrue(all(row["complete_trades"] is None for row in result["metrics"]))

    def test_input_errors_prevent_fair_comparison_claim(self):
        for problem in ({"severity": "error", "code": "SHA256_MISMATCH"},
                        {"severity": "warning", "code": "NATIVE_NET_MISMATCH"}):
            baseline, candidate = comparison_pair()
            candidate["issues"] = [problem]
            self.assertEqual(compare_results(baseline, candidate)["status"], "NOT_COMPARABLE")

    @unittest.skipUnless((ROOT / "examples/fxpro_v400/manifest.json").is_file(), "真实用户附件不随公开源码上传")
    def test_wrong_real_report_capital_is_rejected_by_cli(self):
        path = ROOT / "examples/fxpro_v400/manifest.json"
        manifest = json.loads(path.read_text(encoding="utf-8"))
        manifest["initial_capital"] = 2000
        for item in manifest["inputs"]:
            item["path"] = str(path.parent / item["path"])
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            (base / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
            stderr = io.StringIO()
            with redirect_stdout(io.StringIO()), redirect_stderr(stderr):
                code = main(["analyze", "--manifest", str(base / "manifest.json"), "--output", str(base / "out")])
            self.assertEqual(code, 2)
            self.assertIn("NATIVE_INITIAL_CAPITAL_MISMATCH", stderr.getvalue())
            self.assertFalse((base / "out/report.html").exists())

    @unittest.skipUnless((ROOT / "examples/fxpro_v400/manifest.json").is_file(), "真实用户附件不随公开源码上传")
    def test_native_settings_symbol_not_replaced_by_numeric_symbol_count(self):
        data = load_dataset(ROOT / "examples/fxpro_v400/manifest.json")
        self.assertEqual(data["reports"][0]["raw_summary"]["交易品种"], "GOLD")


if __name__ == "__main__":
    unittest.main()
