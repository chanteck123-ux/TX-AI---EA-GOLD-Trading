"""File/config generation tests. EX5 fixture bytes are explicitly synthetic, never trading binaries."""
from __future__ import annotations

import configparser
import importlib.util
from pathlib import Path
import tempfile
import unittest

ANALYZER = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("make_mt5_test_configs", ANALYZER / "tools/make_mt5_test_configs.py")
assert SPEC is not None and SPEC.loader is not None
generator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generator)


class MT5ConfigTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.inputs = self.root / "inputs"
        self.inputs.mkdir()
        self.args = dict(output_dir=self.root / "output", run_label="SYNTHETIC_IO_TEST", symbol="GOLD",
                         from_date="2026-01-05", end_exclusive="2026-08-27", period="M30", delay_ms=25)
        for role in ("baseline", "candidate"):
            set_path = self.inputs / f"{role}.set"
            # Intentional UTF-16 and CRLF fixture to verify exact copying.
            set_path.write_bytes(("; SYNTHETIC TEST DATA\r\nInpResearchSingleRiskPct=1||1||0||1||N\r\n"
                                  + f"InpExampleModule={'false' if role == 'baseline' else 'true'}\r\n").encode("utf-16"))
            ex5_path = self.inputs / f"{role}.ex5"
            ex5_path.write_bytes(b"SYNTHETIC_IO_FIXTURE_NOT_A_COMPILED_EX5\x00" + role.encode())
            self.args[f"{role}_set"] = set_path
            self.args[f"{role}_ex5"] = ex5_path

    def test_matching_conditions_safe_flags_and_byte_exact_input_copies(self):
        before = {p: p.read_bytes() for p in self.inputs.iterdir()}
        manifest = generator.generate_configs(**self.args)
        self.assertEqual(before, {p: p.read_bytes() for p in self.inputs.iterdir()})
        configs = []
        for role in ("baseline", "candidate"):
            ini = configparser.ConfigParser()
            ini.read(self.args["output_dir"] / f"{role}.ini", encoding="utf-8")
            self.assertEqual(dict(ini["Experts"]), {"allowlivetrading": "0", "allowdllimport": "0", "enabled": "0"})
            for key, value in {"Model": "4", "ExecutionMode": "25", "Optimization": "0",
                               "UseRemote": "0", "UseCloud": "0", "ReplaceReport": "0"}.items():
                self.assertEqual(ini["Tester"][key], value)
            common = dict(ini["Tester"])
            for key in ("expert", "expertparameters", "report"):
                common.pop(key)
            configs.append(common)
            output = self.args["output_dir"]
            self.assertEqual((output / f"MQL5/Experts/GSMAnalyzer/SYNTHETIC_IO_TEST/{role}.ex5").read_bytes(),
                             self.args[f"{role}_ex5"].read_bytes())
            self.assertEqual((output / f"MQL5/Profiles/Tester/GSMAnalyzer_SYNTHETIC_IO_TEST_{role}.set").read_bytes(),
                             self.args[f"{role}_set"].read_bytes())
        self.assertEqual(configs[0], configs[1])
        self.assertEqual(configs[0]["todate"], "2026.08.27")
        self.assertFalse(manifest["terminal_started"])
        self.assertIn("NOT_RUN", manifest["status"])
        self.assertIn("UNVERIFIED", manifest["source_binary_correspondence"])
        self.assertEqual(manifest["set_parameter_differences"], [
            {"parameter": "InpExampleModule", "baseline": "false", "candidate": "true"}])
        for name, digest in manifest["files"].items():
            self.assertEqual(generator.sha256((self.args["output_dir"] / name).read_bytes()), digest)

    def test_missing_ex5_never_generates_a_fake_binary_or_output(self):
        self.args["candidate_ex5"].unlink()
        with self.assertRaises(OSError):
            generator.generate_configs(**self.args)
        self.assertFalse(self.args["output_dir"].exists())

    def test_existing_output_never_overwrites_user_files(self):
        self.args["output_dir"].mkdir()
        file = self.args["output_dir"] / "baseline.ini"
        file.write_bytes(b"user original")
        with self.assertRaisesRegex(ValueError, "拒绝覆盖"):
            generator.generate_configs(**self.args)
        self.assertEqual(file.read_bytes(), b"user original")

    def test_invalid_dates_are_rejected_before_output(self):
        self.args["end_exclusive"] = self.args["from_date"]
        with self.assertRaises(ValueError):
            generator.generate_configs(**self.args)
        self.assertFalse(self.args["output_dir"].exists())

    def test_nonfinite_capital_is_rejected(self):
        self.args["deposit"] = "NaN"
        with self.assertRaises(ValueError):
            generator.generate_configs(**self.args)
        self.assertFalse(self.args["output_dir"].exists())

    def test_native_random_is_not_accepted_as_fixed_delay(self):
        self.args["delay_ms"] = -1
        with self.assertRaisesRegex(ValueError, "固定延迟"):
            generator.generate_configs(**self.args)
        self.assertFalse(self.args["output_dir"].exists())

    def test_manifest_redacts_credentials_without_changing_set(self):
        for role in ("baseline", "candidate"):
            self.args[f"{role}_set"].write_bytes(
                f"InpPassword=synthetic_secret_{role}\nInpResearchSingleRiskPct=1\n".encode())
        manifest = generator.generate_configs(**self.args)
        difference = manifest["set_parameter_differences"][0]
        self.assertEqual(difference["baseline"], "<REDACTED_CREDENTIAL_VALUE>")
        self.assertEqual(difference["candidate"], "<REDACTED_CREDENTIAL_VALUE>")
        self.assertNotIn("synthetic_secret", (self.args["output_dir"] / "test_manifest.json").read_text())
        copied = self.args["output_dir"] / "MQL5/Profiles/Tester/GSMAnalyzer_SYNTHETIC_IO_TEST_baseline.set"
        self.assertEqual(copied.read_bytes(), self.args["baseline_set"].read_bytes())

    def test_ini_injection_and_non_gold_symbol_are_rejected(self):
        for symbol in ("GOLD\nUseCloud=1", "EURUSD"):
            with self.subTest(symbol=symbol):
                self.args["symbol"] = symbol
                with self.assertRaises(ValueError):
                    generator.generate_configs(**self.args)
        self.assertFalse(self.args["output_dir"].exists())

    def test_cli_generates_without_starting_a_terminal(self):
        argv = []
        for key, value in self.args.items():
            argv.extend(["--" + key.replace("_", "-"), str(value)])
        self.assertEqual(generator.main(argv), 0)
        self.assertTrue((self.args["output_dir"] / "test_manifest.json").is_file())


if __name__ == "__main__":
    unittest.main()
