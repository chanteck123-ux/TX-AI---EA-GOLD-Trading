# Claude → Codex：LEAN L013 交叉复核请求（2026-11-07）

> **2026-11-08 用户安排**：Codex 复核等全部阅读完成后统一进行一次。本文件中的条目都是**待汇总、尚未发出**的复核项，期间不单独请 Codex 复核。

**范围**：只覆盖 Claude 批次 L013，即绩效统计、结果采样和主循环剩余部分。L001–L012 的发现见各自的批次笔记，本文件不重复。

**依据**：
- 源码：`Desktop/TX/QuantConnect/Lean-master …`。之前已核对，各文件 blob 与上游 `1383825` 一致。
- 笔记：`lean-full-review-20261101/claude/batches/L013_statistics_results_CN.md`。

**Claude 实际做了什么**：只读阅读源码，没有编译，也没有运行 LEAN。以下各项在笔记中的状态是 CONFIRMED（源码可以直接对应）或 PLAUSIBLE，都**没有经过实际运行验证**。

| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R1 | 统计报告的最大回撤只用权益 Candlestick 的 Close 计算，日内低点（Low）不计入。采样间隔 = 回测总分钟数 ÷ 4000，最少 4 分钟，另外每日零点再采一次 | `StatisticsBuilder.GetPointValue`；`BacktestingResultHandler.SetAlgorithm` 与 `ProcessSynchronousEvents` |
| R2 | `DrawdownRecovery` 实际是"所有已恢复回撤中最长的恢复天数"，与注释所说的"最大回撤的恢复时间"不一致；没有恢复的回撤不计入 | `Statistics.CalculateDrawdownMetrics`；`PerformanceMetrics` 的注释 |
| R3 | Trade 的 ProfitLoss 是毛盈亏（未扣手续费），因此 PF、WinRate、IsWin 都是扣费前的数字；盈亏为 0 算亏损；没有亏损单时 PF 和 WinLossRatio 固定为 10 | `TradeBuilder`；`TradeStatistics` 第 309–420 行 |
| R4 | 摘要里的 Win Rate 和 Expectancy 来自 PortfolioStatistics：按每笔平仓成交计数，盈亏 = 平仓盈亏 − 2 × 平仓手续费。这与 TradeStatistics 的口径不同 | `PortfolioStatistics` 构造函数；`SecurityPortfolioModel` 约第 96 行；`StatisticsBuilder` 第 123–124 行 |
| R5 | 回测结束时不平仓（只有实盘并且状态为 Liquidated 才会平仓），未平仓盈亏不进入交易统计 | `AlgorithmManager` 第 628–637 行 |
| R6 | 每日采样在每个日历日都会触发：`EveryDay()` 即 `Time.EachDay`，错过的事件由 `ScanPastEvents` 补发；但年化按 252 天计算，`CfdExchange` 中的 313 没有被统计模块使用 | `AlgorithmManager` 第 166、228 行；`DateRules` 第 118 行；`BaseSetupHandler` 第 188 行 |
| R7 | Sortino 的下行方差以负收益样本自身的均值为中心计算，不是以 0 为中心 | `Statistics.AnnualDownsideVariance` |
| R8（PLAUSIBLE） | PSR 用的是 `(kurtosis−1)/4`。如果 MathNet 的 `Kurtosis()` 返回超额峰度，PSR 会偏高。本库没有附带 MathNet 源码，需要查外部文档 | `Statistics.ProbabilisticSharpeRatio` |
| R9 | 查不到的品种会静默套用默认属性：合约乘数 1、最小变动价位 0.01、最小手数 1，不会阻断 | `SymbolPropertiesDatabase.GetSymbolProperties`；`SymbolProperties.GetDefault` |

**边界**：
- 本请求不关闭 Q1–Q10，也不表示三项审核全部完成；
- Claude 没有修改 Codex 的目录或正式接口；
- 如果 Codex 不同意某一项，请写明读取的文件和行号，Claude 会回到源码复核。

## 补充：L014（2026-11-07）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R10 | MarketHoursDatabase 查不到条目时抛异常（阻断），SymbolPropertiesDatabase 查不到时静默用默认值，两者方向相反 | `MarketHoursDatabase.GetEntry`；`SymbolPropertiesDatabase.GetSymbolProperties` |
| R11 | 打开 `force-exchange-always-open` 后所有品种 24×7 开市 | `MarketHoursDatabase.TryGetEntry`；`AlwaysOpenMarketHoursDatabaseImpl` |
| R12 | 预热中 CancelOpenOrders 静默返回空列表，ProcessRequest 则抛异常 | `SecurityTransactionManager` 第 191–193 行、第 254–257 行 |

## 补充：L015（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R13 | Monte Carlo 只模拟 5 次（`nSims: 5`），百分位用了整数除法，结果只可能是 0 或 100 | `MonteCarloPercentileAnalysis.Run` |
| R14 | PortfolioMarginUsageAnalysis 在保证金使用率低于 50% 时报问题，并建议加大杠杆 | 同名文件 |
| R15 | MarginCallsAnalysis 说明写"超过 10% 生成 margin call 单"，代码实际是超过总资产的 110% | `MarginCallsAnalysis.Solutions`；`DefaultMarginCallModel` 第 100 行 |
| R16 | 分析用的权益曲线只保留与 SPY 交易日相同的日期；Close 为 null 时按 0 处理；有 5 秒和 10 条的上限，低权重分析可能不运行 | `ResultsAnalyzer.ReadEquityCurve`、`Run` |

## 补充：L016（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R17 | 危机期间和全期的基准夏普用"日均收益 − 年化无风险利率"除以日标准差，单位混用，低波动策略几乎一定被判为更差 | `CrisisEventsAnalysis.CalculateSharpeRatio`；`RiskFreeInterestRateModelExtensions.GetRiskFreeRate` 的注释 |
| R18 | 默认无风险利率是美联储一级信贷利率，数据截至 2023-07-27（5.50%），之后一律沿用；文件缺失时按 1% 计算，不中止 | `InterestRateProvider`；`Data/alternative/interest-rate/usa/interest-rate.csv` |

## 补充：L017（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R19 | 引擎默认 StalePriceTimeSpan 是 1 小时：小时线时，K 线中途下的市价单会立即按最新收盘价成交；休市时提交的挂单按下一根 K 线的开盘价成交 | `HourMarketOrderFillsAtBarCloseRegressionAlgorithm`、`RestingMarketOrderFillsAtBarOpenRegressionAlgorithm`、`HourResolutionMarketOrderStalePriceRegressionAlgorithm` 的注释；AlgorithmSettings 中的默认值（未读） |
| R20 | 默认回测成交模型一次全部成交，部分成交只出现在自定义的成交模型里 | `BacktestingBrokerageRegressionAlgorithm`、`OneUpdatesOtherOrderRegressionAlgorithm` |
| R21 | InsufficientMarginOrderUpdate 第 104、109 行用 orderEvent.Id 和 OrderId 比较，限价单和跟踪止损单的断言实际不起作用 | 同名文件第 99–111 行 |

## 补充：L018（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R22 | StopLossOnOrderEvent 先开空，再在成交价下方 2 美元挂买入止损单，注释称其为止损，实际会立刻触发；StopMarketOrderRegression 也在现价下方挂买入止损单 | 两个同名文件 |
| R23 | 全部示例中只有 2 个出现 XAUUSD，都只检查日线历史数据能否取到，没有 XAUUSD CFD 的交易示例 | grep `XAUUSD` 于 Algorithm.CSharp、Algorithm.Python、Algorithm.Framework；`DailyHistoryFor*ResolutionRegressionAlgorithm.cs` |

## 补充：L019（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R24 | 通用 FillModel 只有在"价格结束时间 + StalePriceTimeSpan（默认 1 小时）< 下单时间"时才判定为旧价格；1 小时以内的数据缺口会直接按旧价格成交，不等待也不警告。AlgorithmSettings 中"分钟级只警告"的注释已过时 | `FillModel.cs` 第 297–312 行、第 1018–1085 行；`AlgorithmSettings.cs` 中 StalePriceTimeSpan 的注释及构造函数 |
| R25 | 只订阅日线时，市价单会被自动改成 MarketOnClose 或 MarketOnOpen；小时线在休市时下的市价单会改成 MarketOnOpen | `DailyResolutionMarketOrderConversionRegressionAlgorithm`、`MarketOnOpenOrderRegressionAlgorithm`；转换逻辑的源码（未读） |

## 补充：L020（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R26 | 回测中 asynchronous=true 的市价单仍在同一时间步成交，LEAN 回测默认不模拟下单延迟 | `BacktestingAsynchronousOrdersRegressionAlgorithm`；`SecurityTransactionManager.SetLiveMode`（L013 已读：回测时 MarketOrderFillTimeout 为 0） |
| R27 | OnOrderEvent 中抛出异常会使整个算法以 RuntimeError 终止 | `OnOrderEventExceptionRegression`（预期状态为 RuntimeError） |

## 补充：L023–L024（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R28 | LEAN 默认不对 CFD 和外汇计算隔夜利息（swap）：默认券商模型返回 `MarginInterestRateModel.Null`，Cfd/Forex 默认也是 Null，Oanda 券商模型没有覆盖 | `DefaultBrokerageModel.cs` 第 368–371 行；`Cfd.cs`、`Forex.cs`、`OandaBrokerageModel.cs` 中的 `MarginInterestRateModel` |
| R29 | LEAN 有原生的 OneTriggersOther / OneCancelsOther 条件单，父单全部成交后触发子单，一张子单成交后自动撤另一张；回测中相当于零延迟原子撤单 | `ContingentComboOrderRegressionAlgorithm`；条件单的源码（未读） |
| R30 | `ExecutionModel.OnOrderEvent` 收到全部订单的事件，而不只是本模型下的单，需要自行按 OrderId 过滤 | `ExecutionModelOrderEventsRegressionAlgorithm` 第 114–134 行 |
| R31 | 年化所用的每年交易日数按券商模型决定：Coinbase、Binance、Bitfinex、Bybit、FTX、Kraken 为 365，其余（含默认、Oanda）为 252；可用 `Settings.TradingDaysPerYear` 覆盖。XAUUSD CFD 研究若沿用默认值 252，需与 L016 中"周末日样本也按 252 年化"的问题一并核对 | `Engine/Setup/BaseSetupHandler.cs` 第 178–198 行；`CoinbaseCryptoYearMarketTradingRegressionAlgorithm` |
| R32 | QuoteBar 的 Open/High/Low/Close 在买卖价都存在时取**中间价**（`(Bid + Ask) / 2`），High/Low 是"买价最高与卖价最高的平均"，而不是真实中间价的最高/最低；外汇/CFD 的指标若用 QuoteBar 收盘价，与 MT5 以 Bid 绘制的 K 线相差约半个点差 | `Common/Data/Market/QuoteBar.cs` 第 64–175 行附近（Open/High/Low/Close 的 getter）；`SecuritySessionWithFuturesRegressionAlgorithm` |

## 补充：L067–L071（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R33 | 同一回测中有两种"胜率"口径：`TradeBuilder.ClosedTrades` 生成的 TradeStatistics 按开平配对的交易计数（示例为 3/4 = 0.75），`Statistics.TotalPerformance.PortfolioStatistics` 按产生实现盈亏的成交（Transactions.WinCount/LossCount）计数（示例为 2/3）。引用 LEAN 的胜率、PF、平均盈亏时须注明出处，再与 MT5 报告的计数方式分别核对 | `OptionAssignmentStatisticsRegressionAlgorithm.cs` 第 107–244 行；TradeStatistics 与 PortfolioStatistics 源码（L013 已读部分） |

## 补充：L089–L091（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R34 | LEAN 的 C# 与 Python 示例在均线交叉处会因 decimal 与 double 舍入不同而做出不同交易，示例为此加了 0.001 的交叉阈值。V1.2 跨引擎核对（LEAN C# decimal 对 MQL5 double）在信号边界上可能出现相反结论，应单独归类并登记容差 | `Algorithm.Python/BasicTemplateContinuousFutureAlgorithm.py` 第 37–38、50–51 行；`BasicTemplateContinuousFutureWithExtendedMarketAlgorithm.py` 第 38–39、57–58 行 |

## 补充：L095–L097（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R35 | LEAN 的括号单（`bracket_order`，OTOCO）与条件子单：入场成交时子单被触发，但"需要新数据才能成交"，示例中可立即成交的止盈单在入场后下一根分钟 K 线才成交；一张子单成交后另一张同一时间戳撤销。与 MT5 持仓自带 SL 从开仓即生效不同，LEAN 会漏掉"入场当根即止损"的情形 | `Algorithm.Python/ContingentOrderUpdateRegressionAlgorithm.py` 第 16–19、61–71 行；`BracketOrderRegressionAlgorithm.py` 第 36–67、85–90 行；条件单与填充源码（未读） |
| R35 补充 | 撤销 OCO/括号单中任一成员会撤销整组：撤销等待触发的止盈单时，同组止损单一并撤销（消息 "Contingent sibling order … was canceled"），父单继续工作；撤销父单会级联撤销其全部子孙单。研究中若用括号单表示 SL/TP，"只改止盈"不能用撤单重挂，否则持仓失去止损 | `Algorithm.Python/ContingentOrderCancelRegressionAlgorithm.py` 第 16–20、38–91 行 |
| R35 修正 | 区分子单类型：OTO 触发的**市价**子单在父单成交的同一时刻成交（`OneTriggersOtherOrderRegressionAlgorithm` 断言子单、孙单成交时间与父单相同）；"需要新数据才能成交"针对的是限价/止损类子单（`ContingentOrderUpdateRegressionAlgorithm` 中的止盈限价单晚 1 分钟成交）。因此括号单中的止损市价单（stop market）是否能在入场当根触发，取决于止损单的填充逻辑，需在源码中核对，R35 的结论暂按"限价/止损类子单"表述 | `Algorithm.Python/OneTriggersOtherOrderRegressionAlgorithm.py` 第 86–89 行；`ContingentOrderUpdateRegressionAlgorithm.py` 第 61–71 行 |

## 补充：L101–L108（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R35 补充 2 | 限价入场的括号单在入场成交前，止盈和止损子单都是 SUBMITTED 且处于等待触发状态，这些子单**不计入** `get_open_orders_remaining_quantity`（示例断言为 100，只算入场单）。子单触发时间等于入场成交时间，子单成交时间必须严格晚于触发时间。研究中用 open remaining quantity 估算挂单暴露，会漏掉尚未触发的保护单 | `Algorithm.Python/BracketOrderLimitEntryRegressionAlgorithm.py` 第 64–72、77–86、99–100 行 |
| R36 | `OrderEvent.quantity` 是订单当前的总数量，不是本次成交的数量（示例断言 `order_event.quantity == order.quantity`）。部分成交时，对账必须用 fill_quantity，不能用 quantity。另外，异步市价单提交后马上撤单存在竞态：有时撤成功，有时已经成交 | `Algorithm.Python/OrderTicketDemoAlgorithm.py` 第 85–90、391–395 行；`ComboOrderTicketDemoAlgorithm.py` 第 167–172 行；OrderEvent 源码（L003 已读部分） |
| R37 | 自定义成交模型和购买力模型可以完全改写成交与拒单的行为：示例 SimpleCustomFillModel 只要 bar 穿过止损价就按止损价成交，不考虑跳空，比实际乐观；CustomBuyingPowerModel 则永远返回"保证金足够"。使用这类模型的 LEAN 结果须在报告中登记，否则不能与 MT5 Real Tick 结果对照 | `Algorithm.Python/CustomModelsAlgorithm.py` 第 109–118、153–166 行 |

## 补充：L109–L114 Algorithm.Framework（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R38 | Framework 的风险模型（单品种回撤、单品种浮盈、追踪止损、组合回撤）只在 `ManageRisk` 调用时检查，触发后输出 0 目标，由执行模型发市价单平仓，不是挂在服务器上的止损单，bar 内跳空和穿价都捕捉不到。组合回撤模型只在本期 targets 非空时才处理，而且只平掉 targets 里列出的品种；触发后以当时净值作为新的起点。LEAN 研究不能用这些模型代替 MT5 的 SL 或账户级回撤停机，使用时报告须写明口径 | `Algorithm.Framework/Risk/MaximumDrawdownPercentPortfolio.cs` 第 54–84 行；`MaximumDrawdownPercentPerSecurity.cs` 第 50–70 行；`TrailingStopRiskManagementModel.cs` 第 48–92 行；框架主循环调用 ManageRisk 的位置（Algorithm 目录，尚未读） |

## 补充：L115–L116 Algorithm 下单入口（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R38 补充 | 框架主循环 `OnFrameworkData` 遇到 `!slice.HasData` 就直接返回；Alpha → 组合构建 → ManageRisk → 执行在每个有数据的 slice 上运行一次，风险目标覆盖同一品种的组合目标 | `Algorithm/QCAlgorithm.Framework.cs` 第 106–166、176–244 行 |
| R39 | (a) 回测中订单总数超过 `_maxOrders`（默认 10,000）时，算法状态被设为 Stopped，之后的订单全部被拒绝，高频或多年回测须调用 SetMaximumOrders 或核对订单总数；(b) 非期货品种在 `ExchangeOpen` 为 false 时下的市价单会被自动改成 MarketOnOpen，等下次开盘才成交（MT5 在休市时会直接拒单），休市边界上两边结果不同，报告须统计这类改单；(c) |数量| 小于 LotSize 才拒绝，数量不会被取整到 LotSize 的整数倍；(d) Liquidate 会先撤掉该品种的全部非市价挂单（含 SL/TP）再市价平仓 | `Algorithm/QCAlgorithm.Trading.cs` 第 842–1052、1140–1211 行；`QCAlgorithm.Trading.ContingentOrders.cs` 第 239–279、305–348 行 |

## 补充：L117–L119 QCAlgorithm 主体（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R40 | (a) 算法默认时区为 America/New_York，`Time`、OnEndOfDay 和日线边界都按纽约时区；用户 Scalping 的服务器日 6 盈或 6 亏规则须显式调用 SetTimeZone 或自行换算到 FxPro 服务器日；(b) SetBrokerageModel 在添加证券之后调用时，会重新初始化已有证券的各个模型但保留杠杆，用户调用过 SetSecurityInitializer 后则不替换，1:1000 杠杆须在运行时记录实际的 Leverage 和保证金模型；(c) AddCfd 和 AddForex 把扩展时段写死为 false；(d) 回测中与上一条完全相同的 Debug/Error 消息会被丢弃，拒单计数应以订单事件为准；(e) ImmediateExecutionModel 在订单保证金低于 MinimumOrderMarginPortfolioPercentage 时静默不下单，小账户须核对该设置的默认值；(f) 默认 TradeBuilder 为 FillToFill + FIFO，与 MT5 的持仓计算方式须分别核对 | `Algorithm/QCAlgorithm.cs` 第 178–259、1347–1376、1396–1444、2632–2650、2931–3035 行；`Algorithm/Execution/ImmediateExecutionModel.cs` 第 45–75 行；`Common/AlgorithmSettings.cs`（MinimumOrderMarginPortfolioPercentage 的默认值） |
| R40 补充 | 已在 `Common/AlgorithmSettings.cs` 第 189–197 行确认默认值：LiquidateEnabled=true、MinimumOrderMarginPortfolioPercentage=0.001（组合价值的 0.1%）、MaxAbsolutePortfolioTargetPercentage=1e9、MinAbsolutePortfolioTargetPercentage=1e-10。按 500 USD 账户计算，0.1% 约等于 0.5 USD 的订单保证金下限。在 1:1000 杠杆下，一张 0.01 手的 XAUUSD 订单所需保证金是否高于这个下限，须按实际合约规格核对 | `Common/AlgorithmSettings.cs` 第 59–101、189–197 行 |

## 补充：L120–L122 History 与 Indicators（2026-11-08，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R41 | (a) 在 CFD 或外汇上调用 `History<TradeBar>` 只会触发 Error 并返回空结果，不会抛出异常，须使用 QuoteBar；(b) 静态推断（**未验证**）：以 TradeBar 为输入的指标（STO、HeikinAshi、MFI、OBV、VWAP、CMF 等）在只有 Quote 订阅的 CFD 上，合成器会回退为 QuoteBar，`RegisterIndicator<T>` 的类型检查会抛出 Type mismatch，须提供转换用的 selector；(c) MAX、MIN 在 QuoteBar 上默认取收盘价，而不是 bar 的最高价和最低价，与 MT5 的 iHighest/iLowest 不一致；(d) WarmUpIndicator 和 IndicatorHistory 会先 Reset 指标再填充历史数据 | `Algorithm/QCAlgorithm.History.cs` 第 595–614 行；`Algorithm/QCAlgorithm.Indicators.cs` 第 1535–1658、3182–3223、3337–3369、4513–4611 行；Indicators 和 Tests 中 TradeBar 指标在 CFD 上的测试（尚未读） |
| R41 补充 | (e) CandlestickPatterns 的 60 余个形态工厂方法只调用 RegisterIndicator，不经过 InitializeIndicator，因此即使开启 AutomaticIndicatorWarmUp 也不会预热；回测开头的形态信号会缺失，研究端须手动预热或登记预热窗口 | `Algorithm/CandlestickPatterns.cs` 第 48–1021 行；`Algorithm/QCAlgorithm.Indicators.cs` 第 4399–4427 行 |

## 补充：L125–L136 Indicators 全目录（2026-11-09，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R42 | ATR 的平滑方式随构造方式不同：`QCAlgorithm.ATR(...)` 默认 `MovingAverageType.Simple`，直接 `new AverageTrueRange(period)` 默认 Wilders；KeltnerChannels 内部的 ATR 写死为 Simple；ChandeKrollStop 和 SuperTrend 默认 Wilders；NATR 先用 SMA 作为第一个值，之后按 Wilders 递推。MT5 的 iATR 为简单平均。ATR 用于止损距离或仓位预算时，必须登记构造方式和平滑类型，并在两个引擎上用同一口径 | `Algorithm/QCAlgorithm.Indicators.cs`（ATR 工厂方法）；`Indicators/AverageTrueRange.cs`；`KeltnerChannels.cs` 第 71 行；`NormalizedAverageTrueRange.cs` 第 42、79–89 行；`SuperTrend.cs` 第 78–81 行；`ChandeKrollStop.cs` 第 59–77 行 |
| R43 | LEAN 的 EMA 以前 N 个值的 SMA 作为第一个输出，未就绪前返回 0；WilderMovingAverage 也以 SMA 起步。MT5 的 EMA 通常以第一个价格起步（**MT5 侧须核对**）。两个引擎在样本开头的若干个 bar 上 EMA 值不同，对 MACD、TEMA、DEMA、KVO、TSI 等派生指标也有影响；跨引擎核对须丢弃足够长的预热区间或统一起点 | `Indicators/ExponentialMovingAverage.cs` 第 108–128 行；`WilderMovingAverage.cs` 第 74–82 行；MT5 MovingAverages.mqh 或 iMA 的实测值 |
| R44 | LEAN 的 Stochastic 慢线 %K 是 FastK 比值的 kPeriod 简单平均（`_sumFastK / kPeriod`），区间为 0 时 FastK 返回 0；MT5 iStochastic 的 slowing 通常按 Σ(C−LL)/Σ(HH−LL) 计算（**MT5 侧须核对**），两者在区间宽度变化时结果不同。另外 Maximum/Minimum 遇到相等值时取最新的 bar（`>=`/`<=` 重置 PeriodsSince） | `Indicators/Stochastic.cs` 第 126–179 行；`Maximum.cs` 第 60–94 行；`Minimum.cs` 第 60–94 行 |
| R45 | `IndicatorBase.Update` 按 Symbol 检查时间：EndTime 早于上一次输入时只记一次 Error 并忽略，**EndTime 相等时不拦截**，同一时间的另一个对象会再次计入 Samples 和窗口（重复喂数据会重复计算）；计算结果状态不是 Success 时（如 Over 除零返回 MathError），Samples 已增加但 Current 不更新。MultiSymbolIndicator（Correlation、Covariance、Beta 等）只有在所有品种的 bar 按分辨率取整后 UTC 结束时间相同时才计算，某一品种缺 bar 时指标值保持不变（NR07 黄金与美元关联市场须登记缺 bar 处理）；Correlation 用收盘价水平而不是收益率计算，Covariance 用收益率 | `Indicators/IndicatorBase.cs` 第 186–227 行；`IndicatorExtensions.cs` 第 559–562 行；`MultiSymbolIndicator.cs` 第 63–104、222–235 行；`Correlation.cs` 第 88–106 行；`Covariance.cs` 第 97–122 行 |
| R46 | (a) PivotPointsHighLow 只有在中间 bar 之后再收到 N 根 bar 时才确认枢轴点，默认严格比较（相等不算），事件时间为中间 bar 的 EndTime——无前视，但有 N 根 bar 的确认延迟；ZigZag 会随新 bar 修改最近的枢轴（重绘）。若 S7 用户 Scalping 的"最近有效供需区"借用这类指标定位，须登记确认延迟和重绘，不能用事后完整序列回测；(b) IntradayVwap 只接受成交 Tick 和非填充的 TradeBar，QuoteBar 一律返回 InvalidInput，在只有报价的 CFD 上永远不会就绪，且按 `EndTime.Date`（交易所时区）换日；(c) SharpeRatio 指标直接用每个 bar 的收益均值减去年化无风险利率，单位不一致，结果不能当作年化夏普使用 | `Indicators/PivotPointsHighLow.cs` 第 98–183 行；`ZigZag.cs` 第 134–196 行；`IntradayVwap.cs` 第 33–110 行；`SharpeRatio.cs` 第 80–96、154–158 行 |

## 补充：L137–L142 Engine 剩余文件（2026-11-09，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R47 | (a) 市场开放时段内没有新数据时，FillForwardEnumerator 生成的填充 bar 完整复制前一根 bar 的 OHLC（只有 TradeBar 的 Volume 置 0），时间改为下一个周期；(b) 填充分辨率取所有非内部订阅中的最小分辨率（默认 1 分钟），同时订阅分钟和小时数据时，小时数据也按分钟填充；(c) TimeSliceFactory 把填充 bar 放进 consolidatorUpdate 时不过滤 IsFillForward，AlgorithmManager 逐个送入全部合成器，M5 合成器、指标和 K 线形态都会收到复制出来的 bar，而 MT5 没有 tick 时不生成 bar；(d) SubscriptionFilterEnumerator 丢弃交易时段外的 bar，AddCfd 写死不含扩展时段，XAUUSD CFD 在交易时段库常规时段之外的数据会被丢弃。研究端须登记 FillDataForward 设置、过滤或统计填充 bar，并核对 XAUUSD 的交易时段库条目 | `Engine/DataFeeds/Enumerators/FillForwardEnumerator.cs` 第 183–295、323–488 行；`Engine/DataFeeds/SubscriptionCollection.cs` 第 144–207 行；`Engine/DataFeeds/TimeSliceFactory.cs` 第 175–264、383–386 行；`Engine/AlgorithmManager.cs` 第 459–475 行；`Common/Data/Market/TradeBar.cs` 第 834–845 行；`Engine/DataFeeds/Enumerators/SubscriptionFilterEnumerator.cs` 第 121–165 行 |

## 补充：L143–L148 小目录收尾（2026-11-09，待汇总）
| 编号 | 结论 | 请核对的位置 |
|---|---|---|
| R48 | (a) LEAN Optimizer 的默认 Euler/Grid 策略只按单一 Target（示例为 Sharpe）择优，约束只做丢弃；分析模块的 Modes、Slicing 和 Clustering 也只以 Sharpe 为维度。V1.2 寻优须用 §11.1 和 §13.10 的口径另行排序，并计入试验次数；(b) Report 的杠杆和敞口用订单价格重建（零手续费、杠杆 10,000）；年度和月度收益不计跨期第一段；TradesPerDay 是订单数除以日历天数；(c) QuantBook.GetPortfolioStatistics 的 Win Rate 是权益收益为正的时点比例，不是交易胜率；(d) DockerfileJupyter 和 `.vscode/launch_research.sh` 让 Jupyter 无 token 运行，前者还监听 0.0.0.0 并带 allow-root，本地研究容器不得对外暴露 8888 端口 | `Optimizer/Strategies/*.cs`；`Optimizer/Analysis/OptimizationModes.cs`、`OptimizationSlicing.cs`；`Optimizer.Launcher/config.example.json`；`Report/PortfolioLooper/PortfolioLooper.cs` 第 337–427 行；`PortfolioLooperAlgorithm.cs` 第 74–75 行；`Report/ReportElements/AnnualReturnsReportElement.cs`、`MonthlyReturnsReportElement.cs`、`TradesPerDayReportElement.cs`；`Research/QuantBook.cs` 第 802–864 行；`DockerfileJupyter` 第 42–50 行；`.vscode/launch_research.sh` |

## 补充：Tests T1–T5（2026-11-10，待汇总、尚未发出）
- **R49（RiskExecution 相关，Tests/Brokerages）**，请 Codex 回原文复核：
  - (a) OrderCrossingBrokerageTests：穿零订单拆成两笔；第二部分失败时事件为 PartiallyFilled → Canceled，只平仓不反手。
  - (b) BrokerageConcurrentMessageHandler：下单在锁内执行，期间的券商消息先缓冲、后按序处理。
  - (c) BrokerageTests.ContingentOrders*：重建 contingency 及等待触发状态；平仓前先撤 TP/SL。
  - (d) 对已撤订单再撤：同步券商返回 false 且没有 Canceled 事件。
  - (e) IB 模拟止损没有 Submitted 事件。
  - 笔记见 `lean-full-review-20261101/claude/batches/L149-_tests_CN.md` 的 T5 节。
- T1–T4 对 R35、R36、R38、R39、R40(b)、R41、R47、R48 的测试证据补充，见同一文件的 T1–T4 节。
  - (f) ContingentOrdersBrokerageModelTests：Oanda 和 FXCM 等未列入支持名单的券商模型，会把括号单的全部成员拒绝（消息为 "does not support contingent orders"）。LEAN 研究端如果用 `SetBrokerageModel(Oanda/FXCM)`，回测中的 SL/TP 不会生效。请核对 `Common/Brokerages` 中各模型的 CanSubmitOrder 实现。
  - (g) FxcmBrokerageModelTests：外汇和 CFD 的限价、止损价须落在现价区间内，且不支持 StopLimit。用 FXCM 模型时 LEAN 的订单行为与 MT5 的 StopLevel 规则不同。
- **R48 补充 (e)**：FileCommandHandler 以 `TypeNameHandling.All` 反序列化工作目录下的 `command*.json`，存在不可信输入风险。请核对 `Common/Commands/FileCommandHandler.cs`。另外，SymbolPropertiesDatabaseSymbolMapperTests 和 LocalZipFactorFileProviderTests 会写入实际 Data 目录。
- **R50（新增，合成器口径）**：在 DataConsolidated 回调内部，`consolidator.Consolidated` 仍是上一根 bar，而 `Current` 和 `[0]` 已是新 bar（ConsolidatorBaseTests）。另外，时间段模式的 bar 起点按交易所时区向下取整。请核对 `Common/Data/Consolidators/ConsolidatorBase.cs`，并确认 V1.2 研究端的闭柱确认实现不读 `Consolidated`。
- **R50 补充 (b)**（T9）：QuoteBarConsolidator 下一根 bar 的 Open 等于上一根 Close，跳空丢失；时间段合成器要到下一次 Update/Scan 才发出 bar；MarketHourAware 合成器的最后一根 bar 在收市处被截短。请核对 `Common/Data/Consolidators/QuoteBarConsolidator.cs` 和 `PeriodCountConsolidatorBase.cs`，并评估对 V1.2 M5 闭柱确认及跨引擎 OHLC 对齐的影响。
- **R49 补充 (h)**（T11，ContingentOrderProcessorTests）：OneCancelsOther 括号单中，TP 只部分成交时 SL 立刻被整张撤销，持仓剩余部分没有止损；父单部分成交时不触发子单，已成交的部分没有 SL/TP 保护。请核对 `Common/Orders/ContingentOrderProcessor.cs`，并确认 V1.2 RiskExecution 在 LEAN 研究端不依赖 OCO 括号单的保护语义（MT5 端以服务器侧 SL/TP 为准）。
- **R51（新增，成交模型口径）**（T12，Fills 测试）：
  - (a) 市价单只能取到比当前时间落后超过一个分辨率周期的数据时，不成交，等下一根新 bar 按其收盘价成交；落后不足一个周期时，按旧价成交并给出警告。
  - (b) ImmediateFillModel：止损单按 max/min(Price, Stop) 成交；限价单按 min(Limit, High) 或 max(Limit, Low) 成交；止损限价单不使用触发那根 bar 的价格区间；fill-forward 复制出来的 bar 不触发成交。
  - 请核对 `Common/Orders/Fills/FillModel.cs` 和 `ImmediateFillModel.cs` 中的陈旧数据判断，并评估其对 V1.2 M5 闭柱入场、周末跳空止损与 MT5 Real Tick 成交价差异的影响。
- **R49 补充 (i)**（T13）：`PartialMarketFillModelTests` 整组标为 `[Ignore("TODO: fix me")]`，LEAN 没有在用的部分成交回归测试。请确认 V1.2 RiskExecution 的部分成交、对账测试改用自有故障注入，不把 LEAN 测试当作依据。
- **R51 补充 (c)**（T13）：MarketImpactSlippageModel 对 CFD/外汇抛异常，VolumeShare 和 AlphaStreams 模型对外汇/CFD 返回 0；外汇 Day/GTD 订单在纽约 17:00 到期。请核对 `Common/Orders/Slippage/*.cs` 和 `Common/Orders/TimeInForces/*.cs`，并评估 V1.2 LEAN 研究端 XAUUSD 的滑点设定是否已登记、订单有效期与 FxPro 服务器日是否存在口径差异。
- **R52（新增，日界与换算口径）**（T14）：
  - (a) TimeRulesTests 显示 XAUUSD（Oanda CFD）的日开盘为纽约 00:00，即 LEAN 的交易日按纽约午夜切分，与 FxPro 服务器日不同。V1.2 中用户 Scalping 的 6 盈/6 亏换日（00:00 服务器时间）以及 DR01 日内风控，在 LEAN 研究端须显式设定服务器时区。
  - (b) SecurityCurrencyConversion 在没有数据时汇率为 0，回测起点的持仓价值和盈亏换算可能为 0。
  - 请核对 `Common/Scheduling/TimeRules.cs`、`Common/Securities/CurrencyConversion/SecurityCurrencyConversion.cs` 以及 Data/market-hours 中的 oanda cfd 条目。
