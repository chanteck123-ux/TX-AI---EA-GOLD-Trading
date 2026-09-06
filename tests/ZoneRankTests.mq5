#property strict
#property version "1.00"
#include "../src/ZoneRank.mqh"

int tests=0,failures=0;
void Check(const string name,const bool passed)
{
   tests++;
   if(!passed) failures++;
   PrintFormat("ZONE_RANK_TEST|%s|%s",name,passed ? "PASS" : "FAIL");
}

int OnInit()
{
   Check("first_eligible_zone",ZoneRankBetter(true,false,50,0,-10,100));
   Check("closer_beats_higher_score",ZoneRankBetter(true,true,1,8,2,90));
   Check("farther_loses_despite_score",!ZoneRankBetter(true,true,8,1,90,2));
   Check("equal_distance_retains_first",!ZoneRankBetter(true,true,1,1,90,2));
   Check("inside_zone_distance_zero",ZoneRankBetter(true,true,0,1,1,50));
   Check("inside_zone_tie_retains_first",!ZoneRankBetter(true,true,0,0,50,1));
   Check("non_scalp_higher_score_wins",ZoneRankBetter(false,true,8,1,90,2));
   Check("non_scalp_closer_not_enough",!ZoneRankBetter(false,true,1,8,2,90));
   Check("non_scalp_score_tie_retains_first",!ZoneRankBetter(false,true,0,8,2,2));
   int failuresBefore=failures;
   for(int d=0;d<20;d++)
      for(int best=0;best<20;best++)
         for(int s=-5;s<=5;s++)
         {
            if(ZoneRankBetter(true,true,(double)d,(double)best,(double)s,0)!=(d<best)) failures++;
            if(ZoneRankBetter(false,true,(double)d,(double)best,(double)s,0)!=(s>0)) failures++;
         }
   Check("ranking_sweep_8800",failures==failuresBefore);
   PrintFormat("ZONE_RANK_TEST_SUMMARY|Tests=%d|Failures=%d|SweepChecks=8800",tests,failures);
   return failures==0 ? INIT_SUCCEEDED : INIT_FAILED;
}
void OnTick() {}
double OnTester() { return failures==0 ? 1.0 : -1.0; }
