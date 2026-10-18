# 方案 B 文档一致性核对与合并 main 意见 — Claude

核对对象：分支 `draft/risk-execution-interface` @ b420eba，对照 `origin/main` @ 6433758。
核对文件：根 `AGENTS.md`、`README.md`；V1.2 `README.md`、`docs/PLAN_CN.md`、`docs/COLLABORATION_CN.md`、`research/CURRENT.json`；`contracts/risk_execution_interface.md` v1.0。另外读了分支 `research/codex/ea-plan-20260906` 中用户的《GSM Gold 6-Strategy Parallel EA 开发执行说明 v1.1》（2026-09-07，提交 e634b2b）。
状态：只读核对。未修改上述文件，未合并。

## 结论：暂不合并 main

方案 B 的职责主体写对了：AGENTS 新增的“V1.2 方案 B：唯一现行分工规则”与契约 v1.0 §1 一致（Codex：Core、信号、指标、编译、唯一 Tester 队列；Claude：RiskExecution；Core 只发意图，全部交易调用经过 RiskExecution）。PLAN §2 和 COLLABORATION 也已改为引用 AGENTS，不再各写一张分工表。

但还有 3 处文档不一致，以及契约与用户已确认规格之间的 4 处冲突。都是小改动，改完再一次合并，避免把已知冲突带进 main。

---

## 一、文档不一致（合并前必须改）

**B1. AGENTS 误删了知识入口段落**
旧 AGENTS 第 39 行“知识大脑与长期研究记忆在本 GitHub 仓库…”整段被删，这段与分工无关。删除后，AGENTS 里已经没有 `gsm-mt5-indicators` 指标库链接，也没有“先读 README、indicator_manifest.json、保留两库提交和哈希”的规则。请恢复原段落（放回“读取顺序”之前）。

**B2. “每次开始前选择模式”的规则前后矛盾**
AGENTS 删除了模式选择规则，但以下位置仍要求先选“使用 Claude 或只用 Codex”，而且多数指向已删除的“第 2 节”：
- PLAN 第 9、50、58、145 行，第 362 行的接续指令模板；
- COLLABORATION 第 66–73 行（选项 2 改成“不用 Claude 须另行明确风险模块责任”，但 AGENTS 没有对应规定）；
- V1.2 README 第 3 行。

请二选一，并只在 AGENTS 写一次，其余引用：
- **保留模式选择**：AGENTS 写明“方案 B（双 AI）”与“只用 Codex”两种模式，以及只用 Codex 时 RiskExecution 由谁写、谁复审。
- **取消模式选择**：V1.2 固定为方案 B，删除上述各处的选择要求。

用户今天只说采用方案 B，没有说取消“只用 Codex”的选项，所以我建议**保留模式选择**；但这是用户的决定，Codex 合并前请确认。

**B3. 两份 README 仍是旧分工**
- 根 `README.md` 第 3 行：“代码由 Claude 负责，Codex 负责协调和测试验证”。
- V1.2 `README.md` 第 3 行：“使用 Claude 时…Claude 写改代码，Codex 编译／测试”。
两处改为一句话引用 AGENTS 方案 B。

---

## 二、契约 v1.0 与用户已确认规格的冲突（建议升 v1.1 后一起合并）

用户规格 v1.1 §0.2 写明：**Magic、策略名称、周期组合、并行与隔离要求属于用户已确认内容**。契约 v1.0 有四处与之不符或缺漏。第一套要迁的是 S4，而 S4 正好涉及 G3，所以这些必须在迁移编码前解决。

**G1. Magic 规则冲突**
- 契约 §4：`magic = magic_base + strategy_index`（连续编号）。
- 用户规格 §2：S1–S6 为 6101、6201、6301、6401、6501、6601（间隔 100）；S7（Scalping）现有证据为 26082152。
- 建议 v1.1：magic 改由 policy 中的显式表登记（strategy_id → magic），默认采用用户规格的值；保留唯一性、跨实例不重叠、启动冲突检查。现有 TB500 EA 实际用哪些 magic，需 Codex 在本地源码核对后填表；若与用户规格不同，如实记录，不擅自改。

**G2. 账户检查缺两项**
用户规格 §2.1 要求同时检查 `ACCOUNT_HEDGE_ALLOWED` 和 `ACCOUNT_FIFO_CLOSE`：强制 FIFO 时无法保证各策略独立平仓，必须拒绝新交易。契约 §4.1 只检查 `ACCOUNT_MARGIN_MODE`。建议 v1.1 补入这两项，加验收用例 RE-28。

**G3. 缺少每个策略的最大活动槽位**
用户规格 §2：默认槽位 S1–S6 为 1/1/1/2/1/1，S4 双槽；槽位计入已持仓、在途请求和挂单。契约只有“同策略同品种在途锁”，没有槽位上限，也没有 S4 第二槽需要新 Setup ID 的规则。建议 v1.1 在 policy 加 `max_active_slots_per_strategy`，由 `EvaluateEntry` 检查，超限返回 `REJECT_RISK`（reason=SLOT_FULL）；加验收用例 RE-29（S4 第三个信号被拒、第二槽需新 Setup ID）。

**G4. 缺少单实例租约**
用户规格 §2.1 第 6 点：同一账户、服务器、品种和 magic 集合只允许一个执行实例，用持久化租约防止重复挂图，旧版 EA 与候选不能用相同 magic 并行。契约只规定每个实例一个状态文件，没有防重复实例。建议 v1.1 补入租约机制，加验收用例 RE-30。

**G5（建议一并处理）. S7 每日 6 盈或 6 亏锁的模块归属**
这条规则需要完整交易净盈亏账本、去重和重启恢复，最适合放在 RiskExecution：`EvaluateEntry` 对 S7 返回 `REJECT_RISK`（reason=STRATEGY_DAILY_LOCK）。契约 v1.0 没有这项。S7 不是第一套迁移，可以晚点做；但既然要升 v1.1，一起写入可免再升一次版本。

以上都是新增字段、原因码和检查，不改变 v1.0 已有语义。按契约规定，须双方批准并升版本号。

---

## 三、不阻断合并的事项

1. **更正我之前的建议**：我曾建议 S4 名称去掉“Scalping”、S5／S6 描述补细节。用户规格里的正式名称就是“伦敦/纽约动能 Scalping”“布林带横盘反转”“D1/H4趋势＋M/W结构 Swing”。建议 PLAN §4.0 直接采用用户规格的原名，我撤回“去掉 Scalping”的建议。
2. **CURRENT.json**：`architecture.mode_selection_required_before_each_new_or_resumed_task`、`realtime_research_monitor.code_owner` 等仍反映旧分工；`next_research_priority` 停在 I17；`seven_signal_modules_implemented` 未注明是 I9 版本。B2 定案后一起更新。
3. **草案归档**：`contracts/drafts/` 合并进 main 后，建议移到 `contracts/history/`，保留提交历史。

## 四、需要用户决定

1. **B2**：V1.2 是否保留“只用 Codex”模式。
2. **用户规格中“用户已确认”的项目，在 NON_USER 下能否修改**：用户今天确认 S1–S6 为 NON_USER，可在授权研究内优化。但用户规格 v1.1 把策略名称、周期组合、Magic、并行与隔离列为用户已确认内容。建议区分：
   - 并行、隔离、对冲账户、不投票、不操作他策略订单、槽位上限，作为**用户的架构要求**继续保护；
   - 各策略的入场规则、指标参数、止损止盈，按 NON_USER 自主优化；
   - **周期组合**（例如 S1 的 H1/M15/M5）是否可改，请用户明确。

## 五、建议的合并顺序

1. Codex 修改 B1–B3。
2. Codex 起草契约 v1.1（G1–G5），Claude 核对后双方批准。
3. 一次合并到 main。
4. 之后再开始 S4 迁移编码。
