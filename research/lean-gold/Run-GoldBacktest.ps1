#requires -Version 5.1
[CmdletBinding()]
param([string]$LeanRoot='', [string]$OutputRoot='', [switch]$BuildEngine)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$commit='985ef30ad3ac774218c5ac516b4cb0aa2655730f'
$quoteBlob='2c0675003e21c8f1310914701053cc22157cc52d'
$culture=[Globalization.CultureInfo]::InvariantCulture
$original=Get-Location;$receiptPath=$null;$code=1
$state=[ordered]@{version='1.0.2';status='RUNNING';source='NOT_STARTED';data='NOT_STARTED';compile='NOT_STARTED';backtests=@();error=$null;live='DISABLED';mt5='NOT_ACCESSED'}
function Save-State{if($script:receiptPath){$script:state|ConvertTo-Json -Depth 15|Set-Content -LiteralPath $script:receiptPath -Encoding UTF8}}
function Native([string]$Exe,[string[]]$ArgumentList,[string]$LogPath=''){
    Write-Host ('> '+$Exe+' '+($ArgumentList -join ' '));$old=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$output=@(& $Exe @ArgumentList 2>&1);$exit=$LASTEXITCODE}finally{$ErrorActionPreference=$old}
    $text=($output|ForEach-Object{[string]$_}) -join [Environment]::NewLine
    if($LogPath){$text|Set-Content -LiteralPath $LogPath -Encoding UTF8};Write-Host $text
    if($exit -ne 0){throw ('Command failed ('+$exit+'): '+$Exe)};return $text
}
function Write-Json($Object,[string]$Path){$Object|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $Path -Encoding UTF8}
function Hash([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}
function Audit-Quotes([string]$ZipPath,[string]$AuditPath){
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $bytes=[IO.File]::ReadAllBytes($ZipPath);$prefix=[Text.Encoding]::ASCII.GetBytes('blob '+$bytes.Length+[char]0)
    $sha=[Security.Cryptography.SHA1]::Create()
    try{$actualBlob=([BitConverter]::ToString($sha.ComputeHash([byte[]]($prefix+$bytes)))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
    if($actualBlob -ne $script:quoteBlob){throw 'Pinned XAUUSD data mismatch; no silent substitution.'}
    $archive=[IO.Compression.ZipFile]::OpenRead($ZipPath)
    $first=$null;$last=$null;$count=0;$duplicates=0;$outOfOrder=0;$badQuotes=0;$zeroSpreads=0
    $fieldCounts=@{};$gaps=New-Object 'System.Collections.Generic.List[object]';$times=New-Object 'System.Collections.Generic.List[datetime]'
    try{
        $entries=@($archive.Entries|Where-Object{$_.Name.EndsWith('.csv')});if($entries.Count -ne 1){throw 'Expected one historical XAUUSD CSV.'}
        $reader=New-Object IO.StreamReader($entries[0].Open())
        try{
            while($null -ne ($line=$reader.ReadLine())){
                if([string]::IsNullOrWhiteSpace($line)){continue}
                $p=$line.Split(',');$t=[DateTime]::ParseExact($p[0],'yyyyMMdd HH:mm',$script:culture)
                $key=[string]$p.Length;if(-not $fieldCounts.ContainsKey($key)){$fieldCounts[$key]=0};$fieldCounts[$key]++
                if($p.Length -ne 11){throw 'Expected bid/ask OHLC columns.'};if($null -eq $first){$first=$t}
                if($null -ne $last){
                    if($t -eq $last){$duplicates++};if($t -lt $last){$outOfOrder++}
                    if(($t-$last).TotalHours -gt 2){$gaps.Add(@{after=$last.ToString('s');before=$t.ToString('s');hours=($t-$last).TotalHours})}
                }
                $bo=[decimal]::Parse($p[1],$script:culture);$bh=[decimal]::Parse($p[2],$script:culture)
                $bl=[decimal]::Parse($p[3],$script:culture);$bc=[decimal]::Parse($p[4],$script:culture)
                $ao=[decimal]::Parse($p[6],$script:culture);$ah=[decimal]::Parse($p[7],$script:culture)
                $al=[decimal]::Parse($p[8],$script:culture);$ac=[decimal]::Parse($p[9],$script:culture)
                if($bc -le 0 -or $ac -lt $bc -or $bh -lt [Math]::Max($bo,$bc) -or $bl -gt [Math]::Min($bo,$bc) -or $ah -lt [Math]::Max($ao,$ac) -or $al -gt [Math]::Min($ao,$ac)){$badQuotes++}
                if($bc -eq $ac){$zeroSpreads++};$last=$t;$count++;$times.Add($t)
            }
        }finally{$reader.Dispose()}
    }finally{$archive.Dispose()}
    if($count -lt 1000 -or $duplicates -gt 0 -or $outOfOrder -gt 0 -or $badQuotes -gt 0){throw 'Quote audit failed.'}
    $end=$last.Date;$start=$end.AddYears(-2);if($start -lt $first.Date.AddDays(14)){$start=$first.Date.AddDays(14)}
    if(($end-$start).TotalDays -lt 90){throw 'Insufficient historical sample.'}
    $selected=@($times|Where-Object{$_ -ge $start -and $_ -lt $end})
    $audit=[ordered]@{
        source='QuantConnect/Lean bundled XAUUSD sample, OANDA-derived CFD quotes';upstream_commit=$script:commit
        git_blob_sha1=$actualBlob;sha256=(Hash $ZipPath);resolution='H1';timestamp_field='Bar start in LEAN data-file timezone, not assumed UTC'
        first_bar_start=$first.ToString('s');last_bar_start=$last.ToString('s');total_rows=$count;column_counts=$fieldCounts
        duplicate_timestamps=$duplicates;out_of_order=$outOfOrder;bad_ohlc_or_crossed_closes=$badQuotes;zero_close_spread_rows=$zeroSpreads
        gaps_gt_2h=$gaps;gap_note='Includes closures/weekends; not a complete trading-calendar audit.'
        start_date=$start.ToString('yyyy-MM-dd');end_exclusive=$end.ToString('yyyy-MM-dd');selected_rows=$selected.Count
        selected_first_bar=$selected[0].ToString('s');selected_last_bar=$selected[-1].ToString('s')
        selection_rule='Latest available 24 calendar months excluding last potentially partial date; selected before returns.'
        limitations=@('Historical bundled sample, not current data','Not FxPro or real ticks','No news/calendar/USD inputs','No synthetic replacement quotes')
    };Write-Json $audit $AuditPath;return $audit
}
try{
    if(-not $LeanRoot){$h=$env:USERPROFILE;if(-not $h){$h=$HOME};$LeanRoot=Join-Path (Join-Path $h 'QuantConnect-LEAN-Local') 'Lean'}
    $LeanRoot=[IO.Path]::GetFullPath($LeanRoot)
    if(-not $OutputRoot){$OutputRoot=Join-Path (Split-Path -Parent $LeanRoot) ('gold-research-runs/'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,6))}
    $OutputRoot=[IO.Path]::GetFullPath($OutputRoot)
    if((Test-Path -LiteralPath $OutputRoot) -and @(Get-ChildItem -LiteralPath $OutputRoot -Force).Count -gt 0){throw 'Output is not empty; will not overwrite evidence.'}
    New-Item -ItemType Directory -Path $OutputRoot -Force|Out-Null
    $receiptPath=Join-Path $OutputRoot 'completion_receipt.json';$state['output_root']=$OutputRoot;$state['started_at']=(Get-Date).ToString('o');Save-State
    $git=(Get-Command git -ErrorAction Stop).Source;$dotnet=(Get-Command dotnet -ErrorAction Stop).Source
    $head=(Native $git @('-C',$LeanRoot,'rev-parse','HEAD')).Trim();if($head -ne $commit){throw 'Pinned LEAN commit mismatch.'}
    if((Native $git @('-C',$LeanRoot,'status','--porcelain')).Trim()){throw 'LEAN tree is modified; existing work left intact.'}
    $state.source='PINNED_CLEAN_SOURCE_VERIFIED';$state['lean_commit']=$head
    $sourceFile=Join-Path $PSScriptRoot 'GoldResearchAlgorithm.cs';$state['algorithm_source_sha256']=Hash $sourceFile
    $audit=Audit-Quotes (Join-Path $LeanRoot 'Data/cfd/oanda/hour/xauusd.zip') (Join-Path $OutputRoot 'data_audit.json')
    $state.data='PINNED_HOURLY_SAMPLE_AUDITED';Save-State
    Write-Json ([ordered]@{
        authorization='Independent LEAN gold research, not MT5 SOP/EA modification.'
        initial_cash_usd=1000;risk_fraction=0.005;leverage_model=20;defaults_status='New research settings, not approved live limits.'
        start_date=$audit.start_date;end_exclusive=$audit.end_exclusive
        entry='Completed H1 EMA20/EMA50 trend, EMA20 slope, touch-and-reclaim candle in same direction.'
        initial_stop='Native StopMarket at actual entry +/-2*Wilder ATR14, rounded away to price tick.'
        target='Market exit at H1-close favorable movement >=2R or >=3R, not resting TP.'
        session='08:00<=NY completed-bar time<15:00 entry; flat at first available close>=16:00.'
        position='One position, no adding, martingale, BE, trailing, partial exit; actual unit-step/risk/margin sizing.'
        base_cost='Bid/ask quote, USD0.035/unit/side commission, USD0.05 absolute price slippage/side; not verified broker tariff.'
        slippage_accounting='Configured allowance is not separately measured actual slippage; native fills determine PnL, never deduct allowance again.'
        comparison='A2R vs B3R then rerun each with 2x commission/slippage; same cash/risk/entry/SL/dates.'
        no_claims=@('No OOS','No tick DD','No MT5/FxPro/live/withdrawal verification','No score without anchors')
        engineering_fixes=@('35519872021: wrong Common DLL name, no candidate compile','35520707024: missing Python.Runtime compile reference and stop API signature, no completed backtest')
        source_sha256=$state.algorithm_source_sha256;registered_at=(Get-Date).ToString('o')
    }) (Join-Path $OutputRoot 'preregistration.json')
    Set-Location -LiteralPath $LeanRoot;$env:DOTNET_CLI_TELEMETRY_OPTOUT='1';$env:DOTNET_NOLOGO='1'
    $sdk=(Native $dotnet @('--version')).Trim();if($sdk -notmatch '^10\.0\.\d+$'){throw 'Stable .NET 10 SDK required.'};$state['dotnet_sdk']=$sdk
    $env:NUGET_PACKAGES=Join-Path (Split-Path -Parent $LeanRoot) 'nuget-packages'
    $bin=Join-Path $LeanRoot 'Launcher/bin/Release';$launcher=Join-Path $bin 'QuantConnect.Lean.Launcher.dll'
    if($BuildEngine){
        $project=Join-Path $LeanRoot 'Launcher/QuantConnect.Lean.Launcher.csproj'
        $null=Native $dotnet @('restore',$project,'--verbosity','minimal') (Join-Path $OutputRoot 'engine-restore.log')
        $null=Native $dotnet @('build',$project,'-c','Release','--no-restore','--verbosity','minimal') (Join-Path $OutputRoot 'engine-build.log')
        $state['engine_compile']='COMPILED_THIS_RUN'
    }else{$state['engine_compile']='REUSE_EXISTING_PINNED_INSTALLATION_BINARY'}
    if(-not (Test-Path -LiteralPath $launcher -PathType Leaf)){throw 'Compiled launcher missing.'}
    $state['launcher_sha256']=Hash $launcher
    $build=Join-Path $OutputRoot 'candidate-build';New-Item -ItemType Directory -Path $build|Out-Null
    Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $build 'GoldResearchAlgorithm.cs')
    # Python.Runtime is an existing LEAN .NET metadata dependency; no Python interpreter/algorithm is installed or run.
    $refs=@('QuantConnect.Common','QuantConnect.Algorithm','QuantConnect.Indicators','QuantConnect.Brokerages','NodaTime','Python.Runtime')
    $refXml=($refs|ForEach-Object{
        $path=Join-Path $bin ($_+'.dll');if(-not (Test-Path -LiteralPath $path)){throw ('Missing compiler reference: '+$_)}
        '<Reference Include="'+$_+'"><HintPath>'+[Security.SecurityElement]::Escape($path)+'</HintPath><Private>false</Private></Reference>'
    }) -join "`n"
    $xml='<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net10.0</TargetFramework><AssemblyName>IndependentLeanGold</AssemblyName><OutputType>Library</OutputType><Nullable>disable</Nullable><Deterministic>true</Deterministic></PropertyGroup><ItemGroup>'+$refXml+'</ItemGroup></Project>'
    $proj=Join-Path $build 'IndependentLeanGold.csproj';[IO.File]::WriteAllText($proj,$xml,[Text.UTF8Encoding]::new($false))
    $null=Native $dotnet @('build',$proj,'-c','Release','--verbosity','minimal') (Join-Path $OutputRoot 'candidate-build.log')
    $dll=Join-Path $build 'bin/Release/net10.0/IndependentLeanGold.dll';if(-not (Test-Path -LiteralPath $dll)){throw 'Candidate DLL missing.'}
    $state.compile='CANDIDATE_COMPILED';$state['candidate_dll_sha256']=Hash $dll;Save-State
    $experiments=@(@{id='A_R2_BASE';target='2';fee='0.035';slip='0.05'},@{id='B_R3_BASE';target='3';fee='0.035';slip='0.05'},
        @{id='A_R2_COST2X';target='2';fee='0.070';slip='0.10'},@{id='B_R3_COST2X';target='3';fee='0.070';slip='0.10'})
    $results=New-Object 'System.Collections.Generic.List[object]'
    foreach($e in $experiments){
        $run=Join-Path $OutputRoot $e.id;$native=Join-Path $run 'native';New-Item -ItemType Directory -Path $native -Force|Out-Null
        $config=[ordered]@{
            environment='backtesting';'algorithm-id'=$e.id;'algorithm-type-name'='GoldResearchAlgorithm';'algorithm-language'='CSharp'
            'algorithm-location'=$dll;'data-folder'=(Join-Path $LeanRoot 'Data');'results-destination-folder'=$native
            'object-store-root'=(Join-Path $run 'storage');'live-mode'=$false;debugging=$false;'close-automatically'=$true
            'log-handler'='QuantConnect.Logging.CompositeLogHandler';'messaging-handler'='QuantConnect.Messaging.Messaging'
            'job-queue-handler'='QuantConnect.Queues.JobQueue';'api-handler'='QuantConnect.Api.Api'
            'map-file-provider'='QuantConnect.Data.Auxiliary.LocalDiskMapFileProvider';'factor-file-provider'='QuantConnect.Data.Auxiliary.LocalDiskFactorFileProvider'
            'data-provider'='QuantConnect.Lean.Engine.DataFeeds.DefaultDataProvider';'data-channel-provider'='DataChannelProvider'
            'object-store'='QuantConnect.Lean.Engine.Storage.LocalObjectStore';'data-aggregator'='QuantConnect.Lean.Engine.DataFeeds.AggregationManager'
            'job-user-id'='0';'api-access-token'='';'job-organization-id'='';'show-missing-data-logs'=$true
            parameters=@{'start-date'=$audit.start_date;'end-exclusive'=$audit.end_exclusive;'evidence-dir'=$run;'run-id'=$e.id
                'initial-cash'='1000';'risk-fraction'='0.005';'target-r'=$e.target;'fee-usd-per-unit-side'=$e.fee;'slippage-price-per-side'=$e.slip}
            environments=@{backtesting=@{'live-mode'=$false;'setup-handler'='QuantConnect.Lean.Engine.Setup.BacktestingSetupHandler'
                'result-handler'='QuantConnect.Lean.Engine.Results.BacktestingResultHandler';'data-feed-handler'='QuantConnect.Lean.Engine.DataFeeds.FileSystemDataFeed'
                'real-time-handler'='QuantConnect.Lean.Engine.RealTime.BacktestingRealTimeHandler'
                'history-provider'=@('QuantConnect.Lean.Engine.HistoricalData.SubscriptionDataReaderHistoryProvider')
                'transaction-handler'='QuantConnect.Lean.Engine.TransactionHandlers.BacktestingTransactionHandler'}}
        }
        $cfg=Join-Path $run 'config.json';Write-Json $config $cfg;Set-Location -LiteralPath $bin
        $null=Native $dotnet @($launcher,'--config',$cfg) (Join-Path $run 'engine.log')
        $mp=Join-Path $run 'metrics.json';if(-not (Test-Path -LiteralPath $mp)){throw ('Missing metrics: '+$e.id)}
        $m=Get-Content -LiteralPath $mp -Raw|ConvertFrom-Json
        if(-not $m.cashflow_reconciliation_pass -or $m.final_open_quantity -ne 0 -or $m.closed_round_trips -lt 1 -or $m.rejected_orders -ne 0 -or
            @(Get-ChildItem -LiteralPath $native -Filter '*.json').Count -lt 1){throw ('Incomplete run evidence: '+$e.id)}
        $results.Add($m);$state.backtests+=@{id=$e.id;status='COMPLETED';metrics_sha256=(Hash $mp);config_sha256=(Hash $cfg)};Save-State
    }
    Write-Json @($results.ToArray()) (Join-Path $OutputRoot 'comparison.json')
    $rows=New-Object 'System.Collections.Generic.List[string]'
    $rows.Add('# LEAN 黄金独立策略：实际回测结果');$rows.Add('')
    $rows.Add(('区间：'+$audit.start_date+' 至 '+$audit.end_exclusive+'（结束日不含）。初始1000 USD，入场风险预算0.5%，模型杠杆1:20。'))
    $rows.Add('固定官方样本：OANDA来源XAUUSD H1，不是近期/FxPro真实Tick；不称样本外。')
    $rows.Add('|实验|净利润USD|H1净值DD USD|H1相对DD %|净额PF|完整交易|胜率 %|佣金USD|配置滑点预算USD|')
    $rows.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|')
    foreach($m in $results){
        $pf='N/A';if($null -ne $m.net_profit_factor){$pf=([double]$m.net_profit_factor).ToString('0.0000',$culture)}
        $rows.Add(('|{0}|{1:0.00}|{2:0.00}|{3:0.0000}|{4}|{5}|{6:0.00}|{7:0.00}|{8:0.00}|' -f $m.run_id,$m.net_profit_usd,
            $m.max_h1_sampled_liquidation_equity_dd_usd,$m.max_h1_sampled_relative_equity_dd_percent,$pf,$m.closed_round_trips,
            $m.win_rate_percent,$m.commission_usd,$m.configured_slippage_allowance_usd))
    }
    $rows.Add('')
    $rows.Add('A/B只改变H1收盘止盈门槛2R/3R。COST2X加倍佣金与价格滑点后实际重跑；仓位按同一风险预算重新计算，不是固定成交路径事后扣费。')
    $rows.Add('净利润依据原生模型成交价及佣金。点差和模型实际施加的滑点已在成交价中，不重复扣除。配置滑点预算不是单独测量的实际滑点。')
    $rows.Add('小时K线不能重建Tick顺序、盘中最大净值回撤或券商延迟。止损是StopMarket，止盈等收盘再市价退出，不保证精确2R/3R。')
    $rows.Add('隔夜费未计；检查 overnight_date_transitions_while_holding，非0须补成本模型。没有MT5/FxPro/实盘/提款持续账户验证。')
    $rows.Add('总分N/A，SCORE_TARGETS_UNSET。回测完成不是策略达标或Champion。')
    $rows.Add('证据：data_audit、preregistration、源码/DLL哈希、编译日志、各轮config/engine.log/原生JSON/metrics/trades/equity_h1。')
    [IO.File]::WriteAllLines((Join-Path $OutputRoot '回测结果_CN.md'),$rows,[Text.UTF8Encoding]::new($true))
    $state.status='ALL_FOUR_GOLD_BACKTESTS_COMPLETED';$code=0
}catch{$state.status='INCOMPLETE';$state.error=$_.Exception.Message;Write-Host ('INCOMPLETE: '+$_.Exception.Message)}
finally{
    $state['finished_at']=(Get-Date).ToString('o');try{Save-State}catch{Write-Host $_.Exception.Message}
    Set-Location -LiteralPath $original.Path;Write-Host ('FINAL STATUS: '+$state.status);if($receiptPath){Write-Host ('Receipt: '+$receiptPath)}
}
exit $code
