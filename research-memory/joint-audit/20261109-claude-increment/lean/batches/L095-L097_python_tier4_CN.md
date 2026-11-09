# L095–L097 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L094，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 24 个）
- L095 8 个、L096 8 个、L097 8 个（`py_unread_sorted.txt` 第 375–398 行）。
- 主要内容：ETF 成分过滤、自定义数据 universe、期货/期货期权到期与清算、PyTorch 神经网络、指数/期货期权 OTM 到期（多份同构）、**条件单更新**、跟踪止损单、全球股票 IBS 均值回归、可做空数量拒单、期货期权单链选择、**括号单（OTOCO）**、订单时效（GTC/DAY/GTD）、日内外汇反转 Alpha、ETF 成分 RSI、杠杆 ETF 再平衡、Keras 模型存 ObjectStore、手动移除合成器、比特币自定义数据、手动设置交易时段与品种属性（Python 版）、定时 universe、期货的 Security.Session。

## 二、与 V1.2 有关的发现（静态阅读）
1. **原生括号单（OTOCO）**（BracketOrderRegressionAlgorithm）：`bracket_order(symbol, 100, take_profit_price, stop_loss_price)` 返回三张 ticket——市价入场单、止盈限价单、止损市价单。入场成交后两张子单在同一时刻被触发并开始工作（contingency 为 ONE_TRIGGERS_OTHER 子单 + ONE_CANCELS_OTHER 成员）；一张成交后，另一张在**同一时间戳**被撤销。这是 LEAN 里最接近"入场即带 SL/TP"的写法。
2. **子单被触发后，要等下一笔新数据才能成交**（ContingentOrderUpdateRegressionAlgorithm）：示例注释和断言写明，入场单成交后触发的子单"与其他订单一样，需要新数据才能成交，不会用开始工作那一刻的数据成交"；示例中可立即成交的止盈单，实际在入场后 1 分钟（下一根分钟 K 线）才成交。另外，等待触发中的子单可以修改（改价、改量、改标签），已撤销的订单不能再修改。
   - 对 V1.2：在 LEAN 中，入场 K 线内即使价格已穿过止损价，保护单也不会在同一根 K 线成交；MT5 中持仓自带的 SL 从开仓即生效，同一根 K 线内即可触发。用 M5 研究时，这会使 LEAN 低估"入场当根即止损"的情形，跨引擎核对需单独统计。**新增待汇总 R35。**
3. **跟踪止损价在 OnData 之后才更新**（TrailingStopOrderRegressionAlgorithm 注释）：止损价按当前切片数据更新的动作发生在 `on_data` 之后，所以示例用上一根 K 线的高/低检查止损距离。读取跟踪止损的"当前止损价"时，需注意它反映的是上一根数据。
4. **订单时效**（TimeInForceAlgorithm）：支持 GTC（默认）、DAY（收盘撤单）、GTD（指定日期收盘撤单）。MT5 的挂单时效（GTC、当日、指定时间）语义不同，研究中若使用，需对应登记。
5. **超出可做空数量的拒单与改单**（ShortableProviderOrdersRejectedRegression）：超出上限的新单在提交时即为 ERROR，改单超限返回 `EXCEEDS_SHORTABLE_QUANTITY`，减少数量的改单允许。CFD 不适用，仅说明 LEAN 的提交前检查会同时考虑现有持仓与挂单。
6. **ML 模型存入 ObjectStore**（KerasNeuralNetworkAlgorithm）：模型在回测结束时保存，下次回测开始时读取。与 L056–L057 第 1 条相同的风险：读取的模型可能是用不同区间（甚至未来数据）训练的，研究中若采用，须在键名中包含训练区间与版本并登记。
7. **凭据处理**：`CustomDataBitcoinAlgorithm.py` 的数据源 URL 同样内嵌 api_key 参数，笔记中不转录其值。
8. **示例代码问题（不影响引擎）**：`GlobalEquityMeanReversionIBSAlpha` 的代码列表中 "EWM" 出现三次；`RebalancingLeveragedETFAlpha.py` 中 `self.date = datetime.min.date` 赋值的是方法对象而非日期（首次比较恒不相等，不影响结果）。
9. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 72 个；下一批从 `py_unread_sorted.txt` 第 399 行开始。
- 新增待汇总：R35（括号单/条件子单需下一笔数据才能成交）。
