# Risk / Execution Interface v1.1 — 草案修订 R3（Claude 处理 Codex R2 复审 8ac6020，待 Codex 复审）

**状态：v1.1 DRAFT R3 / PROPOSED — 等待 Codex 复审实际 diff。不是正式接口，没有冻结，不授权交易实现、部署或合并。**

- R3 处理了 Codex 对 R2（fd5d27b）的复审 `contracts/drafts/planB_v1.1_R2_codex_review_20261021.md`（提交 8ac6020）中的三项必改和三项澄清，逐项对应见 `contracts/drafts/planB_v1.1_R3_claude_response_20261021.md`。

- **双方批准前，FROZEN v1.0（`contracts/risk_execution_interface.md`）仍是唯一有效接口。** 本草案只存在于研究分支；用户对具体 PR 明确批准之前，不替换 main 中的正式文件。
- **基线：** FROZEN v1.0（提交 8a48a8f；main `3718653`，SHA256 bfee24c7…）；v1.1 初稿（SHA256 0c050017…）。
- **整合的决议：**
  - Codex 修订提案 `contracts/drafts/planB_v1.1_resolution_codex_20261021.md`（提交 1237ed3）；
  - Claude 冻结前审查 a36d57d 及更正 c7a288d；
  - G1/G3/G4/G5 证据：Codex f78ccd4，Claude 独立复核 56bba07。
- **逐项接受、差异与替代文字：** `contracts/drafts/planB_v1.1_resolution_claude_review_20261021.md`。
- **原始依据：**
  - 用户《GSM Gold 6-Strategy Parallel EA 开发执行说明 v1.1》（2026-09-07，分支 `research/codex/ea-plan-20260906`，提交 e634b2b）§0.1、§0.2、§2、§2.1；
  - V1.2 `docs/PLAN_CN.md` §4.1。
- **未执行：** 没有编写 MQL5，没有编译，没有回测，没有 Demo 验证。

## v1.1 变更摘要（R2 更正：不止替换 magic 公式）

v1.1 相对 v1.0 是**迁移性变更**，不只是新增字段。以下语义被替换或新增；v1.0 的旧 CSV 或旧状态**不会自动成为**新的 A/B 状态。

| ID | 变更 | 类型 | 位置 | 新验收 |
|---|---|---|---|---|
| G1 | magic 改由 policy 显式表 `magic_map` 登记，取代 `magic_base + strategy_index`；规定 `magic_map_hash` 的规范串 | 替换 | §4、§6、§7 | RE-28a |
| G2 | 账户检查增加 `ACCOUNT_HEDGE_ALLOWED`、`ACCOUNT_FIFO_CLOSE` | 新增 | §4.1 | RE-28b、RE-28c |
| G3 | 每策略最大活动槽位 `max_active_slots`；`TradeIntent` 增加 `setup_id`；槽位按 Setup 状态迁移，不重复计数、不提前释放 | 新增 | §1、§3.1 | RE-29a–f |
| G4 | 执行权**由独占文件句柄决定**；心跳只用于诊断；三种所有权状态 | 新增 | §6.2 | RE-30a–l |
| G5 | S7 服务器日 6 盈或 6 亏锁由 RiskExecution 执行；按服务器历史重算，跨实例共用；归属只按已登记的 magic | 新增 | §3.2 | RE-31a–r |
| X3/X4 | 持久状态身份由 `magic_base` 改为稳定的 `state_scope_id`（**不含** magic、policy、hash）；运行实例 `holder_instance_id` 只用于诊断 | 替换 | §6 | RE-30i、RE-30j |
| X6 | Demo 及获授权部署时，状态与锁都放在 `FILE_COMMON/TradingBrainV1.2/<state_scope_id>/`；v1.0 写的是终端本地 `MQL5/Files/` | 替换（存储位置） | §6、§6.2 | RE-30a–e |
| X8 | 普通 Tester 完全不用 `FILE_COMMON`，只写本地 agent 目录，按 run_id 隔离 | 替换（明确化） | §6.1 | RE-27、RE-30g |
| schema | `schema_version` 由 1 升为 2；字段见 §6 | 替换 | §6 | RE-30j |
| R3-1 | 服务器身份变更的失败即关闭迁移规则：`scope_family_id` 与作用域元数据 | 新增 | §6 | RE-30m |
| R3-2 | 全七策略持久的 `consumed_setup_ids`，在首次发单前与审批、在途意图一起提交，跨重启和换日保留 | 新增 | §3.1、§5、§6 | RE-29g |
| R3-3 | 状态写入权限只属于当前句柄持有者；持久的 `ownership_state` 只作诊断，不能恢复执行权 | 新增 | §6.2 | RE-30n |
| R3-4 | 全文保护、撤单、退出的主语限定为当前执行所有者；无 SL 补设为独立分支；Tester 目录规则与 RE-27 统一 | 澄清 | §1、§5、§6.1、§8 | RE-05b、RE-27 |

## 0. 审查决议追踪与最终决议

本节是 v0.3 与 v1.0 的历史决议，**保留历史效力**；它不覆盖本次 v1.1 新增内容的“待审”状态。

D1、D2、D3、D4 **全部接受，无异议**。M1–M6、P1–P5 按 v0.3 决议保留，M6/P1/P3 的保守约束被 D1–D4 进一步明确。

| ID | 决议 | v0.3 处理 |
|---|---|---|
| M1 | 接受 | §2 唯一 OnTick 顺序、退出优先 |
| M2 | 接受 | §7 生产/注入构建证据隔离 |
| M3 | 接受 | §6 持久记录 schema 与恢复 |
| M4 | 接受 | §3 OrderCalcMargin / OrderCheck 与 RE-23 |
| M5 | 接受（v1.1 G1 修改） | §4 原 magic_base + strategy_index 公式已由显式 magic_map 取代 |
| M6 | **有条件接受** | §5 对账不能仅靠 magic+symbol+方向+时间认定同一请求；必须排除歧义 |
| P1 | **有条件接受** | §4 第一轮拟对冲；运行前核对实际账户模式，净额禁新仓 |
| P2 | 接受 | §7 只冻结字段语义，批次冻结具体数值 |
| P3 | 接受（实现需验证） | §6 A/B 双槽、SHA-256 校验与恢复；不依赖原子替换（v1.1 改为 `FILE_COMMON` 下的稳定作用域目录，见 §6） |
| P4 | 接受 | §5 默认 cancel_remainder |
| P5 | 接受 | §7 单脚本双构建、隔离证据与生产哈希核验 |

### 有条件接受的理由
- **M6**：magic+symbol+方向+发单时间可能对应多个订单/成交，单凭这些字段不能证明本审批已被服务器接受。应优先关联已记录的 request/order/deal/position 标识与成交链；若无法唯一匹配，则 RECONCILE_REQUIRED、保留在途锁、禁止重复发单，依 §5.1 的 D1 规则自动结案或保持锁定；**本段旧的人工等待表述已由 D1 取代，以 §5.1 为准**。订单 comment 只能辅助，不能作为唯一依据。
- **P1**：历史对冲证据仅用于选择试运行目标；启动时读取 ACCOUNT_MARGIN_MODE 并与冻结 policy 比对。不符时禁止新开仓并告警；RE-18 仍为净额上线前必测。
- **P3**：终端文件系统的临时文件覆盖/改名语义、异常中断后持久性需通过故障注入和重启测试验证。**此处早期备选方案已由 D3 取代：唯一持久化方案为 §6 的 A/B 双槽，不依赖 rename；实际持久性仍须故障测试验证。**

## 1. 所有权、接口及单位

Codex 拥有 EA Core、指标和信号、整合、编译与唯一 MT5 Tester 队列；Claude 拥有 RiskExecution（仓位/风险/订单/SL/恢复）及其验收用例。跨模块契约修改须双方确认；各文件仅单方写入，双方互审完整调用路径。所有交易执行（入场、减仓、退出、SL/TP 修改）只允许 RiskExecution 调用交易 API；Core 只能提交意图和转发交易事件。风控 MQL5 本地独立运行，不依赖 Python、AI 或监控服务。

**主语约定（R3-4）：** 本文件所有“保护、补设 SL、保本、追踪、撤单、退出、减仓、对账后恢复”等**会调用交易 API 或改写共享状态**的表述，主语一律是**当前执行所有者**，即持有独占句柄、状态为 `OWNER_HEALTHY` 或 `OWNER_DEGRADED` 的实例（§6.2）。观察者实例和 `OWNERSHIP_UNCERTAIN` 实例一律只读、只告警；即使它们检测到 S7 日锁、无 SL 持仓、待撤挂单或待处理退出，也不发任何交易请求，也不写共享状态。

字段距离及单位后缀：_price、_points、_pct、_seconds、_lots、_account_ccy；仅明确 USD 账户才用 _usd。读取品种 tick size、point、volume min/step/max、stops/freeze、合约及保证金规则。不可混用 point、pip 与价格单位。

核心契约（**语义草案，尚未经过 MQL5 编译**）：
- `TradeIntent`: candidate_id, strategy_id, setup_id, magic, symbol, direction, signal_bar_time, created_at, expires_at, expected_entry_price, initial_sl_price, tp_price, risk_budget_account_ccy, max_price_deviation_price, policy_hash, partial_fill_remainder_policy。
- `ApprovedTrade`: approval_id, intent_digest, approved_lots, expected_loss_account_ccy, portfolio_loss_account_ccy, margin_after_entry_pct, issued_at, expires_at, account/quote/positions_fingerprint。执行模块私有登记才是授权凭证，结构体不能自证。
- `ExitIntent`: exit_id, strategy_id, symbol, position_identifier/ticket, FULL/PARTIAL/EMERGENCY, requested_lots, reason, expires_at；不允许超额减仓反向开仓。
- `ExecutionResult`: status, server_retcode, order/deal/position identifiers, requested_lots, confirmed_lots, message, timestamp。
- `EvaluateEntry(intent, approved)`: 同一步计算可下手数及止损/组合/在途风险、交易成本和保证金，并检查执行所有权（§6.2）、策略槽位（§3.1）与策略日锁（§3.2）；不得向上凑最小手数。
- `SubmitEntry(approved)`: 内部核验批准、未使用、时效、状态指纹及所有权状态 `OWNER_HEALTHY`，先持久记录并加在途锁，再发送请求。
- `SubmitExit(intent)`: 幂等 exit_id，**仅排入执行模块退出队列**，实际操作由 ManagePositions 处理。
- `ManagePositions()`: 优先处理退出队列，再执行安全的持仓保护与待处理操作；SL 只能收紧。仅在所有权状态为 `OWNER_HEALTHY` 或 `OWNER_DEGRADED` 时调用交易 API（§6.2）。
- `ReconcileState()`: 按服务器订单、持仓、成交与持久文件对账，读不到不等于不存在。任何所有权状态下都可执行（只读）。
- `HandleTradeTransaction(trans,request,result)`: 事件幂等，核对服务器结果及部分成交，事件乱序不重复执行。

## 2. 事件调用顺序（M1）

OnInit：读取账户模式、品种参数，计算 `state_scope_id`，尝试取得独占执行句柄（§6.2），读取持久状态、服务器订单/持仓/历史；执行恢复对账。若部分初始化失败，不允许新入场；保护/告警仍尽可能工作（受 §6.2 所有权状态约束）。OnInit 不应以直接停止 EA 的方式无条件丢失保护能力。

OnTick 的**唯一顺序**：
1. `execution.ReconcileState()`（局部失败标记不确定，不得据此删除持仓）。
2. Core 更新新 K 线时钟和本根已评估状态；不受点差、新闻、时段等入场门控影响。
3. Core 基于已收盘 K 线及现有持仓生成 `ExitIntent`；逐个 `execution.SubmitExit()` **仅排队**。
4. `execution.ManagePositions()`：先处理退出队列，再处理初始 SL 补设、保本、追踪、保护重试；同一持仓已有有效退出意图时跳过本轮追踪修改。
5. **只针对新开仓**执行点差、交易时段、新闻、信号有效期/价格偏离及账户风险门控。
6. `BuildEntryIntent → EvaluateEntry → SubmitEntry`。

步骤 1–4 **不得被提前 return 跳过**。步骤 3 的策略退出即使数据不足，也应记录明确状态；不能被入场门控吞掉。步骤 2 更新时钟不意味着把尚未评估的入场信号标记为已评估；首次评估/门控拒绝时需持久记录本 bar 的处理结果，避免同 bar 延迟追单。步骤 4 是否可以调用交易 API 由 §6.2 的所有权状态决定；不可调用时仍要记录待处理动作并告警，而不是静默跳过。

OnTimer：ReconcileState + ManagePositions（含待处理退出/保护）+ 所有权与心跳诊断（§6.2）；无 Tick 不得假定报价新鲜。OnTradeTransaction：Core 无条件转发事件，执行模块对订单/成交/持仓标识幂等处理；服务器最终记录优先于本地推断。

## 3. 风险、保证金、成交后复核（M4）

`EvaluateEntry` 以实际账户净值、策略风险预算、初始 SL、OrderCalcProfit、预估成本、已持仓及在途风险确定合规手数；使用 OrderCalcMargin 估算新增保证金，并用 OrderCheck 及当前账户保证金状态复核。预计入场后保证金水平低于批次冻结 `min_margin_level_after_entry_pct` 或保证金不足，返回 `REJECT_RISK` + reason=MARGIN；不得阻断既有持仓保护。OrderCheck/OrderCalcMargin 是提交前估算，不保证服务器最终接受。
成交后按实际成交均价、成交量、佣金及预计平仓成本、有效 SL 重算单笔和组合风险；若超出 policy 的 `post_fill_risk_tolerance_pct`，按冻结政策减仓/阻止新仓/告警；阻止新仓不等于已减少现有敞口。

### 3.1 G3：每策略最大活动槽位

- 每批 policy 登记 `max_active_slots`（strategy_id → 整数）。取证后的默认值：**S1 1、S2 1、S3 1、S4 2、S5 1、S6 1、S7 1**。
  - S1–S6 取自 I18 保留源码 `g_slots={1,1,1,2,1,1}`；
  - S7 取自 I18 保留源码 `InpScalpMaxOpenPositions=1`、`InpTotalMaxOpenPositions=1`（证据 f78ccd4，复核 56bba07）。
  - 旧 S7 实现是“持仓上限＋挂单门控＋在途门控”三道检查，本节的 Setup 槽位语义是**新的**实现语义，须经 RE-29 验证，不能当作旧实现已经满足。
- **活动槽位以 Setup 计**：一个 `setup_id` 从 PENDING_SUBMIT 起占用 1 个槽位，直到该 Setup 的**全部**挂单、在途请求和持仓都到达终态并完成对账为止。其间挂单、在途请求、部分成交持仓、多个拆分持仓只是同一槽位内的状态迁移，**不重复计数，也不提前释放**。
- **部分成交后取消剩余挂单，但已有成交持仓仍在**：该 Setup 继续占用槽位，直到全部持仓平仓并对账完成（RE-29d）。
- `EvaluateEntry` 在审批前检查槽位；已满返回 `REJECT_RISK`，reason=`SLOT_FULL`，记录被拒的 setup_id。槽位已满不影响已有持仓的保护与退出。
- 每个槽位对应唯一 `setup_id`（至少包含策略、品种、方向、结构 ID、触发 K 线时间）。同一 setup_id 已占用槽位或已消费时，再次提交返回 `REJECT_RISK`，reason=`DUPLICATE_SETUP`。S4 第二槽必须是新的 setup_id。
- **持久 Setup 去重（R3-2，适用于全部七个策略）：**
  - 所有已消费的 setup_id 记录在持久状态的 `consumed_setup_ids`（§6）中。
  - 写入时机：在该 Setup **首次发单之前**，与 `consumed_approval_ids`、在途意图写入**同一次** A/B 提交，并回读校验通过；提交或校验失败则不发单。
  - 一经写入，跨重启、跨换日、跨 Setup 终态都保留。Setup 终态后从 `active_setups` 移除，但仍留在 `consumed_setup_ids`；重启后即使拿到新的审批，同一 setup_id 仍返回 `DUPLICATE_SETUP`（RE-29g）。
  - `consumed_approval_ids` 和 S7 的 `counted_setup_ids` **都不能替代**本表：前者只防同一审批重放，后者只服务 S7 当日计数。
  - **不裁剪。** 在另行规定并证明不会重放的安全保留政策之前，不删除任何条目。条目随 Setup 数增长，实现时须留意文件大小，但不能以空间为由删除。
  - 普通 Tester 每个 run_id 从空表开始（§6.1）。
- 在途锁（§5）键不变：同一策略同一品种同时最多一笔在途请求。S4 第一槽的请求结束在途状态后，第二个 Setup 才可提交；第一槽在途时第二槽返回 `REJECT_IN_FLIGHT`（RE-29e）。
- 任一策略的 `max_active_slots` 为 TBD 时，该策略不得新增风险，含该策略的批次不得运行（RE-29f）。

### 3.2 G5：S7 服务器日 6 盈或 6 亏锁

本条只作用于 S7（用户 Scalping），规则原文见 V1.2 `PLAN_CN.md` §4.1；本节只规定执行归属和接口语义，不改变规则内容。用户 SOP 核心保持：M5 → 最近有效供需区 → 回踩 → 反转 K 线收盘确认。
- **归属**：由 RiskExecution 维护完整交易账本并执行锁定；Core 不自行计数。
- **计数**：按 FxPro 服务器日期，每笔完整交易／Setup 全部结束并完成对账后，按净收益（含已确认佣金、swap 及相关费用；成交价中的点差不重复扣）分类：净盈利计 win、净亏损计 loss、净零另列不计。win 与 loss 分别累计、不互相抵销；跨日持仓按最终结束的服务器日期计数；分批平仓与多笔成交合并为一次。
- **锁定**：当日 win 达 `win_limit` 或 loss 达 `loss_limit`（默认均为 6）即锁定 S7 当天新增风险：`EvaluateEntry` 对 S7 返回 `REJECT_RISK`，reason=`STRATEGY_DAILY_LOCK`；同时由**当前执行所有者**撤销 S7 待入场挂单（**只撤 S7**，不撤 S1–S6 挂单）；观察者或 `OWNERSHIP_UNCERTAIN` 实例检测到锁定时只告警，不撤单。撤单失败时保持锁定、记录原始 retcode、告警并重试（RE-31m）。已有 S7 持仓的保护、保本、追踪、退出与对账继续；锁定后才平仓的 S7 持仓照常计入当日次数，锁定状态不变（RE-31o）。不影响 S1–S6 及其他策略。
- **换日**：服务器时间 00:00 清零当日 win/loss 并解除本锁；午夜无 Tick 时在下一次执行机会按服务器日期更新。服务器偏移和夏令时按历史时点核对，不固定换算成本地时间或 UTC（RE-31p）。账户紧急锁等其他限制不随换日解除。
- **计数来源与跨实例共用**：当日计数以服务器成交历史为准重算，不依赖单个实例的内存或状态文件，因此跨图表、跨实例共用同一计数（PLAN §4.1）。每次处理 S7 新增订单前，核对服务器日期、当日历史交易、在途请求和当日锁定。
- **S7 身份（X5）**：只按 policy `s7_identity_magics` 认定 S7 成交，当前取证值为 **`[26082152]`**；26082102（Intraday）、26082303（Swing）不属于 S7，只参加 §4 的冲突检查。**订单或成交 comment 不得作为归属依据，也不得兜底**；归属须由已登记 magic 及可追溯成交链（order → deal → position）确认。S1–S6、其他策略和手工单（magic 不在该集合内）一律不计入。
- **疑似旧 S7 成交**：若影响当日计数的历史中（当天结束的交易，或仍未平仓的持仓）存在疑似 S7 来源但 magic 未登记的成交，返回 `REJECT_RISK`，reason=`DAILY_LEDGER_UNRESOLVED`，暂停 S7 新增风险，等待归属核对；不悄悄忽略，也不靠 comment 计入。不影响当日计数的更早历史不阻断。没有证据不新增别的 S7 magic。
- **持久化与去重**：本地状态（§6）只保存服务器历史无法提供的内容（费用确认状态、已计入的 setup_id、锁定时间）；重启后与服务器历史重算结果一致；重复或乱序的交易事件不得重复计数；重启或重挂 EA 不能清空当日计数。第一轮**不支持热迁移 S7 magic**；未来如需迁移，按 §6 迁移规则另行登记旧／新身份、服务器历史归属与完整恢复证据。
- **费用未确认或历史不完整**：某笔交易的费用或归属未确认、账户级佣金无法归属到具体持仓，或当日服务器历史查询失败、覆盖范围不足以确定当日计数时，暂停 S7 新增风险（reason=`DAILY_LEDGER_UNRESOLVED`）；不得把查询失败当作零笔交易（RE-31g、RE-31k、RE-31q）。对账完成、历史完整后再计数并解除。本规则在**所有运行模式**下执行（Tester、Demo 及获授权部署）。
- **多实例竞争**：S7 新增订单只能由所有权状态为 `OWNER_HEALTHY` 的唯一执行实例发出（§6.2）；同一实例内，S7 计数检查与 §5 在途锁在同一次 `EvaluateEntry` 中完成：已有在途 S7 请求时直接 `REJECT_IN_FLIGHT`，在途请求结束并计入账本前，不发出下一笔 S7 订单，避免第 6 笔结束前多开一笔。
- **连续盈亏暂停**：旧 I18 源码中的连续暂停函数 `UpdateScalpPause` 没有调用点，本接口**不把它作为默认启用**。基线只执行本节的每日累计 6 盈／6 亏锁。若日后另批明确启用额外连续暂停，须单独登记、单独记录原因码，不改变本节的累计锁（RE-31r）；未经用户授权也不删除该规则的研究选项。
- policy 字段：`strategy_daily_count_lock`：`{strategy_id: "S7", win_limit: 6, loss_limit: 6, day_boundary: "SERVER_00_00"}`；`s7_identity_magics`：`[26082152]`（按数值排序、去重后纳入冻结 policy 及 policy_hash）。

## 4. 账户模式与 magic（M5、P1）

**（v1.1 G1，取代 v1.0 的 `magic_base + strategy_index` 公式）** 每批 policy 以显式表 `magic_map`（strategy_id → magic）登记各策略 magic。取证后的值如下（I18 保留源码；证据 f78ccd4，复核 56bba07）：

| 策略 | magic | 源码出处（I18 `MT5_Current_Research`） |
|---|---|---|
| S1 | 6101 | `g_magics` 全局初始化数组 |
| S2 | 6201 | 同上 |
| S3 | 6301 | 同上 |
| S4 | 6401 | 同上 |
| S5 | 6501 | 同上 |
| S6 | 6601 | 同上 |
| S7 | 26082152 | `InpScalpMagic`，OnInit 强制等于此值 |

- 订单备注只作辅助，**不作归属依据**。
- 已知不属于本表、但必须参加冲突检查的 magic：26082102（Intraday）、26082303（Swing）。
- 启动检查：magic 唯一、互不重复，且与同账户其他 EA 实例的已知 magic 不重叠；冲突时禁止新开仓并告警。不能靠 comment 识别归属。全账户、跨机器的活动 EA 冲突**未经验证**，不能凭本表宣称无冲突。
- **`magic_map_hash` 规范串（X4）**：
  - 固定头 `TB_MAGIC_MAP_V1` 加 LF；
  - 然后按 S1、S2 … S7 的顺序逐行写 `S1=6101` 这样的行，每行（含最后一行）以 LF 结尾；
  - 值为正整数十进制，不带正号、空白或前导零；
  - 必须恰好七个 ID，magic 互不重复；禁用的策略也保留映射；
  - 编码为 UTF-8，无 BOM、无 NUL；对完整字节串取 SHA-256，用小写 hex 表示；
  - 输入 JSON 的键顺序不影响结果；缺项、多项、重复键都拒绝。
  - 本规定只针对 magic_map；完整 policy 的规范序列化另行规定（见 §9 待确定）。
- 第一轮试运行目标：**对冲账户（拟定，启动时验证）**。对冲账户以 magic + POSITION_IDENTIFIER 和 ticket/历史链追踪；ticket 变化不能丢失归属。
- 第一轮若实际为净额模式或与 policy 不一致：禁止新入场、告警；继续管理可确认属于本 EA 的仓位，不得误动其他策略仓位。
- 净额模式未来版本：同品种多策略共享真实仓位不支持；REJECT_NETTING_CONFLICT。RE-18 移至净额上线前阻断验收，第一轮不假装已通过。

### 4.1 D2：非对冲账户及测试器账户模式

- **（v1.1 G2）** 启动及每次新开仓前同时检查：`ACCOUNT_MARGIN_MODE == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING`、`ACCOUNT_HEDGE_ALLOWED == true`、`ACCOUNT_FIFO_CLOSE == false`。任一不满足即视为无法保证各策略独立持仓与独立平仓：禁止新开仓并告警（提示需使用支持双向持仓且不强制 FIFO 的对冲账户），不自动平掉原仓、不切换为净额模拟；仍保护可确认为本 EA 的真实持仓。三项实际读值写入日志和回测报告。
- 第一轮只允许 `ACCOUNT_MARGIN_MODE_RETAIL_HEDGING` 与冻结 policy 对冲模式一致时新开仓。`ACCOUNT_MARGIN_MODE_RETAIL_NETTING` 和 `ACCOUNT_MARGIN_MODE_EXCHANGE` **都属于非对冲**，禁止第一轮新入场并告警；仍保护可确认为本 EA 的真实持仓。
- 回测报告必须记录 Strategy Tester 实际读取的 `ACCOUNT_MARGIN_MODE` 及 policy.account_mode；二者不一致时标记 INVALID，不能作为成绩证据。测试器模式不代表真实经纪账户模式，Demo/实盘另行核验。

## 5. 在途锁、重试、保护、部分成交（M6、P4）

入场只使用已收盘 bar 信号；`max_entry_delay_seconds` 和 `max_price_deviation_price` 由批次 policy 冻结；每个 strategy_id+symbol+signal_bar_time 一次评估或仅按明确重试策略处理，不得在门控结束后追入。
- 在途锁键：`state_scope_id` + strategy_id + symbol；状态 PENDING_SUBMIT → SENT → PARTIAL/FILLED/REJECTED/EXPIRED。PARTIAL 可能仍有剩余订单。锁超时必须先对账；无法确认服务器状态时继续阻挡。
- 提交前先持久记录 approval_id、intent_digest、setup_id、magic、symbol、direction、request_time、request_id（若可得）及状态，并把 approval_id 写入 `consumed_approval_ids`、setup_id 写入 `consumed_setup_ids`；这些在**同一次** A/B 提交中完成并回读校验通过后，才调用服务器（R3-2）。若崩溃发生于记录与发单之间，恢复时以不确定状态对账，不能自动再次发单；该 setup_id 已被消费，不能借新审批再次提交。
- 重试优先使用 request/order/deal/position ID 和成交链精确匹配；若 ID 缺失，按 D1 的服务器时间候选匹配规则处理（详见 §5.1）。comment 仅辅助，不能单独判定。
- 部分成交时立即保护已成交手数并复算风险；**默认 cancel_remainder**，不追补。策略可请求 keep_remainder，但必须获 policy 白名单许可；未确认撤单前仍保持在途锁。剩余挂单取消后，槽位按 §3.1 继续占用到全部持仓终态。
- **SL 修改分两个互斥分支（R3-4）：**
  - **服务器已确认 SL 不存在（`POSITION_SL == 0`）**：作为独立的“补设”分支处理，**不进入**下面的单调比较。数值 0 不是“更宽”或“更紧”的 SL，不能用于比较；尤其 SELL 的“新 SL ≤ 0”这种推论没有意义。补设值取持久的初始 SL 意图，并单独校验：
    - 价格大于 0；
    - 方向正确（BUY 的 SL 低于当前 Bid，SELL 的 SL 高于当前 Ask）；
    - 满足 tick size、SYMBOL_TRADE_STOPS_LEVEL、SYMBOL_TRADE_FREEZE_LEVEL。
    
    不能安全确定补设值时，按 `emergency_unprotected_position_policy` 处理（RE-05、RE-05b）。
  - **服务器已确认 SL 存在**：初始/保本/追踪保护只收紧（BUY 新 SL ≥ 已确认 SL，SELL 新 SL ≤ 已确认 SL），以 Bid/Ask、tick size、`minimum_sl_step_price`、SYMBOL_TRADE_STOPS_LEVEL / SYMBOL_TRADE_FREEZE_LEVEL 校验；拒绝或冻结时保留旧 SL 与待处理记录。
  - 两个分支都只由当前执行所有者执行；服务器确认前不更新“已生效 SL”。
- 净成本保本：求满足 `OrderCalcProfit(方向,品种,实际成交量,实际均价,SL价) + 已发生带符号佣金 + 预计剩余佣金 + 已发生 swap + 预计其他费用 - 滑点缓冲 >= 0` 的 tick-size 离散 SL 价格；不可重复扣已在成交价中的点差。价格按 SL 成交只是估算，不保证实际净利非负。
- 已成交仓位没有 SL：由当前执行所有者按上面的“补设”分支、依持久初始 SL 意图尝试补设；无法安全确定时按 `emergency_unprotected_position_policy` 告警/退出，不能默认为安全。观察者和 `OWNERSHIP_UNCERTAIN` 实例只发最高优先级告警（RE-30l）。

### 5.1 D1：在途对账的唯一匹配与自动结案

- 优先使用已持久化的 request/order/deal/position 标识及历史关联链。若无可用 ID，则用本 EA 专属 magic、同 symbol、同方向、**服务器时间 >= request_time_server - clock_tolerance_seconds** 的挂单、持仓及成交缩小候选。时钟容差属于每批冻结 policy；本地时间不可混作服务器时间。以 order_ticket 聚合：同一订单的多笔部分成交视为**一个候选**。
- **唯一 1 个候选**：关联该订单/成交，转 OK_PENDING，按服务器最终状态推进，保留必要的在途保护。
- **0 个候选 + 挂单/持仓/历史查询全部成功 + 超过 inflight_timeout_seconds**：判定该请求未获可见服务器接受，标记 EXPIRED、释放在途锁，**审批仍为已使用，不自动重发**；只有新信号和新审批才能再入场。
- **0 个候选但查询失败、历史范围不足或仍未超时**：保持锁，RECONCILE_REQUIRED（未超时可保持 OK_PENDING），下次 Tick/Timer 再核对。
- **2 个以上候选**：保持锁，RECONCILE_REQUIRED，禁止该策略新入场并告警；不猜测归属、不重复发单。
- 即使候选存在歧义，所有可确认为本 EA magic 的真实持仓仍须计入组合风险、尝试补设 SL 和持续保护（受 §6.2 所有权状态约束）。订单归属审批不确定**只阻止新开仓**，不阻断真实敞口保护。
- 零候选结案的前提是查询范围完整、账户连接与历史覆盖足以支持结论；无法证明则不能释放锁。

## 6. 持久记录与恢复（M3、P3、D3、D4；v1.1 X3/X4/X6）

**稳定状态身份 `state_scope_id`（X3）**：
- 由固定项目标识 `TradingBrainV1.2`、交易服务器原始字符串、账户登录号、实际 symbol 稳定派生。**不得**包含启动随机数、源码版本、policy_hash、magic_map_hash 或 magic。否则换配置或换映射就能绕开旧在途、已用审批和 S7 日锁。
- **规范串**：依次为 project、server、login、symbol 四项，每项写成“ASCII 字段名 + `:` + UTF-8 字节长度（十进制，无前导零）+ `:` + 原始 UTF-8 值 + LF”。
  - 整体编码为 UTF-8，无 BOM，结尾不写 NUL；
  - 字符串不 trim、不改大小写、不做 Unicode 规范化；
  - 登录号用无符号十进制，无前导零；
  - 对完整字节串取 SHA-256，用小写 hex 表示，即为 `state_scope_id`。
- 账户原文只存本地受控记录；公共审计只用指纹。文件名只用固定前缀和 hex。

**运行实例 `holder_instance_id`**：每次加载生成新值，只用于诊断“谁持有执行权”；它**不赋予执行权，也不决定状态路径**。生成方法由 Claude 实现并留证；不得单独把 ChartID 当作全局唯一身份。

**存储位置（X6、X8）**：
- Demo 及以后获授权的部署：状态 A/B、锁文件、心跳诊断都放在 `FILE_COMMON/TradingBrainV1.2/<state_scope_id>/`，三者是不同的文件。接管者读取同一份 A/B 状态。这是相对 v1.0“终端本地 `MQL5/Files/`”的**显式迁移变更**。
- 普通 Tester：见 §6.1，完全不用 `FILE_COMMON`。

使用带 `schema_version` 的可校验结构化记录（可采用 JSON，MQL5 序列化需实现验证）；每个 `state_scope_id` 固定 **A/B 双槽**，不依赖 rename。

必备字段（schema_version 2）：
```json
{
  "schema_version": 2,
  "state_scope_id": "TBD",
  "holder_instance_id": "TBD",
  "magic_map_hash": "TBD",
  "policy_hash": "TBD",
  "account_login_fingerprint": "TBD",
  "symbol": "TBD",
  "sequence": 0,
  "updated_at_server": "TBD",
  "updated_at_utc": "TBD",
  "ownership_state": "OWNER_HEALTHY",
  "strategy_daily_count": [{"strategy_id": "S7", "server_date": "TBD", "wins": 0, "losses": 0, "zero": 0, "counted_setup_ids": [], "locked": false, "unresolved_reason": ""}],
  "active_setups": [{"strategy_id": "TBD", "setup_id": "TBD", "slot_state": "PENDING_SUBMIT", "order_tickets": [], "position_identifiers": []}],
  "inflight": [{
    "strategy_id": "TBD",
    "setup_id": "TBD",
    "approval_id": "TBD",
    "intent_digest": "TBD",
    "status": "PENDING_SUBMIT",
    "request_time": "TBD",
    "request_id": "TBD",
    "order_ticket": "TBD",
    "deal_tickets": []
  }],
  "consumed_approval_ids": [],
  "consumed_setup_ids": [{"strategy_id": "TBD", "setup_id": "TBD", "consumed_at_server": "TBD", "approval_id": "TBD"}],
  "pending_protection_actions": [],
  "pending_exit_intents": [],
  "positions": [{
    "position_identifier": "TBD",
    "position_ticket": "TBD",
    "magic": 0,
    "setup_id": "TBD",
    "initial_sl_price": "TBD",
    "desired_sl_price": "TBD",
    "confirmed_sl_price": "TBD"
  }],
  "checksum": "TBD"
}
```
- 所有数值占位仅是 schema 示例，**不能当运行 policy**。
- 租约心跳**不在**本文件内，单独存放在心跳诊断文件中（§6.2），避免心跳写入与状态写入互相干扰。
- `ownership_state` 字段**只作诊断记录**（最后一次写入时的状态），**不能**在启动时恢复执行权（§6.2 写入权限）。
- `consumed_setup_ids` 见 §3.1：全七策略，首次发单前提交，不裁剪。

**作用域元数据与服务器身份变更（R3-1，失败即关闭）：**
- 每个 `state_scope_id` 目录另存一个只读的作用域元数据文件 `scope_meta`（与 A/B 状态分开，带 SHA-256 校验），内容为：
  - `state_scope_id`；
  - `scope_family_id`：用 §6 同样的规范串格式，只取 project、login、symbol 三项（**不含 server**）计算的 SHA-256；
  - 服务器名称的指纹；
  - 创建时间。
  
  `scope_meta` 由首次取得该作用域独占句柄的所有者写入一次，之后不改写。
- **启动时的判定**（本项目 `FILE_COMMON/TradingBrainV1.2/` 下）：
  1. 若当前 `state_scope_id` 的目录已有有效状态，正常走 §6.2 流程。
  2. 若当前目录不存在或没有任何状态，先枚举所有其他作用域目录的 `scope_meta`，寻找 `scope_family_id` 相同、`state_scope_id` 不同的候选，即同项目、同登录号、同 symbol，但服务器名称不同：
     - **枚举完整成功，且零个候选**：视为新的作用域，可以开始；
     - **一个或多个候选**：进入 `STATE_MIGRATION_PENDING`，禁止新风险并告警。不自动合并，不自动转移执行权，不把旧目录的状态复制过来。不同券商的账户可能登录号相同，所以**候选再多也不能凭 `scope_family_id` 相同就认定是同一账户**；
     - **任何 `scope_meta` 损坏、不可读，或枚举失败**：不能证明这是全新账户，同样进入 `STATE_MIGRATION_PENDING`。
- **解除迁移待定**：必须有一份显式的迁移记录，写明旧 `state_scope_id` → 新 `state_scope_id` 的映射、依据（例如券商更名的证据）和操作者，然后与新服务器的成交历史完整对账。旧作用域中的 `consumed_setup_ids`、`consumed_approval_ids`、在途请求、初始 SL 意图和 S7 当日计数，**全部**按迁移记录带入新作用域后，才能放行新风险。
  - 服务器改名**不能**静默重置 S7 日锁、已用审批或已消费的 Setup（RE-30m）。
  - 迁移记录由谁提供、以什么格式登记，属于部署规程，第一个 Demo 之前确定；在此之前遇到候选一律保持 `STATE_MIGRATION_PENDING`。
- 普通 Tester 不做此枚举（§6.1，状态在本地 run_id 目录中，每次从空开始）。

**唯一写法：A/B 双槽交替写入。**
- 例如 state_A 与 state_B；写入非当前最新有效槽，写完 flush/close 后重新读取校验。
- 每槽包含单调递增 sequence 和 SHA-256 checksum（使用 MQL5 支持的 CryptEncode/CRYPT_HASH_SHA256，具体编码经编译验证）；哈希计算覆盖规范化 payload，排除 checksum 字段自身。
- 启动时分别读取两槽，选择校验通过且 sequence 最大的记录；一槽损坏则使用另一槽。
- 两槽都无效：RECONCILE_REQUIRED，禁止新入场；依据服务器记录和可信保护记录处理可确认的持仓，不猜测初始 SL；**不放弃独占执行身份**（§6.2）。
- 不得声称文件系统已保证掉电原子性，RE-25 验证中断恢复。

**迁移规则（X3、X7）**：
- 读到的状态 `magic_map_hash`、`policy_hash` 或 `schema_version` 与当前不符：进入 `STATE_MIGRATION_PENDING`，禁止新风险；**不得创建新目录或新状态当作空账户**。可确认的持仓仍按恢复保护规则处理。
- v1.0 的旧状态和旧 CSV 不会自动转换为 schema 2。
- 第一轮不支持热迁移 magic。未来迁移须另行登记：旧／新映射、服务器历史归属、已用审批、未结 Setup 和费用、完整恢复证据；不能借换 magic 清空日锁或漏计旧风险。

服务器订单、持仓及成交记录是交易事实的最终依据；本地保存审批已用、初始 SL 意图及待处理任务等服务器无法完整提供的事实。冲突记录审计；不能把服务器记录缺失/查询失败当作不存在。
文件损坏、缺失、账户指纹不符、schema 不兼容或对账不确定：RECONCILE_REQUIRED，禁止新仓，继续能安全执行的保护并告警；解锁需要可证明的完整对账。对已用审批/在途锁的恢复不得仅靠“没有找到订单”而盲目重新发单。

### 6.1 D4：回测状态隔离（v1.1 X8 明确化）

- **普通 Tester 完全不用 `FILE_COMMON`。** G4 证据显示，测试器内的 `FILE_COMMON` 指向真实共享的 Common 目录，所以隔离必须由实现控制。
  - 普通成绩回测的状态、锁、心跳、去重记录全部写在本地 agent 的 `MQL5/Files/TradingBrainV1.2/test/<run_id>/<state_scope_id>/`；
  - 统一经过一个目录适配器选择路径，不允许个别模块直接拼路径。
- `MQLInfoInteger(MQL_TESTER)` 为真时，**普通回测 OnInit 必须从空状态启动**，不得加载任何先前回测遗留审批、在途锁或持仓保护状态。
- run_id 由单一回测执行器登记并保证唯一：
  - 缺失 run_id 时拒绝运行；
  - **目录规则（R3-4，与 RE-27 一致）**：`test/<run_id>/` 目录**可以预先存在但必须是空的**（例如由 runner 预先创建）。只要其中含有任何文件（状态 A/B、锁、心跳、去重记录、诊断日志或完成标记），EA 都拒绝运行，不静默清空、不覆盖；
  - 优化运行每个 pass 须有唯一子 ID，该机制实现前不运行优化批。
- **唯一例外**：RE-05、RE-06、RE-25 等明确标注的重启恢复验收，显式指定 fixture 文件及恢复模式；build_type、恢复模式、fixture hash 全部留证，不得计入策略成绩。
- 即使 policy_hash 和账户指纹与上一轮相同也必须隔离。RE-27 验证连续两次回测不串状态；RE-30g 验证 Tester 不触碰 `FILE_COMMON`。旧 G4 探针**不能**冒用为新执行层的隔离验收。

### 6.2 G4：执行所有权（X6、X7、X9）

用户规格 §2.1 第 6 点：同一账户、服务器、品种和 magic 集合只允许一个负责执行的 EA 实例。本项目采用更保守的范围：**同一 `state_scope_id`（同账户、同服务器、同 symbol）只运行一个本项目执行器**，由它负责全部七个策略。这不能保证与任意其他 EA 互斥。

**执行权的唯一依据：独占文件句柄。**
- 锁文件路径：`FILE_COMMON/TradingBrainV1.2/<state_scope_id>/execution.lock`（Tester 见 §6.1）。锁按 `state_scope_id` 粗粒度取得，**不含 magic_map_hash**；两份部分重叠但 hash 不同的映射也不能各自取得执行权（RE-30i）。
- 取得方式：`FileOpen` 读写二进制，**不带** FILE_SHARE_READ / FILE_SHARE_WRITE。持有期间不关闭句柄，不删除或重建锁文件，不为刷新心跳临时释放句柄。锁文件与 A/B 状态、心跳诊断是不同的文件。
- 没拿到句柄：观察模式，**不调用任何交易 API**，只做只读对账、诊断和告警。

**写入权限（R3-3）：**
- 只有当前持有独占句柄的实例（`OWNER_HEALTHY` 或 `OWNER_DEGRADED`）可以写以下**共享**内容：
  - 状态 A/B；
  - 持有者心跳诊断文件；
  - `scope_meta`（只在首次创建时写）；
  - `consumed_approval_ids`、`consumed_setup_ids`；
  - 在途记录、`pending_protection_actions`、`pending_exit_intents` 等执行队列。
- 观察者和 `OWNERSHIP_UNCERTAIN` 实例**一律不写**上述任何共享文件；它们的诊断日志写在各自独立的文件中（例如 `diag/<holder_instance_id>.log`），不与持有者共用文件，也不影响持有者的任何状态（RE-30n）。
- **每次加载时执行权都视为未证明。** 持久状态中的 `ownership_state`（即使是 `OWNER_HEALTHY`）只是上一次写入时的诊断记录，**不能**恢复执行权。
  - 新加载的实例必须先重新取得独占句柄，并完成身份核对、A/B 读取和服务器对账，才能成为 `OWNER_DEGRADED` 或 `OWNER_HEALTHY`。
  - 在此之前，它和观察者一样只读，不写共享状态，也不调用交易 API。
- 不同机器之间无法共享此锁；部署范围明确**不支持**多台机器以同一账户、同一 symbol 并行运行。启动时若出现非本实例产生的、属于本项目 magic 的新成交，作为告警线索。

**心跳只用于诊断（X7）。**
- 持有者在 OnTimer 中写心跳诊断文件，内容包括 `holder_instance_id`、单调递增 seq、服务器时间和本机 UTC 时间；不依赖新 Tick。
- 本次运行内的间隔只用 `GetTickCount64` 的差值计算；系统重启前后的读数不能相减。观察者用**自己的**单调计时记录“最近一次观察到 seq 变化”到现在的间隔，不用另一个启动周期的计数作差。
- 文件修改时间、`TimeLocal` 跳变、服务器 `TimeCurrent` 停滞，**都不授予执行权**。
- 心跳过期只触发告警和一次取得独占句柄的尝试；**不能强抢、删除锁文件、覆盖持有者，也不能凭超时自封为持有者**（RE-30b）。持有者进程挂死但句柄仍被占用时，可能无法自动恢复；此时明确告警，不制造双执行器。

**三种所有权状态（X9，修订后的定稿语义）。**

| 状态 | 条件 | 新增风险 | 已有仓位的保护与退出 | 对账 |
|---|---|---|---|---|
| `OWNER_HEALTHY` | 持有独占句柄；持久化与对账正常 | 按冻结 policy 允许 | 正常执行 | 正常 |
| `OWNER_DEGRADED` | 仍持有独占句柄，但心跳或状态写入／回读校验失败 | **立即禁止**（reason=`OWNER_DEGRADED`） | **继续**能确认的保护和退出；失败记录原始 retcode 并告警 | 继续 |
| `OWNERSHIP_UNCERTAIN` | 句柄失效、被关闭，或无法确认仍然独占 | 禁止（reason=`OWNERSHIP_UNCERTAIN`） | **不调用交易 API**；服务器已接受的 SL/TP 继续由服务器执行；待处理动作只记在本实例的诊断日志中，**不写**共享执行队列 | 只读对账；每次 OnTimer/OnTick 尝试重新取得独占句柄 |

- `OWNERSHIP_UNCERTAIN` 期间，不能因为“没有发现另一个持有者”就继续改单，因为那不是排他所有权的证明。
- 若此期间发现本项目持仓**没有服务器端 SL**，只发出最高优先级告警，不发单（RE-30l）。
- 软件无法保证在失去所有权、网络中断或平台故障时继续计算追踪止损；这一限制必须写入部署说明，不能声称保护“不间断”。
- 重新取得句柄后的顺序：
  1. 核对 `state_scope_id` 等身份；
  2. 读取 A/B 状态；
  3. 与服务器对账，在途旧请求按 §5.1 处理，不假设失去句柄时请求已撤回；
  4. 恢复可确认仓位的保护；
  5. 状态写入并回读校验通过，且所有门控通过后，才回到 `OWNER_HEALTHY` 并放行新风险。
- A/B 两槽都坏时不放弃独占身份，但禁止新风险；依据服务器记录和可信保护记录处理已有仓位，不猜测初始 SL（RE-30d）。
- 持有者退出或崩溃会释放句柄；重启后可以重新取得，但必须先核对旧审批、初始 SL 和在途请求，不能按新实例清零（RE-30e）。
- 独占打开在双图表、固定终端崩溃恢复下的实际行为，由 Claude 实现后的 RE-30 验证；G4 平台文件读写证据**不证明**本原语已经成立。

## 7. 构建、试验政策与队列（M2、P2、P5）

- **生产构建**用于所有成绩回测、成本压力、样本外和 Demo；**故障注入构建**只用于 F 验收。生产构建不能含可触发注入代码路径。测试结果不得作为策略收益成绩。
- Codex 负责同一编译脚本参数化生产/注入构建；两者来自同一 commit，注入差异只在 `#ifdef TEST_FAULT_INJECTION` 保护范围内。保存源码 commit、编译参数、编译日志、两个 EX5 SHA256、注入差异检查记录、报告所用 build_type 与 EX5 hash。生产部署前核对 EX5 哈希及无注入路径；未实现前状态 NOT VERIFIED。
- 每批 `policy.json` 冻结字段及数值：account_mode、magic_map（G1）、s7_identity_magics（G5）、max_active_slots（G3）、strategy_daily_count_lock（G5）、heartbeat_interval_seconds、heartbeat_stale_alert_seconds（G4，**只用于诊断告警，不授予执行权**）、initial_capital_account_ccy、symbol、data_range、tick_model、execution_delay、costs、score_anchors、experiment_budget、max_entry_delay_seconds、max_price_deviation_price、approval_ttl_seconds、inflight_timeout_seconds、max_retry_count、post_fill_risk_tolerance_pct、partial_fill_remainder_policy、minimum_sl_step_price、min_margin_level_after_entry_pct、clock_tolerance_seconds、emergency_unprotected_position_policy、以及部分成交、异常退出和恢复所需策略。
  - **run_id 不属于 policy.json，不参与 policy_hash**；由单一回测执行器写入队列任务，并作为 EA 输入参数传入，每份报告记录 run_id。
  - **接口冻结字段/单位/语义，不替批次选择数值**。必要字段为 TBD 时不得启动该批；评分锚点未冻结则总分 N/A，不能事后修改。
- Claude 只创建不可变 `research/queue/pending/<run_id>.json`；Codex 单执行器独占更新 running/completed/failed，持久 run_id 去重、本机锁、异常恢复。Git 文件不是锁；仅一个 MT5 Tester，不额外创建数据目录绕开占用。失败试验也计入总预算。

## 8. 统一状态及验收

v1.1 新增 `REJECT_RISK` 的 reason：`SLOT_FULL`、`DUPLICATE_SETUP`、`STRATEGY_DAILY_LOCK`、`DAILY_LEDGER_UNRESOLVED`、`OWNER_DEGRADED`、`OWNERSHIP_UNCERTAIN`、`STATE_MIGRATION_PENDING`（状态码本身不增加）。

状态码：OK_CONFIRMED、OK_PENDING、REJECT_RISK、REJECT_VOLUME、REJECT_IN_FLIGHT、REJECT_NETTING_CONFLICT、REJECT_APPROVAL、REJECT_MARKET、REJECT_STOPS_LEVEL、RETRYABLE、FAIL_SERVER、DATA_UNAVAILABLE、PROTECTION_PENDING、RECONCILE_REQUIRED。
- OK_PENDING 只表示请求已发/待确认；OK_CONFIRMED 需服务器订单/成交/修改确认。
- RETRYABLE 先精确对账，无法唯一确认则 RECONCILE_REQUIRED；不得重复下单。
- 保护/退出失败记录原始 retcode 并保留待处理；休市等待开市；冻结区不发无效请求；不得放宽服务器已生效 SL。
- 对账数据部分不可用，仍保护可确认持仓（受 §6.2 约束），不允许新入场。
- **矩阵主语（R3-4）：** 下表凡是“保护继续”“撤销挂单”“补设 SL”“退出”等预期，执行者都是当前执行所有者（§1 主语约定）；观察者和 `OWNERSHIP_UNCERTAIN` 实例在同样场景下只读、只告警。

**完整验收矩阵：** 所有可执行用例尚未运行，RE-18 推迟至净额模式上线前。T=策略测试器；F=测试器/可控故障注入；D=Demo；构建审计=静态/编译审计。真实服务器拒单不能仅凭注入测试证明。RE-29～RE-31 属于 RiskExecution **实现阶段**的验收，不是 v1.1 冻结的前提。

| ID | 场景 | 通过条件 | 方式 | 状态 |
|---|---|---|---|---|
| RE-01 | 点差门控 + 已持仓追踪 | 仍更新追踪 SL | T | NOT RUN |
| RE-02 | 新闻门控 + 已持仓保本 | 仍执行保本 | T | NOT RUN |
| RE-03 | 试图放宽 SL | 拒绝，旧 SL 不变 | T | NOT RUN |
| RE-04 | 0.30 手部分成交 0.10 | 保护已成交量、剩余按 policy、重算风险 | F | NOT RUN |
| RE-05 | 重启发现无 SL 持仓 | 补设或按紧急政策处理并告警 | T/D | NOT RUN |
| RE-05b | BUY 与 SELL 持仓各一笔，均无服务器 SL（`POSITION_SL == 0`） | 走独立补设分支，不用单调比较；补设价 > 0、方向正确、满足 stops/freeze；SELL 不因“新 SL ≤ 0”被误判为收紧；无法安全确定时按紧急政策 | F | NOT RUN |
| RE-06 | 重启遗留在途锁但无服务器订单/持仓 | 核对后解除并记录 | F | NOT RUN |
| RE-07 | 修改 SL 被拒 | 旧 SL 不变、保留待处理 | F | NOT RUN |
| RE-08 | SL 修改遇冻结区 | 不提交、保留旧 SL | T | NOT RUN |
| RE-09 | 审批已过期 | REJECT_APPROVAL | T | NOT RUN |
| RE-10 | 同审批重复提交 | REJECT_APPROVAL | T | NOT RUN |
| RE-11 | 审批后行情/点差大变 | 拒绝旧审批 | F | NOT RUN |
| RE-12 | 在途再次触发信号 | REJECT_IN_FLIGHT | T | NOT RUN |
| RE-13 | 滑点致风险超容差 | 执行登记的超额风险政策 | F | NOT RUN |
| RE-14 | 净成本保本 | 成本不重复计点差，目标净 P/L >=0（假设按 SL 价成交） | T | NOT RUN |
| RE-15 | 合规手数低于最小手 | REJECT_VOLUME，不向上凑 | T | NOT RUN |
| RE-16 | 已有持仓再入场 | 组合风险计入已有及在途风险 | T | NOT RUN |
| RE-17 | 减仓量超过实际持仓 | 不反向开仓 | T | NOT RUN |
| RE-18 | 净额账户第二策略同品种入场 | REJECT_NETTING_CONFLICT | D | DEFERRED / NETTING RELEASE GATE |
| RE-19 | 休市时紧急退出 | 待处理，开市重试 | T | NOT RUN |
| RE-20 | 跳空穿过 SL | 记录实际与预计损失差 | T | NOT RUN |
| RE-21 | 对账部分读取失败 | 可安全保护的持仓仍执行 | F | NOT RUN |
| RE-22 | 无 Tick | Timer 仍尝试对账和保护 | T | NOT RUN |
| RE-23 | 保证金不足/预计入场后 margin level 低于冻结阈值 | REJECT_RISK(reason=MARGIN)，已有持仓保护继续 | T | NOT RUN |
| RE-24a | 在途请求出现两个候选订单 | 保持锁、RECONCILE_REQUIRED、不重复发单；已成交仓位继续保护 | F | NOT RUN |
| RE-24b | 零候选、完整历史查询成功且超时 | EXPIRED、释放锁、旧审批已用且不重发 | F | NOT RUN |
| RE-24c | 零候选但查询失败 | 保持锁、RECONCILE_REQUIRED | F | NOT RUN |
| RE-25 | A/B 双槽写入中断、损坏或两槽无效 | 选择最新有效槽；均无效时禁新仓但保护真实持仓 | F | NOT RUN |
| RE-26 | 生产与注入双构建 | 同 commit，哈希/差异可追溯，成绩仅生产 EX5 | 构建审计 | NOT RUN |
| RE-27 | 连续两次普通回测；另测 run_id 目录预先存在且为空，以及目录中已有任一文件 | 第二次完全不读取第一次状态，run_id 隔离；空目录可以运行；目录中有任何文件（状态、锁、心跳、去重、诊断、完成标记）时拒绝运行，不清空、不覆盖 | T | NOT RUN |
| RE-28a | magic_map 有重复值，或与同账户另一实例的已知 magic 重叠；规范串缺项、多项或重复键 | 禁止新开仓并告警；已有持仓保护继续；规范串错误时拒绝启动新风险 | T | NOT RUN |
| RE-28b | `ACCOUNT_HEDGE_ALLOWED` 为 false | 禁止新开仓并告警，不自动平仓 | F | NOT RUN |
| RE-28c | `ACCOUNT_FIFO_CLOSE` 为 true | 禁止新开仓并告警，不自动平仓 | F | NOT RUN |
| RE-29a | S4 两槽已满时出现第三个合格 Setup | REJECT_RISK(SLOT_FULL)，两槽保护继续 | T | NOT RUN |
| RE-29b | 同一 setup_id 第二次提交 | REJECT_RISK(DUPLICATE_SETUP) | T | NOT RUN |
| RE-29c | 某 Setup 只有挂单、尚未成交 | 挂单占用该 Setup 的槽位 | T | NOT RUN |
| RE-29d | 部分成交后取消剩余挂单，已成交部分仍持仓 | 继续占用同一 Setup 槽位；全部持仓平仓并对账后才释放；不双计 | F | NOT RUN |
| RE-29e | S4 第一槽请求在途时出现第二个合格 Setup | REJECT_IN_FLIGHT；第一槽在途结束后可申请第二槽 | T | NOT RUN |
| RE-29f | 某策略 `max_active_slots` 为 TBD | 该策略不得新增风险；含该策略的批次拒绝启动 | T | NOT RUN |
| RE-29g | S1–S6 任一策略的某 Setup 已终态（已从 `active_setups` 移除）；重启并换日后，以新审批再次提交同一 setup_id | REJECT_RISK(DUPLICATE_SETUP)；`consumed_setup_ids` 在首次发单前已提交并回读校验；提交失败时不发单 | F | NOT RUN |
| RE-30a | 同一电脑第二个实例以相同 `state_scope_id` 启动 | 第二实例取不到独占句柄，观察模式，不执行任何交易动作，只告警 | F/D | NOT RUN |
| RE-30b | 持有者心跳超时，但句柄仍被占用 | 不能强抢；只有成功取得独占句柄后才进入接管对账 | F | NOT RUN |
| RE-30c | 两个实例同时启动 | 最多一个取得独占句柄 | F/D | NOT RUN |
| RE-30d | 状态两槽都损坏 | 所有者禁新风险，保持可确认的保护；不是无条件停止全部管理 | F | NOT RUN |
| RE-30e | 持有者退出或崩溃释放句柄后重启 | 能重新取得句柄；先核对旧审批、初始 SL 及在途请求，不按新实例清零 | F | NOT RUN |
| RE-30f | 周末或休市，无 Tick | 心跳由 OnTimer 维持，不误报超时，不改变执行权 | T/F | NOT RUN |
| RE-30g | 普通 Tester 不同 run_id 连续运行 | 状态互不干扰；全程不触碰 `FILE_COMMON` | T | NOT RUN |
| RE-30h | 心跳或状态写入失败但仍持有句柄 | `OWNER_DEGRADED`：继续保护、禁新增；真实失去独占时转 `OWNERSHIP_UNCERTAIN`，不交易，直到重新取得句柄并对账 | F | NOT RUN |
| RE-30i | 不同 `magic_map_hash`、同账户／服务器／symbol 的本项目实例 | 最多一个持有者；不能靠换映射绕开锁 | F | NOT RUN |
| RE-30j | 换 policy、magic 或 schema 后发现旧状态 | `STATE_MIGRATION_PENDING`：不静默以空状态启动；迁移核对完成前禁新风险 | F | NOT RUN |
| RE-30k | 无 Tick、系统时钟跳变、系统重启 | 心跳时钟异常不能授予执行权 | F | NOT RUN |
| RE-30l | `OWNERSHIP_UNCERTAIN` 期间发现本项目持仓没有服务器端 SL | 只发最高优先级告警，不调用交易 API；重新取得句柄并对账后才补设 SL | F | NOT RUN |
| RE-30m | 同一登录号与 symbol，服务器名称改变（含：一个候选、多个候选、`scope_meta` 损坏或枚举失败） | 都进入 `STATE_MIGRATION_PENDING`，禁新风险；不自动合并、不转移执行权；S7 日锁、已用审批、已消费 Setup 不被重置；只有显式迁移记录加完整对账后才放行 | F | NOT RUN |
| RE-30n | 观察者实例或 `OWNERSHIP_UNCERTAIN` 实例运行一段时间（含它检测到日锁、无 SL 持仓、待处理退出） | A/B 状态、心跳诊断、`scope_meta`、`consumed_*`、执行队列的字节内容均未被它改变；它只写自己的诊断日志；它重启后不因持久的 `ownership_state` 而获得执行权 | F | NOT RUN |
| RE-31a | S7 当日 3 盈 3 亏 | 不锁定 | T | NOT RUN |
| RE-31b | S7 当日第 6 笔净盈利（或第 6 笔净亏损） | 锁定 S7 新增风险并撤销 S7 待入场挂单；S7 持仓保护继续；S1–S6 不受影响 | T | NOT RUN |
| RE-31c | 净零交易、手续费使毛盈变净亏 | 净零不计；按净收益分类 | T | NOT RUN |
| RE-31d | 分批平仓／多笔成交 | 全部结束后只计一次 | F | NOT RUN |
| RE-31e | 跨日持仓、午夜无 Tick | 按最终结束的服务器日计数；下一执行机会按新日期换日 | T | NOT RUN |
| RE-31f | 锁定后重启、重复或乱序交易事件 | 恢复相同计数与锁定；不重复计数 | F | NOT RUN |
| RE-31g | 某笔费用未确认 | REJECT_RISK(DAILY_LEDGER_UNRESOLVED)，对账后再计数 | F | NOT RUN |
| RE-31h | S1–S6 及手工单的盈亏 | 不计入 S7 计数 | T | NOT RUN |
| RE-31i | 非连续序列（例：W L W L W L W L W W） | 按累计计数，第 6 笔 win 时锁定；不要求连续 | T | NOT RUN |
| RE-31j | 两个图表／实例、重挂 EA 后 | 读到同一当日计数与锁定状态，不被清空 | F/D | NOT RUN |
| RE-31k | 当日历史查询失败或覆盖不足 | REJECT_RISK(DAILY_LEDGER_UNRESOLVED)，不当作零笔 | F | NOT RUN |
| RE-31l | 两个实例在同一时刻尝试新增 S7 订单 | 只有 `OWNER_HEALTHY` 的持有者能发单；另一实例不执行交易动作 | F/D | NOT RUN |
| RE-31m | 锁定后撤销 S7 挂单失败 | 保持锁定，记录原始 retcode，告警并重试 | F | NOT RUN |
| RE-31n | 锁定时 S1–S6 也有挂单 | 只撤 S7 挂单；S1–S6 挂单不受影响 | T | NOT RUN |
| RE-31o | 锁定时仍有 S7 持仓，之后平仓 | 平仓照常计入当日次数，锁定不变，不发新单 | T | NOT RUN |
| RE-31p | 服务器偏移或夏令时变化当天 | 按服务器 00:00 换日，不按本地时间或 UTC | T | NOT RUN |
| RE-31q | 账户级佣金无法归属到具体持仓；或当日有疑似 S7 但 magic 未登记的成交；或成交带 S7 风格 comment 但 magic 不符 | REJECT_RISK(DAILY_LEDGER_UNRESOLVED)；comment 不计入也不兜底 | F | NOT RUN |
| RE-31r | 基线运行 | 只执行累计 6 盈／6 亏锁；旧连续暂停未启用；若另批启用，单独记录原因码，不改变累计锁 | T | NOT RUN |

注：RE-24a/b/c 是 RE-24 的三个子用例。v1.1 新增 RE-28～RE-31 共 4 个编号，展开为 **42** 条子用例：RE-28 3 条、RE-29 7 条、RE-30 14 条、RE-31 18 条。此外新增 RE-05b，并扩充了 RE-27 的预期。全部 NOT RUN；RE-18 仍为 DEFERRED。
第一轮对冲模式目标下 RE-18 标记 **DEFERRED / NETTING RELEASE GATE**，不是 PASSED。其他用例由双方按可模拟能力决定 T/F/D 及必要的补充集成测试，不得把模拟结果说成真实服务器验证。

## 9. 交接、冻结与未解决问题

交接必须附 candidate_id、run_id、branch、完整 commit SHA、变更模块、源码/参数/EX5 hash、编译日志、原始报告、执行环境、已跑/未跑测试和未解决问题。交叉审查完整调用路径，不只看 diff。

**冻结流程（X1，取代 v1.1 初稿 §9 的旧写法）：**
1. Codex 与 Claude 审查本草案的具体提交；
2. 另开**独立研究分支 PR**，描述逐项写明 AGENTS「main 合并门禁」规定的八项，并附双方真实复核记录的链接；
3. 用户对**该具体 PR** 明确批准前，不用本文件替换 main 的 `contracts/risk_execution_interface.md`，不转 Ready，不合并；
4. 研究分支中的拟升级内容一律标 PROPOSED，不声称已经 FROZEN；
5. 冻结只代表接口规格定稿，**不代表**实现已验证，也不授权部署或实盘。

v1.0 原文保留在 git 历史（提交 8a48a8f）及 main 当前正式文件中。

**待确定：**
- 第一轮实际账户模式及批次 policy 数值；
- 完整 policy 的规范序列化（policy_hash；第一个成绩批次前必须确定）；
- `holder_instance_id` 的生成方法（实现时留证）；
- MQL5 A/B 双槽和 SHA-256 实现验证；
- 独占句柄原语在双图表与崩溃恢复下的实际行为（RE-30）；
- 双构建差异验证脚本；
- 无法自动消除的订单歧义的人工恢复流程；
- 测试器无法模拟的服务器行为的 Demo 计划；
- 服务器身份迁移记录的提供者与登记格式（规则已在 §6 规定；格式须在第一个 Demo 之前确定）；
- 作用域目录枚举所依赖的 `FileFindFirst`/`FileFindNext` 在 `FILE_COMMON` 下的实际行为（实现时验证；枚举不能完整成功时一律按 `STATE_MIGRATION_PENDING` 处理）；
- `consumed_setup_ids` 的安全保留／裁剪政策（在另行规定并证明不会重放之前，一律不裁剪）。
