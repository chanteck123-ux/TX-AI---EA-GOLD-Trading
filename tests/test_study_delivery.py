import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from build_study_delivery import verify, validate_links
from summarize_runs import sha


class DeliveryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.report = self.root / 'FINAL_REPORT_CN.html'
        self.report.write_text('<html><a href="code.mq5">Source</a><a href="SHA256.txt">Manifest</a></html>', encoding='utf-8')
        self.code = self.root / 'code.mq5'
        self.code.write_text('void OnTick() {}', encoding='utf-8')
        self.manifest = self.root / 'SHA256.txt'
        self.manifest.write_text(''.join(sha(p)+'  '+p.name+'\n' for p in (self.report, self.code)), encoding='utf-8')

    def test_valid_delivery(self):
        with contextlib.redirect_stdout(io.StringIO()) as output:
            verify(self.root)
        self.assertIn('RESEARCH_FILES_VERIFIED_NOT_TRADING_APPROVAL', output.getvalue())

    def test_content_tampering(self):
        self.code.write_text('changed', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'DELIVERY_HASH_MISMATCH'):
            verify(self.root)

    def test_manifest_path_escape(self):
        self.manifest.write_text('0'*64+'  ../outside.mq5\n', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'MANIFEST_PATH_ESCAPE'):
            verify(self.root)

    def test_extra_file_rejected(self):
        (self.root/'untracked.txt').write_text('extra', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'UNMANIFESTED_FILE'):
            verify(self.root)

    def test_broken_image_link(self):
        self.report.write_text('<img src="missing.png">', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'BROKEN_LOCAL_LINK'):
            validate_links(self.root)


if __name__ == '__main__':
    unittest.main()
