# L104–L108 第 4 层：Algorithm.Python 示例（收尾）（Claude，2026-11-08）

**方式**：同 L072–L103，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 30 个）
- L104 7 个、L105 7 个、L106 6 个、L107 5 个、L108 5 个，即 `py_unread_sorted.txt` 第 441–470 行，清单已经读完。
- **Algorithm.Python 目录 477 个文件全部 FULL_READ**：.py 470 个，另有 build.bat、build.sh、AssemblyInfo.cs、PythonAlgorithm.cs、.csproj、.pyproj、readme.md 共 7 个（在 L072 读完）。
- 主要内容：
  - 期货期权 ITM 到期（看涨和看跌）、加密货币模板、期货链筛选、运行时统计、Bybit 和 Binance 加密期货、Consolidate 回归。
  - 股票双类别均值回归 Alpha、pandas 历史数据索引、自定义合成器、指数和个股期权链筛选、VIX Dual Thrust、自定义指标预热。
  - 自定义费用、滑点、成交和购买力模型（含 PEP8 版）、ObjectStore 自定义数据（单文件和按日多文件）、CCA 违约概率 Alpha、History 各种调用方式。
  - 指标字段选择器、CAPE 泡沫策略、数据合成入门、Greenblatt 神奇公式、天然气与原油相关性 Alpha、400 只股票空跑基准、指标大全、组合单票据、各类订单票据演示。

## 二、与 V1.2 有关的发现（静态阅读）
1. **订单类型与改单规则**（OrderTicketDemoAlgorithm.py，与 C# 版对应）：
   - 市价单默认同步，在下一行代码执行前就已成交；异步提交后马上撤单，有时能撤掉，有时已经成交，这是竞态。
   - 限价、止损、止损限价和追踪止损单都可以改价格。MOO 和 MOC 单只能改数量和标签。
   - OrderEvent 的 quantity 等于订单当前数量，不是本次成交量；`order_event.ticket` 可以直接取到对应票据。
   - 对 V1.2：LEAN 端对账要用成交事件里的成交数量，不能用 `quantity` 字段。该行为与 R35 系列同属订单语义，列入最终复核请求。
2. **自定义成交模型与部分成交**（CustomModelsAlgorithm 和 PEP8 版）：
   - 示例用固定种子随机数制造部分成交；市价单要用 `asynchronous=True` 提交，否则无法演示部分成交。
   - `SimpleCustomFillModel` 只要 bar 穿过止损价，就按止损价本身成交，不考虑跳空，这比实际更乐观。
   - 购买力模型可以被替换成"永远够用"，这会让保证金不足的拒单不再发生。
   - 对 V1.2：LEAN 研究如果使用自定义成交或购买力模型，必须在报告中登记，否则结果不能与 MT5 对照。部分成交与对账测试可以参考这种固定种子的写法。
3. **维持保证金口径**（Bybit / BasicTemplateCryptoFuture）：`total_margin_used` 等于持仓的维持保证金。超出保证金的下单会同步返回 Invalid，与之前记录的结论一致。加密期货不在 V1.2 范围内，仅作口径参考。
4. **多日 bar 的写法**（DataConsolidationAlgorithm 和 ConsolidateRegression）：
   - `timedelta(1)` 合成的日线比 `Resolution.DAILY` 少一根，这一点已在前面记录。
   - 示例注释明确说明，大于一天的周期直接用时间跨度会被周末打乱，应改用"日线合成器 + 计数合成器"（SequentialConsolidator）。这与之前"不要用 `FromDays(N)` 做多日 bar"的发现一致。
5. **History 计数口径**（HistoryAlgorithm.py）：取一天分钟数据时，开启扩展时段并前向填充得 960 根，只开扩展时段得 919 根，常规时段得 390 根。研究中的样本数取决于这两个参数，报告应写明。
6. **Python 子类合成器的私有状态**（CustomConsolidatorRegression）：Python 继承 C# 合成器时，私有字段与基类分开，必须自己重写 scan 并触发事件。V1.2 研究端用 C#，仅记录。
7. **凭据与外部来源**：CAPE 示例从 Dropbox 链接取数据，链接里没有凭据。ObjectStore 示例把数据写入后再读取，与之前记录的"ObjectStore 前视风险"属于同一类，需要登记数据写入的时间点。
8. **示例代码问题（不影响引擎）**：
   - `StatisticsResultsAlgorithm.py`：两个 IBM 的 EMA 都注册在 SPY 上。
   - `IndicatorSelectorsWorkWithDifferentOptions.py`：ask 字段的报错信息里打印的是 bid 的值；代码同时使用了 `future_chains` 和 `futures_chains` 两种拼写。
   - `ContingentClaimsAnalysisDefaultPredictionAlpha.py`：
     - 注释说取成交额最小的 750 只，代码却按降序排列，取到的是最大的。
     - 精选阶段用 `is_valid` 排序，而不是过滤。
     - `Series.nonzero()` 在新版 pandas 中已删除。
     - tau 用 360 天，却与年化 ROA 混用。
   - `GreenblattMagicFormulaAlpha.py`：EV/EBITDA 降序排列、ROA 升序排列，两者都与神奇公式的方向相反；Alpha 模型实际用的是 ROC。
   - `BubbleAlgorithm.py`：`index.value` 被赋值为字符串；裸 `except` 会吞掉所有错误。
   - `DataConsolidationAlgorithm.py`：三日 bar 的图表标签写成 "3HourBar"；小时 bar 的日志写成 FortyFiveMinute。
   - `IndicatorWarmupAlgorithm.py`、`LiveFeaturesAlgorithm.py` 的问题见 L101–L103 笔记。
9. 其余为第 4 层内容，只记录已读。

## 三、进度（里程碑）
- 盘点表全库：FULL_READ 1,503，DATA_AUDITED 643，HASH_REUSE 5，PARTIAL 5，UNREAD 4,366。
- Algorithm.CSharp 与 Algorithm.Python 都已读完，UNREAD 均为 0。
- UNREAD 最多的目录：Common 1,972、Tests 859、Data 652、Indicators 233、Engine 208、Algorithm.Framework 86、Algorithm 59、ToolBox 57、Report 54、Brokerages 33，其余是零散的小目录和根目录文件。
- 下一步：Algorithm.Framework（86 个）→ Algorithm 剩余的 59 个 → Indicators、Engine 剩余部分 → Tests → Common 剩余部分 → 其他小目录。
