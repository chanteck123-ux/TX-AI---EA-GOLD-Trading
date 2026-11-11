# L089–L091 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L088，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 29 个）
- L089 10 个、L090 10 个、L091 9 个（`py_unread_sorted.txt` 第 320–348 行）。
- 主要内容：小时线合成日线、Insight 标签、SMA 交叉 universe 预热、期权历史、Tick 类型合成、Dropbox BaseData universe、连续期货模板（含扩展时段）、期货扩展时段、黄金期货 EMA 交叉、LIT 订单、自定义再平衡函数、标志性自定义数据、自定义图表、ETF 成分退市、组合目标标签、Stochastic 预热、期货映射模式回退、EMA 交叉 universe、基本面定时选择、期权框架模板、期权链策略过滤、宽跨式、印度数据、三角套利 Alpha、证券自定义属性与费用模型、位移均线带、期货期权逐个添加。

## 二、与 V1.2 有关的发现（静态阅读）
1. **C# decimal 与 Python double 在均线交叉处结果可能不同**（BasicTemplateContinuousFutureAlgorithm 及其扩展时段版本）：示例注释写明，C# 与 Python 版本在交叉点会因 decimal 与 double 舍入不同而做出不同交易，因此加入 0.001 的交叉阈值作为变通。V1.2 的跨引擎核对正是 LEAN C#（decimal）对 MQL5（double）：在信号恰好处于阈值边界时，两端可能给出相反结论。跨引擎核对应把"边界上的信号差异"单独归类，而不是直接判为实现错误，并考虑在信号规则中登记最小差值容差。**新增待汇总 R34。**
2. **小时线合成的日线与数据库日线一致**（ConsolidateHourBarsIntoDailyBarsRegression）：示例断言用 `Resolution.DAILY` 从小时线合成的日线，与历史请求返回的日线完全一致（美股，最后一根小时线在 16:00）。这只针对美股常规时段；XAUUSD 的日线边界（服务器时间 00:00）须另行核对，见 L058–L060 第 1 条。
3. **用 TimeSpan 预热与用历史预热结果一致**（StochasticIndicatorWarmsUpProperlyRegression）：以 1 天合成器注册的 RSI 与 Stochastic，用 `warm_up_indicator(..., timedelta(days=1))` 预热后，与手工用日线历史逐根更新的结果相同。示例中第二组 Stochastic 跳过了第一根，与 RSI 的样本对齐方式有关；研究中若手工预热多个指标，需逐个核对首根样本的处理。
4. **期货映射模式不可用时回退并发警告**（FutureDataMappingModeFallbackRegression）：EUREX 期货不提供持仓量映射时，自动改用 LastTradingDay 并发送一次警告；重复添加且设置不同时，新设置被忽略并警告。这说明 LEAN 会静默（仅警告）替换配置，研究报告应检查日志中的此类警告并登记实际生效的配置。
5. **自定义费用模型可读取证券上的动态属性**（SecurityCustomPropertiesAlgorithm）：费用按 `max(1, 价格 × 数量 × 费率)` 计算，费率存放在证券对象的自定义属性中。若 LEAN 研究要模拟 FxPro 的佣金/点差成本，可用类似方式，但成本口径须与 MT5 报告一致，避免重复扣费（计划 §11 要求）。
6. **示例代码问题（不影响引擎）**：`DisplacedMovingAverageRibbon` 的 `is_ascending` 在 `last < val` 时返回 False，实际检验的是"从快到慢递减"，与函数名相反；且用 `if not last` 判断首个值，若值为 0 会被跳过。`IndiaDataRegressionAlgorithm` 用整数 1 比较证券类型。
7. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 122 个；下一批从 `py_unread_sorted.txt` 第 349 行开始。
- 新增待汇总：R34（decimal 与 double 在信号边界处的差异）。
