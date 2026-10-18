# 交易头脑 V1.2 S1–S6 来源归属核查 — Claude 初查

日期：2026-10-18。状态：**DRAFT / 待 Codex 本地核对与双方复核**。本文件不是正式归属表；正式表在双方复核后另行更新。
本次只读核查，没有修改任何策略、源码、计划或 CURRENT.json，没有编译或回测。

## 0. 用户本次决定（供 Codex 更新 AGENTS／PLAN／COLLABORATION）

用户于 2026-10-18 确认：
1. **方案 B**：交易头脑 V1.2 改用 2026-10-18 商定的新分工（Codex 写 EA 主框架、信号、指标接入并负责编译回测；Claude 写风控与订单执行模块），并适用冻结的 `contracts/risk_execution_interface.md` v1.0。
2. **先迁一套**：七个独立 EA 迁入单一 RiskExecution 时，先迁一套，与该策略原独立 EA 版本同条件对照一致后再扩展。
3. **S1–S6 在归属确认前，不得擅自替换核心规则。**

分工规则最终只在根 `AGENTS.md` 保留一份；PLAN §2 表格、COLLABORATION “共用规则和分工”表格及第 101 行任务文字改为引用 AGENTS。

## 1. 结论摘要

**六套策略依 GitHub 可得证据全部维持 UNKNOWN。** 没有任何一套能凭现有证据定为 USER_OWNED 或 NON_USER。

原因很明确：
- GitHub 上关于 S1–S6 最早的记录是 2026-09-20（QuantConnect 学习入口）和 2026-09-27（LEAN 500 计划）。当时 S1–S6 已经存在，名称为“六策略 v1.2”。
- 最早有成绩记录的是 **I6（2026-10-02）**，而且 I6 已经是在“原版”基础上修改，I1–I5 和原始版本不在 GitHub。
- 七套 MQL5 源码、原始策略说明、`v1-2-ea-mt5` 工作区（2026-09-10 建立）都只在用户本地。
- main 全部历史只有 102 个提交，恢复基线 `d88448e`（2026-09-27）中没有任何 V1.2 文件。

所以决定归属的关键证据都在本地，需要 Codex 按第 4 节核对，必要时向用户确认。

## 2. 已查证据范围

| 来源 | 查到什么 | 对归属的意义 |
|---|---|---|
| main 全部 102 个提交（`git log` 至 6433758） | V1.2 首次出现于 de4e4de（2026-09-20）；无更早 S1–S6 定义 | 无法确认起源 |
| `docs/history/LEAN_500_PLAN_20260927.md`、`LEAN_500_INTAKE_20260927.json` | S1/S4 已有 C# 移植（C7Signals）及“旧 30,000 USD 成绩”；工作区证据路径 | 证明 S1/S4 早于 2026-09-20 已存在，不证明谁设计 |
| `QUANTCONNECT_LEARNING_CN.md` 第 19、21 行 | 用户文件《交易头脑_指标搭配流程_CODEX.md》《交易头脑_指标搭配与分组测试_Codex执行说明.md》（2026-09-13）；称“六策略 v1.2” | 用户提出指标搭配流程；**提出需求不等于原创策略** |
| `research/evidence/MT5_ITERATION6`–`18` | 各策略候选演变和保留决定 | 用于第 3 节修改记录 |
| `tools/mcp_monitor/LEAN_MIGRATION_MAP.json` | 各策略保留版 MQ5 的本地路径；早期 LEAN 工作只是信号层 | 当前源码位置 |
| `LEAN_MCP_20261012/B4B1_20261014/source/*.cs` | I9 信号移植；`S4Core_baseline.cs` 注释提到 MQ5 以 `InpManagedEngine` 选引擎 | 技术谱系线索 |
| I10/I11 RESULTS 中 Scalping 输入 | `InpIntradayMagic`、`InpScalpMagic`、`InpSwingMagic` | Scalping EA 沿用旧 GSM 三引擎框架；S1–S6 是否同源未知 |
| `gsm-sop/README.md`、`FINAL_CHAMPION_ITERATION_SYSTEM_CN.md` §2.2 | GSM 三 SOP 来自 Gold Secret Mastery 课程等教材；USER_OWNED／NON_USER／UNKNOWN 定义 | 课程主题与部分 S 策略相近，但通用技术不能证明来源 |

## 3. 逐套记录

“GitHub 首次记录”指 GitHub 上最早出现该策略的位置，不是策略真正的首次引入版本。

### S1
- **当前保留**：TB500_S1_TRIGGER_M5_SL_R2，风险 1%。
- **规则摘要（依 C# I9 移植）**：H1 趋势 → M15 回调确认 → 已收盘 M5 触发；I6 起初始止损改为 M5 触发 K 线极值加 ATR 缓冲；Stoch 恢复检查。
- **GitHub 首次记录**：2026-09-20 C7Signals S1 信号层（本地 `quantconnect_20260920`）；成绩首见 I6。
- **修改记录**：I6 新增结构止损版（现保留版即此版，非 I6 前原版）、STOCH_EXTREME_EXIT；I9 动态风险、2% 风险；I10 主动恢复；I18 新候选未胜出。
- **源码位置（本地）**：`outputs/TradingBrain_I11_Seven_Strategies_20261004/MT5/S1/TB500_S1_TRIGGER_M5_SL_R2/TB500_S1_TRIGGER_M5_SL_R2.mq5`；I18 包 `MT5_Current_Research/S1`，源码 SHA-256 `05d1efc9…f85eb67`。
- **来源证据**：无。EMA、Stoch、多周期回调属通用技术。
- **暂定**：UNKNOWN。

### S2
- **当前保留**：TB500_S2_PROGRESS_RISK2_BE1_I11，风险 2%。
- **规则摘要**：H1/H4 新鲜供需区首次触碰 + EMA 背景；I9 起改为下一根 M5 推进确认；I11 加 1R 保本。
- **GitHub 首次记录**：I6（TB500_S2_SND_SAME_CLOSE）。
- **修改记录**：I6 试 M5 首次访问确认（淘汰）；I9 下一根 M5 推进；I10 风险 2%、1R 保本；I11 合并为现保留版。**入场确认方式已从原版改变。**
- **源码位置（本地）**：`outputs/TradingBrain_I11_Seven_Strategies_20261004/MT5/S2/TB500_S2_PROGRESS_RISK2_BE1_I11/…mq5`；SHA-256 `734d447e…6bd672`。
- **来源证据**：无。供需区与 GSM 课程主题相近，但“首次触碰 + EMA + 推进确认”的具体组合来源未见记录。
- **暂定**：UNKNOWN。

### S3
- **当前保留**：TB500_S3_H1_SLOPE_PRICE，风险 1%。
- **规则摘要**：冻结的突破回测（`FROZEN_BREAK_RETEST`），H1 斜率与价格条件。
- **GitHub 首次记录**：I6（I6 表中标“保留新研究版”）。
- **修改记录**：I6 后未见新保留版；I18 候选未胜出。
- **源码位置（本地）**：`…/MT5/S3/TB500_S3_H1_SLOPE_PRICE/…mq5`；SHA-256 `0f290156…728f54`。
- **来源证据**：无。突破回测属通用技术，与 GSM 支撑阻力教材主题相近。
- **暂定**：UNKNOWN。

### S4
- **当前保留**：TB500_S4_BE125，风险 2%，双槽。
- **规则摘要**：伦敦／纽约时段强势 K 线 + VFI 动量；1.25R 保本、1.5R 目标。
- **GitHub 首次记录**：2026-09-20 C7Signals S4 信号层；LEAN 500 计划提到旧 30,000 USD 成绩。
- **修改记录**：I6 起保留 BE1.25 版；I18 BE1.0R 候选未保留；LEAN B4A/B4B1 八月复现原生净利。
- **源码位置（本地）**：`…/MT5/S4/TB500_S4_BE125/TB500_S4_BE125.mq5`；SHA-256 `f6abe1ab…63be47`。
- **来源证据**：无。VFI 来自用户指标库（指标本身属第三方作者，指标来源不决定策略来源）。
- **暂定**：UNKNOWN。

### S5
- **当前保留**：TB500_S5_REQUEST_FINALITY_V1，风险 1%。
- **规则摘要**：M15 区间 + M5 布林带触碰 + RSI 回升，ADX 读取；I8 只修请求终态（执行层），交易逻辑未改。
- **GitHub 首次记录**：I6（M5_FIRST_PROGRESS、TRIGGER_INVALIDATION）。
- **修改记录**：I6 新进展退出版；I8 请求终态修复；I18 第二根 M5 推进候选未胜出。
- **源码位置（本地）**：`…/MT5/S5/TB500_S5_REQUEST_FINALITY_V1/…mq5`；SHA-256 `631ef2c3…c2d99a1`。
- **来源证据**：无。布林／RSI 属通用技术。
- **暂定**：UNKNOWN。

### S6
- **当前保留**：TB500_S6_DISTINCT_TRIGGER_BE1，风险 1%。
- **规则摘要**：H4 回调（H4 收盘入场）与趋势 M/W 形态（M5 触发）；目标空间需 ≥ 2R；1R 保本。
- **GitHub 首次记录**：I6（“保留新独立触发版”）。
- **修改记录**：I6 独立触发版；I18 ATR 追踪候选未胜出。
- **源码位置（本地）**：`…/MT5/S6/TB500_S6_DISTINCT_TRIGGER_BE1/…mq5`；SHA-256 `956d2fec…4bdf`。
- **来源证据**：无。M/W 形态与 GSM 图表形态教材主题相近，但通用形态不能证明来源。
- **暂定**：UNKNOWN。

## 4. 发现的风险

1. **现保留版已经不是原版。** S1（结构止损）、S2（入场确认方式）、S3／S5／S6（I6 “新研究版／新进展退出版／新独立触发版”）都在归属未登记期间改过核心或接近核心的规则。若日后某套确认为 USER_OWNED，必须对照原版，列出已改动的规则，由用户决定是否保留这些修改。
2. **技术谱系可能来自旧 GSM EA 代码库。** Scalping EA 带三引擎 magic，S4 C# 注释提到 `InpManagedEngine`。共用代码框架不等于策略同源，但需要查明 S1–S6 的规则是否沿用 GSM 课程 SOP（若是，按课程教材登记为外部来源，类似 Scalping 的 Lewis 教材另行登记）。
3. **用户 2026-09-13 的两份指标搭配说明** 是目前唯一指向用户参与设计的线索。需要读原文，区分“用户规定的具体规则”与“用户提出的研究流程”。

## 5. 需要 Codex 在本地核对

逐套按 I18 选择文件的哈希打开源码，并查：
1. 源码头注释、作者、版本说明、首次创建日期；`v1-2-ea-mt5` 工作区里最早的 S1–S6 版本（I6 之前的“原版”）及其设计文档。
2. `RESEARCH_STATE.md`、`EXPERIMENT_INDEX.jsonl`、`NEXT_ACTIONS.md` 中各策略首次登记的记录：由谁提出、依据什么资料。
3. 用户文件《交易头脑_指标搭配流程_CODEX.md》《交易头脑_指标搭配与分组测试_Codex执行说明.md》原文：哪些是用户给出的具体规则。
4. LEAN 500 计划所说“旧 30,000 USD 成绩”属于哪个项目、哪个版本。
5. S1–S6 是否引用 GSM SOP 文件或课程规则；是否与 `gsm-sop/` 内容逐条对应。

## 6. 需要用户确认

请用户逐套回答（可以只回答知道的）：
- 这套策略是您自己设计的、来自课程或书本、来自网络或别人的 EA，还是您只提出需求、由 AI 设计的？
- 如果来自课程，是哪份资料（例如 GSM 课程某一章）？

判定规则（依 FINAL_CHAMPION §2.2 与用户 2026-10-18 指示）：
- 用户确认是自己的具体规则 → USER_OWNED。
- 有证据来自课程、外部 EA 或由 AI 按一般需求设计 → NON_USER（课程或外部来源另行登记出处与许可）。
- 证据不足 → 维持 UNKNOWN；可以继续资料、实现和日志审查，但不替换核心规则。

在正式归属表更新前，S1–S6 一律按 UNKNOWN 处理。
