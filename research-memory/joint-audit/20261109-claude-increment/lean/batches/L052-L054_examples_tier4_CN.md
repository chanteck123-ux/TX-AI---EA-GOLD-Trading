# L052–L054 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L051，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 34 个）
- L052：12 个，L053：11 个，L054：11 个；清单以 coverage 表中 batch 列为准。
- 主要是期权组合与匹配器、期货/连续合约模板、Session K 线、预热、universe 立即选择、组合目标标签、自定义证券属性与手续费、**手动设置交易时段与品种属性数据库**。

## 二、与 V1.2 有关的发现（静态阅读）
1. **可以在算法内手动设置 CFD 的交易时段与品种属性**（ManuallySetMarketHoursAndSymbolPropertiesDatabaseEntriesAlgorithm）：
   - `MarketHoursDatabase.SetEntry(market, ticker, SecurityType.Cfd, exchangeHours, dataTimeZone)` 与 `SymbolPropertiesDatabase.SetEntry(market, ticker, SecurityType.Cfd, symbolProperties)`，之后 `AddCfd` 就会使用这些设置；
   - 示例比较的属性包括：描述、报价币种、合约乘数、最小价格变动、手数步长、市场代码、最小下单量、价格放大倍数、行权价倍数。
   - 对 V1.2：这是在 LEAN 研究中让 XAUUSD 与 **FxPro 实际规格**（合约大小、最小变动、最小/步进手数、交易时段与时区）对齐的直接办法。可以同时消除 L013 发现的风险——"缺少品种属性时静默默认乘数 1、手数 1"。建议研究配置中显式写入并留证，而不是依赖内置数据库。
2. **自定义证券属性与按属性计费**（SecurityCustomPropertiesAlgorithm）：可以把费率等参数挂在证券对象上（动态属性、`Add`/`Get`、索引器），自定义 FeeModel 读取这些属性计算手续费，最低 1 美元。可作为 V1.2 在 LEAN 中按 FxPro 实际佣金建模的写法参考。
3. **期权组合的自动匹配**（OptionEquityStrategyMatcher）：同一账户里的期权与正股持仓会被自动重新分组为蝶式、备兑、价差等，保证金随分组变化。V1.2 不交易期权，仅作参考。
4. `SecuritySessionWithFutureContractRegressionAlgorithm` 第 102 行在核对期货合约的当前 Session 时，用的是连续合约的 `futureSession.OpenInterest`，而不是 `futureContractSession`，像是复制粘贴遗漏，属于示例断言问题。
5. 期货日线模板（BasicTemplateFuturesDaily）注释说明日线数据在晚 8 点到达，需要检查交易所是否开盘，避免周五夜间下单。
6. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 130 个。
