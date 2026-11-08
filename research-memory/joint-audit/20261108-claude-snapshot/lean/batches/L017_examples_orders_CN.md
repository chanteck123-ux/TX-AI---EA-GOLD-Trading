# L017 第 3 层起步：示例结构归组的结果、测试数据审计、订单类示例（Claude，2026-11-08）

**方式**：只读，没有编译，也没有运行。用户 2026-11-08 选择 A：第 3、4 层全部读完后，再统一交给 Codex 复核一次。

## 一、结构归组的结果（方法记录）
- 工具：`tools/structure_groups.ps1`。处理方式是去掉注释，把字符串和字符字面量换成 S、数字换成 N，压缩空白后计算哈希。
- 结果：Algorithm.CSharp 共 898 个文件，分成 898 组；Algorithm.Python 共 470 个文件，分成 470 组。**没有任何两个文件结构相同**，所以计划中"每组读一个代表、其余做差异核对"的方法用不上。
- 规模估算（规范化后的字符数）：
  - C# 示例约 186 万字符，其中 ExpectedStatistics 模板约 15 万；
  - Python 示例约 71 万字符；
  - Tests 下的 .cs 共 833 个文件，约 9.7 MB（原始大小）。
- 改用的方法：用 `tools/print_example.sh` 逐个文件阅读。跳过的部分有：
  - 14 行许可证头（脚本会先确认其中没有代码）；
  - 空行和 using 行；
  - ExpectedStatistics 字典里形如 `{"Total Orders", "1"},` 的回归统计模板行（每个文件跳过的行数都会打印出来，供核对）。
  - 其余行全部阅读。覆盖表里状态记为 FULL_READ，方法记为 `PRINT_EXAMPLE_EXCL_EXPECTED_STATS`。

## 二、测试数据审计 L-DATA4
- `Tests/TestData` 下的 csv、txt、json 共 170 个文件、143,733 行，用 `audit_text_data.ps1` 做逐行结构核对，状态为 DATA_AUDITED，结果在 `coverage/data_tests_audit.csv`。其中 txt 文件经抽查，全部是 CSV 格式的指标数据。
- `FuturesExpiryFunctionsTestData.xml`（1.3 MB）：XML 能完整解析，共 13,867 个元素，其中 Item 177 个，状态为 DATA_AUDITED。
- 6 个小型成交和权益测试数据文件（test_cash_*、test_forex_*）**全文读过**，状态为 FULL_READ。读取它们的测试是 `SecurityPortfolioManagerTests` 中的 TestCashFills 和 ForexCashFills（第 95–240 行，本批只读到这里，该测试文件仍为 UNREAD）。
  - 其中 `test_forex_equity.xml` 的小数带千分位逗号（如 "100,033.33"），读取时依赖 `Parse.Decimal` 能够容忍这种格式。

## 三、订单类示例（FULL_READ，4 个）
**OneCancelsOtherOrderRegressionAlgorithm、BracketOrderRegressionAlgorithm、TrailingStopOrderRegressionAlgorithm、StopLimitOrderRegressionAlgorithm**

1. OCO 示例：一组三张平仓单（止盈限价单、止损单、更远的止损限价单）。其中一张成交后，另外两张被撤销，撤单消息里包含 "Contingent sibling order"。`GetOpenOrdersRemainingQuantity` 返回 −100（同组只计最大的一张），与 L014 的记录一致。
2. 括号单（OTOCO）示例：
   - 市价开仓单在**提交的同一时刻就成交**；
   - 止盈和止损两张子单在同一个 UtcTime 被触发，开始生效；
   - 其中一张成交后，另一张在**同一时刻、紧接着**被撤销。
   - 这说明 LEAN 中有父子关联的 OCO 不会出现两张都成交的情况。与之对照，L015 中的分析器针对的是没有关联的两张独立挂单。
3. 跟踪止损示例：
   - 止损价在 OnData **之后**用当前 K 线更新，所以判断用的是上一根 K 线的高低价；
   - 有报价数据时，买单用 Ask.Low，卖单用 Bid.High，与 L001 记录的"按买卖价分边"一致。
4. 止损限价示例：成交时要求 StopTriggered 已经设置，并且触发时间早于或等于成交时间，成交价不能比限价差。
5. 这四个示例**全部用 SPY 股票**，没有外汇或 CFD 的示例，所以不能直接证明这些行为在 XAUUSD CFD 上同样成立。

## 四、进度与工作量（如实说明）
- 由于结构归组无效，第 3 层必须逐个文件阅读。按本批的速度估算，LEAN 示例加测试约 2,400 个文件，**需要数十轮**，远多于此前估计的 5–10 轮。QuantSkills 的测试另算。
- 阅读顺序：先读 V1.2 相关的示例（这一类共 173 个文件、约 25,000 行，按文件名关键词筛出），然后读其余示例，再读 Tests。

## 五、第二批示例（FULL_READ，12 个）
- **阅读方法补充**：除了 print_example.sh 外，再用 grep 去掉回归模板的固定注释行和属性行，包括 CanRunLocally、Languages、AlgorithmHistoryDataPoints、ExpectedStatistics 的声明行，以及只有大括号的行。**保留** DataPoints 和 AlgorithmStatus，因为它们可能表明预期结果是运行出错。覆盖表的 note 中已注明。
- 文件：
  - ForexMultiResolution
  - ForexInternalFeedOnData（SameResolution 和 HigherResolution 两个）
  - MarginCallClosedMarket
  - NoMarginCallExpected
  - BacktestingBrokerage
  - OneTriggersOtherOrder
  - OneUpdatesOtherOrder
  - HourMarketOrderFillsAtBarClose
  - RestingMarketOrderFillsAtBarOpen
  - MarketOrderStaleDataFill
  - HourResolutionMarketOrderStalePrice

6. **外汇日线的时间戳**：示例注释显示，Oanda 的 EURGBP 日线 K 线时间是纽约时间**晚上 8 点**（2013-10 处于夏令时，相当于 UTC 0 点），而不是纽约 17:00 的外汇日切。日线数据会被前向填充到小时级的时间切片中。V1.2 的"服务器日"按 FxPro 的定义，**和 LEAN 外汇日线的分界不同**，跨引擎对照时要先对齐日期。
7. **内部换汇数据源**：添加 EURGBP 时，LEAN 会自动加入 GBPUSD 的内部订阅，用于把盈亏换算成账户货币。这个订阅不会推送到 OnData。之后用户再添加同一品种时，会改成普通订阅。
8. **（重要）市价单默认可以用旧价格成交**：
   - 引擎默认的 `StalePriceTimeSpan` 是 **1 小时**，示例注释原话为 "the engine default is one hour"；
   - 用小时级数据时，在 K 线中途下的市价单会**立即**按最新一根 K 线的**收盘价**成交，而这个价格最多已经过去将近一小时；
   - 在休市时提交、到下一根 K 线才成交的挂单，按那根 K 线的**开盘价**成交，相当于 MarketOnOpen；
   - 只有把 StalePriceTimeSpan 调小（例如 1 分钟），K 线中途的单才会等到下一根 K 线收盘再成交；
   - 分钟级数据下，引擎不会用比一个周期更旧的价格成交（MarketOrderStaleDataFill）。
   - 这些都是示例中写明的**预期**行为，没有运行验证。
   - 对 V1.2 的影响：如果 LEAN 研究用小时线或日线，成交价比真实逐笔成交乐观，而且没有滑点。和 MT5 真实逐笔回测对照时，必须写明数据频率和 StalePriceTimeSpan 的设置。
9. **部分成交**：LEAN 默认的回测成交模型会一次全部成交。只有在示例里自己写成交模型时才会出现部分成交（BacktestingBrokerage 中的 PartialMarketFillModel，OUO 中每次成交 40 股的限价成交模型）。所以 **V1.2 RiskExecution 的部分成交测试不能依靠 LEAN 的默认行为**，要自己构造部分成交。
10. **OUO（一张成交，另一张同比例减量）**：部分成交后，兄弟订单会**按比例**减少剩余数量（−200 → −120 → −40），完全成交后兄弟订单被撤销。这个做法可以作为 V1.2 中"止盈部分成交后同步调整止损数量"的参考规则。
11. **OTO（一张成交后触发其他订单）**：父单成交后，被触发的市价子单（以及子单再触发的孙单）在**同一个 UtcTime** 成交，中间没有任何延迟。
12. PatternDayTrading 保证金模型（美股日内交易规则，属于第 4 层的股票内容）：收盘前 10 分钟切换到隔夜杠杆，所以在收盘前持有超出隔夜杠杆的仓位会触发 margin call。

## 六、第三批示例（FULL_READ，4 个）
文件：ContingentOrderCancel、ContingentOrderUpdate、ContingentTrailingStopOrder、InsufficientMarginOrderUpdate。

13. **撤销联动订单**：
    - 撤销父单时，它会触发的子单、孙单都会一起撤销，撤单消息为 "Contingent parent order N was canceled"；
    - 撤销 OCO 组中的任何一张，其余兄弟订单也一起撤销，即使它们还在等待父单触发；
    - `Liquidate()` 会撤销全部挂单，然后平仓。
14. **被触发的限价单和止损单要等新数据才能成交**：
    - 开仓单成交后，止盈止损子单开始生效，但不会用触发那一刻的数据成交，要等**下一分钟**的数据，示例中写明止盈"在开仓后一分钟"成交；
    - 这和第 11 条不矛盾：被触发的**市价**子单是立即成交的。
    - 还没被触发的子单可以修改价格。修改成"可立即成交"的价格后，在父单成交前也不会成交。已经关闭的订单不能再修改。
15. 被触发的跟踪止损单，止损价以**触发那一刻**的市场价为起点开始跟踪。
16. **InsufficientMarginOrderUpdate**（EURUSD）：
    - 示例用 `CalculateOrderQuantity("EURUSD", 50m)` 下单，也就是按**组合价值的 50 倍**下单，靠外汇的高杠杆实现；
    - 之后把三张挂单的数量改成原来的 100 倍，这些改单都会因为保证金不足被拒绝，消息为 "Brokerage failed to update order"，原订单不变。
    - **CONFIRMED：这个测试本身有缺陷**。第 104 行和第 109 行用 `orderEvent.Id`（订单事件的编号）去和 `OrderId` 比较，应该比较的是订单编号。所以限价单和跟踪止损单这两条"改单被拒"的断言**实际上几乎不会被执行**，只有止损单那条（第 99 行）比较正确。这意味着限价单和跟踪止损单改单时的保证金检查，没有被这个测试真正覆盖。
    - 文件中的 `Languages` 只有 C#。
