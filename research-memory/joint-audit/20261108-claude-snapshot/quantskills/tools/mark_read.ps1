# Record that Claude has read the given packs in full (append to coverage/coverage.csv) and update progress.
param([string[]]$Packs, [string]$Plan = 'plan_main.csv', [string]$Method = 'FULL_READ')
$ErrorActionPreference = 'Stop'
$T = 'C:\Users\A\Documents\Codex\outputs\quantskills-learning-20261022\claude-full-review'
$rows = Import-Csv -Encoding UTF8 (Join-Path $T $Plan)
New-Item -ItemType Directory -Force (Join-Path $T 'coverage') | Out-Null
$log = Join-Path $T 'coverage\coverage.csv'
$now = (Get-Date).ToString('s')
$out = New-Object System.Collections.ArrayList
foreach ($p in $Packs) {
  $pn = if ($p -like '*.txt') { $p } else { "$p.txt" }
  $sel = @($rows | Where-Object { $_.pack -eq $pn })
  if ($sel.Count -eq 0) { throw "pack $pn not in plan" }
  foreach ($e in $sel) { [void]$out.Add([pscustomobject]@{ pack=$pn; method=$Method; seq=$e.seq; asset_id=$e.asset_id; repo=$e.repo; relative=$e.relative; sha256=$e.sha256; bytes=$e.bytes; commit=$e.commit; part=$e.part; parts=$e.parts; reuse_of=''; at=$now }) }
}
if (Test-Path $log) { $out | Export-Csv -NoTypeInformation -Encoding UTF8 -Append $log } else { $out | Export-Csv -NoTypeInformation -Encoding UTF8 $log }
[ordered]@{ plan=$Plan; last_pack=$Packs[-1]; updated=$now } | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $T ('progress_' + [IO.Path]::GetFileNameWithoutExtension($Plan) + '.json'))
"recorded $($out.Count) rows through $($Packs[-1])"
