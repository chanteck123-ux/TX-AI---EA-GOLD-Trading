# LEAN L003：订单状态与订单事件（Claude，2026-11-06）

- **FULL_READ（3 个）**：`Common/Orders/` 下 OrderTypes.cs、OrderExtensions.cs、OrderEvent.cs。只读，未运行。
- **下一批**：Order.cs、OrderTicket.cs（30 KB）、OrderResponse*.cs、各订单类型，以及 Engine 中的 TransactionHandlers（部分成交和撤单流程的实际实现）。

## 发现（CONFIRMED）
1. **状态枚举**：
   - 共 9 个值：New=0、Submitted=1、PartiallyFilled=2、Filled=3、Canceled=5、None=6、Invalid=7、CancelPending=8、UpdateSubmitted=9。**4 号空缺**。
   - `IsClosed` 只包括 Filled、Canceled、Invalid 三种，**其余都算 open**，包括 None 和 CancelPending。
   - 对账时，"撤单请求已发出"即 CancelPending 仍然是 open，不能当作已关闭，这与 V1.2"CTrade 返回成功不等于成交"的原则一致。
2. **`IsFill`** 包括 Filled 和 PartiallyFilled。每个 OrderEvent 的 `FillQuantity` 是**本次增量**，`Quantity` 是订单总量。对账累加时必须按事件逐条累加增量，不能把 Quantity 当作已成交量。
3. **序列化会丢字段**：`OrderEvent.FromSerialized` 恢复了 LimitPrice、StopPrice、FillPriceCurrency、Id、Quantity 和 IsAssignment，但**没有恢复 `TriggerPrice`、`TrailingAmount`、`TrailingAsPercentage`**。用序列化事件重建 LimitIfTouched 或 TrailingStop 订单的状态时，会缺少这些字段。
   - 对 V1.2 的含义：状态持久化不能依赖类似的"部分字段序列化"。RiskExecution 的持久化用例需要逐字段往返测试（登记项，NOT RUN）。
4. 价格和数量的 setter 都经过 `Normalize()`，即去掉 decimal 尾随零，不改变数值。
