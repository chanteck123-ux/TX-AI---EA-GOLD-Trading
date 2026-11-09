# L080–L082 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L079，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 49 个）
- L080 18 个、L081 16 个、L082 15 个（`py_unread_sorted.txt` 第 198–246 行）。
- 主要内容：NLTK 情绪示例、期权过滤返回 None、跨式/蝶式/日历价差、券商端订单处理（完整版）、期权链一致性、VWAP 执行模型、基本面 universe、原始价格 universe、可做空数量提供者、期权行权/指派、MACD 趋势、Tick 周期历史限制、行业标准证券代码、运行时增删证券、配对交易 Alpha、Tick 交易所过滤、空购买力模型、Insight 权重组合、历史预热、按交易时段的日内合成器、自定义结算/期权定价模型、Intrinio 经济数据、原始数据与复权因子、TA-Lib、印度指数、指标历史窗口、自定义部分成交模型、两段货币换算、期权日线/小时线、命名参数、排队调度、Universe.UNCHANGED、数据标准化模式、期货期权日线、IB 理财顾问账户、期权拆股。

## 二、与 V1.2 有关的发现（静态阅读）
1. **按交易时段锚定的日内合成器**（MarketHourAwareIntradayConsolidationRegression）：`MarketHourAwareConsolidator(False, 7 分钟, TradeBar, TickType.TRADE, True)` 让每根 K 线从开盘时刻起算，且最后一根在收盘处截断，不跨越休市。XAUUSD 每日有约 1 小时休市；若 LEAN 研究用 M5 合成并要与 MT5 的 K 线边界一致，应比较三种方式（时钟对齐的 TimeSpan、按开盘锚定、MT5 原生 M5）的边界并登记，尤其是休市前后的那几根。
2. **自定义部分成交模型的 Python 写法**（CustomPartialFillModelAlgorithm）：每次只成交 10 股，按订单 ID 记录剩余数量，最后一次返回 FILLED；下单使用异步（第三个参数 True）。与 L067–L070 第 2 条相同的思路，可用于 LEAN 端模拟部分成交并检验 Core→RiskExecution 的状态处理（仅研究用途）。
3. **关闭保证金检查的模型**（NullBuyingPowerOptionBullCallSpreadAlgorithm）：`SecurityMarginModel.NULL` 加 `SecurityPositionGroupModel.NULL` 后，任意数量都能成交，`total_margin_used` 为 0。研究配置中若误用会使保证金约束失效，应在配置审查中列为禁止项（V1.2 新研究要求核验 1:1000 杠杆下的 LEAN 保证金模型）。
4. **日线数据的市价单在日收盘成交**（FutureOptionDailyRegression 注释）：只订阅日线时，订单按日收盘成交，示例因此安排"第一天买、第二天平"。与 R25（日线时市价单改为 MOC/MOO）一致。
5. **指标预热需要多一根数据**（WarmupHistoryAlgorithm 注释）：示例取 `slow_period + 1` 根历史数据，注释说明滚动窗口要等一个数据移出后才算就绪。研究中预热长度需按各指标的 `WarmUpPeriod` 核对，而不是简单等于周期。
6. **货币换算可以经两段路径**（TwoLegCurrencyConversionRegression）：没有直接货币对时，CashBook 会通过两个中间品种换算。V1.2 账户为 USD、XAUUSD 报价为 USD，不涉及；仅记录。
7. **示例代码问题（不影响引擎）**：
   - `BasicTemplateOptionsDailyAlgorithm`：到期时间断言用了 `and` 连接三个"不等"条件，只有月、日、时都不对时才报错，实际起不到校验作用。
   - `OptionSplitRegressionAlgorithm`：若当根没有期权链，`sorted_contracts` 会在未定义时被引用。
   - `BasicTemplateIndiaIndexAlgorithm` 同样把 `_ema_slow` 设为 80、`_ema_fast` 设为 200。
   - `CustomBrokerageSideOrderHandlingRegressionAlgorithm` 的消息处理器 `__init__` 没有调用父类构造函数（Partial 版本有调用）。
   - `BasicTemplateIntrinioEconomicData` 的用户名/密码、`FinancialAdvisorDemoAlgorithm` 的账户号均为占位值。
8. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 224 个；下一批从 `py_unread_sorted.txt` 第 247 行开始。
