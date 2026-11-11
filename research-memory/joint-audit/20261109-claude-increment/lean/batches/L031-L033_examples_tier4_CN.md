# L031–L033 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L030，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 62 个）
- L031：22 个，L032：20 个，L033：20 个；清单以 coverage 表中 batch 列为准。
- 主要是期权组合筛选（Butterfly、Ladder、BoxSpread 等）、期货/期权链完整数据、历史数据请求、universe 选择、容量测试（CapacityTests）、执行模型（StandardDeviation、VWAP）、信号导出、基础模板。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **刚添加、还没有数据的品种，下单为 Invalid**（AddRemoveSecurityCache）：示例断言 `MarketOrder("AIG", 1)` 在 AIG 刚加入、尚无价格时状态为 Invalid。对 V1.2：LEAN 中如果在品种刚订阅后立即下单，会静默无单，需检查订单状态。
2. `ScheduledEventsAlgorithm` 演示每 10 分钟检查一次 `Portfolio.TotalUnrealizedProfit < -1000` 就全部平仓。这类"定时检查"在 LEAN 中依赖时间步，不是逐笔触发，可作为 V1.2 账户级风控对照时的提醒。
3. **容量测试中有 EURUSD 分钟级剥头皮**（IntradayMinuteScalpingEURUSD，Oanda 市场，EMA 20/40 交叉，SetHoldings ±1）。这是 LEAN 容量估计的回归示例，不是 V1.2 用户 Scalping SOP，也不涉及 XAUUSD。
4. 执行模型示例：`StandardDeviationExecutionModel` 只在价格偏离 60 分钟均值 2 个标准差时才分批下单；`VolumeWeightedAveragePriceExecutionModel` 只在价格处于日内 VWAP 有利一侧时下单。V1.2 不使用框架，只作参考。
5. `VBaseSignalExportDemonstrationAlgorithm` 中 API key 和集合名都是占位字符串 `YOUR API KEY`、`YOUR COLLECTION`，不是真实凭证。
6. `FutureSharingTickerRegression` 示例中，`Futures.Metals.Gold` 同时以 COMEX 和 NYMEX 两个市场添加，注释说明 NYMEX 的那个"并不存在，仅作示例"。
7. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 433 个。
