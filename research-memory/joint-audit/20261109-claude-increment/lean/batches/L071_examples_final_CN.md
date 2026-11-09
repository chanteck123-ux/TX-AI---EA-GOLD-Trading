# L071 第 4 层：Algorithm.CSharp 收尾（Claude，2026-11-08）

**方式**：只读，没有编译，也没有运行。本批完成后 Algorithm.CSharp 目录 UNREAD = 0。

## 一、覆盖范围（4 个）
| 文件 | 状态 | 方式 |
|---|---|---|
| `OpeningBreakoutAlgorithm.cs`（551 行） | FULL_READ | Read 工具读全文 |
| `QuantConnect.Algorithm.CSharp.csproj`（61 行） | FULL_READ | 读全文 |
| `StressSymbols.cs`（6,913 行） | DATA_AUDITED | 第 1–36 行与第 6912–6914 行的代码已读；其余 6,875 行用正则逐行核对，均为 `"代码",` 形式的股票代码字面量，没有逻辑 |
| `Benchmarks/EmptyMinute400EquityAlgorithm.xlsx` | DATA_AUDITED | 二进制，只列出 zip 条目并读取 sharedStrings：是引擎性能记录表（commit / time / kpoints/sec / notes），不是 FULL_READ |

## 二、与 V1.2 有关的发现（静态阅读）
1. **OpeningBreakout 示例的做空分支方向写错**：做空入场写作 `MarketOrder(symbol, - -shares)`，双重负号等于 `+shares`，实际是买入；随后的保护单 `StopMarketOrder(symbol, -shares, ...)` 又是卖出。因此"做空"分支实际建立多头，并挂一张反向止损单。这个例子说明下单方向必须由单一来源（意图的 side 字段）推导，并在提交前校验"保护单方向与持仓方向相反"。V1.2 接口要求 TradeIntent 携带方向及初始 SL，由 RiskExecution 统一推导订单方向，正好对应这一风险。
2. **该示例的仓位算法与止损距离不一致**：股数按 `允许亏损 ÷ (0.1 × 日 ATR)` 计算，但实际止损设在当前 K 线最低/最高价外 0.1%，与 0.1×ATR 无关。若止损距离大于 0.1×ATR，实际单笔风险会超过预算。V1.2 的风险比例方案应以实际初始 SL 距离（含点差与滑点）计算手数，与此相反。
3. 示例先市价入场、再单独提交止损单（与 L056–L057 第 4 条同属"先成交、后补保护"的写法），日终用 `OnEndOfDay` 全部平仓。
4. **csproj**：目标框架 `net10.0`，依赖 QuantConnect.pythonnet 2.0.68、Accord 3.6.0、MathNet.Numerics 5.0.0、Newtonsoft.Json 13.0.2、NodaTime 3.0.5。只记录版本，未还原或编译。
5. `StressSymbols.ForexSymbols` 从 SymbolPropertiesDatabase 的 Oanda 外汇条目动态生成。

## 三、Algorithm.CSharp 收尾统计
- L025–L071 共完成第 4 层 C# 示例约 380 个（以 coverage 表 batch 列为准）。
- 新增待汇总（尚未发出）：R31（年化交易日数）、R32（QuoteBar 取中间价）、R33（两种胜率口径）。
- LEAN 全库（2026-11-08，L071 之后）：UNREAD 4,843，FULL_READ 1,026，DATA_AUDITED 643，PARTIAL 5，HASH_REUSE 5。
- 下一步：Algorithm.Python（第 4 层），然后 Algorithm.Framework、Tests 及其他模块。
