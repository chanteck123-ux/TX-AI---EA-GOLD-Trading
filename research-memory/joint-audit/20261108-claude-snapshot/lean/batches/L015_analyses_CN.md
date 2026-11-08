# L015 回测结果分析器与数据库基类（Claude，2026-11-08）

**层级**：第 1 层。
**方式**：只读阅读源码，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ，10 个）
- `Common/Securities/BaseSecurityDatabase.cs`
- `Engine/Results/Analysis/Analyses/` 下的：
  - BaseResultsAnalysis
  - Messages/MessageAnalysis
  - TakeProfitAndStopLossOrdersAnalysis
  - MarginCallsAnalysis
  - StaleOrderFillsAnalysis
  - PortfolioMarginUsageAnalysis
  - PortfolioValueIsNotPositiveAnalysis
  - StatisticalSignificanceOfDailyReturnsAnalysis
  - MonteCarloPercentileAnalysis

## 二、发现（静态阅读，没有运行验证）
1. **CONFIRMED：Monte Carlo"运气"检测实际不起作用。**
   - 调用时传入 `RunSimulation(returns, nSims: 5)`，函数默认值是 5000，所以实际**只模拟 5 次**。
   - 百分位的计算是 `simulatedTotalReturns.Count(...) / simulatedTotalReturns.Length * 100m`，前半部分是两个 int 相除，属于**整数除法**，结果只可能是 0 或 100。
   - 所以只有在超过全部 5 条模拟曲线时才会报警，结论没有统计意义。
   - 此外，方法本身是对同一组日收益做块状重抽样，比较的是总收益落在哪个位置，并不是检验"运气"的标准做法。
   - V1.2 不能把这个分析器的输出当作"不是运气"的证据。
2. **CONFIRMED：保证金使用率分析器鼓励提高杠杆。** `PortfolioMarginUsageAnalysis` 会在保证金使用率的 3 日均值低于 50% 时报告问题，并建议使用更多保证金。这与 V1.2 的风控原则相反（杠杆变更不能自动增加手数或风险），V1.2 应忽略这条建议。
3. **CONFIRMED：margin call 分析器的说明文字和代码不一致。**
   - `MarginCallsAnalysis` 的建议文字写的是"已用保证金超过总资产的 10% 就会生成 margin call 单"；
   - `DefaultMarginCallModel` 第 100 行的实际条件是 `totalMarginUsed > totalPortfolioValue × (1 + 0.10)`，也就是**超过总资产的 110%**；
   - 预警条件（剩余保证金 ≤ 总资产的 5%）与代码一致。
   - 另外，这个分析器靠在日志里搜索文本 "Executed MarginCallOrder" 来识别，而日志在消息过多时会被限流丢弃（见 L013 中 BaseResultsHandler 的说明），所以可能漏报。
4. 止盈止损配对分析器只按"同一品种、同样数量、同一创建时间"配对，每组只取两张单。
   - 不同时间或不同数量挂出的止盈止损单识别不出来；
   - "对侧单没有撤销"的判断依据是撤单时间不等于成交时间。
   - 它能检测到"止盈止损同时成交"，说明 LEAN 中没有用 OCO 关联的两张挂单可以在同一根 K 线内同时成交（另见 L001 关于 OCO 的记录）。
   - 它推荐的替代做法是用 K 线价格自己模拟 OCO，这会改变成交价的口径。
5. 日收益显著性检验：
   - 方法是对策略相对基准（默认 SPY）的超额日收益做单尾 t 检验，阈值 0.05；
   - 没有考虑多重检验、自相关和日收益的采样口径（L013 指出日采样包含周末）；
   - 对 XAUUSD 这类 CFD 策略，以 SPY 为基准的意义有限。
6. 过期价格成交分析器只在订单事件消息中搜索 "Warning: fill at stale price"。是否算过期由 `Settings.StalePriceTimeSpan` 决定，说明文字说默认是 1 小时，代码里的默认值没有读到。
7. `BaseSecurityDatabase.Merge`：从数据文件重新载入时，保留用户自定义的条目；数据文件中已删除、又不是用户自定义的条目会被移除。`Reset` 用于测试，作用是清空全局单例。

## 三、仍未读
- `Analysis/` 下其余分析器，例如 FlatEquityCurve、CrisisEvents，以及 OrderResponseErrors 和 Messages 下的各个小类，后者计划在第 3 层按模板分组处理；
- Live、Regression 和 IResultHandler。

## 四、补读 `Engine/Results/Analysis/ResultsAnalyzer.cs`（FULL_READ，623 行）
8. **CONFIRMED：分析器用的权益曲线只保留 SPY 的交易日。**
   - `ReadEquityCurve` 会拉取 SPY 的日线历史，把策略权益重采样到日频，然后**只保留与 SPY 交易日相同的日期**。
   - 所以 XAUUSD 策略在美股休市日的权益变化会被丢掉，这与 L013 中"统计报表日采样包含周末"的口径又不一样。
   - 如果没有 SPY 数据，两条曲线都返回空。这时 Monte Carlo 直接跳过；显著性检验因为样本不足，p 值被设为 1.0，单尾后为 0.5，结果仍会报告"不显著"。这个结论看起来像是检验过了，其实是缺数据造成的。
   - Candlestick 的 Close 为 null 时按 **0** 处理（`c.Close ?? 0m`），可能人为造成 −100% 的日收益。
9. **CONFIRMED：分析器不保证全部运行。** 最终分析有两个上限：5 秒，以及最多 10 条发现。分析器按权重从高到低运行，权重低的可能因为超时或名额用完而**不运行，也不提示**。Monte Carlo（权重 69）和 ParameterCount 排在最后。
10. 运行中的分析使用截断后的订单事件和日志，同一条发现最多报告 3 次，之后就不再报告。即使后来清除、又再次出现，也不会恢复报告。
