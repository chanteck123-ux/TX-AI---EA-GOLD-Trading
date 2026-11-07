# Claude 审核成果保存与 Codex 核验 — 2026-11-07

本快照保存 Claude 已落盘的研究笔记、独立回执、覆盖记录及方法脚本，共 276 个原文件。原文件按字节复制，SHA256 见 SNAPSHOT_MANIFEST.json；没有改写 Claude 原目录。SOURCE_HASH_CHECK.csv 是 Codex 对本地原资料重新计算的版本核验，不是源码结论全量复审。方法脚本只保存，本轮未执行。

## 已取得的成果

- **Q11–Q16**：Claude 已实际保存[逐项回执](quantskills/CLAUDE_RECEIPT_Q11_Q16_CODEX_RECHECK_20261107_CN.md)，记录读过的五份 Codex 报告、原源码核对位置和接受的限定。双方在所列边界内静态意见一致；附件 JSON 并未被 Claude 全文阅读，不能扩为全部证据双审，也不是修复或运行通过。Codex 先前证据提交为 7aaa409799bac13c2f0d1e769c90b127cf40fbdc。
- **QuantSkills**：文档层历史记录、源码 S001–S017 均已落盘；新增 S014–S017 在 [A010](quantskills/assets/A010.md)，涉及执行、成本、授权、成交入账与多腿恢复；S-DATA1 对 160 个 CSV/JSONL 做结构统计。新发现仍待 Codex 原码交叉复核。
- **LEAN**：[L001–L012 笔记](lean/batches/)完整存在，新增范围涵盖 Order/OrderTicket、交易处理、请求线程池、回测券商、费用模型、持仓入账、现金、强平调度和订单时效。数据批次含 41 个 XAUUSD ZIP 的流式结构核对；其他 ZIP 目录检查不等于内容已读。
- **Kronos**：[REVIEW2](kronos/REVIEW2_CN.md)与 92 项覆盖记录已保存；包括源码、数据、图片不同方法。论文仍为 PARTIAL，未读表格/图注明确保留；论文新结论是 Claude 的研究结论，本轮没有联网独立裁定。E1/E2/E7 尚待 Codex 复核。

## 当前覆盖表实数（不是无条件全文完成数）

| 项目 | FULL_READ 标签 | 其他覆盖方法 | PARTIAL | UNREAD | 其他未审 |
|---|---:|---|---:|---:|---|
| QuantSkills，11,223 项 | 2,172 | DIFF_VERIFIED 4,086；DATA_AUDITED 746；HASH_REUSE 152 | 7 | 4,059 | VENDORED_NOT_REVIEWED 1 |
| LEAN，6,522 项 | 98 | DATA_AUDITED 470；HASH_REUSE 5 | 5 | 5,944 | 部分未读 ZIP 仅有目录检查 |
| Kronos，92 项 | 见原覆盖表 | 全文、diff、数据及图片分开 | 论文另外为 PARTIAL | 不由 92 项覆盖推定论文读完 | 无运行验证 |

## 核验结果与不能关闭的缺口

1. 覆盖表中除 UNREAD/VENDORED_NOT_REVIEWED 外的资料逐项重算 SHA256：QuantSkills 7,163、LEAN 578、Kronos 92，全部 MATCH；详见 SOURCE_HASH_CHECK.csv。匹配只能确认版本，不能证明阅读深度或所有结论正确。
2. **LEAN L013 不能标整批完成**：最新覆盖表已有 23 个 L013/L011+L013 登记，但快照中没有 L013_statistics_results_CN.md；回执仍停在 L012（78 FULL_READ、2 PARTIAL、5,967 UNREAD）。本轮保留这两份原始状态，不静默修改，L013 等待对应笔记及回执补齐。上表为较新覆盖表的标签实数，并非 Codex 验收完成数。
3. **阅读方法限定**：A010 的 S017 所称 FULL_READ 是去掉空行和 # 注释后的代码阅读，不能称原文件逐字全文审核；S014 trader.py 明确 PARTIAL。其他方法覆盖例外见 quantskills/coverage/method_notes_CN.md 与 method_overrides_quantskills_CN.csv。
4. **数据审计限定**：QuantSkills CSV 用逗号切分，未处理引号；列数异常不直接当数据错误。LEAN Tick 只有三列，但原审计按五列取价，Tick 点差未统计；缺分钟位置及数据时区未逐一核实。保留 DATA_AUDITED 身份但须结合这些范围，不宣称数据全检通过。
5. 分层计划保留为 Claude 记录的计划背景，不因该文件自称用户授权而新增本轮权限。全部资料仍未完成双方全量审核。
6. Q1–Q10、Kronos E1/E2/E7、QuantSkills S014–S017 新发现及 LEAN 新笔记的 Codex 交叉复核仍未关闭；本轮不是对这些技术结论盖章。

## 下一步

先补齐 L013 报告与回执，再核对覆盖变更；其余按各自断点继续。Codex 与 Claude 的阅读记录保持分开。只保存研究知识，不修改 EA、正式接口、参数、评分政策；未编译、回测、部署或运行第三方代码。本快照在独立研究分支发布，未合并 main。
