# L115–L116 第 1 层补读：Algorithm 目录的下单入口与框架主循环（Claude，2026-11-08）

**方式**：用 `tools/dump_src.sh` 只读，没有编译或运行。之前的第 1 层阅读覆盖了 Common/Orders、Engine 交易处理和券商模型，**但没有读 `Algorithm/` 目录下的下单入口**。本批补上：
- L115：`QCAlgorithm.Trading.cs`（1,520 行）。
- L116：`QCAlgorithm.Trading.ContingentOrders.cs`（350 行）和 `QCAlgorithm.Framework.cs`（503 行）。

## 一、与 V1.2 有关的发现
1. **下单前检查**（PreOrderChecksImpl，Trading.cs 第 842–1052 行）。以下任何一项不满足，都会直接返回无效票据，并调用 `Error()`：
   - 预热期间。
   - 证券未添加。
   - 数量为 0。
   - |数量| 小于 LotSize。注意这里只比较大小，不把数量取整到 LotSize 的整数倍。
   - 证券不可交易。
   - 价格为 0。
   - 报价货币或基础货币不在 CashBook 中，或其汇率为 0。
   - `HasData` 为 false。
   - 保证金不在这一步检查，由交易处理器检查，与之前记录的"保证金不足同步变为 Invalid"一致。
2. **回测订单总数上限 10,000**（第 950–956 行）：非实盘模式下 `OrdersCount > _maxOrders`（默认 10,000）时，算法状态被设为 **Stopped**，之后的订单都被拒绝。
   - 对 V1.2：S7 Scalping 等高频策略做多年回测时，订单数（含 SL/TP 子单）可能超过 1 万，回测会提前停止。必须在 Initialize 中调用 `SetMaximumOrders`，或者在报告中核对订单总数。列入 R39。
3. **市场关闭时，市价单自动改成 MarketOnOpen**（ContingentOrders.cs 第 305–326 行）：
   - 期货和期货期权不改，可以在扩展时段直接下市价单。
   - 其余品种只要 `!security.Exchange.ExchangeOpen`，市价单就被改成 MOO，等下一次开盘才成交。只有第一次会发一条 Debug 提示。
   - CFD/外汇在每日休市、周末或交易时段数据库中的关闭时段下市价单，同样会被改成 MOO。
   - 对 V1.2：MT5 在休市时段会直接拒绝下单；而 LEAN 会把单子挂到开盘，成交在开盘价，可能有跳空。两边在休市边界上的结果会不一样，研究报告须统计这类被改成 MOO 的订单。列入 R39。
   - 另外，只订阅日线的品种在开盘时段下市价单，回测中会被改成 MOC（如果已在 MOC 截止缓冲内，则改成 MOO），实盘不改。
4. **组合下单是"先全部检查再提交"**（SubmitOrders，第 161–232 行）：
   - 一组条件单的所有请求都先经过 PrepareRequest 和下单前检查；只要有一张失败，就只返回一张无效票据，整组都不提交，不会出现只提交了一半的情况。
   - 等待触发的子单不会被同步等待。对于追踪止损子单，止损价在触发时按当时的市价计算。
5. **Liquidate 会撤掉所有非市价挂单**（第 1140–1211 行）：
   - 对每个品种，先撤掉全部非市价的挂单，包括 SL/TP，再按"持仓数量减去未成交的市价单数量"发出平仓市价单。
   - 如果已经存在一张恰好能平仓的市价单，就不再重复下单。
   - `Settings.LiquidateEnabled=false` 时，Liquidate 只写一条 Debug，什么都不做。
   - 对 V1.2：在 LEAN 研究中调用 Liquidate，会连同保护单一起撤掉，与 R35 补充（撤销 OCO 会连带撤掉止损）属于同一类风险。
6. **SetHoldings**：市场关闭时也会改用 MOO 下单；多个目标按保证金影响排序，先执行减仓的目标。
7. **框架主循环**（Framework.cs，第 106–244 行）：
   - `OnFrameworkData` 遇到 `!slice.HasData` 就直接返回，所以 Alpha → 组合构建 → **ManageRisk** → 执行这条链只在有数据的 slice 上运行，每个 slice 运行一次。
   - 风险模型返回的目标会覆盖同一品种的组合目标（`riskTargetOverrides.Concat(targets).DistinctBy`）。
   - 组合构建模型在没有调仓或没有新 insight 时返回空 targets，这时 MaximumDrawdownPercentPortfolio 不会动作。
   - 以上为 R38 提供了源码依据：风险检查的频率等于数据频率，不是逐笔，也不是服务器端止损。
8. 下单方法多数只是重载包装（Buy、Sell、Order 和各种订单类型的 int/double/decimal 版本）。其中 double 版先用 `SafeDecimalCast` 转换，与 R34（decimal 与 double 的差异）有关。

## 二、进度
- Algorithm 目录已读 3 个，剩余 56 个，其中包括 QCAlgorithm.cs（188 KB）、History、Indicators（287 KB）、Python、Universe 和各种模型的基类。
