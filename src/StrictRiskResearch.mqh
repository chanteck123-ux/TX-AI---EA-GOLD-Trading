#ifndef GSM_RESEARCH_STRICT_RISK_RUNNER
#define GSM_RESEARCH_STRICT_RISK_RUNNER
#include "FeeRiskMath.mqh"
#include "RunnerRules.mqh"

bool studyRunnerMode=false,studyRunnerSizing=false;

double StudyFee(const bool runner,const double volume,const double rate,const int digits)
{
   return runner?RunnerFee(volume,rate,digits,g_volumeMin,g_volumeStep):RiskRoundedFee(volume,rate,digits);
}

double StudyCost(const double unit,const double volume,const double rate,const int digits)
{
   if(!studyRunnerSizing) return RiskRoundedCost(unit,volume,rate,digits);
   return unit*volume+StudyFee(true,volume,rate,digits);
}

input group "R-C00 mandatory research risk policy"
input double InpResearchSingleRiskPct=1.0;
input double InpResearchTotalRiskPct=3.0;
input double InpResearchRoundTripFeePerLotUSD=7.0; // Estimate, not a broker fee override.

struct ResearchRiskState
{
   ulong identifier;
   long magic;
   double initialPerLot;
};
ResearchRiskState researchRiskStates[];
bool researchExecutionUnresolved=false;

string ResearchRiskKey(const ulong id,const long magic)
{
   return StringFormat("GSM_R0_%I64d_%u_%I64d_%I64u",
                       AccountInfoInteger(ACCOUNT_LOGIN),HashText(g_symbol),magic,id);
}

bool ResearchKnownMagic(const long magic)
{
   return magic==InpScalpMagic || magic==InpIntradayMagic || magic==InpSwingMagic;
}

bool ResearchInitialRisk(const ulong id,const long magic,const ENUM_ORDER_TYPE type,
                         double &perLot,string &reason)
{
   for(int i=0;i<ArraySize(researchRiskStates);i++)
      if(researchRiskStates[i].identifier==id && researchRiskStates[i].magic==magic)
      {
         perLot=researchRiskStates[i].initialPerLot;
         return perLot>0.0;
      }
   perLot=0.0;
   string key=ResearchRiskKey(id,magic);
   if(!MQLInfoInteger(MQL_TESTER) && GlobalVariableCheck(key))
      perLot=GlobalVariableGet(key);
   if(!RiskNumber(perLot) || perLot<=0.0)
   {
      if(!HistorySelectByPosition(id))
      {
         reason="INITIAL_RISK_HISTORY_UNAVAILABLE";
         return false;
      }
      // Recover from opening orders, never infer initial risk from a moved SL.
      for(int i=0;i<HistoryDealsTotal();i++)
      {
         ulong deal=HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(deal,DEAL_ENTRY)!=DEAL_ENTRY_IN) continue;
         if(HistoryDealGetInteger(deal,DEAL_MAGIC)!=magic ||
            HistoryDealGetString(deal,DEAL_SYMBOL)!=g_symbol) continue;
         ulong order=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
         if(!HistoryOrderSelect(order))
         {
            reason="INITIAL_ORDER_HISTORY_NOT_SELECTED";
            return false;
         }
         double sl=HistoryOrderGetDouble(order,ORDER_SL);
         double price=HistoryDealGetDouble(deal,DEAL_PRICE);
         double pnl=0.0;
         if(sl<=0.0 || price<=0.0 ||
            !OrderCalcProfit(type,g_symbol,g_volumeMin,price,sl,pnl) || pnl>=0.0)
         {
            reason="INITIAL_SL_MISSING_OR_INVALID";
            return false;
         }
         perLot=MathMax(perLot,-pnl/g_volumeMin);
      }
   }
   if(!RiskNumber(perLot) || perLot<=0.0)
   {
      reason="INITIAL_RISK_UNRECOVERABLE";
      return false;
   }
   if(!MQLInfoInteger(MQL_TESTER))
   {
      if(GlobalVariableSet(key,perLot)==0)
      {
         reason="INITIAL_RISK_PERSIST_FAILED";
         return false;
      }
      GlobalVariablesFlush();
   }
   int index=ArraySize(researchRiskStates);
   ArrayResize(researchRiskStates,index+1);
   researchRiskStates[index].identifier=id;
   researchRiskStates[index].magic=magic;
   researchRiskStates[index].initialPerLot=perLot;
   return true;
}

bool ResearchReservedRisk(double &money,string &reason)
{
   money=0.0;
   if(researchExecutionUnresolved)
   {
      reason="EXECUTION_UNRESOLVED_RECONCILIATION_REQUIRED";
      return false;
   }
   if(OrdersTotal()>0)
   {
      reason="PENDING_ORDER_RISK_UNSUPPORTED_FAIL_CLOSED";
      return false;
   }
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
      {
         reason="POSITION_SNAPSHOT_FAILED";
         return false;
      }
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol || !ResearchKnownMagic(magic))
      {
         reason="UNMANAGED_ACCOUNT_EXPOSURE_FAIL_CLOSED";
         return false;
      }
      ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      double volume=PositionGetDouble(POSITION_VOLUME);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double swap=PositionGetDouble(POSITION_SWAP);
      ENUM_ORDER_TYPE type=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      double current=0.0,initial=0.0;
      if(sl<=0.0 || volume<=0.0 || !OrderCalcProfit(type,g_symbol,g_volumeMin,entry,sl,current))
      {
         reason="LIVE_SL_RISK_UNKNOWN_FAIL_CLOSED";
         return false;
      }
      if(!ResearchInitialRisk(id,magic,type,initial,reason)) return false;
      double reserved=RiskRoundedReservation(initial,MathMax(0.0,-current/g_volumeMin),
                                             volume,InpResearchRoundTripFeePerLotUSD,swap,
                                             (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS));
      if(reserved<0.0) { reason="INVALID_RISK_RESERVATION"; return false; }
      if(studyRunnerMode && magic==InpIntradayMagic)
         reserved+=MathMax(0,StudyFee(true,volume,InpResearchRoundTripFeePerLotUSD,
                                    (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS))-
                              RiskRoundedFee(volume,InpResearchRoundTripFeePerLotUSD,
                                             (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS)));
      money+=reserved;
   }
   return true;
}

bool ResearchUnitRisk(const int dir,const double entry,const double sl,double &unit,string &reason)
{
   long digits=AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS);
   if(digits<0 || digits>8)
   {
      reason="INVALID_ACCOUNT_CURRENCY_PRECISION";
      return false;
   }
   if((dir!=1 && dir!=-1) || !RiskNumber(entry) || !RiskNumber(sl) || entry<=0.0 || sl<=0.0 ||
      (dir>0 ? sl>=entry : sl<=entry))
   {
      reason="INVALID_DIRECTION_OR_INITIAL_SL";
      return false;
   }
   ENUM_ORDER_TYPE type=(dir>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   double adverse=entry+dir*InpDeviationPoints*g_point;
   double pnl=0.0;
   if(!OrderCalcProfit(type,g_symbol,g_volumeMin,adverse,sl,pnl) || pnl>=0.0)
   {
      reason="ORDER_CALC_PROFIT_FAILED_CLOSED";
      return false;
   }
   unit=-pnl/g_volumeMin;
   return RiskNumber(unit) && unit>0.0;
}

bool ResearchSize(const int dir,const double entry,const double sl,const double requestedRisk,
                   double &lots,double &raw,string &reason)
{
   lots=0.0;
   raw=0.0;
   double unit=0.0,reserved=0.0;
   if(!ResearchUnitRisk(dir,entry,sl,unit,reason) || !ResearchReservedRisk(reserved,reason)) return false;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double single=MathMin(InpResearchSingleRiskPct,requestedRisk);
   if(!RiskNumber(single) || single<=0.0 || !RiskNumber(equity) || equity<=0.0)
   {
      reason="INVALID_REQUESTED_RISK_OR_EQUITY";
      return false;
   }
   double budget=MathMin(equity*single/100.0,equity*InpResearchTotalRiskPct/100.0-reserved);
   int digits=(int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS);
   raw=MathMax(0.0,budget/(unit+InpResearchRoundTripFeePerLotUSD));
   lots=RiskRoundedBudgetVolume(equity,single,InpResearchTotalRiskPct,reserved,unit,
                               InpResearchRoundTripFeePerLotUSD,digits,g_volumeMin,g_volumeMax,g_volumeStep);
   while(studyRunnerSizing && lots>=g_volumeMin &&
         StudyCost(unit,lots,InpResearchRoundTripFeePerLotUSD,digits)>budget+1e-9)
      lots=NormalizeDouble(MathFloor((lots-g_volumeStep+g_volumeStep*1e-9)/g_volumeStep)*g_volumeStep,8);
   if(lots<g_volumeMin)
   {
      double minimumRisk=StudyCost(unit,g_volumeMin,InpResearchRoundTripFeePerLotUSD,digits);
      reason=StringFormat("MINIMUM_LOT_EXCEEDS_RISK_OR_NO_BUDGET Equity=%.2f Budget=%.4f MinRisk=%.4f TechnicalMinEquity=%.2f Reserved=%.4f",
                          equity,budget,minimumRisk,minimumRisk/(single/100.0),reserved);
      return false;
   }
   return true;
}

bool ResearchValidateOrder(const int dir,const double entry,const double sl,const double volume,
                           const double requestedRisk,string &reason)
{
   double reserved=0.0,unit=0.0;
   if(!ResearchUnitRisk(dir,entry,sl,unit,reason) || !ResearchReservedRisk(reserved,reason)) return false;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double single=MathMin(InpResearchSingleRiskPct,requestedRisk);
   int digits=(int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS);
   double fee=StudyFee(studyRunnerSizing,volume,InpResearchRoundTripFeePerLotUSD,digits);
   double proposed=StudyCost(unit,volume,InpResearchRoundTripFeePerLotUSD,digits);
   if(!RiskBudgetFits(equity,single,InpResearchTotalRiskPct,reserved,proposed))
   {
      reason="FRESH_QUOTE_OR_EQUITY_EXCEEDS_RISK_BUDGET";
      return false;
   }
   PrintFormat("STRICT_RISK_PLAN|Equity=%.2f|SingleCapPct=%.4f|Volume=%.8f|PlannedUSD=%.4f|PlannedPct=%.4f|ReservedUSD=%.4f|TotalPct=%.4f|FeeEstimateUSDPerLot=%.4f|AdverseBufferPoints=%d|InitialMarginUsed=%.4f|FeeModel=%s|CurrencyDigits=%d|FeeBudgetUSD=%.8f|LinearFeeUSD=%.8f",
               equity,single,volume,proposed,proposed/equity*100.0,reserved,
               (reserved+proposed)/equity*100.0,InpResearchRoundTripFeePerLotUSD,
               InpDeviationPoints,AccountInfoDouble(ACCOUNT_MARGIN),
               studyRunnerSizing?"ENTRY_TWO_EXITS_CEILING":"PER_SIDE_CEILING",digits,fee,volume*InpResearchRoundTripFeePerLotUSD);
   return true;
}

#endif
