# L034–L036 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L033，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 60 个）
- L034、L035、L036 各 20 个；清单以 coverage 表中 batch 列为准。
- 主要是股票期权组合保证金（OptionEquity* 系列）、期权组合筛选、universe 选择与移除、预热与汇率、合成 K 线（Tick/Period/Range）、框架组合构建与风控、容量测试、Alphas 示例。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **起始资金在预热结束后才确定**（WarmupStartingPortfolioValue，GH 9647）：账户持有非 USD 现金并预热时，汇率在预热期间变化；起始资产按预热结束时的汇率计算，预热期间的汇率漂移不计入净利润。V1.2 账户为 USD、XAUUSD 报价币种也是 USD，影响小；但若研究中设置非 USD 现金，起始资产口径要注意。
2. **日线合成默认不包括延长时段**（DailyConsolidationExtendedMarketHoursWarning）：订阅设为 extendedMarketHours 时，还需要 `Settings.DailyConsolidationUseExtendedMarketHours = true`，日线合成才会包含延长时段数据，否则只给警告。V1.2 在 LEAN 中对 XAUUSD 做日线或 H4 合成时，需要核对 CFD 交易时段与此设置，否则 K 线与 MT5 的服务器时间 K 线不一致。
3. **多目标 SetHoldings 按保证金影响排序执行**（SetHoldingsMultipleTargets，GH 3790）：先减仓、后加仓，以避免保证金不足。V1.2 RiskExecution 若同时调整多个仓位，也应先执行降低风险的单。
4. **期权组合保证金**：多头跨式、宽跨式不需要保证金；价差组合的保证金等于行权价差 × 合约乘数 × 数量。属第 4 层内容，V1.2 不交易期权。
5. **下单可自动添加未订阅的股票**（TradingNotAddedEquities）：对未添加的 SPY 下单时，会自动加为可交易品种并用历史价格预填。这与 L033 中"刚添加但无数据的品种下单为 Invalid"的情形不同，取决于是否能预填价格。
6. 容量测试中的 GBPJPY、TRYJPY、BTCETH 分钟级 EMA 剥头皮示例用于验证汇率换算；Triangle 套利 Alpha 示例对三个外汇对设零手续费。均不涉及 XAUUSD。
7. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 373 个。
