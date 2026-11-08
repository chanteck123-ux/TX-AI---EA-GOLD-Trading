# L022 第 3 层：V1.2 相关示例续读（Claude，2026-11-08，用户要求连续执行）

**方式**：只读，没有编译，也没有运行。用 `tools/read_batch.sh` 阅读（即 print_example.sh 加上 L018–L021 用过的模板行、日志行、统计行过滤，另外去掉 `<meta name="tag">` 标签行），其余行全部阅读。

## 一、覆盖范围（FULL_READ，29 个，均在 Algorithm.CSharp 下）
- MultipleUniverseSelectionOrder、BrokerageModelAlgorithm、CanLiquidateWithOrderProperties、CryptoBaseCurrencyFee（父类）、FillForwardEnumeratorOutOfOrderBar、EquityDottedTickerAdditionOrder、ContinuousFutureLimitIfTouchedOrder
- OptionShortCallMarginCallEvents、FillForwardFromWarmUp、ComboLegLimitOrder、TradeStationBrokerageTradeWithOutsideRegularMarketHoursParameter、NoMarginCallOutsideRegularHours、ShortInterestFee、MarketOrdersAreSupportedOnExtendedHoursForFutures
- FillForwardResolutionAdjustedOnRemoval、OrderTicketAssignmentDemo、FillForwardStrictEndTimeHour（父类）、OptionOrdersOnSplit、SplitPartialShare、ScaledFillForwardData、OnWarmupFinishedOrdering、SetCashOnData
- MarketOnCloseOrderFillsOnCloseTradeWithTickResolution、MarketOnOpenOrderFillsOnOpenTradeWithTickResolution、OptionStrategyMarginCallEvents、LiquidatingDistribution、EquityMarginCall、CoveredCallComboLimitOrder、NullBuyingPowerOptionBullCallSpread

## 二、发现（静态阅读，没有运行验证）
1. **券商模型的下单前检查**（BrokerageModelAlgorithm）：自定义券商模型可以在 `CanSubmitOrder` 中拒单，例如要求账户里始终保留至少 500 美元现金，并返回原因消息。这一点可以作为 V1.2 在 LEAN 研究中模拟"账户级风控"的做法。
   - **但示例中有一个反例**：下单被拒后，示例把 SetHoldings 的比例每次乘以 0.95 再试，**直到被接受为止**。这正是 V1.2 禁止的"静默缩小下单量"（AGENTS.md：固定表仓位不被风险比例公式静默缩量）。
2. **异步下单时，订单事件可能比下单函数先返回**（OrderTicketAssignmentDemo）：示例注释写明，订单事件可能在 `_ticket` 变量被赋值**之前**就到达，所以在 OnOrderEvent 里必须用 `orderEvent.Ticket` 取票据，而不能用成员变量。
   - 对 V1.2 的启示：对账逻辑要能处理"下单调用还没返回，成交或回报已经到达"的情况。
3. **margin call 只在正常交易时段触发**（NoMarginCallOutsideRegularHours、EquityMarginCall）：
   - 两个示例都断言，强平单只在交易所开市时生成；
   - 期权组合的 margin call 每次只减 1 个单位（OptionStrategyMarginCallEvents）；
   - 股票 margin call 之后，`MarginRemaining` 重新变为非负。
   - 所以在 LEAN 里，周末或休市期间即使保证金已经不足，也要等开盘后才会处理。MT5 的 Stop Out 同样只能在有报价时执行。两边对照时要注意跳空开盘的情形。
4. **关闭保证金检查**（NullBuyingPowerOptionBullCallSpread）：使用 `SecurityMarginModel.Null` 加 `SecurityPositionGroupModel.Null`，可以完全跳过保证金检查，已用保证金始终为 0。这是和 L019 CustomBuyingPowerModel 同类的反例。
5. MOC 和 MOO 单在 tick 数据下，分别按**官方收盘价和官方开盘价**成交（示例写死了预期价格），成交事件中没有提示消息。
6. 期货在延长交易时段可以下市价单（ES，18 点以后）；TradeStation 券商模型在非正常时段只接受限价单，止损限价单会被拒绝。
7. 预热（warm-up）结束时，`OnWarmupFinished` 会在 StartDate 的时刻、第一条非预热数据到达之前触发（外汇 EURUSD 的场景，预热截止时间是星期中间的午夜）。预热期间的数据也会被前向填充到正式期间。
8. 其余几个文件属于第 4 层内容：股票拆股和分红、期权组合单、做空利息（ShortMarginInterestRateModel）、带点号的股票代码解析、多个 universe 的执行顺序、数据前向填充的细节。这里只记录已经读过，不展开。

## 三、进度
- V1.2 相关示例（173 个）已读 133 个，还剩 40 个。
