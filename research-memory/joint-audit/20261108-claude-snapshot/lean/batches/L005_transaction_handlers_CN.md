# LEAN L005：Engine 交易处理（Claude，2026-11-07）

- **FULL_READ（4 个）**：`Engine/TransactionHandlers/` 下的 ITransactionHandler.cs、BacktestingTransactionHandler.cs、CancelPendingOrders.cs、BrokerageTransactionHandler.cs。
  - BrokerageTransactionHandler.cs 共 2,245 行，SHA-256 前 16 位为 cec865dbc56729c4。阅读方法：先去掉第 1–15 行许可证头、`///` XML 文档注释、空行和 using 行，剩下 1,671 行逐行读完；`//` 行内注释保留。
- **未读**：OrderRequestProcessingPool.cs（24 KB），放到 L006。
- 只读，未编译，未运行。

## 一、请求生命周期（CONFIRMED）
1. **提交时**：
   - 预热期间直接返回 `AlgorithmWarmingUp`；
   - 卖空数量超限时，回测中报错，**实盘中只发警告、照常下单**；
   - 先建 ticket，记录当时的 Bid、Ask、Close（OrderSubmissionData），再放入线程池。
   - 同步提交只等 **1 秒**，超时只记一条日志，**流程照样往下走，不会失败**。
2. **处理提交请求时依次做**：
   1. 数量按 LotSize **向零截断**（`Quantity − Quantity % LotSize`），例如 0.015 手在 LotSize=0.01 时变成 0.01；截断到 0 就作废；
   2. 价格按最小变动价位取整，用 `Math.Round`，C# 默认是"四舍六入五成双"，结果可能比原价更近也可能更远；
   3. 检查保证金是否充足；
   4. 检查券商模型是否接受；
   5. 调用 `PlaceOrder`。

   任何一步失败，都会把订单置为 Invalid，并发出事件。
3. **改单**：只有 New 状态的订单不能改（New 和 Closed 都拒绝，除非请求明确允许修改已关闭订单）。改单前会用"改后订单的克隆"重新检查保证金。**实盘中跳过 `CanUpdateOrder` 检查**，只在回测中检查。
4. **撤单**：
   - 先保存当前状态，然后立即把订单置为 **CancelPending**，并发出事件；
   - 券商撤单失败时，`RemoveAndFallback` 把状态**恢复为撤单前的状态**；
   - 如果撤单途中收到成交事件，`UpdateOrRemove` 会移除保存的状态，以成交为准。
   - 这套"保存、置待撤、失败回滚"的流程可以作为 V1.2 撤单状态机的参照。

## 二、事件处理中的风险点（CONFIRMED，读代码得出）
1. **⚠ 一批事件中只要有一个未知订单号，整批就被丢弃**：`HandleOrderEvents` 的第一个循环里，只要找不到某个 OrderId，就记录错误然后 `return`。此时同批中前面已经识别的事件也全部没有处理：状态没更新，成交没记入持仓，也没有通知算法。V1.2 对账的反例：**单条无法识别的回报不能阻断其他回报的处理**，应该隔离后单独告警。
2. **晚到的 Invalid 不覆盖已完成状态**：订单已经是 Filled 或 Canceled 时，后到的 Invalid 事件不会改写它的状态。这条规则合理，可以借鉴。
3. **成交记入持仓失败时只记日志**：`Portfolio.ProcessFills` 抛出异常时只记日志并发一条 Error，之后照样更新 ticket、发出事件。结果可能是 **ticket 显示已成交，持仓却没有更新**，两边不一致。TradeBuilder 出错时只记日志。
4. **OnOrderEvent 持锁运行**：用户的回调在锁内执行，回调慢会阻塞所有交易线程。超过 10 秒只警告一次，之后不再计时。
5. **券商侧改量的保护**：券商推送数量变更时，新数量不能小于已成交量，方向也不能改变，否则忽略。
6. **实盘现金同步**：距上次成交超过 10 秒才做现金同步；连续失败 5 次抛异常，算法停止。`AccountInstantlyUpdated` 为真时，直接用券商推送的现金覆盖本地值。
7. **⚠ 实盘只保留最近 10,000 个已完成订单**：超过上限就删除 OrderId 较小的订单和 ticket。长时间实盘时，**旧订单的历史会从内存中消失**。V1.2 的持久化和对账不能依赖引擎内存里的历史订单。
8. 停止时队列中还没发出的提交请求会被置为 Invalid，消息是"never sent to the brokerage"。改单和撤单请求只返回错误，不置订单为 Invalid，因为原订单已经发出去了。

## 三、对 V1.2 的登记项（NOT RUN）
- 回报批处理隔离：不能因为一条未知回报就丢弃整批。
- 成交与持仓必须一致：持仓更新失败时，应进入 RECONCILE_REQUIRED 之类的阻断状态，不能只记日志。
- 数量截断与价格取整都要登记：止损价取整的方向，必须是不增加风险的那一侧。LEAN 用的是"四舍六入五成双"，**不保证**这一点。
- 历史订单的保留上限与持久化分开处理。
