# L077–L079 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L076，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 67 个）
- L077 25 个、L078 22 个、L079 20 个（`py_unread_sorted.txt` 第 131–197 行）。
- 主要内容：指数期权价差/铁鹰/日历价差、SetHoldings 多目标、期权/期货 universe 历史、累积 Insight 组合、做空利息费、CFD 模板、扩展时段限价单、参数读取、训练事件超时、自定义基准、Range 合成器、印度市场、Binance 费用与 ImmediateExecution、MOO/MOC、券商事件回调、空保证金组、连续期货期权、证券 seed、期权链 universe、合成器起始时间、Python 自定义指标、Spread/StdDev 执行模型、仅用新数据成交的填充模型、期权指标、Tick 合成类型、异步下单的 ticket 赋值时机、券商端订单处理、MOC 提交缓冲、按日期规则再平衡、Renko 指标等。

## 二、与 V1.2 有关的发现（静态阅读）
1. **"只用下单之后的数据成交"的保守填充模型**（ForwardDataOnlyFillModelAlgorithm）：自定义 `EquityFillModel`，只有当缓存中 QuoteBar/TradeBar/Tick 的 `end_time` ≥ 下单时间时才调用默认成交，否则返回空 Fill。示例中 9:30 用小时线下单，到 10:00 新 K 线到达才成交。示例注释明说，目的是避免用下单前的旧数据成交、让成交更保守。这与 R24（默认 1 小时内旧价格直接成交）、R26（回测异步单同步成交）方向一致：LEAN 研究若要接近 MT5 的 0–250 ms 延迟口径，需要显式使用此类模型或另行建模，并在报告中登记。
2. **异步下单时，订单事件可能早于 ticket 变量赋值**（OrderTicketAssignmentDemoAlgorithm）：`asynchronous=True` 下单后，`on_order_event` 可能在 `self.ticket` 赋值之前触发；示例要求从 `order_event.ticket` 取 ticket，而不是依赖本地变量。这对应 V1.2 对账原则：以订单/成交回报中的标识为准（MT5 中为 ticket/deal/position），不依赖"下单函数返回后再记录"的本地状态。
3. **券商端订单（非算法发出的订单）可被接收或拒绝**（CustomBrokerageSideOrderHandlingRegressionPartialAlgorithm）：自定义 `DefaultBrokerageMessageHandler.handle_order` 决定是否接纳从券商端出现的新订单（示例按 tag 奇偶过滤）。概念上对应 V1.2 RiskExecution 对"人工单/外部单"的识别与归类；LEAN 只用于研究，此处仅作对照。
4. **按点差决定是否下单的执行模型**（SpreadExecutionModelRegression）：`SpreadExecutionModel` 只在点差足够窄时提交订单；`StandardDeviationExecutionModel` 只在价格偏离 60 分钟均值 2 个标准差时提交。XAUUSD 研究若需要点差门控，可参考此思路，但阈值须与 FxPro 实际点差分布核对。
5. **合成器可指定起始时间**（ConsolidatorStartTimeRegression）：`TradeBarConsolidator(timedelta(hours=1), start_time=timedelta(hours=9, minutes=30))` 使小时线从 9:30 起算。M5 合成若要与 MT5 服务器时间的 K 线边界对齐，可用此参数并登记。
6. **全局静态设置会影响其他回测**（MarketOnCloseOrderBufferRegression）：示例修改 `MarketOnCloseOrder.submission_time_buffer`，并在结束时复原，注释写明是为了不影响其他回归测试。与 L067–L070 第 3 条（SymbolPropertiesDatabase、MarketHoursDatabase 为全局状态）一致。
7. **自定义保证金利息模型**（CustomMarginInterestRateModelAlgorithm）：可以按持仓逐期调整现金。结合 R28（CFD/外汇默认无 swap），若 LEAN 研究要计入 XAUUSD 隔夜利息，需要自写此类模型，并用 FxPro 的 swap 表核对。
8. **示例代码问题（不影响引擎）**：`BasicTemplateIndexOptionsAlgorithm`、`BasicTemplateIndexDailyAlgorithm` 同样把 `ema_slow` 设为 80、`ema_fast` 设为 200；`BasicTemplateIndexDailyAlgorithm` 与 `ImmediateExecutionModelWorksWithBinanceFeeModel` 使用旧式大写方法名（`OnEndOfAlgorithm`、`Initialize`）；`FutureUniverseHistoryRegressionAlgorithm` 的类名写成 `OptionUniverseHistoryRegressionAlgorithm`；`TiingoPriceAlgorithm` 的 token 为占位字符串。
9. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 273 个；下一批从 `py_unread_sorted.txt` 第 198 行开始。
