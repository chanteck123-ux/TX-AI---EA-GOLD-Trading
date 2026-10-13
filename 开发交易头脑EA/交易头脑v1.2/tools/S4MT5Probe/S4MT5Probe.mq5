//+------------------------------------------------------------------+
//| S4 B3 tester-only quote/order probe (research/S4_B3_MT5_PROBE_SCOPE_CN.md)
//| Historical Strategy Tester ONLY: OnInit fails outside MQL_TESTER.  |
//| Default mode records quotes and never trades. Order mode requires  |
//| InpMode=PROBE_ORDER AND InpAllowTesterOrders=true. Not a strategy, |
//| not S4, never for demo or live. A minimal probe that does not      |
//| reproduce an effect does NOT rule it out in the full S4 EA.        |
//| Output: agent-local Files S4MT5Probe\<InpRunLabel>\*.csv           |
//+------------------------------------------------------------------+
#property copyright "TradingBrain research probe"
#property version   "1.01"
#property description "S4 B3 tester-only quote/order probe; refuses non-tester; no strategy logic"

enum ENUM_PROBE_MODE { PROBE_QUOTE_ONLY=0, PROBE_ORDER=1 };
input ENUM_PROBE_MODE InpMode=PROBE_QUOTE_ONLY;   // default: quotes only, no orders
input bool   InpAllowTesterOrders=false;           // must be true for PROBE_ORDER, false otherwise
input string InpRunLabel="UNSET";                   // unique label, [A-Za-z0-9_-]
input int    InpDeclaredDelayMs=-1;                 // LABEL ONLY; tester.ini/journal are the delay evidence

#define PROBE_VERSION     "S4B3_PROBE_1.01"
#define PROBE_MAGIC       7340301
#define SL_DISTANCE       8.0     // price distance (registered)
#define TP_DISTANCE       12.0    // price distance (registered)
#define FEE_RESERVE_USD   1.0     // added to stop-loss money risk (registered)
#define MAX_RISK_PCT      2.0     // of equity (registered)
#define HOLD_MS           1000    // exit attempt at first tick >= entry DEAL_TIME_MSC + 1 s
#define BOUNDARY_MS       2000    // log every OnTick within +-2 s of each M5 boundary
#define FOCUS_BEFORE_S    90      // full logging around each registered slot
#define FOCUS_AFTER_S     180
#define RETRY_CLOSE_S     2       // explicit (not unknown) exit rejection may be retried after 2 s

datetime g_slot_time[2];
int      g_slot_state[2];         // 0 waiting, 1 position open, 2 finished (closed/skipped/rejected/unknown)
string   g_slot_reason[2];

bool     g_init_ok=false,g_on_tester_called=false;
MqlTick  g_cached;                // quote cached from the previous OnTick (what an EA would hold)
bool     g_have_cached=false;
long     g_ontick=0,g_same_ms_index=0,g_prev_fresh_msc=-1,g_same_ms_calls=0,g_quote_changes=0,g_first_msc=0,g_last_msc=0,g_logged=0;
long     g_tick_fail=0,g_new_bars=0,g_tx_seq=0;
datetime g_prev_bar=0;
int      h_quotes=INVALID_HANDLE,h_orders=INVALID_HANDLE,h_tx=INVALID_HANDLE,h_meta=INVALID_HANDLE;
string   g_dir="";
int      g_atr=INVALID_HANDLE;
string   g_interventions="";
// position management
ulong    g_pos_id=0;              // DEAL_POSITION_ID / POSITION_IDENTIFIER
ulong    g_pos_ticket=0;          // POSITION_TICKET resolved by identifier + magic + symbol
int      g_pos_slot=-1;
long     g_entry_ref_msc=0;
string   g_hold_basis="";
long     g_close_retry_after_msc=0;
bool     g_block_new_entries=false; // unknown entry outcome or unresolved identity: no new entries
bool     g_exit_blocked=false;      // unknown exit outcome: never resend; tester end will close

string D(double v){return DoubleToString(v,_Digits);}
string L(long v){return IntegerToString(v);}
// RFC4180-style escaping for any field that may contain separators.
string Q(string s){if(StringFind(s,",")<0&&StringFind(s,"\"")<0&&StringFind(s,"\n")<0&&StringFind(s,"\r")<0)return s;StringReplace(s,"\"","\"\"");StringReplace(s,"\r"," ");StringReplace(s,"\n"," ");return "\""+s+"\"";}
void   Out(int h,string s){if(h!=INVALID_HANDLE){FileWriteString(h,s+"\r\n");}}
void   Meta(string k,string v){Out(h_meta,Q(k)+","+Q(v));}
string TickCols(const MqlTick &t){return L(t.time_msc)+","+D(t.bid)+","+D(t.ask)+","+D(t.last)+","+L((long)t.volume)+","+L((long)t.flags);}
string EmptyTick(){return ",,,,,";}
string Snap(const MqlTick &t,bool ok){return ok?L(t.time_msc)+":"+D(t.bid)+":"+D(t.ask)+":"+L((long)t.flags):"FAIL";}
double RoundUp(double p,double t){return NormalizeDouble(MathCeil(p/t-1e-9)*t,_Digits);}
double RoundDown(double p,double t){return NormalizeDouble(MathFloor(p/t+1e-9)*t,_Digits);}

bool LabelOk(string s)
{
   int n=StringLen(s); if(n<4||n>80||s=="UNSET") return false;
   for(int i=0;i<n;i++){ushort c=StringGetCharacter(s,i); if(!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||(c>='0'&&c<='9')||c=='_'||c=='-')) return false;}
   return true;
}
bool NearM5Boundary(long msc){long r=msc%300000; return r<=BOUNDARY_MS || r>=300000-BOUNDARY_MS;}
bool InFocus(long msc)
{
   for(int s=0;s<2;s++){long t=(long)g_slot_time[s]*1000; if(msc>=t-FOCUS_BEFORE_S*1000 && msc<=t+FOCUS_AFTER_S*1000) return true;}
   return false;
}
bool Filling(ENUM_ORDER_TYPE_FILLING &fill)
{
   long flags=SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
   if((flags&SYMBOL_FILLING_FOK)!=0){fill=ORDER_FILLING_FOK;return true;}
   if((flags&SYMBOL_FILLING_IOC)!=0){fill=ORDER_FILLING_IOC;return true;}
   if(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_EXEMODE)!=SYMBOL_TRADE_EXECUTION_MARKET){fill=ORDER_FILLING_RETURN;return true;}
   return false;
}
// Resolve the position ticket from its identifier; never assume identifier == ticket.
ulong FindPositionTicket(ulong posId)
{
   if(posId==0) return 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong t=PositionGetTicket(i);
      if(t>0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==posId && PositionGetInteger(POSITION_MAGIC)==PROBE_MAGIC && PositionGetString(POSITION_SYMBOL)==_Symbol) return t;
   }
   return 0;
}
// OBSERVER INTERVENTION: CopyTicksRange is itself a call into the tester; it runs only on logged ticks and AFTER order logic.
string TesterRowView(long msc)
{
   MqlTick same[]; int n=CopyTicksRange(_Symbol,same,COPY_TICKS_ALL,(ulong)msc,(ulong)msc);
   string flags=""; if(n>0){for(int i=0;i<n;i++) flags+=(i>0?"/":"")+L((long)same[i].flags);}
   string s=L(n)+","+Q(flags)+","+(n>0?D(same[n-1].bid)+","+D(same[n-1].ask):",");
   MqlTick prev[]; int m=CopyTicksRange(_Symbol,prev,COPY_TICKS_ALL,(ulong)(msc-2000),(ulong)(msc-1));
   s+=","+(m>0?L(prev[m-1].time_msc)+","+D(prev[m-1].bid)+","+D(prev[m-1].ask)+","+L((long)prev[m-1].flags):(m<0?"ERR"+L(GetLastError())+",,,":",,,"));
   return s;
}

int OnInit()
{
   g_init_ok=false;
   if(!MQLInfoInteger(MQL_TESTER)){Print("S4B3_PROBE_REFUSED: historical Strategy Tester only");return INIT_FAILED;}
   if(MQLInfoInteger(MQL_OPTIMIZATION)||MQLInfoInteger(MQL_VISUAL_MODE)){Print("S4B3_PROBE_REFUSED: single non-visual tester pass only");return INIT_FAILED;}
   if(InpMode==PROBE_ORDER && !InpAllowTesterOrders){Print("S4B3_PROBE_REFUSED: order mode needs explicit InpAllowTesterOrders=true");return INIT_PARAMETERS_INCORRECT;}
   if(InpMode!=PROBE_ORDER && InpAllowTesterOrders){Print("S4B3_PROBE_REFUSED: InpAllowTesterOrders=true is only valid with PROBE_ORDER");return INIT_PARAMETERS_INCORRECT;}
   if(_Symbol!="GOLD"||_Period!=PERIOD_M5){Print("S4B3_PROBE_REFUSED: registered GOLD M5 only");return INIT_PARAMETERS_INCORRECT;}
   if(!LabelOk(InpRunLabel)){Print("S4B3_PROBE_REFUSED: invalid InpRunLabel");return INIT_PARAMETERS_INCORRECT;}
   g_atr=iATR(_Symbol,PERIOD_M5,14);
   g_slot_time[0]=D'2026.08.03 11:20:00'; g_slot_time[1]=D'2026.08.03 12:30:00';
   for(int s=0;s<2;s++){g_slot_state[s]=(InpMode==PROBE_ORDER?0:2);g_slot_reason[s]=(InpMode==PROBE_ORDER?"NOT_REACHED":"QUOTE_ONLY_MODE");}
   FolderCreate("S4MT5Probe"); g_dir="S4MT5Probe\\"+InpRunLabel; FolderCreate(g_dir);
   h_meta=FileOpen(g_dir+"\\meta.csv",FILE_WRITE|FILE_TXT|FILE_ANSI);
   h_quotes=FileOpen(g_dir+"\\quotes.csv",FILE_WRITE|FILE_TXT|FILE_ANSI);
   h_orders=FileOpen(g_dir+"\\orders.csv",FILE_WRITE|FILE_TXT|FILE_ANSI);
   h_tx=FileOpen(g_dir+"\\transactions.csv",FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h_meta==INVALID_HANDLE||h_quotes==INVALID_HANDLE||h_orders==INVALID_HANDLE||h_tx==INVALID_HANDLE){Print("S4B3_PROBE_REFUSED: cannot open output files err=",GetLastError());return INIT_FAILED;}
   Out(h_meta,"key,value");
   Meta("probe_version",PROBE_VERSION);
   Meta("run_label",InpRunLabel);
   Meta("mode",InpMode==PROBE_ORDER?"PROBE_ORDER":"PROBE_QUOTE_ONLY");
   Meta("allow_tester_orders",InpAllowTesterOrders?"true":"false");
   Meta("declared_delay_ms_label_only",L(InpDeclaredDelayMs));
   Meta("tester",L(MQLInfoInteger(MQL_TESTER)));
   Meta("terminal_build",L(TerminalInfoInteger(TERMINAL_BUILD)));
   Meta("symbol",_Symbol);
   Meta("account_currency",AccountInfoString(ACCOUNT_CURRENCY));
   Meta("account_leverage",L(AccountInfoInteger(ACCOUNT_LEVERAGE)));
   Meta("account_margin_mode",L(AccountInfoInteger(ACCOUNT_MARGIN_MODE)));
   Meta("initial_balance",DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   Meta("initial_equity",DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));
   Meta("volume_min",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),8));
   Meta("volume_step",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP),8));
   Meta("tick_size",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE),8));
   Meta("contract_size",DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE),8));
   Meta("stops_level",L(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)));
   Meta("freeze_level",L(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL)));
   Meta("filling_mode",L(SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE)));
   Meta("trade_exemode",L(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_EXEMODE)));
   Meta("registered_slots_server","2026.08.03 11:20:00|2026.08.03 12:30:00");
   Meta("registered_sl_tp_distance",DoubleToString(SL_DISTANCE,2)+"|"+DoubleToString(TP_DISTANCE,2));
   Meta("registered_risk","fee_reserve_usd="+DoubleToString(FEE_RESERVE_USD,2)+"|max_pct_equity="+DoubleToString(MAX_RISK_PCT,2));
   Meta("wall_clock_note","GetMicrosecondCount is process wall time, NOT simulated market time");
   Meta("intervention_sequence_every_tick","F0 SymbolInfoTick > iTime(M5 0) > F1 > CopyBuffer(iATR14 M5 shift2) > F2 > CopyRates(M5 0 7) > F3; mirrors S4 OnTick start then GSMScan4 Val then GSMNewBar order");
   Meta("observer_intervention","On logged ticks only, CopyTicksRange (same ms; previous 2 s) runs AFTER order logic; it is itself a tester call and cannot prove behaviour of an uninstrumented full S4 EA");
   Meta("boundary","A minimal probe that does not reproduce a cache effect does not rule it out in the full S4 EA");
   Meta("atr_handle_ok",g_atr==INVALID_HANDLE?"0":"1");
   Out(h_quotes,"ontick_seq,same_ms_index,timecurrent_s,wall_us,itime_m5_before,itime_m5_after,new_bar,"
       "cached_time_msc,cached_bid,cached_ask,cached_last,cached_volume,cached_flags,"
       "fresh_time_msc,fresh_bid,fresh_ask,fresh_last,fresh_volume,fresh_flags,"
       "tester_rows_in_ms,tester_flags_in_ms,tester_last_in_ms_bid,tester_last_in_ms_ask,tester_prev_time_msc,tester_prev_bid,tester_prev_ask,tester_prev_flags,log_reason,interventions");
   Out(h_orders,"event,slot,ontick_seq,timecurrent_s,"
       "cached_time_msc,cached_bid,cached_ask,cached_last,cached_volume,cached_flags,"
       "ontick_fresh_time_msc,ontick_fresh_bid,ontick_fresh_ask,ontick_fresh_last,ontick_fresh_volume,ontick_fresh_flags,"
       "pre_request_time_msc,pre_request_bid,pre_request_ask,pre_request_last,pre_request_volume,pre_request_flags,"
       "post_return_time_msc,post_return_bid,post_return_ask,post_return_last,post_return_volume,post_return_flags,"
       "req_type,req_volume,req_price,req_sl,req_tp,req_deviation,req_filling,req_position,"
       "send_return,res_retcode,res_retcode_external,res_request_id,res_order,res_deal,res_price,res_volume,res_bid,res_ask,res_comment,"
       "wall_us_before_send,wall_us_after_send,deal_time_s,deal_time_msc,deal_price,deal_volume,deal_entry,deal_reason,position_id,position_ticket,"
       "risk_usd_incl_reserve,risk_limit_usd,margin_calc,check_retcode,check_margin,equity,detail");
   Out(h_tx,"tx_seq,ontick_seq_at_callback,timecurrent_s,wall_us,cb_fresh_time_msc,cb_fresh_bid,cb_fresh_ask,cb_fresh_last,cb_fresh_volume,cb_fresh_flags,"
       "trans_type,trans_order,trans_deal,trans_position,trans_price,trans_volume,trans_deal_type,trans_order_state,"
       "req_action,req_type,req_price,res_retcode,res_order,res_deal,deal_time_msc,deal_price");
   g_init_ok=true;
   return INIT_SUCCEEDED;
}

void LogOrder(string ev,int slot,const MqlTick &onTickFresh,const MqlTick &pre,bool havePre,const MqlTick &post,bool havePost,
              const MqlTradeRequest &req,bool haveReq,bool sent,const MqlTradeResult &res,bool haveRes,ulong us0,ulong us1,
              double risk,double limit,double margin,const MqlTradeCheckResult &ck,bool haveCk,string detail)
{
   long dsec=0,dmsc=0,dentry=-1,dreason=-1,pid=0; double dprice=0,dvol=0;
   if(haveRes && res.deal>0 && HistoryDealSelect(res.deal))
   {
      dsec=HistoryDealGetInteger(res.deal,DEAL_TIME); dmsc=HistoryDealGetInteger(res.deal,DEAL_TIME_MSC);
      dprice=HistoryDealGetDouble(res.deal,DEAL_PRICE); dvol=HistoryDealGetDouble(res.deal,DEAL_VOLUME);
      dentry=HistoryDealGetInteger(res.deal,DEAL_ENTRY); dreason=HistoryDealGetInteger(res.deal,DEAL_REASON); pid=HistoryDealGetInteger(res.deal,DEAL_POSITION_ID);
   }
   string row=Q(ev)+","+L(slot)+","+L(g_ontick)+","+L((long)TimeCurrent())+","+(g_have_cached?TickCols(g_cached):EmptyTick())+","+TickCols(onTickFresh)+","
      +(havePre?TickCols(pre):EmptyTick())+","+(havePost?TickCols(post):EmptyTick())+",";
   if(haveReq) row+=L((long)req.type)+","+DoubleToString(req.volume,2)+","+D(req.price)+","+D(req.sl)+","+D(req.tp)+","+L((long)req.deviation)+","+L((long)req.type_filling)+","+L((long)req.position)+",";
   else row+=",,,,,,,,";
   if(haveRes) row+=(sent?"1":"0")+","+L((long)res.retcode)+","+L((long)res.retcode_external)+","+L((long)res.request_id)+","+L((long)res.order)+","+L((long)res.deal)+","+D(res.price)+","+DoubleToString(res.volume,2)+","+D(res.bid)+","+D(res.ask)+","+Q(res.comment)+",";
   else row+=",,,,,,,,,,,";
   row+=(us0>0?L((long)us0):"")+","+(us1>0?L((long)us1):"")+","+L(dsec)+","+L(dmsc)+","+D(dprice)+","+DoubleToString(dvol,2)+","+L(dentry)+","+L(dreason)+","+L(pid)+","+L((long)g_pos_ticket)+","
      +DoubleToString(risk,2)+","+DoubleToString(limit,2)+","+DoubleToString(margin,2)+","+(haveCk?L((long)ck.retcode)+","+DoubleToString(ck.margin,2):",")+","
      +DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)+","+Q(detail);
   Out(h_orders,row);
}

bool ExplicitFailure(uint code)
{
   switch(code){case TRADE_RETCODE_REQUOTE:case TRADE_RETCODE_REJECT:case TRADE_RETCODE_CANCEL:case TRADE_RETCODE_INVALID:case TRADE_RETCODE_INVALID_VOLUME:
   case TRADE_RETCODE_INVALID_PRICE:case TRADE_RETCODE_INVALID_STOPS:case TRADE_RETCODE_TRADE_DISABLED:case TRADE_RETCODE_MARKET_CLOSED:case TRADE_RETCODE_NO_MONEY:
   case TRADE_RETCODE_PRICE_CHANGED:case TRADE_RETCODE_PRICE_OFF:case TRADE_RETCODE_INVALID_FILL:case TRADE_RETCODE_INVALID_ORDER:return true;}
   return false;
}

void LogSimple(string ev,int slot,const MqlTick &fresh,string why)
{
   MqlTradeRequest rq={}; MqlTradeResult rs={}; MqlTradeCheckResult ck={}; MqlTick none={};
   LogOrder(ev,slot,fresh,none,false,none,false,rq,false,false,rs,false,0,0,0,0,0,ck,false,why);
}
void Skip(int s,const MqlTick &fresh,string why){g_slot_state[s]=2; g_slot_reason[s]=why; LogSimple("SKIPPED",s,fresh,why);}

// One registered sell at the first eligible tick at/after the slot. Non-compliant -> skipped (no upsizing, no later retry).
void TrySell(int s,const MqlTick &fresh)
{
   MqlTick pre={}; MqlTick none={};
   if(!SymbolInfoTick(_Symbol,pre)||pre.bid<=0||pre.ask<pre.bid) return;   // not an eligible quote; wait for the next tick
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE),vol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),price=pre.bid;
   if(tick<=0||vol<=0){Skip(s,fresh,"SYMBOL_SPEC_INVALID");return;}
   double sl=RoundUp(price+SL_DISTANCE,tick),tp=RoundDown(price-TP_DISTANCE,tick),pl=0,margin=0;
   if(!OrderCalcProfit(ORDER_TYPE_SELL,_Symbol,vol,price,sl,pl)){Skip(s,fresh,"ORDER_CALC_PROFIT_FAILED_"+L(GetLastError()));return;}
   double equity=AccountInfoDouble(ACCOUNT_EQUITY),risk=MathMax(0.0,-pl)+FEE_RESERVE_USD,limit=equity*MAX_RISK_PCT/100.0;
   MqlTradeRequest req={}; MqlTradeResult res={}; MqlTradeCheckResult ck={};
   if(risk>limit+1e-8){g_slot_state[s]=2;g_slot_reason[s]="RISK_OVER_LIMIT";LogOrder("SKIPPED",s,fresh,pre,true,none,false,req,false,false,res,false,0,0,risk,limit,0,ck,false,"RISK_OVER_LIMIT_NO_UPSIZE");return;}
   if(!OrderCalcMargin(ORDER_TYPE_SELL,_Symbol,vol,price,margin)){Skip(s,fresh,"ORDER_CALC_MARGIN_FAILED_"+L(GetLastError()));return;}
   req.action=TRADE_ACTION_DEAL; req.symbol=_Symbol; req.volume=vol; req.type=ORDER_TYPE_SELL; req.price=price; req.sl=sl; req.tp=tp;
   req.deviation=20; req.magic=PROBE_MAGIC; req.comment="S4B3_PROBE_ENTRY_"+L(s); req.type_time=ORDER_TIME_GTC;
   ENUM_ORDER_TYPE_FILLING fill=ORDER_FILLING_FOK; if(!Filling(fill)){Skip(s,fresh,"FILLING_UNSUPPORTED");return;} req.type_filling=fill;
   ResetLastError();
   if(!OrderCheck(req,ck)){g_slot_state[s]=2;g_slot_reason[s]="ORDER_CHECK_FAILED";LogOrder("SKIPPED",s,fresh,pre,true,none,false,req,true,false,res,false,0,0,risk,limit,margin,ck,true,"ORDER_CHECK_FAILED_"+L(GetLastError()));return;}
   ulong us0=GetMicrosecondCount(); bool sent=OrderSend(req,res); ulong us1=GetMicrosecondCount();
   MqlTick post={}; bool havePost=SymbolInfoTick(_Symbol,post);              // fresh quote AFTER return; separate from cached/pre
   string ev="ENTRY_SENT",detail="";
   if(res.retcode==TRADE_RETCODE_DONE||res.retcode==TRADE_RETCODE_DONE_PARTIAL)
   {
      long dmsc=0; ulong pid=0;
      if(res.deal>0&&HistoryDealSelect(res.deal)){dmsc=HistoryDealGetInteger(res.deal,DEAL_TIME_MSC);pid=(ulong)HistoryDealGetInteger(res.deal,DEAL_POSITION_ID);}
      g_pos_id=pid; g_pos_ticket=FindPositionTicket(pid); g_pos_slot=s; g_slot_state[s]=1; g_slot_reason[s]="ENTRY_DONE";
      if(dmsc>0){g_entry_ref_msc=dmsc;g_hold_basis="DEAL_TIME_MSC";}
      else {g_entry_ref_msc=havePost?post.time_msc:fresh.time_msc;g_hold_basis="DEAL_TIME_MSC_UNAVAILABLE_POST_QUOTE_FALLBACK";}
      if(g_pos_ticket==0){g_block_new_entries=true;detail="POSITION_TICKET_NOT_RESOLVED_FROM_IDENTIFIER;";}
      if(res.retcode==TRADE_RETCODE_DONE_PARTIAL) detail+="ENTRY_PARTIAL_FILL;";
   }
   else if(ExplicitFailure(res.retcode)){ev="ENTRY_REJECTED";g_slot_state[s]=2;g_slot_reason[s]="REJECTED_"+L((long)res.retcode);}
   else {ev="ENTRY_UNKNOWN_NO_RETRY";g_slot_state[s]=2;g_slot_reason[s]="UNKNOWN_"+L((long)res.retcode);g_block_new_entries=true;}
   LogOrder(ev,s,fresh,pre,true,post,havePost,req,true,sent,res,true,us0,us1,risk,limit,margin,ck,true,detail+"hold_basis="+g_hold_basis);
}

void TryClose(const MqlTick &fresh)
{
   int slot=g_pos_slot;                                        // keep for logging regardless of state changes
   MqlTick pre={};
   if(!PositionSelectByTicket(g_pos_ticket)) return;
   if(!SymbolInfoTick(_Symbol,pre)||pre.bid<=0||pre.ask<pre.bid) return;
   MqlTradeRequest req={}; MqlTradeResult res={}; MqlTradeCheckResult ck={};
   req.action=TRADE_ACTION_DEAL; req.symbol=_Symbol; req.position=g_pos_ticket; req.volume=PositionGetDouble(POSITION_VOLUME);
   req.type=ORDER_TYPE_BUY; req.price=pre.ask; req.deviation=20; req.magic=PROBE_MAGIC; req.comment="S4B3_PROBE_EXIT_"+L(slot);
   ENUM_ORDER_TYPE_FILLING fill=ORDER_FILLING_FOK; if(!Filling(fill)){g_exit_blocked=true;LogSimple("EXIT_FILLING_UNSUPPORTED",slot,fresh,"exit blocked; tester end closes");return;} req.type_filling=fill;
   ulong us0=GetMicrosecondCount(); bool sent=OrderSend(req,res); ulong us1=GetMicrosecondCount();
   MqlTick post={}; bool havePost=SymbolInfoTick(_Symbol,post);
   string ev="EXIT_SENT",detail="hold_basis="+g_hold_basis+";entry_ref_msc="+L(g_entry_ref_msc);
   if(res.retcode==TRADE_RETCODE_DONE||res.retcode==TRADE_RETCODE_DONE_PARTIAL)
   {
      if(PositionSelectByTicket(g_pos_ticket) && PositionGetDouble(POSITION_VOLUME)>0){ev="EXIT_PARTIAL_REMAINING_MANAGED";detail+=";remaining="+DoubleToString(PositionGetDouble(POSITION_VOLUME),2);}
      else {ev="EXIT_DONE"; if(slot>=0){g_slot_state[slot]=2;g_slot_reason[slot]="CLOSED_BY_PROBE";}}
   }
   else if(ExplicitFailure(res.retcode)){ev="EXIT_REJECTED_RETRY_AFTER_2S"; g_close_retry_after_msc=fresh.time_msc+RETRY_CLOSE_S*1000;}
   else {ev="EXIT_UNKNOWN_NO_RESEND"; g_exit_blocked=true; g_block_new_entries=true;}
   LogOrder(ev,slot,fresh,pre,true,post,havePost,req,true,sent,res,true,us0,us1,0,0,0,ck,false,detail);
   if(ev=="EXIT_DONE"){g_pos_id=0; g_pos_ticket=0; g_pos_slot=-1;}
}

void OrderLogic(const MqlTick &fresh)
{
   // Existing-position management first; it is never blocked by the new-entry stop.
   if(g_pos_id>0)
   {
      if(g_pos_ticket==0) g_pos_ticket=FindPositionTicket(g_pos_id);
      if(g_pos_ticket==0 || !PositionSelectByTicket(g_pos_ticket))
      {
         int slot=g_pos_slot;
         LogSimple("POSITION_CLOSED_BEFORE_PROBE_EXIT",slot,fresh,"server SL/TP or other; see transactions.csv");
         if(slot>=0){g_slot_state[slot]=2;g_slot_reason[slot]="CLOSED_BEFORE_PROBE_EXIT";}
         g_pos_id=0; g_pos_ticket=0; g_pos_slot=-1; return;
      }
      if(!g_exit_blocked && fresh.time_msc>=g_entry_ref_msc+HOLD_MS && fresh.time_msc>=g_close_retry_after_msc) TryClose(fresh);
      return;                                                  // single position: no new entry while one is open
   }
   if(g_block_new_entries) return;
   for(int s=0;s<2;s++)
   {
      if(g_slot_state[s]!=0) continue;
      if(fresh.time_msc<(long)g_slot_time[s]*1000) return;   // wait for the slot; slots are processed in order
      TrySell(s,fresh);
      return;
   }
}

void OnTick()
{
   g_ontick++;
   ulong us=GetMicrosecondCount();
   // Labelled interventions in the order the retained S4 uses them (MQ5 line 3198 SymbolInfoTick at OnTick start;
   // GSMScan4 line ~928: Val(M5 ATR14 shift 2) via CopyBuffer, then GSMNewBar via Rates/CopyRates(M5,0,7)).
   // Executed on EVERY tick (uniform); a fresh SymbolInfoTick is taken after each step.
   MqlTick fresh={}; bool ok=SymbolInfoTick(_Symbol,fresh);                      // F0
   datetime barBefore=iTime(_Symbol,PERIOD_M5,0);                                // I1
   MqlTick f1={}; bool ok1=SymbolInfoTick(_Symbol,f1);                           // F1
   double atrBuf[]; int atrGot=(g_atr==INVALID_HANDLE?-2:CopyBuffer(g_atr,0,2,1,atrBuf)); // I2
   MqlTick f2={}; bool ok2=SymbolInfoTick(_Symbol,f2);                           // F2
   MqlRates rates[]; ArraySetAsSeries(rates,true); int ratesGot=CopyRates(_Symbol,PERIOD_M5,0,7,rates); // I3
   MqlTick f3={}; bool ok3=SymbolInfoTick(_Symbol,f3);                           // F3
   datetime barAfter=(ratesGot>0?rates[0].time:barBefore);
   datetime tc=TimeCurrent();
   g_interventions="ITIME>"+Snap(f1,ok1)+"|ATR_COPYBUFFER("+L(atrGot)+":"+(atrGot>0?DoubleToString(atrBuf[0],6):"")+")>"+Snap(f2,ok2)
                   +"|COPYRATES("+L(ratesGot)+":"+(ratesGot>0?L((long)rates[0].time):"")+")>"+Snap(f3,ok3);
   if(!ok){g_tick_fail++;return;}
   if(g_first_msc==0) g_first_msc=fresh.time_msc;
   g_last_msc=fresh.time_msc;
   if(fresh.time_msc==g_prev_fresh_msc){g_same_ms_index++;g_same_ms_calls++;} else g_same_ms_index=0;
   bool newBar=(g_prev_bar!=0 && barAfter!=g_prev_bar);
   if(newBar) g_new_bars++;
   if(g_have_cached && (fresh.bid!=g_cached.bid||fresh.ask!=g_cached.ask)) g_quote_changes++;
   string reason="";
   if(NearM5Boundary(fresh.time_msc)) reason="M5_BOUNDARY_2S";
   if(InFocus(fresh.time_msc)) reason+=(reason==""?"":"|")+"FOCUS_SLOT";
   if(newBar) reason+=(reason==""?"":"|")+"NEW_BAR";
   string head=L(g_ontick)+","+L(g_same_ms_index)+","+L((long)tc)+","+L((long)us)+","+L((long)barBefore)+","+L((long)barAfter)+","+(newBar?"1":"0")+","
               +(g_have_cached?TickCols(g_cached):EmptyTick())+","+TickCols(fresh);
   if(InpMode==PROBE_ORDER && InpAllowTesterOrders) OrderLogic(fresh);                 // before any observer call
   if(reason!="")
   {
      g_logged++;
      Out(h_quotes,head+","+TesterRowView(fresh.time_msc)+","+Q(reason)+","+Q(g_interventions));   // observer intervention AFTER order logic
   }
   g_cached=fresh; g_have_cached=true; g_prev_fresh_msc=fresh.time_msc; g_prev_bar=barAfter;
}

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
{
   if(!g_init_ok) return;
   g_tx_seq++;
   MqlTick q={}; bool ok=SymbolInfoTick(_Symbol,q);
   long dmsc=0; double dprice=0;
   if(trans.deal>0 && HistoryDealSelect(trans.deal)){dmsc=HistoryDealGetInteger(trans.deal,DEAL_TIME_MSC);dprice=HistoryDealGetDouble(trans.deal,DEAL_PRICE);}
   Out(h_tx,L(g_tx_seq)+","+L(g_ontick)+","+L((long)TimeCurrent())+","+L((long)GetMicrosecondCount())+","+(ok?TickCols(q):EmptyTick())+","
       +L((long)trans.type)+","+L((long)trans.order)+","+L((long)trans.deal)+","+L((long)trans.position)+","+D(trans.price)+","+DoubleToString(trans.volume,2)+","
       +L((long)trans.deal_type)+","+L((long)trans.order_state)+","+L((long)request.action)+","+L((long)request.type)+","+D(request.price)+","
       +L((long)result.retcode)+","+L((long)result.order)+","+L((long)result.deal)+","+L(dmsc)+","+D(dprice));
}

// summary.csv is written ONLY from OnTester, so its presence plus on_tester_called=1 marks a tester pass that reached OnTester.
double OnTester()
{
   if(!g_init_ok) return 0.0;
   g_on_tester_called=true;
   int h=FileOpen(g_dir+"\\summary.csv",FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h==INVALID_HANDLE) return 0.0;
   int open=0; for(int i=PositionsTotal()-1;i>=0;i--){ulong t=PositionGetTicket(i); if(t>0&&PositionGetString(POSITION_SYMBOL)==_Symbol&&PositionGetInteger(POSITION_MAGIC)==PROBE_MAGIC) open++;}
   Out(h,"key,value");
   Out(h,"probe_version,"+PROBE_VERSION);
   Out(h,"on_tester_called,1");
   Out(h,"run_label,"+InpRunLabel);
   Out(h,"mode,"+(InpMode==PROBE_ORDER?"PROBE_ORDER":"PROBE_QUOTE_ONLY"));
   Out(h,"ontick_calls,"+L(g_ontick));
   Out(h,"ontick_calls_same_ms_as_previous,"+L(g_same_ms_calls));
   Out(h,"ontick_bid_or_ask_changed_vs_cached,"+L(g_quote_changes));
   Out(h,"symbolinfotick_failures,"+L(g_tick_fail));
   Out(h,"new_bars_seen,"+L(g_new_bars));
   Out(h,"quote_rows_logged,"+L(g_logged));
   Out(h,"first_fresh_time_msc,"+L(g_first_msc));
   Out(h,"last_fresh_time_msc,"+L(g_last_msc));
   Out(h,"transactions,"+L(g_tx_seq));
   for(int s=0;s<2;s++) Out(h,"slot"+L(s)+","+Q(L(g_slot_state[s])+"|"+g_slot_reason[s]));
   Out(h,"open_probe_positions_at_ontester,"+L(open));
   Out(h,"new_entries_blocked,"+(g_block_new_entries?"1":"0"));
   Out(h,"exit_blocked_unknown,"+(g_exit_blocked?"1":"0"));
   Out(h,"final_balance,"+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   Out(h,"note,probe P/L is a by-product of evidence collection and is not a strategy result");
   FileClose(h);
   return 0.0;
}

void OnDeinit(const int reason)
{
   if(!g_init_ok) return;                                       // rejected OnInit: write nothing
   Meta("deinit_reason",L(reason));
   Meta("on_tester_called_before_deinit",g_on_tester_called?"1":"0");
   if(h_quotes!=INVALID_HANDLE) FileClose(h_quotes);
   if(h_orders!=INVALID_HANDLE) FileClose(h_orders);
   if(h_tx!=INVALID_HANDLE) FileClose(h_tx);
   if(h_meta!=INVALID_HANDLE) FileClose(h_meta);
   if(g_atr!=INVALID_HANDLE) IndicatorRelease(g_atr);
}
