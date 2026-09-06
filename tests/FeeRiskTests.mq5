#property strict
#property version "1.00"
#include "../src/FeeRiskMath.mqh"

int tests=0,failures=0;
void Check(const string name,const bool passed)
{
   tests++;
   if(!passed) failures++;
   PrintFormat("FEE_RISK_TEST|%s|%s",name,passed ? "PASS" : "FAIL");
}
bool Equal(const double a,const double b) { return MathAbs(a-b)<1e-8; }

int OnInit()
{
   Check("one_cent_roundtrip_gap_fixed",Equal(RiskRoundedFee(.01,7,2),.08));
   Check("exact_cent_fee_not_raised",Equal(RiskRoundedFee(.02,7,2),.14));
   Check("five_hundredths_lot",Equal(RiskRoundedFee(.05,7,2),.36));
   Check("third_decimal_currency",Equal(RiskRoundedFee(.01,7,3),.07));
   Check("zero_decimal_currency",Equal(RiskRoundedFee(.01,7,0),2));
   Check("zero_fee",Equal(RiskRoundedFee(.01,0,2),0));
   Check("zero_volume",Equal(RiskRoundedFee(0,7,2),0));
   Check("tiny_positive_not_erased",Equal(RiskRoundedFee(.01,1e-12,2),.02));
   Check("negative_fee_invalid",RiskRoundedFee(.01,-7,2)<0);
   Check("negative_volume_invalid",RiskRoundedFee(-.01,7,2)<0);
   Check("negative_precision_invalid",RiskRoundedFee(.01,7,-1)<0);
   Check("unsupported_precision_invalid",RiskRoundedFee(.01,7,9)<0);
   Check("invalid_cost_price",RiskRoundedCost(0,.01,7,2)<0);
   Check("old_837_boundary_rejected",Equal(RiskRoundedBudgetVolume(837,1,3,0,830,7,2,.01,500,.01),0));
   Check("new_838_boundary_passes",Equal(RiskRoundedBudgetVolume(838,1,3,0,830,7,2,.01,500,.01),.01));
   Check("below_new_boundary_rejected",Equal(RiskRoundedBudgetVolume(837.99,1,3,0,830,7,2,.01,500,.01),0));
   Check("500_no_forced_lot",Equal(RiskRoundedBudgetVolume(500,1,3,0,830,7,2,.01,500,.01),0));
   Check("aggregate_rounding_consumes_budget",Equal(RiskRoundedBudgetVolume(1000,1,3,21.63,830,7,2,.01,500,.01),0));
   Check("aggregate_exact_budget",Equal(RiskRoundedBudgetVolume(1000,1,3,21.62,830,7,2,.01,500,.01),.01));
   Check("be_retains_initial_price_and_fee",Equal(RiskRoundedReservation(800,0,.01,7,0,2),8.08));
   Check("partial_volume_rerounds_fee",Equal(RiskRoundedReservation(800,0,.03,7,0,2),24.22));
   Check("negative_swap_reserved",Equal(RiskRoundedReservation(800,0,.01,7,-1,2),9.08));
   Check("positive_swap_not_released",Equal(RiskRoundedReservation(800,0,.01,7,1,2),8.08));
   Check("nonzero_minimum_grid",Equal(RiskRoundedBudgetVolume(1257,1,3,0,830,7,2,.015,.105,.01),.015));
   int before=failures,cases=0;
   double fees[]={0.0,7.0,7.5,100.0};
   int precisions[]={0,2,3};
   double reservePercent[]={0.0,1.0,2.5,3.0};
   for(int equity=100;equity<=20000;equity+=37)
      for(int f=0;f<ArraySize(fees);f++)
         for(int d=0;d<ArraySize(precisions);d++)
            for(int r=0;r<ArraySize(reservePercent);r++)
            {
               double reserved=(double)equity*reservePercent[r]/100.0;
               double found=RiskRoundedBudgetVolume(equity,1,3,reserved,830,fees[f],precisions[d],.01,.10,.01);
               double expected=0.0;
               for(int index=1;index<=10;index++)
               {
                  double volume=(double)index*.01;
                  if(RiskBudgetFits(equity,1,3,reserved,RiskRoundedCost(830,volume,fees[f],precisions[d]))) expected=volume;
               }
               double linear=RiskBudgetVolume(equity,1,3,reserved,830+fees[f],.01,.10,.01);
               if(!Equal(found,expected) || found>linear+1e-8) failures++;
               cases++;
            }
   Check("grid_search_matches_exhaustive_no_upsize",failures==before);
   PrintFormat("FEE_RISK_TEST_SUMMARY|Tests=%d|Failures=%d|GridCases=%d",tests,failures,cases);
   return failures==0 ? INIT_SUCCEEDED : INIT_FAILED;
}
void OnTick() {}
double OnTester() { return failures==0 ? 1.0 : -1.0; }
