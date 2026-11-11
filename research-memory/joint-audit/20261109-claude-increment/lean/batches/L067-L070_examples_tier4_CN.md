# L067–L070 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L066，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 18 个）
- L067 5 个、L068 5 个、L069 4 个、L070 4 个；清单以 coverage 表中 batch 列为准。
- 主要内容：CAPE 泡沫策略、币安加密期货（分钟）、可做空数量粗选、VIX 双推力 Alpha、期权链过滤器、ObjectStore 自定义数据（单文件/多文件）、比特币自定义数据回归、自定义数据属性与交易时段、Greenblatt 魔法公式 Alpha、指标套件、期权 universe 增删、连续期货换月基类、自定义费用/成交/滑点/购买力模型、期权指派统计、容量测试（100 只股票 EMA）、天然气–原油相关 Alpha、History 各种调用。

## 二、与 V1.2 有关的发现（静态阅读）
1. **两种"胜率"口径并存**（OptionAssignmentStatistics）：同一回测中，`TradeBuilder.ClosedTrades` 的交易统计得到 WinRate 0.75（4 笔交易中 3 笔盈利），而 `Statistics.TotalPerformance.PortfolioStatistics` 基于成交事务（Transactions.WinCount/LossCount）得到 WinRate 2/3。两者分别按"开平配对的交易"和"产生实现盈亏的成交"计数。对 V1.2 §11 的影响：引用 LEAN 胜率、PF、平均盈亏时，必须注明取自 TradeStatistics 还是 PortfolioStatistics，并与 MT5 报告的计数方式（按成交/按持仓）分别核对，不能混用。**新增待汇总 R33。**
2. **自定义成交模型可模拟部分成交，且需 asynchronous 下单**（CustomModelsAlgorithm）：示例的 CustomFillModel 以固定种子随机返回 PartiallyFilled，并注明市价单部分成交需 `asynchronous: true`。这为 LEAN 端模拟"部分成交 → RiskExecution 对账"提供了途径（仅研究用途；V1.2 的部分成交处理仍以 MT5 真实回报为准）。示例中的 SimpleCustomFillModel 止损单按止损价成交，不计跳空滑点；自定义购买力模型总是返回"资金充足"，均不可直接用于研究配置。
3. **自定义数据可附带品种属性与交易时段**（CustomDataProperties）：`AddData<T>(ticker, SymbolProperties, SecurityExchangeHours)` 可为自定义数据（例如从 FxPro 导出的 XAUUSD 数据）设置合约乘数、最小价位、最小手数和交易时段。示例在结束时用 `SymbolPropertiesDatabase.SetEntry` 把条目复原，说明该数据库修改是进程内全局的；研究中如修改，应在同一配置中登记并复原。
4. **连续期货换月测试修改了 MarketHoursDatabase 条目并在异常时复原**（ContinuousFutureRolloverBase）：同样说明 MHDB 为全局状态。
5. **参数取自"随机回测中表现可接受"的结果**（VIXDualThrustAlpha 注释）：示例参数来自同一区间的多次回测，属典型的样本内选择。仅作为"参数来源须登记、须独立样本验证"这一规则的反例记录。该示例还使用 `ConstantFeeModel(0)`（零费用），GreenblattMagicFormula 与 GasAndCrudeOil 示例同样设为零费用。
6. **History 中日线数据的时间戳**（HistoryAlgorithm）：SPY 日线在 16:00 到达、自定义数据在午夜到达，因此混合请求时计数为 2 倍。与第 1 条日线时刻问题一致。
7. **容量测试示例**（EmaPortfolioRebalance100）：列表中 "ACT" 被添加两次，属示例数据重复，不影响引擎。
8. **凭据处理**：`CustomDataRegressionAlgorithm` 的数据源 URL 内嵌 api_key 参数，笔记中不转录其值。
9. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读 5 个；下一批从 `cs_unread_sorted.txt` 第 722 行开始。
- 新增待汇总：R33（TradeStatistics 与 PortfolioStatistics 两种胜率口径）。
