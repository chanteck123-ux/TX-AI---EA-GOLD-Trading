# Mark source-inventory rows (by relative path regex or exact list) with status/method/batch/note. Read-only for sources.
param([string]$Inventory, [string[]]$Paths, [string]$Status = 'FULL_READ', [string]$Method = 'MANUAL', [string]$Batch, [string]$Note = '')
$ErrorActionPreference = 'Stop'
$rows = Import-Csv -Encoding UTF8 $Inventory
$set = @{}; foreach ($p in $Paths) { $set[$p.Replace('/','\')] = $true }
$n = 0
foreach ($r in $rows) { if ($set.ContainsKey($r.relative)) { $r.status = $Status; $r.method = $Method; $r.batch = $Batch; $r.note = $Note; $n++ } }
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
"marked $n of $($Paths.Count) paths as $Status ($Method) batch=$Batch"
