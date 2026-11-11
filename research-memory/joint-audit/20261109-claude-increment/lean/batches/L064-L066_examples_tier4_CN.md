# L064–L066 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L063，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 18 个）
- L064、L065、L066 各 6 个；清单以 coverage 表中 batch 列为准。
- 主要内容：期权重新选取时的初始化、自定义指标预热、自定义数据自动 seed、加密货币模板（多币种现金）、期货框架 universe、Consolidate 重载计数、ETF 成分框架/RSI Alpha、期货期权单链选取、数据合成器入门、Bybit 加密期货、期货/指数期权 ITM 到期、Dropbox BaseData universe、指数期权链过滤器、NIFTY 自定义数据、基本面 universe、实盘通知与券商连接事件。

## 二、与 V1.2 有关的发现（静态阅读）
1. **`TimeSpan.FromDays(1)` 合成在回测末日少一根**（ConsolidateRegression）：按 TimeSpan 或 CalendarInfo 合成日线时，最后一个交易日不会输出，计数为"交易日数 − 1"；按 `Resolution.Daily` 合成则输出全部交易日。这与 L045–L046、L058–L060 第 1 条（两种日线更新时刻不同）一致，又多一个差异：区间末尾的样本数。跨引擎核对 D1 指标时须记录所用方式。
2. **多日 K 线不要用 `TimeSpan.FromDays(N)`**（DataConsolidationAlgorithm 注释）：示例说明跨周末时 N 天时间跨度会出错，应先合成日线，再用 `TradeBarConsolidator(3)` 按数量合并（SequentialConsolidator）。周线/月线可用 `Calendar.Weekly/Monthly`。
3. **自定义指标若未实现 `IIndicatorWarmUpPeriodProvider`，`WarmUpIndicator` 会静默跳过**（CustomWarmUpPeriodIndicator）：不报错，指标仍未就绪。研究中若写自定义指标（例如供需区识别），需实现 WarmUpPeriod 并在启动时断言 IsReady，否则前若干根信号可能基于未就绪状态。
4. **券商断线/重连回调**（LiveFeaturesAlgorithm）：LEAN 提供 `OnBrokerageDisconnect`、`OnBrokerageReconnect`、`OnBrokerageMessage`。V1.2 中 LEAN 只做研究，不用于实盘；MT5 端的断线处理由 RiskExecution 自行实现，此处仅作概念对照。示例中邮箱、电话、FTP 用户名/密码均为占位值。
5. **加密货币现金账户的可用资金需扣除挂单占用**（BasicTemplateCrypto）：示例手工计算未成交买入限价单占用的 USD，再决定新单数量；超额的限价单会因资金不足被拒。这与 V1.2"既有风险全额计入"的原则方向一致（仅概念对照）。
6. **示例代码问题**：`CustomDataNiftyAlgorithm` 中 `niftySma` 实际注册在 rupee 上（`SMA(rupee, 20)`），属示例笔误。
7. **凭据处理**：`CustomDataAutomaticSeedRegressionAlgorithm` 的数据源 URL 同样内嵌一个 api_key 参数，笔记中不转录其值。
8. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读 20 个；下一批从 `cs_unread_sorted.txt` 第 704 行开始。
