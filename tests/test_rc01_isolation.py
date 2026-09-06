import hashlib
import unittest
from pathlib import Path

from test_source_isolation import body, source, TOKEN

ROOT = Path(__file__).resolve().parents[1]


class FeeCandidateIsolation(unittest.TestCase):
    def test_frozen_sources(self):
        hashes = {
            'GSM_FxPro_R_C00.mq5': '989F19C997F5B095A67727BF0C88492B3777F2CCF2682A02D954DBBE18CAE19A',
            'StrictRisk.mqh': '1BC00A2E53A37F9633705B4A8391169B8C2F7844770F1E07A9EC836B0BD46C65',
            'RiskMath.mqh': 'E3F453FC321F5EBDFFBDAB9061C6380F93F4B100AA5689444CCD48EB5A289E22',
            'GSM_FxPro_S_C01.mq5': '1C851244DD2A321C2E44917DE8B9371F24E6A74E1E06E52AE36188245BE50F6E',
        }
        for name, expected in hashes.items():
            with self.subTest(file=name):
                self.assertEqual(hashlib.sha256((ROOT/'src'/name).read_bytes()).hexdigest().upper(), expected)

    def test_entire_ea_unchanged_except_identity_and_risk_include(self):
        old = source(ROOT/'src/GSM_FxPro_R_C00.mq5').replace('\r\n', '\n')
        new = source(ROOT/'src/GSM_FxPro_R_C01.mq5').replace('\r\n', '\n')
        new = new.replace('#property version   "4.22"', '#property version   "4.20"')
        new = new.replace('R-C01 research: currency-precision fee risk reservation.',
                          'R-C00 FxPro risk-normalized research baseline derived from V4.00.')
        new = new.replace('#include "StrictRiskRounded.mqh"', '#include "StrictRisk.mqh"')
        self.assertEqual(old, new)

    def test_risk_header_scope(self):
        old = source(ROOT/'src/StrictRisk.mqh').replace('\r\n', '\n')
        new = source(ROOT/'src/StrictRiskRounded.mqh').replace('\r\n', '\n')
        for name in ['ResearchReservedRisk', 'ResearchUnitRisk', 'ResearchSize', 'ResearchValidateOrder']:
            new = new.replace(body(new, name), body(old, name))
        new = new.replace('GSM_RESEARCH_STRICT_RISK_ROUNDED', 'GSM_RESEARCH_STRICT_RISK')
        new = new.replace('#include "FeeRiskMath.mqh"', '#include "RiskMath.mqh"')
        self.assertEqual(old, new)

    def test_scalping_still_no_profit_protection(self):
        new = source(ROOT/'src/GSM_FxPro_R_C01.mq5')
        tokens = [m.group() for m in TOKEN.finditer(body(new, 'ManageScalpingPosition'))
                  if not m.group().startswith(('//', '/*'))]
        self.assertEqual(''.join(tokens), '{return;}')


if __name__ == '__main__':
    unittest.main()
