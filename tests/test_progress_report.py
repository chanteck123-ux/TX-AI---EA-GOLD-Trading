"""Read-only content and evidence checks; no browser or visual validation."""
import json
import unittest
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []

    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            self.hrefs.extend(v for k, v in attrs if k == 'href')


class Report(unittest.TestCase):
    def test_local_links_exist(self):
        report = ROOT/'reports/FXPRO_R_C00_PROGRESS_CN.html'
        parser = Links()
        parser.feed(report.read_text(encoding='utf-8'))
        self.assertGreater(len(parser.hrefs), 10)
        for href in parser.hrefs:
            with self.subTest(href=href):
                self.assertTrue((report.parent/unquote(href)).resolve().is_file())

    def test_results_have_no_invented_lanes_or_pf(self):
        rows = json.loads((ROOT/'reports/R_C00_RESULTS.json').read_text(encoding='utf-8'))
        self.assertEqual({r['Strategy'] for r in rows}, {'Scalping', 'Intraday'})
        for row in rows:
            self.assertEqual(row['Trades'], 0)
            self.assertIsNone(row['ProfitFactor'])
            self.assertIsNone(row['WinRatePct'])
            self.assertIsNone(row['RecoveryEquity'])
            self.assertEqual(row['SetReportMismatches'], {})
            self.assertEqual(row['SetReportAuditStatus'], 'PARTIAL_DECLARATIONS_ONLY')

    def test_no_promotion_or_visual_pass(self):
        proof = json.loads((ROOT/'reports/PROGRESS_EVIDENCE.json').read_text(encoding='utf-8'))
        self.assertEqual(set(proof['NewChampion'].values()), {'NONE'})
        self.assertEqual(proof['LatestRevisionBacktest'], 'NOT_COMPLETED')
        self.assertEqual(proof['ProfitProtectionIntegration'], 'NOT_EXECUTED')
        self.assertTrue(proof['ReportVisualQA'].startswith('NOT_EXECUTED'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
