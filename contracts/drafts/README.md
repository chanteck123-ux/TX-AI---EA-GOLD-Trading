# 接口规格草案区

本目录只放尚未冻结的接口规格草案，供 Codex 与 Claude 交接审查。冻结后的正式版本移到 `contracts/risk_execution_interface.md` 并合并到 main。

| 文件 | 作者 | 状态 |
|---|---|---|
| risk_execution_interface_v0.1_codex_draft.md | Codex | v0.1 草案，暂不冻结 |
| risk_execution_interface_v0.1_claude_review.md | Claude | 对 v0.1 的审查、失败状态码、RE-01～RE-22 验收用例 |
| risk_execution_interface_v0.2.md | Codex | v0.2 整合版，暂不冻结 |
| risk_execution_interface_v0.2_claude_review.md | Claude | v0.2 最终审查：M1–M6 修改、P1–P5 待决提案 |
| risk_execution_interface_v0.3.md | Codex | v0.3 整合版，M6/P1/P3 有条件接受 |
| risk_execution_interface_v0.3_claude_diff_review.md | Claude | v0.3 差异复核：D1–D4 补充，建议接受后直接冻结 v1.0 |
| risk_execution_interface_v1.0_claude_final_check.md | Claude | v1.0 最终核对：有条件确认，F1–F3 改完即冻结 |
| knowledge_lean_seven_strategy_codex_proposal_20261018.md | Codex | 七策略知识库、LEAN 与执行框架统一审查提案 |
| knowledge_lean_seven_strategy_claude_review.md | Claude | 对上述提案的审查：七策略台账、冲突 K1–K7、LEAN 意见、文件处理建议 |

接口规格：FROZEN v1.0（F1–F3 已于 8a48a8f 落实，Claude 已确认）。七策略统一审查：等待用户决定 K1 作用域、K2 迁移方式与 S1–S6 来源。

所有文件均为规格文字：未编写 MQL5 代码、未编译、未回测。
