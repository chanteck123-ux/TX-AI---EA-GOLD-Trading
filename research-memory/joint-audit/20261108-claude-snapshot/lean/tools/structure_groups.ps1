# Tier-3 structural grouping (read-only). For UNREAD source files under a prefix:
# strip comments, replace string/char literals with S and numeric literals with N, collapse whitespace,
# then hash. Files with the same hash share a structure group. Also writes the normalized text per file
# so a representative can be read and others diffed. Nothing is executed.
param([string]$Root, [string]$Inventory, [string]$Prefix, [string]$Ext, [string]$OutCsv, [string]$NormDir)
$ErrorActionPreference = 'Stop'
$inv = Import-Csv -Encoding UTF8 $Inventory
New-Item -ItemType Directory -Force $NormDir | Out-Null
$md5 = [Security.Cryptography.MD5]::Create()
$out = New-Object System.Collections.ArrayList
foreach ($r in $inv) {
  if ($r.status -ne 'UNREAD' -or -not $r.relative.StartsWith($Prefix) -or $r.ext -ne $Ext) { continue }
  $p = Join-Path $Root $r.relative
  $t = [IO.File]::ReadAllText($p)
  if ($Ext -eq '.cs') {
    $t = [regex]::Replace($t, '(?s)/\*.*?\*/', ' ')
    $t = [regex]::Replace($t, '(?m)//.*$', ' ')
    $t = [regex]::Replace($t, '@?\$?"(?:[^"\\]|\\.|"")*"', 'S')
    $t = [regex]::Replace($t, "'(?:[^'\\]|\\.)'", 'S')
  } else {
    $t = [regex]::Replace($t, '(?s)("""|'''''').*?\1', 'S')
    $t = [regex]::Replace($t, '(?m)#.*$', ' ')
    $t = [regex]::Replace($t, '[rbfuRBFU]{0,2}"(?:[^"\\\n]|\\.)*"', 'S')
    $t = [regex]::Replace($t, "[rbfuRBFU]{0,2}'(?:[^'\\\n]|\\.)*'", 'S')
  }
  $t = [regex]::Replace($t, '\b\d+(\.\d+)?([eE][-+]?\d+)?[mMdDfFLl]?\b', 'N')
  $t = [regex]::Replace($t, '\s+', ' ').Trim()
  $h = ([BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($t))) -replace '-','').Substring(0,12)
  $safe = ($r.relative -replace '[\\/:]','__')
  [IO.File]::WriteAllText((Join-Path $NormDir ($safe + '.norm')), $t)
  [void]$out.Add([pscustomobject]@{ relative = $r.relative; bytes = $r.bytes; norm_len = $t.Length; struct_hash = $h })
}
$out | Export-Csv -NoTypeInformation -Encoding UTF8 $OutCsv
$g = $out | Group-Object struct_hash
"files: $($out.Count); groups: $($g.Count); groups with >1: $(@($g | Where-Object Count -gt 1).Count); files in multi-groups: $((@($g | Where-Object Count -gt 1) | Measure-Object Count -Sum).Sum)"
