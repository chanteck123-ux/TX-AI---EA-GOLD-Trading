import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
from audit_scalp_opportunities import classify


class Opportunities(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = json.loads((ROOT/'reports/SCALP_OPPORTUNITY_AUDIT.json').read_text('utf-8'))

    def test_exclusive_groups_reconcile(self):
        r = self.result
        self.assertEqual(sum(r['Groups'].values()), r['EvaluatedUniqueZones'])
        self.assertEqual(r['EvaluatedUniqueZones']+len(r['TouchesNotEvaluated']), r['FirstTouches'])
        self.assertEqual(r['Groups']['EMA_FAIL_RSI_FAIL'], 74)
        self.assertEqual(r['Groups']['EMA_FAIL_RSI_PASS'], 73)

    def test_broken_events_are_after_touch_at_close(self):
        self.assertEqual(self.result['MissingWithBrokenAfterTouch'], 221)
        self.assertEqual(self.result['MissingBrokenBeforeNominalClose'], 0)
        self.assertTrue(all(p['SecondsAfterNominalM5Close'] == 0 for p in self.result['TouchesNotEvaluated']))

    def test_untraded_profit_not_invented(self):
        self.assertEqual(self.result['UntradedCounterfactualNet'], 'NOT_MEASURED')
        self.assertEqual(self.result['MissedProfitableTrades'], 'UNKNOWN')
        self.assertFalse(self.result['NewChampion'])

    def test_unknown_reason_requires_review(self):
        self.assertEqual(classify(dict(RejectReason='unknown', RawCore='YES', Accepted='NO')), 'UNCLASSIFIED')


if __name__ == '__main__':
    unittest.main()
