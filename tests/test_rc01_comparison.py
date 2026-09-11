import copy
import json
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
from compare_rc01 import compare, select, SOURCE, EX5


class FeeComparison(unittest.TestCase):
    def setUp(self):
        self.base = json.loads((ROOT/'reports/runs/R_C00_Scalping_USD1000_D0_20260906_203616/AUDIT.json').read_text('utf-8'))
        self.candidate = copy.deepcopy(self.base)
        self.candidate['Flags'].remove('FEE_ESTIMATE_UNDERSTATED')
        self.candidate['FeeModelEvidence'] = dict(Model='PER_SIDE_CEILING', CurrencyDigits=2, Flags=[])
        self.candidate['CompleteTradeCostAudit']['MaximumFeeShortfallUSD'] = 0

    def test_engineering_comparison_not_strategy_promotion(self):
        with patch('compare_rc01.fair', return_value='MATCH'), patch('compare_rc01.trade_signature', return_value=[]):
            result = compare(self.base, self.candidate)
        self.assertTrue(result['CompleteTradeSignaturesMatch'])
        self.assertIn('LINEAR_FEE_TO_PER_SIDE', result['ExplicitCodeDifference'])
        self.assertTrue(all(v in (0, None) for v in result['Delta'].values()))

    def test_remaining_fee_shortfall_rejected(self):
        self.candidate['CompleteTradeCostAudit']['MaximumFeeShortfallUSD'] = .01
        with patch('compare_rc01.fair', return_value='MATCH'):
            with self.assertRaisesRegex(ValueError, 'ROUNDED_FEE_VALIDATION_INCOMPLETE'):
                compare(self.base, self.candidate)

    def test_missing_fee_evidence_cannot_pass(self):
        self.candidate['FeeModelEvidence']['Model'] = 'UNOBSERVED'
        with patch('compare_rc01.fair', return_value='MATCH'):
            with self.assertRaises(ValueError):
                compare(self.base, self.candidate)

    def test_unknown_validation_flag_fails_closed(self):
        self.candidate['Flags'].append('NEW_UNEXPLAINED_EVIDENCE_ERROR')
        with patch('compare_rc01.fair', return_value='MATCH'):
            with self.assertRaisesRegex(ValueError, 'VALIDATION_EVIDENCE_FAIL'):
                compare(self.base, self.candidate)

    def test_missing_or_wrong_hash_cannot_be_selected(self):
        with self.assertRaisesRegex(ValueError, 'MISSING_PREREGISTERED_RUN'):
            select([self.base], 'Scalping', 1000, SOURCE, EX5)


if __name__ == '__main__':
    unittest.main()
