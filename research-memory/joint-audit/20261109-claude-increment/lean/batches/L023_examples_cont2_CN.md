# L023 第 3 层：V1.2 相关示例续读（2）（Claude，2026-11-08，用户要求连续执行）

**方式**：只读，没有编译，也没有运行。阅读方法同 L022（`tools/read_batch.sh`）。

## 一、覆盖范围（FULL_READ，20 个，均在 Algorithm.CSharp 下）
- ClassicRenkoConsolidator、ClassicRenkoConsolidatorWithFuturesTickTypes、VolumeRenkoConsolidator
- ComboOrder、OneCancelsOtherOrderCashAccount、CustomMarginInterestRateModel、CryptoFutureHourlyMarginInterest、CryptoFutureLeverageBasedMargin
- CustomBrokerageModel、DelistedEquityCashAccountSettlement、DelistedFutureLiquidate、EqualWeightingPortfolioConstructionModelFuture、FillForwardUntilExpiry
- FutureStopMarketOrderOnExtendedHours、LimitOrdersAreFilledAfterHoursForFutures、MarketOnCloseOrderBufferCheck、MarketOnCloseOrderBufferExtendedMarketHours
- NakedShortOptionStrategyOverMargin、NullMarginMultipleOrders、SingleLotOptionStrategyMarginCall
- **补充核对源码**：`Common/Brokerages/DefaultBrokerageModel.cs` 第 360–375 行（该文件已在 L008 FULL_READ，此次为回查）；用 grep 核对 `Cfd.cs`、`Forex.cs`、`OandaBrokerageModel.cs` 中的 `MarginInterestRateModel`。

## 二、发现（静态阅读，没有运行验证）
1. **CONFIRMED（源码）：LEAN 默认不对 CFD 和外汇计算隔夜利息（swap / financing）。**
   - `DefaultBrokerageModel.GetMarginInterestRateModel` 直接返回 `MarginInterestRateModel.Null`；
   - `Cfd.cs`、`Forex.cs` 的默认值也是 `MarginInterestRateModel.Null`；
   - `OandaBrokerageModel` 没有覆盖这个方法。
   - 对 V1.2 的影响：XAUUSD 持仓过夜（含周三三倍 swap）的成本在 LEAN 中为 0。凡是隔夜持仓的策略，LEAN 结果会**系统性偏乐观**，必须用自定义 `IMarginInterestRateModel` 按 FxPro 实际 swap 补上，或在跨引擎核对时单独扣除，并在报告中写明。→ 待汇总 R28。
2. 自定义保证金利息模型示例（CustomMarginInterestRateModel）按持仓逐期计息，利息直接计入现金并**复利累积**；加密期货示例按资金费率 × 持仓价值 × 次数（每 8 小时一次）扣除，多头为负。可以作为 V1.2 写 swap 模型的参考结构。
3. **现金账户的 OCO 单不会重复占用现金**（OneCancelsOtherOrderCashAccount）：同一组二选一的挂单只按一张单冻结资金。MT5 没有原生 OCO，V1.2 若自行实现，需要在 RiskExecution 中自己定义"挂单占用的风险预算按组计还是按单计"。
4. **期货在延长时段可以挂限价单并成交，但开盘价单（MOO）不允许**；延长时段止损市价单也会触发（FutureStopMarketOrderOnExtendedHours）。
5. **MOC 提交缓冲检查**：收盘前缓冲时间之后提交的 MOC 单会被拒绝；延长时段订阅下，缓冲按**正常收盘时间**计算，而不是延长时段的结束时间。
6. **杠杆变化直接影响保证金**（CryptoFutureLeverageBasedMargin）：调用 `SetLeverage` 后，同样的仓位所需保证金按新杠杆计算。对 V1.2：1:1000 杠杆在 LEAN 中要显式设置并核对 GOLD 的实际保证金规则，这与 AGENTS.md"杠杆变更不自动增加手数"的要求不冲突，但要分别留证。
7. **自定义券商模型可以拒单、拒改单**（CustomBrokerageModel）：`CanSubmitOrder` 返回 false 时，票据的 SubmitRequest 响应中带有原因；`CanUpdateOrder` 返回 false 时改单失败，原订单不变。
8. **保证金不足的下单**：裸卖期权组合超出可用保证金时，订单状态为 Invalid；单手期权组合遇到 margin call 时，因为无法部分减仓，会**整组全部平仓**（此前版本会抛异常，示例为回归修复）。
9. 现金账户下退市股票被自动平仓后，卖出款项先进入未结算现金，证券保留到资金结算完成才移除。期货组合构建示例断言实际持仓价值 / 组合价值 ≥ 10，即按期货保证金杠杆交易。
10. Renko（经典、成交量两种）合成 K 线、前向填充到到期日等属于第 4 层内容，只记录已读。

## 三、进度
- V1.2 相关示例（173 个）已读 153 个，还剩 20 个。
