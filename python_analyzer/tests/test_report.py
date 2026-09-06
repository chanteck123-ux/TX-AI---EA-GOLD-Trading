"""Report security and evidence-boundary regression tests."""

import csv
import json
import tempfile
import unittest
from pathlib import Path

from gsm_analyzer.report import write_report


class ReportTests(unittest.TestCase):
    def make_report(self, result):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        paths = write_report(result, directory.name)
        return paths, Path(paths["report_html"]).read_text(encoding="utf-8")

    def test_missing_equity_is_not_replaced_by_balance(self):
        result = {"metadata": {"data_type": "backtest"},
                  "metrics": [{"strategy": "Intraday", "net_profit": 15, "equity_dd_money": None}],
                  "curves": {"Intraday": [{"time": "2026-01-01", "balance": 500, "equity": None},
                                           {"time": "2026-01-02", "balance": 515, "equity": None}]}}
        paths, text = self.make_report(result)
        self.assertIn("缺少净值数据，不能由余额推算", text)
        stored = json.loads(Path(paths["analysis_json"]).read_text(encoding="utf-8"))
        self.assertIsNone(stored["metrics"][0]["equity_dd_money"])
        self.assertTrue(all(row["equity"] is None for row in stored["curves"]["Intraday"]))
        self.assertEqual(text.count('aria-label="余额曲线"'), 1)
        self.assertNotIn('aria-label="净值曲线（仅使用已提供净值）"', text)

    def test_untrusted_html_and_script_closing_are_escaped(self):
        attack = '</script><script>alert("owned")</script><img src=x onerror=alert(1)>'
        paths, text = self.make_report({"metadata": {"ea_version": attack},
                                       "findings": [{"message": attack, "kind": "hypothesis"}],
                                       "metrics": [{"strategy": attack, "net_profit": -2}],
                                       "curves": {attack: [{"time": attack, "balance": 500}]}})
        self.assertNotIn(attack, text)
        self.assertNotIn('<img src=x', text)
        self.assertIn("\\u003c/script\\u003e", text)
        self.assertIn("&lt;img", text)
        embedded = text.split('<script id="report-context" type="application/json">', 1)[1].split('</script>', 1)[0]
        self.assertEqual(json.loads(embedded)["metadata"]["ea_version"], attack)
        self.assertEqual(json.loads(Path(paths["analysis_json"]).read_text(encoding="utf-8"))["metadata"]["ea_version"], attack)

    def test_csv_formula_strings_are_neutralized_numeric_loss_remains_numeric(self):
        result = {"findings": [{"message": '=HYPERLINK("https://example.invalid")', "evidence": " \t@SUM(1,2)", "id": "-1+2"}],
                  "metrics": [{"strategy": "+CMD", "net_profit": -42.5}],
                  "issues": [{"code": "\tmalicious", "message": "\r=1+1"}]}
        paths, _ = self.make_report(result)
        with Path(paths["findings"]).open(encoding="utf-8-sig", newline="") as handle:
            row = next(csv.DictReader(handle))
        self.assertTrue(row["message"].startswith("'="))
        self.assertTrue(row["evidence"].startswith("'"))
        self.assertTrue(row["id"].startswith("'-"))
        with Path(paths["metrics"]).open(encoding="utf-8-sig", newline="") as handle:
            row = next(csv.DictReader(handle))
        self.assertEqual(row["net_profit"], "-42.5")
        self.assertEqual(row["strategy"], "'+CMD")
        self.assertTrue(Path(paths["metrics"]).read_bytes().startswith(b"\xef\xbb\xbf"))

    def test_synthetic_dataset_clearly_identified(self):
        _, text = self.make_report({"metadata": {"manifest": {"data_type": "synthetic", "timezone": "UTC"}}})
        self.assertIn("合成示例数据", text)
        self.assertIn("不能代表 EA 收益或真实 Tick 覆盖", text)
        self.assertIn("待验证基准", text)
        self.assertNotIn("宣布 PASS", text)

    def test_native_and_computed_metrics_remain_separate(self):
        paths, text = self.make_report({"metrics": [{"strategy": "Combined", "complete_trades": 2}],
                                       "native_reports": [{"format": "mt5_html", "_source": "original.htm",
                                                           "summary": {"Total Trades": 5, "Equity Drawdown": "10%"}}]})
        with Path(paths["native_report_summary"]).open(encoding="utf-8-sig", newline="") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(rows[0]["native_value"], "5")
        self.assertEqual(rows[0]["_source"], "original.htm")
        self.assertIn("MT5 原生报告摘要（独立口径）", text)

    def test_demo_account_is_not_labeled_synthetic(self):
        _, text = self.make_report({"metadata": {"manifest": {"data_type": "demo", "note": "compare with synthetic example later"}}})
        self.assertIn("模拟账户历史", text)
        self.assertNotIn("合成示例数据｜", text)

    def test_empty_report_produces_all_exports_with_headers(self):
        paths, text = self.make_report({})
        self.assertEqual(len(paths), 12)
        for key, path in paths.items():
            self.assertTrue(Path(path).is_file(), key)
            self.assertGreater(Path(path).stat().st_size, 0, key)
        self.assertIn("没有可用于绘图", text)
        self.assertIn("数据类型未明确", text)

    def test_non_finite_numbers_export_as_null(self):
        paths, _ = self.make_report({"metrics": [{"strategy": "Scalping", "profit_factor": float("inf"), "net_profit": float("nan")} ]})
        stored = json.loads(Path(paths["analysis_json"]).read_text(encoding="utf-8"))
        self.assertIsNone(stored["metrics"][0]["profit_factor"])
        self.assertIsNone(stored["metrics"][0]["net_profit"])

    def test_more_than_three_candidates_rejected_without_silent_truncation(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                write_report({"candidates": [{"id": n} for n in range(4)]}, directory)

    def test_canonical_trade_headers_and_stage_translation_are_presentation_only(self):
        result = {"trades": [{"strategy": "Swing", "symbol": "XAUUSD", "side": "BUY", "time_open": "2026-01-01", "time_close": "2026-01-02", "net_profit": 1}],
                  "funnel": [{"strategy": "Swing", "stage": "CANDIDATE", "reason": "SETUP_PRESENT", "count": 1, "unit": "事件"}]}
        paths, text = self.make_report(result)
        self.assertIn("产生候选 (CANDIDATE)", text)
        with Path(paths["trade_analysis"]).open(encoding="utf-8-sig", newline="") as handle:
            header = next(csv.reader(handle))
        self.assertEqual(header[:5], ["strategy", "symbol", "side", "time_open", "time_close"])
        with Path(paths["signal_funnel"]).open(encoding="utf-8-sig", newline="") as handle:
            self.assertEqual(next(csv.DictReader(handle))["stage"], "CANDIDATE")


if __name__ == "__main__":
    unittest.main()
