# L014 交易管理器补完与交易时段类（Claude，2026-11-07）

**层级**：第 1 层。
**方式**：只读阅读源码，没有编译，也没有运行。

## 一、覆盖范围
- **FULL_READ（4 个）**：
  - `Common/Securities/SecurityTransactionManager.cs`：L013 已读第 60–160 行和第 630–680 行，本批补读第 1–60、160–629、680–693 行，合计为全文；
  - `Common/Securities/LocalMarketHours.cs`；
  - `Common/Securities/MarketHoursSegment.cs`；
  - `Common/Securities/MarketHoursDatabase.cs`。
- 后三个文件的阅读方法：先读代码行，再单独读 `///` 注释行。
- 引用了 `BaseSecurityDatabase` 但没有读，状态仍为 UNREAD。

## 二、发现（静态阅读，没有运行验证）
1. **CONFIRMED：缺少交易时段和缺少品种属性的处理方式相反。**
   - `MarketHoursDatabase.GetEntry` 查不到条目时会记录错误并**抛异常**，属于失败即阻断。
   - L013 记录的 `SymbolPropertiesDatabase` 查不到时会**静默使用默认值**：合约乘数 1、最小手数 1。
   - 对 V1.2 来说，XAUUSD 的交易时段会被强制要求登记，品种规格却不会。所以 RiskExecution 必须自己检查品种规格。
   - 查找顺序：先查精确条目，再查"市场 + 类型"的通配条目（null symbol），期货期权回退到对应的期货，自定义数据按 `TYPE.xxx` 查找。
2. **CONFIRMED：配置项 `force-exchange-always-open` 打开后，所有品种都按 24×7 开市处理。** 节假日、周末休市、每日休市都会被忽略，时区仍保留原条目的设置；找不到条目时用 UTC。如果 V1.2 的 LEAN 研究配置里打开了这个开关，交易时段相关的结果就不能和 MT5 对照。
3. **CONFIRMED：回测期间预热时不会撤单，也不会报错。**
   - `ProcessRequest` 在预热中会抛异常，拒绝下单和改单；
   - `CancelOpenOrders` 在预热中直接返回空列表，什么都不撤，也不报错。
4. `GetOpenOrdersRemainingQuantity` 的计算方式：
   - 对 OCO/OUO 这类互斥的兄弟订单，按品种只取剩余量最大的那张；
   - 还在等待父单触发的子单（`IsWaitingForTrigger`）不计入。
   - 所以已挂但没激活的附带止损或止盈单不算在待成交数量里。用它估算挂单风险时要注意这一点。
5. `WaitForOrder`：回测中 `MarketOrderFillTimeout` 为 0，订单要是还没关闭，会立即返回 false；实盘默认等 5 秒（见 L013 读到的 `SetLiveMode`）。
6. `LocalMarketHours` 会过滤掉状态为 Closed 的时段，用 `IsContinuousMarketOpen` 判断跨午夜或相邻时段是否连续，防止把连续交易误判成新开盘。`MarketHoursSegment.Contains` 的区间是左闭右开 [Start, End)。
7. `GetMarketHoursSegments` 会检查开盘、收盘和扩展时段的先后顺序，不合法就抛异常；但 `LocalMarketHours` 的构造函数**不检查**各时段是否重叠、是否按顺序排列。如果数据文件有问题，问题会延后暴露。

## 三、仍未读
- `BaseSecurityDatabase.cs`；
- `Engine/Results` 下的 Live、Regression 和 IResultHandler；
- `Analysis/` 中与止损止盈、保证金、过期成交相关的分析器。
