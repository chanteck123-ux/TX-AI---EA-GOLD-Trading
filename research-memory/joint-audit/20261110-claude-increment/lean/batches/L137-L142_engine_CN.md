# L137–L142 Engine 目录（剩余 208 个文件，至目录读完）— Claude 阅读笔记

- 日期：2026-11-09
- 方法：`dump_batch.sh` 生成带行号的源码（略去许可证头、using、`///` 文档注释），共 13 批（E1–E13），标记为 FULL_READ，方法名 `CAT_N_CODE_EXCL_LICENSE_BLANK_USINGS_XMLDOC`。
- 范围：之前第 1 层已读的 Engine 文件（交易处理、回测券商、主循环、结果处理等）之外的全部剩余文件，包括：
  - 数据馈送：DataFeeds、Enumerators、Transport、WorkScheduling；
  - HistoricalData、RealTime、Results/Analysis；
  - LiveTradingResultHandler、RegressionResultHandler（此前延后的第 4 层文件）；
  - Setup、Storage、Server；
  - Engine.cs、csproj 和 AssemblyInfo。
- 完成情况：**Engine 目录 UNREAD 0**。标记后 LEAN UNREAD 为 3,780，FULL_READ 为 2,089。
- 性质：只读审计，未编译、未运行。

## 新增待汇总条目（已写入 recheck request）

### R47：填充 bar 会进入合成器、指标和 K 线形态，填充分辨率取全局最小值
- **FillForwardEnumerator**：市场开放时段内没有新数据，就按 `fillForwardResolution` 生成填充 bar。
  - 填充 bar 由前一根 bar `Clone(true)` 得到，OHLC 整根复制。
  - 只有 TradeBar 把 Volume 置 0；QuoteBar 的 Bid/Ask 也一并复制。
- **SubscriptionCollection**：填充分辨率取所有非内部订阅中的**最小分辨率**，默认 1 分钟。
  - 订阅变化时，回测会重启全部填充订阅。
  - 同时订阅 XAUUSD 分钟数据和小时级的关联市场（NR07）时，小时数据会按分钟生成填充 bar。
- **TimeSliceFactory 与 AlgorithmManager**：
  - TimeSliceFactory 第 175–264 行把填充 bar 放进 consolidatorUpdate，没有任何 IsFillForward 过滤；
  - AlgorithmManager 第 459–475 行逐个调用 `consolidator.Update(dataPoint)`。
  - 因此 M5 合成器和注册在其上的指标、K 线形态都会收到复制出来的 bar。
- **对 MT5 对照的影响**：
  - MT5 没有 tick 时不生成 bar。
  - 在交易清淡的分钟，LEAN 的 M5 bar 会混入上一分钟的 H/L。
  - 形态类把 Close==Open 记为阳线，与 R41 补充记录一致；复制 bar 也会影响形态判定。
- **SecurityCache 与 LastPointTracker**：两者会跳过填充 bar，只有价格缓存不受影响。
- **研究端要求**：
  - 须登记 FillDataForward 的设置；
  - 或在合成器或指标的输入端过滤 `IsFillForward`；
  - 并在对照报告中统计填充 bar 的数量。
- **SubscriptionFilterEnumerator**：会丢弃不在交易时段内（`IsOpen(Time, EndTime, extendedMarketHours)`）的 bar。
  - AddCfd 把扩展时段写死为 false（R40 (c)）。
  - XAUUSD CFD 在交易时段库中常规时段之外的数据会被直接丢弃，须对照 L-DATA3 已审计的交易时段库核实。

### 其他记录（未单列编号）
- **SubscriptionDataReader** 丢弃 EndTime 小于等于上一条的数据（重复时间戳只保留第一条）。
- **SubscriptionData.Create** 会把 Time 按 bar 周期向下取整（非严格日线结束时间的情况），保证时间点无前视。
- **AggregationManager** 在非 tick 订阅中丢弃 Suspicious tick（仅实盘路径）。
- **预热**：回测预热使用 `Settings.WarmupResolution`，预热段与正式段在 pivot 日重叠一天，再用 FilterEnumerator 去重。
- **BacktestingSetupHandler**：
  - MaxOrders 来自 `job.Controls.BacktestingMaxOrders`（与 R39 (a) 对应）；
  - MaximumRuntime 由 job.Controls 决定；
  - 交易日数在 `SetBrokerageTradingDayPerYear` 中设置（与 R31 对应）。
- **BrokerageSetupHandler（实盘）**：
  - 默认把 MarginCallModel 设为 Null；
  - 非 Paper 券商会先把 CashBook 清零，再从券商读取余额；
  - V1.2 不使用 LEAN 实盘，仅作记录。
- **小缺陷（第 4 层，V1.2 不受影响）**：
  - `ZipEntryNameSubscriptionDataSourceReader` 的私有方法 `OnInvalidSource(source, exception)` 调用自身，会无限递归，GetZipEntries 抛异常时可能导致栈溢出；
  - `ScheduledEventFactory.EveryDayAt` 用 `x < currentUtcTime` 过滤，保留的是过去的事件，方向疑似写反；
  - 两者均须 Codex 核对，暂不单列编号。
- **SineHistoryProvider / FakeHistoryProvider**：测试用的合成数据提供器，研究报告中不得误用其数据。

## 覆盖
- L137–L142 共 208 个文件 FULL_READ（另有约 4 个先前标为 PARTIAL 或第 1 层的文件未变）。
