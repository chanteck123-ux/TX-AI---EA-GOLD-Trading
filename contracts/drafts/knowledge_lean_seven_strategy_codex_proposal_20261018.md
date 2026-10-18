# 七策略知识库、LEAN 与 MT5 执行框架统一审查 — Codex 提案（待 Claude 复核）

日期：2026-10-18。状态：**REVIEW REQUEST / NON-DESTRUCTIVE**。本文件仅发起 GitHub 异步讨论，**不代表 Claude 已读或同意**。不删除、不移动、不覆盖 main/Champion/策略源码、原始报告或历史 LEAN 快照，不运行交易。

## 1. 已核对的事实与范围

- main 树索引约 8,582 项，包含大量 QuantConnect 上游 snapshots；**已盘点文件路径及主要项目规范，并未逐一阅读全部 8,582 份文件**。先将上游快照视为只读外部知识库，与自有交易规则分离。
- 根 AGENTS.md 明确 V1.2 七策略、当前选定 LEAN C# 离线研究 + FxPro MT5/MQL5 独立执行、Claude 编写修改代码、Codex 协调验证。研究/CURRENT.json（2026-10-14）确认 seven_signal_modules_implemented=true，但 full_risk_fill_exit_migrated=false、cross_engine_acceptance=false。
- `开发交易头脑EA/交易头脑v1.2/docs/PLAN_CN.md` §2.1、§4.1 及 CURRENT 是 **V1.2 项目业务/策略规则**；`contracts/risk_execution_interface.md` FROZEN v1.0 位于 **draft/risk-execution-interface 分支**，尚未合并 main，属于待接入 V1.2 的跨模块执行契约。不能声称已部署或已通过验收。
- 旧 GSM 三 SOP 规范及 FINAL_CHAMPION_ITERATION_SYSTEM 属**不同项目/历史研究**，不得直接改写 V1.2；外部第三方代码须守许可证边界。
- 当前数据、回测与策略的状态以原始证据和对应源码/EX5/配置 hash 为准；旧结果不能当成七策略并发或独立 OOS 证据。

## 2. 建议权威层级（请 Claude 核对冲突）

1. **明确用户最新决定及项目作用域**：当前是七策略 V1.2；用户 Scalping 原有 M5 最近供需区回测、反转闭柱确认与 FxPro 服务器日 6 盈或 6 亏停该策略新仓的规则保持。
2. **执行契约**：冻结 `contracts/risk_execution_interface.md` v1.0 只定义 Core ↔ RiskExecution 交易执行、恢复、对账、测试证据边界。并入 main 前须核对与 V1.2 现有实现/账户风险及策略归属是否冲突；不可默默覆盖 V1.2 SOP。
3. **V1.2 研究与策略**：`AGENTS.md` + V1.2 `README.md` + `docs/PLAN_CN.md`；实时状态 `research/CURRENT.json` 和匹配原始 evidence。CLAUDE.md 只引用 AGENTS.md，不维护第二份相反规则。
4. **共享研究方法**：`docs/GSM_EA_RESEARCH_BRAIN_CN.md`、`research-memory/` 与当前评分/实验约定。旧 GSM 三 SOP / 旧 FINAL_CHAMPION 文件只在原项目内有权威，不是 V1.2 交易参数。
5. **历史及外部资料**：`docs/history/`、`gsm-sop/`、`research-library/QuantConnect-LEAN/snapshots/` 和第三方学习库只作带版本来源知识，不能自动执行、复制未经授权源码或覆盖策略。

## 3. 七策略登记（先确认身份，禁止擅自补造规则）

- S1–S6：六个独立研究/信号模块；详细规则、magic、当前保留版本及归属应由 Claude 对照 **实际最新源码** 与 PLAN、CURRENT、evidence 建立逐策略台账。
- Scalping：第七个独立策略，USER_OWNED；M5 → 最近有效 Supply/Demand → 回测 → 反转 K 线收盘确认 → 入场；只该策略受服务器日累计 6 盈 OR 6 亏的新增风险暂停规则约束，已持仓保护不中断。
- 七策略并行扫描**不代表七单同时获批**：所有 TradeIntent 走单一 RiskExecution，账户级组合风险、保证金、在途锁、实际成交风险重算统一执行；信号分数不等于开仓授权。
- 研究台账每行至少包含：strategy_id、SOP owner、实际入口/周期、magic、源码 commit/hash、配置、现存证据、已用开发数据、未见 OOS、风险/退出版本、当前研究状态、LEAN 覆盖、MT5 覆盖、缺口。无证据写 UNKNOWN，不以历史名称推定。

## 4. LEAN 方案供双方讨论

**建议维持双引擎，不把 LEAN 当成 MT5 实盘执行器：**
```
知识/指标研究 → LEAN C# 七策略离线信号与假设测试
                     ↓ 版本化 signal/decision 规范与审计
                   MQL5 七策略信号实现
                     ↓
              FROZEN RiskExecution v1.0
                     ↓
                 FxPro MT5
```
- LEAN 主要用于信号、状态机、数据时点、假设实验、参数研究及组合模拟；**不直接接管 MT5 下单或 SL**。不要以 LEAN 的默认 Fill/Margin/Fee 模型替代 FxPro GOLD 实际合约。
- 逐策略建立 **paired-run**：统一 symbol 映射、交易时区/闭柱、数据快照、bid/ask、spread、commission、swap、slippage、tick size、手数/保证金、交易日历、run_id 和配置哈希；先比每条信号与失效，再比仓位/风控/订单及 P/L。未解释差异为 FAIL/INCONCLUSIVE，不拿 LEAN 成绩替代 MT5 Real Tick。
- 研究优先顺序：先核对已有 S1–S7 信号模块和 LEAN 运行证据 → 选择一条有完整证据的策略做 LEAN↔MT5 逐事件对照 → 修复时点/成本差异 → 逐套扩展 → 七策略并发组合验证。当前并无完整跨引擎通过证据。
- Python 仅作 MCP 监控/报表，不构成 EA 开仓所需的在线依赖。QuantConnect 上游 snapshots 保留许可证和只读来源，不混入我们自有核心逻辑目录。
- 需明确：LEAN 策略 C# 与 MQL5 实现各自编译；共享的是**规格与事件记录**而不是把 C# 原样当 MQ5。

## 5. 已识别的冲突/混乱风险

| 风险 | 现象 | 建议处理（未执行） |
|---|---|---|
| 角色责任不一致 | V1.2 AGENTS 指 Claude 编写两端代码；冻结契约草案指 Codex Core、Claude RiskExecution | **必须由双方确认项目适用分工**：建议 V1.2 代码仍由 Claude 负责，Codex 为 Core 契约 owner/集成/测试审查者；不擅自覆盖 AGENTS |
| 项目规范交叉覆盖 | GSM 三 SOP/FINAL_CHAMPION 与 V1.2 七策略并存 | 明确 project_scope 与 supersedes/legacy 标签，旧资料不删除 |
| 研究端与实盘端误混 | LEAN 已有信号模块但未完成成交/退出迁移 | 分别记录 SIGNAL_IMPLEMENTED、PARITY_UNVERIFIED、MT5_NATIVE_VALIDATED 等 |
| 研究成绩冒充真实验证 | 旧月度数据反复调参、不同资本/杠杆 | 保留 data exposure、账户/成本模型与 paired run；OOS 独立 |
| 评分混淆 | 100分评分未冻结锚点 | 总分 N/A，保留原始净利、回撤、PF、交易数、成本 |
| 历史资料占据入口 | 上游 snapshots 数量庞大 | 只读 third-party index 与项目索引分层，不删除上游原件 |
| 版本权威冲突 | v1.0 契约只在 draft 分支 | 先对照 main 的 AGENTS/V1.2 代码及测试，后续经授权 PR 合并 |

## 6. 文件处理政策（防误删）

KEEP：冻结契约、当前计划、CURRENT、证据原件、七策略源码、所有成功/失败原始报告、许可证、用户 SOP。
INDEX：对重复说明只建统一导航，记录 canonical path + scope + date + source hash；旧入口加“历史/已被取代”说明。
ARCHIVE（待双方确认）：仅对已证明完全重复且无独立证据的**自有衍生说明**提出可逆移动；使用 git mv 并保留原 commit，先检查引用。
DELETE：**本阶段禁止**。不得删除源码、上游 LICENSE、回测证据、旧 SOP、失败候选、历史报告。
每个冲突条目要求：file_a / file_b、精确冲突语句、作用域、哪个是现行、来源依据、建议动作、回退路径、Claude 意见。

## 7. 请 Claude Code 在本分支回复（明确的异步交接）

请 Claude 读取本提案及 main 的 AGENTS、V1.2 PLAN、CURRENT、LEAN 研究记录、七策略最新源码与冻结契约，提交 `contracts/drafts/knowledge_lean_seven_strategy_claude_review.md`：
1. 七策略逐套实际源码入口、周期、Magic、SOP 来源、当前最优/保留候选与证据；UNKNOWN 如实标。
2. 列出 **精确冲突清单**（文件路径+章节/行+建议 canonical），重点核对 V1.2 代码责任人与 RiskExecution 契约责任。
3. LEAN：认可/反对双引擎方案及理由；现有七信号模块的覆盖与尚缺的风险/成交/退出、成本和跨引擎一致性。
4. 给出 KEEP / INDEX / ARCHIVE / DELETE 的逐文件建议；任何删除只提出，不执行。
5. 只读核对，不启动编译、回测或实盘；若需代码更改，另行确定候选与测试政策。

Codex 收到 Claude GitHub 实际审查提交后，才整合统一索引、冲突表和迁移计划；未收到前不得称为双方已讨论完成。
