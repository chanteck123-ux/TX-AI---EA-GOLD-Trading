# TEMPLATE_DIFF for QuantSkills factor libraries (read-only; no code execution of third-party files)
param([string]$OutDir)
$ErrorActionPreference = 'Stop'
$base = 'C:\Users\A\Documents\Codex\quantskills-learning-repos'
$repos = @('skill-quant-factor-directional-alpha','skill-quant-factor-risk-pattern-alpha')
$files = @('SKILL.md','README.md','references\formula.md','validation_real\report.md')
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Get-Meta($dir) {
  $s = Get-Content -Raw -Encoding UTF8 (Join-Path $dir 'SKILL.md')
  $r = Get-Content -Raw -Encoding UTF8 (Join-Path $dir 'README.md')
  $m = @{}
  $m.id = ([regex]::Match($s,'factor_id:\s*(\S+)')).Groups[1].Value
  $m.cat = ([regex]::Match($s,'category:\s*(.+)')).Groups[1].Value.Trim()
  $m.slugname = ([regex]::Match($s,'name:\s*(\S+)')).Groups[1].Value
  $m.en = ([regex]::Match($s,'(?m)^# (.+)$')).Groups[1].Value.Trim()
  $m.zh = ([regex]::Match($r,'(?m)^# (.+)$')).Groups[1].Value.Trim()
  $m.zhcat = ([regex]::Match($r,'属于 `([^`]+)` 类')).Groups[1].Value
  return $m
}
function Normalize([string]$text, $m) {
  $t = $text
  foreach ($k in @('slugname','en','zh')) { if ($m[$k]) { $t = $t.Replace($m[$k], "<$k>") } }
  if ($m.id) { $t = $t.Replace($m.id, '<id>') }
  if ($m.cat) { $t = $t -replace ("(?<=category: )" + [regex]::Escape($m.cat)), '<cat>'; $t = $t.Replace("``$($m.cat)`` family", '`<cat>` family') }
  if ($m.zhcat) { $t = $t.Replace("属于 ``$($m.zhcat)`` 类", '属于 `<zhcat>` 类') }
  # numbers -> <n>, booleans/status kept
  $t = [regex]::Replace($t, '-?\d+(\.\d+)?(e-?\d+)?', '<n>')
  return $t
}

$rows = New-Object System.Collections.ArrayList
$resid = New-Object System.Collections.ArrayList
foreach ($repo in $repos) {
  $fdirs = Get-ChildItem -Directory (Join-Path $base "$repo\factors") | Sort-Object Name
  $ref = $fdirs[0].FullName
  $rm = Get-Meta $ref
  $refNorm = @{}
  foreach ($f in $files) { $refNorm[$f] = (Normalize (Get-Content -Raw -Encoding UTF8 (Join-Path $ref $f)) $rm) -split "`r?`n" }
  $script:altRefs = New-Object System.Collections.ArrayList
  foreach ($d0 in $fdirs) { $m0 = Get-Meta $d0.FullName; foreach ($f in $files) { $n0 = (Normalize (Get-Content -Raw -Encoding UTF8 (Join-Path $d0.FullName $f)) $m0) -split "`r?`n"; $k = "$f|$($n0.Count)"; if (-not $refNorm.ContainsKey($k) -and $n0.Count -ne $refNorm[$f].Count) { $refNorm[$k] = $n0; [void]$script:altRefs.Add("$repo $k template=$($d0.Name)") } } }
  foreach ($d in $fdirs) {
    $m = Get-Meta $d.FullName
    $rep = Get-Content -Raw -Encoding UTF8 (Join-Path $d.FullName 'validation_real\report.md')
    $fm = Get-Content -Raw -Encoding UTF8 (Join-Path $d.FullName 'references\formula.md')
    $formula = ([regex]::Match($fm,'```text\s*\r?\n(.+?)\r?\n```','Singleline')).Groups[1].Value.Trim()
    $params = ([regex]::Match($fm,'```json\s*\r?\n(.+?)\r?\n```','Singleline')).Groups[1].Value -replace '\s+',''
    function Get-MetricVal($name) { ([regex]::Match($rep, '\| ' + [regex]::Escape($name) + ' \| ([^|]+) \|')).Groups[1].Value.Trim() }
    $nres = 0
    foreach ($f in $files) {
      $lines = (Normalize (Get-Content -Raw -Encoding UTF8 (Join-Path $d.FullName $f)) $m) -split "`r?`n"
      $ref2 = $refNorm[$f]; $alt = $refNorm["$f|$($lines.Count)"]; if ($lines.Count -ne $ref2.Count -and $alt) { $ref2 = $alt }
      if ($lines.Count -ne $ref2.Count) {
        $nres += $lines.Count
        [void]$resid.Add("### $repo/$($d.Name)/$f LINECOUNT $($lines.Count) vs $($ref2.Count) (full file follows)")
        (Get-Content -Raw -Encoding UTF8 (Join-Path $d.FullName $f)) -split "`r?`n" | ForEach-Object { [void]$resid.Add("    $_") }
        continue
      }
      $orig = (Get-Content -Raw -Encoding UTF8 (Join-Path $d.FullName $f)) -split "`r?`n"
      for ($i=0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -ne $ref2[$i]) {
          # formula lines (inside text block) and json param lines are captured in CSV; still record raw
          $nres++
          [void]$resid.Add("$repo/$($d.Name)/$f L$($i+1): $($orig[$i])")
        }
      }
    }
    [void]$rows.Add([pscustomobject]@{
      repo=$repo; dir=$d.Name; id=$m.id; cat=$m.cat; zh=$m.zh; en=$m.en; formula=$formula; params=$params
      sample=(Get-MetricVal 'Sample rows'); usable=(Get-MetricVal 'Usable rows'); coverage=(Get-MetricVal 'Coverage'); markets=(Get-MetricVal 'Markets')
      ic=(Get-MetricVal '5D Rank IC mean'); icstd=(Get-MetricVal '5D Rank IC std'); icir=(Get-MetricVal '5D ICIR'); icobs=(Get-MetricVal 'IC observations')
      q5q1=(Get-MetricVal 'Q5-Q1 mean 5D return'); turnover=(Get-MetricVal 'Top quintile turnover'); lookahead=(Get-MetricVal 'No-lookahead check'); status=(Get-MetricVal 'Status')
      residual_lines=$nres })
  }
}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutDir 'factors.csv')
$resid | Set-Content -Encoding UTF8 (Join-Path $OutDir 'residual_lines.txt')
"factors: $($rows.Count); residual lines: $($resid.Count)"

