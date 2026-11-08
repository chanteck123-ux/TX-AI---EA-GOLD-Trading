# L018 第 3 层：CFD、外汇、止损和限价、保证金、手续费、滑点、订单时效示例（Claude，2026-11-08）

**方式**：只读，没有编译，也没有运行。阅读方法同 L017：先用 `tools/print_example.sh` 处理，再用 grep 去掉回归模板的固定行和模板化的注释句。这些注释句是 "Initialise the data and resolution…"、"OnData event is the primary entry…"、"Slice object…" 参数说明、"End of algorithm run event handler"。其余行全部阅读。

## 一、覆盖范围（FULL_READ，19 个，均在 Algorithm.CSharp 下）
- BasicTemplateCfdAlgorithm、BasicTemplateForexAlgorithm、CfdTimeZonesRegressionAlgorithm
- StopMarketOrderRegressionAlgorithm、LimitFillRegressionAlgorithm、StopLossOnOrderEventRegressionAlgorithm
- CancelOpenOrdersRegressionAlgorithm、LiquidateRegressionAlgorithm
- MarginCallEventsAlgorithm、MarginRemainingRegressionAlgorithm、LeveragePrecedenceRegressionAlgorithm
- ZeroFeeRegressionAlgorithm、FeeModelNotUsingAccountCurrency、UnsettledCashWhenQuoteCurrencyIsNotAccountCurrencyAlgorithm
- VolumeShareSlippageModelAlgorithm、MarketImpactSlippageModelRegressionAlgorithm、TimeInForceAlgorithm
- DailyHistoryForDailyResolutionRegressionAlgorithm、DailyHistoryForMinuteResolutionRegressionAlgorithm（这两个是用 grep 搜 XAUUSD 找到的，不在 173 个关键词清单里）

MarginCallEventsAlgorithm 的许可证头被脚本报告有 1 行"代码"，经查是第 1 行开头的 BOM 字符，实际只有许可证文字。

## 二、发现（静态阅读，没有运行验证）
1. **CFD 交易示例只用 DE30EUR**（Oanda 的德国 30 指数 CFD，账户货币 EUR）。CfdTimeZones 测试的是"交易所时区早于数据时区"的情况。
   - **更正（已用 grep 检查全部示例）**：在 Algorithm.CSharp、Algorithm.Python、Algorithm.Framework 中，只有 2 个示例出现 XAUUSD：`DailyHistoryForDailyResolutionRegressionAlgorithm` 和 `DailyHistoryForMinuteResolutionRegressionAlgorithm`。本批已全文读过，均为 FULL_READ。
   - 这两个示例只检查 Oanda 的 XAUUSD CFD 在 2018-03-26 至 2018-04-10 期间，每个时间点都能**取到前一天的日线历史数据**（取不到就报错），**不涉及下单、成交或保证金**。
   - 另外，Tests 目录下有 9 个 .cs 文件出现 XAUUSD，将在读 Tests 时核对。
   - 所以 V1.2 中 LEAN 对 XAUUSD CFD 交易行为的判断，**目前只能依靠源码阅读（L001–L016）推断**，没有官方交易类回归示例可以佐证。
2. **两个示例里的"止损"挂在了错误的一侧**：
   - `StopLossOnOrderEventRegressionAlgorithm`：先开空 100 股，然后在成交价**下方 2 美元**挂买入止损单，注释写的是 "set STOPLOSS"。空单的止损应该挂在成交价**上方**，挂在下方的买入止损会立刻触发。这个示例真正测试的是"在 OnOrderEvent 里下的止损单能够成交"（GH 3239），不能当作止损写法的参考。
   - `StopMarketOrderRegressionAlgorithm` 同样在现价下方 2 美元挂买入止损单，并要求它成交。这也属于"会立刻触发的止损单"。
   - 对 V1.2 的启示：RiskExecution 应校验止损价在持仓方向的正确一侧（多单止损低于现价，空单止损高于现价），放错一侧时拒单。
3. **margin call 事件**：
   - `OnMarginCallWarning` 在剩余保证金低于总资产 5% 时触发；
   - `OnMarginCall` 在 margin call 订单执行**之前**触发，算法可以修改或替换这些订单。示例把平仓数量加大 10%，并把原请求换成新的 `SubmitOrderRequest`，这样原请求的订单属性会丢失；
   - 示例把 SPY 的杠杆设为 100、`SetHoldings(SPY, 100)`，目的是故意制造 margin call。
4. **杠杆的优先级**（GH 3784）：券商模型的 `GetLeverage` 优先于 UniverseSettings 的默认杠杆。V1.2 在 LEAN 里使用 1:1000 时，应在券商模型或品种上显式设置，并在日志中核对实际生效的杠杆。
5. **撤单与被拒单**（Cash 账户，GDAX）：资金不足的限价单状态为 Invalid；`CancelOpenOrders(symbol)` 会撤掉该品种所有挂单。`Liquidate()` 会先撤销所有挂单，再平掉所有持仓，结束时所有订单都是 Canceled，持仓为 0。
6. **手续费**：
   - 可以用自定义模型把手续费设为 0；
   - 手续费也可以用非账户货币支付（示例中用 ETH），引擎会从对应币种的现金中扣除，再换算成账户货币，计入 `TotalFees` 和 Trade 的手续费。
7. **滑点**：示例分别演示了按成交量占比（`VolumeShareSlippageModel(0.3, 0.05)`）和按市场冲击（`MarketImpactSlippageModel`）计算滑点，这两种都要**手动设置**。默认滑点为 0，与 L001/L007 的记录一致。
8. **订单时效**：
   - 默认是 GTC（长期有效）；
   - Day 单在收盘时到期并撤销；
   - GTD 单在指定日期收盘时撤销。
   - 示例注释写明目前只支持 GTC、DAY、GTD 三种。
9. 未结算现金（股票 Cash 账户，账户货币 EUR）：卖出所得先进入 `UnsettledCashBook`，经过 `Equity.DefaultSettlementDays` 后才转为可用现金。这部分和 V1.2 的 CFD 无关（CFD 不结算资金，见 L008）。

## 三、仍未读
V1.2 相关示例（按关键词筛出的 173 个）还剩 136 个，清单可由 L017 的关键词筛选重新生成。之后是其余示例和 Tests。
