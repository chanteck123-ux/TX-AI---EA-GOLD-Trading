# LEAN L009：SecurityPortfolioManager 与 SecurityHolding（Claude，2026-11-07）

- **FULL_READ（2 个）**：`Common/Securities/` 下的 SecurityPortfolioManager.cs（43 KB）和 SecurityHolding.cs（18 KB）。阅读前去掉了 XML 注释。只读，未编译，未运行。
- CashBook.cs 和 Cash.cs 留到 L010。

## 发现（CONFIRMED）
1. **初始资金默认是 100,000 账户货币**：构造函数里直接 `SetAmount(100000)`。V1.2 用 500 USD 研究账户，必须显式调用 `SetCash(500)`，否则资金规模会差 200 倍，风险比例仓位也会随之失真。账户货币只能设置一次，而且必须在加入任何证券之前设置。
2. **总权益的口径（CFD 部分）**：`TotalPortfolioValue` = 现金 + 未结算现金 + 非外汇/加密/期货/CFD 类持仓市值 + **CFD 浮动盈亏** + 期货当日未结算盈亏。CFD 的名义市值不计入，只计浮动盈亏。
3. **浮动盈亏是按"立即平仓"估算的**：多头用 **Bid**、空头用 **Ask** 作为平仓价；没有报价时退回到最后价；还**扣除预估的平仓手续费**（按市价单费用模型计算）。所以 LEAN 的权益和强平判断都会把平仓的点差和费用算进去。MT5 的浮盈按 Bid/Ask 计，但通常不扣佣金，这一点需要对齐（MT5 侧口径未核实）。
4. **可用保证金** = 总权益 − 未结算现金 − 已用保证金（按持仓组汇总）。这就是 L002 中强平阈值所用的公式。
5. **持仓不足一手视为空仓**：只有 `|数量| ≥ LotSize` 时才算持有（`Invested`）。不足一手的残余仓位，浮盈记为 0，也不计入权益。
6. **小缺陷（CONFIRMED，影响不大）**：
   - `CopyTo` 在方法内重新创建了一个局部数组，调用方传入的数组根本不会被填充，等于什么都没做。
   - SecurityHolding 的复制构造函数没有复制 `_totalDividends`。
   - 源码里自己留了一条 TODO，说 `GetMarginRemaining(symbol)` 的注释和实际返回值不符。
7. **ProcessFills**：在锁内逐笔调用 PortfolioModel.ProcessFill，最后使总权益缓存失效，单笔成交出错时的处理方式见 L008。
8. **分红和拆股**：拆股只作用于股票（实盘或 Raw 数据模式）；分红只在回测中、且使用 Raw 或 SplitAdjusted 数据时才计入现金。实盘依赖券商的现金同步。CFD 和外汇不受影响。

## 对 V1.2 的登记项（NOT RUN）
- LEAN 研究配置必须显式写明：初始资金 500、账户货币 USD、杠杆 1000、券商模型。不能依赖默认的 100,000 和 1:50。
- 跨引擎核对权益时，需要先统一以下几点：浮盈是否扣除预估平仓费用；按哪一侧报价计价。
