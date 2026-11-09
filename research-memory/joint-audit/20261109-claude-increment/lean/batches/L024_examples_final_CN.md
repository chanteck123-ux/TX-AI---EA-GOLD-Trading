# L024 第 3 层：V1.2 相关示例最后一批（Claude，2026-11-08，用户要求连续执行）

**方式**：只读，没有编译，也没有运行。阅读方法同 L022（`tools/read_batch.sh`）。

## 一、覆盖范围（FULL_READ，20 个，均在 Algorithm.CSharp 下）
- InteractiveBrokersBrokerageDisablesIndexOptionsExercise、ComboLimitOrder、UpdateOrderLiveTest、DelistedFutureLiquidateFromChainAndContinuous、LiquidatingMultipleOptionStrategies、InsufficientBuyingPowerForAutomaticExercise、CompleteOrderTagUpdate
- ExecutionModelOrderEvents、OptionOTMExpiryOrderHasZeroPrice、ShortableProviderOrdersRejected、ContinuousFutureOpenPositionsLiquidationOnDelisting、RevertComboOrderPositions、ContingentComboOrder、FuturesAndFuturesOptionsExpiryTimeAndLiquidation
- ComboOrdersFillModel、StrictEndTimeLowerResolutionFillForward、SetAccountCurrencySecurityMarginModel、SingleOptionPositionGroupBuyingPowerModel、SetAccountCurrencyCashBuyingPowerModel、ComboOrderTicketDemo

## 二、发现（静态阅读，没有运行验证）
1. **LEAN 有原生的条件单（OTO / OCO）**（ContingentComboOrder）：
   - `OneTriggersOtherOrder(父单, OneCancelsOther(子单A, 子单B))`：父单全部成交后才触发两张子单；其中一张成交，另一张自动撤销。每张票据带 `Contingency`，可以查看 Parent/Child 角色和是否已触发。
   - 对 V1.2：MT5 没有原生 OCO，"入场成交后挂 SL/TP，一边成交撤另一边"要由 RiskExecution 自己实现。LEAN 中如果用这个原生功能做研究，就相当于"零延迟、原子撤单"，比 MT5 实际情况理想，跨引擎对照时要写明。
2. **已成交或已撤销的订单只能改 tag**（CompleteOrderTagUpdate）：改数量会被拒绝，改 tag 会成功，并同步到订单对象。V1.2 对账可以参考这一规则：终态订单的业务字段不可变，只允许追加注释。
3. **执行模型也能收到订单事件**（ExecutionModelOrderEvents）：`ExecutionModel.OnOrderEvent` 收到的是**全部订单**的事件，不只本模型下的单；需要自己按 OrderId 过滤。事件顺序与算法的 OnOrderEvent 完全一致。对 V1.2：Core 与 RiskExecution 若各自订阅成交回报，必须按归属（magic / ticket）过滤，否则会误处理别的模块的单。
4. **可卖空数量限制**（ShortableProviderOrdersRejected）：超过最大可卖空数量的下单被拒（状态 Invalid），改单超限返回 `ExceedsShortableQuantity` 错误码，但原单仍可撤销；判断时会把**已有持仓和挂单合计**。这与 V1.2"既有风险全额计入"的要求同一思路。
5. **期货合约到期后自动平仓，平仓后不可再下单**（ContinuousFutureOpenPositionsLiquidationOnDelisting 等三个）：连续合约换月时，旧合约的持仓在退市时被强制平掉；退市后对该合约下单为 Invalid。期货平仓时间可比预期早 1 分钟。示例结尾的错误提示写 "Expected 3 liquidation events"，但检查的是 2 次，属于提示文字错误。XAUUSD CFD 无到期，此项只作参考。
6. **期权行权保证金不足会触发 margin call**（InsufficientBuyingPowerForAutomaticExercise）：即使保证金不够，空头期权仍会被自动行权，之后再对正股发出 margin call。OTM 到期的期权，行权单价格为 0，并计入一笔交易（GH 4854，交易笔数因此偏多）。
7. **组合单的部分成交**（ComboOrdersFillModel）：自定义成交模型可以让组合单按每次 50、20、10 的数量分批成交。示例的错误提示文字（leg limit 写成 20）与检查值（10）不一致，同属提示文字错误。
8. **账户币种不是 USD 时**（两个 SetAccountCurrency 示例）：手续费、盈亏按报价币种记账，再按汇率折算；示例允许 0.5%–1% 的汇率误差。`SetAccountCurrency` 只能调用一次，第二次调用被忽略。V1.2 账户是 USD，此项影响小，只在核对 XAUUSD 报价币种时参考。
9. 回测中组合市价单下单后立即成交，无法撤销（ComboOrderTicketDemo）；订单事件的 `Quantity` 是订单当前数量而不是 0。IB 券商模型不支持指数期权手动行权，但到期会自动行权。其余为期权组合、前向填充与日线精确结束时间的细节，属第 4 层内容，只记录已读。

## 三、进度
- **V1.2 相关示例（173 个）已全部读完**（L017–L024）。
- 下一步：其余 Algorithm.CSharp、Algorithm.Python、Algorithm.Framework 示例，然后是 Tests。
