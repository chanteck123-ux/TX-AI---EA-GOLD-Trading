# L049–L050 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L048，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 24 个）
- L049、L050 各 12 个；清单以 coverage 表中 batch 列为准。
- 主要是 0DTE 期权选择、期权行权与指派、期货期权日线、波动率模型、运行时添加币种的汇率预填、延长时段历史请求、合成器扫描刷新、模糊推理示例、Binance 期货 BNFCR 保证金池。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **按 TimeSpan 合成的 K 线按时钟对齐，并会在收盘后由"扫描"刷出**（ConsolidateScanRegression）：
   - 小时数据合成 3 小时 K 线，发出时刻为 12:00、15:00、18:00（从午夜起算的 3 小时整点），其中 18:00 那根在 16:00 收盘之后才发出；
   - 2 天 K 线在第 3 天 9:00 发出；按 `Resolution.Daily` 合成的日线在 16:00 发出。
   - 对 V1.2：这与 L040–L042 第 1 条（按开盘对齐的 MarketHourAwareConsolidator）是两种不同的对齐规则。MT5 的 H4 按服务器时间 00:00 起每 4 小时对齐。LEAN 中复现 H4 时，必须确认时区（服务器时区）与对齐起点都一致，并核对"最后一根何时可用"，否则存在提前或滞后一根的风险。
2. **日线订阅下市价单在收盘成交，同日买入后平仓无法实现**（FutureOptionDailyRegression 注释）：与 R25（日线下市价单自动改成 MOC/MOO）一致。示例断言的错误提示写"4PM"，实际检查的是 17 点，属于提示文字不一致。
3. **运行时添加的币种会立即预填汇率**（RuntimeCurrencyConversionSeeding）：修复前汇率为 0 会导致换算抛异常。V1.2 账户为 USD，影响小。
4. **共享保证金池**（BinanceCryptoFutureBnfcrCollateral）：不同报价币种的期货共用同一抵押资产，一个品种已用的维持保证金会从另一个品种的可用购买力中扣除。V1.2 的账户级保证金核算也应按"共享池"理解。
5. `FuzzyInferenceAlgorithm` 与 L043–L044 的 `EtfGlobalRotationAlgorithm` 一样，只捕获 `RegressionTestException`，属于示例代码问题。
6. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 165 个。
