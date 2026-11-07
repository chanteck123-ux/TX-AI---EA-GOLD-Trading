# LEAN L010：CashBook 与 Cash（Claude，2026-11-07）

- **FULL_READ（2 个）**：`Common/Securities/CashBook.cs`、`Common/Securities/Cash.cs`，阅读前去掉了 XML 注释。只读，未运行。

## 发现（CONFIRMED）
1. **账户货币默认是 USD**。更换账户货币时，原账户货币的余额会搬到新币种下，**数值不做汇率换算**。
2. **总现金价值** = 各币种的 `Amount × ConversionRate` 之和。
3. **⚠ 找不到可用于换汇的品种时，静默按 0 计算**：`EnsureCurrencyDataFeed` 在 Forex、CFD、Crypto 的品种属性库中找不到能换算该币种的交易对时，**只记录一条 Error**，然后把换算设为 `ConstantCurrencyConversion.Null`。之后这个币种的现金在总价值中按 0 计算，权益被低估，系统不会停止运行。
   - 只有显式调用 `Convert` 遇到汇率为 0 时才会抛异常；聚合求和时不会抛。
   - XAUUSD 的报价货币就是 USD（等于账户货币），所以不受影响；但其他报价货币的 CFD 可能受影响。
4. **换汇用的价格订阅是内部订阅**：fill-forward，不含延长交易时段，分辨率取当前所有订阅中最细的那个，数据不会发送给算法的 OnData。
5. 单个 Cash 的 `AddAmount` 和 `SetAmount` 在锁内修改金额，然后发出 Updated 事件，使总权益缓存失效（见 L009）。
6. `CashBook` 每次增删币种都复制一份新字典再替换（copy-on-write），所以遍历时不会因为并发修改而抛错。

## 对 V1.2 的登记项（NOT RUN）
- 如果研究或执行中出现非 USD 的现金或费用，必须确认换算来源存在。"找不到汇率时按 0 计"应当视为阻断条件，而不是记一条日志就放过。
