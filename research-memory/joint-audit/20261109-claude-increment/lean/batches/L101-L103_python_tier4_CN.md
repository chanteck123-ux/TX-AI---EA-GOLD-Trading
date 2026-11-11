# L101–L103 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L100，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ）
- L101、L102 7 个、L103 6 个（`py_unread_sorted.txt` 至第 440 行）。L101 批次数量以盘点表 batch 列为准。
- 主要内容：OneTriggersOther、ContingentComboOrder、指数期权 Greeks、ComboOrdersFillModel、价格缺口均值回归、Python 字典特性、EUREX、期货期权链筛选、Fundamental、加密期货小时线、**限价入场括号单**、多品种合成、指标预热、可做空数量粗选、改单回归、实盘通知功能。

## 二、与 V1.2 有关的发现（静态阅读）
1. **OTO 市价子单与父单同时成交**（OneTriggersOther）：这就是 R35 修正的依据。延迟只出现在限价单或止损单子单，止损市价单的行为仍需核对源码。
2. **限价入场的括号单**（BracketOrderLimitEntryRegressionAlgorithm.py）：
   - 入场单成交前，止盈和止损子单为 SUBMITTED，并处于"等待触发"状态。
   - 等待触发的子单不计入 `get_open_orders_remaining_quantity`，示例断言该值为 100，即只算入场单。
   - 子单的触发时间等于入场成交时间，而子单本身的成交时间严格晚于触发时间（`utc_time <= triggered_time` 会被判为错误）。这与 R35 一致：触发后的限价或止损子单要等新数据才能成交。
   - 同一个下单请求只能提交一次，第二次提交抛出 ArgumentException。
   - 对 V1.2 的含义：在 LEAN 里估算挂单风险暴露时，如果只看 open remaining quantity，会漏掉尚未触发的保护单。RiskExecution 的暴露计算不能依赖这个数字。本条并入 R35 证据。
3. **止损单在成交回调里才补挂**（IndicatorWarmupAlgorithm.py）：入场成交后才在 on_order_event 中下止损市价单，中间有一段无保护的空窗。这与 MT5 下单时带 SL 的做法不同，两边对照时要注意，V1.2 不应采用这种做法。
4. **改单字段与时间戳**（UpdateOrderRegressionAlgorithm.py）：
   - 改单可以改数量、限价、止损价和标签，追踪止损单不改 stop_price。
   - 撤单后 `canceled_time` 等于撤单事件时间；成交和部分成交时，`last_fill_time` 等于成交事件时间。
   - 改单成功后 `last_update_time` 不为空。
   - 这些字段可作为 LEAN 端对账的时间来源。
5. **可做空数量**（AllShortableSymbols…）：ShortableProvider 按日期文件提供可做空数量，找不到当天文件时最多往前回溯 7 天。CFD 不涉及，仅记录。
6. **ComboOrdersFillModel**：组合单允许部分成交（L102）。V1.2 不使用组合单，仅记录。
7. **凭据处理**：`LiveFeaturesAlgorithm.py` 里的 ftp、sftp、email 和 sms 参数都是示例占位值（如 "username"、"password"、示例邮箱和号码），不是真实凭据。该示例会向外部地址发通知，V1.2 不使用。
8. **示例代码问题（不影响引擎）**：
   - `IndexOptionCallITMGreeks…`：`vega == 0` 拿整个列表与 0 比较，这个判断永远不会成立（L101）。
   - `PriceGapMeanReversion…`：用百分比跳空与价格水平的标准差比较，两者单位不一致（L102）。
   - `PythonDictionaryFeature…`：调用 `securities.clear()` 不会抛出异常（L102）。
   - `LiveFeaturesAlgorithm.py`：`live_btc["last"]` 是字符串，与 0 比较永远不相等；示例还读取了不存在的 "open" 字段。
   - `IndicatorWarmupAlgorithm.py`：`round_down` 返回的是布尔值而不是取整后的时间，这与函数名不符；`is_ready` 在 `__init__` 中只计算一次。
9. 其余为第 4 层内容，只记录已读。

## 三、进度
- 标记 L103 后，全库 UNREAD 为 4,396。
- Algorithm.Python 下一批从 `py_unread_sorted.txt` 第 441 行开始，到第 470 行结束，还剩约 30 个文件。
