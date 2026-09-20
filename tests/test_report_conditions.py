import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from summarize_runs import verify_conditions


class NativeConditionsTests(unittest.TestCase):
    def setUp(self):
        self.record = dict(Symbol='GOLD', Leverage=100, Period='M5',
                           FromDate='2026.01.05', ToDate='2026.08.26', Capital=500,
                           TerminalVersion='5.0.0.6182')
        self.fields = {'公司:': 'FxPro Markets Ltd.', '交易品种:': 'GOLD',
                       '货币:': 'USD', '杠杆:': '1:100', '初始入金:': '500.00',
                       '期间:': 'M5 (2026.01.05 - 2026.08.26)'}
        self.header = '<table><tr><td>FxPro-MT5 Demo (Build 6182)</td></tr></table>'

    def test_matching_native_report(self):
        issues, header = verify_conditions(self.record, self.fields, self.header)
        self.assertEqual({}, issues)
        self.assertEqual('FxPro-MT5 Demo (Build 6182)', header)

    def test_each_condition_mismatch(self):
        for key in self.fields:
            with self.subTest(key=key):
                fields = dict(self.fields)
                fields[key] = '1000' if key == '初始入金:' else 'WRONG'
                issues, _ = verify_conditions(self.record, fields, self.header)
                self.assertIn(key, issues)

    def test_other_broker_header_is_not_fxpro_evidence(self):
        issues, _ = verify_conditions(self.record, self.fields,
                                     self.header.replace('FxPro-MT5 Demo', 'Other Broker'))
        self.assertIn('ServerHeader', issues)

    def test_changed_build_is_detected(self):
        issues, _ = verify_conditions(self.record, self.fields, self.header.replace('6182', '6140'))
        self.assertIn('Build', issues)


if __name__ == '__main__':
    unittest.main()
