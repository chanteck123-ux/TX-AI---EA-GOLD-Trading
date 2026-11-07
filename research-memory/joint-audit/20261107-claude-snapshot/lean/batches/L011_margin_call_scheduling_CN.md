# LEAN L011：margin call 的调度（Claude，2026-11-07）

- **PARTIAL**：`Engine/AlgorithmManager.cs` 共 1,062 行，本次只读了第 130–140 行和第 355–421 行（margin call 调度这一段）。
- 读到这段的方法：在 Engine 和 Common 中 grep `GetMarginCallOrders`、`ExecuteMarginCall`，唯一调用点就在这里。
- 只读，未运行。

## 发现（CONFIRMED）
1. **回测中每 5 分钟检查一次**：`marginCallFrequency = TimeSpan.FromMinutes(5)`，按算法时间计。两次检查之间即使保证金已经跌破阈值，也不会强平；最多延迟 5 分钟才平仓。MT5 的 Stop Out 是由报价驱动、逐 tick 判定的，**两边的强平时点会不同**。V1.2 的极端行情用例需要把这一点列出来。
2. **只有在所有强平单对应的交易所都开盘时才执行**（`ExchangeOpen`）。如果在周末或休市期间权益已经不足，就要等到开盘后的第一次检查才会强平。
3. 强平前会先回调 `OnMarginCall`，算法可以在这里修改强平单。没有执行强平但收到预警标志时，回调 `OnMarginCallWarning`。
4. **小缺陷**：局部变量 `executingMarginCall` 初始化为 false 后**再也没有被赋值为 true**，所以 ExecuteMarginCall 抛出异常时，错误来源也会被标成 "OnMarginCall"，日志中的来源不准确。
5. **PLAUSIBLE，判断条件疑似写反**：实盘条件是 `_liveMode && nextMarginCallTime > DateTime.UtcNow`。按字面意思，只要下一次检查时间还在未来就会执行，结果是实盘中几乎每个时间片都检查。从注释来看本意应该是"到点就检查"。这种写法不会漏检，只是检查得更频繁。具体效果需结合上下文的 `time` 来源确认，未运行验证。
