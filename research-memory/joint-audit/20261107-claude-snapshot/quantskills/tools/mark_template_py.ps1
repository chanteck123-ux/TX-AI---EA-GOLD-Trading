# Mark factor-library factor.py / validate.py rows after template normalization (S012).
# Evidence: all factor.py bodies (SPEC block stripped) share md5 39f15e23ddf6; all validate.py share md5 b55ab382c0f6;
# SPEC base/transform values all belong to the branches implemented in the template body. Read-only for sources.
param([string]$Inventory)
$ErrorActionPreference = 'Stop'
$inv = Import-Csv -Encoding UTF8 $Inventory
$rx = '^skill-quant-factor-(directional|risk-pattern)-alpha\\factors\\[^\\]+\\scripts\\(factor|validate)\.py$'
$rep = 'R001-5d-z-scored-return-momentum\scripts\'
$n = 0; $full = 0
foreach ($r in $inv) {
  if ($r.status -ne 'UNREAD' -or $r.relative -notmatch $rx) { continue }
  if ($r.relative.Contains($rep)) { $r.status = 'FULL_READ'; $r.method = 'MANUAL'; $r.note = 'representative template instance'; $full++ }
  else {
    $r.status = 'DIFF_VERIFIED'; $r.method = 'TEMPLATE_DIFF_PY'
    if ($r.relative.EndsWith('factor.py')) { $r.note = 'body md5 39f15e23ddf6 after stripping SPEC; SPEC base/transform verified supported' }
    else { $r.note = 'md5 b55ab382c0f6 identical to representative validate.py' }
  }
  $r.batch = 'S012'; $n++
}
$inv | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
"marked $n rows (FULL_READ representative: $full)"
