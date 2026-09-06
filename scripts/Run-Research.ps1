param(
    [ValidateSet('Scalping','Intraday','Swing','Combined','UnitTests')][string]$Lane='Scalping',
    [int]$Capital=500,
    [int]$DelayMs=0,
    [string]$Source='src\GSM_FxPro_R_C00.mq5',
    [int]$TimeoutSeconds=1200
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$checkpoint=Join-Path $root 'CHECKPOINT.json'
if(Test-Path -LiteralPath $checkpoint){
    $previous=Get-Content -LiteralPath $checkpoint -Raw | ConvertFrom-Json
    if($previous.Stage -eq 'WAITING_MT5_UPDATE_BASELINE_INCOMPLETE'){
        throw 'MT5_UPDATE_BLOCKED: verify update completion and save a READY checkpoint before retry'
    }
}
$workspace=Split-Path (Split-Path $root -Parent) -Parent
$terminalRoot=Join-Path $workspace 'work\backtest-v220\fxpro-terminal'
$runtimeCheckpoint=Join-Path $root 'RUNTIME_CHECKPOINT.json'
if(Test-Path -LiteralPath $runtimeCheckpoint){
    $runtime=Get-Content -LiteralPath $runtimeCheckpoint -Raw | ConvertFrom-Json
    if($runtime.BrokerServer -ne 'FxPro-MT5 Demo' -or $runtime.LiveTradingEnabled){throw 'INVALID_RESEARCH_RUNTIME'}
    $terminalRoot=$runtime.TerminalRoot
    foreach($entry in $runtime.BinaryHashes.PSObject.Properties){
        if((Get-FileHash -LiteralPath (Join-Path $terminalRoot $entry.Name)).Hash -ne $entry.Value){throw 'RUNTIME_EXECUTABLE_CHANGED'}
    }
}
$terminal=Join-Path $terminalRoot 'terminal64.exe'
if(Get-Process terminal64 -ErrorAction SilentlyContinue | Where-Object {$_.Path -eq $terminal}){throw 'TERMINAL_ALREADY_RUNNING; reconcile before retry'}
$protected=Join-Path $workspace 'work\baseline-audit-20260905\repository\champion\current\GSM_GOLD_3SOP_EA_V4.00_CURRENT_CHAMPION.zip'
if((Get-FileHash -LiteralPath $protected).Hash -ne '43AF3C393B6C226211115A1A1DBC70C88F0F07250FA332D22C04C3ED64EB80E2'){throw 'CURRENT_CHAMPION_INTEGRITY_FAIL'}
if($Lane -eq 'UnitTests' -and -not $PSBoundParameters.ContainsKey('Source')){$Source='tests\RiskMathTests.mq5'}
$sourcePath=Join-Path $root $Source
$binary=[IO.Path]::ChangeExtension($sourcePath,'.ex5')
$sourceHash=(Get-FileHash -LiteralPath $sourcePath).Hash
$binaryHash=(Get-FileHash -LiteralPath $binary).Hash
$compiles=@(Get-ChildItem -LiteralPath (Join-Path $root 'reports\compile') -Filter COMPILE.json -Recurse -File | ForEach-Object {Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json})
$proof=$compiles | Where-Object {$_.Stage -eq 'COMPILE_PASS' -and $_.SourceSHA256 -eq $sourceHash -and $_.EX5SHA256 -eq $binaryHash -and $_.Dependencies} | Select-Object -Last 1
if(-not $proof){throw 'NO_MATCHING_COMPILE_PROOF'}
foreach($property in $proof.Dependencies.PSObject.Properties){
    if((Get-FileHash -LiteralPath $property.Name).Hash -ne $property.Value){throw "COMPILE_DEPENDENCY_CHANGED: $($property.Name)"}
}
$candidate=if([IO.Path]::GetFileNameWithoutExtension($Source) -in @('GSM_FxPro_S_C01','ZoneRankTests')){'S_C01'}else{'R_C00'}
$run=('{0}_{1}_USD{2}_D{3}_{4}' -f $candidate,$Lane,$Capital,$DelayMs,(Get-Date -Format 'yyyyMMdd_HHmmss'))
$out=Join-Path $root ('reports\runs\'+$run)
New-Item -ItemType Directory -Path $out | Out-Null
$expertName=[IO.Path]::GetFileName($binary)
Copy-Item -LiteralPath $binary -Destination (Join-Path $terminalRoot ('MQL5\Experts\'+$expertName))
$parameters=[ordered]@{}
$baseSet=$null
if($Lane -ne 'UnitTests'){
    $links=Import-Csv -LiteralPath (Join-Path $workspace 'work\baseline-audit-20260905\audit\CONFIG_REPORT_HASH_LINKS.csv')
    $link=@($links | Where-Object {$_.Lane -eq $Lane -and $_.Broker -eq 'FxPro' -and $_.Segment -eq 'FULL'})
    if($link.Count -ne 1){throw 'FROZEN_SET_NOT_UNIQUE'}
    $baseSet=$link[0].FoundSET
    if((Get-FileHash -LiteralPath $baseSet).Hash -ne $link[0].SetSHA256){throw 'FROZEN_SET_HASH_CHANGED'}
    foreach($line in Get-Content -LiteralPath $baseSet){if($line -match '^(Inp\w+)=(.*)$'){$parameters[$Matches[1]]=$Matches[2].Split('||')[0]}}
    $overrides=@{InpMoneyManagementMode='1';InpUseFixedLot='false';InpMaxAccountOpenRiskPct='3';InpResearchSingleRiskPct='1';InpResearchTotalRiskPct='3';InpResearchRoundTripFeePerLotUSD='7';InpCapitalLadderMode='0';InpSmallAccountProfile='0';InpForceBrokerMinimumLot='false';InpEnableConfidence100LotBoost='false';InpScalpUseBreakEven='false';InpRequireHedging='true';InpShowPanel='false';InpDrawZones='false';InpEnableChartSwitches='false';InpAuditRunLabel=$run;InpSignalFunnelFileName=$run+'_SIGNAL_FUNNEL.csv';InpTradeReviewFileName=$run+'_TRADE_REVIEW.csv';InpSignalAuditFileName=$run+'_SIGNAL_AUDIT.csv'}
    foreach($key in $overrides.Keys){$parameters[$key]=$overrides[$key]}
}
$set=Join-Path $out ($run+'.set')
[IO.File]::WriteAllLines($set,@($parameters.GetEnumerator() | ForEach-Object {"$($_.Key)=$($_.Value)"}),[Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath $set -Destination (Join-Path $terminalRoot ('MQL5\Profiles\Tester\'+$run+'.set'))
$period=if($Lane -in @('Intraday','Swing')){'M30'}else{'M5'}
$end=if($Lane -eq 'UnitTests'){'2026.01.06'}else{'2026.08.26'}
$ini=@('[Experts]','AllowLiveTrading=0','AllowDllImport=0','Enabled=0','[StartUp]','Expert=','Script=','[Tester]',"Expert=$expertName","ExpertParameters=$run.set",'Symbol=GOLD',"Period=$period",'Model=4',"ExecutionMode=$DelayMs",'Optimization=0','FromDate=2026.01.05',"ToDate=$end",'ForwardMode=0',"Deposit=$Capital",'Currency=USD','Leverage=100',"Report=$run.htm",'ReplaceReport=0','ShutdownTerminal=1','Visual=0','UseLocal=1','UseRemote=0','UseCloud=0')
$config=Join-Path $out ($run+'.ini')
[IO.File]::WriteAllLines($config,$ini,[Text.UTF8Encoding]::new($false))
$record=[ordered]@{Stage='RUNNING';Run=$run;Lane=$Lane;Source=$Source;SourceSHA256=$sourceHash;EX5SHA256=$binaryHash;SETSHA256=(Get-FileHash -LiteralPath $set).Hash;ConfigSHA256=(Get-FileHash -LiteralPath $config).Hash;BaseSet=$baseSet;Capital=$Capital;Leverage=100;DelayMs=$DelayMs;Model=4;Broker='FxPro';Symbol='GOLD';Period=$period;FromDate='2026.01.05';ToDate=$end;OOS='ALREADY_VIEWED_NOT_UNTOUCHED';Started=(Get-Date).ToString('o');Output=$out;Terminal=$terminal}
$record['TerminalSHA256']=(Get-FileHash -LiteralPath $terminal).Hash
$record['TerminalVersion']=(Get-Item -LiteralPath $terminal).VersionInfo.FileVersion
$record['CompileEvidence']=$proof
Copy-Item -LiteralPath $binary -Destination (Join-Path $out $expertName)
$before=@{}
$logFiles=@(Get-ChildItem -LiteralPath (Join-Path $terminalRoot 'Tester') -Directory | ForEach-Object {Get-ChildItem -Path (Join-Path $_.FullName 'logs\*.log') -File -ErrorAction SilentlyContinue})
foreach($file in $logFiles){$before[$file.FullName]=$file.Length}
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $out 'RUN.json') -Encoding utf8
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $root 'RUN_CHECKPOINT.json') -Encoding utf8
$process=Start-Process -FilePath $terminal -ArgumentList '/portable',('/config:"'+$config+'"') -WindowStyle Hidden -PassThru
$record['PID']=$process.Id
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $root 'RUN_CHECKPOINT.json') -Encoding utf8
if(-not $process.WaitForExit($TimeoutSeconds*1000)){throw "TEST_TIMEOUT_PID_$($process.Id); do not start another run"}
$handoffDeadline=(Get-Date).AddSeconds($TimeoutSeconds)
do {
    $children=@(Get-CimInstance Win32_Process -Filter "Name='terminal64.exe'" | Where-Object {$_.CommandLine -like ('*'+$run+'*')})
    if($children.Count -eq 0){break}
    $record['HandoffPIDs']=@($children.ProcessId)
    $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'RUN_CHECKPOINT.json') -Encoding utf8
    Start-Sleep -Seconds 2
} while((Get-Date) -lt $handoffDeadline)
if($children.Count){throw 'STARTUP_HANDOFF_TIMEOUT; inspect recorded processes before retry'}
$record['ExitCode']=$process.ExitCode
$record['Ended']=(Get-Date).ToString('o')
$record['TerminalEndSHA256']=(Get-FileHash -LiteralPath $terminal).Hash
$report=Join-Path $terminalRoot ($run+'.htm')
$record.Stage='REPORT_MISSING'
if(Test-Path -LiteralPath $report){
    Get-ChildItem -LiteralPath $terminalRoot -Filter ($run+'*') -File | Copy-Item -Destination $out
    $record['ReportSHA256']=(Get-FileHash -LiteralPath $report).Hash
    $record.Stage='REPORT_CREATED_PENDING_AUDIT'
}
$common=Join-Path $env:APPDATA 'MetaQuotes\Terminal\Common\Files'
Get-ChildItem -LiteralPath $common -Filter ($run+'*') -File | Copy-Item -Destination $out
$logFiles=@(Get-ChildItem -LiteralPath (Join-Path $terminalRoot 'Tester') -Directory | ForEach-Object {Get-ChildItem -Path (Join-Path $_.FullName 'logs\*.log') -File -ErrorAction SilentlyContinue})
foreach($file in $logFiles){
    $offset=if($before.ContainsKey($file.FullName)){$before[$file.FullName]}else{0}
    if($file.Length -le $offset){continue}
    $stream=[IO.File]::Open($file.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try {
        $stream.Seek($offset,[IO.SeekOrigin]::Begin) | Out-Null
        $reader=[IO.StreamReader]::new($stream,[Text.Encoding]::Unicode,$false)
        $text=$reader.ReadToEnd()
        $name=(Split-Path (Split-Path $file.DirectoryName -Parent) -Leaf)+'_'+$file.Name+'.txt'
        [IO.File]::WriteAllText((Join-Path $out $name),$text,[Text.UTF8Encoding]::new($false))
    } finally {$stream.Dispose()}
}
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $out 'RUN.json') -Encoding utf8
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $root 'RUN_CHECKPOINT.json') -Encoding utf8
Write-Output ($record | ConvertTo-Json -Depth 12 -Compress)
if($record.Stage -eq 'REPORT_MISSING'){throw 'REPORT_MISSING'}
