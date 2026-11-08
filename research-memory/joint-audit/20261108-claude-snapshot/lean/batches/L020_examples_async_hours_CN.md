# L020 第 3 层：异步下单、休市时下单、OnOrderEvent 异常、平仓变体（Claude，2026-11-08）

**方式**：只读，没有编译，也没有运行。阅读方法同 L018。

## 一、覆盖范围（FULL_READ，18 个，均在 Algorithm.CSharp 下）
- 异步版本（都是 1 行覆盖 `AsynchronousOrders => true` 的子类，父类已在 L017–L019 读过）：
  - StopLimitOrderRegressionAsync、StopMarketOrderAsync、TrailingStopOrderAsync、LimitIfTouchedAsync、MarketOnCloseOrderAsync、MarketOnOpenOrderAsync
- BacktestingAsynchronousOrders
- FillOutsideHours 的 5 个分辨率版本：Minute（基类）、Hour、Daily、Second、Tick
- OnOrderEventExceptionRegression、OrderSubmissionData、ScheduledEventsOrder
- LiquidateUsingSetHoldings、LiquidateAllExceptSpecifiedSymbol、SetHoldingReturnsOrderTickets

## 二、发现（静态阅读，没有运行验证）
1. **回测中"异步"下单实际是同步执行的**（BacktestingAsynchronousOrders）：
   - 即使设置 `asynchronous: true`，市价单在同一个时间步里就会提交并成交；限价单在同一时间步提交，状态为 Submitted。
   - 也就是说，**LEAN 回测默认不模拟下单延迟**。
   - 对 V1.2 的影响：主执行延迟按 0–250 ms 计算，这部分只能在 MT5 或自建模型中处理。LEAN 的研究结果相当于"零延迟"情形，对照时要写明。
2. **休市时下的市价单**（FillOutsideHours）：在 23:00 提交的市价单，**无论数据分辨率是多少（包括日线）都不会立即成交**，会等新数据到来。
   - 文档注释不一致：Hour、Second、Tick 三个子类的注释仍写着"日线会在休市时成交"，而基类和 Daily 子类的注释（以及断言）写的是"不会立即成交"。那几条旧注释已经过时。
3. **CONFIRMED（示例的预期状态为 `AlgorithmStatus.RuntimeError`）：OnOrderEvent 里抛出异常，整个算法会以 RuntimeError 终止**（GH 4947）。
   - 对 V1.2 的启示：成交和订单事件的处理函数里出现异常时，必须就地隔离、记录，并进入对账状态，不能让异常扩散，导致已有仓位的保护逻辑一起停摆。
4. **下单时的报价快照**（OrderSubmissionData）：每张订单都记录下单那一刻的 Bid、Ask、Last 价格，SPY 和 EURUSD 都有。可以用来事后核算滑点，也可以作为 V1.2 对账字段（下单时的报价）的参考。
5. **定时事件的顺序**：同一时刻注册的多个定时事件，按注册顺序依次执行，事件时间不会倒退。收盘后（16:05）的事件也会照常执行。
6. **平仓的几种变体**：
   - `SetHoldings(空列表, liquidateExistingHoldings: true, tag, orderProperties)` 可以把所有持仓平掉，并给所有订单统一打上 tag 和订单属性；
   - `SetHoldings(Spy, 1, true)` 会先撤销所有挂单、平掉其他持仓，再调整 SPY 的仓位；
   - SetHoldings 如果已经达到目标仓位，就不会生成订单，返回的票据列表为空。

## 三、补读 OrderTicketDemoAlgorithm（FULL_READ，681 行）
- **阅读方法补充**：本文件额外去掉了只做日志输出的 `Log(` 和 `Debug(` 行，以及空的 `//` 注释行，覆盖表的 note 中已注明。
7. 示例中逐一演示了七种订单的提交、修改和撤销：市价、限价、止损、止损限价、跟踪止损、开盘价单（MOO）、收盘价单（MOC）。
   - 注释写明，**只有市价单默认按同步方式处理**，下单那一行执行完就已成交，并称"这在实盘中同样适用"。这一说法没有在本审核中核实。
   - 异步市价单下单后立即尝试撤单，结果"有时能撤成功，有时已经先成交"。
8. 止损单的方向说明是正确的：多头方向的止损价高于现价，作为空单的止损；空头方向的止损价低于现价，作为多单的止损。这与 L018 中两个把止损挂反的示例正好相反，可以作为正确写法的参考。
9. MOC 和 MOO 单在成交前只能修改数量和 tag。订单事件中的 `Quantity` 是订单的当前数量（不是 0），`LimitPrice` 和 `StopPrice` 都有值；通过 `orderEvent.Ticket` 可以取到对应的票据。
