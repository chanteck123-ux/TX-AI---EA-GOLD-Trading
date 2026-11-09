# L025–L027 第 4 层：其余 Algorithm.CSharp 示例（按文件大小从小到大）（Claude，2026-11-08）

**方式**：只读，没有编译，也没有运行。
- 用 `tools/next_batch.sh`（调用 `read_batch.sh`）按文件大小从小到大打印，过滤规则同 L022。
- **新增保护**：如果文件前 14 行不是许可证头（`header_code_lines` ≥ 2），脚本会把第 1–15 行另外打印出来，避免漏读。本批中 `BasicTemplateIndexHourlyAlgorithm.cs`、`Properties/AssemblyInfo.cs` 两个文件属于这种情况，已补读前 15 行。
- 标记用 `tools/mark_list.ps1`。

## 一、覆盖范围（FULL_READ 145 个）
- L025：45 个，L026：50 个，L027：50 个。文件清单以 coverage 表中 batch 列为准。
- 大多数是**子类壳文件**（只覆盖分辨率、预热长度、时区偏移、ExtendedMarketHours 等一两个属性），以及基准测试（Benchmarks/）、期权组合策略示例、框架 Alpha 模型回归、预热、连续期货换月、Renko/Range 合成 K 线、期权定价模型、指数期权。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **框架自带的风控模型**：`MaximumDrawdownPercentPerSecurity(0.004)`、`MaximumUnrealizedProfitPercentPerSecurity(0.004)`、`MaximumDrawdownPercentPortfolio(0.01)` 与 `(0.015, trailing: true)` 的组合（CompositeRiskManagementModel）。V1.2 不使用 LEAN 框架，仅作参考，说明 LEAN 研究端有现成的组合回撤停止模块可以对照。
2. `Settings.FreePortfolioValue = 500` 可以设定固定的预留金额，此时不再按百分比浮动（GH 4104）。
3. **期货每日结算**（FuturesDailySettlementShort）：期货持仓按日结算现金，示例写出了每日预期现金余额。XAUUSD CFD 不按日结算，此项只作参考。
4. 外汇示例（WarmupHistory、FilteredIdentity、G10CurrencySelectionModel）使用 EURUSD 等 Oanda 市场的 QuoteBar；`FilteredIdentity` 只接受 Trade tick，而外汇只有报价 tick，所以指标永远不会就绪（示例注释已说明）。V1.2 若在 LEAN 中对 XAUUSD 用 tick 指标，要选 Quote 类型。
5. `MarketOnOpenOnCloseAlgorithm` 在 OnOrderEvent 中用 `Console.WriteLine` 打印每个事件，仅为演示。`TiingoPriceAlgorithm` 中的 API token 是占位字符串 `my-tiingo-api-token`，不是真实凭证。`FinancialAdvisorDemoAlgorithm` 中的 IB 子账户号 `DU123456` 是示例值。
6. 其余内容（期权定价模型支持的行权方式、0DTE 选择、连续期货换月时区、预热起点计算、指标与合成 K 线）属于第 4 层，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 578 个（较大的文件在后面）。
