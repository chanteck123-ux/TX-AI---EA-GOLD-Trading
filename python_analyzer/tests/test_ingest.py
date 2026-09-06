import json
import tempfile
import unittest
from pathlib import Path
from gsm_analyzer.ingest import load_dataset


class ImportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.manifest = dict(schema_version=1, run_id="TEST", data_type="synthetic", broker="FxPro", symbol="GOLD", symbol_aliases=["XAUUSD"], timezone="UTC+02:00", account_currency="USD", initial_capital=500, ea_version="test-only", ea_sha256="a"*64, set_sha256="b"*64, strategy_scope=["Scalping", "Intraday", "Swing"], magic_map={"22":"Intraday"}, contract=dict(contract_size=100,volume_min=.01,volume_step=.01,tick_size=.01), costs={}, test={}, segment="development", inputs=[])

    def tearDown(self):
        self.tmp.cleanup()

    def file(self, name, content, kind, encoding="utf-8", **kwargs):
        (self.root / name).write_bytes(content.encode(encoding))
        self.manifest["inputs"].append(dict(path=name,kind=kind,**kwargs))

    def load(self, **kwargs):
        path=self.root/"manifest.json"
        path.write_text(json.dumps(self.manifest),encoding="utf-8")
        return load_dataset(path,**kwargs)

    def test_utf16_semicolon_mapping_alias_and_timezone(self):
        self.file("trades.csv", "id;open;close;s;dir;净利\n1;2026.01.05 10:00:00;2026.01.05 11:00:00;XAUUSD;BUY;-4.5\n", "trades", encoding="utf-16", strategy="Intraday", columns={"position_id":"id","time_open":"open","time_close":"close","symbol":"s","side":"dir","net_profit":"净利"})
        data=self.load(); t=data["trades"][0]
        self.assertEqual(t["symbol"],"GOLD")
        self.assertEqual(t["time_open"],"2026-01-05T08:00:00+00:00")
        self.assertEqual(t["net_profit"],-4.5)
        self.assertIsNone(t["commission"])
        self.assertEqual(data["provenance"][0]["encoding"],"utf-16")
        self.assertEqual(len(data["provenance"][0]["sha256"]),64)

    def test_no_invented_net_profit_and_wrong_symbol_quarantine(self):
        self.file("trades.csv", "position_id,symbol,Profit\n1,GOLD,10\n2,GC,500\n", "trades")
        data=self.load()
        self.assertEqual(len(data["trades"]),1)
        self.assertIsNone(data["trades"][0]["net_profit"])
        self.assertTrue({"NET_PROFIT_MISSING","SYMBOL_MISMATCH"}.issubset({i["code"] for i in data["issues"]}))

    def test_native_deals_do_not_guess_position_and_preserve_zero_costs(self):
        self.file("deals.csv", "Deal,PositionID,Magic,Symbol,Entry,Type,Volume,Price,Profit,Commission,Swap,Fee,TimeMsc,Order\n1,99,22,GOLD,0,0,0.01,2400,0,-0.04,0,0,1767607200000,10\n2,99,22,GOLD,1,1,0.01,2405,5,-0.04,0,0,1767610800000,11\n", "deals")
        data=self.load()
        self.assertEqual(len(data["deals"]),2)
        self.assertEqual(data["deals"][0]["strategy"],"Intraday")
        self.assertEqual(data["deals"][0]["position_id"],"99")
        self.assertEqual(data["deals"][1]["entry"],"out")
        self.assertEqual(data["deals"][1]["side"],"SELL")
        self.assertEqual(data["deals"][1]["fee"],0)

    def test_duplicate_conflict_quarantines_both(self):
        self.file("equity.csv", "time,balance,equity\n2026.01.05 10:00:00,500,499\n2026.01.05 10:00:00,500,498\n2026.01.05 11:00:00,502,501\n2026.01.05 11:00:00,502,501\n", "equity")
        data=self.load()
        self.assertEqual(len(data["equity"]),1)
        self.assertEqual(data["equity"][0]["equity"],501)
        self.assertIn("DUPLICATE_CONFLICT",{i["code"] for i in data["issues"]})
        self.assertIn("DUPLICATE_REMOVED",{i["code"] for i in data["issues"]})

    def test_final_gate_before_input_read(self):
        self.manifest["segment"]="final"
        self.manifest["inputs"]=[dict(kind="deals",path="does-not-exist.csv")]
        with self.assertRaisesRegex(ValueError,"最终样本"):
            self.load()
        data=self.load(allow_final=True)
        self.assertIn("FINAL_SEGMENT_OPENED",{i["code"] for i in data["issues"]})
        self.assertIn("INPUT_MISSING",{i["code"] for i in data["issues"]})

    def test_missing_input_does_not_stop_valid_input(self):
        self.manifest["inputs"]=[dict(kind="trades",path="absent.csv")]
        self.file("bars.csv", "<DATE>\t<TIME>\t<OPEN>\t<HIGH>\t<LOW>\t<CLOSE>\t<TICKVOL>\n2026.01.05\t10:00:00\t2400\t2405\t2390\t2401\t20\n", "bars",timeframe="M5")
        data=self.load()
        self.assertEqual(len(data["bars"]),1)
        self.assertEqual(data["bars"][0]["time"],"2026-01-05T08:00:00+00:00")
        self.assertNotIn("INVALID_TIME",{i["code"] for i in data["issues"]})

    def test_ticks_require_bid_ask_and_unknown_time_stays_naive(self):
        self.manifest["timezone"]="unknown"
        self.file("ticks.csv", "time,symbol,bid,ask,last\n2026.01.05 10:00:00,GOLD,2400,2400.2,\n2026.01.05 10:00:01,GOLD,2401,2400,\n2026.01.05 10:00:02,GOLD,,,2400\n", "ticks")
        data=self.load()
        self.assertEqual(len(data["ticks"]),1)
        self.assertEqual(data["ticks"][0]["time"],"2026-01-05T10:00:00")
        self.assertIn("TIMEZONE_UNKNOWN",{i["code"] for i in data["issues"]})

    def test_funnel_is_snapshot_and_audit_is_one_event(self):
        self.file("funnel.csv","Run,EndTime,SOP,Magic,FirstTouches,HardSOPPassed,OrdersFilled,EMARejected,ZeroTradeDiagnosis\nR,2026.01.05 10:00:00,Intraday M30,22,391,391,4,380,已有成交\n","funnel")
        self.file("audit.csv","Time,SOP,RawCore,IndicatorPassed,MACDPassed,ConfidencePassed,GatePassed,Accepted,RejectReason\n2026.01.05 10:00:00,Intraday M30,YES,NO,YES,YES,NO,NO,EMA未通过\n","events")
        data=self.load()
        self.assertEqual(data["funnel"][0]["counts"]["EMARejected"],380)
        self.assertEqual(len(data["events"]),1)
        self.assertEqual(data["events"][0]["decision"],"blocked")
        self.assertFalse(data["events"][0]["flags"]["IndicatorPassed"])

    def test_native_html_summary_dd_percent_and_no_position_guess(self):
        self.file("report.htm", """<table><tr><td>Total Net Profit:</td><td>1 200.50</td><td>Equity Drawdown Relative:</td><td>17.50% (350.00)</td></tr><tr><td>Equity Drawdown Maximal:</td><td>360.00 (17.00%)</td></tr><tr><td>Profit Trades (% of total):</td><td>12 (60.00%)</td></tr><tr><td>Time</td><td>Deal</td><td>Symbol</td><td>Type</td><td>Direction</td><td>Volume</td><td>Price</td><td>Order</td><td>Commission</td><td>Swap</td><td>Profit</td></tr><tr><td>2026.01.05 10:00:00</td><td>2</td><td>GOLD</td><td>buy</td><td>in</td><td>0.01</td><td>2400</td><td>1</td><td>-0.04</td><td>0.00</td><td>0.00</td></tr></table>""", "report")
        data=self.load(); summary=data["reports"][0]["summary"]
        self.assertEqual(summary["net_profit"],1200.5)
        self.assertEqual(summary["equity_drawdown_pct"],17.5)
        self.assertEqual(summary["equity_drawdown_money"],360)
        self.assertEqual(summary["win_rate"],60)
        self.assertIsNone(data["deals"][0]["position_id"])
        self.assertFalse(data["equity"])
        self.assertIn("HTML_POSITION_ID_MISSING",{i["code"] for i in data["issues"]})

    def test_native_stats_metric_value(self):
        self.file("native.csv","Metric,Value\nNetProfitUSD,12.5\nMaxEquityDDUSD,20\nMaxEquityDDPct,4.1\nNativeBalanceRecovery,3.4\nNativeTrades,2\n","report")
        s=self.load()["reports"][0]["summary"]
        self.assertEqual(s["recovery_factor"],3.4)
        self.assertEqual(s["total_trades"],2)

    def test_diagnostic_log_preserves_observation_and_sampled_equity(self):
        self.file("expert.log", "GSM_ANALYZER|Run=R|Time=2026.01.05 10:00:00|SOP=Scalping|Stage=FILTER_AUDIT|Decision=OBSERVED_PASS|Reason=A%7CB%3Dx|EventID=R:1:1|DecisionMeaning=PRE_REQUEST_FILTER|RawCore=1\nGSM_ANALYZER|Run=R|Time=2026.01.05 10:00:00|SOP=Scalping|Stage=FILTER_AUDIT|Decision=OBSERVED_PASS|Reason=A%7CB%3Dx|EventID=R:1:2|DecisionMeaning=PRE_REQUEST_FILTER|RawCore=1\nGSM_ANALYZER|Run=R|Time=2026.01.05 10:01:00|SOP=Combined|Stage=ACCOUNT_SAMPLE|Balance=500|Equity=499|SampleSeconds=60\n", "log")
        data=self.load()
        self.assertEqual(len(data["events"]),2)
        self.assertEqual(data["events"][0]["reason"],"A|B=x")
        self.assertEqual(data["events"][0]["decision"],"observed_pass")
        self.assertFalse(data["events"][0]["_decision_is_fill"])
        self.assertEqual(data["equity"][0]["equity"],499)
        self.assertIn("not_native_tick",data["equity"][0]["_equity_sampling"])

    def test_decimal_comma_is_not_silently_thousand_value(self):
        self.file("comma.csv", "position_id;symbol;net_profit\n1;GOLD;1,23\n", "trades")
        data = self.load()
        self.assertIsNone(data["trades"][0]["net_profit"])
        self.assertIn("INVALID_NUMBER", {i["code"] for i in data["issues"]})

    def test_utf16_without_bom_is_detected_with_warning(self):
        self.file("ticks.csv", "time,bid,ask\n2026.01.05 10:00:00,2400,2401\n", "ticks", encoding="utf-16-le")
        data = self.load()
        self.assertEqual(len(data["ticks"]), 1)
        self.assertIn("ENCODING_INFERRED", {i["code"] for i in data["issues"]})

    def test_bar_availability_aliases_and_run_ids_survive(self):
        self.file("bars.csv", "Run,Time,BarEndTime,IndicatorAvailableAt,Open,High,Low,Close\nA,2026.01.05 10:00:00,2026.01.05 10:05:00,2026.01.05 10:06:00,2400,2402,2399,2401\nB,2026.01.05 10:00:00,2026.01.05 10:05:00,2026.01.05 10:06:00,2400,2402,2399,2401\n", "bars", timeframe="M5")
        self.file("eq.csv", "Run,time,balance,equity\nA,2026.01.05 10:00:00,500,499\n", "equity")
        self.file("tick.csv", "Run,time,bid,ask\nA,2026.01.05 10:00:00,2400,2401\n", "ticks")
        self.file("deal.csv", "Run,Deal,PositionID,Magic,Symbol,Entry,Type,Volume,Price,Time\nA,1,9,22,GOLD,0,0,.01,2400,2026.01.05 10:00:00\n", "deals")
        data = self.load()
        self.assertEqual(len(data["bars"]), 2)
        self.assertEqual({b["run_id"] for b in data["bars"]}, {"A", "B"})
        self.assertEqual(data["bars"][0]["time_close"], "2026-01-05T08:05:00+00:00")
        self.assertEqual(data["bars"][0]["available_at"], "2026-01-05T08:06:00+00:00")
        for kind in ("equity", "ticks", "deals"):
            self.assertEqual(data[kind][0]["run_id"], "A")

    def test_invalid_explicit_bar_availability_is_quarantined(self):
        self.file("bars.csv", "time,available_at,open,high,low,close\n2026.01.05 10:00:00,not-a-time,2400,2402,2399,2401\n", "bars", timeframe="M5")
        data = self.load()
        self.assertFalse(data["bars"])
        self.assertIn("INVALID_BAR_AVAILABILITY", {i["code"] for i in data["issues"]})

    def test_hash_mismatch_does_not_read_data(self):
        self.file("x.csv","time,bid,ask\n2026.01.05 10:00:00,2400,2401\n","ticks",sha256="0"*64)
        data=self.load()
        self.assertFalse(data["ticks"])
        self.assertEqual(len(data["provenance"]), 1)
        self.assertEqual(data["provenance"][0]["row_count"], 0)
        self.assertNotEqual(data["provenance"][0]["sha256"], "0" * 64)
        self.assertIn("SHA256_MISMATCH",{i["code"] for i in data["issues"]})


if __name__ == "__main__":
    unittest.main()
