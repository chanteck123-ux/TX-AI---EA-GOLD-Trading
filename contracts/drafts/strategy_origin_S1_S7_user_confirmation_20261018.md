# S1–S7 策略来源归属 — 用户确认（2026-10-18）

状态：**USER CONFIRMED / PROJECT-SCOPE OWNERSHIP CLASSIFICATION**。本文件只登记项目内策略来源与核心修改权限，不判断法律版权/知识产权，不变更策略源码、RiskExecution v1.0、回测或实盘状态。

## 用户明确确认

用户原话：**“AI 根据我的方向研究、组合出来的”**，回答对象为 **S1–S6**。因此 S1–S6 的项目内 SOP 来源分类统一为 **NON_USER**（AI 根据用户方向研究组合），不再按 UNKNOWN 处理。用户指定保护的第七套 Scalping SOP 仍为 **USER_OWNED**；此分类表示核心修改审批要求，不表示其教材或通用交易概念的版权归属。

| 策略 | 当前描述（须与源码复核） | SOP 来源分类 | 研究/修改边界 |
|---|---|---|---|
| S1 | H1 趋势 + M15 回踩 + M5 触发 | NON_USER | 允许已授权 AI 研究、优化和替换候选 |
| S2 | Supply/Demand First Touch | NON_USER | 同上 |
| S3 | 突破后回踩 | NON_USER | 同上 |
| S4 | 伦敦/纽约动能 Scalping | NON_USER | 同上 |
| S5 | 布林带 | NON_USER | 同上 |
| S6 | 趋势 M/W 结构 + M15/M5 入场 | NON_USER | 同上 |
| S7 | 用户指定的 M5 Scalping SOP | USER_OWNED | 保留用户明确指定的核心；核心修改另获授权 |

## 执行约束

1. **NON_USER ≠ 可直接部署**：策略研究与修改仍须预登记、版本化、编译、MT5 原生验证、成本/风险检查、保留失败证据和用户授权的部署门槛。
2. S1–S6 不能因允许优化而绕过冻结的 `contracts/risk_execution_interface.md` v1.0；接口修改需双方批准并升版本号。
3. 第七套 Scalping 的用户核心保护包括 M5、最近有效供需区回踩、反转闭柱确认；服务器日 6 盈 OR 6 亏仅锁该策略新增风险，已有仓位保护继续。其外部教材/启发来源与用户制定的项目 SOP 权限是不同维度，需分别记录。
4. 表中策略名称和周期为项目描述；最新真实源码入口、magic、参数、当前候选及证据须由 Claude/Codex 逐套核对，不以本表取代源码事实。
5. 本确认优先于此前将 S1–S6 记为 UNKNOWN 的暂定讨论；建议 Claude 在 `contracts/drafts/knowledge_lean_seven_strategy_claude_review.md` 中引用本文件。若旧项目其他策略也称 S1–S6，须按 V1.2 项目作用域区分。

## 给 Claude Code 与 Codex 的行动

以此用户确认为策略来源权威，更新后续统一知识索引/冲突清单；核对实际源码与七套策略登记，保留历史来源、学习参考和失败研究，不自动删文件、不覆盖 main、不触发实盘。
