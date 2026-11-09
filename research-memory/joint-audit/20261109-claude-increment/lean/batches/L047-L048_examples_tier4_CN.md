# L047–L048 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L046，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 26 个）
- L047、L048 各 13 个；清单以 coverage 表中 batch 列为准。
- 主要是期权组合与指派、期货合约与连续合约、日线精确结束时间、合成器 tick 类型、universe 选择与订阅移除、预热与定时事件、TotalPortfolioValue、原始价格数据、Samco/印度市场模板。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **日线 K 线的两种定义**（DailyStrictEndTimeConsolidators）：
   - `DailyPreciseEndTime = true` 时，按 `Resolution.Daily` 合成的日线结束于 16:00，周期 6.5 小时（只含正常交易时段）；
   - 按 `TimeSpan.FromDays(1)` 从分钟数据合成的日线则结束于午夜，周期 24 小时。
   - 对 V1.2：XAUUSD 的"日"在 MT5 中按服务器时间 00:00 切分。在 LEAN 中两种写法得到的日线不同，必须选与 MT5 一致的一种，并结合 L034–L036 第 2 条（延长时段设置）和 L045–L046 第 2 条（时区设置）统一核对。
2. **直接修改 CashBook 会立即改变 TotalPortfolioValue**（TotalPortfolioValueRegression，GH 3272）：示例注释写明 "users should not do this"。V1.2 研究代码不应手动改现金来模拟出入金，否则收益与回撤统计失真。
3. **数据生成示例会写入并删除本地数据目录下的文件**（ConstituentsUniverseDataGeneratorAlgorithm：在 `Globals.DataFolder` 下 `Directory.CreateDirectory`、`File.Delete`、写 CSV）。本次只读未运行；如果将来运行此类示例，要注意它会改写数据目录。
4. 远程数据源示例（CustomDataUniverseAlgorithm）在实盘模式下抓取 WSJ 网页、回测时读取 Dropbox CSV，属于外部数据依赖示例；V1.2 不使用。
5. `GlobalEquityMeanReversionIBSAlpha` 的 ETF 列表中 "EWM" 出现了 3 次，注释称 33 只 ETF，实际去重后更少，属示例数据问题。
6. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 189 个。
