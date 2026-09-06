import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from build_study_report import choose, fmt, table
from summarize_runs import TableParser


class StudyReport(unittest.TestCase):
    def test_does_not_select_restart_as_primary(self):
        rows=[dict(CandidateID=x,Run=x+'_Intraday_USD2000_D0',CapitalUSD=2000,DelayMs=0,Strategy='Intraday')
              for x in ('I_C02_FIX2','I_C02_FIX2_RESTART')]
        self.assertEqual(choose(rows,'I_C02_FIX2')['CandidateID'],'I_C02_FIX2')

    def test_unknown_not_zero(self):
        self.assertNotEqual(fmt(None),fmt(0))

    def test_table_dimensions_and_escaping(self):
        t=TableParser();t.feed(table(['<A>','B'],[['x',3],['y',None]]))
        self.assertEqual([len(r) for r in t.rows],[2,2,2])
        self.assertIn('&lt;A&gt;',table(['<A>'],[]))


if __name__=='__main__':
    unittest.main()
