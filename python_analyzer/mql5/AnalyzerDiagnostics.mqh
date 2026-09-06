#ifndef GSM_ANALYZER_DIAGNOSTICS_MQH
#define GSM_ANALYZER_DIAGNOSTICS_MQH

// Observation only. This header has NOT been compiled or MT5-regression-tested.
// No trade requests, parameter mutation, files, networking, or account identifiers.
input group "GSM Python Analyzer - observation only"
input bool   InpAnalyzerDiagnostics = false;
input bool   InpAnalyzerEquitySamples = false;
input int    InpAnalyzerSampleSeconds = 60;
input string InpAnalyzerRunLabel = ""; // Empty uses original InpAuditRunLabel.

ulong    g_analyzerSequence = 0;
string   g_analyzerSession = "";
datetime g_analyzerLastSample = 0;
bool     g_analyzerMetadataSent = false;

string AnalyzerEscape(string value)
{
   StringReplace(value,"%","%25");
   StringReplace(value,"|","%7C");
   StringReplace(value,"=","%3D");
   StringReplace(value,"\r","%0D");
   StringReplace(value,"\n","%0A");
   return value;
}

string AnalyzerRun(string originalRun)
{
   return (InpAnalyzerRunLabel==""?originalRun:InpAnalyzerRunLabel);
}

string AnalyzerEventId(string run)
{
   if(g_analyzerSession=="")
      g_analyzerSession=IntegerToString((long)TimeLocal())+"-"+IntegerToString((long)GetMicrosecondCount());
   g_analyzerSequence++;
   return AnalyzerEscape(run+":"+g_analyzerSession+":"+IntegerToString((long)g_analyzerSequence));
}

string AnalyzerDataMode()
{
   if(MQLInfoInteger(MQL_TESTER)) return "BACKTEST";
   long mode=AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(mode==ACCOUNT_TRADE_MODE_DEMO) return "DEMO";
   if(mode==ACCOUNT_TRADE_MODE_CONTEST) return "CONTEST";
   return "REAL";
}

void AnalyzerObserveFilter(string originalRun,string sop,string side,string zoneId,
                           bool rawCore,bool indicatorPassed,bool macdPassed,
                           bool confidencePassed,bool gatePassed,bool finalAccepted,
                           string reason,string decisionMeaning)
{
   if(!InpAnalyzerDiagnostics) return;
   string run=AnalyzerRun(originalRun);
   PrintFormat("GSM_ANALYZER|Run=%s|Time=%s|SOP=%s|Stage=FILTER_AUDIT|Reason=%s|Decision=%s|ZoneID=%s|EventID=%s|Side=%s|RawCore=%d|Indicator=%d|MACD=%d|Confidence=%d|Gate=%d|AcceptedObserved=%d|DecisionMeaning=%s|DataMode=%s|TimeZone=SERVER_UNKNOWN",
               AnalyzerEscape(run),TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
               AnalyzerEscape(sop),AnalyzerEscape(reason),(finalAccepted?"OBSERVED_PASS":"OBSERVED_BLOCK"),
               AnalyzerEscape(zoneId),AnalyzerEventId(run),AnalyzerEscape(side),
               (int)rawCore,(int)indicatorPassed,(int)macdPassed,(int)confidencePassed,
               (int)gatePassed,(int)finalAccepted,AnalyzerEscape(decisionMeaning),AnalyzerDataMode());
}

void AnalyzerObserveAccount(string originalRun,string symbol)
{
   if(!InpAnalyzerDiagnostics && !InpAnalyzerEquitySamples) return;
   string run=AnalyzerRun(originalRun);
   if(symbol=="") symbol=_Symbol;
   if(!g_analyzerMetadataSent)
   {
      PrintFormat("GSM_ANALYZER|Run=%s|Time=%s|SOP=Combined|Stage=METADATA|Reason=OBSERVATION_CONTEXT|Decision=OBSERVED|ZoneID=|EventID=%s|Symbol=%s|Currency=%s|DataMode=%s|TimeZone=SERVER_UNKNOWN|Point=%.10f|TickSize=%.10f|TickValue=%.10f|ContractSize=%.8f|VolumeMin=%.8f|VolumeStep=%.8f|DiagnosticEnabled=%d|EquitySamplesEnabled=%d|SampleSeconds=%d",
                  AnalyzerEscape(run),TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),AnalyzerEventId(run),
                  AnalyzerEscape(symbol),AnalyzerEscape(AccountInfoString(ACCOUNT_CURRENCY)),AnalyzerDataMode(),
                  SymbolInfoDouble(symbol,SYMBOL_POINT),SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE),
                  SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE),SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE),
                  SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN),SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP),
                  (int)InpAnalyzerDiagnostics,(int)InpAnalyzerEquitySamples,
                  (InpAnalyzerSampleSeconds>0?InpAnalyzerSampleSeconds:60));
      g_analyzerMetadataSent=true;
   }
   if(!InpAnalyzerEquitySamples) return;
   datetime now=TimeCurrent();
   int interval=(InpAnalyzerSampleSeconds>0?InpAnalyzerSampleSeconds:60);
   if(g_analyzerLastSample!=0 && now>=g_analyzerLastSample && now-g_analyzerLastSample<interval) return;
   g_analyzerLastSample=now;
   PrintFormat("GSM_ANALYZER|Run=%s|Time=%s|SOP=Combined|Stage=ACCOUNT_SAMPLE|Reason=SAMPLED_ACCOUNT_SNAPSHOT|Decision=OBSERVED|ZoneID=|EventID=%s|Balance=%.8f|Equity=%.8f|Currency=%s|Margin=%.8f|FreeMargin=%.8f|SampleSeconds=%d|DataMode=%s|TimeZone=SERVER_UNKNOWN",
               AnalyzerEscape(run),TimeToString(now,TIME_DATE|TIME_SECONDS),AnalyzerEventId(run),
               AccountInfoDouble(ACCOUNT_BALANCE),AccountInfoDouble(ACCOUNT_EQUITY),
               AnalyzerEscape(AccountInfoString(ACCOUNT_CURRENCY)),AccountInfoDouble(ACCOUNT_MARGIN),
               AccountInfoDouble(ACCOUNT_MARGIN_FREE),interval,AnalyzerDataMode());
}

#endif
