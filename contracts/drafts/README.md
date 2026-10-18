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

下一步：Codex 修改 F1–F3 → Claude 只核对这三处 → 一致即 FROZEN v1.0。正式文件在 contracts/risk_execution_interface.md。

所有文件均为规格文字：未编写 MQL5 代码、未编译、未回测。
