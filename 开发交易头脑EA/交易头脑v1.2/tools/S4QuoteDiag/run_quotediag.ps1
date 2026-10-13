# S4 B2 read-only quote diagnostic runner (Windows PowerShell 5.1 or 7). Builds the C# tool, runs the
# engineering self-test, then the raw-tick scan, and writes RUN_RECEIPT.json with input/output hashes.
# No LEAN engine, no MT5, no Python, no trading-code change.
param([string]$Label='S4_B2_QUOTEDIAG')
$ErrorActionPreference='Stop'
$tool=$PSScriptRoot
$project=[IO.Path]::GetFullPath((Join-Path $tool '..\..'))
$research=[IO.Path]::GetFullPath((Join-Path $project '..'))
$qc=Join-Path $research 'quantconnect_20260920'
$sdk=Join-Path $qc 'runtime\dotnet\dotnet.exe'
$env:DOTNET_CLI_HOME=Join-Path $qc 'runtime\dotnet_home'; $env:DOTNET_CLI_TELEMETRY_OPTOUT='1'; $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE='1'
function Sha($p){ (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
$id=$Label+'_'+[datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$dir=Join-Path $project ('diagnostics\'+$id)
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$receipt=[ordered]@{ schema='S4_B2_QUOTEDIAG_RECEIPT_V1'; id=$id; started_utc=[datetime]::UtcNow.ToString('o'); status='STARTED'
  source_sha256=[ordered]@{ 'QuoteDiag.cs'=(Sha (Join-Path $tool 'QuoteDiag.cs')); 'Program.cs'=(Sha (Join-Path $tool 'Program.cs')); 'S4QuoteDiag.csproj'=(Sha (Join-Path $tool 'S4QuoteDiag.csproj')); 'run_quotediag.ps1'=(Sha $PSCommandPath) }
  scope='READ_ONLY_RAW_TICK_EVIDENCE; no engine, no trading change; score N/A'; data_role='AUGUST_2026_ALREADY_USED_DEVELOPMENT_NOT_OOS' }
$receiptPath=Join-Path $dir 'RUN_RECEIPT.json'
function Save { $receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding UTF8 }
Save
try {
  & $sdk build (Join-Path $tool 'S4QuoteDiag.csproj') -c Release --nologo --artifacts-path (Join-Path $dir 'artifacts') *> (Join-Path $dir 'build.log')
  if($LASTEXITCODE -ne 0){ throw 'build failed' }
  $dll=Join-Path $dir 'artifacts\bin\S4QuoteDiag\release\S4QuoteDiag.dll'
  $receipt.dll_sha256=Sha $dll; $receipt.build_log_sha256=Sha (Join-Path $dir 'build.log')
  & $sdk $dll --selftest (Join-Path $dir 'selftest') *> (Join-Path $dir 'selftest.log')
  if($LASTEXITCODE -ne 0){ throw 'engineering self-test failed' }
  $receipt.selftest_result_sha256=Sha (Join-Path $dir 'selftest\SELFTEST_RESULT.json'); $receipt.status='SELFTEST_PASS'; Save
  $cmd=@('--raw-dir',(Join-Path $qc 'data\raw'),'--export-manifest',(Join-Path $qc 'data\EXPORT_MANIFEST.json'),'--lean-tick-manifest',(Join-Path $qc 'data\LEAN_TICK_MANIFEST.json'),
    '--native-baseline',(Join-Path $project 'research\S4_NATIVE_AUG_BASELINE.json'),'--native-audit',(Join-Path $research 'mt5_iteration9_20261004\S4_BASE_AUG_D250\session\run\audit'),
    '--lean-run',(Join-Path $project 'runs\S4B1_FULLAUGUST_D250_20261012T090714Z_ab0a4fb2'),'--out-dir',(Join-Path $dir 'out'))
  $receipt.command='dotnet S4QuoteDiag.dll '+($cmd -join ' ')
  & $sdk $dll @cmd *> (Join-Path $dir 'scan.log')
  $code=$LASTEXITCODE
  $sum=Get-Content -Raw -LiteralPath (Join-Path $dir 'out\SUMMARY.json') | ConvertFrom-Json
  $receipt.scan_exit_code=$code; $receipt.summary_status=$sum.status
  if($code -ne 0){ throw ('scan refused or failed: '+$sum.status) }
  $receipt.outputs=[ordered]@{}
  foreach($f in 'SUMMARY.json','events.csv','evidence_rows.csv'){ $receipt.outputs[$f]=Sha (Join-Path $dir ('out\'+$f)) }
  $receipt.scan_log_sha256=Sha (Join-Path $dir 'scan.log')
  $receipt.status='DIAGNOSTIC_COMPLETE_REVIEW_REQUIRED'
} catch { $receipt.status='FAILED'; $receipt.error=$_.Exception.Message; throw }
finally { $receipt.completed_utc=[datetime]::UtcNow.ToString('o'); Save; Write-Output ('S4B2_DIAG_DIR '+$dir+' STATUS '+$receipt.status) }
