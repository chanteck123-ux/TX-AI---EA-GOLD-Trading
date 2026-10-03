# 开发交易头脑 V1.2 黄金 EA

500 USD 起步，先验证成本后盈利、账户持续运作与提款可行性。**采用LEAN（C#）研究引擎＋MT5／MQL5执行；EA独立计算信号、交易和本地风控。每次新开发或接续研究前，先选择使用 Claude，或不用 Claude、只用 Codex；未选择不默认启动。** 使用 Claude 时双方讨论和复审，Claude 写改代码，Codex 编译／测试；只用 Codex 时由 Codex 完成全流程。当前请求已明确选择就不重复问，同一次任务内不逐步重问，具体按[计划第2节](docs/PLAN_CN.md#2-技术路线与职责)执行。

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

一套主计划支持两种协作模式。LEAN（C#）承担离线研究，MQL5承担独立执行，候选经两端差异核对和MT5原生验证后再进入后续验证。复用现有运行时和资料库，不要求LEAN或其他辅助服务常驻。旧P1/P2保留原证据身份，原cTrader执行路线仍为历史；本轮只确认架构，未完成新的迁移或联接。

后续实际开发沿用原 `v1-2-ea-mt5` 工作区及固定 MT5 终端。本次没有把本地全部 EA 源码、EX5 或大包重新公开到 GitHub，没有创建空壳交易程序。跨电脑协作先取得已授权的匹配交付包并核对哈希；仅拿到这份骨架时，可审计划与报告，不声称已能编译 EA。

2026-10-03 最新实际测试证据（早于本次架构更新）：第七轮冻结版本延迟测试完成10次原生运行，9次严格核验通过；S5八月1次审计无效、成绩N/A。S1/S3/S4/S5/S6各月独立500 USD，对照250/1000ms；S2只做诊断，Scalping复核既有证据。本轮没有改EA源码、重新编译、部署或晋级，原9组版本保留。

查看[第七轮成绩](research/evidence/MT5_ITERATION7_DELAY_20261003_CN.md)、[复审与下一步](research/evidence/MT5_ITERATION7_REVIEW_ADDENDUM_20261003_CN.md)及[第六轮恢复依据](research/evidence/MT5_ITERATION6_20261002_CN.md)。第七轮交付包1,124个文件已逐个核对哈希；包和MQ5/EX5在原本地工作区，身份见[证据索引](research/EVIDENCE_INDEX.json)。这些均为已用开发数据，尚未证明稳定盈利、提款或实盘可用。
