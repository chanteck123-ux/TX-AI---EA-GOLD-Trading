param([string]$Stage,[string]$Next)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$workspace=Split-Path (Split-Path $root -Parent) -Parent
$source=Join-Path $root 'src\GSM_FxPro_R_C00.mq5'
$package=Join-Path $workspace 'work\baseline-audit-20260905\repository\champion\current\GSM_GOLD_3SOP_EA_V4.00_CURRENT_CHAMPION.zip'
$hash=(Get-FileHash -LiteralPath $package).Hash
if($hash -ne '43AF3C393B6C226211115A1A1DBC70C88F0F07250FA332D22C04C3ED64EB80E2'){throw 'CURRENT_CHAMPION_INTEGRITY_FAIL'}
$record=[ordered]@{Updated=(Get-Date).ToString('o');Stage=$Stage;Candidate='R-C00';Purpose='Risk-normalized research control, not Champion';Broker='FxPro';BaselinePackageSHA256=$hash;SourceSHA256=(Get-FileHash -LiteralPath $source).Hash;Branch=(git -C $root branch --show-current);Next=$Next;HeartbeatId='fxpro-ea';OOS='Historical dates already viewed; not untouched';RealTradingEnabled=$false}
$record['SourceFiles']=@(Get-ChildItem -LiteralPath (Join-Path $root 'src') -File | Where-Object {$_.Extension -in '.mq5','.mqh'} | ForEach-Object {[ordered]@{File=$_.Name;SHA256=(Get-FileHash -LiteralPath $_.FullName).Hash}})
foreach($name in 'COMPILE_CHECKPOINT.json','RUN_CHECKPOINT.json'){
    $path=Join-Path $root $name
    if(Test-Path -LiteralPath $path){$record[$name]=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json}
}
$record['ActiveTerminals']=@(Get-CimInstance Win32_Process -Filter "Name='terminal64.exe' OR Name='metaeditor64.exe'" | Select-Object ProcessId,ExecutablePath)
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $root 'CHECKPOINT.json') -Encoding utf8
Write-Output ('CHECKPOINT|'+$Stage+'|'+$Next)
