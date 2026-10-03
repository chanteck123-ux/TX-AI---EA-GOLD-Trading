# 开发交易头脑 V1.2 黄金 EA

500 USD 起步，先验证成本后盈利、账户持续运作与提款可行性。**MQL5 EA 独立执行交易和本地风控；Codex 与 Claude 共同讨论和复审，Claude 负责代码，Codex 负责测试验证与证据整理。**

| 现在要做什么 | 打开这里 |
| --- | --- |
| 看完整新计划 | [开发计划](docs/PLAN_CN.md) |
| 查看当前 Codex／Claude 分工 | [协作与交接](docs/COLLABORATION_CN.md) |
| 看目前做到哪一步 | [当前状态](research/CURRENT.json) · [证据与哈希](research/EVIDENCE_INDEX.json) |
| 登记下一轮候选 | [统一候选模板](research/candidate.template.json) |
| 看原计划及本次清理 | [路线调整与恢复](docs/CHANGELOG_CN.md) |

## 实际目录

```text
交易头脑v1.2/
├── README.md
├── docs/                       当前计划、协作和改动说明
│   └── history/                被替代的 LEAN 计划原文
├── research/                   当前状态、候选模板、证据哈希
│   └── evidence/               已有 MT5 与 LEAN 报告，分别标识
└── QUANTCONNECT_LEARNING_CN.md  可选参考入口
```

这里不再并排维护一套单 AI 框架和一套双 AI 框架，也不要求运行 LEAN、Railway、数据库或 Agent 常驻服务。LEAN 旧 C# 专项已做过工程回放，保留为可恢复的历史路线；MT5 与 LEAN 成绩不混排。

后续实际开发沿用原 `v1-2-ea-mt5` 工作区及固定 MT5 终端。本次没有把本地全部 EA 源码、EX5 或大包重新公开到 GitHub，没有创建空壳交易程序。跨电脑协作先取得已授权的匹配交付包并核对哈希；仅拿到这份骨架时，可审计划与报告，不声称已能编译 EA。

2026-10-03 状态：新计划已整理，新增研发和部署未启动。已有第六轮结果是开发样本证据，见 [原报告](research/evidence/MT5_ITERATION6_20261002_CN.md)。
