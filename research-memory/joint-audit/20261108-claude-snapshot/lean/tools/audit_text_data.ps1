# Tier-2 DATA_AUDIT for UNREAD text data files (.csv/.json/.txt and extension-less) under a path prefix.
# Reads every line, read-only, nothing executed. CSV-like: rows, column-count distribution, empty-field count,
# numeric-field ratio, first-column monotonic violations. JSON: parse success and top-level shape.
param([string]$Root, [string]$Inventory, [string]$Prefix, [string]$OutCsv, [string]$Batch = 'L-DATA3', [string[]]$Exts = @())
$ErrorActionPreference = 'Stop'
$inv = Import-Csv -Encoding UTF8 $Inventory
$ci = [Globalization.CultureInfo]::InvariantCulture
$out = New-Object System.Collections.ArrayList
foreach ($r in $inv) {
  if ($r.status -ne 'UNREAD' -or -not $r.relative.StartsWith($Prefix)) { continue }
  if ($r.class -ne 'DATA' -and $r.class -ne 'TEXT') { continue }
  if ($Exts.Count -gt 0 -and $Exts -notcontains $r.ext) { continue }
  if ($Exts.Count -eq 0 -and @('.md','.txt','.yaml','.yml','.toml','.mdc') -contains $r.ext) { continue }
  $p = Join-Path $Root $r.relative
  $note = ''
  try {
    if ($r.ext -eq '.jsonl') {
      $lines = 0; $okLines = 0
      foreach ($line in [IO.File]::ReadLines($p)) { if ($line.Trim() -eq '') { continue }; $lines++; try { $null = $line | ConvertFrom-Json; $okLines++ } catch {} }
      $note = "jsonl lines=$lines; parsed=$okLines"
      [void]$out.Add([pscustomobject]@{ relative = $r.relative; kind = 'jsonl'; rows = $lines; cols = "parsed=$okLines"; empty = ''; numeric_ratio = ''; non_monotonic = ''; ok = [int]($lines -eq $okLines) })
      if ($lines -ne $okLines) { continue }
    } elseif ($r.ext -eq '.json') {
      $txt = [IO.File]::ReadAllText($p)
      $obj = $txt | ConvertFrom-Json
      $shape = if ($obj -is [Array]) { "array[$($obj.Count)]" } else { "object{" + (@($obj.PSObject.Properties).Count) + "}" }
      $note = "json parsed; shape=$shape"
      [void]$out.Add([pscustomobject]@{ relative = $r.relative; kind = 'json'; rows = ''; cols = $shape; empty = ''; numeric_ratio = ''; non_monotonic = ''; ok = 1 })
    } else {
      $rows = 0; $cols = @{}; $empty = 0; $num = 0; $fields = 0; $nonMono = 0; $prev = $null
      foreach ($line in [IO.File]::ReadLines($p)) {
        if ($line.Trim() -eq '' -or $line.StartsWith('#')) { continue }
        $f = $line.Split(','); $rows++; $cols[$f.Count] = 1 + [int]$cols[$f.Count]
        foreach ($x in $f) { $fields++; if ($x.Trim() -eq '') { $empty++ } else { $d = 0.0; if ([double]::TryParse($x, [Globalization.NumberStyles]::Float, $ci, [ref]$d)) { $num++ } } }
        if ($prev -ne $null -and [string]::CompareOrdinal($f[0], $prev) -lt 0) { $nonMono++ }
        $prev = $f[0]
      }
      $ratio = if ($fields) { [math]::Round($num / $fields, 3) } else { 0 }
      $colTxt = ($cols.Keys | Sort-Object | ForEach-Object { "${_}:$($cols[$_])" }) -join ';'
      $note = "rows=$rows; cols=$colTxt; empty=$empty; numeric_ratio=$ratio; first_col_non_monotonic=$nonMono"
      [void]$out.Add([pscustomobject]@{ relative = $r.relative; kind = 'text'; rows = $rows; cols = $colTxt; empty = $empty; numeric_ratio = $ratio; non_monotonic = $nonMono; ok = 1 })
    }
    $r.status = 'DATA_AUDITED'; $r.method = 'STRUCTURAL_ALL_ROWS'; $r.batch = $Batch; $r.note = $note
  } catch {
    [void]$out.Add([pscustomobject]@{ relative = $r.relative; kind = 'error'; rows = ''; cols = $_.Exception.Message; empty = ''; numeric_ratio = ''; non_monotonic = ''; ok = 0 })
  }
}
$inv | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
$out | Export-Csv -NoTypeInformation -Encoding UTF8 $OutCsv
"audited: $(@($out | Where-Object ok -eq 1).Count); errors: $(@($out | Where-Object ok -eq 0).Count); rows: $(($out | Where-Object kind -eq 'text' | Measure-Object rows -Sum).Sum)"
"files with first-col non-monotonic>0: $(@($out | Where-Object { $_.kind -eq 'text' -and [int]$_.non_monotonic -gt 0 }).Count); with mixed column counts: $(@($out | Where-Object { $_.kind -eq 'text' -and $_.cols -match ';' }).Count)"
