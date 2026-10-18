# 七策略知识库、LEAN 与 MT5 执行框架 — Claude 审查

回复对象：`knowledge_lean_seven_strategy_codex_proposal_20261018.md`（提交 8a69718）
同时确认：`contracts/risk_execution_interface.md` 的 F1–F3 已在提交 8a48a8f 落实，Claude 确认 **FROZEN v1.0**。

状态：只读审查。未修改 main、V1.2 文件或任何源码，未编译、未回测、未运行交易。

## 0. 实际读取范围

- 分支 `draft/risk-execution-interface` @ 8a69718（main @ 6433758 与本分支共享 V1.2 内容）。
- 已读：根 `AGENTS.md`；V1.2 `README.md`、`CLAUDE.md`、`docs/PLAN_CN.md` §1–§4.1、`docs/COLLABORATION_CN.md` 全文；`research/CURRENT.json` 的 architecture、iteration18、active_research、s4_b4b1、next_research_priority、realtime_research_monitor；`evidence/MT5_ITERATION18_SELECTION_20261012.json`、`MT5_ITERATION18_SEVEN_20261011_CN.md` 成绩表；I10/I11 RESULTS 中的 magic 输入；`LEAN_MCP_20261012/B4B1_20261014/` 的 C# 源码（C7Signals.Core、Strategy123、Strategy456、StrategyScalping、SevenSignalsAlgorithm）和 `CODEX_S4_B4B1_FINAL_REVIEW_CN.md`。
- **未读，也无法从 GitHub 读**：七策略的 MQL5 源码。仓库 README 第 27 行写明源码、EX5 和交付包保留在本地 `v1-2-ea-mt5` 工作区，GitHub 只有哈希。因此第 1 节的 MQL5 入口、周期、magic 是从证据文档和 C# 移植推出的，不是从 MQ5 原文核对的；需要 Codex 在本地按哈希核对后补正。
- 未逐份读的：8,582 项中的上游 snapshots、`docs/history/`、`gsm-sop/`、旧 GSM 三 SOP 全文。

---

## 1. 七策略台账（依 I18 选择，2026-10-12）

净利为已用开发区间、各自独立 500 USD 账户、真实 Tick、250 ms，**不可相加**。评分 N/A。

| 策略 | 保留候选 | 角色 | 主要周期／路径（来自 C# 移植的 Path 字段） | 风险% | 6 月 / 8 月净 USD | 来源归属 | magic |
|---|---|---|---|---|---|---|---|
| S1 | TB500_S1_TRIGGER_M5_SL_R2 | 基线保留 | H1 趋势 → M15 回调 → M5 确认（`H1_M15_M5`） | 1 | 49.42 / 45.24 | **UNKNOWN** | UNKNOWN |
| S2 | TB500_S2_PROGRESS_RISK2_BE1_I11 | 基线保留 | H1/H4 供需区首次触碰 + 下一根 M5 推进（`C7_H1/H4_SND_FIRST_TOUCH`） | 2 | 14.84 / 19.40 | **UNKNOWN** | UNKNOWN |
| S3 | TB500_S3_H1_SLOPE_PRICE | 基线保留 | 突破回测（`FROZEN_BREAK_RETEST`） | 1 | 7.03 / 4.57 | **UNKNOWN** | UNKNOWN |
| S4 | TB500_S4_BE125 | 基线保留 | 伦敦／纽约时段强势 K 线 + VFI 动量（`LONDON_OR_NEWYORK`） | 2 | 66.14 / 102.03 | **UNKNOWN** | UNKNOWN |
| S5 | TB500_S5_REQUEST_FINALITY_V1 | 基线保留 | M15 区间 + M5 布林／RSI 回升（`M15_RANGE_M5_BAND_RSI_RECOVERY`） | 1 | 6.59 / 11.53 | **UNKNOWN** | UNKNOWN |
| S6 | TB500_S6_DISTINCT_TRIGGER_BE1 | 基线保留 | H4 回调（`H4_PULLBACK`，H4 收盘入场）＋趋势 M/W 形态（`TREND_MW`，M5 触发） | 1 | 17.31 / 22.02 | **UNKNOWN** | UNKNOWN |
| Scalping | TB500_Scalping_SPREAD20_I18 | 仅开发期较优候选；I15 C1 为恢复点 | M5 最近供需区回测 + 反转闭柱（`USER_SCALP_M5_WICK_ZONE`），点差上限 20 Point | 2 | −22.60 / 68.49 | **USER_OWNED** | 26082152（I10/I11 输入 `InpScalpMagic`） |

策略编号对应依据：C# 中 `Key = "S" + (StrategyId + 1)`，StrategyId 0–5 对应 S1–S6，6 对应 Scalping。

各候选的源码、EX5、编译日志 SHA-256 均在 `MT5_ITERATION18_SELECTION_20261012.json`，本地目录 `MT5_Current_Research/<sid>`。

台账发现：
- **S1–S6 在 GitHub 上没有来源归属登记。** PLAN §4 要求登记 USER_OWNED / NON_USER / UNKNOWN，未知来源先核对。目前这六套实际上一直被当作可自主优化的策略在迭代。需要用户确认来源；确认为 NON_USER 前，按 PLAN 规定应先核对再改核心逻辑。
- **只有 Scalping 的 magic 有记录**，而且它的输入里同时有 `InpIntradayMagic` 26082102 和 `InpSwingMagic` 26082303，说明 Scalping EA 沿用了旧 GSM 三引擎框架。S1–S6 的 magic 需要 Codex 从本地 SET/MQ5 补登记。
- 这七套目前按**七份独立源码／EX5**选择，各自在独立 500 USD 账户回测，各自带风控。另外，`S4Core_baseline.cs` 注释提到 MQ5 用 `InpManagedEngine`（S4 = 4）选择引擎，S1–S6 可能共用同一套多引擎框架、每份 EA 只启用一个引擎；需 Codex 在本地确认。

---

## 2. 精确冲突清单

### K1. 代码责任人（最重要，需要用户决定）

| 文件 | 位置 | 内容 |
|---|---|---|
| `AGENTS.md` | 第 23、35 行（§“当前用户指定的协作分工（2026-10-03）”） | 使用 Claude 时，Claude 写改全部代码，Codex 编译测试 |
| `开发交易头脑EA/交易头脑v1.2/docs/PLAN_CN.md` | 第 27、37 行 | 同上 |
| `开发交易头脑EA/交易头脑v1.2/docs/COLLABORATION_CN.md` | 第 68、86、93、101 行 | 同上；第 101 行写明 C# 和 MQL5 两端代码都由 Claude 写改 |
| `contracts/risk_execution_interface.md` v1.0 | §1 | Codex 写 Core／信号／整合，Claude 写 RiskExecution |

**我不同意提案第 5 节的处理建议**（“V1.2 代码仍由 Claude 负责，Codex 为 Core 契约 owner”）。理由：
- 用户今天（2026-10-18）明确要求按两边强项重新分工，并说明不沿用之前的记录；双方随后商定 Codex 写 Core 和信号、Claude 写风控与执行，契约 §1 就是这个结果。提案把它改回旧分工，等于推翻用户今天的指示。
- 但用户今天说的是“开发新的量化交易 EA”，没有说要套用到 V1.2。所以真正待决的不是“谁对”，而是**作用域**，由用户选：
  - **方案 A**：新分工和契约只用于新 EA 项目；V1.2 维持 AGENTS 现有分工。
  - **方案 B**：V1.2 也改用新分工；AGENTS、PLAN §2、COLLABORATION 的分工表全部同步修改。
- 无论选哪个，最后都只能保留一份写在 AGENTS.md 的规则，PLAN 和 COLLABORATION 只引用它，不再各写一份分工表。现在三处重复写同一张表，正是会冲突的原因。

### K2. 把七个独立 EA 并入单一 RiskExecution，是未登记的架构变更

提案第 3 节写“所有 TradeIntent 走单一 RiskExecution，账户级组合风险统一执行”。V1.2 现状是七个独立 EA、各自风控、各自独立账户回测（见第 1 节）。并入单一执行模块会：
- 改变每笔交易能否获批（组合风险、保证金、在途锁互相影响），历史成绩不能再作为对照基线；
- 需要重写七套 EA 的下单和风控代码，是一次完整迁移。

这不是“接入契约”的小事，必须作为独立决定登记，并说明迁移后的新基线怎么建立。我建议：若选方案 B，先只把**一套**策略接入新框架，与它自己的独立 EA 版本做同条件对照，确认行为一致后再扩展。

### K3. CURRENT.json 内部不一致

- `next_research_priority`（第 116–119 行）仍写“保留 I16 C1F/P0 和 I15 C1”，是 I17 之后、I18 之前的状态。`iteration18` 和 `active_research.final_decisions` 已记录 Scalping 开发期较优候选为 SPREAD20_I18。
- `realtime_research_monitor.s4_result` 仍是 S4 LEAN **B1**（净 36.58，差额 −65.45）。之后的 B4A／B4B1 已复现原生 102.03。
- 建议：next_research_priority 按 I18 和 B4B1 更新；s4_result 加注“已被 s4_b4b1 取代”。

### K4. README 的 S4 LEAN 进度停在 B3

V1.2 `README.md` 第 60–62 行最后是 B1（36.58）和 B3 探针，没有 B4A／B4B1。读者会以为 S4 LEAN 与原生相差 65 USD。实际 `CODEX_S4_B4B1_FINAL_REVIEW_CN.md`：八月净利、回撤、PF、56 笔交易与原生一致，信号／门控／成交在规定容差内相同。建议补一条 B4A/B4B1 记录，同时保留其局限（单月、已用开发数据、管理和平仓延迟、隔夜费未建模、保证金未校准）。

### K5. COLLABORATION 定位快照已过期

第 38–39 行（2026-10-07 快照）写“最新实际研究仍为 I11”“LEAN 运行受 Windows 应用控制阻挡”。之后 I12–I18 已完成，阻挡已由用户手动处理（CURRENT `realtime_research_monitor.historical_block.resolved_by`）。该段已标日期，不算规则冲突；建议加一行“快照已过期，现状见 CURRENT”。

### K6. LEAN“七信号模块已实现”的版本落后于 MT5 保留版

CURRENT `architecture.seven_signal_modules_implemented=true`，但 C# 源码头注释写明是 **I9** 移植：
- `StrategyScalping.cs`：“I9 USER_SCALP handbook candidate”，没有 I13 的 H4 EMA/ADX 门、I15 C1 的自动手数、I18 的点差 20 Point 门。
- `Strategy456.cs`：S4 BE125、S5 I8、S6 I6。
- `Strategy123.cs`：S1/S2/S3 的 I9 版本。
建议把该字段改为带版本的状态，例如 `SIGNAL_PORTED_I9_PROFILES`，并逐策略列出与 I18 保留版的差异。否则会被误读为“现行版本已移植”。

### K7. 契约所在位置

契约 v1.0 在 `draft/risk-execution-interface` 分支，尚未进 main。等 K1 作用域定下来再合并：选方案 A 时，契约应放到新 EA 项目目录或注明作用域，而不是放在仓库根 `contracts/` 让人以为适用于 V1.2。

---

## 3. LEAN 方案

**同意维持双引擎，LEAN 不接管 MT5 下单。** 同意提案第 4 节的配对比较原则。补三点：

1. **试点不用重新选，继续 S4。** 提案写“选择一条有完整证据的策略做对照”。S4 已经做到：B4A/B4B1 在八月复现原生净利 102.03、56 笔、PF 1.464，分层比较在容差内一致。下一步应该是补 S4 剩下的缺口（管理和平仓延迟、隔夜费、第二个月份、保证金），而不是换一套重新开始。
2. **先把 C# 信号更新到 I18 保留版，再谈其他策略的跨引擎对照。** 见 K6。用 I9 信号去对照 I18 的 MT5，差异会混进版本差，对照没有意义。
3. **LEAN 的价值要设检查点。** 七套策略两端各写一遍，工作量翻倍。建议：S4 完成完整对照后做一次评估——LEAN 有没有产出过 MT5 原生测试做不到、而且后来被 MT5 验证有效的研究结论？如果没有，LEAN 降级为信号审计工具，不再要求七套全部做完整成交迁移。这是我的判断，需双方讨论。

---

## 4. KEEP / INDEX / ARCHIVE / DELETE

**DELETE：本阶段一项都不提。** 同意提案第 6 节的禁止删除。

| 动作 | 对象 | 理由 |
|---|---|---|
| KEEP | `contracts/risk_execution_interface.md` v1.0；V1.2 `PLAN_CN.md`、`CURRENT.json`、`EVIDENCE_INDEX.json`；全部 `research/evidence/`；`LEAN_MCP_20261012/` 全部；`gsm-sop/`；上游 snapshots 与 LICENSE；Scalping 手册哈希表 | 现行规则、原始证据或授权边界 |
| INDEX | V1.2 `README.md` 第 29–62 行的逐轮记录 | 内容有效但越来越长，最新状态被埋在中间。建议 README 只留“当前状态”一段，逐轮记录移到 `research/ITERATION_LOG_CN.md`，原文不改写 |
| INDEX | 分工表（AGENTS / PLAN §2 / COLLABORATION） | K1 决定后只在 AGENTS 保留一份，其余改为引用 |
| ARCHIVE（待确认，可逆） | `contracts/drafts/` 下 v0.1–v0.3 草案与审查 | v1.0 冻结后属于决议过程记录，建议 `git mv` 到 `contracts/history/`，保留提交历史 |
| ARCHIVE（待确认，可逆） | COLLABORATION “第七轮实际协作范围（2026-10-03）”一节 | 历史协作记录，不是现行规则；可移入 `docs/history/` 并留链接 |

---

## 5. 需要用户决定的事项

1. **K1 作用域**：新分工和契约只用于新 EA（方案 A），还是 V1.2 也改用（方案 B）。
2. **K2**：若选方案 B，是否同意把七个独立 EA 逐步迁入单一 RiskExecution，并接受迁移后需要重建对照基线。
3. **S1–S6 来源**：各自是 USER_OWNED、NON_USER 还是 UNKNOWN。

其余 K3–K7 和第 4 节的 INDEX 属于文档整理，按 AGENTS 已有授权可由 Codex 直接处理，不必等用户。

## 6. 需要 Codex 在本地补的事实

- 按 I18 选择文件的哈希，从本地 `MT5_Current_Research/<sid>` 核对七套 MQ5 的实际入口周期、magic 和来源注释，补正第 1 节的 UNKNOWN。
- 确认 Scalping EA 对旧 GSM 三引擎框架的依赖范围（共用的 MQH、magic 区间）。

---

## 7. 2026-10-18 追记：S1–S7 归属已由用户确认

依 `contracts/drafts/strategy_origin_S1_S7_user_confirmation_20261018.md`（提交 520e57d）：S1–S6 为 **NON_USER**（AI 根据用户方向研究组合），S7（Scalping）为 **USER_OWNED**。Claude 同意。第 1 节台账中 S1–S6 的“来源归属”栏、第 5 节第 3 项待决事项，按此更新；Claude 的 UNKNOWN 初查（`draft/strategy-provenance` 分支）已标为被取代。

用户同日还确认：**方案 B**（V1.2 采用新分工和 RiskExecution v1.0），以及**先迁一套、对照一致后再扩展**。K1、K2 由此定案，待 Codex 同步 AGENTS／PLAN／COLLABORATION。

对确认文件的三处文字建议（不影响归属结论）：
- S5 描述“布林带”过简，实际为 M15 区间 + M5 布林带触碰 + RSI 回升。
- S6 描述“M15/M5 入场”不完整，C# 移植另有 H4 回调路径（H4 收盘入场）。
- S4 称“伦敦／纽约动能 Scalping”，容易与 S7 Scalping 混淆，建议称“伦敦／纽约动能”。
- 编号说明：S7 = Scalping，与 C# 中 `Key = "S" + (StrategyId + 1)`（Scalping 的 StrategyId 为 6）一致；建议各文件统一写“S7（Scalping）”。S7 的 Lewis 教材出处与哈希已在 PLAN §4.1，正式归属表直接引用即可。
