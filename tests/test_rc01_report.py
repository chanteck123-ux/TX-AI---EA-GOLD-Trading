import json
import sys
import unittest
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
from summarize_runs import sha
from compare_rc01 import MATRIX, SOURCE, EX5, compare, proof
from test_progress_report import Links


class FeeReport(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = json.loads((ROOT/'reports/R_C01_COMPARISON.json').read_text('utf-8'))

    def test_six_fair_pairs_no_strategy_promotion(self):
        r = self.result
        self.assertEqual(r['Verdict'], 'ENGINEERING_CORRECTION_VALIDATED_TESTED_CASES_NOT_CHAMPION')
        self.assertEqual([(p['Strategy'],p['CapitalUSD']) for p in r['Comparisons']], MATRIX)
        self.assertTrue(all(v == 'NONE' for v in r['NewChampions'].values()))
        for pair in r['Comparisons']:
            self.assertEqual(pair['Candidate']['SourceSHA256'], SOURCE)
            self.assertEqual(pair['Candidate']['EX5SHA256'], EX5)
            checked = compare(pair['Control'],pair['Candidate'])
            self.assertTrue(checked['CompleteTradeSignaturesMatch'])
            self.assertTrue(all(v in (None,0) for v in checked['Delta'].values()))

    def test_actual_fill_fee_validation_is_not_zero_trade_evidence(self):
        filled = [p['Candidate'] for p in self.result['Comparisons'] if p['Candidate']['Trades']]
        self.assertEqual(len(filled), 2)
        self.assertEqual([r['Trades'] for r in filled], [20,20])
        for r in filled:
            self.assertEqual(r['FeeModelEvidence']['Model'], 'PER_SIDE_CEILING')
            self.assertEqual(r['CompleteTradeCostAudit']['MaximumFeeShortfallUSD'], 0)

    def test_compile_and_unit_proof(self):
        self.assertEqual(self.result['ValidationProof'], proof())

    def test_report_links_and_sha256_manifest(self):
        report = ROOT/'reports/R_C01_REPORT_CN.html'
        links = Links()
        links.feed(report.read_text('utf-8'))
        self.assertGreater(len(links.hrefs), 60)
        for href in links.hrefs:
            self.assertTrue((report.parent/unquote(href)).resolve().is_file(), href)
        for line in (ROOT/'reports/R_C01_SHA256.txt').read_text('ascii').splitlines():
            digest, path = line.split('  ',1)
            self.assertEqual(sha(ROOT/path), digest)


if __name__ == '__main__':
    unittest.main()
