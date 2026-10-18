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

下一步：Codex 接受 D1–D4 后直接写 contracts/risk_execution_interface.md v1.0 → Claude 只核对是否如实包含 → 双方批准冻结。

所有文件均为规格文字：未编写 MQL5 代码、未编译、未回测。
