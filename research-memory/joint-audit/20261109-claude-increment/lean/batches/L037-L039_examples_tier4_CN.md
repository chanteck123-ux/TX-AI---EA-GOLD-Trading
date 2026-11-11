# L037–L039 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L036，只读，没有编译，也没有运行。另补读源码 `Engine/Setup/BaseSetupHandler.cs` 第 178–198 行（该文件在 L013 为 PARTIAL，本次只补读这一段，状态不变）。

## 一、覆盖范围（FULL_READ 54 个）
- L037、L038、L039 各 18 个；清单以 coverage 表中 batch 列为准。
- 主要是股票期权组合保证金（OptionEquity* 系列）、框架组合构建（BlackLitterman、InsightWeighting、ConfidenceWeighted、RiskParity）、信号导出（Numerai）、自定义数据 zip、相关性与 Beta 指标、期权希腊值、印度市场模板。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **CONFIRMED（源码）：年化用的每年交易日数随券商模型而定。**
   - `BaseSetupHandler.SetBrokerageTradingDayPerYear`：Coinbase、Binance、Bitfinex、Bybit、FTX、Kraken 为 365，**其余（包括默认券商模型和 Oanda）一律为 252**；用户可以用 `Settings.TradingDaysPerYear` 覆盖。
   - 示例 CoinbaseCryptoYearMarketTrading 断言 Coinbase 下为 365。
   - 对 V1.2：XAUUSD CFD 研究若用默认或 Oanda 券商模型，年化按 252 天。结合 L016 中"周末的日度样本也按 252 年化"的发现，夏普等年化指标的口径需要显式设定并在报告中写明。→ 待汇总 R31。
2. **夏令时切换时历史数据不重复**（DaylightSavingTimeHistory）：EURUSD（FXCM 市场）日线 QuoteBar 在 2011 年 11 月夏令时切换前后没有重复 K 线；股票没有日线 QuoteBar，请求会抛 ArgumentException。V1.2 对照 MT5 服务器时间（GMT+2/+3 切换）时，仍需单独核对 XAUUSD 的切换周。
3. **基于周期数的 tick 历史请求不允许**（PeriodBasedHistoryRequestNotAllowedWithTickResolution）：`History<Tick>(symbol, 1)` 会抛 InvalidOperationException，只能按时间范围请求 tick 历史。
4. `SetHoldings` 的 decimal、double、float 三种重载都能正确下单（SetHoldingsRegression），异步标志与算法设置一致。
5. 期货日线合成：`Settings.DailyConsolidationUseExtendedMarketHours = true` 并订阅延长时段时，日线从周日 18:00 开始，按"午夜到午夜"切分（FutureMarketOpenConsolidator 的两个版本）。这与 L034–L036 第 2 条一致。
6. `NumeraiSignalExportDemonstrationAlgorithm` 中 Public ID、Secret ID、Model ID 都是空字符串，不是真实凭证。
7. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 319 个。
