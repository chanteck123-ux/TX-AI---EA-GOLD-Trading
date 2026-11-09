# L055 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L054，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 11 个）
- 清单以 coverage 表中 batch=L055 为准：期权改名、午间均值回归 Alpha、期权框架模板、期货模板、连续合约深度偏移历史、Collective2 组合信号导出、期货 SetHoldings、印度数据映射、期货期权逐个添加数据流、移动均线带、ETF 成分退市。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **期货的 SetHoldings 目标超出 ±1 会抛异常**（SetHoldingsFutureRegression，GH 4027）：`SetHoldings(合约, 1.1)` 或 `-1.1` 抛 InvalidOperationException；在 ±1 之内按期货保证金杠杆计算最大可开手数。示例断言实际持仓价值 / 组合价值 ≥ 10，且没有余量再加一手。CFD 不适用这条规则，仅作参考。
2. `ETFConstituentUniverseCompositeDelisting` 中有一条 TODO：由另一个 universe 加入的 AAPL 不应被当作"已移除"发出，说明 universe 移除事件在多 universe 共用证券时存在已知的不精确之处。
3. `MeanReversionLunchBreakAlpha` 用 `!cf.HasFundamentalData` 来筛选 ETF（没有基本面数据的就当作 ETF），属于示例里的近似写法。
4. `Collective2PortfolioSignalExportDemonstrationAlgorithm` 的 API key 为占位字符串 `YOUR APIV4 KEY`，系统 ID 为 0。
5. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读 108 个。
