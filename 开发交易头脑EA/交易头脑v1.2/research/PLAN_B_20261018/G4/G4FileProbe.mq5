#property strict
#property version "1.00"
// Codex platform capability probe only. No trading calls; tester only.
input string InpRunId="";
input string InpPreviousRunId="";
bool ok=true;
void Record(string stage,string value,int error=0)
{
 PrintFormat("G4|run=%s|stage=%s|value=%s|error=%d",InpRunId,stage,value,error);
}
bool SafeId(string value)
{
 if(StringLen(value)<8 || StringLen(value)>80) return false;
 for(int i=0;i<StringLen(value);i++) { ushort c=StringGetCharacter(value,i); if(!((c>=48&&c<=57)||(c>=65&&c<=90)||(c>=97&&c<=122)||c==95)) return false; }
 return true;
}
bool RoundTrip(string path,int common)
{
 if(FileIsExist(path,common)) { Record("REFUSE_EXISTING",path);return false; }
 ResetLastError(); int w=FileOpen(path,FILE_WRITE|FILE_TXT|FILE_ANSI|common);
 Record("WRITE_OPEN",path,GetLastError()); if(w==INVALID_HANDLE)return false;
 ResetLastError(); uint n=FileWriteString(w,InpRunId); int e=GetLastError();FileFlush(w);FileClose(w);
 Record("WRITE_CLOSE",IntegerToString((int)n),e);
 ResetLastError(); int r=FileOpen(path,FILE_READ|FILE_TXT|FILE_ANSI|common);
 Record("READ_OPEN",path,GetLastError());if(r==INVALID_HANDLE)return false;
 string actual=FileReadString(r);FileClose(r);Record("READ_CLOSE",actual);
 return n>0 && actual==InpRunId;
}
int OnInit()
{
 if(!MQLInfoInteger(MQL_TESTER) || !SafeId(InpRunId) || (InpPreviousRunId!=""&&!SafeId(InpPreviousRunId)))return INIT_PARAMETERS_INCORRECT;
 Record("TERMINAL_PATH",TerminalInfoString(TERMINAL_PATH));
 Record("TERMINAL_DATA_PATH",TerminalInfoString(TERMINAL_DATA_PATH));
 Record("TERMINAL_COMMONDATA_PATH",TerminalInfoString(TERMINAL_COMMONDATA_PATH));
 Record("TESTER",IntegerToString((int)MQLInfoInteger(MQL_TESTER)));
 Record("ACCOUNT_TRADE_MODE",IntegerToString((int)AccountInfoInteger(ACCOUNT_TRADE_MODE)));
 string own="TB_PLANB_G4\\"+InpRunId+"\\state.txt";
 ok=RoundTrip(own,FILE_COMMON)&&ok;
 ok=RoundTrip(own,0)&&ok;
 // Deliberate missing-file fixture: negative evidence, never interpreted as success.
 ResetLastError();int missing=FileOpen("TB_PLANB_G4\\"+InpRunId+"\\absent.txt",FILE_READ|FILE_TXT|FILE_COMMON);
 int err=GetLastError();Record("EXPECTED_MISSING_OPEN",IntegerToString(missing),err);
 if(missing!=INVALID_HANDLE){FileClose(missing);ok=false;}else if(err==0)ok=false;
 if(InpPreviousRunId!="")
 {
  string prev="TB_PLANB_G4\\"+InpPreviousRunId+"\\state.txt";
  ResetLastError();int h=FileOpen(prev,FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
  Record("PREVIOUS_READ_OPEN",prev,GetLastError());
  if(h==INVALID_HANDLE)ok=false;
  else {string value=FileReadString(h);FileClose(h);Record("PREVIOUS_UNCHANGED",value);if(value!=InpPreviousRunId)ok=false;}
 }
 Record("DUAL_CHART","NOT_RUN_TESTER_SINGLE_EA_NOT_A_DUAL_INSTANCE_TEST");
 Record("FILE_CAPABILITY_RESULT",ok?"PASS":"FAIL");
 return INIT_SUCCEEDED;
}
void OnTick() {}
double OnTester(){Record("ON_TESTER",ok?"PASS":"FAIL");return ok?1:0;}
