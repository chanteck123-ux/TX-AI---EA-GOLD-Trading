# For every UNREAD row whose SHA-256 equals a row already FULL_READ / DIFF_VERIFIED / DATA_AUDITED / IMAGE_VIEWED,
# mark it HASH_REUSE pointing at that row. Read-only for sources. Excludes empty files (sha of zero bytes) from reuse.
param([string]$Inventory, [string]$Batch = 'S013')
$ErrorActionPreference = 'Stop'
$inv = Import-Csv -Encoding UTF8 $Inventory
$emptySha = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
$src = @{}
foreach ($r in $inv) {
  if (@('FULL_READ','DIFF_VERIFIED','DATA_AUDITED','IMAGE_VIEWED') -contains $r.status -and -not $src.ContainsKey($r.sha256)) { $src[$r.sha256] = $r.relative }
}
$n = 0; $byClass = @{}
foreach ($r in $inv) {
  if ($r.status -ne 'UNREAD' -or $r.sha256 -eq $emptySha) { continue }
  if ($src.ContainsKey($r.sha256)) {
    $r.status = 'HASH_REUSE'; $r.method = 'SHA256_EQUAL'; $r.batch = $Batch; $r.note = "same as $($src[$r.sha256])"; $n++
    $byClass[$r.class] = 1 + [int]$byClass[$r.class]
  }
}
$empty = ($inv | Where-Object { $_.status -eq 'UNREAD' -and $_.sha256 -eq $emptySha })
foreach ($r in $empty) { $r.status = 'FULL_READ'; $r.method = 'EMPTY_FILE'; $r.batch = $Batch; $r.note = 'zero bytes' }
$inv | Export-Csv -NoTypeInformation -Encoding UTF8 $Inventory
"hash_reuse: $n; empty files: $(@($empty).Count)"
$byClass.Keys | Sort-Object | ForEach-Object { "  ${_}: $($byClass[$_])" }
