# 分支、PR 与 Issue 目录

盘点日期：2026-09-10 UTC。记录当时状态，后续任务应核对变化。分支存在不代表已合并或已通过验收。

| 分支 | 固定提交 | 文件数 | 用途 |
| --- | --- | ---: | --- |
| `main` | [eb74280c53](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/eb74280c53e474e0dbcb0c10c491705689922416) | 18 | 稳定入口、历史基准与资料索引 |
| `research/codex/ea-plan-20260906` | [e634b2b966](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/e634b2b966244ecc7f0aa38ef3d76ba01b0f6369) | 23 | 研发路线、更新计划、六策略说明及资金资料 |
| `research/combined/codex/fee-rounding` | [44930b495f](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/44930b495f900008f3ef211c0256725cebb432e6) | 87 | R-C01 费用舍入工程修正；未晋级 |
| `research/combined/codex/fxpro-research-delivery` | [c75c488fa7](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/c75c488fa7c3feddf01de2edd9314f99e689d8fa) | 197 | FxPro 研究源码、参数与摘要；NO NEW CHAMPION |
| `research/combined/codex/risk-normalization` | [2f7a358672](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/2f7a3586729c7886b7beb74564fd79d5e21b6238) | 57 | R-C00 风险标准化研究记录 |
| `research/python/gsm-gold-analyzer-source-v1` | [e74983f50b](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/e74983f50b42ac0ede891ff2472baefb78b429f0) | 166 | 包含 python_analyzer/ 的分析器源码与使用说明 |
| `research/python/gsm-gold-analyzer-v1` | [8326fbab6e](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/8326fbab6ee8beb2a0db77aa1f1663e08c4bff41) | 108 | 分析器前置研究快照；与源码分支分开定位 |
| `research/scalping/codex/nearest-zone` | [78473bc5d6](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/78473bc5d6a4e7cc02ffee3efe576aad0ff7bec5) | 68 | S-C01 距离排序；拒绝为新 Champion 的历史实验 |

## 讨论与交付记录

| 编号 | 类型与状态 | 内容 |
| --- | --- | --- |
| [#1](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/issues/1) | issue；已关闭 | Champion EA 交付后记录到 GitHub |
| [#2](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/2) | pull_request；草稿；已关闭 | [REJECT / 不合并] S-C01 最近区域距离排序：真实 Tick 成交无改善 |
| [#3](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/3) | pull_request；草稿；开放中 | R-C01: FxPro 佣金预算修正及六组真实 Tick 核对（非 Champion） |
| [#4](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/4) | pull_request；草稿；开放中 | GSM EA 新研发计划：先校准风险与基线，再优化区域和进场 |
| [#5](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/5) | pull_request；草稿；开放中 | FxPro 3-SOP research delivery: real-tick evidence, no new Champion |
| [#6](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/6) | pull_request；开放中 | Research/python/gsm gold analyzer v1 |
| [#7](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/7) | pull_request；草稿；开放中 | GSM Gold Python Analyzer v1：离线导入、不开单诊断与中文报告 |

本次发现 0 个 GitHub Release。标签列表接口当前不支持，未将其记录为“没有标签”。压缩包内文件、完整历史提交和 Actions 产物不在本次内容审计范围。
