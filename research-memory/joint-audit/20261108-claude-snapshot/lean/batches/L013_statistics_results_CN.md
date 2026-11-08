# L013 绩效统计口径、结果采样、主循环剩余部分、Paper 券商、品种属性与交易时段（Claude，2026-11-07）

**层级**：第 1 层（与 V1.2 执行和风控直接相关）。
**方式**：只读阅读源码，没有编译、运行或回测。
**源码根目录**：`Desktop/TX/QuantConnect/Lean-master …`。

## 一、覆盖范围

**FULL_READ（20 个文件）**：
- `Common/Statistics/` 全部 12 个：AlgorithmPerformance、DrawdownMetrics、IStatisticsService、PerformanceMetrics、PortfolioStatistics、Statistics、StatisticsBuilder、StatisticsResults、Trade、TradeBuilder、TradeEnums、TradeStatistics。
  - 其中 8 个小文件（Trade、TradeEnums、AlgorithmPerformance、DrawdownMetrics、StatisticsResults、IStatisticsService、PerformanceMetrics，以及 TradeStatistics 的第 80–300 行）是分两次读的：先读代码行，再单独读 `///` 注释行（去掉了 `<summary>` 一类标签），两部分合起来覆盖全文。
- `Engine/Results/BaseResultsHandler.cs`、`Engine/Results/BacktestingResultHandler.cs`。
- `Engine/AlgorithmManager.cs`：L011 已读第 130–140、355–421 行，本批补读第 1–130、140–355、421–1062 行，合计全文。
- `Brokerages/Paper/PaperBrokerage.cs`、`PaperBrokerageFactory.cs`。
- `Common/Securities/SymbolProperties.cs`、`SymbolPropertiesDatabase.cs`、`SecurityExchangeHours.cs`。
- 第 1–14 行是许可证头，已用脚本确认这几行只有注释，没有代码。

**PARTIAL（4 个文件，只读了相关段落）**：
- `Common/Securities/SecurityTransactionManager.cs`：第 60–160、630–680 行；
- `Common/Extensions.cs`：第 4530–4560 行（`OrderEvent.IsWin`）；
- `Engine/Setup/BaseSetupHandler.cs`：第 180–205 行；
- `Common/Scheduling/DateRules.cs`：第 118–130 行。

**引用但不重读**：`SecurityPortfolioModel.cs` 已在 L008 全文读过。L008 已记录"成交的 transactionProfitLoss = 平仓盈亏 − 2 × 本次平仓手续费"，本批不重复计数。

## 二、对 V1.2 有影响的发现

以下全部是静态阅读的结论，都没有运行验证。标 CONFIRMED 的，表示源码可以直接对应；标 PLAUSIBLE 的，表示还依赖本库之外的代码或外部库的语义。

### A. 回撤（V1.2 评分"净值回撤 25%"会受影响）
1. **CONFIRMED：统计报告里的最大回撤只用权益采样点的收盘值。**
   - 权益曲线是 Candlestick（开高低收），但 `StatisticsBuilder.GetPointValue` 只取 `Close`。
   - 回测的采样间隔 `ResamplePeriod` = 回测总分钟数 ÷ 4000，最少 4 分钟（`BacktestingResultHandler.SetAlgorithm`）。回测 1 年约每 131 分钟采一次，3 年约每 6.6 小时一次。另外每个日历日零点还额外采一次。
   - 结果：两个采样点之间的浮亏低点（K 线的 Low）**不进入** `Drawdown`。
   - MT5 按每个 tick 算的净值回撤会比 LEAN 报告的大，所以两边不能直接对照，需要从订单事件或逐 tick 净值重新计算。
2. **CONFIRMED：`DrawdownRecovery` 的文档和代码不一致。**
   - `PerformanceMetrics` 的注释写的是"最大回撤的恢复时间"；
   - 代码（`Statistics.CalculateDrawdownMetrics`）算的是**所有已恢复回撤里最长的恢复天数**；
   - 回测结束时还没恢复的回撤不计入。所以即使最大回撤一直没恢复，这个值也可能显示为 0，或者显示另一次较小回撤的恢复时间。
   - 这与 V1.2 §11 要求"恢复时长单列"相关，必须自己重新计算。
3. 图表里的 Drawdown 序列（`SampleDrawdown`）只在每日零点采样，同样不含日内低点。

### B. 盈亏比（PF）、胜率、费用口径（与 V1.2"PF、胜率、零盈亏单、费用同口径"相关）
4. **CONFIRMED：Trade 的 `ProfitLoss` 是毛盈亏，没有扣手续费**（注释写明 gross，手续费另放在 `TotalFees`）。
   - 因此 `TradeStatistics.ProfitFactor`、`WinRate`、`AverageProfit/Loss`、`LargestProfit/Loss`、交易级"Sharpe/Sortino"、`MaximumClosedTradeDrawdown` 都是**扣费前**的数字；
   - `Trade.IsWin` 判断的是毛盈亏 > 0，所以毛利很小、扣费后亏损的单子会被算成"赢"。
5. **CONFIRMED：盈亏恰好为 0 的交易算作亏损**，`TradeStatistics` 和 `PortfolioStatistics` 两处都是这样（代码用 `> 0 ? 赢 : 亏`）。
6. **CONFIRMED：没有亏损单时，`ProfitFactor` 被固定为 10，`WinLossRatio` 也固定为 10**，而不是 N/A。`ProfitToMaxDrawdownRatio` 同理。
7. **CONFIRMED：同一份报告里有两套胜率口径。**
   - 摘要里的 Win Rate、Loss Rate、Average Win、Average Loss、Expectancy 来自 `PortfolioStatistics`：
     - 计数单位是每一笔**平仓成交**，部分平仓会分别计数；
     - 盈亏用的是"平仓盈亏 − 2 × 本次平仓手续费"，用平仓手续费的两倍去估算开仓费，而不是实际的开仓费；
     - 金额换算成占"当时滚动资金"的百分比。
   - `TradeStatistics` 的计数单位是 `TradeBuilder` 组成的交易。
   - 两套数字可能不一样。V1.2 对照时必须写明用的是哪一套。
8. **CONFIRMED：默认的成交分组方式是 FillToFill 加 FIFO**（`QCAlgorithm` 第 238 行）。
   - 部分平仓会拆成多笔 Trade；
   - 开仓手续费只分给第一笔被拆出来的 Trade（拆分后剩余部分的 `TotalFees` 被清零）；
   - 同一订单的多次成交只在第一次计手续费，靠一个最多缓存 1000 个订单 id 的队列判断；
   - 两个 Flat 分组模式下，MAE、MFE、EndTradeDrawdown 固定为 0（代码注释承认这一点）。
9. **CONFIRMED：FillToFill 模式下的 MAE/MFE 用的是"整个持仓"的最高价和最低价**，从第一笔建仓开始算。之后加仓的 Trade 会继承加仓前的极值，所以并不是这笔 Trade 自己的不利/有利波动。价格来自 `security.Price`（`AlgorithmManager` 第 275 行），不是按买价或卖价分边计算。
10. **CONFIRMED：回测结束时不会平掉持仓。**
    - 只有在实盘并且状态是 Liquidated 时才会调用 Liquidate（第 631 行）；
    - 所以未平仓的浮动盈亏算在权益和 Net Profit 里，但不会进入交易统计；
    - 而 MT5 测试器在测试结束时会强制平仓并计入成交。两边的交易数和 PF 因此不能直接比较。
11. 摘要里的 "Total Orders" 是**订单数**（`TransactionHandler.OrdersCount`），不是交易数，也不是往返次数。

### C. 夏普比率和年化口径（V1.2 §11.1：夏普只作辅助参考，必须先核对口径）
12. **CONFIRMED：每日采样在每个日历日都会触发，包括周末。**
    - 采样用 `DateRules.EveryDay()`，也就是 `Time.EachDay`；
    - 回测中如果那天没有数据，错过的定时事件会由 `ScanPastEvents` 补发（第 228 行）；
    - 年化用的 `TradingDaysPerYear` 来自券商模型：加密券商用 365，其他一律 252（`BaseSetupHandler` 第 188 行）。`CfdExchange.TradingDaysPerYear = 313` **不会被统计模块使用**。
    - 后果：日收益序列里混有周末的 0 收益，却按 252 天年化。粗略估算，在无风险利率为 0 时，夏普会被压低约 √(5/7) ≈ 0.845 倍。这个比例只是推导，没有经过实测。
13. **CONFIRMED：年化收益 = (日收益算术平均 + 1)^252 − 1**，属于复利年化，而不是常见的 "平均 × 252"。夏普 = (年化收益 − 无风险利率) ÷ (日标准差 × √252)，所以它与常见的 "平均 ÷ 标准差 × √252" 写法数值不同。
14. **CONFIRMED：计算 Sortino 时，下行方差只取负收益样本，并且以这些负收益自身的均值为中心计算方差**（MathNet 的 `Variance()`）。标准做法应以 0 或最低可接受收益为基准，所以这里的口径不标准。
15. **PLAUSIBLE：概率夏普比率（PSR）可能高估置信度。**
    - 公式里用的是 `(kurtosis − 1) / 4`；Bailey 与 López de Prado 原公式要求用非超额峰度。
    - 如果 MathNet 的 `Kurtosis()` 返回的是超额峰度（我记得是，但本库没有附带 MathNet 源码，无法核实），方差项会被低估，PSR 会偏高。
    - 基准夏普取年化 1（即 1/√252）。
16. 第 0 天和第 1 天的收益被丢弃，用来对齐基准（`PreprocessPerformanceValues`）。滚动窗口从中途开始时，以该窗口第一个权益点作为起始资金。
17. VaR 采用正态分布的方差-协方差法，只取最后 `TradingDaysPerYear` 个样本。`TrackingError` 在两条序列长度不一致时直接返回 0，不报错。

### D. 主循环剩余部分（`AlgorithmManager`）
18. 回测中一旦 `TotalPortfolioValue <= 0`，回测直接停止（第 216 行），没有对应的 Stop Out 建模。
19. 每个时间片的执行顺序：
    1. 补发已错过的定时事件；
    2. 扫描 consolidator；
    3. `SetDateTime`；
    4. 更新品种价格，同时更新 TradeBuilder 的价格；
    5. 每小时一次计算保证金利息和资金结算；
    6. 更新 CashBook；
    7. 第一次 `transactions.ProcessSynchronousEvents()`：成交模型先撮合，然后才进入用户代码；
    8. `realtime.SetTime`；
    9. 保证金追缴检查（L011 已记录）；
    10. 分红与拆股、consolidator、自定义数据回调；
    11. `OnData`；
    12. 第二次撮合；
    13. 结果采样。
20. 预热期间不采样（`Sample` 在预热时直接返回）。预热结束后，起始资金会按预热后的汇率重新取值（`OnWarmupFinished`）。

### E. Paper 券商
21. `PaperBrokerage` 继承 `BacktestingBrokerage`（L006 已读），使用 `DefaultBrokerageModel`：CFD 杠杆 50 倍、手续费 0、滑点 0（L002 和 L007 已记录）。唯一新增的逻辑是把分红直接加进报价币现金。Paper 模式因此**不能**代表 FxPro 的真实成交、成本和保证金。

### F. 品种属性与交易时段
22. **CONFIRMED：数据库里查不到的品种会静默套用默认属性**（`SymbolProperties.GetDefault`）：合约乘数 1、最小变动价位 0.01、最小手数 1。
    - 查找顺序：先查精确条目；期货期权再查标的；然后查"该市场 + 该品种类型"的通配条目；最后才用默认值。
    - 全程不报错、不拦截，正好对应风控反模式里的"未知乘数必须阻断"。V1.2 的 RiskExecution 不能依赖这种做法。
23. 品种属性 CSV 用不处理引号的 `Split(',')` 解析，无法识别的品种类型会被静默跳过；这和 L-DATA 中"约 20 个 CSV 的列数统计可能不准"的说明是同一种情况。
24. `SecurityExchangeHours`：
    - 有一个按单日缓存的 `GetMarketHours`，按"节假日 → 提前收盘 → 推迟开盘"的顺序组合当天的交易时段；
    - `GetNextMarketOpen/Close` 最多向后找 15 天，找不到就抛异常；
    - `Update()` **没有复制 `_bankHolidays`**，属于小问题，只影响到期规则，不影响 V1.2 的 XAUUSD；
    - 类注释说明它假设 `IsOpen` 只会按时间递增调用。

## 三、给 V1.2 的建议（只是建议，不改任何文件）
- 用 LEAN 和 MT5 对照时：
  - 净值回撤、恢复时长、PF、胜率、交易数都要从订单事件或成交记录用同一口径重新计算；
  - 不要直接使用 LEAN 的 summary；
  - 回测结束时的未平仓持仓要单独列出；
  - 夏普要写明采样频率、是否包含周末，以及年化天数。
- 品种属性必须显式登记，例如 XAUUSD 的合约乘数和最小手数；查不到时应阻断，不能套用默认值。

## 四、仍未读（第 1 层还剩的部分）
- `Engine/Results/` 下的 LiveTradingResultHandler、RegressionResultHandler、IResultHandler 等，以及整个 `Analysis/` 目录（全部 UNREAD，下一批按相关性挑选）；
- `SecurityTransactionManager.cs` 的其余部分；
- `Common/Securities/` 的 LocalMarketHours、MarketHoursDatabase。
