# S4保留版 LEAN 迁移第一批：差异与缺口登记（Claude，2026-10-12）

参照源：`TB500_S4_BE125.mq5`，SHA256 `f6abe1ab…be47`（只读，未修改）。实现：`lean/algorithms/S4/`。数据是 2026 年 8 月的数据，已在开发中使用，**不是 OOS**。评分 N/A（SCORE_TARGETS_UNSET）。本批属于工程迁移，**不宣称**与原生结果对等，也**不宣称**迁移已完成。

## 1. 各层落实情况

| 层 | LEAN 实现 | 依据／状态 |
|---|---|---|
| 指标与信号 | 复用 I9 C# 引擎（`Scan4`、VFI_SIGNAL_DELTA 门控、`IsValid`＝Valid15 sid3 的时段与动量检查），以引用方式编译，不复制、不改写；只启用 S4，Scalping 关闭 | I9 的 67 项旧信号 fixture 已由 Codex 用原 DLL 重跑通过（属于信号层）；本批 fixture 也链接并跑通 legacy 与 S456 语义套件。VFI 数学本批**没有重新审计**，沿用 I9 的历史核对 |
| K 线与报价 | 使用原生收盘 K 线（真实 tick_volume），按收盘时间发布；报价来自 FxPro tick ZIP（UTC+3，只在 8 月核实过）；不从报价行数推算 tick_volume | runner 校验 tick manifest 与 K 线扩展证明的哈希 |
| 风险门控 | 依 MQ5 RiskGate 顺序移植：紧急锁、日锁、基线、过期／已消费、Valid15、在途请求、两槽、冷却、**方向性追价**（只拦逆向追价，`dir*(entry-ref)>0.25ATR`）、SL 取整、绝对／相对点差、TP＝1.5R、StopsValid、最小手风险、`min(余额,净值)`×2%、组合 2%／净值 3% 剩余额度、AUTO_RISK 不设手数上限、保证金 25%、Stop-out 缓冲 | 21 项默认值由 fixture 直接解析 MQ5 `input` 后逐项比对 |
| 仓位 | 最小手单位风险含 2 tick 入场／出场压力和 15 USD/手**估算额度**；真实手续费单独记账 | 两者分开，不重复扣除 |
| 保护与退出 | 服务器侧 SL/TP；1.25R 保本（剩余量按比例分摊的实际入场手续费＋5 USD/手估算平仓成本＋负隔夜利息＋2 tick，向保护方向取整；须改善 ≥2 tick 且 StopsValid）；ENTRY_RISK_OVERRUN 缩减到安全手数或全平；紧急锁全部平仓；连续 3 笔净亏损后冷却到平仓时间＋15 分钟；按 UTC 日计算 3% 日亏损（**不套用** Scalping 的服务器日 Daily6） | 管理先于新增风险门控（MQ5 OnTick 顺序）。日锁只拦新单，管理照常（fixture 已验证） |
| 成交与成本 | 每次开、平、减仓都是真实 QC `MarketOrder`；成交价＝决策时报价（自定义 FillModel，不允许无因果报价的成交）；手续费为每手每边 3.5 USD、向上取整到分 | 3.5 来自 MT5 测试器 deals（0.01 手收 0.04，0.02 手收 0.07），**未按实盘校准**。原生 D4BF2385 记录的成本是 7.67 USD／往返标准手 |
| 双槽对账 | MT5 是对冲账户的两个独立持仓，LEAN 只有一个净持仓。S4Core 的槽位账本**只由真实 QC 成交**（价格、数量、费用）构成。每次成交写入账本**之后**做对账：LEAN 数量必须等于各槽签名手数之和，LEAN TPV 与账本净值的差 ≤0.05 USD，逐单手续费一致，成交价一致。任一不符时 RESULT 标为 RECONCILIATION_FAILED | 不存在“引擎空仓、伪账本独立出利润”的情况。fixture 证明净额制与对冲制在任意价格下的总净值相等 |

## 2. 已修正的问题（Codex 初读时发现）
- 原代码在 `Execute` 内下单后**立即**对账，这时账本还没写入这笔成交，每张单都会被计为不一致，所有运行都会判失败。现在改为 core 在“成交写入账本之后”回调 `AfterFillApplied`，在这个时点做正式对账，容差不放宽。fixture `reconcile_hook_after_each_applied_fill_zero_mismatch`（4 次回调、0 次不符）和 `reconcile_inside_broker_call_would_see_transient`（旧位置会出现 4 次暂态不符）锁定了这个时序。
- ~~TPV 比对取三个候选标价中差额最小者~~：这一做法已撤销。Smoke 运行 `S4B1_SMOKE_D250_20261012T090135Z_c3a0007a` 的对账差额为 0.07，判为失败（运行留档，不覆盖）。Codex 从源码确定了原因：LEAN 的 `SecurityPortfolioManager.cs` 第 455–459 行中，CFD 的 TPV 使用 `Holdings.UnrealizedProfit`，即 `SecurityHolding.TotalCloseProfit(includeFees=true)`（第 477–508 行）。它把**净持仓**按单边报价计价（净多用 bid、净空用 ask），并扣除净仓的**预计平仓手续费**。该次运行中净持仓 0.02 手，ceil(0.02×3.5)＝0.07，与差额完全一致；数量、手续费、成交价的不符次数都是 0，期末余额两边都是 517.36。
- 现在使用**唯一固定公式**：预期 TPV＝所有槽位按 LEAN 净持仓方向的同侧报价计价后的账本净值，减去净持仓的平仓手续费（3.5／手、向上取整到分）。不再从多个候选中取最优，容差仍为 0.05。平仓手续费另用 `holdings.TotalCloseProfit(includeFees:false) − holdings.UnrealizedProfit` 独立核对；只要不符，就记一次 `liquidation_fee_mismatches`，对账判为失败。MT5 close-side 净值仍逐条保留，与 LEAN 的差额明确拆成两部分：(a) 对冲槽各自按平仓侧计价与按净持仓单边计价的差；(b) LEAN 的预计平仓手续费。这一差额只作归因，不参与通过判定。fixture `lean_tpv_net_long_*`／`lean_tpv_net_short_*`（各 5 项）用按 LEAN 公式实现的独立净额 broker 精确复现了这个差异。

## 3. 未移植或假设项（结果中均有标注）
| 编号 | 内容 | 影响／处理 |
|---|---|---|
| G1 | 保证金按名义 1:1000 计算（手数×100×价格/1000），按总保证金保守检查；**不代表**券商的保证金档位或对冲保证金规则 | 500 USD 时保证金远低于 25%，预计不会触发；不能由此推出券商一致 |
| G2 | Stop-out 水平假设为 100%（账户未导出该值） | 同上 |
| G3 | 不计隔夜利息（swap 为 0）；contract.csv 有多头 −69.25、空头 17.15，但历史日期的值未核实 | **更正（2026-10-12）**：原生 D4BF2385 的 swap＝0，只说明原生持仓没有产生隔夜利息，**不能**推出 LEAN 的持仓不会跨夜，或跨夜不受影响。LEAN 的路径可能不同。全月完整 trace 必须检查每笔 LEAN 持仓是否跨过服务器 00:00；比较工具 `tools/S4Compare` 的 layer8 会逐笔列出两边的跨夜持仓。LEAN 一侧只要出现跨夜，就登记为本缺口下的成本缺口，并且不能把这部分差额归因到策略 |
| G4 | SL/TP 默认按触发时的报价成交（`-ProtectiveFill LEVEL` 可改为按价位成交）；MT5 测试器的实际语义未核实 | 跳空时盈亏有差异，需要 Codex 对照原生 deal 价格 |
| G5 | 同一 tick 内的顺序：先处理到期的延迟请求，再服务器侧 SL/TP，再执行 EA 逻辑 | MT5 的顺序不可知；历史上同毫秒报价差异曾经让 TP/SL 结果反转，这类差异应登记为模型差异，**不能**解读为策略改善 |
| G6 | 延迟模型：请求在 t＋延迟之后的第一个报价执行，不加随机性；到时 stops 无效则拒单，结构不复用 | **更正（2026-10-12）**：原生基线的 MT5 测试器使用**固定**执行延迟 250 ms（`conditions.execution_delay_ms=250`），原文写成“随机延迟”是错误的。LEAN 同样使用固定 250 ms。剩余的、未核实的差异在于：MT5 在延迟到期后以哪一个报价成交（第一个时间不早于到期时刻的报价，还是有其他规则），以及同一毫秒内多个报价的先后顺序；这些都需要用原生 ORDER_SENT 价格逐笔对照（比较工具 layer4） |
| G7 | 不对 deal 利润做“分”位取整（MT5 按分取整，每笔差 ≤0.005 USD） | 很小，已列出 |
| G8 | 不模拟部分成交、requote 或 deviation（FxPro 为市价执行模式） | — |
| G9 | stops/freeze level 取 0，来自 2026-10-04 的快照，**不是**历史值 | — |
| G10 | 测试器的现金台账、持久化状态、租约、ownership、外部持仓、MISSING_SL、报价新鲜度（回放中恒为新）均未移植，因为单进程回测中不存在这些情况 | 不影响 S4 研究路径 |
| G11 | MaxDailyTrades＝0（关闭）未移植；如改为非 0，门控会返回 NOT_PORTED | — |
| G12 | ATR 移动止损与部分平仓按默认关闭，未移植 | 若开启必须另批移植并测试 |

## 4. 运行顺序（由 Codex 执行）
1. `run_s4.ps1 -Mode Fixtures`（纯 C#）。
2. `-Mode Build`。
3. `-Mode Smoke -LatencyMs 250`（服务器时间 8/1–8/3）。
4. 只有在 smoke 状态为 `SMOKE_PASS_REVIEW_REQUIRED`、对账通过、源码哈希不变时，才执行一次 `-Mode FullAugust -LatencyMs 250 -SmokeRunDir <smoke目录>`。runner 会强制检查上述条件，并核对全月行数＝20,513,403。

建议用 250 ms，是为了与原生基线 D4BF2385（500 USD、250 ms、净 102.03 USD、56 笔）的条件对齐，见 `research/S4_NATIVE_AUG_BASELINE.json`。对照时按时钟→指标→信号→仓位→保护→订单→成本的顺序逐层比较。净值差异只能作为模型差异分析的线索，不作为结论。
