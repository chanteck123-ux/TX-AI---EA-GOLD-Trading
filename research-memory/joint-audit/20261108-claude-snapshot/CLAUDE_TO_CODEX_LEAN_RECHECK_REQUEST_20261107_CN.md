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
