# Carry doc-layer coverage (coverage.csv packs + TEMPLATE_DIFF) into the per-file source inventory.
# Only fills rows still UNREAD; requires repo\relative path match AND identical SHA-256. Read-only for sources.
param([string]$Coverage, [string]$TemplateCov, [string]$Inventory, [string]$Report)
$ErrorActionPreference = 'Stop'
$inv = Import-Csv -Encoding UTF8 $Inventory
$byKey = @{}; foreach ($r in $inv) { $byKey[$r.relative.ToLowerInvariant()] = $r }
$stats = @{ applied = 0; sha_mismatch = 0; not_in_inventory = 0; already_set = 0 }
$mismatch = New-Object System.Collections.ArrayList
$work = New-Object System.Collections.ArrayList
foreach ($c in (Import-Csv -Encoding UTF8 $Coverage)) {
  $note = "pack=$($c.pack); commit=$($c.commit)"; if ($c.reuse_of) { $note += "; reuse_of=$($c.reuse_of)" }
  [void]$work.Add(@($c, $c.method, 'DOC_PACK', $note))
}
foreach ($c in (Import-Csv -Encoding UTF8 $TemplateCov)) { [void]$work.Add(@($c, 'DIFF_VERIFIED', 'TEMPLATE_DIFF', "commit=$($c.commit); see template_diff/")) }
foreach ($w in $work) {
  $row = $w[0]
  $k = ($row.repo + '\' + $row.relative).ToLowerInvariant()
  $t = $byKey[$k]
  if (-not $t) { $stats.not_in_inventory += 1; continue }
  if ($t.sha256 -ne $row.sha256) { $stats.sha_mismatch += 1; [void]$mismatch.Add("$k`t$($row.sha256)`t$($t.sha256)"); continue }
  if ($t.status -ne 'UNREAD') { $stats.already_set += 1; continue }
  $t.status = $w[1]; $t.method = $w[2]; $t.batch = 'DOC_LAYER'; $t.note = $w[3]; $stats.applied += 1
}
$inv | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
$summary = $stats.Keys | Sort-Object | ForEach-Object { "${_}: $($stats[$_])" }
$lines = @('# doc-layer -> source inventory sync', "at: $(Get-Date -Format s)") + $summary + '' + '## sha mismatches (key, coverage sha, inventory sha)' + $mismatch
$lines | Set-Content -Encoding UTF8 $Report
$summary
