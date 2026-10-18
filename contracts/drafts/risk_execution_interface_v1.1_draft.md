# Risk / Execution Interface v1.1 — 草案（Claude 起草，待 Codex 核对）

**状态：v1.1 DRAFT / PENDING CODEX REVIEW。** 由 Claude 依《方案 B 文档核对》（`contracts/drafts/planB_docs_merge_check_claude_20261018.md`）G1–G5 起草，基线为 FROZEN v1.0（`contracts/risk_execution_interface.md`，提交 8a48a8f）。依据：用户《GSM Gold 6-Strategy Parallel EA 开发执行说明 v1.1》（2026-09-07，分支 `research/codex/ea-plan-20260906`，提交 e634b2b）§0.1、§0.2、§2、§2.1；V1.2 `docs/PLAN_CN.md` §4.1。**双方批准前，v1.0 仍是唯一有效接口。** 未编写 MQL5、未编译、未回测或 Demo 验证。

## v1.1 变更摘要

相对 v1.0 只新增字段、原因码与检查；v1.0 已有条款的语义不变，唯一替换是 §4 的 magic 公式（G1）。

| ID | 变更 | 位置 | 新验收 |
|---|---|---|---|
| G1 | magic 改由 policy 显式表 `magic_map` 登记，取代 `magic_base + strategy_index`；默认值取自用户规格 §2 | §4、§6、§7 | RE-28a |
| G2 | 账户检查增加 `ACCOUNT_HEDGE_ALLOWED`、`ACCOUNT_FIFO_CLOSE` | §4.1 | RE-28b、RE-28c |
| G3 | 每策略最大活动槽位 `max_active_slots`；`TradeIntent` 增加 `setup_id` | §1、§3.1 | RE-29a、RE-29b |
| G4 | 单执行实例租约 | §6.2 | RE-30a、RE-30b |
| G5 | S7（Scalping）服务器日 6 盈或 6 亏锁由 RiskExecution 执行 | §3.2 | RE-31a–RE-31h |


## 0. 审查决议追踪与最终决议

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
| P3 | 接受（实现需验证） | §6 MQL5/Files A/B 双槽、SHA-256 校验与恢复；不依赖原子替换 |
| P4 | 接受 | §5 默认 cancel_remainder |
| P5 | 接受 | §7 单脚本双构建、隔离证据与生产哈希核验 |

### 有条件接受的理由
- **M6**：magic+symbol+方向+发单时间可能对应多个订单/成交，单凭这些字段不能证明本审批已被服务器接受。应优先关联已记录的 request/order/deal/position 标识与成交链；若无法唯一匹配，则 RECONCILE_REQUIRED、保留在途锁、禁止重复发单，依 §5.1 的 D1 规则自动结案或保持锁定；**本段旧的人工等待表述已由 D1 取代，以 §5.1 为准**。订单 comment 只能辅助，不能作为唯一依据。
- **P1**：历史对冲证据仅用于选择试运行目标；启动时读取 ACCOUNT_MARGIN_MODE 并与冻结 policy 比对。不符时禁止新开仓并告警；RE-18 仍为净额上线前必测。
- **P3**：终端文件系统的临时文件覆盖/改名语义、异常中断后持久性需通过故障注入和重启测试验证。**此处早期备选方案已由 D3 取代：唯一持久化方案为 §6 的 A/B 双槽，不依赖 rename；实际持久性仍须故障测试验证。**

## 1. 所有权、接口及单位

Codex 拥有 EA Core、指标和信号、整合、编译与唯一 MT5 Tester 队列；Claude 拥有 RiskExecution（仓位/风险/订单/SL/恢复）及其验收用例。跨模块契约修改须双方确认；各文件仅单方写入，双方互审完整调用路径。所有交易执行（入场、减仓、退出、SL/TP 修改）只允许 RiskExecution 调用交易 API；Core 只能提交意图和转发交易事件。风控 MQL5 本地独立运行，不依赖 Python、AI 或监控服务。

字段距离及单位后缀：_price、_points、_pct、_seconds、_lots、_account_ccy；仅明确 USD 账户才用 _usd。读取品种 tick size、point、volume min/step/max、stops/freeze、合约及保证金规则。不可混用 point、pip 与价格单位。

核心契约（**语义草案，尚未经过 MQL5 编译**）：
- `TradeIntent`: candidate_id, strategy_id, setup_id, magic, symbol, direction, signal_bar_time, created_at, expires_at, expected_entry_price, initial_sl_price, tp_price, risk_budget_account_ccy, max_price_deviation_price, policy_hash, partial_fill_remainder_policy。
- `ApprovedTrade`: approval_id, intent_digest, approved_lots, expected_loss_account_ccy, portfolio_loss_account_ccy, margin_after_entry_pct, issued_at, expires_at, account/quote/positions_fingerprint。执行模块私有登记才是授权凭证，结构体不能自证。
- `ExitIntent`: exit_id, strategy_id, symbol, position_identifier/ticket, FULL/PARTIAL/EMERGENCY, requested_lots, reason, expires_at；不允许超额减仓反向开仓。
- `ExecutionResult`: status, server_retcode, order/deal/position identifiers, requested_lots, confirmed_lots, message, timestamp。
- `EvaluateEntry(intent, approved)`: 同一步计算可下手数及止损/组合/在途风险、交易成本和保证金，并检查策略槽位（§3.1）与策略日锁（§3.2）；不得向上凑最小手数。
- `SubmitEntry(approved)`: 内部核验批准、未使用、时效、状态指纹，先持久记录并加在途锁，再发送请求。
- `SubmitExit(intent)`: 幂等 exit_id，**仅排入执行模块退出队列**，实际操作由 ManagePositions 处理。
- `ManagePositions()`: 优先处理退出队列，再执行安全的持仓保护与待处理操作；SL 只能收紧。
- `ReconcileState()`: 按服务器订单、持仓、成交与持久文件对账，读不到不等于不存在。
- `HandleTradeTransaction(trans,request,result)`: 事件幂等，核对服务器结果及部分成交，事件乱序不重复执行。

## 2. 事件调用顺序（M1）

OnInit：读取账户模式、品种参数、持久状态、服务器订单/持仓/历史；执行恢复对账。若部分初始化失败，不允许新入场；保护/告警仍尽可能工作。OnInit 不应以直接停止 EA 的方式无条件丢失保护能力。

OnTick 的**唯一顺序**：
1. `execution.ReconcileState()`（局部失败标记不确定，不得据此删除持仓）。
2. Core 更新新 K 线时钟和本根已评估状态；不受点差、新闻、时段等入场门控影响。
3. Core 基于已收盘 K 线及现有持仓生成 `ExitIntent`；逐个 `execution.SubmitExit()` **仅排队**。
4. `execution.ManagePositions()`：先处理退出队列，再处理初始 SL 补设、保本、追踪、保护重试；同一持仓已有有效退出意图时跳过本轮追踪修改。
5. **只针对新开仓**执行点差、交易时段、新闻、信号有效期/价格偏离及账户风险门控。
6. `BuildEntryIntent → EvaluateEntry → SubmitEntry`。

步骤 1–4 **不得被提前 return 跳过**。步骤 3 的策略退出即使数据不足，也应记录明确状态；不能被入场门控吞掉。步骤 2 更新时钟不意味着把尚未评估的入场信号标记为已评估；首次评估/门控拒绝时需持久记录本 bar 的处理结果，避免同 bar 延迟追单。

OnTimer：ReconcileState + ManagePositions（含待处理退出/保护）；无 Tick 不得假定报价新鲜。OnTradeTransaction：Core 无条件转发事件，执行模块对订单/成交/持仓标识幂等处理；服务器最终记录优先于本地推断。

## 3. 风险、保证金、成交后复核（M4）

`EvaluateEntry` 以实际账户净值、策略风险预算、初始 SL、OrderCalcProfit、预估成本、已持仓及在途风险确定合规手数；使用 OrderCalcMargin 估算新增保证金，并用 OrderCheck 及当前账户保证金状态复核。预计入场后保证金水平低于批次冻结 `min_margin_level_after_entry_pct` 或保证金不足，返回 `REJECT_RISK` + reason=MARGIN；不得阻断既有持仓保护。OrderCheck/OrderCalcMargin 是提交前估算，不保证服务器最终接受。
成交后按实际成交均价、成交量、佣金及预计平仓成本、有效 SL 重算单笔和组合风险；若超出 policy 的 `post_fill_risk_tolerance_pct`，按冻结政策减仓/阻止新仓/告警；阻止新仓不等于已减少现有敞口。

### 3.1 G3：每策略最大活动槽位

- 每批 policy 登记 `max_active_slots`（strategy_id → 整数）。默认值取自用户规格 §2：S1 1、S2 1、S3 1、S4 2、S5 1、S6 1；S7 以现行 S7 源码的实际上限登记，未核对前为 TBD（TBD 时不得启动含 S7 的批次）。
- 活动槽位 = 本策略已持仓 + 在途请求 + 本策略挂单承诺。在途请求成交只是同一槽位的状态转换，不重复计数；同一 Setup 的部分成交属于同一槽位，不多占也不多释放。
- `EvaluateEntry` 在审批前检查槽位；已满返回 `REJECT_RISK`，reason=`SLOT_FULL`，记录被拒的 setup_id。槽位已满不影响已有持仓的保护与退出。
- 每个槽位对应唯一 `setup_id`（至少包含策略、品种、方向、结构 ID、触发 K 线时间）。同一 setup_id 已占用槽位或已消费时，再次提交返回 `REJECT_RISK`，reason=`DUPLICATE_SETUP`。S4 第二槽必须是新的 setup_id。
- 在途锁（§5）键不变：同一策略同一品种同时最多一笔在途请求。S4 第二槽须在第一槽请求结束在途状态后才可提交。

### 3.2 G5：S7 服务器日 6 盈或 6 亏锁

本条只作用于 S7（用户 Scalping），规则原文见 V1.2 `PLAN_CN.md` §4.1；本节只规定执行归属和接口语义，不改变规则内容。
- **归属**：由 RiskExecution 维护完整交易账本并执行锁定；Core 不自行计数。
- **计数**：按 FxPro 服务器日期，每笔完整交易／Setup 全部结束并完成对账后，按净收益（含已确认佣金、swap 及相关费用；成交价中的点差不重复扣）分类：净盈利计 win、净亏损计 loss、净零另列不计。win 与 loss 分别累计、不互相抵销；跨日持仓按最终结束的服务器日期计数；分批平仓与多笔成交合并为一次。
- **锁定**：当日 win 达 `win_limit` 或 loss 达 `loss_limit`（默认均为 6）即锁定 S7 当天新增风险：`EvaluateEntry` 对 S7 返回 `REJECT_RISK`，reason=`STRATEGY_DAILY_LOCK`；同时撤销 S7 待入场挂单。已有 S7 持仓的保护、保本、追踪、退出与对账继续。不影响 S1–S6 及其他策略。
- **换日**：服务器时间 00:00 清零当日 win/loss 并解除本锁；午夜无 Tick 时在下一次执行机会按服务器日期更新。服务器偏移和夏令时按历史时点核对，不固定换算成本地时间或 UTC。账户紧急锁等其他限制不随换日解除。
- **持久化与去重**：当日计数、已计入的 setup_id 和锁定状态写入状态文件（§6）；重启后恢复相同结果；重复或乱序的交易事件不得重复计数；换 magic、重启或重挂 EA 不能清空当日计数。
- **费用未确认**：某笔交易的费用或归属未确认时，暂停 S7 新增风险（reason=`DAILY_LEDGER_UNRESOLVED`），对账完成后再计数。
- policy 字段：`strategy_daily_count_lock`：`{strategy_id: "S7", win_limit: 6, loss_limit: 6, day_boundary: "SERVER_00_00"}`。

## 4. 账户模式与 magic（M5、P1）

**（v1.1 G1，取代 v1.0 的 `magic_base + strategy_index` 公式）** 每批 policy 以显式表 `magic_map`（strategy_id → magic）登记各策略 magic。默认值取自用户规格 §2（用户已确认内容）：

| 策略 | 默认 magic | 订单备注（仅辅助，不作归属依据） |
|---|---|---|
| S1 | 6101 | `GSM_TREND` |
| S2 | 6201 | `GSM_SD` |
| S3 | 6301 | `GSM_BREAKOUT` |
| S4 | 6401 | `GSM_MOMENTUM` |
| S5 | 6501 | `GSM_BOLLINGER` |
| S6 | 6601 | `GSM_SWING` |
| S7 | 26082152（I10/I11 证据中的 `InpScalpMagic`） | 待核对 |

- 现有 TB500 各 EA 实际使用的 magic 须由 Codex 在本地源码／SET 核对后登记；与上表不同时如实记录，并在迁移时说明采用哪一套，不擅自改动用户确认值。
- 启动检查：magic 唯一、互不重复，且与同账户其他 EA 实例的 magic 不重叠；冲突时禁止新开仓并告警。不能靠 comment 识别归属。
- 第一轮试运行目标：**对冲账户（拟定，启动时验证）**。对冲账户以 magic + POSITION_IDENTIFIER 和 ticket/历史链追踪；ticket 变化不能丢失归属。
- 第一轮若实际为净额模式或与 policy 不一致：禁止新入场、告警；继续管理可确认属于本 EA 的仓位，不得误动其他策略仓位。
- 净额模式未来版本：同品种多策略共享真实仓位不支持；REJECT_NETTING_CONFLICT。RE-18 移至净额上线前阻断验收，第一轮不假装已通过。

### 4.1 D2：非对冲账户及测试器账户模式

- **（v1.1 G2）** 启动及每次新开仓前同时检查：`ACCOUNT_MARGIN_MODE == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING`、`ACCOUNT_HEDGE_ALLOWED == true`、`ACCOUNT_FIFO_CLOSE == false`。任一不满足即视为无法保证各策略独立持仓与独立平仓：禁止新开仓并告警（提示需使用支持双向持仓且不强制 FIFO 的对冲账户），不自动平掉原仓、不切换为净额模拟；仍保护可确认为本 EA 的真实持仓。三项实际读值写入日志和回测报告。
- 第一轮只允许 `ACCOUNT_MARGIN_MODE_RETAIL_HEDGING` 与冻结 policy 对冲模式一致时新开仓。`ACCOUNT_MARGIN_MODE_RETAIL_NETTING` 和 `ACCOUNT_MARGIN_MODE_EXCHANGE` **都属于非对冲**，禁止第一轮新入场并告警；仍保护可确认为本 EA 的真实持仓。
- 回测报告必须记录 Strategy Tester 实际读取的 `ACCOUNT_MARGIN_MODE` 及 policy.account_mode；二者不一致时标记 INVALID，不能作为成绩证据。测试器模式不代表真实经纪账户模式，Demo/实盘另行核验。

## 5. 在途锁、重试、保护、部分成交（M6、P4）

入场只使用已收盘 bar 信号；`max_entry_delay_seconds` 和 `max_price_deviation_price` 由批次 policy 冻结；每个 strategy_id+symbol+signal_bar_time 一次评估或仅按明确重试策略处理，不得在门控结束后追入。
- 在途锁键：EA 实例 + strategy_id + symbol；状态 PENDING_SUBMIT → SENT → PARTIAL/FILLED/REJECTED/EXPIRED。PARTIAL 可能仍有剩余订单。锁超时必须先对账；无法确认服务器状态时继续阻挡。
- 提交前先持久记录 approval_id、intent_digest、magic、symbol、direction、request_time、request_id（若可得）及状态；随后才调用服务器。若崩溃发生于记录与发单之间，恢复时以不确定状态对账，不能自动再次发单。
- 重试优先使用 request/order/deal/position ID 和成交链精确匹配；若 ID 缺失，按 D1 的服务器时间候选匹配规则处理（详见 §5.1）。comment 仅辅助，不能单独判定。
- 部分成交时立即保护已成交手数并复算风险；**默认 cancel_remainder**，不追补。策略可请求 keep_remainder，但必须获 policy 白名单许可；未确认撤单前仍保持在途锁。
- SL 初始/保本/追踪保护只收紧（BUY 新 SL ≥ 服务器已确认 SL，SELL 新 SL ≤ 已确认 SL），以 Bid/Ask、tick size、`minimum_sl_step_price`、SYMBOL_TRADE_STOPS_LEVEL / SYMBOL_TRADE_FREEZE_LEVEL 校验；拒绝或冻结时保留旧 SL 与待处理记录。服务器确认前不更新“已生效 SL”。
- 净成本保本：求满足 `OrderCalcProfit(方向,品种,实际成交量,实际均价,SL价) + 已发生带符号佣金 + 预计剩余佣金 + 已发生 swap + 预计其他费用 - 滑点缓冲 >= 0` 的 tick-size 离散 SL 价格；不可重复扣已在成交价中的点差。价格按 SL 成交只是估算，不保证实际净利非负。
- 已成交仓位没有 SL：按持久初始 SL 意图尝试补设；无法安全确定时按 `emergency_unprotected_position_policy` 告警/退出，不能默认为安全。

### 5.1 D1：在途对账的唯一匹配与自动结案

- 优先使用已持久化的 request/order/deal/position 标识及历史关联链。若无可用 ID，则用本 EA 专属 magic、同 symbol、同方向、**服务器时间 >= request_time_server - clock_tolerance_seconds** 的挂单、持仓及成交缩小候选。时钟容差属于每批冻结 policy；本地时间不可混作服务器时间。以 order_ticket 聚合：同一订单的多笔部分成交视为**一个候选**。
- **唯一 1 个候选**：关联该订单/成交，转 OK_PENDING，按服务器最终状态推进，保留必要的在途保护。
- **0 个候选 + 挂单/持仓/历史查询全部成功 + 超过 inflight_timeout_seconds**：判定该请求未获可见服务器接受，标记 EXPIRED、释放在途锁，**审批仍为已使用，不自动重发**；只有新信号和新审批才能再入场。
- **0 个候选但查询失败、历史范围不足或仍未超时**：保持锁，RECONCILE_REQUIRED（未超时可保持 OK_PENDING），下次 Tick/Timer 再核对。
- **2 个以上候选**：保持锁，RECONCILE_REQUIRED，禁止该策略新入场并告警；不猜测归属、不重复发单。
- 即使候选存在歧义，所有可确认为本 EA magic 的真实持仓仍须计入组合风险、尝试补设 SL 和持续保护。订单归属审批不确定**只阻止新开仓**，不阻断真实敞口保护。
- 零候选结案的前提是查询范围完整、账户连接与历史覆盖足以支持结论；无法证明则不能释放锁。

## 6. 持久记录与恢复（M3、P3、D3、D4）

每个 EA 实例在终端 `MQL5/Files/` 下持久化状态文件，文件名包含经过安全编码的 symbol 和 `instance_id`（v1.1 G1：不再使用 magic_base）；使用 schema_version，禁止两个实例共用文件。使用带 schema_version 的可校验结构化记录（可采用 JSON，MQL5 序列化需实现验证）。每实例固定 **A/B 双槽**，不依赖 rename。
必备字段：
```json
{
  "schema_version": 1,
  "instance_id": "TBD",
  "magic_map_hash": "TBD",
  "lease": {"holder_instance_id": "TBD", "heartbeat_at": "TBD"},
  "strategy_daily_count": [{"strategy_id": "S7", "server_date": "TBD", "wins": 0, "losses": 0, "zero": 0, "counted_setup_ids": [], "locked": false}],
  "symbol": "TBD",
  "account_login_fingerprint": "TBD",
  "policy_hash": "TBD",
  "sequence": 0,
  "updated_at": "TBD",
  "inflight": [{
    "strategy_id": "TBD",
    "approval_id": "TBD",
    "intent_digest": "TBD",
    "status": "PENDING_SUBMIT",
    "request_time": "TBD",
    "request_id": "TBD",
    "order_ticket": "TBD",
    "deal_tickets": []
  }],
  "consumed_approval_ids": [],
  "pending_protection_actions": [],
  "pending_exit_intents": [],
  "positions": [{
    "position_identifier": "TBD",
    "position_ticket": "TBD",
    "magic": 0,
    "initial_sl_price": "TBD",
    "desired_sl_price": "TBD",
    "confirmed_sl_price": "TBD"
  }],
  "checksum": "TBD"
}
```
所有数值占位仅是 schema 示例，**不能当运行 policy**。**唯一写法：A/B 双槽交替写入**，例如 state_A 与 state_B；写入非当前最新有效槽，写完 flush/close 后重新读取校验。每槽包含单调递增 sequence 和 SHA-256 checksum（使用 MQL5 支持的 CryptEncode/CRYPT_HASH_SHA256，具体编码经编译验证）；哈希计算覆盖规范化 payload，排除 checksum 字段自身。启动时分别读取两槽，选择校验通过且 sequence 最大的记录；一槽损坏则使用另一槽；两槽都无效则 RECONCILE_REQUIRED，禁止新入场并继续安全保护。不得声称文件系统已保证掉电原子性，RE-25 验证中断恢复。
服务器订单、持仓及成交记录是交易事实的最终依据；本地保存审批已用、初始 SL 意图及待处理任务等服务器无法完整提供的事实。冲突记录审计；不能把服务器记录缺失/查询失败当作不存在。
文件损坏、缺失、账户指纹不符、schema 不兼容或对账不确定：RECONCILE_REQUIRED，禁止新仓，继续能安全执行的保护并告警；解锁需要可证明的完整对账。对已用审批/在途锁的恢复不得仅靠“没有找到订单”而盲目重新发单。

### 6.1 D4：回测状态隔离

- `MQLInfoInteger(MQL_TESTER)` 为真时，**普通回测 OnInit 必须从空状态启动**，不得加载任何先前回测遗留审批、在途锁或持仓保护状态；状态文件名包含本次唯一 run_id（由单一回测执行器提供）。缺失/复用 run_id 的成绩批次不得运行。
- 唯一例外：RE-05、RE-06、RE-25 等明确标注的重启恢复验收，显式指定 fixture 文件及恢复模式，且不得计入策略成绩。
- 即使 policy_hash 和账户指纹与上一轮相同也必须隔离。新增 RE-27 验证连续两次回测不串状态。

### 6.2 G4：单执行实例租约

用户规格 §2.1 第 6 点：同一账户、服务器、品种和 magic 集合只允许一个负责执行的 EA 实例。
- **租约键**：账户登录号 + 交易服务器 + symbol + `magic_map_hash`。
- **租约文件**：写在终端公共目录（`FILE_COMMON`），使同一台电脑上的多个终端也能互相看见；内容为持有者 `instance_id`、心跳时间（服务器时间）和启动时间，采用与 §6 相同的 A/B 双槽与校验。
- **持有者**：按 policy `lease_heartbeat_seconds` 更新心跳。
- **非持有者**：不执行任何交易动作（不开仓、不改单、不平仓），只告警并显示只读诊断，避免两个实例同时修改同一持仓的 SL。
- **接管**：心跳超过 policy `lease_stale_seconds` 未更新，才可接管；接管后先完整对账（§5.1、§6）再恢复保护与新开仓。
- **局限**：租约只能防止同一台电脑上的重复实例；不同电脑上用同一账户运行的重复实例无法由文件发现，须由部署规程禁止，并在启动时以“出现非本实例产生的同 magic 新成交”作为告警线索。
- **回测**：`MQL_TESTER` 为真时，租约按 run_id 隔离、不写公共目录（与 §6.1 一致）。

## 7. 构建、试验政策与队列（M2、P2、P5）

- **生产构建**用于所有成绩回测、成本压力、样本外和 Demo；**故障注入构建**只用于 F 验收。生产构建不能含可触发注入代码路径。测试结果不得作为策略收益成绩。
- Codex 负责同一编译脚本参数化生产/注入构建；两者来自同一 commit，注入差异只在 `#ifdef TEST_FAULT_INJECTION` 保护范围内。保存源码 commit、编译参数、编译日志、两个 EX5 SHA256、注入差异检查记录、报告所用 build_type 与 EX5 hash。生产部署前核对 EX5 哈希及无注入路径；未实现前状态 NOT VERIFIED。
- 每批 `policy.json` 冻结字段及数值：account_mode、magic_map（v1.1 G1）、max_active_slots（G3）、strategy_daily_count_lock（G5）、lease_heartbeat_seconds、lease_stale_seconds（G4）、initial_capital_account_ccy、symbol、data_range、tick_model、execution_delay、costs、score_anchors、experiment_budget、max_entry_delay_seconds、max_price_deviation_price、approval_ttl_seconds、inflight_timeout_seconds、max_retry_count、post_fill_risk_tolerance_pct、partial_fill_remainder_policy、minimum_sl_step_price、min_margin_level_after_entry_pct、clock_tolerance_seconds、emergency_unprotected_position_policy、以及部分成交、异常退出和恢复所需策略。**run_id 不属于 policy.json，不参与 policy_hash；由单一回测执行器写入队列任务，并作为 EA 输入参数传入，每份报告记录 run_id。** **接口冻结字段/单位/语义，不替批次选择数值**。必要字段为 TBD 时不得启动该批；评分锚点未冻结则总分 N/A，不能事后修改。
- Claude 只创建不可变 `research/queue/pending/<run_id>.json`；Codex 单执行器独占更新 running/completed/failed，持久 run_id 去重、本机锁、异常恢复。Git 文件不是锁；仅一个 MT5 Tester，不额外创建数据目录绕开占用。失败试验也计入总预算。

## 8. 统一状态及验收

v1.1 新增 `REJECT_RISK` 的 reason：`SLOT_FULL`、`DUPLICATE_SETUP`、`STRATEGY_DAILY_LOCK`、`DAILY_LEDGER_UNRESOLVED`（状态码本身不增加）。

状态码：OK_CONFIRMED、OK_PENDING、REJECT_RISK、REJECT_VOLUME、REJECT_IN_FLIGHT、REJECT_NETTING_CONFLICT、REJECT_APPROVAL、REJECT_MARKET、REJECT_STOPS_LEVEL、RETRYABLE、FAIL_SERVER、DATA_UNAVAILABLE、PROTECTION_PENDING、RECONCILE_REQUIRED。
- OK_PENDING 只表示请求已发/待确认；OK_CONFIRMED 需服务器订单/成交/修改确认。
- RETRYABLE 先精确对账，无法唯一确认则 RECONCILE_REQUIRED；不得重复下单。
- 保护/退出失败记录原始 retcode 并保留待处理；休市等待开市；冻结区不发无效请求；不得放宽服务器已生效 SL。
- 对账数据部分不可用，仍保护可确认持仓，不允许新入场。

**完整验收矩阵（RE-01～RE-27）：** 所有可执行用例尚未运行，RE-18 推迟至净额模式上线前。T=策略测试器；F=测试器/可控故障注入；D=Demo；构建审计=静态/编译审计。真实服务器拒单不能仅凭注入测试证明。

| ID | 场景 | 通过条件 | 方式 | 状态 |
|---|---|---|---|---|
| RE-01 | 点差门控 + 已持仓追踪 | 仍更新追踪 SL | T | NOT RUN |
| RE-02 | 新闻门控 + 已持仓保本 | 仍执行保本 | T | NOT RUN |
| RE-03 | 试图放宽 SL | 拒绝，旧 SL 不变 | T | NOT RUN |
| RE-04 | 0.30 手部分成交 0.10 | 保护已成交量、剩余按 policy、重算风险 | F | NOT RUN |
| RE-05 | 重启发现无 SL 持仓 | 补设或按紧急政策处理并告警 | T/D | NOT RUN |
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
| RE-27 | 连续两次普通回测 | 第二次完全不读取第一次状态，run_id 隔离 | T | NOT RUN |
| RE-28a | magic_map 有重复值，或与同账户另一实例重叠 | 禁止新开仓并告警；已有持仓保护继续 | T | NOT RUN |
| RE-28b | `ACCOUNT_HEDGE_ALLOWED` 为 false | 禁止新开仓并告警，不自动平仓 | F | NOT RUN |
| RE-28c | `ACCOUNT_FIFO_CLOSE` 为 true | 禁止新开仓并告警，不自动平仓 | F | NOT RUN |
| RE-29a | S4 两槽已满时出现第三个合格 Setup | REJECT_RISK(SLOT_FULL)，两槽保护继续 | T | NOT RUN |
| RE-29b | 同一 setup_id 第二次提交 | REJECT_RISK(DUPLICATE_SETUP) | T | NOT RUN |
| RE-30a | 同一电脑第二个实例以相同租约键启动 | 第二实例不执行任何交易动作，只告警 | F | NOT RUN |
| RE-30b | 持有者心跳超时 | 接管者先完整对账再恢复保护与新开仓 | F | NOT RUN |
| RE-31a | S7 当日 3 盈 3 亏 | 不锁定 | T | NOT RUN |
| RE-31b | S7 当日第 6 笔净盈利（或第 6 笔净亏损） | 锁定 S7 新增风险并撤销 S7 待入场挂单；S7 持仓保护继续；S1–S6 不受影响 | T | NOT RUN |
| RE-31c | 净零交易、手续费使毛盈变净亏 | 净零不计；按净收益分类 | T | NOT RUN |
| RE-31d | 分批平仓／多笔成交 | 全部结束后只计一次 | F | NOT RUN |
| RE-31e | 跨日持仓、午夜无 Tick | 按最终结束的服务器日计数；下一执行机会按新日期换日 | T | NOT RUN |
| RE-31f | 锁定后重启、重复或乱序交易事件 | 恢复相同计数与锁定；不重复计数 | F | NOT RUN |
| RE-31g | 某笔费用未确认 | REJECT_RISK(DAILY_LEDGER_UNRESOLVED)，对账后再计数 | F | NOT RUN |
| RE-31h | S1–S6 的盈亏 | 不计入 S7 计数 | T | NOT RUN |

注：RE-24a/b/c 是 RE-24 的三个子用例；v1.1 新增 RE-28～RE-31 共 4 个编号（展开为 15 条子用例）。全部 NOT RUN；RE-18 仍为 DEFERRED。
第一轮对冲模式目标下 RE-18 标记 **DEFERRED / NETTING RELEASE GATE**，不是 PASSED。其他用例由双方按可模拟能力决定 T/F/D 及必要的补充集成测试，不得把模拟结果说成真实服务器验证。

## 9. 交接、冻结与未解决问题

交接必须附 candidate_id、run_id、branch、完整 commit SHA、变更模块、源码/参数/EX5 hash、编译日志、原始报告、执行环境、已跑/未跑测试和未解决问题。交叉审查完整调用路径，不只看 diff。
本文件为 v1.1 草案。Codex 核对 G1–G5 后，双方确认即以本文件替换 `contracts/risk_execution_interface.md`，状态改为 FROZEN v1.1；v1.0 原文保留在 git 历史（提交 8a48a8f）。此冻结不代表实现已验证；合并 main 仍需项目授权。本次不合并 main、不启动开发或实盘。

**待确定**：第一轮实际账户模式及批次 policy 数值；MQL5 A/B 双槽和 SHA-256 实现验证；双构建差异验证脚本；无法自动消除的订单歧义的人工恢复流程；测试器无法模拟的服务器行为的 Demo 计划。
