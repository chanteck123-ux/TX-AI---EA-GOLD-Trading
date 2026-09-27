#property strict
#include <Trade/Trade.mqh>
CTrade probe;
bool sent=false;
ulong identifier=0,openingOrder=0;
datetime last=0,opened=0;
void Dump(string stage)
{
   if(identifier==0) return;
   ResetLastError();bool selected=HistorySelectByPosition(identifier);int selectError=GetLastError();
   double sl=0,tp=0;ResetLastError();bool slOK=HistoryOrderGetDouble(openingOrder,ORDER_SL,sl);int slError=GetLastError();
   bool tpOK=HistoryOrderGetDouble(openingOrder,ORDER_TP,tp);
   PrintFormat("HISTORY_PROBE|Stage=%s|Position=%I64u|Order=%I64u|Select=%s|Error=%d|Deals=%d|Orders=%d|SLOK=%s|SL=%g|TP=%g|SLError=%d|TPOK=%s",
               stage,identifier,openingOrder,selected?"YES":"NO",selectError,HistoryDealsTotal(),HistoryOrdersTotal(),slOK?"YES":"NO",sl,tp,slError,tpOK?"YES":"NO");
   ResetLastError();bool orderOK=HistoryOrderSelect(openingOrder);int orderError=GetLastError();
   PrintFormat("HISTORY_PROBE_SELECT_ORDER|OK=%s|Error=%d|SL=%g|TP=%g",orderOK?"YES":"NO",orderError,
               HistoryOrderGetDouble(openingOrder,ORDER_SL),HistoryOrderGetDouble(openingOrder,ORDER_TP));
}
int OnInit() {return MQLInfoInteger(MQL_TESTER)?INIT_SUCCEEDED:INIT_FAILED;}
void OnTick()
{
   MqlDateTime d;TimeToStruct(TimeCurrent(),d);
   if(!sent && d.hour>=2)
   {
      MqlTick q;if(!SymbolInfoTick(_Symbol,q))return;
      probe.SetExpertMagicNumber(998812);probe.SetTypeFillingBySymbol(_Symbol);
      sent=true;opened=TimeCurrent();
      bool ok=probe.Buy(.01,_Symbol,q.ask,NormalizeDouble(q.ask-12,_Digits),NormalizeDouble(q.ask+7,_Digits),"HISTORY_PROBE");
      openingOrder=probe.ResultOrder();
      PrintFormat("HISTORY_PROBE_SEND|OK=%s|Retcode=%u|Order=%I64u",ok?"YES":"NO",probe.ResultRetcode(),openingOrder);
      if(PositionSelect(_Symbol))identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      Dump("IMMEDIATE");
   }
   if(identifier>0 && TimeCurrent()-last>=2 && TimeCurrent()-opened<16){last=TimeCurrent();Dump("TICK");}
}
double OnTester(){Dump("END");return 0;}
