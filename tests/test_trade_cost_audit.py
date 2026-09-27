import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'scripts'))
from trade_cost_audit import audit, estimated_fee, fee_evidence


class Costs(unittest.TestCase):
    def setUp(self):
        self.rows = [
            ['时间','成交','交易品种','类型','趋势','交易量','价位','订单','手续费','库存费','盈利','结余','注释'],
            ['2026.01.05 01:00:00','2','GOLD','buy','in','0.01','100','2','-0.04','0','0','999.96',''],
            ['2026.01.05 02:00:00','3','GOLD','sell','out','0.01','107','3','-0.04','0','7','1006.92','']]
        self.trades = [dict(PositionID='2', ExitDeal='3', EntryTime='2026.01.05 01:00:00',
                            ExitTime='2026.01.05 02:00:00', Direction='BUY', Entry='100', Volume='0.01',
                            Profit='6.92', InitialSL='95', ExitReason='DEAL_REASON_TP',
                            ActualSLRiskMoney='5', LossClassification='PROFIT', ChaseEntry='NO', MFE_Money='7', MAE_Money='1')]

    def test_complete_net_includes_both_commissions(self):
        result = audit(self.rows, self.trades, 1, 6.92, 7)
        self.assertEqual(result['Status'], 'RECONCILED_COMPLETE_POSITIONS')
        self.assertAlmostEqual(result['NetStats']['ExpectancyNetUSD'], 6.92)
        self.assertAlmostEqual(result['CommissionUSD'], -0.08)
        self.assertAlmostEqual(result['MaximumFeeShortfallUSD'], 0.01)
        self.assertIn('FEE_ESTIMATE_UNDERSTATED', result['Flags'])

    def test_partial_exits_not_counted_as_whole_trades(self):
        rows = self.rows+[list(self.rows[-1])]
        result = audit(rows, self.trades, 1, 6.92, 7)
        self.assertIn('PARTIAL_OR_COMPLEX_POSITION_AUDIT_REQUIRED', result['Flags'])
        self.assertNotIn('NetStats', result)

    def test_wrong_exit_link_fails(self):
        self.trades[0]['ExitDeal'] = '999'
        self.assertIn('POSITION_DEAL_LINK_MISSING', audit(self.rows, self.trades, 1, 6.92, 7)['Flags'])

    def test_wrong_net_fails(self):
        self.trades[0]['Profit'] = '7'
        self.assertIn('COMPLETE_POSITION_NET_MISMATCH', audit(self.rows, self.trades, 1, 6.92, 7)['Flags'])

    def test_stop_gap_is_not_zero_risk(self):
        self.rows[-1][6] = '94.40'
        self.rows[-1][10] = '-5.6'
        self.trades[0].update(Profit='-5.68', ExitReason='DEAL_REASON_SL')
        result = audit(self.rows, self.trades, 1, -5.68, 7)
        self.assertAlmostEqual(result['MaximumStopAdversePrice'], 0.6)

    def test_no_trades_does_not_invent_statistics(self):
        result = audit([], [], 0, 0, 7)
        self.assertEqual(result['Status'], 'NO_TRADES')
        self.assertNotIn('NetStats', result)

    def test_rounded_fee_reconciles_native_commission(self):
        result = audit(self.rows, self.trades, 1, 6.92, 7, 'PER_SIDE_CEILING', 2)
        self.assertEqual(result['Flags'], [])
        self.assertEqual(result['MaximumFeeShortfallUSD'], 0)

    def test_fee_math_and_invalid_model(self):
        self.assertEqual(estimated_fee('.01', 7, 'PER_SIDE_CEILING', 2), .08)
        self.assertEqual(estimated_fee('.02', 7, 'PER_SIDE_CEILING', 2), .14)
        self.assertEqual(estimated_fee('.01', 7, 'PER_SIDE_CEILING', 3), .07)
        with self.assertRaises(ValueError):
            estimated_fee('.01', 7, 'UNKNOWN', 2)
        for volume, rate in [(-1, -1), ('NaN', 7), ('.01', 'Infinity')]:
            with self.assertRaises(ValueError):
                estimated_fee(volume, rate)

    def test_fee_proof_requires_actual_plan_fields(self):
        p = dict(FeeModel='PER_SIDE_CEILING', CurrencyDigits='2', Volume='.01',
                 FeeEstimateUSDPerLot='7', FeeBudgetUSD='.08')
        self.assertEqual(fee_evidence([p], 7)['Flags'], [])
        p['FeeBudgetUSD'] = '.07'
        self.assertIn('FEE_PLAN_MODEL_NOT_VERIFIED', fee_evidence([p], 7)['Flags'])
        self.assertIn('FEE_PLAN_MODEL_NOT_VERIFIED', fee_evidence([p, {}], 7)['Flags'])
        p['FeeBudgetUSD'] = 'NaN'
        self.assertIn('FEE_PLAN_MODEL_NOT_VERIFIED', fee_evidence([p], 7)['Flags'])
        self.assertEqual(fee_evidence([], 7)['Model'], 'UNOBSERVED')


if __name__ == '__main__':
    unittest.main()
