#ifndef GSM_RC01_FEE_RISK_MATH
#define GSM_RC01_FEE_RISK_MATH
#include "RiskMath.mqh"

double RiskRoundedFee(const double volume,const double roundTripPerLot,const int digits)
{
   if(!RiskNumber(volume) || !RiskNumber(roundTripPerLot) || digits<0 || digits>8) return -1.0;
   double scale=MathPow(10.0,digits);
   double raw=volume*roundTripPerLot*0.5*scale;
   if(!RiskNumber(raw)) return -1.0;
   // Remove floating-point noise at positive integer boundaries, not tiny fees.
   double nearest=MathRound(raw);
   if(nearest>0.0 && MathAbs(raw-nearest)<=8.0*DBL_EPSILON*MathMax(1.0,raw)) raw=nearest;
   double fee=2.0*(MathCeil(raw)/scale);
   return RiskNumber(fee) ? fee : -1.0;
}

double RiskRoundedCost(const double pricePerLot,const double volume,
                        const double feePerLot,const int digits)
{
   double fee=RiskRoundedFee(volume,feePerLot,digits);
   if(!RiskNumber(pricePerLot) || pricePerLot<=0.0 || fee<0.0) return -1.0;
   double money=pricePerLot*volume+fee;
   return RiskNumber(money) ? money : -1.0;
}

double RiskRoundedReservation(const double initialPerLot,const double currentPerLot,
                               const double volume,const double feePerLot,const double swap,const int digits)
{
   double price=RiskReservation(initialPerLot,currentPerLot,volume,0.0,swap);
   double fee=RiskRoundedFee(volume,feePerLot,digits);
   if(price<0.0 || fee<0.0) return -1.0;
   double money=price+fee;
   return RiskNumber(money) ? money : -1.0;
}

double RiskRoundedBudgetVolume(const double equity,const double singlePct,const double totalPct,
                               const double reserved,const double pricePerLot,const double feePerLot,
                               const int digits,const double minimum,const double maximum,const double step)
{
   if(!RiskNumber(pricePerLot) || pricePerLot<=0.0 || RiskRoundedFee(minimum,feePerLot,digits)<0.0) return 0.0;
   double upper=RiskBudgetVolume(equity,singlePct,totalPct,reserved,pricePerLot+feePerLot,minimum,maximum,step);
   if(upper<minimum || !RiskBudgetFits(equity,singlePct,totalPct,reserved,
                                     RiskRoundedCost(pricePerLot,minimum,feePerLot,digits))) return 0.0;
   double count=MathFloor((upper-minimum)/step+1e-10);
   if(!RiskNumber(count) || count>1.0e12) return 0.0;
   long low=0,high=(long)count;
   while(low<high)
   {
      long mid=low+(high-low+1)/2;
      double volume=NormalizeDouble(minimum+(double)mid*step,8);
      if(RiskBudgetFits(equity,singlePct,totalPct,reserved,RiskRoundedCost(pricePerLot,volume,feePerLot,digits)))
         low=mid;
      else high=mid-1;
   }
   double lots=NormalizeDouble(minimum+(double)low*step,8);
   if(lots>upper+1e-10 || !RiskBudgetFits(equity,singlePct,totalPct,reserved,
                                        RiskRoundedCost(pricePerLot,lots,feePerLot,digits))) return 0.0;
   return lots;
}

#endif
