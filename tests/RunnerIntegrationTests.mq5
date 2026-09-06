#property strict
// Native MQL5 fixture: the REAL runner header, mocked broker responses; no orders.
string g_symbol="GOLD",InpAuditRunLabel="";
long InpIntradayMagic=102,InpScalpMagic=101,InpSwingMagic=103;
int InpDeviationPoints=30,InpSwingLookbackBars=260,InpSwingDepth=3,g_digits=2;
double g_tickSize=.01,g_point=.01,g_volumeMin=.01,g_volumeStep=.01,InpResearchRoundTripFeePerLotUSD=7;
bool researchExecutionUnresolved=false;
datetime clockNow=D'2026.01.05 10:00:00';
datetime createdAt=D'2026.01.05 09:00:00';
bool historyReady=true;
bool openingOrderSelected=false;
double posEntry=100,posSL=90,posTP=110,posVolume=.01,originalVolume=.01,mockMarket=106,h4Close=120;
long posMagic=102; int direction=1,trend=1,modifyCalls=0,partialCalls=0,failures=0,checks=0;
ulong positionId=1;
uint modifyCode=TRADE_RETCODE_DONE,partialCode=TRADE_RETCODE_DONE;
bool phantomModify=false,timeoutFilled=false,hasExit=false;
double partialFill=0;

uint HashText(const string value)
{
   uint h=2166136261; for(int i=0;i<StringLen(value);i++) {h^=(uint)StringGetCharacter(value,i);h*=16777619;} return h;
}
bool MockSelect(ulong ticket) {return ticket==positionId;}
long MockPositionInteger(ENUM_POSITION_PROPERTY_INTEGER p)
{
   if(p==POSITION_IDENTIFIER) return (long)positionId;
   if(p==POSITION_MAGIC) return posMagic;
   if(p==POSITION_TIME) return (long)createdAt;
   if(p==POSITION_TYPE) return direction>0?POSITION_TYPE_BUY:POSITION_TYPE_SELL;
   return 0;
}
double MockPositionDouble(ENUM_POSITION_PROPERTY_DOUBLE p)
{
   if(p==POSITION_SL) return posSL; if(p==POSITION_TP) return posTP;
   if(p==POSITION_VOLUME) return posVolume; if(p==POSITION_PRICE_OPEN) return posEntry; return 0;
}
string MockPositionString(ENUM_POSITION_PROPERTY_STRING p) {return g_symbol;}
bool MockTick(string symbol,MqlTick &q) {ZeroMemory(q);q.bid=mockMarket;q.ask=mockMarket;return true;}
long MockSymbolInteger(string symbol,ENUM_SYMBOL_INFO_INTEGER p) {return 0;}
int MockPositionsTotal() {return 1;}
ulong MockPositionTicket(int index) {return positionId;}
datetime MockTime() {return clockNow;}
datetime MockBar(string symbol,ENUM_TIMEFRAMES tf,int shift) {return clockNow;}
bool MockHistorySelect(ulong id) {openingOrderSelected=false;return historyReady && id==positionId;}
bool MockOrderSelect(ulong order) {openingOrderSelected=historyReady && order==positionId;return openingOrderSelected;}
int MockDealsTotal() {return 1;}
ulong MockDealTicket(int i) {return positionId;}
long MockDealInteger(ulong deal,ENUM_DEAL_PROPERTY_INTEGER p)
{
   if(p==DEAL_MAGIC) return posMagic; if(p==DEAL_ENTRY) return DEAL_ENTRY_IN;
   if(p==DEAL_ORDER) return (long)positionId; return 0;
}
string MockDealString(ulong deal,ENUM_DEAL_PROPERTY_STRING p) {return g_symbol;}
double MockDealDouble(ulong deal,ENUM_DEAL_PROPERTY_DOUBLE p)
{
   if(p==DEAL_VOLUME) return originalVolume;
   if(p==DEAL_PRICE) return posEntry;
   if(p==DEAL_COMMISSION) return -.04; return 0;
}
double MockOrderDouble(ulong order,ENUM_ORDER_PROPERTY_DOUBLE p)
{
   if(!openingOrderSelected) return 0;
   if(p==ORDER_SL) return direction>0?90:110;
   if(p==ORDER_TP) return direction>0?110:90; return 0;
}
bool MockProfit(ENUM_ORDER_TYPE type,string symbol,double volume,double a,double b,double &p)
{p=(type==ORDER_TYPE_BUY?1:-1)*(b-a)*volume*100;return true;}
int DetectSwingTrend(ENUM_TIMEFRAMES tf,int lookback,int depth) {return trend;}
bool LoadRates(ENUM_TIMEFRAMES tf,int count,MqlRates &rates[])
{ArrayResize(rates,count);ZeroMemory(rates);rates[0].close=9999;rates[1].close=h4Close;return true;}
double CalcATR(MqlRates &rates[],int shift,int period) {return shift==1?2:9999;}

class MockTrade
{
private: uint last;
public:
   void SetAsyncMode(bool value) {}
   void SetExpertMagicNumber(long value) {}
   uint ResultRetcode() {return last;}
   bool PositionModify(ulong ticket,double sl,double tp)
   {
      modifyCalls++;last=modifyCode;
      if(last==TRADE_RETCODE_DONE && !phantomModify) {posSL=sl;posTP=tp;}
      return true; // Deliberately true even when the server rejects.
   }
   bool PositionClosePartial(ulong ticket,double volume,ulong deviation)
   {
      partialCalls++;last=partialCode;
      if(last==TRADE_RETCODE_DONE || last==TRADE_RETCODE_DONE_PARTIAL || timeoutFilled)
      {posVolume-=partialFill>0?partialFill:volume;hasExit=true;}
      return last!=TRADE_RETCODE_TIMEOUT;
   }
};
MockTrade trade;

#define PositionSelectByTicket MockSelect
#define PositionGetInteger MockPositionInteger
#define PositionGetDouble MockPositionDouble
#define PositionGetString MockPositionString
#define SymbolInfoTick MockTick
#define SymbolInfoInteger MockSymbolInteger
#define PositionsTotal MockPositionsTotal
#define PositionGetTicket MockPositionTicket
#define TimeCurrent MockTime
#define iTime MockBar
#define HistorySelectByPosition MockHistorySelect
#define HistoryDealsTotal MockDealsTotal
#define HistoryDealGetTicket MockDealTicket
#define HistoryDealGetInteger MockDealInteger
#define HistoryDealGetDouble MockDealDouble
#define HistoryDealGetString MockDealString
#define HistoryOrderGetDouble MockOrderDouble
#define HistoryOrderSelect MockOrderSelect
#define OrderCalcProfit MockProfit
#include "../src/IntradayRunner.mqh"

void Check(bool ok,string name)
{checks++;if(!ok){failures++;Print("RUNNER_INTEGRATION_FAIL|",name);}}
void Reset(double volume=.02,int dir=1)
{
   positionId++;direction=dir;trend=dir;posMagic=102;originalVolume=volume;posVolume=volume;
   posEntry=100;posSL=dir>0?90:110;posTP=dir>0?110:90;mockMarket=100+dir*6;
   h4Close=dir>0?120:80;modifyCalls=0;partialCalls=0;phantomModify=false;
   modifyCode=TRADE_RETCODE_DONE;partialCode=TRADE_RETCODE_DONE;timeoutFilled=false;
   hasExit=false;partialFill=0;researchExecutionUnresolved=false;clockNow+=10;
   createdAt=clockNow-100;historyReady=true;
   ArrayResize(runnerStates,0);
}
void Tick() {clockNow+=2;ManageIntradayRunner();}
int OnInit()
{
   InpAuditRunLabel="FIXTURE_"+IntegerToString((long)GetMicrosecondCount());
   if(!InpIntradayRunner) {Print("FIXTURE_REQUIRES_RUNNER_INPUT");return INIT_PARAMETERS_INCORRECT;}
   Reset();createdAt=clockNow;historyReady=false;Tick();
   Check(!researchExecutionUnresolved && modifyCalls==0,"new position history lag defers without releasing protection");
   historyReady=true;Tick();Check(ArraySize(runnerStates)==1 && !researchExecutionUnresolved,"history catches up recovery succeeds");
   Reset();historyReady=false;Tick();Check(researchExecutionUnresolved,"old position absent history fails closed");
   Reset();createdAt=clockNow;historyReady=false;Tick();Tick();Tick();Check(researchExecutionUnresolved,"new position history wait is bounded");
   Reset();posMagic=101;Tick();Check(modifyCalls==0 && partialCalls==0,"scalping ownership hard isolation");
   Reset();posMagic=103;Tick();Check(modifyCalls==0,"swing ownership isolation");
   Reset();trend=0;Tick();Check(modifyCalls==0,"no closed trend alignment");
   Reset();modifyCode=TRADE_RETCODE_INVALID_STOPS;Tick();Tick();Check(posTP==110 && partialCalls==0,"true bool rejected server never releases TP");
   Reset();phantomModify=true;Tick();Tick();Check(posTP==110,"DONE without server SL is not confirmation");
   Reset();Tick();Check(posSL>100 && posTP==110,"BE first retaining TP");Tick();Check(posTP==0,"release TP after server BE");
   mockMarket=111;Tick();Check(partialCalls==1 && MathAbs(posVolume-.01)<1e-8,"legal half close");
   Tick();Tick();Check(partialCalls==1,"no duplicate partial");
   ArrayResize(runnerStates,0);Tick();Check(partialCalls==1 && runnerStates[0].partialAttempted,"durable restart prevents repeat");
   Reset(.01);Tick();Tick();mockMarket=111;Tick();Check(partialCalls==0 && posVolume==.01,"min lot never split or enlarged");
   Reset();Tick();Tick();mockMarket=111;partialCode=TRADE_RETCODE_TIMEOUT;Tick();Tick();Check(partialCalls==1 && researchExecutionUnresolved,"timeout without fill fails closed no retry");
   Reset();Tick();Tick();mockMarket=111;partialCode=TRADE_RETCODE_TIMEOUT;timeoutFilled=true;Tick();ArrayResize(runnerStates,0);Tick();Check(partialCalls==1 && MathAbs(posVolume-.01)<1e-8,"timeout with late fill no double close");
   Reset(.04);Tick();Tick();mockMarket=111;partialCode=TRADE_RETCODE_DONE_PARTIAL;partialFill=.01;Tick();Tick();Check(partialCalls==1 && MathAbs(posVolume-.03)<1e-8,"partial fill no repeat request");
   Reset();Tick();Tick();mockMarket=125;Tick();Tick();Check(posSL>=116 && posSL<200,"closed H4 trail ignores forming candle");
   double prior=posSL;h4Close=115;Tick();Check(posSL>=prior,"buy trailing never loosens");
   Reset(.02,-1);Tick();Tick();mockMarket=75;Tick();Tick();Check(posSL<=84 && posSL>0,"sell trailing correct direction");
   prior=posSL;h4Close=85;Tick();Check(posSL<=prior,"sell trailing never loosens");
   Reset();posTP=0;Tick();Check(modifyCalls==0 && researchExecutionUnresolved,"lost durable state and missing TP fails closed");
   Reset();Tick();double r=runnerStates[0].risk;ArrayResize(runnerStates,0);Tick();Check(runnerStates[0].risk==r && r==10,"initial R immutable after moved stop and restart");
   PrintFormat("RUNNER_INTEGRATION_SUMMARY|Checks=%d|Failures=%d|Broker=MOCK|Header=REAL",checks,failures);
   return failures?INIT_FAILED:INIT_SUCCEEDED;
}
void OnTick() {}
