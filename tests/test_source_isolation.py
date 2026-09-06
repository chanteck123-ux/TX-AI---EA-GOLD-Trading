"""Static boundaries only; these do not replace native broker integration tests."""
import hashlib
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT.parent/'baseline-audit-20260905/package/CODE/GSM_Gold_3SOP_EA_CHAMPION.mq5'
CURRENT = ROOT/'src/GSM_FxPro_R_C00.mq5'
EXPECTED = 'AC9826E6EF4959562B9079A1FF9B8CBB35E5E8C2A913E431488CA5C900D1FF60'
TOKEN = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\S')


def source(path):
    raw = path.read_bytes()
    return raw.decode('utf-16' if raw[:2] in (b'\xff\xfe', b'\xfe\xff') else 'utf-8-sig')


def body(text, name):
    match = re.search(r'(?m)^\w+\s+'+re.escape(name)+r'\([^;{}]*\)\s*\{', text)
    if not match:
        raise AssertionError('Function definition not found: '+name)
    start = match.end()-1
    depth = 0
    for token in TOKEN.finditer(text, start):
        value = token.group()
        if value == '{':
            depth += 1
        elif value == '}':
            depth -= 1
            if depth == 0:
                return text[start:token.end()]
    raise AssertionError('Unclosed function: '+name)


class Isolation(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.old, cls.new = source(BASE), source(CURRENT)

    def test_original_hash(self):
        self.assertEqual(hashlib.sha256(BASE.read_bytes()).hexdigest().upper(), EXPECTED)

    def test_entry_and_other_managers_unchanged(self):
        for name in ['RunScalpingM5', 'ExecuteScalpFirstTouch', 'RefreshIntradayM30Zones',
                     'MonitorIntradayM30FirstTouch', 'ExecuteIntradayFirstTouch', 'RunSwingD1',
                     'FindBestSDZone', 'FindBestIntradaySDZone',
                     'ManageIntradayPosition', 'ManageSwingPosition']:
            with self.subTest(function=name):
                self.assertEqual(body(self.old, name), body(self.new, name))

    def test_scalping_manager_no_protection(self):
        tokens = [m.group() for m in TOKEN.finditer(body(self.new, 'ManageScalpingPosition'))
                  if not m.group().startswith(('//', '/*'))]
        self.assertEqual(''.join(tokens), '{return;}')

    def test_lexer_ignores_comments_and_strings(self):
        sample = 'void F() { Print("}"); /* } */ if(true) { return; } }\nvoid G(){}'
        self.assertEqual(body(sample, 'F'), '{ Print("}"); /* } */ if(true) { return; } }')


if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(Isolation)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    record = dict(Scope='STATIC_SOURCE_BOUNDARIES_ONLY', Tests=result.testsRun,
                  Failures=len(result.failures), Errors=len(result.errors),
                  SourceSHA256=hashlib.sha256(CURRENT.read_bytes()).hexdigest().upper(),
                  NativeProtectionIntegration='NOT_EXECUTED')
    (ROOT/'reports/SOURCE_ISOLATION.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    raise SystemExit(not result.wasSuccessful())
