#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$LeanRoot = '',
    [string]$OutputRoot = '',
    [switch]$BuildEngine
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$commit = '985ef30ad3ac774218c5ac516b4cb0aa2655730f'
$quoteBlob = '2c0675003e21c8f1310914701053cc22157cc52d'
$culture = [Globalization.CultureInfo]::InvariantCulture
$original = Get-Location
$receiptPath = $null
$code = 1
$state = [ordered]@{version='1.0.0';status='RUNNING';source='NOT_STARTED';data='NOT_STARTED';compile='NOT_STARTED';backtests=@();error=$null;live='DISABLED';mt5='NOT_ACCESSED'}
function Save-State { if ($script:receiptPath) { $script:state | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $script:receiptPath -Encoding UTF8 } }
function Native([string]$Exe,[string[]]$ArgumentList,[string]$LogPath='') {
    Write-Host ('> ' + $Exe + ' ' + ($ArgumentList -join ' '))
    $old = $ErrorActionPreference
    try { $ErrorActionPreference='Continue'; $output=@(& $Exe @ArgumentList 2>&1); $exit=$LASTEXITCODE }
    finally { $ErrorActionPreference=$old }
    $text=($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ($LogPath) { $text | Set-Content -LiteralPath $LogPath -Encoding UTF8 }
    Write-Host $text
    if ($exit -ne 0) { throw ('Command failed ('+$exit+'): '+$Exe) }
    return $text
}
function Write-Json($Object,[string]$Path) { $Object | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8 }
function Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Audit-Quotes([string]$ZipPath,[string]$AuditPath) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $bytes=[IO.File]::ReadAllBytes($ZipPath)
    $prefix=[Text.Encoding]::ASCII.GetBytes('blob '+$bytes.Length+[char]0)
    $sha=[Security.Cryptography.SHA1]::Create()
    try { $actualBlob=([BitConverter]::ToString($sha.ComputeHash([byte[]]($prefix+$bytes)))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
    if ($actualBlob -ne $script:quoteBlob) { throw 'XAUUSD sample differs from the pinned upstream data. No silent data substitution.' }
    $archive=[IO.Compression.ZipFile]::OpenRead($ZipPath)
    $first=$null; $last=$null; $count=0; $duplicates=0; $outOfOrder=0; $badQuotes=0; $zeroSpreads=0
    $fieldCounts=@{}; $gaps=New-Object 'System.Collections.Generic.List[object]'
    $allTimes=New-Object 'System.Collections.Generic.List[datetime]'
    try {
        $entries=@($archive.Entries | Where-Object { $_.Name.EndsWith('.csv') })
        if ($entries.Count -ne 1) { throw 'Expected one historical XAUUSD CSV in the hourly archive.' }
        $reader=New-Object IO.StreamReader($entries[0].Open())
        try {
            while ($null -ne ($line=$reader.ReadLine())) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts=$line.Split(',')
                $t=[DateTime]::ParseExact($parts[0],'yyyyMMdd HH:mm',$script:culture)
                $key=[string]$parts.Length
                if (-not $fieldCounts.ContainsKey($key)) { $fieldCounts[$key]=0 }; $fieldCounts[$key]++
                if ($null -eq $first) { $first=$t }
                if ($null -ne $last) {
                    if ($t -eq $last) { $duplicates++ }
                    if ($t -lt $last) { $outOfOrder++ }
                    if (($t-$last).TotalHours -gt 2) { $gaps.Add(@{after=$last.ToString('s');before=$t.ToString('s');hours=($t-$last).TotalHours}) }
                }
                if ($parts.Length -eq 11) {
                    $bo=[decimal]::Parse($parts[1],$script:culture); $bh=[decimal]::Parse($parts[2],$script:culture)
                    $bl=[decimal]::Parse($parts[3],$script:culture); $bc=[decimal]::Parse($parts[4],$script:culture)
                    $ao=[decimal]::Parse($parts[6],$script:culture); $ah=[decimal]::Parse($parts[7],$script:culture)
                    $al=[decimal]::Parse($parts[8],$script:culture); $ac=[decimal]::Parse($parts[9],$script:culture)
                    if ($bc -le 0 -or $ac -lt $bc -or $bh -lt [Math]::Max($bo,$bc) -or $bl -gt [Math]::Min($bo,$bc) -or
                        $ah -lt [Math]::Max($ao,$ac) -or $al -gt [Math]::Min($ao,$ac)) { $badQuotes++ }
                    if ($bc -eq $ac) { $zeroSpreads++ }
                }
                $last=$t; $count++; $allTimes.Add($t)
            }
        } finally { $reader.Dispose() }
    } finally { $archive.Dispose() }
    if ($count -lt 1000 -or $duplicates -gt 0 -or $outOfOrder -gt 0 -or $badQuotes -gt 0) { throw 'Historical data audit failed; see data source rather than replacing it with synthetic prices.' }
    # Choose by coverage only, before inspecting strategy returns. Last day is discarded as potentially partial.
    $end=$last.Date
    $start=$end.AddYears(-2)
    if ($start -lt $first.Date.AddDays(14)) { $start=$first.Date.AddDays(14) }
    if (($end-$start).TotalDays -lt 90) { throw 'Insufficient hourly sample for this research batch.' }
    $selected=@($allTimes | Where-Object { $_ -ge $start -and $_ -lt $end })
    $audit=[ordered]@{
        source='QuantConnect/Lean official repository bundled XAUUSD sample; OANDA-derived CFD quotes'
        upstream_commit=$script:commit;git_blob_sha1=$actualBlob;sha256=(Hash $ZipPath)
        resolution='H1';timestamp_field='Bar start in the LEAN data-file timezone, not assumed UTC'
        first_bar_start=$first.ToString('s');last_bar_start=$last.ToString('s');total_rows=$count
        column_counts=$fieldCounts;duplicate_timestamps=$duplicates;out_of_order=$outOfOrder;bad_ohlc_or_crossed_closes=$badQuotes
        zero_close_spread_rows=$zeroSpreads;gaps_gt_2h=$gaps;gap_note='Includes market closures/weekends; not a trading-calendar completeness certificate.'
        start_date=$start.ToString('yyyy-MM-dd');end_exclusive=$end.ToString('yyyy-MM-dd');selected_rows=$selected.Count
        selected_first_bar=$selected[0].ToString('s');selected_last_bar=$selected[-1].ToString('s')
        selection_rule='Latest available 24 calendar months, excluding last possibly partial date; no profit-based period selection.'
        limitations=@('Historical bundled data, not current market feed','Not FxPro data','Not real ticks','No historical news/calendar/USD correlation inputs','No synthetic fill-forward data')
    }
    Write-Json $audit $AuditPath
    return $audit
}
try {
    if (-not $LeanRoot) {
        $profileHome=$env:USERPROFILE
        if (-not $profileHome) { $profileHome=$HOME }
        $LeanRoot=Join-Path (Join-Path $profileHome 'QuantConnect-LEAN-Local') 'Lean'
    }
    $LeanRoot=[IO.Path]::GetFullPath($LeanRoot)
    if (-not $OutputRoot) { $OutputRoot=Join-Path (Split-Path -Parent $LeanRoot) ('gold-research-runs/'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,6)) }
    $OutputRoot=[IO.Path]::GetFullPath($OutputRoot)
    if (Test-Path -LiteralPath $OutputRoot) {
        if (@(Get-ChildItem -LiteralPath $OutputRoot -Force).Count -gt 0) { throw 'Output directory is not empty; existing evidence will not be overwritten.' }
    }
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
    $receiptPath=Join-Path $OutputRoot 'completion_receipt.json'
    $state['output_root']=$OutputRoot; $state['started_at']=(Get-Date).ToString('o'); Save-State
    $git=(Get-Command git -ErrorAction Stop).Source
    $dotnet=(Get-Command dotnet -ErrorAction Stop).Source
    $head=(Native $git @('-C',$LeanRoot,'rev-parse','HEAD')).Trim()
    if ($head -ne $commit) { throw 'LEAN commit does not match the installed/pinned research version.' }
    $dirty=(Native $git @('-C',$LeanRoot,'status','--porcelain')).Trim()
    if ($dirty) { throw 'LEAN source tree has changes. Kept intact; use a clean independent installation.' }
    $state.source='PINNED_CLEAN_SOURCE_VERIFIED';$state['lean_commit']=$head
    $sourceFile=Join-Path $PSScriptRoot 'GoldResearchAlgorithm.cs'
    $state['algorithm_source_sha256']=Hash $sourceFile
    $quotePath=Join-Path $LeanRoot 'Data/cfd/oanda/hour/xauusd.zip'
    $audit=Audit-Quotes $quotePath (Join-Path $OutputRoot 'data_audit.json')
    $state.data='PINNED_HOURLY_SAMPLE_AUDITED'; Save-State
    $prereg=[ordered]@{
        authorization='User selected independent LEAN gold strategy backtest; not a modification of any MT5 SOP/EA.'
        initial_cash_usd=1000;risk_fraction=0.005;leverage_model=20
        defaults_status='Research starting settings selected for this new project, not inherited approved live limits.'
        start_date=$audit.start_date;end_exclusive=$audit.end_exclusive
        entry='Completed H1: EMA20 above/below EMA50, EMA20 slope in same direction, candle touches EMA20 and closes back on trend side with same candle direction.'
        initial_stop='Native StopMarket at actual entry price +/- 2*Wilder ATR14, rounded away to price tick.'
        target='Market exit after an H1 close reaches 2R or 3R; NOT a resting take-profit order.'
        session='Entry only 08:00 <= completed-bar time < 15:00 New York; market-flat at first available close >=16:00.'
        position='One position, no scale-in, martingale, BE, trailing or partial exits. Size rounded down to actual LEAN unit step.'
        base_cost='Bid/ask from source, USD0.035 per quantity unit per side, USD0.05 price slippage per side. These are modeled assumptions, not a verified broker tariff.'
        comparison='A:2R vs B:3R. Then re-run each with double commission and double absolute slippage. Same source, dates, starting cash, risk and initial stop.'
        no_claims=@('No OOS designation for this batch','No tick-level drawdown','No MT5/FxPro equivalence','No live or withdrawal validation','No formal score without frozen scoring anchors')
        source_sha256=$state.algorithm_source_sha256;registered_at=(Get-Date).ToString('o')
    }
    Write-Json $prereg (Join-Path $OutputRoot 'preregistration.json')
    Set-Location -LiteralPath $LeanRoot
    $env:DOTNET_CLI_TELEMETRY_OPTOUT='1'; $env:DOTNET_NOLOGO='1'
    $sdk=(Native $dotnet @('--version')).Trim()
    if ($sdk -notmatch '^10\.0\.\d+$') { throw 'Use stable .NET 10 SDK for this pinned LEAN version.' }
    $state['dotnet_sdk']=$sdk
    $env:NUGET_PACKAGES=Join-Path (Split-Path -Parent $LeanRoot) 'nuget-packages'
    $bin=Join-Path $LeanRoot 'Launcher/bin/Release'
    $launcher=Join-Path $bin 'QuantConnect.Lean.Launcher.dll'
    if ($BuildEngine) {
        $project=Join-Path $LeanRoot 'Launcher/QuantConnect.Lean.Launcher.csproj'
        $null=Native $dotnet @('restore',$project,'--verbosity','minimal') (Join-Path $OutputRoot 'engine-restore.log')
        $null=Native $dotnet @('build',$project,'-c','Release','--no-restore','--verbosity','minimal') (Join-Path $OutputRoot 'engine-build.log')
        $state['engine_compile']='COMPILED_THIS_RUN'
    } else { $state['engine_compile']='REUSE_EXISTING_PINNED_INSTALLATION_BINARY' }
    if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) { throw 'Compiled LEAN engine not found. Complete the previous installation first.' }
    $state['launcher_sha256']=Hash $launcher
    $build=Join-Path $OutputRoot 'candidate-build'
    New-Item -ItemType Directory -Path $build | Out-Null
    $sourceCopy=Join-Path $build 'GoldResearchAlgorithm.cs'
    Copy-Item -LiteralPath $sourceFile -Destination $sourceCopy
    $refs=@('QuantConnect','QuantConnect.Algorithm','QuantConnect.Indicators','QuantConnect.Brokerages','NodaTime')
    $refXml=($refs | ForEach-Object {
        $path=[Security.SecurityElement]::Escape((Join-Path $bin ($_+'.dll')))
        if (-not (Test-Path -LiteralPath (Join-Path $bin ($_+'.dll')))) { throw ('Missing compiler reference: '+$_) }
        '<Reference Include="'+$_+'"><HintPath>'+ $path +'</HintPath><Private>false</Private></Reference>'
    }) -join "`n"
    $projectXml='<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net10.0</TargetFramework><AssemblyName>IndependentLeanGold</AssemblyName><OutputType>Library</OutputType><Nullable>disable</Nullable><Deterministic>true</Deterministic></PropertyGroup><ItemGroup>'+$refXml+'</ItemGroup></Project>'
    $candidateProject=Join-Path $build 'IndependentLeanGold.csproj'
    [IO.File]::WriteAllText($candidateProject,$projectXml,[Text.UTF8Encoding]::new($false))
    $null=Native $dotnet @('build',$candidateProject,'-c','Release','--verbosity','minimal') (Join-Path $OutputRoot 'candidate-build.log')
    $dll=Join-Path $build 'bin/Release/net10.0/IndependentLeanGold.dll'
    if (-not (Test-Path -LiteralPath $dll)) { throw 'Candidate DLL missing after build.' }
    $state.compile='CANDIDATE_COMPILED';$state['candidate_dll_sha256']=Hash $dll; Save-State
    $experiments=@(
        @{id='A_R2_BASE';target='2';fee='0.035';slip='0.05'},
        @{id='B_R3_BASE';target='3';fee='0.035';slip='0.05'},
        @{id='A_R2_COST2X';target='2';fee='0.070';slip='0.10'},
        @{id='B_R3_COST2X';target='3';fee='0.070';slip='0.10'}
    )
    $results=New-Object 'System.Collections.Generic.List[object]'
    foreach ($e in $experiments) {
        $run=Join-Path $OutputRoot $e.id
        $nativeOut=Join-Path $run 'native'
        New-Item -ItemType Directory -Path $nativeOut -Force | Out-Null
        $config=[ordered]@{
            environment='backtesting';'algorithm-id'=$e.id;'algorithm-type-name'='GoldResearchAlgorithm'
            'algorithm-language'='CSharp';'algorithm-location'=$dll;'data-folder'=(Join-Path $LeanRoot 'Data')
            'results-destination-folder'=$nativeOut;'object-store-root'=(Join-Path $run 'storage')
            'live-mode'=$false;debugging=$false;'close-automatically'=$true
            'log-handler'='QuantConnect.Logging.CompositeLogHandler';'messaging-handler'='QuantConnect.Messaging.Messaging'
            'job-queue-handler'='QuantConnect.Queues.JobQueue';'api-handler'='QuantConnect.Api.Api'
            'map-file-provider'='QuantConnect.Data.Auxiliary.LocalDiskMapFileProvider'
            'factor-file-provider'='QuantConnect.Data.Auxiliary.LocalDiskFactorFileProvider'
            'data-provider'='QuantConnect.Lean.Engine.DataFeeds.DefaultDataProvider';'data-channel-provider'='DataChannelProvider'
            'object-store'='QuantConnect.Lean.Engine.Storage.LocalObjectStore';'data-aggregator'='QuantConnect.Lean.Engine.DataFeeds.AggregationManager'
            'job-user-id'='0';'api-access-token'='';'job-organization-id'='';'show-missing-data-logs'=$true
            parameters=@{'start-date'=$audit.start_date;'end-exclusive'=$audit.end_exclusive;'evidence-dir'=$run;'run-id'=$e.id;
                'initial-cash'='1000';'risk-fraction'='0.005';'target-r'=$e.target;'fee-usd-per-unit-side'=$e.fee;'slippage-price-per-side'=$e.slip}
            environments=@{backtesting=@{'live-mode'=$false;'setup-handler'='QuantConnect.Lean.Engine.Setup.BacktestingSetupHandler';
                'result-handler'='QuantConnect.Lean.Engine.Results.BacktestingResultHandler';'data-feed-handler'='QuantConnect.Lean.Engine.DataFeeds.FileSystemDataFeed';
                'real-time-handler'='QuantConnect.Lean.Engine.RealTime.BacktestingRealTimeHandler';
                'history-provider'=@('QuantConnect.Lean.Engine.HistoricalData.SubscriptionDataReaderHistoryProvider');
                'transaction-handler'='QuantConnect.Lean.Engine.TransactionHandlers.BacktestingTransactionHandler'}}
        }
        $configPath=Join-Path $run 'config.json'; Write-Json $config $configPath
        Set-Location -LiteralPath $bin
        $null=Native $dotnet @($launcher,'--config',$configPath) (Join-Path $run 'engine.log')
        $metricsPath=Join-Path $run 'metrics.json'
        if (-not (Test-Path -LiteralPath $metricsPath)) { throw ('No strategy metrics for '+$e.id) }
        $m=Get-Content -LiteralPath $metricsPath -Raw | ConvertFrom-Json
        if (-not $m.cashflow_reconciliation_pass -or $m.final_open_quantity -ne 0 -or $m.closed_round_trips -lt 1 -or
            $m.rejected_orders -ne 0 -or @(Get-ChildItem -LiteralPath $nativeOut -Filter '*.json').Count -lt 1) {
            throw ('Run evidence incomplete: '+$e.id)
        }
        $results.Add($m)
        $state.backtests+=@{id=$e.id;status='COMPLETED';metrics_sha256=(Hash $metricsPath);config_sha256=(Hash $configPath)}
        Save-State
    }
    Write-Json @($results.ToArray()) (Join-Path $OutputRoot 'comparison.json')
    $rows=New-Object 'System.Collections.Generic.List[string]'
    $rows.Add('# LEAN 黄金独立策略：本轮实际回测结果')
    $rows.Add('')
    $rows.Add(('区间：'+$audit.start_date+' 至 '+$audit.end_exclusive+'（结束日不含）。初始资金 1000 USD，每次入场预算 0.5%，模型杠杆 1:20。'))
    $rows.Add('数据为固定版本官方源码随附的 OANDA 来源 XAUUSD H1 历史样本，不是 FxPro 真实 Tick。')
    $rows.Add('')
    $rows.Add('|实验|净利润 USD|H1采样净值DD USD|H1最大相对DD %|净额PF|完整交易|胜率 %|佣金 USD|已含滑点 USD|')
    $rows.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|')
    foreach ($m in $results) {
        $pf='N/A';if ($null -ne $m.net_profit_factor) { $pf=([double]$m.net_profit_factor).ToString('0.0000',$culture) }
        $rows.Add(('|{0}|{1:0.00}|{2:0.00}|{3:0.0000}|{4}|{5}|{6:0.00}|{7:0.00}|{8:0.00}|' -f
            $m.run_id,$m.net_profit_usd,$m.max_h1_sampled_liquidation_equity_dd_usd,$m.max_h1_sampled_relative_equity_dd_percent,
            $pf,$m.closed_round_trips,$m.win_rate_percent,$m.commission_usd,$m.modeled_slippage_usd_already_in_fills))
    }
    $rows.Add('')
    $rows.Add('A/B 仅改变收盘触发止盈门槛 2R/3R；COST2X 同时加倍该版本的佣金和价格滑点并重新运行，不是事后直接扣费。风险金额会随净值及成本预算变化，并非固定成交路径。')
    $rows.Add('点差已在买卖报价成交价中，不重复扣除。成本栏的滑点已计入成交价，不能再次从净利扣除；点差没有单独精确拆分。')
    $rows.Add('止损由 LEAN 的原生 StopMarket 模型处理；止盈等 H1 收盘再市价退出。小时K线无法重建真实Tick顺序、延迟或盘中最大净值回撤。')
    $rows.Add('本轮全部为研究样本，不称未见样本外；没有 MT5、实盘、提款持续账户或历史新闻模块验证。若 metrics 中 overnight_date_transitions_while_holding 非0，隔夜费用缺口必须另行补齐。')
    $rows.Add('综合分数 N/A（SCORE_TARGETS_UNSET），本轮完成不等于盈利达标、Champion 或可实盘。')
    $rows.Add('完整证据：data_audit.json、preregistration.json、源码/DLL哈希、编译日志、每轮config.json、engine.log、原生结果、metrics.json、trades.csv及equity_h1.csv。')
    [IO.File]::WriteAllLines((Join-Path $OutputRoot '回测结果_CN.md'),$rows,[Text.UTF8Encoding]::new($true))
    $state.status='ALL_FOUR_GOLD_BACKTESTS_COMPLETED';$code=0
}
catch { $state.status='INCOMPLETE';$state.error=$_.Exception.Message;Write-Host ('INCOMPLETE: '+$_.Exception.Message) }
finally {
    $state['finished_at']=(Get-Date).ToString('o');try { Save-State } catch { Write-Host $_.Exception.Message }
    Set-Location -LiteralPath $original.Path
    Write-Host ('FINAL STATUS: '+$state.status)
    if ($receiptPath) { Write-Host ('Receipt: '+$receiptPath) }
}
exit $code
