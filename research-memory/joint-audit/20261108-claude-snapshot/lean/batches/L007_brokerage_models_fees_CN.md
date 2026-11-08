# LEAN L007：IB 与 Oanda 券商模型、手续费基础类（Claude，2026-11-07）

- **FULL_READ（8 个）**：
  - `Common/Brokerages/` 下 OandaBrokerageModel.cs、InteractiveBrokersBrokerageModel.cs；
  - `Common/Orders/Fees/` 下 IFeeModel.cs、FeeModel.cs、ConstantFeeModel.cs、OrderFee.cs、OrderFeeParameters.cs、InteractiveBrokersFeeModel.cs。
- 只读，未编译，未运行。

## 发现（CONFIRMED）
1. **CFD 默认杠杆因券商模型而异**：

   | 券商模型 | CFD 杠杆 |
   |---|---|
   | InteractiveBrokersBrokerageModel | **10** |
   | DefaultBrokerageModel、OandaBrokerageModel | 50（Oanda 继承 Default） |

   回测券商工厂的默认模型是 IB（见 L006），所以在不显式设置的情况下，**同一个 XAUUSD CFD 的杠杆可能是 10，也可能是 50**。V1.2 要求的 1:1000 必须在研究配置中显式设置并登记，FxPro 的实际 GOLD 规则则另行核验。
2. **Oanda 模型的限制**：
   - 只接受 Forex 和 CFD；
   - 只支持 Market、Limit、StopMarket、StopLimit 四种订单，**不支持 TrailingStop**；
   - **不支持 contingent 订单**（OCO、OTO）；
   - 只接受 GTC 时效；
   - 手续费为 0；
   - CFD 使用 AccountCurrencyImmediateSettlementModel 结算。
3. **IB 模型**：支持 OCO、OTO、OUO；trailing stop 只能由限价单或止损限价单触发；CFD 的手续费是**订单价值的 0.002%，按报价货币计，最低 1**（JPY 最低 40，HKD 最低 10），每笔订单单独计算。
4. **ConstantFeeModel 按每笔订单收取固定金额**，与手数无关，而且会取绝对值（负数会变成正数）。用它来模拟按手计算的佣金是错误的。
5. `FeeModel` 基类返回 0 USD；`OrderFee.Zero` 的币种是 NullCurrency。`OrderFee.ApplyToPortfolio` 从对应币种的现金中扣除费用，非账户货币的费用需要依赖汇率换算。
6. **PLAUSIBLE，方向可能写反**：`GetPotentialOrderPrice` 对市价**买单取 BidPrice、卖单取 AskPrice**。买入实际成交在 Ask，所以这里疑似写反了。这个函数只用于期权佣金分档（权利金 ≥ 0.1 等阈值），影响有限，需上游确认是否有意为之。
7. IB 外汇佣金分档：月成交额不超过 10 亿美元时为 0.2 bp，最低 2 USD。默认参数是"月成交额为 0"，即落在第一档。

## 对 V1.2 的登记项（NOT RUN）
- LEAN 研究配置必须显式写明：券商模型、杠杆、手续费模型（按手、按价值还是按单）、以及点差来源。这一点与 L001、L002 一致。
- 如果改用 Oanda 模型，就不能使用 trailing stop 和 OCO。V1.2 的保护单若依赖这两种订单，需要改用自定义模型或别的表达方式。
