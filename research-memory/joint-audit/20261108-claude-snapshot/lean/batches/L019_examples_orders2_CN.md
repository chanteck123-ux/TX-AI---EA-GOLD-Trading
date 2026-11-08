# L019 第 3 层：订单类示例（续）、MOC/MOO、成交模型与 AlgorithmSettings（Claude，2026-11-08）

**方式**：只读，没有编译，也没有运行。示例的阅读方法与 L018 相同。

## 一、覆盖范围
- **FULL_READ 示例（16 个，均在 Algorithm.CSharp 下）**：
  - BracketOrderLimitEntry、LimitIfTouched、UpdateOrder、OrderImmutability
  - MarketOnCloseOrder、MarketOnOpenOrder、MarketOnCloseOrderBuffer、MarketOnOpenOrderSlippage、DailyResolutionMarketOrderConversion
  - CustomPartialFillModel、ForwardDataOnlyFillModel、CustomBuyingPowerModel
  - MinimumOrderSize、MinimumOrderMargin、NoMinimumOrderMargin、ImmediateExecutionModelMinimumOrderMargin
- **FULL_READ 源码（1 个）**：`Common/AlgorithmSettings.cs`，共 203 行。
- **补读**：`Common/Orders/Fills/FillModel.cs` 第 297–312 行、第 1018–1085 行。这个文件在 L001 已 FULL_READ，这次是回头核对；`EquityFillModel.cs` 只用 grep 看了与 stale 相关的行，仍为 UNREAD。

## 二、发现（静态阅读，没有运行验证）
1. **CONFIRMED（源码）：几项默认设置**（`AlgorithmSettings` 构造函数）：
   - `StalePriceTimeSpan` = **1 小时**；
   - `FreePortfolioValuePercentage` = 0.25%（SetHoldings 预留的缓冲）；
   - `MinimumOrderMarginPortfolioPercentage` = 0.1%，保证金低于组合价值 0.1% 的 SetHoldings 小额调仓会被忽略；
   - `LiquidateEnabled` = true，`DailyPreciseEndTime` = true；
   - `IgnoreUnknownAssetHoldings` 默认 true，所以账户里有 LEAN 不认识的持仓时，算法不会终止；
   - `DatabasesRefreshPeriod` = 1 天。
2. **CONFIRMED：旧价格的判断方式，注释与代码不一致。**
   - `AlgorithmSettings` 和 `FillModel.ShouldWaitForFreshData` 的注释都说：分钟、秒、tick 数据"仍按旧价格成交，只加一条警告"。
   - 实际调用的是 `ShouldWaitForFreshDataOnStale`。它的逻辑是：小时和日线一律等新数据；分钟级只要最新数据落后超过一个周期，也会等新数据；只有 tick 数据从不等待。旧注释已经过时，示例 MarketOrderStaleDataFill 的预期也与新逻辑一致。
   - **更重要的是**：通用 FillModel（外汇和 CFD 用的就是它）第 304 行只有在"价格结束时间 + StalePriceTimeSpan < 下单时间"时才判定为旧价格。所以在默认的 1 小时内，**分钟数据即使中断 30 分钟，市价单也会直接按 30 分钟前的价格成交，不等待，也不加警告**。
   - 对 V1.2 的影响：XAUUSD 在休市前后，或数据有缺口时，LEAN 的成交价可能比实际更理想。对照 MT5 时，建议把 StalePriceTimeSpan 调小，并把成交时间和数据时间的差值记录下来。
3. **CONFIRMED（示例 DailyResolutionMarketOrderConversion、MarketOnOpenOrder）：市价单会被自动改成其他订单类型。**
   - 只订阅日线时，盘中下的市价单会被**自动改成 MarketOnClose**，按当天收盘价成交；
   - 在 MOC 提交截止时间之后下的，会改成 **MarketOnOpen**，按下一个开盘价成交；
   - 小时线在午夜（休市）下的市价单，也会被改成 MarketOnOpen；
   - 分钟级订阅不会被改。
   - 订单类型改了，`OrderType` 也随之改变。策略如果按"市价单"做统计，就会出现偏差。
4. MOC 的提交截止时间 `MarketOnCloseOrder.SubmissionTimeBuffer` 是一个**全局静态变量**，示例里修改后，要在结束时手动改回 `DefaultSubmissionTimeBuffer`，否则会影响同一进程中的其他算法。开盘价单（MOO）的滑点以开盘价为基准计算（GH 9753）。
5. **括号单的限价开仓**：止盈和止损在开仓成交前一直被挂起，不计入未成交数量，也不会成交。开仓成交后，它们**严格晚于**触发时间才成交。同一个下单请求不能提交两次，第二次会抛出 ArgumentException。
6. **订单对象的保护**：`Transactions.GetOrderById` 每次返回的都是**副本**，修改副本不会影响真实订单，只能通过 OrderTicket 修改。这种"状态只有一个所有者"的设计，可以作为 V1.2 RiskExecution 订单状态管理的参考。改单、成交、撤单会分别更新 LastUpdateTime、LastFillTime 和 CanceledTime，它们都等于对应事件的时间。
7. **成交模型示例**：
   - `ForwardDataOnlyFillModel` 只用下单**之后**才到达的数据成交，示例说明称这样更保守，可以避免用旧数据成交。**建议 V1.2 在 LEAN 研究中采用类似的保守成交模型。**
   - `CustomPartialFillModel` 每次只成交 10 股。
   - `CustomBuyingPowerModel` 演示了如何**完全关闭购买力检查，并把维持保证金设为 0**，以避免 margin call。这是一个反例：如果研究配置用了类似模型，保证金和强平的结果就会失真。
8. 最小下单量：Bitfinex 的 BTCUSD 低于最小下单量时，状态为 Invalid；改单后低于最小量，这次改单会失败，原订单保持不变。
9. LimitIfTouched 示例中，按默认手续费模型，SPY 每笔收取 1 USD。

## 三、仍未读
V1.2 相关示例（173 个）已读 53 个，还剩 120 个，之后是其余示例和 Tests。
