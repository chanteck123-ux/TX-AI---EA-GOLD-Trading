param([string]$Source='src\GSM_FxPro_R_C00.mq5')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$workspace=Split-Path (Split-Path $root -Parent) -Parent
$editor=Join-Path $workspace 'work\backtest-v220\fxpro-terminal\MetaEditor64.exe'
$runtimeCheckpoint=Join-Path $root 'RUNTIME_CHECKPOINT.json'
if(Test-Path -LiteralPath $runtimeCheckpoint){
    $runtime=Get-Content -LiteralPath $runtimeCheckpoint -Raw | ConvertFrom-Json
    $editor=Join-Path $runtime.TerminalRoot 'MetaEditor64.exe'
    if((Get-FileHash -LiteralPath $editor).Hash -ne $runtime.BinaryHashes.'MetaEditor64.exe'){throw 'EDITOR_RUNTIME_CHANGED'}
}
$sdk=Join-Path $workspace 'work\backtest-v220\tradona-terminal\MQL5'
$sourcePath=Join-Path $root $Source
$output=Join-Path $root ('reports\compile\'+[IO.Path]::GetFileNameWithoutExtension($Source)+'_'+(Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Path $output | Out-Null
$log=Join-Path $output 'MetaEditor.log'
$binary=[IO.Path]::ChangeExtension($sourcePath,'.ex5')
$record=[ordered]@{Stage='COMPILE_RUNNING';Source=$Source;SourceSHA256=(Get-FileHash -LiteralPath $sourcePath).Hash;SDKTradeSHA256=(Get-FileHash -LiteralPath (Join-Path $sdk 'Include\Trade\Trade.mqh')).Hash;EditorSHA256=(Get-FileHash -LiteralPath $editor).Hash;Started=(Get-Date).ToString('o')}
$record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'COMPILE_CHECKPOINT.json') -Encoding utf8
$process=Start-Process -FilePath $editor -ArgumentList ('/compile:"'+$sourcePath+'"'),('/inc:"'+$sdk+'"'),('/log:"'+$log+'"') -WindowStyle Hidden -PassThru
if(-not $process.WaitForExit(120000)) { throw "Compile timeout; inspect PID $($process.Id) before retrying" }
if(-not (Test-Path -LiteralPath $log)){throw 'COMPILE_LOG_MISSING'}
$content=Get-Content -LiteralPath $log -Raw
$dependencies=[ordered]@{}
foreach($match in [regex]::Matches($content,'(?m): information: including ([^\r\n]+)')){
    $path=$match.Groups[1].Value.Trim()
    $dependencies[$path]=(Get-FileHash -LiteralPath $path).Hash
    if($path.StartsWith((Join-Path $root 'src'),[StringComparison]::OrdinalIgnoreCase)){
        Copy-Item -LiteralPath $path -Destination (Join-Path $output ([IO.Path]::GetFileName($path)))
    }
}
$record['Dependencies']=$dependencies
$record['Result']=$content.Trim().Split("`n")[-1]
$record['LogSHA256']=(Get-FileHash -LiteralPath $log).Hash
$record.Stage='COMPILE_FAIL'
if($content -match 'Result: 0 errors, 0 warnings' -and (Test-Path -LiteralPath $binary) -and (Get-Item -LiteralPath $binary).LastWriteTime -ge [datetime]$record.Started){
    $record.Stage='COMPILE_PASS'
    $record['EX5SHA256']=(Get-FileHash -LiteralPath $binary).Hash
    Copy-Item -LiteralPath $binary -Destination (Join-Path $output ([IO.Path]::GetFileName($binary)))
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $output ([IO.Path]::GetFileName($sourcePath)))
    $record['BinaryArchive']=Join-Path $output ([IO.Path]::GetFileName($binary))
}
$record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'COMPILE.json') -Encoding utf8
$record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'COMPILE_CHECKPOINT.json') -Encoding utf8
Write-Output $content
Write-Output ($record | ConvertTo-Json -Compress)
if($record.Stage -ne 'COMPILE_PASS'){throw 'Compile not passed; no tester launch allowed'}
