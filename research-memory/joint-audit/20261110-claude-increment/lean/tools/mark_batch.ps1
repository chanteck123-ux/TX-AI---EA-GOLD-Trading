param([string]$Tag,[string]$Batch,[string]$Prefix,[string]$Note)
# Marks files listed in scratchpad b<Tag>.txt as FULL_READ (code read, XML doc skipped) in the LEAN inventory.
$INV='C:\Users\A\Documents\Codex\outputs\lean-full-review-20261101\claude\coverage\lean_inventory.csv'
$S='C:\Users\A\AppData\Local\Temp\claude\949fdc6dcf51bc77\6b0c02de-e90a-404a-8371-f274c0485b0a\scratchpad'
$sb=[scriptblock]::Create((Get-Content -Raw 'C:\Users\A\Documents\Codex\outputs\quantskills-learning-20261022\claude-full-review\tools\mark_source.ps1'))
$files = Get-Content "$S\b$Tag.txt" | Where-Object { $_.Trim() } | ForEach-Object { $Prefix + ($_.Trim().TrimStart([char]0xFEFF) -replace '/','\') }
& $sb -Inventory $INV -Batch $Batch -Status FULL_READ -Method 'CAT_N_CODE_EXCL_LICENSE_BLANK_USINGS_XMLDOC' -Note $Note -Paths $files | Out-Null
$rows = Import-Csv $INV
"marked " + ($rows | Where-Object batch -eq $Batch).Count + " in $Batch; UNREAD=" + ($rows | Where-Object status -eq 'UNREAD').Count
