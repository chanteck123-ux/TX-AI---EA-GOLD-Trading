# 方案 B 整理与 RiskExecution v1.1 — Claude 侧一致性核对

分支：`draft/risk-execution-interface`。基于 Claude《方案 B 文档核对》（提交 8240e70）。
状态：Claude 已完成 B1–B3 修正和 v1.1 草案；**等待 Codex 核对，尚未合并 main**。未编写 MQL5、未编译、未回测。

## 一、本次完成的修改

| 项目 | 文件 | 修改 |
|---|---|---|
| B1 | `AGENTS.md` | 恢复被误删的“知识大脑与长期研究记忆”段落（含 gsm-mt5-indicators 读取规则），原文取自 main |
| B2 | `AGENTS.md` | 在方案 B 一节新增“协作模式选择”：方案 B 双 AI，或只用 Codex（Codex 负责 Core 与 RiskExecution，仍遵守冻结接口，不声称 Claude 参与）。规则只在此维护 |
| B2 | V1.2 `PLAN_CN.md` 第 9、50、58、145、362 行 | 改为引用 AGENTS 的协作模式选择，不再指向已删除的第 2 节 |
| B2 | V1.2 `COLLABORATION_CN.md` | 删除重复的模式选择列表，改为引用 AGENTS |
| B3 | 根 `README.md`、V1.2 `README.md` 第 3 行 | 旧分工改为引用 AGENTS 方案 B，并链接接口文件 |
| 命名 | V1.2 `PLAN_CN.md` §4.0 | S5、S6 采用用户规格 v1.1 原名，并注明名称与周期出处 |
| G1–G5 | `contracts/drafts/risk_execution_interface_v1.1_draft.md` | 以 v1.0 为基线起草 v1.1，变更摘要见文件开头 |

关于 B2：用户尚未明确回答是否保留“只用 Codex”模式。我按《方案 B 文档核对》的建议保留，因为用户只说采用方案 B，没有说取消该选项。**若用户决定取消，只需删 AGENTS 中一条**，其余文件已改为引用，不必再改。

## 二、AGENTS 方案 B 与接口 v1.1 逐项对照

| 检查点 | AGENTS 方案 B | 接口 v1.1 | 结果 |
|---|---|---|---|
| Core 责任 | Codex：EA Core、S1–S7 策略与指标集成、编译、唯一 Tester 队列 | §1：Codex 拥有 Core、指标和信号、整合、编译与唯一 Tester 队列 | 一致 |
| RiskExecution 责任 | Claude：风险预算、仓位、保证金、下单与 SL/TP、部分成交、对账、持久化、故障注入 | §1：Claude 拥有 RiskExecution（仓位/风险/订单/SL/恢复）及验收用例 | 一致 |
| 交易调用边界 | Core 只产生意图，全部交易调用经 RiskExecution | §1、§2：Core 不得直接调用交易 API | 一致 |
| 保护优先 | 已有仓位保护、退出、对账先于新增风险门控 | §2 唯一 OnTick 顺序，步骤 1–4 不得被提前 return 跳过 | 一致 |
| 测试队列 | Claude 提交不可变请求，Codex 独占执行与状态 | §7：Claude 只建 pending，Codex 单执行器唯一写入者 | 一致 |
| 接口变更 | 双方批准并升版本号 | §9 同 | 一致 |
| S7 日锁 | S7 USER_OWNED，保留仅该策略的 6 盈或 6 亏暂停 | §3.2（G5）：由 RiskExecution 执行，只作用于 S7 | 一致（v1.0 缺，v1.1 补） |
| 策略隔离、对冲 | AGENTS 未细列；用户规格 §0.1、§2.1 要求 | §4、§4.1（G1、G2）、§3.1（G3）、§6.2（G4） | v1.1 补齐 |

未发现 AGENTS 与接口 v1.1 的冲突。

## 三、请 Codex 核对的重点

1. **G1 magic**：在本地核对七个 TB500 EA 实际使用的 magic，填入 `magic_map`；与用户规格 6101…6601 不同时如实记录。
2. **G3 槽位**：确认 S7 现行源码的槽位上限（v1.1 暂列 TBD）；确认“S4 第二槽须等第一槽请求结束在途状态”不会与 S4 原有双槽行为冲突。
3. **G4 租约**：确认 `FILE_COMMON` 在固定终端（/portable 模式）下可用，以及回测按 run_id 隔离的写法。
4. **G5 日锁**：确认由 RiskExecution 计数与 PLAN §4.1 的全部验证点一一对应（v1.1 RE-31a–h）。
5. B1–B3 的文字修改是否符合文档维护习惯。

## 四、合并条件

1. Codex 完成上述核对；有异议的项目在 v1.1 草案中注明，双方处理。
2. 双方确认后，Codex 以 v1.1 替换 `contracts/risk_execution_interface.md`，状态改为 FROZEN v1.1（v1.0 原文保留在 git 历史）。
3. 一次合并到 main；`contracts/drafts/` 建议同时移到 `contracts/history/`。
4. 合并只代表文档和接口规格定稿，不代表任何代码已实现、编译或测试通过。
