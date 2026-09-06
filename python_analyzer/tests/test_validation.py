"""Observed input, rather than manifest claims, determines temporal eligibility."""
from copy import deepcopy
from pathlib import Path
import unittest

from gsm_analyzer.ingest import load_dataset
from gsm_analyzer.validation import check_observed_window


def dataset():
    return {"manifest": {"timezone": "UTC", "symbol": "GOLD", "symbol_aliases": ["XAUUSD"],
                         "initial_capital": 500, "segment": "development", "splits": [],
                         "test": {"start": "2026-01-01T00:00:00Z", "end": "2026-02-01T00:00:00Z"}},
            "issues": [], "reports": [], "trades": [], "deals": [], "events": [], "funnel": [],
            "equity": [], "ticks": [], "bars": []}


def record(**kwargs):
    return dict(_source="actual.csv", _row=7, **kwargs)


class ObservedWindowTests(unittest.TestCase):
    def test_half_open_inclusion_and_return_without_filter(self):
        data = dataset()
        data["trades"] = [record(time_open="2026-01-01T00:00:00Z", time_close="2026-01-31T23:59:59Z")]
        before = deepcopy(data["trades"])
        self.assertIs(check_observed_window(data), data)
        self.assertEqual(data["trades"], before)

    def test_each_event_kind_rejects_at_end_with_source_row(self):
        for kind in ("deals", "events", "funnel", "equity", "ticks"):
            with self.subTest(kind=kind):
                data = dataset()
                data[kind] = [record(time="2026-02-01T00:00:00Z")]
                with self.assertRaisesRegex(ValueError, f"kind={kind} source=actual.csv row=7"):
                    check_observed_window(data)
                self.assertEqual(len(data[kind]), 1)

    def test_declared_2025_does_not_allow_2026_trades(self):
        data = dataset()
        data["manifest"]["test"] = {"start": "2025-01-01", "end": "2026-01-01"}
        data["trades"] = [record(time_open="2026-01-03T00:00:00Z", time_close="2026-01-04T00:00:00Z")]
        with self.assertRaisesRegex(ValueError, "OBSERVED_TIME_OUTSIDE_TEST"):
            check_observed_window(data)

    def test_trade_entry_and_exit_must_both_be_in_window(self):
        for opening, closing in (("2025-12-31T23:59:59Z", "2026-01-01T01:00:00Z"),
                                 ("2026-01-31T23:00:00Z", "2026-02-01T00:00:00Z")):
            data = dataset()
            data["trades"] = [record(time_open=opening, time_close=closing)]
            with self.assertRaisesRegex(ValueError, "OBSERVED_TIME_OUTSIDE_TEST"):
                check_observed_window(data)

    def test_bar_warmup_and_derived_close_exactly_at_end_allowed(self):
        data = dataset()
        data["bars"] = [record(time="2025-12-20T00:00:00Z", timeframe="H4")]
        check_observed_window(data)
        data["bars"].append(record(time="2026-01-31T23:55:00Z", timeframe="M5"))
        check_observed_window(data)

    def test_bar_derived_close_after_end_is_rejected(self):
        data = dataset()
        data["bars"] = [record(time="2026-01-31T23:56:00Z", timeframe="M5")]
        with self.assertRaisesRegex(ValueError, "field=timeframe_close"):
            check_observed_window(data)

    def test_bar_explicit_late_availability_rejected(self):
        data = dataset()
        data["bars"] = [record(time="2026-01-31T23:00:00Z", timeframe="M5", available_at="2026-02-01T00:00:01Z")]
        with self.assertRaisesRegex(ValueError, "field=available_at"):
            check_observed_window(data)

    def test_bar_explicit_completion_and_availability_at_end_allowed(self):
        data = dataset()
        data["bars"] = [record(time="2026-01-31T23:55:00Z", timeframe="M5",
                               time_close="2026-02-01T00:00:00Z", available_at="2026-02-01T00:00:00Z")]
        check_observed_window(data)
        self.assertIn("BAR_AVAILABLE_AT_TEST_END", {i["code"] for i in data["issues"]})

    def test_bar_opening_exactly_at_end_is_rejected(self):
        data = dataset()
        data["bars"] = [record(time="2026-02-01T00:00:00Z", timeframe="M5")]
        with self.assertRaisesRegex(ValueError, "field=time "):
            check_observed_window(data)

    def test_bar_just_closed_at_final_start_does_not_read_final(self):
        data = dataset()
        data["manifest"]["splits"] = [{"name": "final", "start": "2026-02-01T00:00:00Z", "end": "2026-03-01T00:00:00Z"}]
        data["bars"] = [record(time="2026-01-31T23:55:00Z", timeframe="M5",
                               time_close="2026-02-01T00:00:00Z", available_at="2026-02-01T00:00:00Z")]
        check_observed_window(data)

    def test_bar_opening_in_or_spanning_into_final_is_rejected(self):
        for opening, closing in (("2026-02-01T00:00:00Z", "2026-02-01T00:05:00Z"),
                                 ("2026-01-31T23:59:00Z", "2026-02-01T00:04:00Z"),
                                 ("2026-01-01T00:00:00Z", "2026-04-01T00:00:00Z")):
            data = dataset()
            data["manifest"]["splits"] = [{"name": "final", "start": "2026-02-01T00:00:00Z", "end": "2026-03-01T00:00:00Z"}]
            data["bars"] = [record(time=opening, time_close=closing)]
            with self.assertRaisesRegex(ValueError, "FINAL_DATA_LOCKED_OBSERVED"):
                check_observed_window(data)

    def test_timezone_offset_boundaries_match_normalized_records(self):
        data = dataset()
        data["manifest"].update(timezone="UTC+02:00", test={"start": "2026-01-01", "end": "2026-02-01"})
        data["ticks"] = [record(time="2025-12-31T22:00:00+00:00")]
        check_observed_window(data)

    def test_unalignable_timezone_is_issue_not_fake_conversion(self):
        data = dataset()
        data["ticks"] = [record(time="2026-01-15T12:00:00")]
        check_observed_window(data)
        self.assertIn("OBSERVED_WINDOW_TIMEZONE_UNVERIFIED", {i["code"] for i in data["issues"]})
        self.assertEqual(data["ticks"][0]["time"], "2026-01-15T12:00:00")

    def test_final_detected_from_actual_time_despite_development_claim(self):
        data = dataset()
        data["manifest"]["splits"] = [{"name": "final", "start": "2026-02-01T00:00:00Z", "end": "2026-03-01T00:00:00Z"}]
        data["events"] = [record(time="2026-02-10T00:00:00Z")]
        with self.assertRaisesRegex(ValueError, "FINAL_DATA_LOCKED_OBSERVED"):
            check_observed_window(data)

    def test_final_unknown_record_clock_fails_closed(self):
        data = dataset()
        data["manifest"]["splits"] = [{"name": "final", "start": "2026-02-01T00:00:00Z", "end": "2026-03-01T00:00:00Z"}]
        data["ticks"] = [record(time="2026-02-10T00:00:00")]
        with self.assertRaisesRegex(ValueError, "FINAL_TIMEZONE_UNVERIFIED"):
            check_observed_window(data)

    def test_trade_crossing_whole_final_is_not_hidden_by_endpoint_checks(self):
        data = dataset()
        data["manifest"]["splits"] = [{"name": "final", "start": "2026-02-01T00:00:00Z", "end": "2026-03-01T00:00:00Z"}]
        data["trades"] = [record(time_open="2026-01-15T00:00:00Z", time_close="2026-03-03T00:00:00Z")]
        with self.assertRaisesRegex(ValueError, "FINAL_DATA_LOCKED_OBSERVED"):
            check_observed_window(data)

    def test_allow_final_does_not_bypass_actual_test_window(self):
        data = dataset()
        data["manifest"]["splits"] = [{"name": "final", "start": "2026-02-01T00:00:00Z", "end": "2026-03-01T00:00:00Z"}]
        data["events"] = [record(time="2026-02-10T00:00:00Z")]
        with self.assertRaisesRegex(ValueError, "OBSERVED_TIME_OUTSIDE_TEST"):
            check_observed_window(data, allow_final=True)
        data["manifest"]["test"] = {"start": "2026-02-01T00:00:00Z", "end": "2026-03-01T00:00:00Z"}
        check_observed_window(data, allow_final=True)

    def test_missing_test_continues_with_explicit_issue(self):
        data = dataset()
        data["manifest"].pop("test")
        data["ticks"] = [record(time="2026-05-01T00:00:00Z")]
        check_observed_window(data)
        self.assertIn("OBSERVED_WINDOW_UNDECLARED", {i["code"] for i in data["issues"]})

    def test_native_symbol_and_deposit_contradictions_are_fatal(self):
        for raw, code in (({"Symbol": "GC"}, "NATIVE_SYMBOL_MISMATCH"),
                          ({"初始入金": "2 000.00"}, "NATIVE_INITIAL_CAPITAL_MISMATCH")):
            data = dataset()
            data["reports"] = [record(raw_summary=raw)]
            with self.assertRaisesRegex(ValueError, code):
                check_observed_window(data)

    def test_native_explicit_alias_allowed_numeric_symbol_count_not_guessed(self):
        data = dataset()
        data["reports"] = [record(raw_summary={"Symbol": "XAUUSD", "Initial Deposit": "500.00", "交易品种": "1"})]
        check_observed_window(data)
        self.assertIn("NATIVE_SYMBOL_UNVERIFIED", {i["code"] for i in data["issues"]})

    @unittest.skipUnless((Path(__file__).resolve().parents[1] / "examples/fxpro_v400/manifest.json").is_file(), "真实用户附件不随公开源码上传")
    def test_actual_fxpro_dataset_remains_valid(self):
        path = Path(__file__).resolve().parents[1] / "examples/fxpro_v400/manifest.json"
        data = load_dataset(path)
        check_observed_window(data)
        self.assertEqual(len(data["trades"]), 25)
        self.assertAlmostEqual(sum(t["net_profit"] for t in data["trades"]), 93.71)


if __name__ == "__main__":
    unittest.main()
