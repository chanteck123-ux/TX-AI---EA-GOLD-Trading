# L061–L063 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L060，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 23 个）
- L061 8 个、L062 8 个、L063 7 个；清单以 coverage 表中 batch 列为准。
- 主要内容：Security.Session、连续期货、期货/指数期权 ITM/OTM 到期与指派（多份同构）、比特币自定义数据、定时 universe 模型、EUREX 期货（EUR 账户货币）、期货期权链过滤器、重复期权指派、多资产模板、从 universe 添加期权合约、辅助数据历史、400 只股票空载基准、币安期货（小时）、ETF 成分过滤、期权链 universe 移除、指标字段选择器、期货链过滤器、运行时统计访问。

## 二、与 V1.2 有关的发现（静态阅读）
1. **Security.Session 提供当日会话 OHLCV**（SecuritySessionRegression）：设置 `security.Session.Size = N` 后，可读当前会话及前 N−1 个会话的 Open/High/Low/Close/Volume，`session[1]` 为上一会话。默认只统计常规交易时段；`DailyPreciseEndTime` 与 `ExtendedMarketHours` 影响边界。研究中若需要"前一日高低点"类供需区参考，可用此功能，但 XAUUSD 的会话边界须先按 FxPro 交易时段设定（见 L052–L054 第 1 条）。
2. **退市或指派时挂单会被自动撤销**（DuplicateOptionAssignment）：未成交的限价单在合约退市时依次收到 CancelPending、Canceled 事件，指派照常处理。对 V1.2 的启示：对账逻辑必须能处理"非本系统主动发起"的撤单与成交事件（RiskExecution 的外部事件归类），不能假设所有订单状态变化都来自自己的请求。
3. **保证金不足的订单立即返回 Invalid**（BasicTemplateCryptoFutureHourly）：下单数量超出保证金时，`Buy` 返回的 ticket 状态即为 Invalid，未进入经纪商。LEAN 中这一判定同步完成；MT5 中 OrderCheck/OrderSend 返回码另行核对，二者不能直接等同。
4. **辅助数据可单独查历史**（HistoryAuxiliaryData）：分红、拆股、退市、改名、连续期货换月事件以及加密期货保证金利率都可用 `History<T>` 查询。连续期货按 OpenInterest 与 LastTradingDay 两种映射方式的换月时间不同。
5. **账户货币可设为非 USD**（BasicTemplateEurexFutures 用 `SetAccountCurrency(EUR)`）。V1.2 为 USD 账户，仅记录。
6. **示例代码问题**：`StatisticsResultsAlgorithm` 中 IBM 的两条 EMA 实际注册在 SPY 上（`EMA(_spy, 10)`、`EMA(_spy, 30)`），属示例笔误，不影响引擎。
7. **凭据处理**：`CustomDataBitcoinAlgorithm` 的数据源 URL 内嵌一个 api_key 参数。按本次审查规则，笔记中不转录其值；该文件状态仍为 FULL_READ。
8. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读 38 个；下一批从 `cs_unread_sorted.txt` 第 686 行开始。
