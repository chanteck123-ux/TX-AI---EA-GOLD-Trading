# RiskExecution v1.1 冻结前审查：Claude 复核记录（2026-10-18）

- **身份：** Claude Code，方案 B RiskExecution 负责人。
- **性质：** 冻结前的文件和规格审查，以及取证复核清单。**不是** Codex 的本地取证，**也不是**对 v1.1 冻结的批准。
- **基线：** `origin/main` = `3718653b8f7bde02e2f52ef5ec47a6ec4c1c459d`。审查前执行了 `git fetch origin` 和 `git log origin/main`。
- **未做的事：**
  - 没有修改正式接口 v1.0；
  - 没有编写 RiskExecution 交易代码；
  - 没有编译、回测，没有启动 MT5；
  - 没有合并 main。

## 一、已读取的文件（origin/main 3718653）

| 文件 | SHA256 |
|---|---|
| `AGENTS.md` | d894148c…11a5 |
| `CLAUDE.md` | 仅一行，导入 AGENTS.md |
| `contracts/risk_execution_interface.md`（FROZEN v1.0） | bfee24c7…ce86 |
| `contracts/drafts/risk_execution_interface_v1.1_draft.md` | 0c050017…90d6 |
| `contracts/drafts/planB_v1.1_consistency_check_claude_20261018.md`（修改前） | d09b1c3b…5805 |
| V1.2 `README.md` | ecafce72…c5a5 |
| V1.2 `docs/PLAN_CN.md`（§2、§2.1、§3、§4、§4.0、§4.1 全文） | ebcb4d19…76b5 |
| V1.2 `docs/COLLABORATION_CN.md` | 3b89f33e…ec94 |
| V1.2 `research/CURRENT.json` | a6ab0aa1…c2fc |
| 分支 `draft/v1.1-evidence-scope` 的 `contracts/drafts/v1.1_preliminary_evidence_iteration10_cn.md` | 提交 `454dc9ab…6b09` |

PLAN 的 §6、§8、§9 本次只核对了与 RiskExecution 相关的风险约束（§6 账户风险和保护优先、§6.2 延迟），评分章节不在本次接口审查范围内。

**Claude 自行读取的本地源码（只读，作为线索，不能代替 Codex 的取证）：** 第 18 轮交付 `outputs/TradingBrain_I18_Seven_Strategies_20261011/`。

| 文件 | SHA256（前 16 位） |
|---|---|
| `candidates/S1…S6/*_I18.mq5` | S1 877a801f… S2 501d0296… S3 4cb60e6d… S4 6139181a… S5 3ac3510a… S6 286a26ef… |
| `candidates/Scalping_TB500_Scalping_SPREAD20_I18/MT5/TB500_Scalping_SPREAD20_I18.mq5`（9595 行） | 41f443dd4ee26c49 |
| `baseline_restore/Scalping_TB500_Scalping_DYNAMIC_COST_BREAKEVEN_V1_I15/*.mq5` | cbc629f049f70106 |

“第 18 轮保留版本”具体指哪一个文件（I18 候选，还是 baseline_restore 中的 I15），由 Codex 按 CURRENT.json 和交付清单确认。下面的源码线索都注明了文件和行号。

## 二、接口状态

| 状态 | 事实 |
|---|---|
| 正式接口 | `contracts/risk_execution_interface.md` 仍为 **FROZEN v1.0** |
| v1.1 | 只在 `contracts/drafts/`，是草案，**没有生效** |
| 代码 | 方案 B 的 RiskExecution 模块没有实现、没有编译、没有测试 |

第 18 轮的历史源码不等于新模块已经实现。

## 三、AGENTS 方案 B 与 v1.1 草案的一致性：发现的冲突

职责划分（Core 与 RiskExecution、交易调用边界、保护优先、测试队列）与 AGENTS 方案 B 一致，与原核对文件第二节的结论相同。以下是本次新发现的问题：

| # | 问题 | 依据 | 建议 | 是否阻断冻结 |
|---|---|---|---|---|
| X1 | **合并流程与 AGENTS 门禁冲突。** v1.1 §9 写“双方确认即以本文件替换”；核对文件第四节写“Codex 以 v1.1 替换……一次合并到 main” | AGENTS「main 合并门禁」：必须另开独立 PR，写明八项，并取得用户对该 PR 的明确批准；代理不得代用户表示批准 | v1.1 §9 改为引用 AGENTS 门禁；核对文件第四节已在本分支修正 | 是（文字修正即可关闭） |
| X2 | **变更摘要不完整。** v1.1 写“唯一替换是 §4 的 magic 公式”，但 §6 的状态文件身份也由 `magic_base` 改成 `instance_id`，持久字段也由 `magic_base` 改成 `magic_map_hash` | v1.0 与 v1.1 的逐行 diff | 摘要补上这两处替换 | 是 |
| X3 | **`instance_id` 没有定义。** 状态文件名和租约都依赖它，但没有规定如何生成、重启后是否保持不变。若每次启动都变，重启后就找不到原状态，恢复会失效；若多个图表相同，又会共用同一文件 | v1.1 §6、§6.2 | 区分两件事：（a）**状态身份**，由账户、服务器、symbol、`magic_map_hash` 稳定派生；（b）**进程实例随机值**，只用于租约持有者 | 是 |
| X4 | **`magic_map_hash` 没有规定规范化方法**（字段顺序、编码、哈希算法） | v1.1 §6.2 租约键 | 规定按 strategy_id 排序的规范文本，再取 SHA-256 | 是 |
| X5 | **S7 归属不能靠 comment，与现行源码冲突。** v1.1 §3.2 只按 `s7_identity_magics` 识别 S7；§4 写明“不能靠 comment”。而 I18 Scalping 的日锁账本用 “magic==26082152 **或** comment 以 `GSM50_S_` 开头” 认定归属 | I18 Scalping 第 1730、1828、1876、1921、1947 行 | 由 Codex 核对历史上是否有不带 26082152 的 S7 成交。若有，要么补登记对应 magic，要么在 v1.1 中明确迁移规则；不能悄悄沿用 comment 作为归属依据 | 是（属于 G1、G5 证据） |
| X6 | **租约取得没有互斥原语。** v1.1 §6.2 只规定心跳文件加 A/B 双槽，两个实例同时启动时都可能认为自己是持有者。现行源码用 `FileOpen(...FILE_READ\|FILE_WRITE\|FILE_BIN\|FILE_COMMON)` 独占句柄作执行锁 | I18 Scalping 第 1620、1777 行；S1–S6 I18 第 193–204 行 | v1.1 写明“以独占文件句柄取得租约，心跳文件只作诊断”，或规定其他可验证的原子取得方式。G4 取证必须覆盖独占打开在两图表和两终端下的实际行为 | 是（属于 G4） |
| X7 | **心跳时钟没有规定。** 写“服务器时间”，但没有 Tick 时（周末、休市）`TimeCurrent()` 不前进，心跳超时判断会失真 | v1.1 §6.2 | 存活判断用本机单调时钟或 `TimeLocal`/`GetTickCount64`，审计记录用服务器时间；两者分开 | 是 |
| X8 | **测试器下的租约位置有差异。** v1.1 写测试器下租约不写公共目录；I18 Scalping 在测试器中仍写 `FILE_COMMON`，只是用 run label 区分作用域 | I18 Scalping 第 1775–1779 行 | 二选一，写入 v1.1，并由 G4 取证 | 否（说明后可冻结） |
| X9 | **失去租约后的保护规则不清。** v1.1 写“非持有者不执行任何交易动作”。若持有者自己续约失败，且没有其他持有者，它的持仓保护应当继续还是停止，没有规定 | v1.1 §6.2；AGENTS“保护优先” | 写明：续约失败时先停新增风险；只有确认另有活跃持有者时，才停止保护动作 | 是 |
| X10 | **S7 日锁在非测试器路径上的差异（现行源码事实）。** I18 中，“下单前先对账、在途标记、自有挂单阻挡”只在测试器中执行；非测试器只靠 `pauseUntil`，而它只在已锁定时设置。账本对账失败但尚未锁定时，非测试器路径不会阻止 S7 新增风险 | I18 Scalping 第 1643、1659、1928–1936、6924 行 | 这是旧源码的事实，**不是 v1.1 的缺陷**；新的 RiskExecution 必须在所有模式下执行 `DAILY_LEDGER_UNRESOLVED`。列入 G5 证据 | 否（G5 证据项） |
| X11 | **连续暂停与每日锁的关系。** I18 第 8820 行注释写日锁维护“supersedes the legacy consecutive-streak/24-hour pause”，而 `InpScalpPauseAfterStreak=6`、`InpScalpPauseHours=24` 两个输入仍在 | I18 第 599–600、8820 行 | 不能据此认定连续暂停已删除，也不能合并。请 Codex 核对实际效果，由用户确认是否保留 | 否（登记待决） |

## 四、G1 / G3 / G4 / G5 复核矩阵（等待 Codex 取证）

| 项目 | Codex 必须提交的证据（接收标准） | Claude 的本地线索（只是线索） | 当前状态 |
|---|---|---|---|
| **G1 七策略 magic** | ① 第 18 轮保留版本的七个源码路径和完整 SHA256，并与第 10 轮哈希比对；② 每个 magic 的源码行号（输入参数或写死的值）；③ 实际 SET 文件中的覆盖值；④ 冲突检查结果；⑤ `s7_identity_magics` 只能放有证据属于 S7 的 magic（26082102、26082303 不能放）；⑥ 与用户规格 6101…6601 不同时如实记录 | S1–S6 I18：`long g_magics[6]={6101,6201,6301,6401,6501,6601};`（S1 第 89 行，S4 第 84 行等）。Scalping I18：`InpScalpMagic=26082152`（第 485 行）、`InpIntradayMagic=26082102`（第 484 行）、`InpSwingMagic=26082303`（第 486 行）；日锁账本把 26082152 写死，并用 comment `GSM50_S_` 兜底（见 X5） | **待 Codex 取证** |
| **G3 S7 槽位** | ① S7 现行源码中并发上限的实际行号和生效逻辑；② 挂单是否占用槽位、在途请求是否占用；③ 确认 S4 第二槽须等第一槽在途请求结束，且不与原有双槽行为冲突 | Scalping I18：`InpScalpMaxOpenPositions=1`（第 601 行）、`InpTotalMaxOpenPositions=1`（第 501 行）；测试器路径中只要存在自有挂单就拒绝新增风险（第 1944–1948 行 `SCALP_OWN_ORDER_PENDING`），说明挂单实际占用。S1–S6 I18：`int g_slots[6]={1,1,1,2,1,1};`。从 B4 研究已读的原生 S4（I11 `TB500_S4_BE125.mq5` 第 2957 行）看，请求在途时返回 `REQUEST_UNKNOWN`，与 v1.1 的在途锁一致 | **待 Codex 取证**；若无法确定，保持 TBD，并禁止 S7 新增风险和 S7 回测批次 |
| **G4 `FILE_COMMON`** | ① 固定 523FF `/portable` 终端下 `FILE_COMMON` 的实际路径；② 在 Demo 或测试器中，两个图表能否读写同一文件；③ 独占句柄在第二个图表、第二个终端上是否打开失败（见 X6）；④ 测试器按 run_id 隔离的路径；⑤ 不在挂实盘的终端上新增实例 | 源码已在用 `FILE_COMMON` 独占句柄（S1–S6 I18 第 193–204 行；Scalping 第 1620、1777 行），但**没有**任何平台实测记录 | **待 Codex 取证** |
| **G5 S7 日锁现行行为** | ① 计数来源（服务器历史还是本地状态）、换日、归属、费用口径的源码行号；② 换 magic、重挂 EA 是否清零；③ 多实例是否共用计数；④ 手工单是否排除；⑤ 测试器与非测试器路径的差异（见 X10）；⑥ 连续暂停是否仍生效（见 X11）；⑦ 第 10 轮 `PASS_OBSERVED_NATIVE_DAILY_NET6_6` **没有观察到任何锁定日**，这一缺口保留 | Scalping I18 第 1693–1957 行：按完整服务器历史（`HistorySelect(0,TimeCurrent())`）重算；以服务器日 `DayStart(TimeCurrent())` 换日；按原始入场订单把多个持仓、多笔成交归为一个 Setup；净值 = profit+commission+swap+fee；遇到无法归属的账户级佣金时停止（`UNALLOCATED_ACCOUNT_COMMISSION`）；状态写入 `FILE_COMMON` CSV；锁定后取消自有挂单。手工单因 magic 不同、comment 不带前缀而不计入，此推断待 Codex 确认 | **待 Codex 取证** |

**复核时逐项检查：**
1. 源码与第 18 轮保留版本是否一致（以哈希为准）；
2. 文件哈希、magic、历史身份和冲突检查是否有依据；
3. S7 槽位和挂单占用是否由源码确认；
4. `FILE_COMMON` 是否有真实路径、共享读写和隔离记录；
5. 日锁是否对照了 PLAN §4.1，且没有把连续暂停和累计锁混为一谈；
6. 未知值是否仍标 TBD；
7. `s7_identity_magics` 是否只包含有证据的 S7 magic。

**状态统计：** 目前没有任何一项“已通过”。四项都在等待 Codex 取证。X1–X4、X6、X7、X9 必须先修改草案，才能冻结。

## 五、RE-29 / RE-30 / RE-31 完整性审查

| 编号 | 现有定义 | 缺口 | 建议补充 |
|---|---|---|---|
| RE-29 | a 槽位已满；b setup_id 重复 | §3.1 规定了挂单占槽、部分成交不多占也不多释放、S4 第二槽须等第一槽在途结束，但都没有验收用例；S7 槽位为 TBD 时的拒绝也没有用例 | **RE-29c** 挂单占用槽位；**RE-29d** 部分成交只占一个槽位，取消剩余部分后正确释放；**RE-29e** S4 第一槽在途时第二槽返回 REJECT_IN_FLIGHT；**RE-29f** `max_active_slots.S7=TBD` 时拒绝 S7 新增风险，并拒绝含 S7 的批次 |
| RE-30 | a 第二实例启动；b 心跳超时后接管 | 两个实例同时启动的竞争；租约文件损坏；持有者在超时时间内重启；没有 Tick 时的心跳；测试器隔离；持有者续约失败 | **RE-30c** 两个实例同时启动，最多只有一个持有者；**RE-30d** 租约文件两槽都损坏，不交易并告警；**RE-30e** 持有者在超时时间内重启，能安全重新取得租约；**RE-30f** 周末或休市无 Tick，不误判超时；**RE-30g** 测试器不同 run_id 互不干扰；**RE-30h** 持有者续约失败，停新增风险、保护规则按 X9 处理 |
| RE-31 | a–l | 撤销 S7 挂单失败；其他策略挂单不被撤销的单独用例；锁定后仍在场的 S7 持仓平仓后的计数；服务器偏移／夏令时换日；账户级佣金无法归属；连续暂停与累计锁分开 | **RE-31m** 撤销 S7 挂单失败，保持锁定、重试并告警；**RE-31n** 只撤 S7 挂单，S1–S6 挂单不受影响；**RE-31o** 锁定时仍有 S7 持仓，平仓后照常计数，锁定不变；**RE-31p** 服务器偏移或夏令时变化当天按服务器 00:00 换日；**RE-31q** 账户级佣金无法归属，返回 DAILY_LEDGER_UNRESOLVED；**RE-31r** 连续暂停与每日累计锁分开登记，互不替代 |

以上用例都属于**实现阶段的验收**，不是 v1.1 冻结的前提。冻结前只需要把用例写进草案的验收矩阵。

## 六、RiskExecution 模块设计纲要（冻结后才实现）

- **模块划分：**
  - `RiskBudget`：单笔、策略、组合风险，保证金和 OrderCheck；
  - `ExecutionGateway`：审批登记、在途锁、发单、改单、撤单、平仓；
  - `Reconciler`：服务器订单、成交、持仓与 A/B 状态文件的对账；
  - `ProtectionManager`：退出队列、补设 SL、保本、追踪，SL 只收紧；
  - `LeaseManager`：独占句柄加心跳诊断；
  - `DailyLedgerS7`：按服务器历史重算；
  - `StateStore`：A/B 双槽加 SHA-256。
  
  所有交易 API 只出现在 `ExecutionGateway`。
- **执行顺序：** 严格按 v1.1 §2 步骤 1–4（对账、退出、保护）先于新增风险，任何门控都不能跳过前四步。
- **构建：** 故障注入只在 `#ifdef TEST_FAULT_INJECTION` 范围内。单元测试用可替换的交易与历史桩（Core 不直接交易），由 Codex 在固定终端上编译并运行测试器验收。
- **安全验收：** 每一个 RE 用例都写成不可变的测试请求，交给 Codex 执行；结果以原始日志和哈希为准，Claude 独立比对预期。不在实盘终端增加实例。

## 七、本分支对核对文件的修正

`contracts/drafts/planB_v1.1_consistency_check_claude_20261018.md`：
- 第 4 行的过期状态（“尚未合并 main”）改为当前准确状态；
- 第四节的合并条件改为遵守 AGENTS 的八项门禁和用户逐 PR 批准；
- 其余内容不变。

## 八、下一步

1. Codex 提交 G1、G3、G4、G5 的本地证据后，Claude 按第四节逐项独立复核，并把结果保存到 GitHub。
2. X1–X4、X6、X7、X9 需要 Claude 与 Codex 共同修改 v1.1 草案，修改须经双方复核。
3. 证据充分后另开 v1.1 升级 PR，写明八项，并由用户对该 PR 明确批准。**Claude 不会自行合并。**
4. 正式接口升级之前，Claude 不实现任何与未冻结接口冲突的交易功能。

## 九、2026-10-19 更正（依据 Codex 取证 f78ccd4 及 Claude 独立复核 56bba07）

| 项目 | 原写法 | 更正 |
|---|---|---|
| X10 | 根据 I18 第 1643、1659 行推断“非测试器路径不会阻止 S7 新增风险” | **范围错误。**该版本 OnInit 第 2038–2039 行拒绝所有非测试器运行，不能推断它在 Demo 或实盘可以绕过日锁开仓。保留的只是对新实现的要求：在所有模式下执行 `DAILY_LEDGER_UNRESOLVED`。改为不阻断的设计提示 |
| X11 | “连续暂停参数仍在，需核对实际效果” | `UpdateScalpPause` 只有第 6580 行的定义、没有调用点，没有旧连续暂停正在运行的证据。仍然不能据此删除或合并该规则 |
| S1–S6 行号与哈希 | 引用的是 I18 新候选 `candidates/…` | 第 18 轮保留版本是 `MT5_Current_Research/` 下的 7 套（S1 第 88 行、S4 第 84 行等）。magic 与槽位的数值相同，结论不受影响 |
| X8 补充 | — | G4 原生日志显示，测试器内的 `FILE_COMMON` 就是真实共享的 Common 目录，隔离只靠文件名中的 run_id |

复核全文：分支 `research/plan-b-claude-evidence-review-20261019`，`开发交易头脑EA/交易头脑v1.2/research/PLAN_B_20261019_CLAUDE_REVIEW/CLAUDE_G1_G3_G4_G5_REVIEW_CN.md`。
