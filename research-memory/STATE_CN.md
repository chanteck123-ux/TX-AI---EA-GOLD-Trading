# 当前研究状态与历史身份

计划入口更新：2026-09-12。本次没有实现 Candidate、编译 EA、运行 MT5 回测或更改 Champion。下文 2026-09-10 的事实和证据缺口保留其历史日期；需要执行时重新核对当前环境与证据。

核对日期：2026-09-10 UTC；main 快照 `eb74280c53e474e0dbcb0c10c491705689922416`。本页依据已读仓库文件和讨论整理，本轮没有运行新的 MT5 编译或回测。

| 对象 | 当前能确认的事实 | 证据 |
| --- | --- | --- |
| V4.00 历史交付 | `champion/current/` 中存在 ZIP、安装说明和 SHA256 清单。2026-09-04 的交付记录将其称为当时的 Research / Backtest Champion。 | [历史交付记录](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/issues/1#issuecomment-5535364150)、[安装修正记录](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/issues/1#issuecomment-5535624599) |
| 新研究下的 Champion | 已读 FxPro 研究分支及分析器 README 将四组合格 Champion 记为 NONE / 历史待验证基准。此整理不重新评选或撤换原包。 | [研究交付摘要](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/c75c488fa7c3feddf01de2edd9314f99e689d8fa/reports/RESEARCH_SUMMARY_CN.md) |
| R-C00 / R-C01 | 风险标准化与费用预算工程研究基线；与策略晋级区分。 | [R-C01 PR #3](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/3) |
| S-C01 | 最近区域距离排序实验已关闭，记录为无观察到的成交改善，不晋级。 | [PR #2](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/2) |
| FxPro 后续研究 | 分支保留源码、参数和研究摘要；S-C02 关闭 EMA 被拒绝，尾仓与组合结果未胜出。 | [草稿 PR #5](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/5) |
| Python 分析器 | 完整源码入口位于 `research/python/gsm-gold-analyzer-source-v1` 的 `python_analyzer/`，PR #7 是草稿。 | [分析器使用说明](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/e74983f50b42ac0ede891ff2472baefb78b429f0/python_analyzer/README_CN.md) |
| 当前 EA 研发计划 | 2026-09-12 根据用户指定的风险更新稿完整替换旧中英文总计划。原文历史完成项保持原日期；本次仅保存与翻译。 | [中文](../FINAL_CHAMPION_ITERATION_SYSTEM_CN.md) · [English](../FINAL_CHAMPION_ITERATION_SYSTEM.md) |
| 旧研发计划和六策略说明 | `research/codex/ea-plan-20260906` 中的资料作为历史来源保存；旧计划不再作为当前执行入口，六策略说明不自动合入当前三 SOP 路线。 | [历史资料](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/e634b2b966244ecc7f0aa38ef3d76ba01b0f6369/research/github) |

## 已消解的记忆混淆

- 原外部索引中的“Champion NONE / 尚无 current 目录”标明日期为 2026-08-31，应作为历史快照保存；2026-09-04 后存在交付包，不能继续按旧索引推断文件不存在。
- 同时保留“历史交付身份”和“按后续研究标准尚未晋级”的两种记录；包名含 CHAMPION 不足以证明通过所有最新验收。
- `C-C01` 在 V4.00 历史交付与后续组合研究中有同名使用。记录时必须附版本、分支和提交，不能合并其指标或结论。
- `samw2591/gold-quant-trading` 是当前连接只读的外部参考；自有 Python 分析器位于上表的研究分支。

## 证据缺口与继续工作

1. 后续实际研究前，先读取适用计划、冻结基准、数据与环境记录；本次目录不替代源码审计。
2. 依照已读研究记录保留 500 USD 最小手数可行性问题、M15/M5 入场研究与 Intraday/Swing 保护研究；不把这些计划写成已实现功能。
3. FxPro 研究预登记 OOS 为服务器日期 `[2026-09-08, 2027-03-08)`；记录为既有冻结计划，不在资料整理中读取其成绩、重新调参或宣称已经完成。
4. main 树中的 `champion/current/` 未单独列出清单里的 `src/GSM_Gold_3SOP_EA_CHAMPION.mq5`；本次未解压 ZIP，因此外置源码位置与包内映射待后续需要源码时核对。不会据此删除或补造文件。

本次完成目录、规则、分支与历史状态整理。未来任务按新增证据更新本页；旧报告和冻结文件保留原身份。
