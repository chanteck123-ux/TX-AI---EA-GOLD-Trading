# S013: audit factor-library result.json (DATA_AUDITED) and agents/openai.yaml (TEMPLATE_DIFF) for both libraries.
# Read-only for sources. Writes a CSV + summary; marks inventory rows.
param([string]$Repos, [string]$FactorCsv, [string]$Inventory, [string]$OutCsv, [string]$OutSummary)
$ErrorActionPreference = 'Stop'
$ref = @{}; foreach ($r in (Import-Csv -Encoding UTF8 $FactorCsv)) { $ref["$($r.repo)|$($r.dir)"] = $r }
$rows = New-Object System.Collections.ArrayList
$yamlHash = @{}
$issues = New-Object System.Collections.ArrayList
foreach ($lib in 'skill-quant-factor-directional-alpha','skill-quant-factor-risk-pattern-alpha') {
  $idx = @{}; foreach ($e in (Get-Content -Raw -Encoding UTF8 (Join-Path $Repos "$lib\factor_index.json") | ConvertFrom-Json)) { $idx[$e.factor_id] = $e }
  foreach ($d in (Get-ChildItem -LiteralPath (Join-Path $Repos "$lib\factors") -Directory)) {
    $j = Get-Content -Raw -Encoding UTF8 (Join-Path $d.FullName 'validation_real\result.json') | ConvertFrom-Json
    $k = "$lib|$($d.Name)"; $f = $ref[$k]
    $ratio = if ($j.ic_std_5d -and $j.ic_mean_5d) { $j.icir_5d / ($j.ic_mean_5d / $j.ic_std_5d) } else { [double]::NaN }
    $m = @()
    if (-not $f) { $m += 'no_readme_row' } else {
      if ([math]::Abs([double]$f.ic - $j.ic_mean_5d) -gt 5e-7) { $m += 'ic' }
      if ([math]::Abs([double]$f.icir - $j.icir_5d) -gt 5e-7) { $m += 'icir' }
      if ([int]$f.icobs -ne $j.ic_observations) { $m += 'icobs' }
      if ($f.status -ne $j.status) { $m += 'status' }
    }
    $e = $idx[$j.factor_id]
    if (-not $e -or $e.base -ne $j.base -or $e.transform -ne $j.transform -or (($e.params | ConvertTo-Json -Compress) -ne ($j.params | ConvertTo-Json -Compress))) { $m += 'index_spec' }
    if (-not $d.Name.StartsWith("$($j.factor_id)-")) { $m += 'dir_id' }
    if ($m.Count) { [void]$issues.Add("$k : $($m -join ',')") }
    [void]$rows.Add([pscustomobject]@{ lib=$lib; dir=$d.Name; id=$j.factor_id; base=$j.base; transform=$j.transform; window=$j.params.window;
      ic=$j.ic_mean_5d; icstd=$j.ic_std_5d; icir=$j.icir_5d; icir_over_raw=$ratio; icobs=$j.ic_observations; ls=$j.long_short_mean_5d;
      ls_obs=$j.long_short_observations; cn=$j.markets.cn; us=$j.markets.us; no_future_check=$j.no_future_check; status=$j.status; mismatch=($m -join ',') })
    $y = Get-Content -Raw -Encoding UTF8 (Join-Path $d.FullName 'agents\openai.yaml')
    $norm = ($y -split "`r?`n" | Where-Object { $_ -notmatch '^\s*(display_name|default_prompt|factor_id|category):' }) -join "`n"
    $h = [BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($norm))).Replace('-','').Substring(0,12)
    $yamlHash["$lib|$h"] = 1 + [int]$yamlHash["$lib|$h"]
  }
}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $OutCsv
$ok = $rows | Where-Object { -not $_.mismatch }
$r2 = $rows | Where-Object { -not [double]::IsNaN($_.icir_over_raw) } | Measure-Object icir_over_raw -Minimum -Maximum
$neg = @($rows | Where-Object { $_.ic -lt 0 }).Count
$lsneg = @($rows | Where-Object { $_.ls -lt 0 }).Count
$tstat = $rows | ForEach-Object { if ($_.icstd -gt 0) { $_.ic / ($_.icstd / [math]::Sqrt($_.icobs)) } }
$sig = @($tstat | Where-Object { [math]::Abs($_) -ge 1.96 }).Count
$sum = @(
  "result.json audited: $($rows.Count); consistent with README-derived factors_584.csv and factor_index.json: $(@($ok).Count)",
  "status values: " + (($rows | Group-Object status | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', '),
  "no_future_check values: " + (($rows | Group-Object no_future_check | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', '),
  "icir_5d / (ic_mean/ic_std): min $($r2.Minimum.ToString('0.000')) max $($r2.Maximum.ToString('0.000')) (sqrt(252/5)=7.099)",
  "ic_mean < 0: $neg; long_short_mean < 0: $lsneg",
  "|naive t| >= 1.96 (t = ic/(icstd/sqrt(icobs)); overlapping 5d IC so t is overstated): $sig of $($rows.Count)",
  "markets: " + (($rows | Group-Object { "cn=$($_.cn),us=$($_.us)" } | ForEach-Object { "$($_.Name) x$($_.Count)" }) -join '; '),
  "openai.yaml normalized hash groups: " + (($yamlHash.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '),
  '', '## mismatches') + $issues
$sum | Set-Content -Encoding UTF8 $OutSummary
$sum
