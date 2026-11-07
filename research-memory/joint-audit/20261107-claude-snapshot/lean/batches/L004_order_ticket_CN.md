# LEAN L004：Order、OrderTicket、OrderResponse（Claude，2026-11-07）

- **FULL_READ（4 个）**：`Common/Orders/` 下 Order.cs、OrderTicket.cs、OrderResponse.cs、OrderResponseErrorCode.cs。只读，未编译，未运行。

## 发现（CONFIRMED，读代码得出）
1. **方向由数量符号决定**：`Direction` 根据 Quantity 的正负返回 Buy、Sell 或 Hold，数量为 0 时返回 Hold。订单的买卖方向没有单独存储；通过 `ApplyUpdateOrderRequest` 改数量就可能改变方向，**改数量的同时也就改了方向**，所以 update 请求需要单独校验。
2. **平均成交价**：`AddOrderEvent` 用全部 `IsFill` 事件的 `|FillQuantity| × FillPrice` 之和除以 `|累计 FillQuantity|`，并写回 `_order.Price`。也就是说，**订单的 Price 字段在成交后变成了平均成交价**，不再是下单时的价格。期权行权另有特殊处理。
3. **重复撤单防护**：已有撤单请求且它不是 Error 状态时，再次 Cancel 直接返回 `RequestCanceled` 错误，不会重复提交（ticket 本身和 TrySetCancelRequest 两处都有这道检查）。
4. **⚠ ticket 隐式转 int 的陷阱**：`implicit operator int(OrderTicket)` 在最近一次响应出错时返回**负的错误码**，例如 -3 表示保证金不足；只有没出错时才返回 OrderId。调用方如果把 ticket 当作订单号保存，可能存下一个负数错误码。
   - 对 V1.2 RiskExecution 的反例：请求 ID、订单号和错误码必须是三个不同的字段，不能共用一个整数。
5. **响应状态分为三种**：`Unprocessed` 是 OrderId 为 int.MinValue 的单例；`IsSuccess` 等于"已处理且无错误"。"已提交"不等于成功，"成功"也不等于成交。错误码 0 到 -35 是一个连续列表，例如 -15 表示 ExchangeNotOpen，-24 表示 AlgorithmWarmingUp。
6. **非法请求也会返回 ticket**：找不到订单的撤单或更新请求，同样返回一个 ticket，只是用 `_orderStatusOverride` 把状态强制设为 Invalid。所以对账时**不能根据"返回了 ticket"就认定订单存在**。
7. **CreatedTime 就是 Time**：后续的 update 不会改变 Time。ticket 的 `Time` 取的是最近一次请求的时间。
