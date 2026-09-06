"""Temporal holdout, comparison eligibility and offline CLI regression tests."""

from contextlib import redirect_stderr, redirect_stdout
from copy import deepcopy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gsm_analyzer.cli import main, run_analysis
from gsm_analyzer.research import annotate_splits, compare_results, guard_final, validate_splits


def windows():
    return [{"name": "development", "start": "2026-01-01T00:00:00+00:00", "end": "2026-02-01T00:00:00+00:00"},
            {"name": "validation", "start": "2026-02-01T00:00:00+00:00", "end": "2026-03-01T00:00:00+00:00"},
            {"name": "final", "start": "2026-03-01T00:00:00+00:00", "end": "2026-09-01T00:00:00+00:00"}]


def metadata():
    return {"schema_version": 1, "run_id": "research-unit", "broker": "FxPro", "symbol": "GOLD",
            "timezone": "UTC", "account_currency": "USD", "initial_capital": 2000,
            "data_type": "synthetic", "strategy_scope": "Combined", "prior_use": "unseen",
            "risk": {"single_pct": 1, "total_pct": 3},
            "costs": {"commission_per_lot": 8, "spread_mode": "observed", "delay_ms": 25},
            "contract": {"contract_size": 100, "volume_min": .01, "volume_step": .01},
            "test": {"start": "2026-02-01T00:00:00+00:00", "end": "2026-03-01T00:00:00+00:00"},
            "market_data_sha256": "a"*64, "ea_sha256": "b"*64, "set_sha256": "c"*64,
            "splits": windows(), "segment": "validation", "inputs": []}


def comparison_pair():
    base = {"metadata": metadata(), "metrics": [{"strategy": "Combined", "net_profit": 10,
             "complete_trades": 101, "equity_dd_pct": 5, "win_rate": 40, "profit_factor": 1.3}]}
    candidate = deepcopy(base)
    candidate["metadata"].update(run_id="candidate-unit", ea_sha256="d"*64, set_sha256="e"*64,
                                 experiment={"changed_modules": ["risk_rounding"],
                                             "baseline_ea_sha256": "b"*64, "baseline_set_sha256": "c"*64})
    candidate["metrics"][0]["net_profit"] = 15
    return base, candidate


def final_manifest():
    value = metadata()
    value.update(segment="final", test={"start": "2026-03-01T00:00:00+00:00", "end": "2026-09-01T00:00:00+00:00"},
                 experiment={"frozen_at": "2026-02-28T12:00:00+00:00"})
    return value


class TemporalPartitionTests(unittest.TestCase):
    def test_adjacent_half_open_windows_are_valid(self):
        parsed = validate_splits({"splits": windows()})
        self.assertEqual([p[2] for p in parsed], ["development", "validation", "final"])
        self.assertEqual(parsed[0][1], parsed[1][0])

    def test_overlap_and_inverted_temporal_roles_are_rejected(self):
        overlap = windows()
        overlap[1]["start"] = "2026-01-31T23:59:00+00:00"
        with self.assertRaisesRegex(ValueError, "SPLIT_OVERLAP"):
            validate_splits({"splits": overlap})
        inverted = windows()
        inverted[0]["name"], inverted[1]["name"] = "validation", "development"
        with self.assertRaisesRegex(ValueError, "SPLIT_ORDER"):
            validate_splits({"splits": inverted})

    def test_duplicate_empty_or_mixed_timezone_windows_are_rejected(self):
        repeated = windows()+[dict(windows()[0])]
        with self.assertRaises(ValueError):
            validate_splits({"splits": repeated})
        empty = windows()
        empty[0]["end"] = empty[0]["start"]
        with self.assertRaises(ValueError):
            validate_splits({"splits": empty})
        mixed = windows()
        mixed[0]["start"] = "2026-01-01T00:00:00"
        with self.assertRaisesRegex(ValueError, "TIMEZONE"):
            validate_splits({"splits": mixed})

    def test_cross_boundary_positions_do_not_inflate_oos_counts(self):
        result = {"metadata": {"splits": windows()}, "trades": [
            {"position_id": "development", "time_open": "2026-01-10T00:00:00+00:00", "time_close": "2026-01-11T00:00:00+00:00"},
            {"position_id": "touch_boundary", "time_open": "2026-01-31T23:00:00+00:00", "time_close": "2026-02-01T00:00:00+00:00"},
            {"position_id": "validation", "time_open": "2026-02-01T00:00:00+00:00", "time_close": "2026-02-01T01:00:00+00:00"},
            {"position_id": "cross_final", "time_open": "2026-02-28T23:00:00+00:00", "time_close": "2026-03-01T01:00:00+00:00"},
            {"position_id": "final", "time_open": "2026-03-01T00:00:00+00:00", "time_close": "2026-03-01T01:00:00+00:00"}]}
        annotated = annotate_splits(result)
        labels = {r["position_id"]: r["segment"] for r in annotated["trades"]}
        self.assertEqual(labels["development"], "development")
        self.assertEqual(labels["validation"], "validation")
        self.assertEqual(labels["final"], "final")
        self.assertEqual(labels["touch_boundary"], "CROSSES_BOUNDARY_NOT_IN_OOS_SAMPLE")
        self.assertEqual(labels["cross_final"], "CROSSES_BOUNDARY_NOT_IN_OOS_SAMPLE")
        self.assertEqual(sum(r["segment"] == "final" for r in annotated["trades"]), 1)


class FinalHoldoutTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name)/"manifest.json"

    def test_final_is_locked_by_default_even_if_named_validation(self):
        value = final_manifest()
        for segment in ("final", "validation"):
            with self.subTest(segment=segment):
                value["segment"] = segment
                with self.assertRaisesRegex(ValueError, "FINAL_DATA_LOCKED"):
                    guard_final(value, self.path, False)
        self.assertFalse((self.path.parent/"final_exposure_ledger.jsonl").exists())

    def test_validation_ending_at_final_start_is_not_exposed(self):
        self.assertIsNone(guard_final(metadata(), self.path, False))
        self.assertFalse((self.path.parent/"final_exposure_ledger.jsonl").exists())

    def test_final_requires_unseen_data_frozen_time_and_file_hashes(self):
        for update in ({"prior_use": "seen"}, {"prior_use": "unknown"}, {"ea_sha256": ""},
                       {"set_sha256": None}, {"experiment": {}}):
            with self.subTest(update=update):
                value = final_manifest()
                value.update(update)
                with self.assertRaises(ValueError):
                    guard_final(value, self.path, True)
        self.assertFalse((self.path.parent/"final_exposure_ledger.jsonl").exists())

    def test_final_rejects_freeze_after_oos_has_started(self):
        value = final_manifest()
        value["experiment"]["frozen_at"] = "2026-03-01T00:00:01+00:00"
        with self.assertRaisesRegex(ValueError, "LATE_FREEZE"):
            guard_final(value, self.path, True)

    def test_final_hash_placeholders_cannot_authorize_exposure(self):
        for key in ("ea_sha256", "set_sha256"):
            with self.subTest(key=key):
                value = final_manifest()
                value[key] = "not-a-sha256"
                with self.assertRaises(ValueError):
                    guard_final(value, self.path, True)
        self.assertFalse((self.path.parent/"final_exposure_ledger.jsonl").exists())

    def test_final_requires_valid_market_data_fingerprint_before_reserving(self):
        for value in (None, "", "unknown", "a"*63, "z"*64):
            with self.subTest(value=value):
                manifest = final_manifest()
                manifest["market_data_sha256"] = value
                with self.assertRaisesRegex(ValueError, "FINAL_MARKET_HASH_INVALID"):
                    guard_final(manifest, self.path, True)
        self.assertFalse((self.path.parent/"final_exposure_ledger.jsonl").exists())

    def test_final_without_valid_test_start_end_cannot_reserve_exposure(self):
        for interval in (None, {}, {"start": "2026-03-01"}, {"end": "2026-09-01"},
                         {"start": "invalid", "end": "2026-09-01"},
                         {"start": "2026-09-01", "end": "2026-03-01"}):
            with self.subTest(interval=interval):
                manifest = final_manifest()
                manifest["test"] = interval
                with self.assertRaises(ValueError):
                    guard_final(manifest, self.path, True)
        self.assertFalse((self.path.parent/"final_exposure_ledger.jsonl").exists())

    def test_final_requires_registered_window_and_exact_half_open_extent(self):
        cases = [{"splits": []}, {"splits": windows()[:2]},
                 {"test": {"start": "2026-03-02T00:00:00+00:00", "end": "2026-09-01T00:00:00+00:00"}},
                 {"test": {"start": "2026-02-28T00:00:00+00:00", "end": "2026-09-01T00:00:00+00:00"}},
                 {"test": {"start": "2026-03-01T00:00:00+00:00", "end": "2026-08-31T00:00:00+00:00"}}]
        for updates in cases:
            with self.subTest(updates=updates):
                manifest = final_manifest()
                manifest.update(updates)
                with self.assertRaisesRegex(ValueError, "FINAL_WINDOW"):
                    guard_final(manifest, self.path, True)
        self.assertFalse((self.path.parent/"final_exposure_ledger.jsonl").exists())

    def test_exposure_is_recorded_before_input_reads_and_not_repeated_for_new_candidate(self):
        value = final_manifest()
        ledger = Path(guard_final(value, self.path, True))
        recorded = json.loads(ledger.read_text(encoding="utf-8").strip())
        self.assertEqual(recorded["status"], "EXPOSURE_RESERVED")
        self.assertEqual(len(recorded["exposure_id"]), 64)
        value.update(run_id="retuned-candidate", ea_sha256="f"*64)
        with self.assertRaisesRegex(ValueError, "FINAL_REUSE_BLOCKED"):
            guard_final(value, self.path, True)
        self.assertEqual(len(ledger.read_text(encoding="utf-8").splitlines()), 1)


class ComparisonEligibilityTests(unittest.TestCase):
    def test_matching_conditions_produce_only_pending_mt5_verification(self):
        baseline, candidate = comparison_pair()
        actual = compare_results(baseline, candidate)
        self.assertTrue(actual["same_conditions"])
        self.assertEqual(actual["status"], "CONDITIONS_MATCH_MT5_VERIFICATION_PENDING")
        self.assertEqual(actual["deltas"][0]["net_profit_delta"], 5)
        self.assertNotIn(actual["status"], ("PASS", "CHAMPION"))

    def test_risk_cost_test_dates_and_market_fingerprint_must_match(self):
        changes = {"risk": {"single_pct": 2, "total_pct": 3}, "costs": {"commission_per_lot": 0},
                   "test": {"start": "2026-02-02T00:00:00+00:00", "end": "2026-03-01T00:00:00+00:00"},
                   "market_data_sha256": "f"*64, "initial_capital": 500, "timezone": "UTC+02:00",
                   "data_type": "live"}
        for key,value in changes.items():
            with self.subTest(key=key):
                baseline, candidate = comparison_pair()
                candidate["metadata"][key] = value
                actual = compare_results(baseline, candidate)
                self.assertFalse(actual["same_conditions"])
                self.assertEqual(actual["status"], "NOT_COMPARABLE")
                self.assertIn(key, actual["different_fields"])

    def test_missing_conditions_and_wrong_parent_hash_block_comparison(self):
        baseline, candidate = comparison_pair()
        candidate["metadata"].pop("contract")
        candidate["metadata"]["experiment"]["baseline_ea_sha256"] = "f"*64
        result = compare_results(baseline, candidate)
        self.assertEqual(result["status"], "NOT_COMPARABLE")
        self.assertIn("contract", result["missing_fields"])
        self.assertIn("baseline_ea_sha256", result["different_fields"])

    def test_changed_modules_must_be_a_list_of_one_nonempty_module(self):
        for modules in ([], ["entry", "risk"], "x", [""]):
            with self.subTest(modules=modules):
                baseline, candidate = comparison_pair()
                candidate["metadata"]["experiment"]["changed_modules"] = modules
                self.assertEqual(compare_results(baseline, candidate)["status"], "NOT_COMPARABLE")

    def test_placeholder_version_hash_is_not_comparable(self):
        baseline, candidate = comparison_pair()
        candidate["metadata"]["ea_sha256"] = "unknown-hash"
        self.assertEqual(compare_results(baseline, candidate)["status"], "NOT_COMPARABLE")

    def test_same_unknown_timezone_is_not_evidence_of_matching_clock(self):
        for timezone in ("SERVER_UNKNOWN", "unknown", None, "  "):
            with self.subTest(timezone=timezone):
                baseline, candidate = comparison_pair()
                baseline["metadata"]["timezone"] = candidate["metadata"]["timezone"] = timezone
                result = compare_results(baseline, candidate)
                self.assertEqual(result["status"], "NOT_COMPARABLE")
                self.assertIn("timezone", result["missing_fields"])

    def test_matching_nested_unknown_values_do_not_establish_known_conditions(self):
        cases = {"costs": {"spread": "observed", "execution": {"commission": None}},
                 "risk": {"single_pct": 1, "portfolio": {"total_pct": "unknown"}},
                 "contract": {"contract_size": 100, "volume": {"step": "UNKNOWN"}},
                 "test": {"start": "2026-02-01T00:00:00+00:00", "end": None}}
        for key,value in cases.items():
            with self.subTest(key=key):
                baseline, candidate = comparison_pair()
                baseline["metadata"][key] = candidate["metadata"][key] = value
                result = compare_results(baseline, candidate)
                self.assertEqual(result["status"], "NOT_COMPARABLE")
                self.assertIn(key, result["missing_fields"])

    def test_matching_empty_invalid_or_overlapping_splits_are_not_comparable(self):
        overlap = windows()
        overlap[1]["start"] = "2026-01-31T00:00:00+00:00"
        for splits in ([], {}, ["development"], overlap):
            with self.subTest(splits=splits):
                baseline, candidate = comparison_pair()
                baseline["metadata"]["splits"] = candidate["metadata"]["splits"] = splits
                result = compare_results(baseline, candidate)
                self.assertEqual(result["status"], "NOT_COMPARABLE")
                self.assertIn("splits", result["missing_fields"])

    def test_matching_invalid_market_hashes_are_not_comparable(self):
        for fingerprint in ("same-file", "a"*63, "z"*64, None):
            with self.subTest(fingerprint=fingerprint):
                baseline, candidate = comparison_pair()
                baseline["metadata"]["market_data_sha256"] = candidate["metadata"]["market_data_sha256"] = fingerprint
                result = compare_results(baseline, candidate)
                self.assertEqual(result["status"], "NOT_COMPARABLE")
                self.assertIn("market_data_sha256", result["missing_fields"])

    def test_matching_nonpositive_or_invalid_capital_is_not_comparable(self):
        for capital in (0, -500, None, True, float("inf")):
            with self.subTest(capital=capital):
                baseline, candidate = comparison_pair()
                baseline["metadata"]["initial_capital"] = candidate["metadata"]["initial_capital"] = capital
                result = compare_results(baseline, candidate)
                self.assertEqual(result["status"], "NOT_COMPARABLE")
                self.assertIn("initial_capital", result["missing_fields"])

    def test_matching_invalid_or_missing_test_window_is_not_comparable(self):
        for interval in ({"start": "2026-02-01"}, {"end": "2026-03-01"},
                         {"start": "invalid", "end": "2026-03-01"},
                         {"start": "2026-03-01", "end": "2026-03-01"},
                         {"start": "2026-04-01", "end": "2026-03-01"}):
            with self.subTest(interval=interval):
                baseline, candidate = comparison_pair()
                baseline["metadata"]["test"] = candidate["metadata"]["test"] = interval
                result = compare_results(baseline, candidate)
                self.assertEqual(result["status"], "NOT_COMPARABLE")
                self.assertIn("test", result["missing_fields"])

    def test_explicit_zero_costs_are_valid_known_values_in_synthetic_comparison(self):
        baseline, candidate = comparison_pair()
        costs = {"commission_per_lot": 0, "swap": 0, "spread": 0, "delay_ms": 0, "synthetic": True}
        baseline["metadata"]["costs"] = candidate["metadata"]["costs"] = costs
        self.assertEqual(compare_results(baseline, candidate)["status"], "CONDITIONS_MATCH_MT5_VERIFICATION_PENDING")


class CLIHoldoutTests(unittest.TestCase):
    def test_locked_final_cli_fails_before_loading_inputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = root/"final.json"
            manifest.write_text(json.dumps(final_manifest()), encoding="utf-8")
            with patch("gsm_analyzer.cli.load_dataset") as loader:
                errors = io.StringIO()
                with redirect_stderr(errors), redirect_stdout(io.StringIO()):
                    code = main(["analyze", "--manifest", str(manifest), "--output", str(root/"out")])
                self.assertEqual(code, 2)
                self.assertIn("FINAL_DATA_LOCKED", errors.getvalue())
                loader.assert_not_called()
            self.assertFalse((root/"out").exists())

    def test_compare_cli_writes_readable_pending_result_without_orders(self):
        baseline, candidate = comparison_pair()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, content in (("baseline", baseline), ("candidate", candidate)):
                (root/f"{name}.json").write_text(json.dumps(content), encoding="utf-8")
            with redirect_stdout(io.StringIO()):
                code = main(["compare", "--baseline", str(root/"baseline.json"), "--candidate", str(root/"candidate.json"),
                             "--output", str(root/"out")])
            self.assertEqual(code, 0)
            actual = json.loads((root/"out"/"comparison.json").read_text(encoding="utf-8"))
            self.assertEqual(actual["status"], "CONDITIONS_MATCH_MT5_VERIFICATION_PENDING")
            self.assertTrue((root/"out"/"comparison.csv").is_file())
            self.assertTrue(any((root/"out").glob("*.html")))


if __name__ == "__main__":
    unittest.main()
