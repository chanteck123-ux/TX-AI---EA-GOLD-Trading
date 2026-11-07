# LEAN L006：请求处理线程池与回测券商（Claude，2026-11-07）

- **FULL_READ（3 个）**：
  - `Engine/TransactionHandlers/OrderRequestProcessingPool.cs`，去掉 XML 注释后 352 行；
  - `Brokerages/Backtesting/BacktestingBrokerage.cs`；
  - `Brokerages/Backtesting/BacktestingBrokerageFactory.cs`。
- 只读，未编译，未运行。

## 一、请求线程池（CONFIRMED）
- **回测模式**：同步执行，由算法线程自己处理队列（`Synchronous`）。
- **实盘模式**：开启并发时，线程数在最少 2、最多 10 之间按需增加；不开并发时只有 1 个线程。
- **同一订单的请求严格按到达顺序执行**：按 key（contingency → 组合单 → 订单号）把后到的请求排在后面，不同订单之间可以并行。这是一个可借鉴的设计：**同一订单的提交、改单、撤单必须串行处理**。
- **关闭时**：先停止接收新请求，再给工作线程 60 秒处理积压。仍卡住的线程会被中断，并再等 5 秒。超过期限还留在队列里的提交请求，由交易处理器标为 Invalid（见 L005）。
- **PLAUSIBLE**：如果 `_processRequest` 抛出异常，`ProcessInOrder` 的 finally 只会减少忙碌计数，不会删除这个订单在 `_inFlight` 里的 key。之后同一订单的请求会一直排队等待，而该工作线程的 Drain 循环会经 `_onError` 退出。正常路径下券商调用的异常已经在交易处理器内部捕获，所以这种情况只在异常没被捕获时才会出现。

## 二、回测券商的成交时序（CONFIRMED）
1. **市价单可以在下单的同一时间点成交**。非市价单（限价、止损等）跳过 `order.Time == UtcTime` 的那次扫描，**从下一根数据开始才能成交**。所以基于收盘信号下的市价单，会按信号 bar 的 Current（收盘价）成交（见 L001）。MT5 Real Tick 下单则是在下一个 tick 成交，二者有系统性的时间差。
2. **OCO 的保守假设**：同一组 OCO 中，如果多个成员在同一根数据上都能成交，**止损类订单优先处理**，止盈排在后面。也就是同 bar 内先止损后止盈。这和 V1.2 回测"同 bar 内假设不利结果"的原则一致，可以作为跨引擎核对的固定项。
3. **成交前再次检查保证金**：成交时会重新检查一次保证金，不足就把订单置为 Invalid 并移除；处于 CancelPending 的订单除外。
4. **⚠ 部分成交不收手续费**：`BacktestingBrokerage.Scan` 只在 `Status == Filled` 且手续费为 0 时才调用 FeeModel。**PartiallyFilled 事件不会计算手续费**。默认成交模型总是全量成交，所以平时不会触发；但如果自定义成交模型会产生部分成交，前面每次部分成交的手续费都会漏掉。
5. 成交模型抛出异常时只记日志，订单仍留在待处理队列里，下次继续尝试。
6. TimeInForce 到期时，整组订单置为 Canceled。
7. `BacktestingBrokerageFactory` 默认的券商模型是 `InteractiveBrokersBrokerageModel`，**不是 DefaultBrokerageModel**。所以通过这个工厂运行时，杠杆、手续费等默认值要以 IB 模型为准，L002 中按 DefaultBrokerageModel 得出的默认值不一定适用。IB 模型尚未阅读，已列为待读。
8. **PLAUSIBLE，撤单结果与订单状态可能不一致**：`CancelOrder` 对组内每个订单，无论是否真的从待处理队列里删除成功，都会先发出 Canceled 事件。如果删除失败，函数返回 false，交易处理器会报"撤单失败"，但订单状态已经被 Canceled 事件改掉了，cancel-pending 记录也已被删除，所以不会回滚。最终表现为"响应说撤单失败，订单却显示已撤"。前置检查排除了已关闭的订单，所以只在罕见的竞态条件下才会出现。

## 三、对 V1.2 的登记项（NOT RUN）
- 跨引擎核对必须固定以下几点：市价单是在同一 bar 还是下一个 tick 成交；同 bar 内 SL 与 TP 的先后顺序；部分成交时手续费的计算口径。
- 同一订单的请求要串行；关闭时，未发出的请求要标记为"从未发送"。
- LEAN 研究配置中必须显式指定券商模型，不能依赖工厂默认的 IB 模型。
