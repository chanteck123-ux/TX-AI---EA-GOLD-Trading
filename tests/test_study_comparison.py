import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from study_comparison import input_delta, validate_changes
from portfolio_audit import exposure


class ComparisonTests(unittest.TestCase):
    def test_hidden_risk_change_rejected(self):
        with self.assertRaises(ValueError):
            validate_changes({'InpResearchSingleRiskPct':['1','2']},{'InpIntradayRunner'})

    def test_audit_identity_ignored_not_volume(self):
        self.assertEqual(input_delta({'InpAuditRunLabel':'a','lot':'.01'},
                                     {'InpAuditRunLabel':'b','lot':'.02'}),{'lot':['.01','.02']})

    def test_one_declared_module(self):
        validate_changes({'InpIntradayRunner':['false','true']},{'InpIntradayRunner'})

    def test_partial_does_not_inflate_concurrency(self):
        rows=[dict(Deal='1',PositionID='1',Magic='a',Entry='0',Type='0',Volume='.02',TimeMsc='1'),
              dict(Deal='2',PositionID='1',Magic='a',Entry='1',Type='1',Volume='.01',TimeMsc='2'),
              dict(Deal='3',PositionID='2',Magic='b',Entry='0',Type='1',Volume='.01',TimeMsc='3'),
              dict(Deal='4',PositionID='1',Magic='a',Entry='1',Type='1',Volume='.01',TimeMsc='4')]
        r=exposure(rows)
        self.assertEqual(r['PeakPositions'],2)
        self.assertTrue(r['ObservedOppositeExposure'])
        self.assertTrue(r['PositionLimitPass'])
        self.assertEqual(r['UnclosedPositions'],1)
        self.assertIsNone(r['PeakTickMargin'])

    def test_exit_without_entry_rejected(self):
        with self.assertRaises(ValueError):
            exposure([dict(Deal='1',PositionID='1',Entry='1',Volume='.01',TimeMsc='1')])


if __name__=='__main__': unittest.main()
