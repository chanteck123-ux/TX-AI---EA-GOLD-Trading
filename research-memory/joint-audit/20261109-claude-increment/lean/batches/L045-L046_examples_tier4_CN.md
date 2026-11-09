# L045–L046 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L044，只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 28 个）
- L045、L046 各 14 个；清单以 coverage 表中 batch 列为准。
- 主要是期权组合策略、数据归一化、universe 选择、信号导出（Collective2）、自定义期权定价模型、合成 K 线滚动窗口、分红、定时规则时区、远程命令回调。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **远程命令可以直接触发下单**（CallbackCommandRegression）：
   - `AddCommand<T>()` 注册命令类型，`Link(command)` 生成可点击的触发链接（示例通过 `Notify.Email` 发出），`BroadcastCommand` 向同一项目的**所有实盘部署**广播；
   - 命令的 `Run` 或 `OnCommand` 里可以直接 `Order` / `Buy`。
   - 对 V1.2：LEAN 只做研究，MT5/MQL5 独立执行，Python 只做 MCP 监控；如果将来有人在 LEAN 端启用命令功能，就形成了一条绕过 RiskExecution 的外部下单通道，应明确禁止。示例中的邮箱 `email@address` 和 ProjectId 都是示例值。
2. **定时规则默认按算法时区**（TimeRulesDefaultTimeZone，GH 3740）：`TimeRules.Every(6 小时)`、`Noon`、`Midnight` 和定时 universe 选择都按算法时区（默认纽约）触发。V1.2 的"服务器日 00:00 换日"（用户 Scalping 每日 6 盈/6 亏）若在 LEAN 中复现，必须显式设置时区为 FxPro 服务器时区，否则换日时刻错位。
3. **合成器自带滚动窗口**（ConsolidatorRollingWindow）：`consolidator[0]` 是刚合成的 K 线，`[1]` 是上一根，默认窗口大小为 2。
4. **分红在 Raw 模式下直接计入现金**（DividendRegression）：总利润等于分红总额，净利润 = 分红 − 手续费。CFD 不涉及。
5. `Collective2IndexOptionAlgorithm` 的 API key 为占位字符串 `YOUR APIV4 KEY`，系统 ID 为 0；`CustomUniverseImmediateSelection` 中把 AAPL 写成了 "APPL"（拼写错误，示例仍期望 3 个品种被加入）。
6. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 215 个。
