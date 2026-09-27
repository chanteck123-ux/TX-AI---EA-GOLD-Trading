#ifndef GSM_STUDY_EVIDENCE
#define GSM_STUDY_EVIDENCE

long studyRequests=0,studyRejected=0,studyManagementRequests=0;

void StudyTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,
                      const MqlTradeResult &result)
{
   if(trans.type!=TRADE_TRANSACTION_REQUEST || !ResearchKnownMagic((long)request.magic) ||
      request.symbol!=g_symbol) return;
   studyRequests++;
   if(request.action==TRADE_ACTION_SLTP || request.position>0) studyManagementRequests++;
   bool accepted=(result.retcode==TRADE_RETCODE_DONE || result.retcode==TRADE_RETCODE_DONE_PARTIAL ||
                  result.retcode==TRADE_RETCODE_PLACED || result.retcode==TRADE_RETCODE_NO_CHANGES);
   if(!accepted) studyRejected++;
   PrintFormat("STUDY_REQUEST|Magic=%I64u|Action=%d|Position=%I64u|Retcode=%u|Accepted=%s|Price=%.8f|Fill=%.8f|Volume=%.8f",
               request.magic,(int)request.action,request.position,result.retcode,
               accepted?"YES":"NO",request.price,result.price,result.volume);
}

bool StudyExportEvidence()
{
   if(!MQLInfoInteger(MQL_TESTER)) return true;
   if(!HistorySelect(0,TimeCurrent())) return false;
   int file=FileOpen(InpAuditRunLabel+"_DEALS.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,',',CP_UTF8);
   if(file==INVALID_HANDLE) return false;
   FileWrite(file,"Deal","PositionID","Magic","Symbol","Entry","Type","Volume","Price",
             "Profit","Commission","Swap","Fee","TimeMsc","Order","Reason");
   for(int i=0;i<HistoryDealsTotal();i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      long type=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=g_symbol ||
         !ResearchKnownMagic(HistoryDealGetInteger(deal,DEAL_MAGIC))) continue;
      FileWrite(file,deal,HistoryDealGetInteger(deal,DEAL_POSITION_ID),HistoryDealGetInteger(deal,DEAL_MAGIC),
                g_symbol,HistoryDealGetInteger(deal,DEAL_ENTRY),type,
                DoubleToString(HistoryDealGetDouble(deal,DEAL_VOLUME),8),
                DoubleToString(HistoryDealGetDouble(deal,DEAL_PRICE),8),
                DoubleToString(HistoryDealGetDouble(deal,DEAL_PROFIT),8),
                DoubleToString(HistoryDealGetDouble(deal,DEAL_COMMISSION),8),
                DoubleToString(HistoryDealGetDouble(deal,DEAL_SWAP),8),
                DoubleToString(HistoryDealGetDouble(deal,DEAL_FEE),8),
                HistoryDealGetInteger(deal,DEAL_TIME_MSC),HistoryDealGetInteger(deal,DEAL_ORDER),
                HistoryDealGetInteger(deal,DEAL_REASON));
   }
   FileClose(file);
   file=FileOpen(InpAuditRunLabel+"_NATIVE_STATS.csv",FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,',',CP_UTF8);
   if(file==INVALID_HANDLE) return false;
   FileWrite(file,"Metric","Value");
   FileWrite(file,"NetProfitUSD",TesterStatistics(STAT_PROFIT));
   FileWrite(file,"MaxEquityDDUSD",TesterStatistics(STAT_EQUITY_DD));
   FileWrite(file,"MaxEquityDDPct",TesterStatistics(STAT_EQUITY_DDREL_PERCENT));
   FileWrite(file,"NativeBalanceRecovery",TesterStatistics(STAT_RECOVERY_FACTOR));
   FileWrite(file,"NativeTrades",TesterStatistics(STAT_TRADES));
   FileWrite(file,"NativeDeals",TesterStatistics(STAT_DEALS));
   FileWrite(file,"MinMarginLevel",TesterStatistics(STAT_MIN_MARGINLEVEL));
   FileWrite(file,"AllRequests",studyRequests);
   FileWrite(file,"ManagementRequests",studyManagementRequests);
   FileWrite(file,"AllRequestRejects",studyRejected);
   FileClose(file);
   return true;
}

double OnTester()
{
   if(!StudyExportEvidence()) Print("STUDY_EVIDENCE_EXPORT_FAILED");
   return TesterStatistics(STAT_PROFIT);
}
#endif
