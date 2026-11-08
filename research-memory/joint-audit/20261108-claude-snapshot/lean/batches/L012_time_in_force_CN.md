# LEAN L012：订单时效（TimeInForce）（Claude，2026-11-07）

- **FULL_READ（4 个）**：`Common/Orders/TimeInForce.cs`，以及 `Common/Orders/TimeInForces/` 下的 DayTimeInForce.cs、GoodTilCanceledTimeInForce.cs、GoodTilDateTimeInForce.cs。只读，未运行。
- EquityFillModel 只适用于股票，与 XAUUSD 无关，**降为低优先级**，暂不读。

## 发现（CONFIRMED）
1. **CFD 和外汇的 Day 单在纽约时间 17:00 到期**：截止时间写死为纽约 17:00，下单时间晚于 17:00 的顺延到次日。源码注释说这与 IB、Oanda、FXCM 的实际做法一致。FxPro 和 MT5 的挂单时效，以及服务器日的分界（这同样影响 V1.2 Scalping 的"每日 6 盈 / 6 亏"是按哪一天计数），**需要另行核实**，不能直接套用这个 17:00。
2. **GTC 永不到期**，`IsFillValid` 恒为 true。Oanda 模型只接受 GTC（见 L007）。
3. **contingent 子单的时效从父单成交时开始计算**（`GetWorkingTime`）。
4. **PLAUSIBLE，时区可能混用**：GoodTilDate 处理 CFD 和外汇时，用 `order.Time.Date`（UTC 日期）和 `Expiry.Date` 比较，判断是否同一天。如果 Expiry 用的是纽约时间或交易所时间，日期边界附近可能判断错一天，未运行验证。
