"""Offline integration gates against shipped evidence and realistic CSV boundaries."""
from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
from copy import deepcopy
import csv
from datetime import datetime, timedelta, timezone
import hashlib
import io
import json
from pathlib import Path
import socket
import tempfile
import unittest
from unittest.mock import patch

from gsm_analyzer.analytics import analyze
from gsm_analyzer.cli import main, run_analysis
from gsm_analyzer.ingest import load_dataset
from gsm_analyzer.report import write_report


PROJECT = Path(__file__).resolve().parents[1]
REAL_MANIFEST = PROJECT / "examples" / "fxpro_v400" / "manifest.json"
SYNTHETIC_MANIFEST = PROJECT / "examples" / "synthetic" / "manifest.json"


def metric(result, name="Combined"):
    return next(row for row in result["metrics"] if row["strategy"] == name)


@unittest.skipUnless(REAL_MANIFEST.is_file(), "真实用户附件不随公开源码上传")
class ActualFxProEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dataset = load_dataset(REAL_MANIFEST)
        cls.result = analyze(deepcopy(cls.dataset))

    def test_actual_full_run_reconciles_per_engine_and_exported_csv(self):
        expected = {"Scalping": (20, 64.39), "Intraday": (4, 28.66),
                    "Swing": (1, .66), "Combined": (25, 93.71)}
        self.assertEqual(len(self.result["trades"]), 25)
        self.assertEqual(len({r["position_id"] for r in self.result["trades"]}), 25)
        for strategy, (trades, net) in expected.items():
            actual = metric(self.result, strategy)
            self.assertEqual(actual["complete_trades"], trades)
            self.assertAlmostEqual(actual["net_profit"], net, places=2)
        self.assertAlmostEqual(self.dataset["reports"][0]["summary"]["net_profit"], 93.71, places=2)
        self.assertNotIn("NATIVE_NET_MISMATCH", {r["code"] for r in self.result["issues"]})
        self.assertEqual(self.result["metadata"]["mt5_verification"], "PENDING")
        self.assertLessEqual(len(self.result["candidates"]), 3)
        for record in self.dataset["provenance"]:
            self.assertEqual(record["sha256"], hashlib.sha256(Path(record["path"]).read_bytes()).hexdigest())
        with tempfile.TemporaryDirectory() as folder:
            exported = write_report(self.result, folder)
            with Path(exported["metrics"]).open(encoding="utf-8-sig", newline="") as handle:
                rows = {r["strategy"]: r for r in csv.DictReader(handle)}
            self.assertEqual(int(rows["Combined"]["complete_trades"]), 25)
            self.assertEqual(float(rows["Combined"]["net_profit"]), 93.71)
            with Path(exported["trade_analysis"]).open(encoding="utf-8-sig", newline="") as handle:
                trades = list(csv.DictReader(handle))
            self.assertEqual(len(trades), 25)
            self.assertAlmostEqual(sum(float(r["net_profit"]) for r in trades), 93.71)
            html = Path(exported["report_html"]).read_text(encoding="utf-8")
            self.assertIn("93.71", html)
            self.assertIn("待验证", html)
            self.assertNotIn('<script src="http', html)
            saved = json.loads(Path(exported["analysis_json"]).read_text(encoding="utf-8"))
            self.assertEqual(saved["metadata"]["run_id"], "V400_C-C01_FULL_FxPro")
            self.assertEqual(saved["metadata"]["ea_sha256"], self.dataset["manifest"]["ea_sha256"])

    def test_native_equity_drawdown_is_separate_and_never_becomes_curve(self):
        combined = metric(self.result)
        self.assertEqual(combined["balance_dd_money"], 9.32)
        self.assertEqual(combined["equity_dd_money"], 57.69)
        self.assertEqual(combined["equity_dd_pct"], 9.48)
        self.assertNotEqual(combined["equity_dd_money"], combined["balance_dd_money"])
        self.assertEqual(self.dataset["equity"], [])
        for strategy, curve in self.result["curves"].items():
            self.assertTrue(all(row.get("equity") is None for row in curve), strategy)
        self.assertIsNone(metric(self.result, "Scalping")["equity_dd_money"])
        self.assertIsNone(metric(self.result, "Intraday")["equity_dd_money"])
        self.assertIsNone(metric(self.result, "Swing")["equity_dd_money"])
        self.assertIn("无时序不生成净值曲线", combined["equity_dd_source"])
        self.assertIn("REAL_TICK_COVERAGE_UNVERIFIED", {r["code"] for r in self.result["issues"]})

    def test_html_deals_have_no_fabricated_position_id_or_complete_count(self):
        self.assertEqual(len(self.dataset["deals"]), 50)
        self.assertTrue(all(not row.get("position_id") for row in self.dataset["deals"]))
        self.assertTrue(any(row.get("order_id") for row in self.dataset["deals"]))
        original = deepcopy(self.dataset["manifest"])
        original["inputs"] = [dict(item, path=str((REAL_MANIFEST.parent/item["path"]).resolve()))
                              for item in original["inputs"] if item["kind"] == "report"]
        with tempfile.TemporaryDirectory() as folder:
            manifest = Path(folder)/"html_only.json"
            manifest.write_text(json.dumps(original), encoding="utf-8")
            data = load_dataset(manifest)
            actual = analyze(data)
            self.assertEqual(actual["trades"], [])
            self.assertIsNone(metric(actual)["complete_trades"])
            self.assertEqual(metric(actual)["native_total_trades"], 25)
            self.assertEqual(metric(actual)["net_profit"], 93.71)
            self.assertEqual(actual["curves"]["Combined"], [])
            self.assertIn("DEAL_POSITION_ID_MISSING", {r["code"] for r in actual["issues"]})


class OfflineDemoTests(unittest.TestCase):
    def test_synthetic_source_remains_demo_and_never_approved(self):
        with tempfile.TemporaryDirectory() as folder:
            result, exports = run_analysis(SYNTHETIC_MANIFEST, folder)
            self.assertEqual(result["metadata"]["data_type"], "synthetic")
            self.assertIn("DEMO", result["metadata"]["run_id"])
            self.assertEqual(result["metadata"]["mt5_verification"], "PENDING")
            self.assertIn("不授予Champion", result["metadata"]["status"])
            self.assertTrue(all(m["status"] != "Champion" for m in result["metrics"]))
            html = Path(exports["report_html"]).read_text(encoding="utf-8")
            self.assertIn("合成示例数据", html)
            self.assertIn("不能代表 EA 收益或真实 Tick 覆盖", html)
            self.assertLessEqual(len(result["candidates"]), 3)

    def test_cli_demo_succeeds_when_network_connections_are_forbidden(self):
        # Exercise actual CLI routing, file imports, analysis, splits and reports.
        # An attempted outbound connection fails this test immediately.
        with tempfile.TemporaryDirectory() as folder:
            stdout, stderr = io.StringIO(), io.StringIO()
            blocked = AssertionError("offline analyzer attempted network connection")
            with patch.object(socket, "create_connection", side_effect=blocked), \
                 patch.object(socket.socket, "connect", side_effect=blocked), \
                 patch("webbrowser.open", side_effect=AssertionError("browser launch not requested")), \
                 redirect_stdout(stdout), redirect_stderr(stderr):
                code = main(["demo", "--output", folder])
            self.assertEqual(code, 0, stderr.getvalue())
            self.assertIn("SYNTHETIC_DEMO_ONLY", stdout.getvalue())
            self.assertTrue((Path(folder)/"report.html").is_file())
            self.assertTrue((Path(folder)/"analysis.json").is_file())
            self.assertTrue((Path(folder)/"metrics.csv").is_file())


class CausalImportIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.start = datetime(2026, 1, 6, tzinfo=timezone.utc)
        self.manifest = {
            "schema_version": 1, "run_id": "E2E", "data_type": "synthetic", "symbol": "GOLD",
            "symbol_aliases": [], "broker": "SYNTHETIC", "timezone": "UTC",
            "account_currency": "USD", "initial_capital": 500, "strategy_scope": "Combined",
            "ea_version": "SYNTHETIC", "ea_sha256": "a"*64, "set_sha256": "b"*64,
            "contract": {}, "costs": {}, "segment": "development",
            "test": {"start": self.start.isoformat(), "end": (self.start+timedelta(days=1)).isoformat()},
            "inputs": [{"kind": "trades", "path": "trades.csv"},
                       {"kind": "bars", "path": "bars.csv", "timeframe": "M5"}],
        }
        self.bars = []
        for i in range(30):
            opened = self.start+timedelta(minutes=5*i)
            closed = opened+timedelta(minutes=5)
            self.bars.append(dict(Run="E2E", Time=opened.isoformat(), BarEndTime=closed.isoformat(),
                                  IndicatorAvailableAt=closed.isoformat(), Symbol="GOLD",
                                  Open=2400+i, High=2401+i, Low=2399+i, Close=2400+i))
        self.trades = [dict(run_id="E2E", position_id="1", strategy="Intraday", symbol="GOLD", side="BUY",
                           time_open=(self.start+timedelta(minutes=105)).isoformat(),
                           time_close=(self.start+timedelta(minutes=110)).isoformat(), volume=.01,
                           net_profit=2, commission=0, swap=0, fee=0)]

    def tearDown(self):
        self.temp.cleanup()

    def load(self):
        for filename, rows in (("bars.csv", self.bars), ("trades.csv", self.trades)):
            with (self.root/filename).open("w", encoding="utf-8", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
                writer.writeheader()
                writer.writerows(rows)
        path = self.root/"manifest.json"
        path.write_text(json.dumps(self.manifest), encoding="utf-8")
        return load_dataset(path)

    def test_future_price_changes_do_not_affect_earlier_entry(self):
        before = analyze(self.load())["trades"][0]
        self.assertEqual(before["market_regime"], "上涨代理")
        for row in self.bars[21:]:
            row.update(Open=1_000_000, High=1_000_002, Low=1, Close=2)
        after = analyze(self.load())["trades"][0]
        for key in ("market_regime", "regime_available_at", "proxy_atr_sma_tr14"):
            self.assertEqual(before[key], after[key])
        self.assertLessEqual(after["regime_available_at"], after["time_open"])

    def test_premature_bar_availability_is_excluded_after_csv_import(self):
        self.bars[20]["IndicatorAvailableAt"] = (self.start+timedelta(minutes=101)).isoformat()
        result = analyze(self.load())
        self.assertIn("BAR_AVAILABLE_BEFORE_CLOSE", {r["code"] for r in result["issues"]})
        self.assertEqual(result["trades"][0]["market_regime"], "UNKNOWN_NO_CAUSAL_BARS")
        self.assertIsNone(result["trades"][0]["regime_available_at"])

    def test_mixed_run_ids_survive_import_and_analysis_rejects_pooling(self):
        other = dict(self.bars[0], Run="OTHER_RUN")
        self.bars.append(other)
        dataset = self.load()
        self.assertEqual(len(dataset["bars"]), 31)
        with self.assertRaisesRegex(ValueError, "RUN_ID_MISMATCH"):
            analyze(dataset)


if __name__ == "__main__":
    unittest.main()
