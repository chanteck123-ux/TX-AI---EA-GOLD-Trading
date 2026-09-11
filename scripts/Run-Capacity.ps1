param(
    [ValidateSet('Scalping','Intraday','Swing','Combined')][string]$Lane='Scalping'
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$sourceHash='989F19C997F5B095A67727BF0C88492B3777F2CCF2682A02D954DBBE18CAE19A'
$binaryHash='BB77B5D947614A9D1796E02E2F3382945C1FCAFD5DF68EFF1FF8D387368957EB'
$runtimeHash='3DBB5F966441FC043D49BC637A5931686BE847E77DC89E295C944EDA6B9A08C7'
$inventory=Get-Content -LiteralPath (Join-Path $root 'reports/R_C00_BASELINE_INVENTORY.json') -Raw | ConvertFrom-Json
if($inventory.Status -ne 'BASELINE_AUDITED_NOT_CHAMPION' -or $inventory.Baseline.Count -ne 4){throw 'FOUR_LANE_BASELINE_REQUIRED'}
if($inventory.SourceSHA256 -ne $sourceHash -or $inventory.EX5SHA256 -ne $binaryHash){throw 'BASELINE_REVISION_CHANGED'}
$state=[ordered]@{Stage='RUNNING';Lane=$Lane;SourceSHA256=$sourceHash;EX5SHA256=$binaryHash;Completed=@();NextCapital=$null}
foreach($capital in @(1000,100,200,300,750,2000,5000,10000)){
    if((Get-FileHash -LiteralPath (Join-Path $root 'src/GSM_FxPro_R_C00.mq5')).Hash -ne $sourceHash){throw 'SOURCE_CHANGED_DURING_MATRIX'}
    $runs=@(Get-ChildItem -LiteralPath (Join-Path $root 'reports/runs') -Filter RUN.json -Recurse -File | ForEach-Object {Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json})
    $match=@($runs | Where-Object {
        $_.Stage -eq 'REPORT_CREATED_PENDING_AUDIT' -and $_.Lane -eq $Lane -and $_.Capital -eq $capital -and
        $_.SourceSHA256 -eq $sourceHash -and $_.EX5SHA256 -eq $binaryHash -and $_.TerminalSHA256 -eq $runtimeHash -and
        $_.Model -eq 4 -and $_.DelayMs -eq 0 -and $_.Leverage -eq 100 -and $_.FromDate -eq '2026.01.05' -and $_.ToDate -eq '2026.08.26'
    } | Sort-Object Run)
    $state.NextCapital=$capital
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'CAPACITY_CHECKPOINT.json') -Encoding utf8
    if($match.Count){
        $result=$match[-1]
        $report=Join-Path $result.Output ($result.Run+'.htm')
        if((Get-FileHash -LiteralPath $report).Hash -ne $result.ReportSHA256){throw 'EXISTING_REPORT_HASH_MISMATCH'}
        Write-Output ('REUSE_VERIFIED_RUN|'+$result.Run)
    }else{
        Write-Output ('START_CAPACITY|'+$Lane+'|USD'+$capital)
        $result=(& (Join-Path $PSScriptRoot 'Run-Research.ps1') -Lane $Lane -Capital $capital) | ConvertFrom-Json
        if($result.Stage -ne 'REPORT_CREATED_PENDING_AUDIT'){throw 'CAPACITY_REPORT_MISSING'}
        Write-Output ('REPORT_CREATED|'+$result.Run)
    }
    $state.Completed+=@{Capital=$capital;Run=$result.Run;ReportSHA256=$result.ReportSHA256}
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'CAPACITY_CHECKPOINT.json') -Encoding utf8
}
$state.Stage='REPORTS_CREATED_PENDING_AUDIT'
$state.NextCapital=$null
$state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'CAPACITY_CHECKPOINT.json') -Encoding utf8
Write-Output ('CAPACITY_COMPLETE_PENDING_AUDIT|'+$Lane)
