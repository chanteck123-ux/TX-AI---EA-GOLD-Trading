import hashlib
import unittest
from pathlib import Path

from test_source_isolation import body, source, TOKEN

ROOT = Path(__file__).resolve().parents[1]


class CandidateIsolation(unittest.TestCase):
    def test_control_bytes_frozen(self):
        self.assertEqual(hashlib.sha256((ROOT/'src/GSM_FxPro_R_C00.mq5').read_bytes()).hexdigest().upper(),
                         '989F19C997F5B095A67727BF0C88492B3777F2CCF2682A02D954DBBE18CAE19A')

    def test_only_zone_ranking_and_identity_changed(self):
        base = source(ROOT/'src/GSM_FxPro_R_C00.mq5').replace('\r\n', '\n')
        new = source(ROOT/'src/GSM_FxPro_S_C01.mq5').replace('\r\n', '\n')
        reverted = new.replace(body(new, 'FindBestSDZone'), body(base, 'FindBestSDZone'))
        reverted = reverted.replace('#include "ZoneRank.mqh"\n', '')
        reverted = reverted.replace('#property version   "4.21"', '#property version   "4.20"')
        reverted = reverted.replace('S-C01 research: Scalping distance-only zone ranking. Not Champion; real-account execution disabled.',
                                    'R-C00 FxPro risk-normalized research baseline derived from V4.00. Not Champion; real-account execution disabled.')
        self.assertEqual(base, reverted)
        changed = body(new, 'FindBestSDZone')
        self.assertIn('ZoneRankBetter(strategy==STRATEGY_SCALPING,best.valid,', changed)
        self.assertIn('bestDistance=dist;', changed)

    def test_scalp_has_no_profit_protection(self):
        new = source(ROOT/'src/GSM_FxPro_S_C01.mq5')
        tokens = [m.group() for m in TOKEN.finditer(body(new, 'ManageScalpingPosition'))
                  if not m.group().startswith(('//', '/*'))]
        self.assertEqual(''.join(tokens), '{return;}')


if __name__ == '__main__':
    unittest.main()
