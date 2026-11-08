# LEAN L008：DefaultBrokerageModel 全文与持仓成交入账（Claude，2026-11-07）

- **FULL_READ（2 个）**：`Common/Brokerages/DefaultBrokerageModel.cs`（L002 时只读了一部分，本批补成全文）、`Common/Securities/SecurityPortfolioModel.cs`。
- 只读，未编译，未运行。

## 一、DefaultBrokerageModel（CONFIRMED，补充 L002）
- **CFD 的默认市场是 Oanda**。IB 模型里 CFD 的默认市场则是 InteractiveBrokers（见 L007）。
- `RequiredFreeBuyingPowerPercent = 0`，即不预留空闲保证金。
- `CanSubmitOrder` 只拒绝"期货或期货期权的 MarketOnOpen 订单"；`CanUpdateOrder` 和 `CanExecuteOrder` 一律放行。
- 卖空数据源默认是 `NullShortableProvider`，可以无限卖空；保证金利息模型默认为 Null。
- `IsValidOrderSize` 只检查最小下单量。

## 二、成交如何改变持仓（CONFIRMED）
1. **只有净持仓（netting），没有对冲持仓（hedging）**：每个品种只有一个 Holdings，记录数量和平均价格。加仓时按数量加权更新均价；反向成交时先抵减持仓，穿过 0 后均价改为本次成交价。
   - **对 V1.2 的含义**：如果 FxPro MT5 账户是对冲模式，同一品种可以同时持有多笔独立的多单和空单，每笔有自己的 SL 和 TP。LEAN 无法表达这种结构。跨引擎核对必须先确认 MT5 的账户模式。账户模式**尚未核实**，作为 V1.2 的登记项。
2. **CFD 和期货的资金处理**：开仓时不扣除名义资金，平仓时把已实现盈亏一次性计入现金（ApplyFunds）。浮动盈亏只体现在持仓估值里。
3. **手续费**：费用为 0 或 OrderFee.Zero 时跳过；否则把费用换算成账户货币，计入持仓费用，并从对应币种的现金中扣除。
4. **⚠ 交易记录的盈亏口径**：每次平仓的 `transactionProfitLoss = 已实现盈亏 − 2 × 本次手续费`。也就是**假设开仓手续费等于平仓手续费**。开平仓费用不同时（例如按价值收费），记录下来的单笔盈亏和胜负判定（`IsWin`）都会有偏差。V1.2 评分要求"费用口径一致，避免重复扣费"，这里的单笔记录不能直接拿来用。
5. **⚠ 异常时状态可能不一致**：`ProcessFill` 整体包在 try 中，catch 只记日志，之后**仍会调用 SetHoldings** 写回当时局部变量的值。如果中途抛出异常（例如费用已经扣了，但数量还没更新），就会出现现金已变、持仓数量没变的半完成状态，而且不会报错。这与 L005 中"ProcessFills 异常只记日志"叠加，形成两层吞掉异常。
6. 已实现盈亏 = 平仓数量 ×（成交价 − 持仓均价），平仓数量取本次成交量和原持仓量中较小的一方，再换算成账户货币。

## 三、对 V1.2 的登记项（NOT RUN）
- 先核实 MT5 账户是对冲模式还是净持仓模式，再决定跨引擎核对的粒度。如果是对冲模式，LEAN 侧只能做按品种汇总的对照。
- 胜率和单笔盈亏必须用 V1.2 自己的口径重新计算：开仓费、平仓费、点差、隔夜费分开列示。
- 成交入账要具备原子性：失败时进入阻断和对账流程，不能写回半完成状态。
