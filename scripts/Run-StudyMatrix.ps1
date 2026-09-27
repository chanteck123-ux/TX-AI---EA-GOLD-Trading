param([Parameter(Mandatory)][string]$Definition)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$matrix=Get-Content -LiteralPath (Join-Path $root $Definition) -Raw | ConvertFrom-Json
$source='src/GSM_FxPro_RESEARCH.mq5'
$sourceHash=(Get-FileHash -LiteralPath (Join-Path $root $source)).Hash
$binaryHash=(Get-FileHash -LiteralPath (Join-Path $root 'src/GSM_FxPro_RESEARCH.ex5')).Hash
if($matrix.SourceSHA256 -ne $sourceHash -or $matrix.EX5SHA256 -ne $binaryHash){throw 'MATRIX_FREEZE_MISMATCH'}
foreach($case in $matrix.Cases){
    $overrides=@{}
    foreach($p in $case.Inputs.PSObject.Properties){$overrides[$p.Name]="$($p.Value)"}
    $existing=@(Get-ChildItem -Path (Join-Path $root 'reports/runs/*/RUN.json') -File | ForEach-Object {
        Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
    } | Where-Object {
        $_.CandidateId -eq $case.ID -and $_.Lane -eq $case.Lane -and $_.Capital -eq $case.Capital -and
        $_.DelayMs -eq $case.Delay -and $_.Leverage -eq 100 -and $_.Model -eq 4 -and
        $_.SourceSHA256 -eq $sourceHash -and $_.EX5SHA256 -eq $binaryHash -and
        $_.FromDate -eq '2026.01.05' -and $_.ToDate -eq '2026.08.26'
    })
    $matching=@($existing | Where-Object {
        $item=$_
        $props=@($item.InputOverrides.PSObject.Properties)
        $same=($props.Count -eq $overrides.Count)
        foreach($p in $props){if(-not $overrides.ContainsKey($p.Name) -or $overrides[$p.Name] -ne "$($p.Value)"){$same=$false}}
        $same
    })
    if($matching.Count -gt 1){throw 'DUPLICATE_MATCHING_RUNS_REQUIRE_RECONCILIATION'}
    if($matching.Count -eq 1){
        $done=$matching[0]
        if($done.Stage -ne 'REPORT_CREATED_PENDING_AUDIT'){throw ('INCOMPLETE_RUN_RECONCILE_'+$done.Run)}
        foreach($pair in @(@('.htm','ReportSHA256'),@('.set','SETSHA256'),@('.ini','ConfigSHA256'))){
            if((Get-FileHash -LiteralPath (Join-Path $done.Output ($done.Run+$pair[0]))).Hash -ne $done.($pair[1])){throw 'EXISTING_EVIDENCE_HASH_MISMATCH'}
        }
        Write-Output ('MATRIX_SKIP_VERIFIED_EXISTING|'+$done.Run)
        continue
    }
    Write-Output ('MATRIX_START|'+$case.ID+'|'+$case.Lane+'|USD'+$case.Capital+'|Delay'+$case.Delay)
    & (Join-Path $PSScriptRoot 'Run-Candidate.ps1') -Lane $case.Lane -Source $source -CandidateId $case.ID -Capital $case.Capital -DelayMs $case.Delay -InputOverrides $overrides | Out-Null
    & (Join-Path $PSScriptRoot 'Save-Checkpoint.ps1') -Stage 'STUDY_MATRIX_IN_PROGRESS' -Source $source -Candidate $case.ID -Next ('Resume verified matrix '+$Definition+'; do not duplicate completed runs.')
    Write-Output ('MATRIX_COMPLETE|'+$case.ID+'|'+$case.Lane+'|USD'+$case.Capital+'|Delay'+$case.Delay)
}
