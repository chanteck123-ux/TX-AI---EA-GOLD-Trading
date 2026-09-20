import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'scripts'))
from position_ledger import aggregate


def deal(id, entry, volume, profit=0, fee=-.04, position='1', magic='2'):
    return dict(Deal=str(id), PositionID=position, Magic=magic, Symbol='GOLD',
                Entry=str(entry), Type='0' if entry==0 else '1', Volume=str(volume),
                Profit=str(profit), Commission=str(fee), Swap='0', Fee='0', TimeMsc=str(id*1000))


class LedgerTests(unittest.TestCase):
    def test_partial_exits_one_trade(self):
        result=aggregate([deal(1,0,.02),deal(2,1,.01,5),deal(3,1,.01,8)],12.88)
        self.assertEqual(result['Complete']['Trades'],1)
        self.assertAlmostEqual(result['Complete']['NetUSD'],12.88)

    def test_partial_fill_one_trade(self):
        result=aggregate([deal(1,0,.01),deal(2,0,.01),deal(3,1,.02,10)])
        self.assertEqual(result['Complete']['Trades'],1)

    def test_open_not_counted(self):
        result=aggregate([deal(1,0,.02),deal(2,1,.01,5)])
        self.assertEqual(result['Complete']['Trades'],0)
        self.assertEqual(len(result['OpenPositions']),1)

    def test_duplicate_rejected(self):
        with self.assertRaisesRegex(ValueError,'DUPLICATE'):
            aggregate([deal(1,0,.01),deal(1,0,.01)])

    def test_mixed_owner_rejected(self):
        with self.assertRaisesRegex(ValueError,'MIXED'):
            aggregate([deal(1,0,.01),deal(2,1,.01,magic='3')])

    def test_overclose_rejected(self):
        with self.assertRaisesRegex(ValueError,'EXCEEDS'):
            aggregate([deal(1,0,.01),deal(2,1,.02)])

    def test_missing_cost_fails_reconciliation(self):
        with self.assertRaisesRegex(ValueError,'MISMATCH'):
            aggregate([deal(1,0,.01),deal(2,1,.01,10)],10)


if __name__=='__main__': unittest.main()
