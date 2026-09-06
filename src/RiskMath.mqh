#ifndef GSM_RESEARCH_RISK_MATH
#define GSM_RESEARCH_RISK_MATH

bool RiskNumber(const double value)
{
   return MathIsValidNumber(value) && value>=0.0;
}

double RiskFloorVolume(const double requested,const double minimum,
                       const double maximum,const double step)
{
   if(!RiskNumber(requested) || !RiskNumber(minimum) || !RiskNumber(maximum) ||
      !RiskNumber(step) || minimum<=0.0 || step<=0.0 || maximum<minimum ||
      requested+1e-12<minimum)
      return 0.0;
   double capped=MathMin(requested,maximum);
   double lots=NormalizeDouble(minimum+MathFloor((capped-minimum)/step+1e-10)*step,8);
   if(lots>capped+1e-10 || lots<minimum-1e-10 || lots>maximum+1e-10)
      return 0.0;
   return lots;
}

bool RiskBudgetFits(const double equity,const double singlePct,const double totalPct,
                    const double reserved,const double proposed)
{
   return RiskNumber(equity) && RiskNumber(singlePct) && RiskNumber(totalPct) &&
          RiskNumber(reserved) && RiskNumber(proposed) && equity>0.0 && proposed>0.0 &&
          singlePct>0.0 && singlePct<=1.0 && totalPct>0.0 && totalPct<=3.0 &&
          proposed<=equity*singlePct/100.0+1e-8 &&
          reserved+proposed<=equity*totalPct/100.0+1e-8;
}

double RiskBudgetVolume(const double equity,const double singlePct,const double totalPct,
                        const double reserved,const double unitLoss,const double minimum,
                        const double maximum,const double step)
{
   if(!RiskNumber(unitLoss) || unitLoss<=0.0 || !RiskNumber(reserved) ||
      !RiskNumber(equity) || !RiskNumber(singlePct) || !RiskNumber(totalPct) ||
      singlePct<=0.0 || singlePct>1.0 || totalPct<=0.0 || totalPct>3.0)
      return 0.0;
   double money=MathMin(equity*singlePct/100.0,equity*totalPct/100.0-reserved);
   if(money<=0.0) return 0.0;
   double lots=RiskFloorVolume(money/unitLoss,minimum,maximum,step);
   if(!RiskBudgetFits(equity,singlePct,totalPct,reserved,lots*unitLoss)) return 0.0;
   return lots;
}

double RiskReservation(const double initialPerLot,const double currentPerLot,
                       const double remainingVolume,const double feePerLot,const double swap)
{
   if(!RiskNumber(initialPerLot) || initialPerLot<=0.0 || !RiskNumber(currentPerLot) ||
      !RiskNumber(remainingVolume) || !RiskNumber(feePerLot) || !MathIsValidNumber(swap))
      return -1.0;
   return (MathMax(initialPerLot,currentPerLot)+feePerLot)*remainingVolume+MathMax(0.0,-swap);
}

#endif
