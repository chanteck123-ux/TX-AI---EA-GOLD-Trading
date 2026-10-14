#requires -Version 7.0
# S4 B4A quote-field candidate runner (research/S4_B4A_QUOTE_FIELDS_SCOPE_CN.md). Executed by Codex.
#   Fixtures   : B4A adapter fixtures + the ORIGINAL 90 B1 fixtures (unchanged sources), pure C#
#   Build      : compile the B4A LEAN algorithm only
#   Smoke      : real LEAN run, server 2026-08-01..2026-08-03 (budget 1, plus 1 correction with -CorrectionReason)
#   FullAugust : one run; REUSES the verified smoke build (no recompile); requires identical sources/config (-SmokeRunDir)
# Fixed: 500 USD, 2%, 250 ms, protective QUOTE, commission 3.5. August 2026 already-used development data. Score N/A.
param(
  [Parameter(Mandatory=$true)][ValidateSet('Fixtures','Build','Smoke','FullAugust')][string]$Mode,
  [string]$SmokeRunDir='',
  [string]$CorrectionReason='',
  [string]$Owner='Codex'
)
$ErrorActionPreference='Stop'
$src=$PSScriptRoot
$project=[IO.Path]::GetFullPath((Join-Path $src '../../..'))                 # lean_mcp_20261012
$research=[IO.Path]::GetFullPath((Join-Path $project '..'))                   # repair_research
$qc=Join-Path $research 'quantconnect_20260920'
$i9=Join-Path $research 'mt5_iteration9_20261004'
$b1=Join-Path $project 'lean/algorithms/S4'
$sdk=Join-Path $qc 'runtime/dotnet/dotnet.exe'
$leanBin=Join-Path $qc 'vendor/Lean/Launcher/bin/Release'
$mq5=[IO.Path]::GetFullPath((Join-Path $research '../../outputs/TradingBrain_I11_Seven_Strategies_20261004/MT5/S4/TB500_S4_BE125/TB500_S4_BE125.mq5'))
$env:DOTNET_CLI_HOME=Join-Path $qc 'runtime/dotnet_home'; $env:DOTNET_CLI_TELEMETRY_OPTOUT='1'; $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE='1'
$candidate='TB500_S4_BE125_LEAN_B4A'
$LatencyMs=250; $ProtectiveFill='QUOTE'; $CommissionPerLotSide=3.5
$registry=Join-Path $project 'research/S4B4A_RUN_REGISTRY.json'
# Frozen, hash-bound shared inputs (B1 R2 and I9; must be byte-identical).
$frozen=[ordered]@{
  'lean/algorithms/S4/S4Core.cs'='ee509e1d50440b2bc0351a1b568abed7bc7e08050f9010eaafd5da3fc6be4e5d'
  'lean/algorithms/S4/fixtures/Program.cs'='c1edbbda5b255b9d3bd451d5f1f7ac9c76c0a2761f668068302eef61a6aa4775'
  'lean/algorithms/S4/fixtures/S4.Fixtures.csproj'='b026fba548e1516e75501812c0ddefb0545147b5fb60dceae15b361b29d65007'
  '../mt5_iteration9_20261004/algorithm/C7Signals.Core.cs'='261b96eb242267aa7471b89c9d73b3f8076b816b020fbecd41dc8239f55dd595'
  '../mt5_iteration9_20261004/algorithm/Strategy123.cs'='1be13bfe8ceda032430bdd3cb087f5b474e6ceaec9efba650767aabd246e3bd9'
  '../mt5_iteration9_20261004/algorithm/Strategy456.cs'='cffb2b726971c6d5088c1e0285191b8e01a4f4b77ae5e3c6d79a7e881f12e2fb'
  '../mt5_iteration9_20261004/algorithm/StrategyScalping.cs'='1576cd1e3993201541fb941943ba287a0fbfaa4afbd306b071ecbab092fcde09'
}
$expected=@{
  mq5='f6abe1abc8d9cfca27e6483f344aab03110b9df11b8d1b458e3fce432d63be47'
  tick_manifest='9a3926c75890be2a0d54537cfe1b31f37fd1209ca04291ce9064172551cd117f'
  export_manifest='9024018027104db19e53f238c8479cb249255b336c0a6f9b51cf2d43a0aeb581'
  smoke_rows=923807
  full_august_rows=20513403
}
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Stage([string]$stage,[string]$id,[string]$status,[string]$evidence){
  $line=[ordered]@{stage=$stage;sid='S4';id=$id;candidate_id=$candidate;run_id=$id;status=$status;utc=[datetime]::UtcNow.ToString('o');owner=$Owner;evidence=$evidence}|ConvertTo-Json -Compress
  Add-Content -LiteralPath (Join-Path $project 'research/STAGES.jsonl') -Value $line -Encoding utf8
}
$ownFiles=@('QuoteFieldAdapter.cs','S4B4AAlgorithm.cs','TradingBrain.S4B4A.csproj','run_s4b4a.ps1','fixtures/Program.cs','fixtures/S4B4A.Fixtures.csproj')|ForEach-Object{Join-Path $src $_}
function FrozenPath([string]$rel){[IO.Path]::GetFullPath((Join-Path $project $rel))}
function SourceHashes{ @($ownFiles|ForEach-Object{[ordered]@{path=[IO.Path]::GetRelativePath($research,$_);sha256=(Sha $_)}}) + @($frozen.Keys|ForEach-Object{[ordered]@{path=[IO.Path]::GetRelativePath($research,(FrozenPath $_));sha256=(Sha (FrozenPath $_))}}) }
function HashText($list){ @($list|ForEach-Object{$_.path+'='+$_.sha256}) -join ';' }
function Assert-SourcesUnchanged([string]$when){ if((HashText (SourceHashes)) -ne (HashText $receipt.source_hashes)){throw ('Sources changed '+$when)} }
function Read-Registry{ if(Test-Path -LiteralPath $registry){Get-Content -LiteralPath $registry -Raw|ConvertFrom-Json -AsHashtable}else{@{runs=@()}} }
function Save-Registry($r){ $r|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $registry -Encoding utf8 }

# ---- gates common to every mode
if((Sha $mq5) -ne $expected.mq5){throw 'Retained S4 MQ5 hash mismatch'}
foreach($rel in $frozen.Keys){ if((Sha (FrozenPath $rel)) -ne $frozen[$rel]){throw ('Frozen shared source changed: '+$rel)} }
$stamp=[datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$id='S4B4A_'+$Mode.ToUpperInvariant()+'_D'+$LatencyMs+'_'+$stamp+'_'+([guid]::NewGuid().ToString('N').Substring(0,8))
$isRun=$Mode -in 'Smoke','FullAugust'
# ---- budget (checked before creating anything)
$reg=Read-Registry; $runs=@($reg.runs)
if($Mode -eq 'Smoke'){
  $smokes=@($runs|Where-Object{$_.mode -eq 'Smoke'})
  if($smokes.Count -ge 2){throw 'Smoke budget exhausted (1 + 1 correction)'}
  if($smokes.Count -eq 1 -and $CorrectionReason.Trim().Length -lt 15){throw 'Second smoke is the single correction run: -CorrectionReason (>=15 chars, evidence-based) required'}
}
if($Mode -eq 'FullAugust'){
  if(@($runs|Where-Object{$_.mode -eq 'FullAugust'}).Count -ge 1){throw 'Full-August budget (1) exhausted'}
  if(-not $SmokeRunDir){throw 'FullAugust requires -SmokeRunDir of a passing B4A Smoke run'}
}
$dir=Join-Path $project ($(if($isRun){'runs/'}else{'builds/'})+$id)
New-Item -ItemType Directory -Path $dir -Force|Out-Null
$receiptPath=Join-Path $dir 'RUN_RECEIPT.json'
$receipt=[ordered]@{schema='S4_LEAN_B4A_RECEIPT_V1';id=$id;mode=$Mode;candidate_id=$candidate;owner=$Owner;latency_ms=$LatencyMs;protective_fill=$ProtectiveFill;commission_per_lot_side=$CommissionPerLotSide;
  single_change='QUOTE_FIELDS_FROM_CURRENT_ROW_FLAGS';correction_reason=$CorrectionReason;data_role='AUGUST_2026_ALREADY_USED_DEVELOPMENT_NOT_OOS';score_status='SCORE_TARGETS_UNSET';
  mq5_sha256=$expected.mq5;source_hashes=(SourceHashes);frozen_shared_verified=$true;started_utc=[datetime]::UtcNow.ToString('o');status='STARTED'}
function Save{$receipt|ConvertTo-Json -Depth 12|Set-Content -LiteralPath $receiptPath -Encoding utf8}
Save
if($isRun){ $runs+=@{mode=$Mode;id=$id;dir=$dir;correction_reason=$CorrectionReason;status='STARTED';utc=[datetime]::UtcNow.ToString('o')}; $reg.runs=$runs; Save-Registry $reg }
try{
  if($Mode -eq 'Fixtures'){
    Stage 'test' $id 'STARTED' $dir
    & $sdk build (Join-Path $src 'fixtures/S4B4A.Fixtures.csproj') -c Release --nologo --artifacts-path (Join-Path $dir 'artifacts_b4a') *> (Join-Path $dir 'build_b4a.log')
    if($LASTEXITCODE -ne 0){throw 'B4A fixture build failed'}
    & $sdk (Join-Path $dir 'artifacts_b4a/bin/S4B4A.Fixtures/release/S4B4A.Fixtures.dll') --work (Join-Path $dir 'synthetic_csv') --out (Join-Path $dir 'B4A_FIXTURE_RESULT.json') *> (Join-Path $dir 'b4a_fixture_run.log')
    $c1=$LASTEXITCODE; $f1=Get-Content -LiteralPath (Join-Path $dir 'B4A_FIXTURE_RESULT.json') -Raw|ConvertFrom-Json
    & $sdk build (Join-Path $b1 'fixtures/S4.Fixtures.csproj') -c Release --nologo --artifacts-path (Join-Path $dir 'artifacts_b1') *> (Join-Path $dir 'build_b1.log')
    if($LASTEXITCODE -ne 0){throw 'B1 fixture build failed'}
    & $sdk (Join-Path $dir 'artifacts_b1/bin/S4.Fixtures/release/S4.Fixtures.dll') --mq5 $mq5 --out (Join-Path $dir 'B1_FIXTURE_RESULT.json') *> (Join-Path $dir 'b1_fixture_run.log')
    $c2=$LASTEXITCODE; $f2=Get-Content -LiteralPath (Join-Path $dir 'B1_FIXTURE_RESULT.json') -Raw|ConvertFrom-Json
    Assert-SourcesUnchanged 'during fixtures'
    $receipt.b4a_fixtures=[ordered]@{status=$f1.status;passed=$f1.passed;failed=@($f1.failed).Count;sha256=(Sha (Join-Path $dir 'B4A_FIXTURE_RESULT.json'))}
    $receipt.b1_fixtures=[ordered]@{status=$f2.status;passed=$f2.passed;failed=@($f2.failed).Count;sha256=(Sha (Join-Path $dir 'B1_FIXTURE_RESULT.json'))}
    if($c1 -ne 0 -or $f1.status -ne 'PASS' -or $c2 -ne 0 -or $f2.status -ne 'PASS' -or $f2.passed -ne 90){throw 'Fixtures failed (B4A adapter or original 90 B1)'}
    $receipt.status='FIXTURES_PASS';Stage 'test' $id 'PASS' (Join-Path $dir 'B4A_FIXTURE_RESULT.json');return
  }
  # ---- bind sources into the run: own files + frozen shared sources; EVERY copy checked against the receipt hashes
  $bound=Join-Path $dir 'compiled'
  New-Item -ItemType Directory -Path (Join-Path $bound 'S4B4A'),(Join-Path $bound 'S4'),(Join-Path $bound 'i9') -Force|Out-Null
  $byPath=@{}; foreach($h in $receipt.source_hashes){$byPath[$h.path]=$h.sha256}
  $copies=@()
  foreach($n in 'QuoteFieldAdapter.cs','S4B4AAlgorithm.cs','TradingBrain.S4B4A.csproj'){ $copies+=,@((Join-Path $src $n),(Join-Path $bound ('S4B4A/'+$n))) }
  $copies+=,@((Join-Path $b1 'S4Core.cs'),(Join-Path $bound 'S4/S4Core.cs'))
  foreach($n in 'C7Signals.Core.cs','Strategy123.cs','Strategy456.cs','StrategyScalping.cs'){ $copies+=,@((Join-Path $i9 ('algorithm/'+$n)),(Join-Path $bound ('i9/'+$n))) }
  $boundHashes=[ordered]@{}
  foreach($c in $copies){
    Copy-Item -LiteralPath $c[0] -Destination $c[1]
    $rel=[IO.Path]::GetRelativePath($research,$c[0]); $want=$byPath[$rel]
    if(-not $want){throw ('Bound source not in receipt: '+$rel)}
    $got=Sha $c[1]; if($got -ne $want){throw ('Bound copy differs from receipt-captured hash: '+$rel)}
    $boundHashes[[IO.Path]::GetRelativePath($dir,$c[1])]=$got
  }
  $receipt.bound_source_hashes=$boundHashes; Save
  if($Mode -eq 'FullAugust'){
    # ---- reuse the verified smoke build (no recompile: build paths/PDB make DLL bytes differ between builds)
    $sr=Get-Content -LiteralPath (Join-Path $SmokeRunDir 'RUN_RECEIPT.json') -Raw|ConvertFrom-Json
    $sres=Get-Content -LiteralPath (Join-Path $SmokeRunDir 'RESULT.json') -Raw|ConvertFrom-Json
    if($sr.candidate_id -ne $candidate -or $sr.status -ne 'SMOKE_PASS_REVIEW_REQUIRED' -or $sr.build_mode -ne 'FRESH_COMPILE'){throw 'Smoke run did not pass (or is not a freshly compiled B4A smoke)'}
    if($sr.result_sha256 -ne (Sha (Join-Path $SmokeRunDir 'RESULT.json'))){throw 'Smoke RESULT hash differs from its receipt'}
    if($sr.latency_ms -ne $LatencyMs -or $sr.protective_fill -ne $ProtectiveFill -or $sr.commission_per_lot_side -ne $CommissionPerLotSide){throw 'Smoke configuration differs'}
    if((HashText $receipt.source_hashes) -ne (HashText $sr.source_hashes)){throw 'Sources changed since the Smoke run: a new Smoke is required (hash gate not relaxed)'}
    if(-not $sres.reconciliation.passed -or -not $sres.quote_adapter.aligned){throw 'Smoke reconciliation or sidecar alignment failed'}
    $smokeRelease=Join-Path $SmokeRunDir 'compiled/artifacts/bin/TradingBrain.S4B4A/release'
    if((Sha (Join-Path $smokeRelease 'TradingBrain.S4B4A.dll')) -ne $sr.dll_sha256){throw 'Smoke DLL on disk differs from the smoke receipt'}
    if((Sha (Join-Path $SmokeRunDir 'compile.log')) -ne $sr.compile_log_sha256){throw 'Smoke compile log differs from the smoke receipt'}
    $release=Join-Path $bound 'artifacts/bin/TradingBrain.S4B4A/release'; New-Item -ItemType Directory -Path $release -Force|Out-Null
    Copy-Item -Path (Join-Path $smokeRelease '*') -Destination $release -Recurse
    Copy-Item -LiteralPath (Join-Path $SmokeRunDir 'compile.log') -Destination (Join-Path $dir 'compile.log')
    $dll=Join-Path $release 'TradingBrain.S4B4A.dll'
    if((Sha $dll) -ne $sr.dll_sha256 -or (Sha (Join-Path $dir 'compile.log')) -ne $sr.compile_log_sha256){throw 'Copied smoke build differs from the smoke receipt'}
    $receipt.build_mode='REUSED_MATCHING_SMOKE_BUILD';$receipt.smoke_run=$sr.id;$receipt.smoke_dir=$SmokeRunDir;$receipt.dll_sha256=$sr.dll_sha256;$receipt.compile_log_sha256=$sr.compile_log_sha256;$receipt.status='BUILD_REUSED';Save
  } else {
    Stage 'compile' $id 'STARTED' $dir
    & $sdk build (Join-Path $bound 'S4B4A/TradingBrain.S4B4A.csproj') -c Release --nologo ('-p:LeanBin='+$leanBin) '-p:I9Src=../i9' '-p:S4CoreSrc=../S4' --artifacts-path (Join-Path $bound 'artifacts') *> (Join-Path $dir 'compile.log')
    if($LASTEXITCODE -ne 0){Stage 'compile' $id 'FAILED' (Join-Path $dir 'compile.log');throw 'C# build failed'}
    $dll=Join-Path $bound 'artifacts/bin/TradingBrain.S4B4A/release/TradingBrain.S4B4A.dll'
    Assert-SourcesUnchanged 'during compilation'
    foreach($k in $boundHashes.Keys){ if((Sha (Join-Path $dir $k)) -ne $boundHashes[$k]){throw ('Bound copy changed during compilation: '+$k)} }
    $receipt.build_mode='FRESH_COMPILE';$receipt.dll_sha256=Sha $dll;$receipt.compile_log_sha256=Sha (Join-Path $dir 'compile.log');$receipt.status='COMPILED';Save
    Stage 'compile' $id 'PASS' (Join-Path $dir 'compile.log')
  }
  if($Mode -eq 'Build'){return}

  # ---- data gates
  $tickManifest=Join-Path $qc 'data/LEAN_TICK_MANIFEST.json'; $exportManifest=Join-Path $qc 'data/EXPORT_MANIFEST.json'
  if((Sha $tickManifest) -ne $expected.tick_manifest){throw 'Tick manifest changed'}
  if((Sha $exportManifest) -ne $expected.export_manifest){throw 'Export manifest changed'}
  if((Get-Content -LiteralPath $tickManifest -Raw|ConvertFrom-Json).sourceManifestSha256 -ne $expected.export_manifest){throw 'Tick manifest does not name the export manifest'}
  $barProofPath=Join-Path $i9 'data/BAR_EXTENSION_VERIFICATION.json'; $barProof=Get-Content -LiteralPath $barProofPath -Raw|ConvertFrom-Json
  if($barProof.status -ne 'PASS_NATIVE_EXTENSION_OVERLAP_IDENTICAL'){throw 'Native bar extension not verified'}
  foreach($f in $barProof.files){if((Sha $f.path) -ne $f.sha256){throw ('Native bars changed '+$f.tf)}}
  $receipt.tick_manifest_sha256=$expected.tick_manifest;$receipt.export_manifest_sha256=$expected.export_manifest;$receipt.bar_proof_sha256=Sha $barProofPath
  $endDate=$(if($Mode -eq 'FullAugust'){'2026-08-31'}else{'2026-08-03'}); $expectRows=$(if($Mode -eq 'FullAugust'){$expected.full_august_rows}else{$expected.smoke_rows})
  $config=Get-Content -LiteralPath (Join-Path $qc 'lean_bootstrap/smoke_01_config.json') -Raw|ConvertFrom-Json -AsHashtable
  $config['environments']=@{backtesting=$config['environments']['backtesting']}
  $config['algorithm-type-name']='TradingBrain.S4B4A.S4B4AAlgorithm';$config['algorithm-language']='CSharp';$config['algorithm-location']=$dll
  $config['data-folder']=Join-Path $qc 'data/lean';$config['results-destination-folder']=$dir
  $config['object-store-root']=Join-Path $dir 'storage';$config['algorithm-id']=$id;$config['backtest-name']=$id
  $config['parameters']=@{'output-dir'=$dir;'raw-dir'=(Join-Path $i9 'data/native_raw');'daily-file'=(Join-Path $i9 'data/native_raw/bars_D1.csv');'end-date'=$endDate;
    'candidate-id'=$candidate;'run-id'=$id;'latency-ms'=[string]$LatencyMs;'protective-fill'=$ProtectiveFill;'commission-per-lot-side'=$CommissionPerLotSide.ToString([Globalization.CultureInfo]::InvariantCulture);
    'raw-ticks-dir'=(Join-Path $qc 'data/raw');'export-manifest'=$exportManifest;'export-manifest-sha256'=$expected.export_manifest}
  $config['transaction-log']=Join-Path $dir 'lean_transactions.csv';$config['log-file-handler']=Join-Path $dir 'engine.log';$config['log-file']=Join-Path $dir 'log.txt'
  $config['maximum-data-points-per-chart-series']=20000;$config['live-mode']=$false;$config['close-automatically']=$true;$config['python-venv']='';$config['job-project-id']=0
  $cfg=Join-Path $dir 'config.json';$config|ConvertTo-Json -Depth 14|Set-Content -LiteralPath $cfg -Encoding utf8
  $receipt.config_sha256=Sha $cfg;$receipt.end_date=$endDate;$receipt.status='RUNNING';Save
  Stage 'backtest' $id 'STARTED' $dir
  & (Join-Path $qc 'lean_bootstrap/run_lean.ps1') -ConfigPath $cfg -ConsoleLog (Join-Path $dir 'console.log')
  $resultPath=Join-Path $dir 'RESULT.json'
  if(-not (Test-Path -LiteralPath $resultPath)){throw 'Engine exited without RESULT.json'}
  $r=Get-Content -LiteralPath $resultPath -Raw|ConvertFrom-Json
  $receipt.result_sha256=Sha $resultPath;$receipt.ticks=$r.ticks;$receipt.result_status=$r.status
  Assert-SourcesUnchanged 'during the engine run'
  if((Sha $dll) -ne $receipt.dll_sha256){throw 'DLL changed during the engine run'}
  if($r.candidate_id -ne $candidate -or $r.run_id -ne $id -or $r.latency_ms -ne $LatencyMs){throw 'RESULT configuration mismatch'}
  if(-not $r.quote_adapter.aligned){throw 'Sidecar alignment failed'}
  if($r.quote_adapter.raw_rows_in_window_total -ne $expectRows -or $r.quote_adapter.lean_ticks_in_window -ne $expectRows){throw ('Row coverage mismatch: expected '+$expectRows)}
  if(-not $r.reconciliation.passed){throw 'LEAN/slot-ledger reconciliation failed'}
  $receipt.status=$(if($Mode -eq 'Smoke'){'SMOKE_PASS_REVIEW_REQUIRED'}else{'FULL_AUGUST_COMPLETE_REVIEW_REQUIRED'})
  Stage 'backtest' $id $receipt.status $resultPath
}catch{
  $receipt.status='FAILED';$receipt.error=$_.Exception.Message
  try{Stage $(if($Mode -eq 'Fixtures'){'test'}elseif($receipt.Contains('dll_sha256')){'backtest'}else{'compile'}) $id 'FAILED' $_.Exception.Message}catch{}
  throw
}finally{
  $receipt.completed_utc=[datetime]::UtcNow.ToString('o');Save
  if($isRun){ $reg=Read-Registry; foreach($x in $reg.runs){ if($x.id -eq $id){$x.status=$receipt.status} }; Save-Registry $reg }
  Write-Output ('S4B4A_DIR '+$dir+' STATUS '+$receipt.status)
}
