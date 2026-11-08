# L021 第 3 层：短小示例批（期货、组合单、加密手续费、券商消息、退市结算等）（Claude，2026-11-08）

**方式**：只读，没有编译，也没有运行。
- 阅读方法同 L018，另外按 L020 的做法，去掉只做日志输出的 `Log(`、`Debug(` 行和空的 `//` 注释行。
- 本批还新增过滤 `{ "key", "value" }` 形式的统计模板行（有些文件写成 `new()` 而不是 `new Dictionary<…>`，print_example.sh 的规则匹配不到，所以补充）。

## 一、覆盖范围（FULL_READ，32 个，均在 Algorithm.CSharp 下）
- **子类壳文件**（只覆盖一两个属性，父类之后读或已读）：
  - EquityDottedTickerFirstAdditionOrder、ComboLegLimitOrderAsync、ComboLimitOrderAsync
  - StrictEndTimeLowerResolutionFillForwardWithExtendedMarketHours、DelistedEquityInMultipleUniversesCashAccountSettlement、DelistedEquitySoldOnWarningCashAccountSettlement
  - DelistedFutureLiquidateDaily、DelistedFutureLiquidateFromChainAndContinuousMidnightExpiry、CryptoFutureDailyMarginInterest
  - FillForwardStrictEndTimeDaily、FillForwardStrictEndTimeMinute
  - Bitfinex 和 Binance 的 Cash、Margin 账户手续费（共 4 个）、MarketOnCloseOrderDayTimeInForceFillsOnCloseTrade
  - ComboMarketOrder、NullMarginComboOrder、DefaultMarginComboOrder、DefaultMarginMultipleOrders
- **其他**：
  - ClassicRenkoConsolidatorWithFutures 的 AndDefaultTickType 和 QuoteTickType 两个版本、BasicTemplateFillForward、SetHoldingsLiquidateExistingHoldingsMultipleTargets、TrailingStopRiskFramework
  - BrokerageActivityEventHandling、CustomBrokerageMessageHandler、CustomBrokerageSideOrderHandling、DelistedEquityFromRemovedUniverseCashAccountSettlement
  - OptionsMarginCallEventsAlgorithmBase、EmitInsightCryptoCashAccountType、ImmediateExecutionModelWorksWithBinanceFeeModel

## 二、发现（静态阅读，没有运行验证）
1. **券商连接事件和券商端下单**：
   - `OnBrokerageMessage`、`OnBrokerageDisconnect`、`OnBrokerageReconnect` 分别在收到券商消息、断开连接、重新连接时触发；
   - 通过自定义的 `IBrokerageMessageHandler.HandleOrder`，可以决定是否把**在券商那边手动下的订单**加入 LEAN 的交易记录，示例中只接受 tag 为偶数的订单。
   - 对 V1.2 的参考：RiskExecution 的对账需要明确规定，在 MT5 终端手动下的单或其他来源的订单，是纳入管理还是告警隔离。
2. 示例 OptionsMarginCallEventsAlgorithmBase 的注释写明，默认的 margin call 只有在"已用保证金 > 总资产的 110%"时才会生成强平单（缓冲为 10%），所以示例把缓冲设为 0 才能触发。这与 L015 的 R15（分析器说明误写成 10%）的结论一致。
3. **默认保证金模型会拒绝超出可用保证金的组合单或多张订单**，订单状态为 Invalid，持仓组和已用保证金都保持为 0。只有显式改用"空持仓组"的保证金模型时，这类订单才能成交。
4. 收盘价单（MOC）设为 Day 时效时，**不会在收盘时过期**，而是等到收盘之后，按官方收盘价成交。
5. `TrailingStopRiskManagementModel(0.01)` 示例（框架中的风险管理模型）：预期结果是 2 笔订单、胜率 0%、净值 −0.41%，每笔手续费 1 美元。这是 LEAN 自带的跟踪止损风控模块，V1.2 不使用 LEAN 的框架，仅作参考。
6. 期货相关的示例使用了 **COMEX 黄金期货**（`Futures.Metals.Gold`），场景包括 Renko 合成 K 线，以及午夜到期的合约在退市时的平仓边界情况（GH 9092）。这是**黄金期货，不是 XAUUSD CFD**，只能说明 LEAN 有黄金期货的数据和到期规则，不能直接用于 CFD。
7. 加密货币手续费示例按 Binance 和 Bitfinex 区分 Cash 和 Margin 账户，并且在计算下单数量时会考虑手续费，属于第 4 层的内容。

## 三、进度
- V1.2 相关示例（173 个）已读 104 个，还剩 69 个，大多数行数在 120–380 行之间。
