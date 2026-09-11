#property strict
#property version "1.00"
#include "../src/RiskMath.mqh"

int tests=0,failures=0;
void Check(const string name,const bool passed)
{
   tests++;
   if(!passed) failures++;
   PrintFormat("RISK_TEST|%s|%s",name,passed ? "PASS" : "FAIL");
}
bool Equal(const double a,const double b) { return MathAbs(a-b)<1e-8; }

int OnInit()
{
   Check("minimum_lot_not_forced",Equal(RiskBudgetVolume(500,1,3,0,837,.01,500,.01),0));
   Check("technical_minimum_boundary",Equal(RiskBudgetVolume(837,1,3,0,837,.01,500,.01),.01));
   Check("below_boundary_rejected",Equal(RiskBudgetVolume(836.99,1,3,0,837,.01,500,.01),0));
   Check("floor_not_round_up",Equal(RiskFloorVolume(.019,.01,500,.01),.01));
   Check("three_decimal_step",Equal(RiskFloorVolume(.0179,.001,1,.001),.017));
   Check("broker_max_floor",Equal(RiskFloorVolume(10,.01,.125,.01),.12));
   Check("invalid_step",Equal(RiskFloorVolume(.01,.01,500,0),0));
   Check("invalid_range",Equal(RiskFloorVolume(.01,.1,.01,.01),0));
   Check("aggregate_downsizes",Equal(RiskBudgetVolume(1000,1,3,25,100,.01,500,.01),.05));
   Check("aggregate_exhausted",Equal(RiskBudgetVolume(1000,1,3,30,100,.01,500,.01),0));
   Check("zero_unit_loss_rejected",Equal(RiskBudgetVolume(1000,1,3,0,0,.01,500,.01),0));
   Check("over_one_percent_rejected",!RiskBudgetFits(500,2,3,0,5));
   Check("over_three_percent_rejected",!RiskBudgetFits(500,1,4,0,5));
   Check("zero_equity_rejected",!RiskBudgetFits(0,1,3,0,5));
   Check("negative_reservation_rejected",!RiskBudgetFits(500,1,3,-1,5));
   Check("negative_loss_rejected",!RiskBudgetFits(500,1,3,0,-1));
   Check("fee_breaks_budget",!RiskBudgetFits(500,1,3,0,5.07));
   Check("equity_drop_rechecked",!RiskBudgetFits(499,1,3,0,5));
   Check("be_retains_initial_risk",Equal(RiskReservation(800,0,.01,7,0),8.07));
   Check("partial_releases_proportionally",Equal(RiskReservation(800,0,.02,7,0)/2,RiskReservation(800,0,.01,7,0)));
   Check("wider_stop_increases_reserve",Equal(RiskReservation(800,1000,.01,7,0),10.07));
   Check("swap_debit_added",Equal(RiskReservation(800,0,.01,7,-.5),8.57));
   Check("swap_credit_not_released",Equal(RiskReservation(800,0,.01,7,.5),8.07));
   Check("unknown_initial_fails_closed",RiskReservation(0,0,.01,7,0)<0);
   Check("opposite_positions_not_netted",!RiskBudgetFits(1000,1,3,RiskReservation(1000,0,.02,7,0),10));
   for(int dollars=1;dollars<=10000;dollars+=13)
   {
      double lot=RiskBudgetVolume(dollars,1,3,0,837,.01,500,.01);
      if(lot>0.0 && !RiskBudgetFits(dollars,1,3,0,lot*837)) failures++;
   }
   PrintFormat("RISK_TEST_SUMMARY|Tests=%d|Failures=%d|SweepCases=770",tests,failures);
   return INIT_SUCCEEDED;
}
void OnTick() {}
double OnTester() { return failures==0 ? tests : -failures; }
