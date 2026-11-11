# L120–L122 Algorithm：History、Universe、Plotting、Indicators（Claude，2026-11-08）

**方式**：用 `tools/dump_src.sh` 只读。可执行代码全部读完，`///` 文档注释和 `[DocumentationAttribute]` 行没有逐行阅读；方法标记为 `CAT_N_CODE_EXCL_LICENSE_BLANK_USINGS_XMLDOC`。没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 5 个）
- L120：QCAlgorithm.History.cs（1,698 行）。
- L121：QCAlgorithm.Universe.cs（755 行）、Framework.Python.cs（141 行）、Plotting.cs（573 行）。
- L122：QCAlgorithm.Indicators.cs（4,628 行，其中约 1,200 行是各个指标的工厂方法）。

## 二、与 V1.2 有关的发现
1. **History 会截掉未来的数据**（History.cs 第 1042–1074 行）：结束时间晚于 UtcTime 的请求会被截到当前时刻，并提示一次 "Request for future history modified to end now"。这在引擎层面防止了前视偏差，但通过 ObjectStore 或自定义数据源引入的未来数据不受这条限制（R 系列中已有 ObjectStore 前视风险的记录）。
2. **在 CFD 或外汇上调用 `History<TradeBar>` 会得到空结果**（第 595–614 行）：引擎只调用 Error 提示，不会抛出异常，只能用 QuoteBar。对 V1.2：XAUUSD CFD 的研究代码如果写成 TradeBar 版本，会静默得到空历史，指标也就不会预热。列入 R41。
3. **TradeBar 输入的指标在 CFD 上可能直接报错**（静态推断，**尚未验证**）：
   - Stochastic、HeikinAshi、MFI、OBV、VWAP、CMF、RVI、MASS、FISH 等指标的工厂方法接收 `Func<IBaseData, TradeBar>`，走 `RegisterIndicator<T>` 时会按 TradeBar 去解析合成器。
   - CFD 只有 Quote 订阅，`GetSubscription` 会回退到第一个订阅，也就是 QuoteBar，于是合成器输出 QuoteBar。
   - 第 3346–3360 行的类型检查遇到 TradeBar 与 QuoteBar 不匹配时，会抛出 "Type mismatch"。
   - 对 V1.2：S1–S7 如果在 LEAN 中用到这类指标，必须提供 selector 把 QuoteBar 转成 TradeBar，或者改用以 IBaseDataBar 为输入的版本。列入 R41，需要在源码和测试中核对。
4. **MAX、MIN 的默认取值**（Indicators.cs 第 1535–1658 行）：只有订阅类型是 TradeBar 时，默认 selector 才取 High 或 Low；QuoteBar（CFD/外汇）的默认 selector 是 `x.Value`，即收盘价。
   - 对 V1.2：在 XAUUSD 上用 MAX/MIN 找最近的高低点或供需区边界，不传 selector 时取到的是收盘价的最高/最低，不是 bar 的最高价和最低价，这会与 MT5 的 iHighest/iLowest 不一致。列入 R41。
5. **预热会重置指标**（第 4513–4611 行）：WarmUpIndicator 和 IndicatorHistory 一开始都会调用 `indicator.Reset()`，再用历史数据重新填充。在已有数据的指标上再调用 WarmUpIndicator，会清掉原有状态。
   - 预热取 WarmUpPeriod 根 bar（`period=0` 时不减 1）。
   - 不实现 IIndicatorWarmUpPeriodProvider 的指标会被跳过，只发一次警告。这个警告与 EmitInsights 共用同一个 `_isEmitWarmupInsightWarningSent` 标志，其中一个提示过以后，另一个就不会再提示。
   - `Settings.AutomaticIndicatorWarmUp` 打开时，每个工厂方法都会自动预热。
6. **日线合成**（第 4298–4321 行）：Resolution.Daily 使用 MarketHourAwareConsolidator，受 `Settings.DailyPreciseEndTime` 和 `DailyConsolidationUseExtendedMarketHours` 控制。CFD 的日线边界按交易时段数据库的开收盘时间计算，与 R40(a) 的服务器日问题相关。
7. **证券和 universe 的添加在当前时间步结束时才生效**（Universe.cs 第 70–190 行）：AddSecurity 和 AddUniverse 产生的变更进入待处理列表，在 `OnEndOfTimeStep` 中统一提交。
8. **自动添加证券**（第 3182–3202 行）：对未订阅的品种注册指标或合成器时，`CanAutoAddSecurity` 为真就会自动调用 AddSecurity，下单时也是一样（L115）。研究代码拼错品种名时不会报错，而是会多订阅一个品种。
9. **Plotting**：0–100 的纯数字统计名是保留名；实盘预热期间不绘图；Strategy Equity、Drawdown、Benchmark 等图表下的部分 series 名是保留名。
10. **代码问题（不影响 V1.2 路径）**：
    - `HT()` 计算了 name，但构造 HilbertTransform 时没有传进去。
    - `IndicatorWarmupAlgorithm` 等示例中的 `round_down` 问题不在本批，见 L101–L103。

## 三、进度
- Algorithm 目录剩余：QCAlgorithm.Python.cs（123 KB）、CandlestickPatterns.cs（64 KB）、ConstituentUniverseDefinitions.cs（43 KB）。
