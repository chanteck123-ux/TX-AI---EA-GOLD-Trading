# Build full-text reading packs for Claude's QuantSkills full review.
# Reads only documentation files listed in the shared manifest; executes nothing from the repos.
param(
  [string]$Manifest = 'C:\Users\A\Documents\Codex\outputs\quantskills-learning-20261022\full-review\document-manifest.json',
  [string]$OutDir,                     # scratch dir for pack text files
  [string]$PlanPath,                   # plan json (pack -> entries)
  [int]$PackBytes = 52000
)
$ErrorActionPreference = 'Stop'
$factorRepos = @('skill-quant-factor-directional-alpha','skill-quant-factor-risk-pattern-alpha')
$m = Get-Content -Raw -Encoding UTF8 $Manifest | ConvertFrom-Json
New-Item -ItemType Directory -Force $OutDir | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)

# Order: assets by id, then non-asset org repos; factor-library per-factor files handled separately.
$isFactorChild = { param($e) ($factorRepos -contains $e.repo) -and ($e.relative -like 'factors\*') }
$main = $m | Where-Object { -not (& $isFactorChild $_) } |
  Sort-Object @{e={ if ($_.asset_id -eq $null) { 9999 } else { [int]$_.asset_id } }}, repo, relative

$seen = @{}        # sha -> first file key
$plan = New-Object System.Collections.ArrayList
$packNo = 0; $sb = New-Object System.Text.StringBuilder; $entries = New-Object System.Collections.ArrayList
function Flush-Pack {
  if ($script:entries.Count -eq 0) { return }
  $script:packNo++
  $name = 'P{0:D4}.txt' -f $script:packNo
  [IO.File]::WriteAllText((Join-Path $OutDir $name), $script:sb.ToString(), $script:utf8)
  foreach ($x in $script:entries) { [void]$script:plan.Add([pscustomobject]@{ pack=$name; kind="FULL"; seq=$x.seq; asset_id=$x.asset_id; repo=$x.repo; relative=$x.relative; sha256=$x.sha256; bytes=$x.bytes; commit=$x.commit; part=$x.part; parts=$x.parts; reuse_of="" }) }
  $script:sb = New-Object System.Text.StringBuilder; $script:entries = New-Object System.Collections.ArrayList
}
$seq = 0
foreach ($e in $main) {
  $seq++
  $key = "$($e.repo)/$($e.relative)"
  if ($seen.ContainsKey($e.sha256)) {
    [void]$plan.Add([pscustomobject]@{ pack="REUSE"; kind="HASH_REUSE"; seq=$seq; asset_id=$e.asset_id; repo=$e.repo; relative=$e.relative; sha256=$e.sha256; bytes=$e.bytes; commit=$e.commit; part=1; parts=1; reuse_of=$seen[$e.sha256] })
    continue
  }
  $seen[$e.sha256] = $key
  $text = [IO.File]::ReadAllText($e.path, [Text.Encoding]::UTF8)
  $lines = $text -split "`r?`n"
  # split long files into parts of <= PackBytes
  $parts = New-Object System.Collections.ArrayList; $cur = New-Object System.Text.StringBuilder
  foreach ($ln in $lines) {
    if ($cur.Length -gt 0 -and ($utf8.GetByteCount($cur.ToString()) + $utf8.GetByteCount($ln)) -gt ($PackBytes - 400)) { [void]$parts.Add($cur.ToString()); $cur = New-Object System.Text.StringBuilder }
    [void]$cur.AppendLine($ln)
  }
  [void]$parts.Add($cur.ToString())
  for ($i = 0; $i -lt $parts.Count; $i++) {
    $body = $parts[$i]
    if ($sb.Length -gt 0 -and ($utf8.GetByteCount($sb.ToString()) + $utf8.GetByteCount($body)) -gt $PackBytes) { Flush-Pack }
    $hdr = "#### FILE $seq | A$($e.asset_id) | $($e.repo) | $($e.relative) | sha:$($e.sha256.Substring(0,12)) | $($e.bytes)B | part $($i+1)/$($parts.Count)"
    [void]$sb.AppendLine($hdr); [void]$sb.Append($body); [void]$sb.AppendLine("#### END FILE $seq part $($i+1)")
    [void]$entries.Add([pscustomobject]@{ seq=$seq; asset_id=$e.asset_id; repo=$e.repo; relative=$e.relative; sha256=$e.sha256; bytes=$e.bytes; commit=$e.commit; part=($i+1); parts=$parts.Count })
  }
}
Flush-Pack
$plan | Export-Csv -NoTypeInformation -Encoding UTF8 $PlanPath
"packs=$packNo rows=$($plan.Count) reuse=$(@($plan | Where-Object { $_.kind -eq "HASH_REUSE" }).Count)"
