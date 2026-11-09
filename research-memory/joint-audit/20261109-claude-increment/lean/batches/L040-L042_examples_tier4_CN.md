# L040–L042 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L039，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 47 个）
- L040：16 个，L041：16 个，L042：15 个；清单以 coverage 表中 batch 列为准。
- 主要是股票期权组合保证金（OptionEquity* 系列）、框架组合再平衡规则、universe 选择、结算模型、执行模型（Spread）、合成 K 线（MarketHourAware）、辅助数据事件、自定义数据。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **按交易时段对齐的合成 K 线**（MarketHourAwareIntradayConsolidation）：`MarketHourAwareConsolidator` 以**开盘时刻**为起点切分 K 线（示例为 7 分钟），收盘时最后一根会被截短，不跨收盘。普通 `TradeBarConsolidator(TimeSpan)` 则按时钟取整对齐（见 L036 的 ConsolidatorStartTime 示例可用 `startTime` 指定起点）。
   - 对 V1.2：用户 Scalping 规定 M5，MT5 的 M5 按服务器时钟对齐。LEAN 中合成 M5/H4 时要选择与 MT5 一致的对齐方式，并核对周一开盘、每日休市前后的那几根 K 线；否则信号会错位。
2. **粗选数据不会有前视偏差**（CoarseNoLookAheadBias）：粗选数据按**前一交易日**发出，盘中 10:00 时的粗选价格等于前一收盘价。说明 LEAN 在这一点上有防前视的设计；V1.2 自己的日线派生特征也要同样处理。
3. **组合再平衡规则**（PortfolioRebalanceOnInsightChanges / OnDateRules）：可以关闭"信号变化即再平衡"与"品种变化即再平衡"，只按日期规则（例如每周三）或固定间隔（30 天）调仓。V1.2 不用框架，仅作参考。
4. **自定义结算模型**（SetCustomSettlementModel）与**手动移除合约后仍按延迟结算**（DelayedSettlementAfterManualSecurityRemoval）：现金在结算日才可用。CFD 为即时结算，影响小。
5. `FractionalQuantityRegression`：低于最小下单量的单会失败（示例注释 "should fail"）；该示例为使用杠杆，把加密货币的现金型购买力模型替换为 3.3 倍杠杆的保证金模型。
6. `SpreadExecutionModel` 只在买卖价差足够窄时下单，可作为 V1.2 "点差过宽不入场"的参考写法（V1.2 不用框架）。
7. `BasicTemplateIntrinioEconomicData` 的用户名和密码为空字符串；`CustomDataBenchmark` 等示例的数据源是公开的 Dropbox 链接，不是凭证。
8. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 272 个。
