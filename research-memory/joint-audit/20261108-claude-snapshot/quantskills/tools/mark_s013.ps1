# Mark S013 rows: factor result.json -> DATA_AUDITED; per-factor agents/openai.yaml -> DIFF_VERIFIED; factor_index.json -> DATA_AUDITED.
param([string]$Inventory)
$ErrorActionPreference = 'Stop'
$inv = Import-Csv -Encoding UTF8 $Inventory
$base = '^skill-quant-factor-(directional|risk-pattern)-alpha\\'
$n = @{ json = 0; yaml = 0; index = 0 }
foreach ($r in $inv) {
  if ($r.status -ne 'UNREAD' -or $r.relative -notmatch $base) { continue }
  if ($r.relative -match '\\factors\\[^\\]+\\validation_real\\result\.json$') {
    $r.status = 'DATA_AUDITED'; $r.method = 'PARSED_ALL_FIELDS'; $r.batch = 'S013'; $r.note = 'parsed; matches factors_584.csv and factor_index.json; see template_diff/result_json_summary.txt'; $n.json++
  } elseif ($r.relative -match '\\factors\\[^\\]+\\agents\\openai\.yaml$') {
    $r.status = 'DIFF_VERIFIED'; $r.method = 'TEMPLATE_DIFF_YAML'; $r.batch = 'S013'; $r.note = 'identical after removing display_name/default_prompt/factor_id/category; groups = category short_description'; $n.yaml++
  } elseif ($r.relative -match '^skill-quant-factor-(directional|risk-pattern)-alpha\\factor_index\.json$') {
    $r.status = 'DATA_AUDITED'; $r.method = 'PARSED_ALL_FIELDS'; $r.batch = 'S013'; $r.note = 'used as SPEC cross-check for every result.json'; $n.index++
  }
}
$inv | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
"result.json=$($n.json) openai.yaml=$($n.yaml) factor_index=$($n.index)"
