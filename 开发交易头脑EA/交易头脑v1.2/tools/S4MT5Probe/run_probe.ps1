#requires -Version 7.0
<#
S4 B3 MT5 probe runner (research/S4_B3_MT5_PROBE_SCOPE_CN.md). Written by Claude; Codex compiles/runs.
Adapted from repair_research/native_runner.ps1 (same fixed 523FF portable terminal, /portable launch,
no process termination, shared runner.lock + native_owner.json so the two runners exclude each other,
common.ini/terminal.ini backup and byte-verified restore, journal offsets). Tester-only probe EA.

Actions: Status | Compile | Prepare | Launch | Resume | Run(=Prepare+Launch)
Variants (main budget, each at most once): QUOTE_D0, ORDER_D0, ORDER_D250
Diagnostic re-runs: add -Diagnostic -DiagnosticReason "..." (at most 2 in total).
Every launch uses a NEW run directory; evidence is never overwritten.
#>
[CmdletBinding()]
param(
    [ValidateSet('Status','Compile','Prepare','Launch','Resume','Run')][string]$Action = 'Status',
    [string]$SessionDir,
    [ValidateSet('QUOTE_D0','ORDER_D0','ORDER_D250')][string]$Variant,
    [switch]$Diagnostic,
    [string]$DiagnosticReason = '',
    [string]$BuildManifestPath,
    [ValidateRange(0,86400)][int]$WaitSeconds = 30
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Tool = $PSScriptRoot
if (!$SessionDir) { $SessionDir = Join-Path ([IO.Path]::GetFullPath((Join-Path $script:Tool '..\..'))) 'mt5_probe_b3' }
$script:Terminal = 'C:\Users\A\AppData\Roaming\MetaQuotes\Terminal\523FF71FCA93BC15AC28868379E0D478'
$script:Main = 'S4MT5Probe.mq5'
$script:Binary = 'S4MT5Probe.ex5'
$script:Session = [IO.Path]::GetFullPath($SessionDir)
$script:Private = Join-Path $script:Session 'private'
$script:Active = Join-Path $script:Private 'active_launch.json'
$script:Registry = Join-Path $script:Session 'run_registry.json'
$script:Control = Join-Path $script:Terminal 'MQL5\Files\TradingBrain_AutoLab'   # shared with native_runner.ps1
$script:Owner = Join-Path $script:Control 'native_owner.json'                    # shared with native_runner.ps1
$script:Utf8 = [Text.UTF8Encoding]::new($false, $true)
$script:Lock = $null
# Registered scenario (scope): one server day, GOLD M5, real ticks, 500 USD, leverage 1:1000.
$script:Scenario = [ordered]@{ name='S4B3_AUG03'; symbol='GOLD'; period='M5'; model=4; from_date='2026.08.03'; to_date='2026.08.04'; deposit=500; currency='USD'; leverage=1000 }
$script:Variants = @{
    QUOTE_D0   = [ordered]@{ InpMode='0'; InpAllowTesterOrders='false'; delay=0 }
    ORDER_D0   = [ordered]@{ InpMode='1'; InpAllowTesterOrders='true';  delay=0 }
    ORDER_D250 = [ordered]@{ InpMode='1'; InpAllowTesterOrders='true';  delay=250 }
}

# ---------------------------------------------------------------- helpers (same semantics as native_runner.ps1)
function Full([string]$Path) { [IO.Path]::GetFullPath($Path) }
function Sha([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Bytes-Sha([byte[]]$Bytes) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant() }
function Assert-Within([string]$Path,[string]$Parent) {
    $p = (Full $Parent).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (!(Full $Path).StartsWith($p,[StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes allowed parent: $Path" }
}
function Assert-NoLink([string]$Path) { $i=Get-Item -LiteralPath $Path -Force; if (($i.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Reparse points are unsupported: $Path" } }
function Make-Dir([string]$Path) { [IO.Directory]::CreateDirectory($Path) | Out-Null }
function New-Dir([string]$Path) { if (Test-Path -LiteralPath $Path) { throw "Existing evidence directory refused: $Path" }; Make-Dir $Path }
function Read-Text([string]$Path) {
    $bytes=[IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254) { return [Text.Encoding]::Unicode.GetString($bytes,2,$bytes.Length-2) }
    if ($bytes.Length -gt 0 -and $bytes[0..([Math]::Min(99,$bytes.Length-1))] -contains 0) { return [Text.Encoding]::Unicode.GetString($bytes) }
    return $script:Utf8.GetString($bytes).TrimStart([char]0xFEFF)
}
function Read-Json([string]$Path) { ConvertFrom-Json -InputObject (Read-Text $Path) -AsHashtable }
function Write-NewText([string]$Path,[string]$Value,[Text.Encoding]$Encoding = $script:Utf8) {
    Make-Dir ([IO.Path]::GetDirectoryName($Path))
    $s=[IO.FileStream]::new($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $pre=$Encoding.GetPreamble(); $s.Write($pre); $s.Write($Encoding.GetBytes($Value)); $s.Flush($true) } finally { $s.Dispose() }
}
function Write-NewJson([string]$Path,$Value) { Write-NewText $Path ($Value | ConvertTo-Json -Depth 60) }
function Write-State([string]$Path,$Value) { $tmp=$Path+'.tmp_'+[Guid]::NewGuid().ToString('N'); Write-NewJson $tmp $Value; [IO.File]::Move($tmp,$Path,$true) }
function Copy-Evidence([string]$From,[string]$To) {
    Assert-NoLink $From
    if (Test-Path -LiteralPath $To) { if ((Sha $From) -ne (Sha $To)) { throw "Refusing changed existing evidence: $To" }; return }
    Make-Dir ([IO.Path]::GetDirectoryName($To)); [IO.File]::Copy($From,$To,$false)
    if ((Sha $From) -ne (Sha $To)) { throw "Copy identity mismatch: $To" }
}
function Verify-Terminal {
    Assert-NoLink $script:Terminal
    $origin=(Read-Text (Join-Path $script:Terminal 'origin.txt')).Trim()
    if ((Full $origin) -ine (Full 'C:\Program Files\FxPro - MetaTrader 5')) { throw 'Fixed terminal origin.txt identity mismatch' }
    foreach($n in @('terminal64.exe','metaeditor64.exe')) { $p=Join-Path $script:Terminal $n; if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw "Fixed portable executable missing: $n" }; Assert-NoLink $p }
}
function Native-Processes {
    foreach($item in @(Get-CimInstance Win32_Process -Filter "Name='terminal64.exe' OR Name='metaeditor64.exe'")) {
        $expected=Join-Path $script:Terminal $item.Name
        $exe=[string]$item.ExecutablePath; $cmd=[string]$item.CommandLine
        [ordered]@{pid=[int]$item.ProcessId;name=$item.Name;created=$(if($item.CreationDate){$item.CreationDate.ToUniversalTime().ToString('o')}else{''});executable=$exe
            fixed_terminal=([bool]$exe -and (Full $exe) -ieq (Full $expected));portable=$(if($cmd){$cmd -match '(?i)(?:^|\s)/portable(?:\s|$)'}else{$null});identity_verified=([bool]$exe -and [bool]$cmd)}
    }
}
function Assert-Idle { if (@(Native-Processes).Count) { throw 'WAITING: MT5 or MetaEditor is open; close it normally. No process is terminated.' } }
function Checkpoint($Record) {
    Write-State $script:Active $Record
    Write-State $script:Owner @{active_record=$script:Active;session_dir=$script:Session;token=$Record.token;runner='s4_mt5_probe_v1'}
}
function Archive($Record,$Result) {
    $Record.result=$Result
    Write-NewJson (Join-Path $script:Private ('history\'+$Record.token+'_'+[Guid]::NewGuid().ToString('N')+'.json')) $Record
    [IO.File]::Delete($script:Active)
    if (Test-Path -LiteralPath $script:Owner) { $o=Read-Json $script:Owner; if ($o.active_record -ieq $script:Active) { [IO.File]::Delete($script:Owner) } }
}
function Source-Manifest([string]$Root) {
    $files=[ordered]@{}; $names=[Collections.Generic.List[string]]::new()
    foreach($f in Get-ChildItem -LiteralPath $Root -File -Force) { Assert-NoLink $f.FullName; if ($f.Extension -ieq '.mq5' -or $f.Extension -ieq '.mqh') { $names.Add($f.Name) } }
    if (!$names.Contains($script:Main)) { throw "Missing $script:Main" }
    $arr=$names.ToArray(); [Array]::Sort($arr,[StringComparer]::Ordinal); $id=[Text.StringBuilder]::new()
    foreach($n in $arr) { $d=Sha (Join-Path $Root $n); $files[$n]=$d; [void]$id.Append($n).Append([char]0).Append($d).Append("`n") }
    @{sha256=(Bytes-Sha $script:Utf8.GetBytes($id.ToString()));files=$files}
}
function Registry { if (Test-Path -LiteralPath $script:Registry) { Read-Json $script:Registry } else { @{runs=@()} } }
function Save-Registry($Reg) { Write-State $script:Registry $Reg }

# ---------------------------------------------------------------- native process launch/resume
function Start-Native([string]$Exe,[string[]]$Arguments,$Record) {
    Assert-Idle
    $Record.phase='LAUNCHING'; $Record.started_utc=[datetime]::UtcNow.ToString('o'); Checkpoint $Record
    $p=Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $script:Terminal -WindowStyle Hidden -PassThru
    $Record.pid=$p.Id; $Record.process_created=$p.StartTime.ToUniversalTime().ToString('o'); $Record.phase='RUNNING'; Checkpoint $Record
    $found=@(Native-Processes | Where-Object { $_.pid -eq $p.Id })
    if ($found.Count -and $found[0].identity_verified -and (!$found[0].fixed_terminal -or !$found[0].portable)) { throw 'Native process routing verification failed; checkpoint retained, no termination' }
    $Record.process_identity=$(if($found.Count){$found[0]}else{'PENDING_OBSERVATION'}); Checkpoint $Record
}
function Resume-Native {
    if (!(Test-Path -LiteralPath $script:Active)) { return @{status='IDLE'} }
    $r=Read-Json $script:Active
    if ($r.phase -eq 'PREPARED') { return @{status='PREPARED';run_dir=$r.run_dir} }
    if ($r.phase -eq 'RESTORE_FAILED') { Assert-Idle }   # retry restoration below; launches stay blocked by the retained checkpoint
    $name=if($r.kind -eq 'compile'){'metaeditor64.exe'}else{'terminal64.exe'}
    if (@(Native-Processes | Where-Object { $_.pid -eq $r.pid -or $_.name -ieq $name }).Count) { return @{status='PENDING';pid=$r.pid;kind=$r.kind} }
    Assert-Idle
    if ($r.kind -eq 'tester' -and !$r.configs_restored) {
        try { Restore-Configs $r }
        catch {
            # Never Archive here: the checkpoint and owner file are the only recovery entry. New launches remain blocked.
            $r.phase='RESTORE_FAILED'; $r.restore_error=$_.Exception.Message; $r.restore_failed_utc=[datetime]::UtcNow.ToString('o'); Checkpoint $r
            return [ordered]@{status='RESTORE_FAILED';reason=$r.restore_error;active_record=$script:Active;note='checkpoint and owner retained; fix and run -Action Resume to re-verify restoration'}
        }
    }
    try {
        $result=if($r.kind -eq 'compile'){Finish-Compile $r}else{Collect-Probe $r}
        Archive $r $result; return $result
    } catch {
        $result=[ordered]@{status=$(if($r.kind -eq 'compile'){'COMPILE_FAILED'}else{'FAILED'});reason=$_.Exception.Message;token=$r.token;configs_restored=$(if($r.kind -eq 'tester'){$r.configs_restored}else{$null});failed_utc=[datetime]::UtcNow.ToString('o')}
        if ($r.kind -eq 'tester') { $p=Join-Path $r.run_dir 'probe_result.json'; if (!(Test-Path -LiteralPath $p)) { Write-NewJson $p $result }; Update-Registry $r $result.status }
        Archive $r $result; return $result
    }
}
function Wait-AndResume {
    $deadline=[datetime]::UtcNow.AddSeconds($WaitSeconds)
    do { $res=Resume-Native; if ($res.status -notin @('PENDING','RUNNING')) { return $res }; if ([datetime]::UtcNow -ge $deadline) { return $res }; Start-Sleep -Milliseconds 1000 } while($true)
}

# ---------------------------------------------------------------- compile: frozen source copy -> fresh warning-free EX5
function Compile-Probe {
    if (Test-Path -LiteralPath $script:Active) { throw 'An active launch requires Resume first' }
    Assert-Idle
    $manifest=Source-Manifest $script:Tool; $token=[Guid]::NewGuid().ToString('N')
    $buildDir=Join-Path $script:Private ('builds\'+$token); New-Dir $buildDir
    foreach($n in $manifest.files.Keys) { Copy-Evidence (Join-Path $script:Tool $n) (Join-Path $buildDir $n) }
    if ((Source-Manifest $buildDir).sha256 -ne $manifest.sha256) { throw 'Source changed during copy' }
    Write-NewJson (Join-Path $buildDir 'source_manifest.json') $manifest
    $rec=[ordered]@{kind='compile';phase='PREPARED';token=$token;pid=$null;started_utc=[datetime]::UtcNow.ToString('o');build_dir=$buildDir;source_sha256=$manifest.sha256}
    Checkpoint $rec
    Start-Native (Join-Path $script:Terminal 'metaeditor64.exe') @('/portable',('/compile:"'+(Join-Path $buildDir $script:Main)+'"'),('/log:"'+(Join-Path $buildDir 'compile.log')+'"'),('/inc:"'+(Join-Path $script:Terminal 'MQL5')+'"')) $rec
    Wait-AndResume
}
function Finish-Compile($r) {
    $log=Join-Path $r.build_dir 'compile.log'; $ex5=Join-Path $r.build_dir $script:Binary
    foreach($p in @($log,$ex5)) {
        if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw 'Fresh compiler log and EX5 required' }
        $i=Get-Item -LiteralPath $p; if ($i.Length -eq 0 -or $i.LastWriteTimeUtc -lt ([datetime]$r.started_utc).ToUniversalTime().AddSeconds(-2)) { throw 'Compile output missing, empty or stale' }
    }
    $m=[regex]::Matches((Read-Text $log),'(?i)\b(\d+)\s+errors?\s*,\s*(\d+)\s+warnings?\b')
    if (!$m.Count -or $m[-1].Groups[1].Value -ne '0' -or $m[-1].Groups[2].Value -ne '0') { throw 'MetaEditor did not report 0 errors, 0 warnings' }
    if ((Source-Manifest $r.build_dir).sha256 -ne $r.source_sha256) { throw 'Source changed during compilation' }
    $b=[ordered]@{status='COMPLETE';build_dir=$r.build_dir;ex5=$ex5;compile_log=$log;source_sha256=$r.source_sha256;ex5_sha256=(Sha $ex5);compile_log_sha256=(Sha $log);errors=0;warnings=0;compiled_at=[datetime]::UtcNow.ToString('o')}
    Write-NewJson (Join-Path $r.build_dir 'build.json') $b; $b
}
function Validate-Build($b) {
    if ($b.status -ne 'COMPLETE' -or $b.errors -ne 0 -or $b.warnings -ne 0) { throw 'Build not warning-free COMPLETE' }
    Assert-Within $b.build_dir (Join-Path $script:Private 'builds')
    if ((Source-Manifest $b.build_dir).sha256 -ne $b.source_sha256 -or (Sha $b.ex5) -ne $b.ex5_sha256 -or (Sha $b.compile_log) -ne $b.compile_log_sha256) { throw 'Compiled build hash mismatch' }
    if ((Source-Manifest $script:Tool).sha256 -ne $b.source_sha256) { throw 'Current tool source differs from the frozen build; recompile' }
    $b
}

# ---------------------------------------------------------------- config backup/restore (byte-verified)
function Backup-Configs($r) {
    Assert-Idle; $root=Join-Path $script:Private ('backups\'+$r.token); New-Dir $root; $e=@()
    foreach($n in @('common.ini','terminal.ini')) { $o=Join-Path $script:Terminal ('config\'+$n); $b=Join-Path $root $n; Copy-Evidence $o $b; $e+=@{name=$n;backup=$b;sha256=(Sha $b)} }
    Write-NewJson (Join-Path $root 'backup_receipt.json') @{token=$r.token;created_utc=[datetime]::UtcNow.ToString('o');files=$e}; $e
}
function Restore-Configs($r) {
    Assert-Idle
    if (@($r.backups).Count -ne 2) { throw 'Config backups incomplete' }
    $receipt=@()
    foreach($e in $r.backups) {
        Assert-Within $e.backup (Join-Path $script:Private ('backups\'+$r.token)); if ((Sha $e.backup) -ne $e.sha256) { throw 'Config backup SHA mismatch' }
        $dst=Join-Path $script:Terminal ('config\'+$e.name); $before=if(Test-Path -LiteralPath $dst){Sha $dst}else{''}
        $tmp=$dst+'.s4probe_'+$r.token; if (Test-Path -LiteralPath $tmp) { throw 'Unexpected restore temp file' }
        [IO.File]::Copy($e.backup,$tmp,$false); [IO.File]::Move($tmp,$dst,$true)
        $after=Sha $dst; if ($after -ne $e.sha256) { throw 'Restored config SHA mismatch' }
        $receipt+=@{name=$e.name;backup_sha256=$e.sha256;before_restore_sha256=$before;restored_sha256=$after;byte_identical=$true}
    }
    $r.configs_restored=$true; $r.restore_receipt=$receipt; Checkpoint $r
}

# ---------------------------------------------------------------- journal (bounded tail since launch)
function Journal-Paths {
    $t=Join-Path $script:Terminal 'Tester'; $roots=@((Join-Path $t 'logs'))
    if (Test-Path -LiteralPath $t) { foreach($a in Get-ChildItem -LiteralPath $t -Directory -Filter 'Agent-*') { Assert-NoLink $a.FullName; $roots+=Join-Path $a.FullName 'logs' } }
    foreach($x in $roots) { if (Test-Path -LiteralPath $x) { foreach($f in Get-ChildItem -LiteralPath $x -File -Filter '*.log') { $f.FullName } } }
}
function Read-Shared([string]$Path,[long]$Offset,[long]$Count) {
    $s=[IO.FileStream]::new($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try { [void]$s.Seek($Offset,[IO.SeekOrigin]::Begin); $b=[byte[]]::new([int]$Count); $t=0; while($t -lt $b.Length){$n=$s.Read($b,$t,$b.Length-$t); if(!$n){break}; $t+=$n}; if($t -ne $Count){throw 'Journal changed during read'}; ,$b } finally { $s.Dispose() }
}
function Journal-Snapshot { $h=@{}; foreach($p in Journal-Paths){ $h[$p]=(Get-Item -LiteralPath $p).Length }; $h }
function Journal-Tail($r) {
    $parts=[Collections.Generic.List[string]]::new()
    foreach($p in Journal-Paths) {
        $size=(Get-Item -LiteralPath $p).Length; $off=if($r.journal_before.Contains($p)){[long]$r.journal_before[$p]}else{0}
        if ($size -lt $off -or $size-$off -gt 32MB) { throw 'Journal rotated or tail too large' }
        if ($size -eq $off) { continue }
        $head=Read-Shared $p 0 ([Math]::Min(64,$size)); $bytes=Read-Shared $p $off ($size-$off)
        $enc=if(($head.Length -ge 2 -and $head[0] -eq 255 -and $head[1] -eq 254) -or $head -contains 0){[Text.UnicodeEncoding]::new($false,$false,$true)}else{$script:Utf8}
        $parts.Add($enc.GetString($bytes).TrimStart([char]0xFEFF))
    }
    $parts -join "`n"
}

# ---------------------------------------------------------------- prepare/launch one registered variant
function Prepare-Probe {
    if (Test-Path -LiteralPath $script:Active) { throw 'Existing checkpoint requires Resume first' }
    if (!$Variant) { throw 'Variant is required' }
    if (!$BuildManifestPath) { throw 'BuildManifestPath of a fresh warning-free Compile is required' }
    $build=Validate-Build (Read-Json (Full $BuildManifestPath))
    $reg=Registry; $runs=@($reg.runs)
    $main=@($runs | Where-Object { !$_.diagnostic }); $diag=@($runs | Where-Object { $_.diagnostic })
    if ($Diagnostic) {
        if ($DiagnosticReason.Trim().Length -lt 10) { throw 'Diagnostic runs require -DiagnosticReason (>=10 chars)' }
        if ($diag.Count -ge 2) { throw 'Diagnostic budget (2) exhausted' }
        if (!@($main | Where-Object { $_.variant -eq $Variant }).Count) { throw 'A diagnostic re-run requires the main run of the same variant first' }
    } elseif (@($main | Where-Object { $_.variant -eq $Variant }).Count) { throw "Main run for $Variant already used; use -Diagnostic with a reason" }
    Assert-Idle
    $v=$script:Variants[$Variant]; $token=[Guid]::NewGuid().ToString('N')
    $label='S4B3_'+$Variant+'_'+$token.Substring(0,12)
    $run=Join-Path $script:Session ('runs\'+$label); New-Dir $run
    $set=[ordered]@{InpMode=$v.InpMode;InpAllowTesterOrders=$v.InpAllowTesterOrders;InpRunLabel=$label;InpDeclaredDelayMs=[string]$v.delay}
    $setText=(($set.Keys | ForEach-Object { $_+'='+$set[$_] }) -join "`r`n")+"`r`n"
    $expert=Join-Path $script:Terminal ('MQL5\Experts\S4MT5Probe\'+$token); New-Dir $expert
    Copy-Evidence (Join-Path $build.build_dir $script:Main) (Join-Path $expert $script:Main); Copy-Evidence $build.ex5 (Join-Path $expert $script:Binary)
    $setName='S4MT5Probe_'+$token+'.set'; $setPath=Join-Path $script:Terminal ('MQL5\Profiles\Tester\'+$setName)
    Write-NewText $setPath $setText ([Text.Encoding]::Unicode); Copy-Evidence $setPath (Join-Path $run 'effective.set')
    $compiled=Join-Path $run 'compiled'; New-Dir $compiled
    Copy-Evidence $build.ex5 (Join-Path $compiled $script:Binary); Copy-Evidence $build.compile_log (Join-Path $compiled 'compile.log'); Copy-Evidence (Join-Path $build.build_dir $script:Main) (Join-Path $compiled $script:Main)
    $s=$script:Scenario; $reportRel='S4MT5Probe_Reports\'+$token+'.html'; $reportSrc=Join-Path $script:Terminal $reportRel
    Make-Dir ([IO.Path]::GetDirectoryName($reportSrc)); if (Test-Path -LiteralPath $reportSrc) { throw 'Unique report already exists' }
    $expertRel='S4MT5Probe\'+$token+'\'+$script:Binary
    $ini=@('[Common]',('Profile=S4MT5Probe_NoCharts_'+$token),'[Experts]','Enabled=0','AllowLiveTrading=0','AllowDllImport=0','[Tester]',('Expert='+$expertRel),('ExpertParameters='+$setName),
        ('Symbol='+$s.symbol),('Period='+$s.period),('Model='+$s.model),('ExecutionMode='+$v.delay),'Optimization=0',('FromDate='+$s.from_date),('ToDate='+$s.to_date),'ForwardMode=0',
        ('Deposit='+$s.deposit),('Currency='+$s.currency),('Leverage=1:'+$s.leverage),'Visual=0','UseLocal=1','UseRemote=0','UseCloud=0',('Report='+$reportRel),'ReplaceReport=0','ShutdownTerminal=1') -join "`r`n"
    $config=Join-Path $script:Private ('launches\'+$token+'\tester.ini'); Write-NewText $config ($ini+"`r`n") ([Text.Encoding]::Unicode); Copy-Evidence $config (Join-Path $run 'tester.ini')
    Write-NewJson (Join-Path $run 'scenario.json') ([ordered]@{scenario=$s;variant=$Variant;execution_delay_ms_requested=$v.delay;diagnostic=[bool]$Diagnostic;diagnostic_reason=$DiagnosticReason})
    $rec=[ordered]@{kind='tester';phase='PREPARED';token=$token;pid=$null;run_dir=$run;run_label=$label;variant=$Variant;diagnostic=[bool]$Diagnostic;diagnostic_reason=$DiagnosticReason;delay=$v.delay
        source_sha256=$build.source_sha256;ex5_sha256=$build.ex5_sha256;compile_log_sha256=$build.compile_log_sha256;set_path=$setPath;set_sha256=(Sha $setPath);config=$config;config_sha256=(Sha $config)
        expert_dir=$expert;expert_relative=$expertRel;report_source=$reportSrc;configs_restored=$false;main_mq5_sha256=(Sha (Join-Path $build.build_dir $script:Main))}
    Checkpoint $rec; Write-NewJson (Join-Path $run 'launch_identity.json') $rec
    $runs+=@{variant=$Variant;diagnostic=[bool]$Diagnostic;reason=$DiagnosticReason;run_dir=$run;label=$label;status='PREPARED';utc=[datetime]::UtcNow.ToString('o')}
    $reg.runs=$runs; Save-Registry $reg
    @{status='PREPARED';run_dir=$run;run_label=$label;variant=$Variant}
}
function Update-Registry($r,[string]$Status) { $reg=Registry; foreach($x in $reg.runs){ if($x.label -eq $r.run_label){$x.status=$Status;$x.completed_utc=[datetime]::UtcNow.ToString('o')} }; Save-Registry $reg }
function Launch-Probe {
    if (!(Test-Path -LiteralPath $script:Active)) { throw 'No prepared probe launch' }
    $r=Read-Json $script:Active
    if ($r.kind -ne 'tester' -or $r.phase -ne 'PREPARED') { throw 'Launch requires a PREPARED tester checkpoint' }
    Assert-Idle
    if ((Sha $r.config) -ne $r.config_sha256 -or (Sha $r.set_path) -ne $r.set_sha256 -or (Sha (Join-Path $r.expert_dir $script:Binary)) -ne $r.ex5_sha256) { throw 'Prepared artifact hash mismatch' }
    if ((Source-Manifest $r.expert_dir).sha256 -ne $r.source_sha256 -or (Sha (Join-Path $r.expert_dir $script:Main)) -ne $r.main_mq5_sha256) { throw 'Installed MQ5 source differs from the frozen build source (source/EX5 identity)' }
    if ((Source-Manifest (Join-Path $r.run_dir 'compiled')).sha256 -ne $r.source_sha256 -or (Sha (Join-Path $r.run_dir ('compiled\'+$script:Binary))) -ne $r.ex5_sha256) { throw 'Run evidence copy differs from the frozen build' }
    $r.backups=@(Backup-Configs $r); $r.journal_before=Journal-Snapshot; $r.agent_dirs_before=@(Probe-OutputDirs | ForEach-Object { $_ })
    Checkpoint $r
    Start-Native (Join-Path $script:Terminal 'terminal64.exe') @('/portable',('/config:"'+$r.config+'"')) $r
    Wait-AndResume
}

# ---------------------------------------------------------------- collect + completion checks (not just process exit)
function Probe-OutputDirs {
    $t=Join-Path $script:Terminal 'Tester'
    if (Test-Path -LiteralPath $t) { foreach($a in Get-ChildItem -LiteralPath $t -Directory -Filter 'Agent-*') { $root=Join-Path $a.FullName 'MQL5\Files\S4MT5Probe'; if (Test-Path -LiteralPath $root) { foreach($d in Get-ChildItem -LiteralPath $root -Directory) { Assert-NoLink $d.FullName; $d.FullName } } } }
}
function Read-KeyValue([string]$Path) { $h=@{}; foreach($row in Import-Csv -LiteralPath $Path) { $h[$row.key]=$row.value }; $h }
function Collect-Probe($r) {
    $saved=Join-Path $r.run_dir 'probe_result.json'; if (Test-Path -LiteralPath $saved) { return Read-Json $saved }
    if (!$r.configs_restored) { throw 'Configs not restored' }
    $dirs=@(Probe-OutputDirs | Where-Object { (Split-Path $_ -Leaf) -ceq $r.run_label })
    if ($dirs.Count -ne 1) { throw "Expected exactly one probe output dir for $($r.run_label); found $($dirs.Count)" }
    $out=Join-Path $r.run_dir 'probe_output'; New-Dir $out; $hashes=[ordered]@{}
    foreach($n in @('meta.csv','quotes.csv','orders.csv','transactions.csv','summary.csv')) {
        $src=Join-Path $dirs[0] $n; if (!(Test-Path -LiteralPath $src -PathType Leaf)) { throw "Probe output missing: $n (OnTester/OnDeinit may not have completed)" }
        Copy-Evidence $src (Join-Path $out $n); $hashes['probe_output/'+$n]=Sha (Join-Path $out $n)
    }
    $meta=Read-KeyValue (Join-Path $out 'meta.csv'); $sum=Read-KeyValue (Join-Path $out 'summary.csv')
    $v=$script:Variants[$r.variant]; $expectMode=if($v.InpMode -eq '1'){'PROBE_ORDER'}else{'PROBE_QUOTE_ONLY'}
    $orders=@(Import-Csv -LiteralPath (Join-Path $out 'orders.csv')); $tx=@(Import-Csv -LiteralPath (Join-Path $out 'transactions.csv'))
    if (!(Test-Path -LiteralPath $r.report_source -PathType Leaf)) { throw 'Fresh tester HTML report is required' }
    $rep=Get-Item -LiteralPath $r.report_source
    if ($rep.Length -eq 0 -or $rep.LastWriteTimeUtc -lt ([datetime]$r.started_utc).ToUniversalTime().AddSeconds(-2)) { throw 'Tester report empty or stale' }
    $repDir=Join-Path $r.run_dir 'report'; Make-Dir $repDir; Copy-Evidence $rep.FullName (Join-Path $repDir $rep.Name); $hashes['report/'+$rep.Name]=Sha (Join-Path $repDir $rep.Name)
    foreach($img in Get-ChildItem -LiteralPath $rep.DirectoryName -File -Filter ($r.token+'*.png')) { Copy-Evidence $img.FullName (Join-Path $repDir $img.Name); $hashes['report/'+$img.Name]=Sha (Join-Path $repDir $img.Name) }
    $journal=Journal-Tail $r
    $selected=@($journal -split '\r?\n' | Where-Object { ($_ -match 'GOLD' -or $_.Contains($r.run_label) -or $_.Contains('S4B3_PROBE') -or $_ -match '(?i)delay|execution|automatic testing finished') -and $_ -notmatch '(?i)password|login\s*[=:]|authorization|token\s*[=:]|account\s*#' })
    Write-NewText (Join-Path $r.run_dir 'tester_journal.log') (($selected -join "`n")+"`n"); $hashes['tester_journal.log']=Sha (Join-Path $r.run_dir 'tester_journal.log')
    $html=[Net.WebUtility]::HtmlDecode([regex]::Replace((Read-Text $rep.FullName),'<[^>]+>',' ')); $flat=[regex]::Replace($html,'\s+',' ')
    $s=$script:Scenario; $start="GOLD,M5: testing of Experts\$($r.expert_relative) from $($s.from_date) 00:00 to $($s.to_date) 00:00"
    $delayLines=@($selected | Where-Object { $_ -match '(?i)delay' })
    $checks=[ordered]@{
        on_tester_called=($sum.on_tester_called -eq '1')
        normal_end_ontester_before_deinit=($meta.Contains('deinit_reason') -and $meta.on_tester_called_before_deinit -eq '1')
        ontick_calls_positive=($sum.Contains('ontick_calls') -and [long]$sum.ontick_calls -gt 0)
        summary_label_matches=($sum.run_label -ceq $r.run_label -and $meta.run_label -ceq $r.run_label)
        summary_mode_matches_variant=($sum.mode -ceq $expectMode -and $meta.mode -ceq $expectMode)
        meta_tester_flag=($meta.tester -eq '1')
        meta_leverage_1000=($meta.account_leverage -eq '1000')
        quote_rows_logged=([long]$sum.quote_rows_logged -gt 0)
        quote_only_has_no_orders_or_transactions=$(if($expectMode -eq 'PROBE_QUOTE_ONLY'){$orders.Count -eq 0 -and $tx.Count -eq 0}else{$true})
        no_open_probe_position_at_ontester=($sum.open_probe_positions_at_ontester -eq '0')
        no_unknown_exit=($sum.exit_blocked_unknown -eq '0')
        single_day_window=($sum.first_fresh_time_msc -and [long]$sum.first_fresh_time_msc -ge 1785715200000 -and [long]$sum.last_fresh_time_msc -lt 1785801600000)

        journal_expert_dates_symbol=($journal.Contains($start,[StringComparison]::OrdinalIgnoreCase))
        journal_real_ticks=($journal -match '(?i)generating based on real ticks')
        journal_test_passed=($journal -match '(?i)Test passed')
        journal_no_tick_fallback=($journal -notmatch '(?i)no real ticks|generated ticks|tick data[^\r\n]*(?:missing|not found|unavailable)')
        tester_ini_execution_mode_matches_variant=((Read-Text $r.config) -match ('(?m)^ExecutionMode='+$r.delay+'\r?$'))
        configs_restored_byte_identical=($r.configs_restored -and @($r.restore_receipt | Where-Object { !$_.byte_identical }).Count -eq 0)
    }
    foreach($n in @('effective.set','scenario.json','tester.ini','launch_identity.json')) { $hashes[$n]=Sha (Join-Path $r.run_dir $n) }
    $ok=@($checks.Values | Where-Object { !$_ }).Count -eq 0
    $result=[ordered]@{status=$(if($ok){'COMPLETE_REVIEW_REQUIRED'}else{'COMPLETED_WITH_FAILED_CHECKS'});variant=$r.variant;diagnostic=$r.diagnostic;diagnostic_reason=$r.diagnostic_reason;run_label=$r.run_label
        source_sha256=$r.source_sha256;ex5_sha256=$r.ex5_sha256;set_sha256=$r.set_sha256;config_sha256=$r.config_sha256;checks=$checks
        diagnostics_not_pass_criteria=[ordered]@{report_history_quality_100pct=($flat -match '(?i)(?:History Quality|质量历史|历史质量)\s*[:：]?\s*100(?:\.0+)?%');note='History Quality is a report figure only; it does not prove actual tick coverage. Real-tick mode, journal and fallback checks are listed separately in checks.'}
        delay_evidence=[ordered]@{requested_execution_mode_ms=$r.delay;journal_lines_mentioning_delay=$delayLines;status=$(if($delayLines.Count){'JOURNAL_LINES_FOUND_REVIEW_REQUIRED'}else{'DELAY_NOT_CONFIRMED_BY_JOURNAL_REVIEW_REQUIRED'});note='InpDeclaredDelayMs is a label only; the requested ExecutionMode is in tester.ini; actual delay behaviour needs journal/order evidence review'}
        restore_receipt=$r.restore_receipt;evidence_sha256=$hashes;summary=$sum;probe_pnl_note='by-product of evidence collection; not a strategy result; score N/A';completed_utc=[datetime]::UtcNow.ToString('o')}
    Write-NewJson $saved $result; Update-Registry $r $result.status; $result
}

# ---------------------------------------------------------------- main
try {
    Verify-Terminal
    if ($Action -eq 'Status') {
        $a=if(Test-Path -LiteralPath $script:Active){Read-Json $script:Active}else{$null}
        $result=@{status=$(if($a){$a.phase}else{'IDLE'});kind=$(if($a){$a.kind}else{$null});registry=(Registry);processes=@(Native-Processes)}
    } else {
        Make-Dir $script:Private; Make-Dir $script:Control
        try { $script:Lock=[IO.FileStream]::new((Join-Path $script:Control 'runner.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) } catch { throw 'WAITING: another native runner owns the terminal lock' }
        if (Test-Path -LiteralPath $script:Owner) { $o=Read-Json $script:Owner; if ($o.active_record -ine $script:Active -and (Test-Path -LiteralPath $o.active_record)) { throw 'Another session has an unfinished native launch; resume its owner first' } }
        switch ($Action) {
            'Compile' { $result=Compile-Probe }
            'Prepare' { $result=Prepare-Probe }
            'Launch'  { $result=Launch-Probe }
            'Resume'  { $result=Wait-AndResume }
            'Run'     { $result=Prepare-Probe; if ($result.status -eq 'PREPARED') { $result=Launch-Probe } }
        }
    }
    $result | ConvertTo-Json -Depth 60
    if ($result.status -in @('FAILED','COMPILE_FAILED','RESTORE_FAILED')) { exit 1 }
} catch {
    [ordered]@{status=$(if($_.Exception.Message.StartsWith('WAITING:')){'WAITING'}else{'ERROR'});reason=$_.Exception.Message;line=$_.InvocationInfo.ScriptLineNumber} | ConvertTo-Json
    exit 1
} finally { if ($null -ne $script:Lock) { $script:Lock.Dispose() } }
