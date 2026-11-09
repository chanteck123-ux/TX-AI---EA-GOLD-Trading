param([string]$ListFile,[string]$Batch,[string]$Prefix='Algorithm.CSharp\')
# Marks every file named in $ListFile (one relative path per line, '/' or '\') as FULL_READ in the LEAN inventory.
$INV='C:\Users\A\Documents\Codex\outputs\lean-full-review-20261101\claude\coverage\lean_inventory.csv'
$sb=[scriptblock]::Create((Get-Content -Raw 'C:\Users\A\Documents\Codex\outputs\quantskills-learning-20261022\claude-full-review\tools\mark_source.ps1'))
$files = Get-Content $ListFile | Where-Object { $_.Trim() } | ForEach-Object { $Prefix + ($_.Trim().TrimStart([char]0xFEFF) -replace '/','\') }
& $sb -Inventory $INV -Batch $Batch -Status FULL_READ -Method 'PRINT_EXAMPLE_EXCL_EXPECTED_STATS' -Note "tools/read_batch.sh; see batches/${Batch}_*_CN.md" -Paths $files | Out-Null
$rows = Import-Csv $INV
"marked " + ($rows | Where-Object batch -eq $Batch).Count + " in $Batch; UNREAD=" + ($rows | Where-Object status -eq 'UNREAD').Count
