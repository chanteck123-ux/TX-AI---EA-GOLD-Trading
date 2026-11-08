# DATA_AUDIT of LEAN sample XAUUSD zips (cfd/oanda): stream-read every CSV entry (no extraction to disk, nothing executed).
# Per entry: rows, column-count set, first/last time key, time key monotonic, non-positive prices,
# bid>ask violations (quote layouts), spread stats (ask close - bid close). Read-only.
param([string]$Root, [string]$Inventory, [string]$OutCsv, [string]$Batch = 'L-XAU')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$inv = Import-Csv -Encoding UTF8 $Inventory
$ci = [Globalization.CultureInfo]::InvariantCulture
$out = New-Object System.Collections.ArrayList
foreach ($r in $inv) {
  if ($r.ext -ne '.zip' -or $r.relative -notmatch '^Data\\cfd\\oanda\\[^\\]+\\(xauusd\.zip|xauusd\\)') { continue }
  $z = [System.IO.Compression.ZipFile]::OpenRead((Join-Path $Root $r.relative))
  try {
    foreach ($e in $z.Entries) {
      $sr = New-Object IO.StreamReader($e.Open())
      $rows = 0; $cols = @{}; $first = $null; $last = $null; $nonMono = 0; $nonPos = 0; $crossed = 0
      $spMin = [double]::MaxValue; $spMax = [double]::MinValue; $spSum = 0.0; $spN = 0; $prevKey = $null
      while (($line = $sr.ReadLine()) -ne $null) {
        if ($line.Trim() -eq '') { continue }
        $f = $line.Split(','); $rows++; $cols[$f.Count] = 1 + [int]$cols[$f.Count]
        $key = $f[0]; if ($first -eq $null) { $first = $key }; $last = $key
        if ($prevKey -ne $null) {
          $a = 0.0; $b = 0.0
          if ([double]::TryParse($prevKey, [Globalization.NumberStyles]::Float, $ci, [ref]$a) -and [double]::TryParse($key, [Globalization.NumberStyles]::Float, $ci, [ref]$b)) { if ($b -le $a) { $nonMono++ } }
          elseif ([string]::CompareOrdinal($key, $prevKey) -le 0) { $nonMono++ }
        }
        $prevKey = $key
        for ($i = 1; $i -lt $f.Count; $i++) { $v = 0.0; if ([double]::TryParse($f[$i], [Globalization.NumberStyles]::Float, $ci, [ref]$v) -and $v -le 0 -and ($f.Count -ne 11 -or ($i -ne 5 -and $i -ne 10)) -and ($f.Count -ne 5 -or ($i -ne 2 -and $i -ne 4))) { $nonPos++ } }
        $bid = $null; $ask = $null
        if ($f.Count -eq 11) { $bid = [double]::Parse($f[4], $ci); $ask = [double]::Parse($f[9], $ci) }
        elseif ($f.Count -eq 5) { $bid = [double]::Parse($f[1], $ci); $ask = [double]::Parse($f[3], $ci) }
        if ($bid -ne $null -and $bid -gt 0 -and $ask -gt 0) {
          $sp = $ask - $bid; if ($sp -lt 0) { $crossed++ }
          if ($sp -lt $spMin) { $spMin = $sp }; if ($sp -gt $spMax) { $spMax = $sp }; $spSum += $sp; $spN++
        }
      }
      $sr.Dispose()
      [void]$out.Add([pscustomobject]@{ zip = $r.relative; entry = $e.FullName; rows = $rows; cols = (($cols.Keys | Sort-Object | ForEach-Object { "${_}:$($cols[$_])" }) -join ';');
        first = $first; last = $last; non_monotonic = $nonMono; non_positive = $nonPos; crossed_bid_ask = $crossed;
        spread_min = $(if ($spN) { [math]::Round($spMin, 5) } else { '' }); spread_mean = $(if ($spN) { [math]::Round($spSum / $spN, 5) } else { '' }); spread_max = $(if ($spN) { [math]::Round($spMax, 5) } else { '' }) })
    }
  } finally { $z.Dispose() }
  $r.status = 'DATA_AUDITED'; $r.method = 'ZIP_STREAM_PARSED'; $r.batch = $Batch; $r.note = 'every CSV row parsed in-memory; see coverage/xauusd_audit.csv'
}
$inv | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
$out | Export-Csv -NoTypeInformation -Encoding UTF8 $OutCsv
"entries audited: $($out.Count); rows: $(($out | Measure-Object rows -Sum).Sum)"
"non_monotonic total: $(($out | Measure-Object non_monotonic -Sum).Sum); non_positive total: $(($out | Measure-Object non_positive -Sum).Sum); crossed total: $(($out | Measure-Object crossed_bid_ask -Sum).Sum)"
