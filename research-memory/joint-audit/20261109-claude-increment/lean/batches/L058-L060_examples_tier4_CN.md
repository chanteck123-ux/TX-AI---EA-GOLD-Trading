# L058–L060 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L057，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 27 个）
- L058、L059、L060 各 9 个；清单以 coverage 表中 batch 列为准。
- 主要内容：期货每日现金结算、日线 vs 1 天 TimeSpan 指标、链式基本面 universe 时间、杠杆 ETF 再平衡 Alpha、ObjectStore 降序自定义数据、期货期权/指数期权到期（ITM/OTM，多份同构文件）、自定义 universe 与基准、Consolidate 按数量/Renko/Range 重载、期权镜像合约指标、自定义数据 map file、RegisterIndicator 数据类型、连续期货换月、粗精选+期权链、连续期货立即选取、universe 退市/改名边界、Dropbox universe、成交量拆股调整、Collective2 信号导出、证券重新加入时的初始化、多品种合成器结构。

## 二、与 V1.2 有关的发现（静态阅读）
1. **日线指标两种更新时刻再次确认**（DailyResolutionVsTimeSpan）：`Resolution.Daily` 注册的指标在 16:00 收盘更新，`TimeSpan.FromDays(1)` 注册的在午夜更新；两者值相同，只是时刻不同。与 L045–L046 记录一致。XAUUSD 若做日线信号，要在研究配置中固定其中一种，并与 MT5 的 D1 收盘时刻（服务器时区 00:00）对齐登记。
2. **链式基本面数据避免前视**（ChainedFundamentalUniverseSelectionTime，issue 9793）：基本面数据的 Time 是前一交易日、EndTime 是当前选取时刻；周一取到的是周五数据的前向填充。这是 LEAN 修复过的前视问题，说明数据时间戳口径需逐项核对。
3. **期货换月是两笔独立订单**（BasicTemplateFutureRollover）：收到 SymbolChangedEvent 后先 Liquidate 旧合约，再 MarketOrder 新合约，并重置、重新预热 EMA。两笔之间无原子保证。CFD 无换月，但 LEAN 中若用连续合约做研究，换月成交需单独计入成本。
4. **多品种合成器写法**（MultipleSymbolConsolidation）：外汇使用 QuoteBarConsolidator，股票使用 TradeBarConsolidator；用 `Bars[0].Time == 当前时间 − 周期` 判断"刚刚收完一根"。这是在 OnData 中判断 M5 收柱的一种可用写法，与 S7 反转闭柱确认的研究实现有关（仅记录写法，不代表已实现）。
5. **移除后重新加入的证券是同一个对象**（SecurityInitializationOnReAddition）：移除后不可交易，重新加入后恢复可交易，且初始化器每次加入只执行一次。
6. `DropboxUniverseSelection` 中示例 `UserName:Password` 是占位的 Basic 认证头，未含真实凭据；`Collective2SignalExportDemonstration` 的 API key 也是占位字符串。
7. 期货每日结算示例（FuturesDailySettlementLong）显示期货持仓的盈亏每日计入现金（SettledProfit），CFD 不适用。
8. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读 61 个；下一批从 `cs_unread_sorted.txt` 第 663 行开始。
