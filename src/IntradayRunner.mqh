#ifndef GSM_INTRADAY_RUNNER
#define GSM_INTRADAY_RUNNER
#include "RunnerRules.mqh"

input group "I-C02 Intraday runner research (Scalping excluded)"
input bool InpIntradayRunner=false;
input double InpRunnerBreakEvenR=0.5;
input double InpRunnerTrailStartR=2.0;
input double InpRunnerATRMultiple=2.0;
input int InpRunnerATRPeriod=14;
input bool InpRunnerRestartProbe=false; // Tester-only recovery diagnostic.

struct RunnerState
{
   ulong id;
   int dir;
   double entry,risk,tp,volume,be;
   bool armed,partialAttempted,trail;
   datetime lastRequest;
};
RunnerState runnerStates[];

string RunnerKey(const ulong id,const string field)
{
   string context=AccountInfoString(ACCOUNT_SERVER)+g_symbol;
   if(MQLInfoInteger(MQL_TESTER)) context+=InpAuditRunLabel;
   return StringFormat("GSMI2_%I64d_%u_%I64u_%s",AccountInfoInteger(ACCOUNT_LOGIN),HashText(context),id,field);
}

bool RunnerStore(RunnerState &s)
{
   bool ok=(GlobalVariableSet(RunnerKey(s.id,"OK"),0)>0);
   GlobalVariablesFlush();
   ok=(GlobalVariableSet(RunnerKey(s.id,"R"),s.risk)>0)&&ok;
   ok=(GlobalVariableSet(RunnerKey(s.id,"E"),s.entry)>0)&&ok;
   ok=(GlobalVariableSet(RunnerKey(s.id,"T"),s.tp)>0)&&ok;
   ok=(GlobalVariableSet(RunnerKey(s.id,"V"),s.volume)>0)&&ok;
   ok=(GlobalVariableSet(RunnerKey(s.id,"B"),s.be)>0)&&ok;
   ok=(GlobalVariableSet(RunnerKey(s.id,"A"),s.armed?1:0)>0)&&ok;
   ok=(GlobalVariableSet(RunnerKey(s.id,"P"),s.partialAttempted?1:0)>0)&&ok;
   ok=(GlobalVariableSet(RunnerKey(s.id,"L"),s.trail?1:0)>0)&&ok;
   ok=(GlobalVariableSet(RunnerKey(s.id,"Q"),(double)s.lastRequest)>0)&&ok;
   if(ok) ok=(GlobalVariableSet(RunnerKey(s.id,"OK"),1)>0);
   GlobalVariablesFlush();
   if(!ok) { researchExecutionUnresolved=true; Print("RUNNER_PERSIST_FAILED_NO_NEW_ORDERS"); }
   return ok;
}

int RunnerRecover(const ulong id,const int dir)
{
   for(int i=0;i<ArraySize(runnerStates);i++) if(runnerStates[i].id==id) return i;
   RunnerState s; ZeroMemory(s); s.id=id; s.dir=dir;
   if(GlobalVariableCheck(RunnerKey(id,"OK")))
   {
      if(GlobalVariableGet(RunnerKey(id,"OK"))!=1) return -1;
      string required[]={"R","E","T","V","B","A","P","L","Q"};
      for(int i=0;i<ArraySize(required);i++) if(!GlobalVariableCheck(RunnerKey(id,required[i]))) return -1;
      s.risk=GlobalVariableGet(RunnerKey(id,"R")); s.entry=GlobalVariableGet(RunnerKey(id,"E"));
      s.tp=GlobalVariableGet(RunnerKey(id,"T")); s.volume=GlobalVariableGet(RunnerKey(id,"V"));
      s.be=GlobalVariableGet(RunnerKey(id,"B")); s.armed=(GlobalVariableGet(RunnerKey(id,"A"))==1);
      s.partialAttempted=(GlobalVariableGet(RunnerKey(id,"P"))==1);
      s.trail=(GlobalVariableGet(RunnerKey(id,"L"))==1);
      s.lastRequest=(datetime)GlobalVariableGet(RunnerKey(id,"Q"));
   }
   else
   {
      if(!HistorySelectByPosition(id)) return -1;
      double weighted=0,sl=0;
      bool priorExit=false;
      for(int i=0;i<HistoryDealsTotal();i++)
      {
         ulong deal=HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpIntradayMagic ||
            HistoryDealGetString(deal,DEAL_SYMBOL)!=g_symbol) return -1;
         if(HistoryDealGetInteger(deal,DEAL_ENTRY)!=DEAL_ENTRY_IN) { priorExit=true; continue; }
         ulong order=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
         if(!HistoryOrderSelect(order)) return -1;
         double initialSL=HistoryOrderGetDouble(order,ORDER_SL),initialTP=HistoryOrderGetDouble(order,ORDER_TP);
         if(initialSL<=0 || initialTP<=0) return -1;
         if(sl>0 && (MathAbs(sl-initialSL)>g_tickSize*0.1 || MathAbs(s.tp-initialTP)>g_tickSize*0.1)) return -1;
         double v=HistoryDealGetDouble(deal,DEAL_VOLUME);
         weighted+=v*HistoryDealGetDouble(deal,DEAL_PRICE); s.volume+=v; sl=initialSL; s.tp=initialTP;
      }
      // Without durable intent, an existing reduced/TP-less position is ambiguous.
      if(priorExit || s.volume<=0 || PositionGetDouble(POSITION_TP)<=0) return -1;
      s.entry=weighted/s.volume; s.risk=dir*(s.entry-sl);
      if(s.risk<=g_tickSize || dir*(s.tp-s.entry)<=0) return -1;
      if(!RunnerStore(s)) return -1;
   }
   if(!MathIsValidNumber(s.risk) || s.risk<=g_tickSize || s.entry<=0 || s.volume<=0 || s.tp<=0) return -1;
   int index=ArraySize(runnerStates); ArrayResize(runnerStates,index+1); runnerStates[index]=s;
   PrintFormat("RUNNER_RECOVER|PositionID=%I64u|InitialR=%.8f|OriginalTP=%.8f|Volume=%.8f|PartialIntent=%s",
               id,s.risk,s.tp,s.volume,s.partialAttempted?"YES":"NO");
   return index;
}

bool RunnerSelect(const ulong ticket,const ulong id)
{
   return PositionSelectByTicket(ticket) && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==id &&
          PositionGetString(POSITION_SYMBOL)==g_symbol &&
          RunnerOwner(PositionGetInteger(POSITION_MAGIC),InpIntradayMagic,InpScalpMagic,InpSwingMagic);
}

double RunnerCostBE(RunnerState &s,const double volume,const double swap)
{
   if(!HistorySelectByPosition(s.id)) return 0;
   double costs=MathMax(0,-swap);
   for(int i=0;i<HistoryDealsTotal();i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      costs+=MathMax(0,-HistoryDealGetDouble(deal,DEAL_COMMISSION))+
             MathMax(0,-HistoryDealGetDouble(deal,DEAL_FEE))+
             MathMax(0,-HistoryDealGetDouble(deal,DEAL_SWAP));
   }
   int digits=(int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS);
   double scale=MathPow(10.0,digits),rate=InpResearchRoundTripFeePerLotUSD;
   double exitFee=MathCeil(volume*rate*0.5*scale-1e-10)/scale;
   double half=RunnerHalfVolume(volume,g_volumeMin,g_volumeStep);
   if(!s.partialAttempted && half>0)
      exitFee=MathCeil(half*rate*0.5*scale-1e-10)/scale+
              MathCeil((volume-half)*rate*0.5*scale-1e-10)/scale;
   double pnl=0;
   if(!OrderCalcProfit(s.dir>0?ORDER_TYPE_BUY:ORDER_TYPE_SELL,g_symbol,volume,
                       s.entry,s.entry+s.dir*g_tickSize,pnl) || pnl<=0) return 0;
   return RunnerRoundedPrice(s.dir,s.entry+s.dir*((costs+exitFee)/pnl*g_tickSize+g_tickSize),g_tickSize);
}

bool RunnerModify(const ulong ticket,RunnerState &s,const double desiredSL,const double desiredTP)
{
   if(!RunnerSelect(ticket,s.id) || TimeCurrent()-s.lastRequest<1) return false;
   MqlTick quote; if(!SymbolInfoTick(g_symbol,quote)) return false;
   double oldSL=PositionGetDouble(POSITION_SL),oldTP=PositionGetDouble(POSITION_TP);
   double minimum=(MathMax(SymbolInfoInteger(g_symbol,SYMBOL_TRADE_STOPS_LEVEL),
                          SymbolInfoInteger(g_symbol,SYMBOL_TRADE_FREEZE_LEVEL))+2)*g_point;
   double market=(s.dir>0?quote.bid:quote.ask);
   bool sameSL=(MathAbs(desiredSL-oldSL)<g_tickSize*0.1);
   if(sameSL && MathAbs(desiredTP-oldTP)<g_tickSize*0.1) return true;
   if(sameSL) { if(s.dir*(market-desiredSL)<minimum) return false; }
   else if(!RunnerLegalStop(s.dir,desiredSL,oldSL,market,minimum,g_tickSize)) return false;
   if(desiredTP==0 && !RunnerProtected(s.dir,oldSL,s.be,g_tickSize)) return false;
   s.lastRequest=TimeCurrent(); if(!RunnerStore(s)) return false;
   trade.SetAsyncMode(false); trade.SetExpertMagicNumber(InpIntradayMagic);
   bool sent=trade.PositionModify(ticket,NormalizeDouble(desiredSL,g_digits),desiredTP);
   uint code=trade.ResultRetcode();
   PrintFormat("RUNNER_MODIFY|PositionID=%I64u|SL=%.8f|TP=%.8f|Retcode=%u",s.id,desiredSL,desiredTP,code);
   if(!sent || (code!=TRADE_RETCODE_DONE && code!=TRADE_RETCODE_NO_CHANGES)) return false;
   if(!RunnerSelect(ticket,s.id)) return false;
   return RunnerProtected(s.dir,PositionGetDouble(POSITION_SL),desiredSL,g_tickSize) &&
          MathAbs(PositionGetDouble(POSITION_TP)-desiredTP)<g_tickSize*0.1;
}

void ManageIntradayRunner()
{
   if(!InpIntradayRunner) return;
   static datetime trendBar=0;
   static int d1=0,h4=0;
   datetime bar=iTime(g_symbol,PERIOD_H4,0);
   if(bar!=trendBar && bar>0)
   {
      d1=DetectSwingTrend(PERIOD_D1,InpSwingLookbackBars,InpSwingDepth);
      h4=DetectSwingTrend(PERIOD_H4,InpSwingLookbackBars,InpSwingDepth); trendBar=bar;
   }
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i),id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(!RunnerSelect(ticket,id)) continue;
      int dir=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?1:-1);
      int index=RunnerRecover(id,dir);
      if(index<0)
      {
         // Position and opening-order history can arrive in different transactions.
         // No management or risk release while a NEW position waits for history.
         datetime created=(datetime)PositionGetInteger(POSITION_TIME);
         if(created>0 && TimeCurrent()>=created && TimeCurrent()-created<5 &&
            !GlobalVariableCheck(RunnerKey(id,"OK")))
         {
            static ulong lastDeferred=0;
            if(lastDeferred!=id) PrintFormat("RUNNER_RECOVERY_DEFERRED_HISTORY|PositionID=%I64u",id);
            lastDeferred=id;
            continue;
         }
         if(!researchExecutionUnresolved) PrintFormat("RUNNER_RECOVERY_FAILED_CLOSED|PositionID=%I64u",id);
         researchExecutionUnresolved=true; continue;
      }
      RunnerState s=runnerStates[index];
      if(!RunnerSelect(ticket,id)) continue;
      double volume=PositionGetDouble(POSITION_VOLUME),swap=PositionGetDouble(POSITION_SWAP);
      if(volume>s.volume+g_volumeStep*0.1) { researchExecutionUnresolved=true; continue; }
      MqlTick quote; if(!SymbolInfoTick(g_symbol,quote)) continue;
      double market=(dir>0?quote.bid:quote.ask),r=dir*(market-s.entry)/s.risk;
      if(!s.armed)
      {
         if(r<InpRunnerBreakEvenR || d1!=dir || h4!=dir) continue;
         s.armed=true;
         if(!RunnerStore(s)) continue;
      }
      double be=RunnerCostBE(s,volume,swap);
      if(be<=0 || !RunnerSelect(ticket,id)) continue;
      if(s.be<=0 || dir*(be-s.be)>0) s.be=be;
      double sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
      if(!RunnerProtected(dir,sl,s.be,g_tickSize))
         RunnerModify(ticket,s,s.be,tp);
      else if(tp>0)
         RunnerModify(ticket,s,sl,0);
      else
      {
         double half=RunnerHalfVolume(s.volume,g_volumeMin,g_volumeStep);
         if(!s.partialAttempted && dir*(market-s.tp)>=0)
         {
            // Write intent BEFORE sending; an unknown outcome is never blindly retried.
            s.partialAttempted=true;
            if(!RunnerStore(s)) continue;
            if(half>0 && volume-half>=g_volumeMin-1e-9 && RunnerSelect(ticket,id))
            {
               trade.SetAsyncMode(false); trade.SetExpertMagicNumber(InpIntradayMagic);
               bool sent=trade.PositionClosePartial(ticket,half,(ulong)InpDeviationPoints);
               PrintFormat("RUNNER_PARTIAL|PositionID=%I64u|Volume=%.8f|Sent=%s|Retcode=%u",id,half,sent?"YES":"NO",trade.ResultRetcode());
               if(!sent || (trade.ResultRetcode()!=TRADE_RETCODE_DONE && trade.ResultRetcode()!=TRADE_RETCODE_DONE_PARTIAL))
                  PrintFormat("RUNNER_PARTIAL_UNRESOLVED_NO_RETRY|PositionID=%I64u",id);
               if(trade.ResultRetcode()==TRADE_RETCODE_TIMEOUT || trade.ResultRetcode()==TRADE_RETCODE_CONNECTION ||
                  trade.ResultRetcode()==TRADE_RETCODE_PLACED) researchExecutionUnresolved=true;
            }
            else PrintFormat("RUNNER_PARTIAL_SKIPPED_MIN_LOT|PositionID=%I64u|Volume=%.8f",id,volume);
         }
         if(r>=InpRunnerTrailStartR) s.trail=true;
         if(s.trail && RunnerSelect(ticket,id))
         {
            MqlRates rates[];
            if(LoadRates(PERIOD_H4,InpRunnerATRPeriod+5,rates))
            {
               double atr=CalcATR(rates,1,InpRunnerATRPeriod);
               double target=rates[1].close-dir*atr*InpRunnerATRMultiple;
               target=(dir>0?MathMax(target,s.be):MathMin(target,s.be));
               if(atr>0) RunnerModify(ticket,s,RunnerRoundedPrice(dir,target,g_tickSize),0);
            }
         }
      }
      bool changed=(s.be!=runnerStates[index].be || s.armed!=runnerStates[index].armed ||
                    s.partialAttempted!=runnerStates[index].partialAttempted || s.trail!=runnerStates[index].trail ||
                    s.lastRequest!=runnerStates[index].lastRequest);
      runnerStates[index]=s;
      if(changed && !RunnerStore(s)) continue;
      if(InpRunnerRestartProbe && MQLInfoInteger(MQL_TESTER) && s.armed &&
         !GlobalVariableCheck(RunnerKey(id,"PROBE")))
      {
         GlobalVariableSet(RunnerKey(id,"PROBE"),1); GlobalVariablesFlush();
         ArrayResize(runnerStates,0);
         PrintFormat("RUNNER_RESTART_PROBE|PositionID=%I64u|MemoryCleared=YES",id);
         break;
      }
   }
}
#endif
