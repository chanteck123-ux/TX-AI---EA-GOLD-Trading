# Correct batch L-DATA3: prose docs (.md) must be read, not structurally audited. Revert them to UNREAD.
# .keep placeholder files: record as FULL_READ only if empty/trivial (checked separately).
param([string]$Inventory)
$ErrorActionPreference = 'Stop'
$inv = Import-Csv -Encoding UTF8 $Inventory
$n = 0
foreach ($r in $inv) {
  if ($r.batch -eq 'L-DATA3' -and $r.ext -eq '.md') { $r.status = 'UNREAD'; $r.method = ''; $r.batch = ''; $r.note = 'reverted: prose doc wrongly structural-audited in L-DATA3; must be read'; $n++ }
}
$inv | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
"reverted .md rows: $n"
