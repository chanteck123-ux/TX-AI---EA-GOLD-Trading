# L043–L044 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L042，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 29 个）
- L043：15 个，L044：14 个；清单以 coverage 表中 batch 列为准。
- 主要是期权组合（大数量组合单、跨式、备兑认沽等）、期货连续合约与换月、数据归一化/映射模式的历史请求、粗选立即生效、容量测试、tick 过滤、指数模板。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **手动换月是"先平后开"两张单**（ManualContinuousFuturesPositionRollover）：在 SymbolChangedEvent 中先 `Liquidate` 旧合约、再按原数量对新合约下单，不是原子操作。XAUUSD CFD 不换月；但 V1.2 RiskExecution 如有"先平后开"的反手或换品种操作，需要处理两单之间的中间状态（一张成交、另一张失败）。
2. **tick 数据过滤**（TickDataFilteringAlgorithm）：通过 `ISecurityDataFilter` 只接受 ARCA 交易所的 tick。V1.2 在 LEAN 中处理 XAUUSD 报价 tick 时，可以用同样机制剔除异常报价，但过滤规则要与 MT5 端一致并登记。
3. **历史请求可按不同的归一化/映射模式取数**（HistoryWithDifferentDataNormalizationMode / MappingMode），不同模式下同一时刻的收盘价都不同；股票支持 Raw、Adjusted、SplitAdjusted，期货支持 Raw、BackwardsRatio、BackwardsPanamaCanal、ForwardPanamaCanal。CFD 无此问题。
4. `EtfGlobalRotationAlgorithm` 的 OnData 只捕获 `RegressionTestException`，其他异常不会被捕获（看起来是批量替换 Exception 名称时带来的），属于示例代码问题，与 V1.2 无关。
5. 容量测试 `IntradayMinuteScalpingFuturesES`、`CheeseMilkHourlyRebalance` 为期货高频与流动性测试，不涉及 XAUUSD。
6. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 243 个。
