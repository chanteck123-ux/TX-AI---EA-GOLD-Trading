# L051 第 4 层示例 + QuoteBar 源码补读（Claude，2026-11-08）

**方式**：只读，没有编译，也没有运行。示例 12 个用 `tools/next_batch.sh` 阅读（FULL_READ）；另外对 `Common/Data/Market/QuoteBar.cs` 读了第 15–240 行（去掉文档注释和 using 行），状态记为 PARTIAL（解析、克隆、更新等其余部分未读）。

## 一、覆盖范围
- FULL_READ 12 个示例（清单见 coverage 表 batch=L051）：Stochastic 预热、连续期货模板、共享订阅、期权未平仓量、自定义数据 universe、Insight 标签、期货延长时段、EUREX 映射模式回退、Math.NET 组合优化、定时 universe 与预热、希腊值筛选、期货 Session K 线。
- PARTIAL 1 个：`Common/Data/Market/QuoteBar.cs`。

## 二、发现（静态阅读）
1. **CONFIRMED（源码）：QuoteBar 的 OHLC 取买卖价的中间价。**
   - `Open/High/Low/Close` 的 getter：买价和卖价都存在且非 0 时返回 `(Bid.X + Ask.X) / 2`；只有一侧时返回那一侧；都没有时 Close 返回 `Value`。
   - 因此 **High = (买价最高 + 卖价最高) / 2**，Low 同理，并不是"真实中间价序列"的最高/最低。
   - 示例 SecuritySessionWithFutures 用报价 tick 自行累计 Session K 线时也按这种方式计算（mid 的开收、bidHigh 与 askHigh 的平均）。
   - 对 V1.2：MT5 图表的 K 线按 **Bid** 绘制。若 LEAN 中 XAUUSD 的指标、供需区、止损距离基于 QuoteBar 的 Close/High/Low，会与 MT5 相差约半个点差，点差放大时（开盘、数据发布）偏差更大。跨引擎核对应在 LEAN 中显式使用 `Bid` 或 `Ask` 子 K 线。→ 待汇总 R32。
2. **EUREX 期货不支持按未平仓量映射**（FutureDataMappingModeFallback）：会自动回退为 LastTradingDay 并发警告；对已添加的连续合约再次添加不同映射模式会被忽略并警告。与 V1.2 无直接关系。
3. `PortfolioOptimizationNumericsAlgorithm` 中无风险利率写死为 0.01，与 L016 中"无风险利率缺省回退 1%"的口径无关，仅为示例常数。
4. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 153 个。
