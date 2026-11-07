# Record a check method for every UNREAD .zip in the LEAN inventory: open the central directory read-only
# (no extraction, nothing executed), record entry count, entry names (first 3), total uncompressed size, and
# whether the archive opens. Status stays UNREAD (BINARY_METHOD_ONLY): listing a zip is not reading its contents.
param([string]$Root, [string]$Inventory, [string]$OutCsv, [string]$Batch = 'L-ZIP')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$inv = Import-Csv -Encoding UTF8 $Inventory
$rows = New-Object System.Collections.ArrayList
$ok = 0; $bad = 0
foreach ($r in $inv) {
  if ($r.status -ne 'UNREAD' -or $r.ext -ne '.zip') { continue }
  $p = Join-Path $Root $r.relative
  try {
    $z = [System.IO.Compression.ZipFile]::OpenRead($p)
    try {
      $names = @($z.Entries | ForEach-Object { $_.FullName })
      $unc = ($z.Entries | Measure-Object Length -Sum).Sum
      $suspicious = @($names | Where-Object { $_ -match '\.\.[\\/]' -or $_ -match '^[\\/]' -or $_ -match '\.(exe|dll|ps1|bat|cmd|sh|py|cs)$' })
      $note = "entries=$($names.Count); uncompressed=$unc; first=" + (($names | Select-Object -First 3) -join '|') + "; suspicious=$($suspicious.Count)"
      [void]$rows.Add([pscustomobject]@{ relative = $r.relative; bytes = $r.bytes; entries = $names.Count; uncompressed = $unc; suspicious = $suspicious.Count; first = ($names | Select-Object -First 3) -join '|' })
      $ok++
    } finally { $z.Dispose() }
  } catch { $note = "OPEN_FAILED: $($_.Exception.Message)"; $bad++ }
  $r.method = 'BINARY_METHOD_ONLY'; $r.batch = $Batch; $r.note = "zip central directory listed, not extracted; $note"
}
$inv | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $OutCsv
"zips listed: $ok; open failed: $bad; with suspicious entries: $(@($rows | Where-Object { $_.suspicious -gt 0 }).Count)"
"total entries: $(($rows | Measure-Object entries -Sum).Sum); total uncompressed MB: $([math]::Round((($rows | Measure-Object uncompressed -Sum).Sum)/1MB,1))"
