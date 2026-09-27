import sys
import unittest
import json
from pathlib import Path
from urllib.parse import unquote

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from build_baseline_report import FROZEN_EX5, FROZEN_SOURCE, LANES, select_results
from test_progress_report import Links
from summarize_runs import ROOT, sha


class SelectionTests(unittest.TestCase):
    def setUp(self):
        self.rows = [dict(EX5SHA256=FROZEN_EX5, SourceSHA256=FROZEN_SOURCE, DelayMs=0,
                          CapitalUSD=500, Strategy=lane, Run=lane+'_001', Flags=[])
                     for lane in LANES]

    def test_four_real_lanes_required(self):
        self.assertEqual(4, len(select_results(self.rows)[0]))
        with self.assertRaisesRegex(ValueError, 'BASELINE_MISSING_Combined'):
            select_results(self.rows[:-1])

    def test_old_binary_cannot_fill_gap(self):
        self.rows[-1]['EX5SHA256'] = 'OLD'
        with self.assertRaises(ValueError):
            select_results(self.rows)

    def test_mismatching_conditions_are_rejected(self):
        self.rows[-1]['Flags'] = ['NATIVE_TEST_CONDITIONS_MISMATCH']
        with self.assertRaisesRegex(ValueError, 'BASELINE_EVIDENCE_FAIL'):
            select_results(self.rows)

    def test_capacity_is_separate_and_deduplicated(self):
        self.rows += [dict(self.rows[0], CapitalUSD=1000, Run='capacity_001'),
                      dict(self.rows[0], CapitalUSD=1000, Run='capacity_002')]
        baseline, capacity = select_results(self.rows)
        self.assertEqual(4, len(baseline))
        self.assertEqual(['capacity_002'], [r['Run'] for r in capacity])


class PublishedBaselineTests(unittest.TestCase):
    def test_local_links_and_native_hashes(self):
        report = ROOT/'reports/R_C00_BASELINE_CN.html'
        parser = Links()
        parser.feed(report.read_text(encoding='utf-8'))
        self.assertGreater(len(parser.hrefs), 20)
        for href in parser.hrefs:
            with self.subTest(href=href):
                self.assertTrue((report.parent/unquote(href)).resolve().is_file())
        inventory = json.loads((ROOT/'reports/R_C00_BASELINE_INVENTORY.json').read_text('utf-8'))
        self.assertEqual(set(inventory['StrategyChampions'].values()), {'NONE'})
        for row in inventory['Baseline']:
            run = row['Run']
            self.assertEqual(sha(ROOT/'reports/runs'/run/(run+'.htm')), row['ReportSHA256'])
            self.assertEqual(row['SetReportMismatches'], {})
            self.assertEqual(row['TestConditionMismatches'], {})
            self.assertEqual(row['SetReportAuditStatus'], 'COMPLETE')
            self.assertEqual(row['EX5SHA256'], FROZEN_EX5)


if __name__ == '__main__':
    unittest.main()
