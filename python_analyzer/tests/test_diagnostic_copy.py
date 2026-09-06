"""Generator safety and source-preservation tests; no claim of MQL5 compilation."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("make_diagnostic_copy", ROOT / "python_analyzer/tools/make_diagnostic_copy.py")
assert SPEC is not None and SPEC.loader is not None
generator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generator)


@unittest.skipUnless((ROOT / "src/GSM_FxPro_RESEARCH.mq5").is_file(), "需仓库内已审阅 EA 源码")
class DiagnosticCopyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source_dir = self.root / "src"
        self.source_dir.mkdir()
        names = ["GSM_FxPro_RESEARCH.mq5", *generator.DEPENDENCY_SHA256]
        for name in names:
            (self.source_dir / name).write_bytes((ROOT / "src" / name).read_bytes())
        self.source = self.source_dir / "GSM_FxPro_RESEARCH.mq5"
        self.target = self.root / "new_copy"

    def test_separate_copy_preserves_original_and_all_dependencies(self):
        originals = {p.name: p.read_bytes() for p in self.source_dir.iterdir()}
        manifest = generator.build_copy(self.source, self.target)
        self.assertEqual(originals, {p.name: p.read_bytes() for p in self.source_dir.iterdir()})
        generated = (self.target / generator.OUTPUT_NAME).read_text(encoding="utf-8")
        for anchor, added in generator.INSERTIONS.items():
            self.assertEqual(generated.count(added), 1)
            generated = generated.replace(anchor + added, anchor, 1)
        self.assertEqual(generated.encode("utf-8"), originals[self.source.name])
        for name in generator.DEPENDENCY_SHA256:
            self.assertEqual((self.target / name).read_bytes(), originals[name])
        disk_manifest = json.loads((self.target / "diagnostic_manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest, disk_manifest)
        for name, digest in manifest["files"].items():
            self.assertEqual(generator.sha256((self.target / name).read_bytes()), digest)
        self.assertIn("UNCOMPILED", manifest["validation_status"])
        self.assertFalse(manifest["diagnostic_defaults"]["InpAnalyzerDiagnostics"])
        self.assertFalse(manifest["diagnostic_defaults"]["InpAnalyzerEquitySamples"])

    def test_rejects_changed_source_before_creating_output(self):
        self.source.write_bytes(self.source.read_bytes() + b"\n// unreviewed\n")
        with self.assertRaisesRegex(ValueError, "源 SHA256 不匹配"):
            generator.build_copy(self.source, self.target)
        self.assertFalse(self.target.exists())

    def test_rejects_changed_dependency_before_creating_output(self):
        dependency = self.source_dir / "RiskMath.mqh"
        dependency.write_bytes(dependency.read_bytes() + b"\n// changed\n")
        with self.assertRaisesRegex(ValueError, "依赖 SHA256 不匹配"):
            generator.build_copy(self.source, self.target)
        self.assertFalse(self.target.exists())

    def test_rejects_missing_dependency(self):
        (self.source_dir / "StudyEvidence.mqh").unlink()
        with self.assertRaisesRegex(ValueError, "依赖缺失"):
            generator.build_copy(self.source, self.target)
        self.assertFalse(self.target.exists())

    def test_existing_output_is_never_overwritten(self):
        self.target.mkdir()
        sentinel = self.target / generator.OUTPUT_NAME
        sentinel.write_bytes(b"existing user work")
        with self.assertRaisesRegex(ValueError, "输出目录已存在"):
            generator.build_copy(self.source, self.target)
        self.assertEqual(sentinel.read_bytes(), b"existing user work")
        self.assertEqual(len(list(self.target.iterdir())), 1)

    def test_hash_override_cannot_bypass_reviewed_source(self):
        with self.assertRaisesRegex(ValueError, "不能用命令行绕过"):
            generator.build_copy(self.source, self.target, "0" * 64)
        self.assertFalse(self.target.exists())

    def test_repeat_injection_is_rejected(self):
        generator.build_copy(self.source, self.target)
        second = self.root / "second_copy"
        with self.assertRaisesRegex(ValueError, "已经注入"):
            generator.build_copy(self.target / generator.OUTPUT_NAME, second)
        self.assertFalse(second.exists())

    def test_duplicate_function_anchor_is_rejected(self):
        source = self.source.read_text(encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "锚点必须唯一"):
            generator.inject_observers(source + generator.TICK_ANCHOR)


if __name__ == "__main__":
    unittest.main()
