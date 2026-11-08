# Build a per-file inventory (path, sha256, bytes, class, initial status) for a source tree. Read-only.
param([string]$Root, [string]$Out, [string]$Label)
$ErrorActionPreference = 'Stop'
$text = @('.py','.cs','.mjs','.js','.ts','.ps1','.sh','.toml','.yaml','.yml','.json','.jsonl','.csv','.txt','.md','.mdc','.xml','.csproj','.sln','.ipynb','.cfg','.ini','.example','.lock','.gitignore','.gitattributes','.props','.targets','.config','.html','.css','.svg','.keep','.gitkeep','.python-version','.sql','.r','.bat','.editorconfig')
$binary = @('.zip','.pyc','.png','.jpg','.jpeg','.gif','.parquet','.dll','.exe','.pdf','.ico','.db','.pkl','.npy','.npz','.h5','.whl','.gz','.7z')
$rows = New-Object System.Collections.ArrayList
Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\\.git\\' } | Sort-Object FullName | ForEach-Object {
  $rel = $_.FullName.Substring($Root.Length).TrimStart('\')
  $ext = $_.Extension.ToLowerInvariant(); if (-not $ext) { $ext = '(none)' }
  $cls = if ($binary -contains $ext) { 'BINARY' } elseif ($text -contains $ext -or $ext -eq '(none)') { 'TEXT' } else { 'OTHER' }
  if ($ext -eq '.py' -or $ext -eq '.cs' -or $ext -eq '.mjs' -or $ext -eq '.js' -or $ext -eq '.ts' -or $ext -eq '.ps1' -or $ext -eq '.sh' -or $ext -eq '.bat' -or $ext -eq '.ipynb') { $cls = 'CODE' }
  if ($ext -eq '.csv' -or $ext -eq '.jsonl' -or $ext -eq '.parquet') { $cls = if ($cls -eq 'BINARY') { 'BINARY' } else { 'DATA' } }
  $h = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
  [void]$rows.Add([pscustomobject]@{ label=$Label; relative=$rel; ext=$ext; class=$cls; bytes=$_.Length; sha256=$h; status='UNREAD'; method=''; batch=''; note='' })
}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 $Out
$rows | Group-Object class | ForEach-Object { "$($_.Name): $($_.Count) files, $([math]::Round((($_.Group | Measure-Object bytes -Sum).Sum)/1MB,2)) MB" }
"total: $($rows.Count)"
