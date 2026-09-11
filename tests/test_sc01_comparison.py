import json
import sys
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
from compare_sc01 import fair, trade_signature
from test_progress_report import Links


class ComparisonTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = json.loads((ROOT/'reports/S_C01_COMPARISON.json').read_text('utf-8'))

    def test_comparison_verified_not_promoted(self):
        self.assertEqual(self.report['Verdict'], 'REJECT_AS_CHAMPION_NO_OBSERVED_IMPROVEMENT')
        self.assertEqual([p['CapitalUSD'] for p in self.report['Comparisons']], [500, 1000])
        for pair in self.report['Comparisons']:
            self.assertTrue(pair['CompleteTradeSignaturesMatch'])
            self.assertTrue(all(v in (0, None) for v in pair['Delta'].values()))
            self.assertTrue(fair(pair['Control'], pair['Candidate']).startswith('MATCH'))

    def test_capital_mismatch_is_not_fair(self):
        pair = self.report['Comparisons'][0]
        changed = dict(pair['Candidate'], CapitalUSD=10000)
        with self.assertRaisesRegex(ValueError, 'UNFAIR_COMPARISON'):
            fair(pair['Control'], changed)

    def test_risk_parameter_mismatch_is_not_fair(self):
        pair = self.report['Comparisons'][0]
        with patch('compare_sc01.set_values', side_effect=[{'risk':1}, {'risk':2}]):
            with self.assertRaisesRegex(ValueError, '.set_CONDITIONS_CHANGED'):
                fair(pair['Control'], pair['Candidate'])

    def test_missing_trade_file_requires_native_zero_trade_proof(self):
        row = dict(self.report['Comparisons'][0]['Control'], Run='NONEXISTENT_TEST_FIXTURE')
        self.assertEqual(trade_signature(row), [])
        row['Trades'] = 1
        with self.assertRaises(FileNotFoundError):
            trade_signature(row)

    def test_report_links_exist(self):
        report = ROOT/'reports/S_C01_REPORT_CN.html'
        parser = Links()
        parser.feed(report.read_text('utf-8'))
        self.assertGreater(len(parser.hrefs), 20)
        for href in parser.hrefs:
            self.assertTrue((report.parent/unquote(href)).resolve().is_file(), href)


if __name__ == '__main__':
    unittest.main()
