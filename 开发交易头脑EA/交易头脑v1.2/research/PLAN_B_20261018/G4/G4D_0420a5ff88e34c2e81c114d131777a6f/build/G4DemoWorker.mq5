#property strict
input string InpRunId="";
input string InpRole="";
bool done=false;
string FileName(string role){return "TB_PLANB_G4\\"+InpRunId+"\\"+role+".txt";}
bool Write(string role,string value){ResetLastError();int h=FileOpen(FileName(role),FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);if(h==INVALID_HANDLE){Print("G4D|write_error=",GetLastError());return false;}FileWriteString(h,value);FileFlush(h);FileClose(h);return true;}
string Read(string role){int h=FileOpen(FileName(role),FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ);if(h==INVALID_HANDLE)return "";string s=FileReadString(h);FileClose(h);return s;}
int OnInit(){if(MQLInfoInteger(MQL_TESTER)||AccountInfoInteger(ACCOUNT_TRADE_MODE)!=ACCOUNT_TRADE_MODE_DEMO||InpRunId==""||(InpRole!="A"&&InpRole!="B"))return INIT_FAILED;Print("G4D|run=",InpRunId,"|role=",InpRole,"|chart=",ChartID(),"|stage=INIT_DEMO");EventSetTimer(1);return INIT_SUCCEEDED;}
void OnTimer(){if(done)return;if(AccountInfoInteger(ACCOUNT_TRADE_MODE)!=ACCOUNT_TRADE_MODE_DEMO){EventKillTimer();return;}string prefix=InpRunId+"|";if(InpRole=="A"){if(Read("PING")=="")Write("PING",prefix+IntegerToString(ChartID()));string ack=Read("ACK");if(StringFind(ack,prefix)==0&&ack!=Read("PING")){if(Write("DONE",Read("PING")+";"+ack)){done=true;Print("G4D|run=",InpRunId,"|role=A|stage=PASS|peer=",ack);}}}else{string ping=Read("PING");if(StringFind(ping,prefix)==0&&ping!=prefix+IntegerToString(ChartID())){if(Write("ACK",prefix+IntegerToString(ChartID()))){done=true;Print("G4D|run=",InpRunId,"|role=B|stage=ACK|peer=",ping);}}}}
void OnTick(){}
void OnDeinit(const int reason){EventKillTimer();}
