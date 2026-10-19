#requires -Version 7.0
$ErrorActionPreference='Stop'
$term='C:\Users\A\AppData\Roaming\MetaQuotes\Terminal\523FF71FCA93BC15AC28868379E0D478'
$token='G4D_'+[guid]::NewGuid().ToString('N');$dest=Join-Path $PSScriptRoot $token
$control=Join-Path $term 'MQL5\Files\TradingBrain_AutoLab';$owner=Join-Path $control 'native_owner.json'
$mutex=[Threading.Mutex]::new($false,'Local\TradingBrain_523FF_NativeQueue');if(!$mutex.WaitOne(0)){throw 'Queue occupied'}
$lock=$null;$owned=$false;$backups=@()
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
try{
 $lock=[IO.File]::Open((Join-Path $control 'runner.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 if((Test-Path $owner)-or @(Get-Process terminal64,metaeditor64 -ErrorAction SilentlyContinue).Count){throw 'Native queue occupied'}
 New-Item -ItemType Directory $dest|Out-Null
 @{token=$token;evidence=$dest;scope='DEMO_NO_TRADE_DUAL_CHART';phase='COMPILE'}|ConvertTo-Json|Set-Content $owner;$owned=$true
 $build=Join-Path $dest 'build';New-Item -ItemType Directory $build|Out-Null
 foreach($name in @('G4DemoWorker','G4DemoController')){
  Copy-Item (Join-Path $PSScriptRoot ($name+'.mq5')) $build
  $mq=Join-Path $build ($name+'.mq5');$log=Join-Path $build ($name+'.compile.log')
  $p=Start-Process (Join-Path $term 'MetaEditor64.exe') -ArgumentList @('/portable',('/compile:"'+$mq+'"'),('/log:"'+$log+'"')) -WindowStyle Hidden -PassThru
  $p.WaitForExit();if((Get-Content $log -Raw)-notmatch '0 errors, 0 warnings'){throw ('Compile failed '+$name)}
 }
 $experts=Join-Path $term ('MQL5\Experts\TB_PlanB_G4\'+$token);$scripts=Join-Path $term ('MQL5\Scripts\TB_PlanB_G4\'+$token)
 New-Item -ItemType Directory $experts,$scripts|Out-Null
 Copy-Item (Join-Path $build 'G4DemoWorker.ex5') $experts;Copy-Item (Join-Path $build 'G4DemoController.ex5') $scripts
 $base=Get-Content (Join-Path $term 'MQL5\Profiles\Templates\default.tpl') -Raw
 if($base -match '<expert>'){throw 'Default template has expert; refuse'}
 foreach($role in @('A','B')){
  $expert="<expert>`r`nname=G4DemoWorker`r`npath=Experts\TB_PlanB_G4\$token\G4DemoWorker.ex5`r`nexpertmode=0`r`n<inputs>`r`nInpRunId=$token`r`nInpRole=$role`r`n</inputs>`r`n</expert>`r`n"
  $tpl=$base.Replace('<window>',$expert+'<window>') -replace '(?m)^symbol=.*','symbol=GOLD'
  $tpl|Set-Content (Join-Path $term ("MQL5\Profiles\Templates\${token}_${role}.tpl")) -Encoding unicode
  $tpl|Set-Content (Join-Path $dest ($role+'.tpl')) -Encoding unicode
 }
 $preset=Join-Path $term ('MQL5\Presets\'+$token+'.set');New-Item -ItemType Directory (Split-Path $preset) -Force|Out-Null
 "InpRunId=$token`r`nInpTemplateA=${token}_A.tpl`r`nInpTemplateB=${token}_B.tpl"|Set-Content $preset -Encoding unicode
 Copy-Item $preset (Join-Path $dest 'effective.set')
 $profile='PlanB_NoCharts_'+$token;New-Item -ItemType Directory (Join-Path $term ('MQL5\Profiles\Charts\'+$profile))|Out-Null
 $private=Join-Path $dest 'private';New-Item -ItemType Directory $private|Out-Null
 foreach($name in @('common.ini','terminal.ini')){$original=Join-Path $term ('config\'+$name);$backup=Join-Path $private $name;Copy-Item $original $backup;$backups+=@{original=$original;backup=$backup;sha256=(Sha $backup)}}
 $backups|ConvertTo-Json|Set-Content (Join-Path $private 'restore.json')
 $ini=Join-Path $dest 'startup.ini'
 @"
[Common]
Profile=$profile
[Charts]
ProfileLast=$profile
[Experts]
Enabled=1
AllowLiveTrading=0
AllowDllImport=0
[StartUp]
Symbol=GOLD
Period=M5
Script=TB_PlanB_G4\$token\G4DemoController
ScriptParameters=$token.set
ShutdownTerminal=1
"@|Set-Content $ini -Encoding unicode
 @{token=$token;evidence=$dest;scope='DEMO_NO_TRADE_DUAL_CHART';phase='RUNNING';restore=(Join-Path $private 'restore.json')}|ConvertTo-Json|Set-Content $owner
 $p=Start-Process (Join-Path $term 'terminal64.exe') -ArgumentList @('/portable',('/config:"'+$ini+'"')) -WindowStyle Hidden -PassThru
 $cim=Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)"
 @{pid=$p.Id;path=$cim.ExecutablePath;command=$cim.CommandLine;run_id=$token}|ConvertTo-Json|Set-Content (Join-Path $dest 'launch.json')
 if($cim.ExecutablePath -ine (Join-Path $term 'terminal64.exe') -or $cim.CommandLine -notmatch '/portable'){throw 'Wrong route'}
 if(!$p.WaitForExit(90000)){throw 'Native Demo probe timeout; preserve owner, do not start another terminal'}
 $result=Join-Path $env:APPDATA ('MetaQuotes\Terminal\Common\Files\TB_PLANB_G4\'+$token+'\RESULT.txt')
 if(!(Test-Path $result)){throw 'No Demo probe result'}
 Copy-Item (Split-Path $result) (Join-Path $dest 'common_exchange') -Recurse
 Get-Content $result
 $entries=Get-ChildItem $build -File|ForEach-Object{@{file=$_.Name;sha256=(Sha $_.FullName)}}
 $entries|ConvertTo-Json|Set-Content (Join-Path $dest 'build_identity.json')
 Write-Output $dest
}catch{if(Test-Path $dest){$_|Out-String|Set-Content (Join-Path $dest 'failure.txt')};throw}
finally{
 if($owned -and !@(Get-Process terminal64,metaeditor64 -ErrorAction SilentlyContinue).Count){$ok=$true;foreach($b in $backups){try{[IO.File]::WriteAllBytes($b.original,[IO.File]::ReadAllBytes($b.backup));if((Sha $b.original)-ne $b.sha256){$ok=$false}}catch{$ok=$false}};if($ok){@{restored=$true;run_id=$token}|ConvertTo-Json|Set-Content (Join-Path $dest 'restoration.json');Remove-Item -LiteralPath $owner}}
 if($null-ne $lock){$lock.Dispose()};$mutex.ReleaseMutex();$mutex.Dispose()
}
