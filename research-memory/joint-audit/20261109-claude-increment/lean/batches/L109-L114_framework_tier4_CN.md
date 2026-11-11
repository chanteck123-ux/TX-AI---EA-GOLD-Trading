# L109–L114 第 4 层：Algorithm.Framework 全部 86 个文件（Claude，2026-11-08）

**方式**：只读。新增工具 `tools/dump_src.sh` 输出带行号的源码，跳过开头的许可证注释、空行和 using/import 行（文件开头的 BOM 已处理）。csproj 用 `cat -n` 完整阅读。没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 86 个，Algorithm.Framework UNREAD 0）
| 批次 | 内容 | 文件数 |
|---|---|---|
| L109 | Risk 5 个模型和 Execution 3 个模型，各含 C# 与 Python 版 | 16 |
| L110 | Portfolio 第 1 部分：Accumulative、AlphaStreams、BlackLitterman、ConfidenceWeighted、EqualWeighting.cs | 8 |
| L111 | Portfolio 第 2 部分：EqualWeighting.py、InsightWeighting、MaxSharpe、MeanReversion、MeanVariance、MinimumVariance.cs | 10 |
| L112 | Portfolio 第 3 部分：MinimumVariance.py、PythonWrapper、ReturnsSymbolData、RiskParity（模型和优化器）、SectorWeighting、UnconstrainedMV | 11 |
| L113 | Alphas 7 个模型，各含 C# 与 Python 版；NotifiedSecurityChanges；AssemblyInfo | 16 |
| L114 | Selection 24 个文件；csproj | 25 |

## 二、与 V1.2 有关的发现（静态阅读）
1. **Framework 的风险模型不是止损单**（Risk/*）：
   - MaximumDrawdownPercentPerSecurity、MaximumUnrealizedProfitPercentPerSecurity、TrailingStop 和 MaximumDrawdownPercentPortfolio 都只在 `ManageRisk` 被调用时，按当时的 `UnrealizedProfitPercent` 或 `AbsoluteHoldingsValue` 判断，然后输出一个数量为 0 的 PortfolioTarget，再由执行模型发市价单平仓。
   - 这意味着判断频率等于数据或调仓频率，bar 内的跳空和穿价都不会被捕捉到，成交价是下一次市价成交的价格。
   - 对 V1.2：LEAN 研究中不能用这些模型代替 MT5 服务器端的 SL。如果使用，报告应写明"按 bar 收盘检查后市价平仓"的口径。该条列入最终复核（R38）。
2. **组合回撤模型的触发条件依赖当期 targets**（MaximumDrawdownPercentPortfolio，C# 第 70 行、Python 第 47 行）：
   - 只有回撤超限而且 `targets.Length != 0` 时才处理，并且只平掉本次 targets 里列出的品种，不是全部持仓。
   - 没有新 target 的周期里，即使回撤已经超限也不会动作。
   - 触发后 `_initialised` 被设为 false，下一次以当时净值作为新的起点。
   - 对 V1.2：这不是账户级的"回撤即停"。账户风险上限必须由 RiskExecution 独立实现，不能套用这个模型。列入 R38。
3. **C# 与 Python 版的行为不一致**（跨语言核对时注意）：
   - StandardDeviation 和 VWAP 执行模型的 Python 版在找不到 symbol 数据时用 `return`，会中断整个循环并跳过 `clear_fulfilled`；C# 版用 `continue`。
   - MaximumSharpeRatio 优化器：C# 用 Charnes-Cooper 二次规划，Python 用 SLSQP 直接最大化，源码注释已说明两者算法不同，结果可能不一样。
   - MeanReversion.py 和 MacdAlphaModel.py 仍用旧的 PascalCase API，其余文件已改为 snake_case。
   - 对 V1.2：研究端只用 C#，这类差异只作记录。
4. **示例和模型的代码问题（不影响 V1.2 路径）**：
   - **InceptionDateUniverseSelectionModel 的队列依赖插入顺序**：`TryPeek` 遇到第一个上市日还没到的条目就停下。USTreasuriesETFUniverse 中 EDV（2007-12-10）排在 BIL、SPTL（2007-05-30）前面，因此 BIL 和 SPTL 要等到 EDV 的日期才会被加入，推迟约 6 个月。LiquidETFUniverse 按分组拼接，同样不保证日期顺序。
   - **MeanReversion（OLMAR）的步长截断方向**：代码截断的是 `(b·x − ε)`，再用 `b − λ(x − x̄)` 更新；论文截断的是 `(ε − b·x)`，再用 `b + λ(x − x̄)`。两种写法乘积相同，但 `max(0, ·)` 的触发条件相反。这是静态推断，尚未验证。另外，移除品种时如果字典里没有该品种，C# 和 Python 版都会出现空引用。
   - **RiskParity 优化器**：先归一化再按上下限截断，结果之和可能不等于 1。
   - **MinimumVariance**：注释写 `w^T µ ≥ β`，代码是等式约束；结果最后按绝对值之和重新缩放，目标收益约束因此不再成立。
   - **BlackLitterman**：类注释写 tau 为 0.0025，实际默认值是 0.05；后验协方差乘以 delta，与 cookbook 的写法不同。
   - **EmaCrossAlphaModel**：`FastIsOverSlow` 初始为 false，指标就绪的第一根 bar 上只要 fast > slow，就会发出 Up 信号，即使并没有发生交叉。
   - **RSI 和 HistoricalReturns 的预热**：历史数据只取 period 或 lookback 根，而指标需要多 1 根才能就绪，所以预热结束后指标仍未就绪。RSI 的 Python 版只取 TradeBar 历史，外汇用的是 QuoteBar，会取不到数据。
   - **BasePairsTrading**：注释写"2 倍标准差"，实际阈值是均值的百分比。
   - **OptionUniverseSelectionModel.py**：下次刷新时间用 `.date()`，与 C# 版的 datetime 不一致。
5. **依赖版本**（csproj）：net10.0、Accord 3.6.0、MathNet.Numerics 5.0.0、QuantConnect.pythonnet 2.0.68、NodaTime 3.0.5。只记录，没有安装。

## 三、进度
- 盘点表全库：FULL_READ 1,589，DATA_AUDITED 643，HASH_REUSE 5，PARTIAL 5，UNREAD 4,280。
- Algorithm.CSharp、Algorithm.Python、Algorithm.Framework 三个目录 UNREAD 均为 0。
- 下一步：Algorithm 目录剩余 59 个 → Indicators 233 个 → Engine 208 个 → Tests 859 个 → Common 1,972 个 → 其余目录。
