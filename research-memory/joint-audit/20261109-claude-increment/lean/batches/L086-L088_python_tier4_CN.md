# L086–L088 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L085，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 34 个）
- L086 12 个、L087 11 个、L088 11 个（`py_unread_sorted.txt` 第 286–319 行）。
- 主要内容：期货动量、保证金追缴事件、scikit-learn 线性回归、期货期权模板、Bybit 现货、期货期权日内买卖、期权策略基类、期货 universe 过滤、粗精选组合、条件触发的跟踪止损、流动 ETF universe、期权改名、日历价差/跨式（多份）、自定义券商模型、指标型波动率模型、期权链提供者、Expiry 帮助类、Insight 评分、扩展时段期货止损单、期货模板、期货扩展时段数据、ETF 成分退市、Dropbox universe、自定义证券初始化器、期货框架、期权希腊值过滤、券商模型（最低余额）、指标扩展、指数期权日内买卖、期货历史。

## 二、与 V1.2 有关的发现（静态阅读）
1. **追加保证金事件及可修改的强平单**（MarginCallEventsAlgorithm）：剩余保证金低于组合价值 5% 时触发 `on_margin_call_warning`；`on_margin_call(requests)` 在强平单下达前调用，可以修改或替换这些订单。LEAN 的保证金追缴/强平逻辑与 FxPro 的 Margin Call / Stop Out 水平不同，V1.2 研究若评估爆仓风险，必须按 FxPro 实际规则另行核对（计划要求"Stop Out 另核对"），不能直接采用 LEAN 的事件时点。示例在遍历 `requests` 时修改同一列表，属示例写法问题。
2. **券商模型可在下单前拒单或拒绝改单**（CustomBrokerageModelRegression、BrokerageModelAlgorithm）：覆盖 `can_submit_order` / `can_update_order` 可返回 False 和原因消息；示例分别模拟"某品种禁止下单""订单不可修改""账户须保留最低现金"。LEAN 研究若想模拟 MT5 的 stops level、freeze level 或最小止损距离等拒单情形，可用这种方式，但取值须来自 FxPro 的实际品种规格。
3. **条件触发的跟踪止损**（ContingentTrailingStopOrderRegression）：通过 `order_factory` 建立"限价入场成交后触发跟踪止损"的组合（OTO）。跟踪止损在被触发前止损价为 0，触发后才按当时市价设定并开始跟踪。与 R29（OTO/OCO 原生条件单）一致；这种"入场后才生成保护"的方式与 V1.2 要求入场意图携带初始 SL 不同，研究中若用它，需登记入场与保护之间的时间差。
4. **扩展时段与止损单**（FutureStopMarketOrderOnExtendedHoursRegression、FutureContractsExtendedMarketHoursRegression）：只有订阅时打开 `extended_market_hours`，扩展时段才会有数据，止损单才会在扩展时段成交；黄金期货在未开启时，扩展时段完全没有数据。XAUUSD CFD 的交易时段以 MarketHoursDatabase 中的 CFD 条目为准，研究配置须确认是否需要该开关，否则夜盘的触发与成交会被遗漏。
5. **示例代码问题（不影响引擎）**：
   - `FuturesMomentumAlgorithm`：下跌判断 `fast < slow × tolerance` 与上涨判断使用同一个乘数（应为除以容差），且注释说选"最近月"，代码却按到期日倒序取最远月。
   - `DropboxUniverseSelectionAlgorithm` 未在 `initialize` 中初始化 `self._changes`。
   - `CustomSecurityInitializerAlgorithm` 的子类没有调用父类构造函数，而是另存一个 base 实例。
   - Dropbox 示例中的 `UserName:Password` 为占位的认证头。
6. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 151 个；下一批从 `py_unread_sorted.txt` 第 320 行开始。
