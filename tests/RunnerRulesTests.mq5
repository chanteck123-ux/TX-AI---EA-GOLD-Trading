#property strict
#include "../src/RunnerRules.mqh"
int failures=0,checks=0;
void Check(const bool ok,const string name)
{
   checks++; if(!ok) { failures++; Print("RUNNER_RULE_FAIL|",name); }
}
int OnInit()
{
   Check(RunnerHalfVolume(.01,.01,.01)==0,"minimum cannot split");
   Check(MathAbs(RunnerHalfVolume(.02,.01,.01)-.01)<1e-9,"two minimum lots split");
   Check(MathAbs(RunnerHalfVolume(.03,.01,.01)-.01)<1e-9,"floor not round up");
   Check(RunnerHalfVolume(-1,.01,.01)==0,"negative volume");
   Check(!RunnerOwner(101,102,101,103),"scalping excluded");
   Check(!RunnerOwner(103,102,101,103),"swing excluded");
   Check(RunnerOwner(102,102,101,103),"intraday allowed");
   Check(!RunnerOwner(102,102,102,103),"magic collision excluded");
   Check(!RunnerProtected(1,99,100,.01),"buy BE unconfirmed");
   Check(!RunnerProtected(-1,101,100,.01),"sell BE unconfirmed");
   Check(RunnerProtected(1,100.1,100,.01),"buy server BE confirmed");
   Check(RunnerProtected(-1,99.9,100,.01),"sell server BE confirmed");
   Check(!RunnerLegalStop(1,98,99,105,.02,.01),"buy cannot loosen");
   Check(!RunnerLegalStop(-1,102,101,95,.02,.01),"sell cannot loosen");
   Check(!RunnerLegalStop(1,105,99,105,.02,.01),"invalid buy stops");
   Check(!RunnerLegalStop(-1,95,101,95,.02,.01),"invalid sell stops");
   Check(RunnerLegalStop(1,100,99,105,.02,.01),"valid buy stop");
   Check(RunnerLegalStop(-1,100,101,95,.02,.01),"valid sell stop");
   Check(MathAbs(RunnerFee(.02,7,2,.01,.01)-.15)<1e-9,"entry and split exit rounded fees");
   Check(MathAbs(RunnerFee(.01,7,2,.01,.01)-.08)<1e-9,"unsplit fees");
   for(int i=1;i<=10000;i++)
   {
      double volume=i*.01,half=RunnerHalfVolume(volume,.01,.01);
      Check(half==0 || (half>=.01-1e-9 && volume-half>=.01-1e-9 && half<=volume/2+1e-9),"volume grid");
      double p=100+i*.001;
      Check(RunnerRoundedPrice(1,p,.01)>=p-1e-9 && RunnerRoundedPrice(-1,p,.01)<=p+1e-9,"price rounding grid");
   }
   PrintFormat("RUNNER_RULES_SUMMARY|Checks=%d|Failures=%d",checks,failures);
   return failures?INIT_FAILED:INIT_SUCCEEDED;
}
void OnTick() {}
