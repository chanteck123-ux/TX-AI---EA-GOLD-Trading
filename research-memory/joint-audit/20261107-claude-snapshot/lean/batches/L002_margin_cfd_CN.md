# LEAN L002：保证金、购买力、CFD 和 Forex 默认模型（Claude，2026-11-06）

- **FULL_READ（13 个）**：
  - `Common/Securities/` 下 BuyingPowerModel.cs、SecurityMarginModel.cs、DefaultMarginCallModel.cs；
  - `Cfd/` 下 Cfd.cs、CfdHolding.cs、CfdExchange.cs、CfdCache.cs、CfdDataFilter.cs；
  - `Forex/` 下 ForexHolding.cs、ForexExchange.cs、ForexCache.cs、ForexDataFilter.cs，以及 Forex.cs（构造函数部分与第二个构造函数结构相同，已全部看到）。
- **PARTIAL**：`Common/Brokerages/DefaultBrokerageModel.cs`，只读了 GetLeverage、GetFillModel、GetFeeModel、GetSlippageModel、GetBuyingPowerModel 几段。
- 只读，未编译，未运行。

## 一、默认值（CONFIRMED）
| 项目 | CFD | Forex | 出处 |
|---|---|---|---|
| 成交模型 | ImmediateFillModel，即基类 FillModel | 同左 | Cfd.cs、Forex.cs、DefaultBrokerageModel.GetFillModel |
| 手续费 | `ConstantFeeModel(0)`，**为 0** | 构造时用 InteractiveBrokersFeeModel；通过 DefaultBrokerageModel 设置时为 `ConstantFeeModel(0)` | 同上 |
| 滑点 | NullSlippageModel，**为 0** | 同左 | 同上 |
| 杠杆 | **50**（`SecurityMarginModel(50m)`，DefaultBrokerageModel 也返回 50） | 50 | 同上 |
| 年交易日数 | 313（365 减去周六） | 313 | CfdExchange、ForexExchange |
| 数据过滤 | 不过滤 | `Filter` 恒返回 true（注释："FXCM 数据很干净"） | DataFilter |

**含义**：V1.2 要求的 1:1000 杠杆必须显式 `SetLeverage(1000)` 或使用自定义券商模型，否则 LEAN 默认是 1:50。手续费和点差成本也必须**显式设置**，默认值为 0。

## 二、保证金计算（CONFIRMED）
- 初始保证金 = `QuoteCurrency.ConversionRate × ContractMultiplier × security.Price × 数量 × (1/杠杆)`。
  - 使用的是 `security.Price`，即最后价，**不区分 Bid 和 Ask，也不使用开仓价**。
  - 杠杆是单一常数，**没有分档**。按手数分档的保证金和品种单独的保证金率都无法表达。MT5/FxPro 的 GOLD 保证金规则（计算模式、按品种和按量的限制）必须另外核验，与 AGENTS.md 中"分别核验并留证"的要求一致。
- 用杠杆构造时，初始保证金率等于维持保证金率，都是 1/杠杆。
- 下单检查的初始保证金还包含手续费：`orderMargin + sign × fees`。
- **只减仓或平仓的订单总是视为保证金充足**：判定条件为 `holdings × order < 0` 且 `|holdings| ≥ |order|`。这与 V1.2"保护和退出优先于新增风险门控"的原则一致。
- 反手（反方向开仓）时，可用保证金会加回当前持仓的维持保证金，再加上同等数量的初始保证金，作为近似。
- 按目标仓位计算数量时，按 LotSize 向"不超过目标"的方向取整，并迭代把手续费计算在内；不收敛时直接抛出异常。

## 三、追加保证金和强平（CONFIRMED）
- 剩余保证金不超过总权益的 5% 时发出警告。
- **只有在剩余保证金 ≤ 0 且 已用保证金 > 总权益 × 1.1 时才强平**。换算成保证金比例（权益 ÷ 已用保证金），约在低于 90.9% 时触发。
- 强平顺序为**浮亏最大的持仓组优先**，每平一组后重新检查，剩余保证金回到 0 以上就停止。
- 这与 MT5 券商的 Margin Call 和 Stop Out 水平（按保证金比例计算，具体数值由券商设定）**不是同一个机制**。LEAN 的强平结果不能直接拿来代替 FxPro 的 Stop Out 判定，需要分别核对（取值未联网核实，本文不填写 FxPro 数值）。

## 四、对 V1.2 的登记项（没有执行任何测试）
- 跨引擎核对清单增加以下几项：杠杆是否设为 1000；手续费和点差模型是否显式设置；保证金价格口径（最后价，还是 Bid、Ask 或开仓价）；有无分档；强平阈值的口径。
- RiskExecution 的反例：LEAN 默认"减仓总是允许"可作为正例参照；而"手续费为 0、滑点为 0、杠杆为 50"这些默认值，必须在研究配置中被**显式覆盖并登记**，不能静默沿用。
