#requires -Version 7.0
$ErrorActionPreference='Stop'
$term='C:\Users\A\AppData\Roaming\MetaQuotes\Terminal\523FF71FCA93BC15AC28868379E0D478'
$control=Join-Path $term 'MQL5\Files\TradingBrain_AutoLab'
$token='G4_'+[guid]::NewGuid().ToString('N')
$dest=Join-Path $PSScriptRoot $token
$mutex=[Threading.Mutex]::new($false,'Local\TradingBrain_523FF_NativeQueue')
if(!$mutex.WaitOne(0)){throw 'Native mutex occupied'}
$lock=$null
$proc=$null
$owner=Join-Path $control 'native_owner.json'
$owned=$false
$backups=@()
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Idle {if(@(Get-Process terminal64,metaeditor64 -ErrorAction SilentlyContinue).Count){throw 'Terminal/editor is occupied'}}
try {
 $lock=[IO.File]::Open((Join-Path $control 'runner.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 if(Test-Path $owner){throw 'Existing native owner checkpoint; resume it before new work'}
 Idle
 New-Item -ItemType Directory -Path $dest | Out-Null
 @{token=$token;runner='plan_b_g4';evidence=$dest;scope='TESTER_ONLY_NO_TRADING';phase='PREPARING'}|ConvertTo-Json|Set-Content $owner
 $owned=$true
 $build=Join-Path $dest 'build';New-Item -ItemType Directory $build|Out-Null
 Copy-Item (Join-Path $PSScriptRoot 'G4FileProbe.mq5') $build
 $mq=Join-Path $build 'G4FileProbe.mq5';$ex=Join-Path $build 'G4FileProbe.ex5';$cl=Join-Path $build 'compile.log'
 $proc=Start-Process (Join-Path $term 'MetaEditor64.exe') -ArgumentList @('/portable',('/compile:"'+$mq+'"'),('/log:"'+$cl+'"')) -WindowStyle Hidden -PassThru
 $proc.WaitForExit();$proc=$null
 $ct=Get-Content $cl -Raw
 if($ct -notmatch '0 errors, 0 warnings' -or !(Test-Path $ex)){throw 'Native compilation failed'}
 @{source_sha256=(Sha $mq);ex5_sha256=(Sha $ex);compile_log_sha256=(Sha $cl);result='0 errors, 0 warnings'}|ConvertTo-Json|Set-Content (Join-Path $build 'identity.json')
 $install=Join-Path $term ('MQL5\Experts\TB_PlanB_G4\'+$token)
 New-Item -ItemType Directory $install|Out-Null;Copy-Item $ex $install
 $profile='PlanB_NoCharts_'+$token
 New-Item -ItemType Directory (Join-Path $term ('MQL5\Profiles\Charts\'+$profile))|Out-Null
 $private=Join-Path $dest 'private';New-Item -ItemType Directory $private|Out-Null
 foreach($name in @('common.ini','terminal.ini')){
  $original=Join-Path $term ('config\'+$name);$backup=Join-Path $private $name
  Copy-Item $original $backup;$backups+=@{original=$original;backup=$backup;sha256=(Sha $backup)}
 }
 $backups|ConvertTo-Json|Set-Content (Join-Path $private 'restore.json')
 $prior='';$results=@()
 foreach($suffix in @('A','B')) {
  Idle
  $run=$token+'_'+$suffix;$runDir=Join-Path $dest $run;New-Item -ItemType Directory $runDir|Out-Null
  $setName=$run+'.set';$set=Join-Path $term ('MQL5\Profiles\Tester\'+$setName)
  "InpRunId=$run`r`nInpPreviousRunId=$prior`r`n"|Set-Content $set -Encoding unicode
  Copy-Item $set (Join-Path $runDir 'effective.set')
  $reportRel='TB_PlanB_G4_Reports\'+$run+'.html'
  New-Item -ItemType Directory (Join-Path $term 'TB_PlanB_G4_Reports') -Force|Out-Null
  $ini=Join-Path $runDir 'tester.ini'
  @"
[Common]
Profile=$profile
[Experts]
Enabled=0
AllowLiveTrading=0
AllowDllImport=0
[Tester]
Expert=TB_PlanB_G4\$token\G4FileProbe.ex5
ExpertParameters=$setName
Symbol=GOLD
Period=M5
Model=4
ExecutionMode=0
Optimization=0
FromDate=2026.08.03
ToDate=2026.08.04
ForwardMode=0
Deposit=500
Currency=USD
Leverage=1:1000
Visual=0
UseLocal=1
UseRemote=0
UseCloud=0
Report=$reportRel
ReplaceReport=0
ShutdownTerminal=1
"@ |Set-Content $ini -Encoding unicode
  @{token=$token;runner='plan_b_g4';evidence=$dest;run_id=$run;phase='LAUNCHING';restore=(Join-Path $private 'restore.json')}|ConvertTo-Json|Set-Content $owner
  $before=@{};foreach($j in Get-ChildItem (Join-Path $term 'Tester') -Recurse -File -Filter '*.log'){$before[$j.FullName]=$j.Length}
  $proc=Start-Process (Join-Path $term 'terminal64.exe') -ArgumentList @('/portable',('/config:"'+$ini+'"')) -WindowStyle Hidden -PassThru
  $cim=Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)"
  @{run_id=$run;pid=$proc.Id;executable=$cim.ExecutablePath;command=$cim.CommandLine}|ConvertTo-Json|Set-Content (Join-Path $runDir 'launch.json')
  if($cim.ExecutablePath -ine (Join-Path $term 'terminal64.exe') -or $cim.CommandLine -notmatch '/portable'){throw 'Routing not verified'}
  $proc.WaitForExit();$proc=$null
  foreach($b in $backups){[IO.File]::WriteAllBytes($b.original,[IO.File]::ReadAllBytes($b.backup));if((Sha $b.original)-ne $b.sha256){throw 'Config restore mismatch'}}
  $lines=@();$origins=@()
  foreach($log in Get-ChildItem (Join-Path $term 'Tester') -Recurse -File -Filter '*.log'){
   $offset=if($before.ContainsKey($log.FullName)){$before[$log.FullName]}else{0}
   if($log.Length -eq $offset){continue};if($log.Length -lt $offset -or $log.Length-$offset -gt 32MB){throw 'Unexpected journal rotation/size'}
   $stream=[IO.File]::Open($log.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
   try{$head=[byte[]]::new(32);[void]$stream.Read($head,0,32);[void]$stream.Seek($offset,[IO.SeekOrigin]::Begin);$bytes=[byte[]]::new($log.Length-$offset);$stream.ReadExactly($bytes)}finally{$stream.Dispose()}
   $enc=if($head -contains 0){[Text.Encoding]::Unicode}else{[Text.Encoding]::UTF8}
   $tail=$enc.GetString($bytes);$hits=@($tail -split '\r?\n' | Where-Object {$_.Contains("G4|run=$run|")})
   if($hits.Count){$lines+=$hits;$raw=Join-Path $runDir ('journal_'+$origins.Count+'.bin');[IO.File]::WriteAllBytes($raw,$bytes);$origins+=@{path=$log.FullName;byte_offset=$offset;byte_count=$bytes.Length;raw_sha256=(Sha $raw)}}
  }
  $lines|Set-Content (Join-Path $runDir 'native_g4_log.txt') -Encoding utf8
  $origins|ConvertTo-Json -Depth 8|Set-Content (Join-Path $runDir 'log_origins.json')
  $report=Join-Path $term $reportRel
  if(Test-Path $report){Copy-Item $report (Join-Path $runDir 'report.html')}
  $pass=($lines -match 'stage=FILE_CAPABILITY_RESULT\|value=PASS').Count -gt 0 -and ($lines -match 'stage=ON_TESTER\|value=PASS').Count -gt 0
  $results+=@{run_id=$run;capability_pass=$pass;report_exists=(Test-Path $report);configs_restored=$true;dual_chart='NOT_RUN';trading='NO_TRADE_CALLS_IN_SOURCE'}
  $results|ConvertTo-Json -Depth 8|Set-Content (Join-Path $dest 'results.json')
  if(!$pass){throw 'G4 probe failed; preserve raw logs'}
  $prior=$run
 }
 $results|ConvertTo-Json -Depth 8
} catch {
 if(Test-Path $dest){$_|Out-String|Set-Content (Join-Path $dest 'failure.txt')}
 throw
} finally {
 $running=@(Get-Process terminal64,metaeditor64 -ErrorAction SilentlyContinue).Count -gt 0
 if(!$running -and $owned){
  $restored=$true
  foreach($b in $backups){try{[IO.File]::WriteAllBytes($b.original,[IO.File]::ReadAllBytes($b.backup));if((Sha $b.original)-ne $b.sha256){$restored=$false}}catch{$restored=$false}}
  if($restored){Remove-Item -LiteralPath $owner}
 }
 if($null-ne $lock){$lock.Dispose()};$mutex.ReleaseMutex();$mutex.Dispose()
}
