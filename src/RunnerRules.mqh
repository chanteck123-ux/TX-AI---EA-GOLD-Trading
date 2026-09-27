#ifndef GSM_RUNNER_RULES
#define GSM_RUNNER_RULES

double RunnerHalfVolume(const double volume,const double minimum,const double step)
{
   if(!MathIsValidNumber(volume) || minimum<=0 || step<=0 || volume<2*minimum-1e-9) return 0;
   double half=NormalizeDouble(MathFloor((volume*0.5+step*1e-9)/step)*step,8);
   if(half<minimum-1e-9 || volume-half<minimum-1e-9) return 0;
   return half;
}

double RunnerRoundedPrice(const int dir,const double price,const double tick)
{
   if(tick<=0 || price<=0 || !MathIsValidNumber(price) || (dir!=1 && dir!=-1)) return 0;
   return (dir>0 ? MathCeil(price/tick-1e-9) : MathFloor(price/tick+1e-9))*tick;
}

bool RunnerProtected(const int dir,const double sl,const double floor,const double tick)
{
   return sl>0 && floor>0 && (dir==1 || dir==-1) && dir*(sl-floor)>=-tick*0.1;
}

bool RunnerLegalStop(const int dir,const double wanted,const double oldSL,const double market,
                     const double minimumDistance,const double tick)
{
   if(wanted<=0 || market<=0 || tick<=0 || !MathIsValidNumber(wanted)) return false;
   if(dir!=1 && dir!=-1) return false;
   if(dir*(market-wanted)<minimumDistance-1e-9) return false;
   return oldSL<=0 || dir*(wanted-oldSL)>=tick*0.9;
}

bool RunnerOwner(const long actual,const long intra,const long scalp,const long swing)
{
   return actual==intra && actual!=scalp && actual!=swing;
}

double RunnerFee(const double volume,const double rate,const int digits,
                 const double minimum,const double step)
{
   if(volume<=0 || rate<0 || digits<0 || digits>8) return -1;
   double scale=MathPow(10.0,digits);
   double entry=MathCeil(volume*rate*0.5*scale-1e-10)/scale;
   double half=RunnerHalfVolume(volume,minimum,step);
   if(half<=0) return entry*2;
   return entry+MathCeil(half*rate*0.5*scale-1e-10)/scale+
          MathCeil((volume-half)*rate*0.5*scale-1e-10)/scale;
}
#endif
