$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$source='src\GSM_FxPro_R_C01.mq5'
$sourceHash='CCED6620AAA43B8D30F2DC88208CBEB799F6F26EFDC14A8F6CD05873EE195F4E'
$binaryHash='F1F26A995805B9CE963FAA03627A0923B9C6B7E30C9A83D37FC2A8C639A1EFAF'
$state=[ordered]@{Stage='RUNNING';Candidate='R-C01';Completed=@();Next=$null}
$matrix=@(@{Lane='Scalping';Capital=500},@{Lane='Intraday';Capital=500},@{Lane='Swing';Capital=500},@{Lane='Combined';Capital=500},@{Lane='Scalping';Capital=1000},@{Lane='Scalping';Capital=2000})
foreach($item in $matrix){
    if((Get-FileHash -LiteralPath (Join-Path $root $source)).Hash -ne $sourceHash){throw 'SOURCE_CHANGED_DURING_MATRIX'}
    $state.Next=$item
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'FEE_CHECKPOINT.json') -Encoding utf8
    $runs=@(Get-ChildItem -LiteralPath (Join-Path $root 'reports/runs') -Filter RUN.json -Recurse -File | ForEach-Object {Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json})
    $matches=@($runs | Where-Object {
        $_.Stage -eq 'REPORT_CREATED_PENDING_AUDIT' -and $_.Lane -eq $item.Lane -and $_.Capital -eq $item.Capital -and
        $_.SourceSHA256 -eq $sourceHash -and $_.EX5SHA256 -eq $binaryHash -and $_.Broker -eq 'FxPro' -and $_.Symbol -eq 'GOLD' -and
        $_.Model -eq 4 -and $_.DelayMs -eq 0 -and $_.Leverage -eq 100 -and $_.FromDate -eq '2026.01.05' -and $_.ToDate -eq '2026.08.26'
    } | Sort-Object Run)
    if($matches.Count){
        $result=$matches[-1]
        if((Get-FileHash -LiteralPath (Join-Path $result.Output ($result.Run+'.htm'))).Hash -ne $result.ReportSHA256){throw 'EXISTING_REPORT_HASH_MISMATCH'}
        Write-Output ('REUSE_VERIFIED_RUN|'+$result.Run)
    }else{
        Write-Output ('START_FEE_VALIDATION|'+$item.Lane+'|USD'+$item.Capital)
        $result=(& (Join-Path $PSScriptRoot 'Run-Research.ps1') -Lane $item.Lane -Capital $item.Capital -Source $source) | ConvertFrom-Json
        if($result.Stage -ne 'REPORT_CREATED_PENDING_AUDIT'){throw 'FEE_VALIDATION_REPORT_MISSING'}
        Write-Output ('REPORT_CREATED|'+$result.Run)
    }
    $state.Completed+=@{Lane=$item.Lane;Capital=$item.Capital;Run=$result.Run;ReportSHA256=$result.ReportSHA256}
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'FEE_CHECKPOINT.json') -Encoding utf8
}
$state.Stage='REPORTS_CREATED_PENDING_AUDIT'
$state.Next=$null
$state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'FEE_CHECKPOINT.json') -Encoding utf8
Write-Output 'FEE_MATRIX_COMPLETE_PENDING_AUDIT'
