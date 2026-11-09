# L092–L094 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L091，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 26 个）
- L092 9 个、L093 9 个、L094 8 个（`py_unread_sorted.txt` 第 349–374 行）。
- 主要内容：期权定价模型适用性基类、粗精选+期权链、ETF 映射成分、400 只股票期权基准、Constituents universe、执行模型订单事件、自定义数据 map file、已完成订单改标签、止损限价单、ObjectStore 缓存、ETF 全球轮动、蝶式价差（看涨/看跌）、回调命令、自定义数据 universe、Collective2 组合信号、CAPM Alpha 排名、改写为框架算法、Sykes 小盘股做空 Alpha、定时自定义数据 universe、铁鹰、定时事件、Numerai/CrunchDAO 信号导出、OCO 订单、连续期货。

## 二、与 V1.2 有关的发现（静态阅读）
1. **OCO 退出单组的行为**（OneCancelsOtherOrderRegressionAlgorithm）：市价入场后，用 `one_cancels_other_order([...])` 同时挂止盈限价单、止损市价单和远端止损限价单；任一张成交后，其余两张收到 "Contingent sibling order" 撤单事件。挂单期间 `get_open_orders_remaining_quantity` 为 −100（而不是三张合计 −300），即 LEAN 把同一 OCO 组按"至多一张会成交"计入剩余数量。对 V1.2：若 LEAN 研究用 OCO 模拟 SL/TP，挂单敞口按一份计算；而 MT5 中持仓自带的 SL/TP 不是独立挂单，两端的"挂单数量/敞口"统计口径不同，跨引擎核对需分开记录。与 R29 一致，作为补充证据。
2. **已关闭订单的标签仍可修改**（CompleteOrderTagUpdateAlgorithm）：已成交或已撤销的订单，可通过 `UpdateOrderFields.tag` 改写标签，订单对象与 ticket 上的标签都会变化。因此 LEAN 的订单标签不能作为不可变的审计证据；研究若用标签记录 candidate_id/run_id，应在下单时另行落盘，不能只依赖结束时读取的标签。
3. **止损限价单的触发记录**（StopLimitOrderRegressionAlgorithm）：成交时订单带有 `stop_triggered` 与 `stop_triggered_time`，成交价不劣于限价。示例的 `trend_is_down` 同样用了 `(1 + tolerance)`（与 L086–L088 第 5 条同类笔误）。
4. **执行模型收到全部订单事件**（ExecutionModelOrderEventsRegressionAlgorithm）：示例按自己保存的 ticket 过滤，与 R30 一致（Python 版本）。
5. **定时检查浮亏并强平**（ScheduledEventsAlgorithm）：每 10 分钟检查 `total_unrealized_profit < −1000` 则全部平仓。这种"轮询式"风控在两次检查之间不生效；V1.2 的亏损上限与保护应以持仓自带 SL 为主，轮询只能作补充。
6. **信号导出到第三方平台的示例**（Numerai、CrunchDAO、Collective2）：各示例的 API key、ID 均为空串或占位值。V1.2 不涉及。
7. **示例代码问题（不影响引擎）**：`CapmAlphaRankingFrameworkAlgorithm` 的回归把基准收益作为因变量、个股收益作为自变量（`lstsq([个股, 1], 基准)`），得到的截距并不是个股相对基准的 alpha；`ConstituentsUniverseRegressionAlgorithm` 使用 `OnSecuritiesChanged` 旧式名；`ObjectStoreExampleAlgorithm` 使用 pandas 已废弃的 `squeeze=True` 参数。
8. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 96 个；下一批从 `py_unread_sorted.txt` 第 375 行开始。
