param()
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$workspace=Split-Path (Split-Path $root -Parent) -Parent
$snapshot=Join-Path $root 'ENVIRONMENT_CHECKPOINT.json'
$previous=if(Test-Path -LiteralPath $snapshot){Get-Content -LiteralPath $snapshot -Raw | ConvertFrom-Json}else{$null}
$terminalRoots=@(
    (Join-Path $workspace 'work\backtest-v220\fxpro-terminal'),
    (Join-Path $workspace 'work\side-scalping-best-v290\fxpro-terminal-side')
)
$records=@()
foreach($directory in $terminalRoots){
    $path=Join-Path $directory 'terminal64.exe'
    if(-not (Test-Path -LiteralPath $path)){throw ('TERMINAL_NOT_FOUND '+$path)}
    $file=Get-Item -LiteralPath $path
    $version=[version]$file.VersionInfo.FileVersion
    $journal=Get-ChildItem -LiteralPath (Join-Path $directory 'logs') -Filter '*.log' -File |
        Where-Object {$_.Name -match '^\d{8}\.log$'} |
        Sort-Object Name -Descending | Select-Object -First 1
    $updateFolder=$null
    if($journal){
        $tail=(Get-Content -LiteralPath $journal.FullName -Tail 2000) -join "`n"
        $matches=[regex]::Matches($tail,'LiveUpdate\s+start "([^"\r\n]+\\liveupdate\\terminal64\.exe)"')
        if($matches.Count){
            $candidate=Split-Path $matches[$matches.Count-1].Groups[1].Value -Parent
            $allowed=[IO.Path]::GetFullPath((Join-Path $env:APPDATA 'MetaQuotes\Terminal'))+'\'
            if(-not [IO.Path]::GetFullPath($candidate).StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)){
                throw 'UPDATE_PATH_OUTSIDE_METAQUOTES_DATA'
            }
            $updateFolder=$candidate
        }
    }
    $payloads=@()
    if($updateFolder -and (Test-Path -LiteralPath $updateFolder)){
        $payloads=@(Get-ChildItem -LiteralPath $updateFolder -File |
            Where-Object {$_.Name -match '^mt5clw64\.(\d+)$'} |
            ForEach-Object {[ordered]@{Name=$_.Name;Build=[int]($_.Name.Split('.')[-1]);Length=$_.Length;Modified=$_.LastWriteTimeUtc.ToString('o')}})
    }
    $target=($payloads | ForEach-Object {$_.Build} | Measure-Object -Maximum).Maximum
    if($payloads.Count -and $null -eq $target){throw 'UPDATE_BUILD_PARSE_FAILED'}
    $records += [ordered]@{
        Terminal=$path;Version=$version.ToString();SHA256=(Get-FileHash -LiteralPath $path).Hash
        PayloadBuild=$target;UpdatePayloads=$payloads
        UpdatePending=($null -ne $target -and $target -gt $version.Revision)
    }
}
$processes=@(Get-CimInstance Win32_Process -Filter "Name='terminal64.exe' OR Name='metaeditor64.exe'" |
    Select-Object ProcessId,Name,ExecutablePath)
$services=@(Get-CimInstance Win32_Service -Filter "Name LIKE 'MetaTester-%'" |
    Sort-Object Name | Select-Object Name,State,ProcessId)
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin=([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$state=[ordered]@{Terminals=$records;TerminalOrEditorProcesses=$processes;MetaTesterServices=$services;Administrator=$isAdmin}
$bytes=[Text.Encoding]::UTF8.GetBytes(($state | ConvertTo-Json -Depth 8 -Compress))
$fingerprint=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
$collectorHash=(Get-FileHash -LiteralPath $PSCommandPath).Hash
$status=if($processes.Count){'PROCESS_RECONCILIATION_REQUIRED'}elseif(@($records | Where-Object {$_.UpdatePending}).Count){'UPDATE_STILL_PENDING_NO_LIVE_TEST'}else{'NO_UPDATE_PAYLOAD_DETECTED_REVIEW_REQUIRED'}
$record=[ordered]@{
    Observed=(Get-Date).ToString('o');Status=$status;Fingerprint=$fingerprint
    CollectorSHA256=$collectorHash
    ChangedSincePrior=if($previous -and $previous.CollectorSHA256 -eq $collectorHash){$previous.Fingerprint -ne $fingerprint}else{$null}
    State=$state;ReadOnly=$true;ServicesModified=$false;NewTestLaunched=$false
}
$record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $snapshot -Encoding utf8
$record | ConvertTo-Json -Depth 10
