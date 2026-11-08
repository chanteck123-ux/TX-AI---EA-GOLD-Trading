# L016 基准比较与其余分析器（Claude，2026-11-08）

**层级**：第 1 层。
**方式**：只读阅读源码，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ，6 个）
- `Engine/Results/Analysis/Analyses/` 下的：
  - FlatEquityCurveAnalysis
  - CrisisEventsAnalysis
  - PerformanceRelativeToBenchmarkAnalysis
  - OrderResponseErrorsAnalyses/OrderResponseErrorAnalysis
  - OrderResponseErrorsAnalyses/InsufficientBuyingPowerOrderResponseErrorAnalysis
- `Common/Data/IRiskFreeInterestRateModel.cs`（全文）

阅读方法：先读代码行，再单独读 `///` 注释行。

## 二、发现（静态阅读，没有运行验证）
1. **CONFIRMED：危机期间和全期的基准夏普比较，单位混用了。**
   - `CrisisEventsAnalysis.CalculateSharpeRatio` 把**日**收益的均值和标准差，与 `GetRiskFreeRate(...)` 直接相减；
   - 而 `GetRiskFreeRate` 的注释写明返回的是"average risk free **annual** return rate"，也就是**年化**利率；
   - 换句话说，计算的是 (日均收益 − 年化无风险利率) ÷ 日标准差。注释里说的是"Calculates annualised Sharpe ratios"，与代码不一致。
   - 后果：无风险利率一旦为正，两边的夏普都会被压成很大的负数，而且**波动越小，负得越多**。
   - 所以低波动的策略在"危机期间夏普不如基准"和"全期夏普不如基准"这两项上，**几乎一定会被判为表现更差**，结论没有意义。
   - `PerformanceRelativeToBenchmarkAnalysis` 直接调用同一个函数，问题相同。
   - 默认的利率模型是 `InterestRateProvider`（QCAlgorithm 第 219 行），本批第四节已补读，见第 5–7 条。
2. 危机事件表写死在代码里，只用整段落在回测区间内的事件。最后一项 "AI Boom 2022-Present" 的结束时间取 `DateTime.Now`，所以同一个回测在不同时间重新分析，结果可能不一样。
3. 平坦权益曲线分析：在与 SPY 对齐后的日权益里找连续相同的值。休市或数据缺失也可能被识别为"平坦"。它的建议只针对"不出信号"这类原因。
4. 下单失败（Invalid）类的分析器，靠在 Invalid 订单事件的消息里匹配文字片段来识别。如果消息文本改了，就会漏报。"购买力不足"类的建议里提到了现金缓冲（FreePortfolioValuePercentage），这一点与 L002/L008 读到的购买力模型一致。

## 三、仍未读
- `IResultHandler.cs` 已补读（只有接口）。`LiveTradingResultHandler.cs` 和 `RegressionResultHandler.cs` 已标为第 4 层延后：V1.2 中 LEAN 只用于研究，实盘由 MT5 执行。
- （InterestRateProvider 已在本批第四节补读）
- 其余分析器，例如速度分析、参数数量分析，以及 Messages 和 OrderResponseErrors 下的模板小类，计划在第 3 层归组处理。

## 四、补读 `Common/Data/InterestRateProvider.cs`（FULL_READ，172 行）
5. **CONFIRMED：默认的无风险利率用的是美联储一级信贷利率（Primary Credit Rate，即贴现窗口利率），而不是国库券利率。**
   - 数据文件是 `Data/alternative/interest-rate/usa/interest-rate.csv`，列名为 PCREDIT8。这个文件在 L-DATA3 已做结构核对：56 行，从 2003-01-09 到 2023-07-27。
   - 一级信贷利率通常比联邦基金利率和国库券利率**高**，所以 LEAN 统计里的夏普和 Sortino 会被**系统性压低**。
6. **CONFIRMED：数据文件之后的日期一律沿用最后一个值。**
   - 文件最后一条是 2023-07-27 的 5.50%，之后每一天都按 5.50% 计算，直到运行当天；
   - 2024–2026 年的回测会使用一个没有更新的利率。
   - 1998 年到文件第一条日期之间，沿用第一条的值。
7. **CONFIRMED：数据文件缺失时只记录错误，不中止。** 这种情况下所有日期都按默认的 1% 计算，而统计报告里看不出用的是默认值。
- **对 V1.2 的建议**：做 LEAN 和 MT5 的夏普对照时，要显式指定无风险利率（或者统一设为 0），并写明利率的来源和日期，不要依赖 LEAN 的默认值。
