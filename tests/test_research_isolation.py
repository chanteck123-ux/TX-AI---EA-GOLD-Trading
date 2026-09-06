import hashlib
import sys
import unittest
from pathlib import Path
from test_source_isolation import body, source, TOKEN

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
from audit_study import runner_fee


class ResearchIsolation(unittest.TestCase):
    def test_rc01_frozen(self):
        self.assertEqual(hashlib.sha256((ROOT/'src/GSM_FxPro_R_C01.mq5').read_bytes()).hexdigest().upper(),
                         'CCED6620AAA43B8D30F2DC88208CBEB799F6F26EFDC14A8F6CD05873EE195F4E')

    def test_scalping_no_protection(self):
        new = source(ROOT/'src/GSM_FxPro_RESEARCH.mq5')
        tokens = [m.group() for m in TOKEN.finditer(body(new, 'ManageScalpingPosition'))
                  if not m.group().startswith(('//', '/*'))]
        self.assertEqual(''.join(tokens), '{return;}')

    def test_unchanged_other_management_and_trend(self):
        old, new = [source(ROOT/'src'/p) for p in ('GSM_FxPro_R_C01.mq5', 'GSM_FxPro_RESEARCH.mq5')]
        for name in ('ManageSwingPosition', 'DetectSwingTrend', 'FindLastTwoPivots', 'MovingAverageTrend',
                     'DetectCandlestickSignal', 'IsScalpingWhitelist', 'CalcATR'):
            self.assertEqual(body(old, name), body(new, name), name)
        intraday = body(new, 'ManageIntradayPosition').replace('   if(InpIntradayRunner) { ManageIntradayRunner(); return; }\n', '')
        self.assertEqual(body(old, 'ManageIntradayPosition'), intraday)

    def test_runner_closed_bar_only(self):
        header = source(ROOT/'src/IntradayRunner.mqh')
        self.assertIn('CalcATR(rates,1,InpRunnerATRPeriod)', header)
        self.assertIn('rates[1].close', header)
        self.assertNotIn('rates[0]', header)
        self.assertNotIn('POSITION_PRICE_CURRENT', header)

    def test_split_fee_budget(self):
        self.assertAlmostEqual(runner_fee('.01', '7', 2), .08)
        self.assertAlmostEqual(runner_fee('.02', '7', 2), .15)
        self.assertAlmostEqual(runner_fee('.03', '7', 2), .22)
        self.assertAlmostEqual(runner_fee('.04', '7', 2), .28)
        for bad in ('nan', '-1', 'Infinity'):
            with self.assertRaises(ValueError):
                runner_fee(bad, '7', 2)


if __name__ == '__main__':
    unittest.main()
