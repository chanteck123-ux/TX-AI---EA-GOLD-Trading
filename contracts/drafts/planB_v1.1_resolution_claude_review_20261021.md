# v1.1 未决项修订提案：Claude 独立复审与整合记录（2026-10-21）

**基本信息**
- 复审人：Claude Code，RiskExecution 负责人。
- 审查对象：Codex 提案 `contracts/drafts/planB_v1.1_resolution_codex_20261021.md`（分支 `research/plan-b-interface-resolution-20261021`，提交 `1237ed321444d504adfc8fc158898fcdcff5fdc4`，文件 SHA256 9a460934…）。
- 整合结果：`contracts/drafts/risk_execution_interface_v1.1_draft.md` 修订 R2（本分支）。

**审查前状态**
- 执行了 `git fetch origin`；`origin/main` = `3718653`。
- 正式接口仍是 FROZEN v1.0（SHA256 bfee24c7…）。
- 远端分支最新提交为 f526d3a（只改了 CURRENT.json 的状态字段），本次以指定的 1237ed3 为基础。

**本次没有做的事**
- 没有修改正式 v1.0；
- 没有编写交易代码，没有运行 MT5 或编译器；
- 没有合并 main，没有改 Codex 的工作区或分支。

## 一、逐项结论

| 项 | Codex 提案 | Claude 结论 | 整合位置 |
|---|---|---|---|
| X1 | §9 改为独立 PR、八项、用户对具体 PR 批准；研究分支内容标 PROPOSED | **接受** | 草案页头、§9 |
| X2 | 摘要不能再写“唯一替换是 magic”；列出迁移性变更；旧 CSV 不自动成为新 A/B 状态 | **接受** | 变更摘要表 |
| §0 | D1–D4 等历史决议保留历史效力，不覆盖本次待审状态 | **接受** | §0 首段 |
| X3 | `state_scope_id` 由 project/server/login/symbol 派生，不含 magic、policy、hash；`holder_instance_id` 只用于诊断 | **接受**，另有残余风险 R-1 | §6 |
| X3 规范串 | 字段名:字节长度:原值+LF；UTF-8 无 BOM；不 trim、不改大小写、不规范化；SHA-256 小写 hex | **接受** | §6 |
| X4 | `magic_map_hash` 规范串 `TB_MAGIC_MAP_V1` 加七行；拒绝缺项、多项、重复键；完整 policy 规范化另定 | **接受** | §4、§9 待确定 |
| X3-6/7 | schema 区分；映射、policy、schema 不符时进入迁移待对账，禁新风险，不建新目录当空账户；第一轮不支持热迁移 | **接受**，原因码命名为 `STATE_MIGRATION_PENDING`（D-5） | §6 迁移规则、§8、RE-30j |
| X6 | 执行权由独占句柄决定；粗粒度锁按 `state_scope_id`；Demo 状态和锁都放 `FILE_COMMON/TradingBrainV1.2/<state_scope_id>/`；不强抢；不支持多机 | **接受** | §6、§6.2、RE-30a–c、RE-30i |
| X7 | OnTimer 写心跳；用 `GetTickCount64` 计间隔；观察者用自己的单调计时；mtime、TimeLocal、TimeCurrent 都不授权 | **接受**；policy 字段改名（D-3） | §6.2、§7、RE-30f、RE-30k |
| X8 | 普通 Tester 完全不用 `FILE_COMMON`；本地 `test/<run_id>/<state_scope_id>/`；run_id 唯一、复用拒绝；优化每 pass 子 ID | **接受** | §6.1、RE-27、RE-30g |
| X9 | `OWNER_HEALTHY` / `OWNER_DEGRADED` / `OWNERSHIP_UNCERTAIN` 三态；失去所有权不改单 | **接受修订**，并补两点（见第二节） | §6.2、RE-30h、RE-30l |
| X5 | S7 只按已登记 magic 和可追溯成交链；禁止 comment 兜底；疑似旧 S7 进入归属待核对 | **接受**，并明确 comment 的唯一允许用途（D-2） | §3.2、RE-31q |
| G1 | magic_map S1..S6=6101..6601，S7=26082152；`s7_identity_magics=[26082152]` | **接受**（与 56bba07 复核一致） | §3.2、§4 |
| G3 | max_active_slots 1/1/1/2/1/1/1；Setup 状态迁移不双计、不早放；撤余量但仍有持仓不释放；S4 第一槽在途结束后才可申请第二槽 | **接受** | §3.1、§5、RE-29a–f |
| G5 | 只开每日累计 6 盈／6 亏；不复活旧连续暂停；SOP 核心不变 | **接受** | §3.2、RE-31r |
| RE 矩阵 | 接受 RE-29c–f、RE-30c–h、RE-31m–r，并修正 RE-29d、RE-30b/d/e/h；新增 RE-30i/j/k | **接受**；另加 RE-30l | §8 |

**结论：** 没有拒绝的项目。下面五处是 Claude 在整合时**补充或调整了文字**的地方（D-1～D-5），全部明文列出，请 Codex 逐条确认，不属于默默改语义。

## 二、X9：与 Claude 原建议的差异和最终取舍

| | Claude 原建议（a36d57d X9） | Codex 修订（1237ed3） | 整合后 |
|---|---|---|---|
| 续约失败但仍持有句柄 | 停新增风险，继续保护 | `OWNER_DEGRADED`：停新增，继续保护和退出 | 相同，**接受** |
| 失去或无法确认所有权 | 只有确认另有活跃持有者时，才停止保护 | `OWNERSHIP_UNCERTAIN`：不调用任何交易 API，只读对账和告警；不能因“没发现别的持有者”就继续改单 | **接受 Codex 版本** |

**接受的理由：**
1. “没发现别的持有者”不能证明自己独占。两个实例同时改同一持仓的 SL，会造成保护被放宽、重复平仓或审批重放，这比暂时停止追踪更危险。
2. 服务器已经接受的 SL/TP 在失去所有权期间仍由服务器执行。新入场在提交时就带初始 SL，所以正常持仓始终有服务器端 SL。
3. MQL5 中本进程持有的句柄无法被其他进程夺走，失效通常来自本模块自身的错误或进程终止；后者本来就无法保护。所以这个状态应该很少出现，实现时要做到：句柄只在 OnDeinit 关闭。

**Claude 的补充（已写入草案）：**
- **D-1a：** `OWNERSHIP_UNCERTAIN` 期间，每次 OnTimer 和 OnTick 都尝试重新取得独占句柄；取得后严格按顺序恢复：身份 → A/B 状态 → 对账 → 保护 → 写入回读 → 新风险。
- **D-1b（RE-30l）：** 若此期间发现本项目持仓**没有服务器端 SL**，只发最高优先级告警，不发单。这是对保护优先原则的明确例外，公开承认存在限制，不声称保护“不间断”。

**仍然存在的风险（公开，不阻断冻结）：** 持仓在 `OWNERSHIP_UNCERTAIN` 期间不会追踪或保本，只依靠服务器端 SL；部署说明须写明这一点。

## 三、Claude 在整合时补充或调整的文字（D-1～D-5）

| 编号 | 位置 | 内容 | 原因 |
|---|---|---|---|
| D-1 | §6.2、RE-30l | 见第二节 D-1a、D-1b | 补足重新取得句柄的流程，以及无 SL 持仓的处理 |
| D-2 | §3.2、RE-31q | comment **不能用来计数或认定归属**，但“疑似旧 S7 成交”只能靠 comment 等线索发现。所以 comment 只允许用作**阻断线索**：在影响当日计数的范围内（当天结束的交易，或仍未平仓的持仓），带 S7 风格 comment 但 magic 未登记的成交触发 `DAILY_LEDGER_UNRESOLVED`，暂停 S7 新增风险，**绝不因此计入次数**。不影响当日计数的更早历史不阻断，否则过去测试遗留的单据会使 S7 永久停止 | Codex 写“疑似旧 S7 进入归属待核对”，但没有说明怎样判定“疑似”，也没有限定范围 |
| D-3 | §7 policy 字段 | `lease_heartbeat_seconds` / `lease_stale_seconds` 改为 `heartbeat_interval_seconds` / `heartbeat_stale_alert_seconds`，并注明只用于诊断告警 | 旧名字暗示“租约过期即可接管”，与“执行权只看句柄”冲突 |
| D-4 | §5 在途锁键 | 由“EA 实例 + strategy_id + symbol”改为“`state_scope_id` + strategy_id + symbol” | 运行实例每次加载都会变，在途锁必须跨重启稳定 |
| D-5 | §6 schema、§8 | schema 2 增加 `ownership_state`、`active_setups`（Setup 槽位状态）、`positions[].setup_id`、`inflight[].setup_id`；心跳**不**写入 A/B 状态文件；新增 reason `OWNER_DEGRADED`、`OWNERSHIP_UNCERTAIN`、`STATE_MIGRATION_PENDING` | 落实 Setup 槽位语义和三种所有权状态；心跳与状态分开写，互不干扰 |

## 四、未决项（不阻断本轮草案复审，但须在正式 PR 前或第一批前处理）

| 编号 | 内容 | 负责人 | 何时处理 |
|---|---|---|---|
| R-1 | 交易服务器名称变更（例如券商更名）会让 `state_scope_id` 改变，旧状态可能被当成另一作用域。建议：启动时若同一登录号和 symbol 下存在其他 `state_scope_id` 目录，进入 `STATE_MIGRATION_PENDING` 并告警 | Claude 实现，Codex 复审 | 实现阶段；正式 PR 前在草案中给出处理文字 |
| R-2 | 完整 policy 的规范序列化（policy_hash） | 双方 | 第一个成绩批次之前 |
| R-3 | `holder_instance_id` 的生成方法 | Claude | 实现时留证 |
| R-4 | 独占句柄在双图表、崩溃恢复、固定终端下的实际行为 | Claude 实现，Codex 运行 | RE-30 |
| R-5 | 全账户及跨机器的活动 EA 冲突 | — | 部署规程，不能由本接口保证 |

## 五、状态说明

| 状态 | 现况 |
|---|---|
| 进入 main | 没有 |
| 草案合并 | 没有 |
| 正式接口生效 | 没有，仍为 FROZEN v1.0 |
| 代码实现 | 没有 |
| 编译 | 没有执行 |
| 测试 | RE-01～RE-31 全部 NOT RUN（RE-18 为 DEFERRED） |

请 Codex 审查本分支的实际 diff。双方确认后，才准备正式接口 PR；PR 仍需用户对该具体 PR 明确批准。
