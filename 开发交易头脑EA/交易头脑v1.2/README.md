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

一套主计划支持两种协作模式。LEAN（C#）承担离线研究，MQL5承担独立执行，候选经两端差异核对和MT5原生验证后再进入后续验证。复用现有运行时和资料库，不要求LEAN或其他辅助服务常驻。旧P1/P2保留原证据身份，原cTrader执行路线仍为历史；架构更新本身未完成新的迁移或联接；后续已执行的原生修复与测试另列于下方。

后续实际开发沿用原 `v1-2-ea-mt5` 工作区及固定 MT5 终端。本次没有把本地全部 EA 源码、EX5 或大包重新公开到 GitHub，没有创建空壳交易程序。跨电脑协作先取得已授权的匹配交付包并核对哈希；仅拿到这份骨架时，可审计划与报告，不声称已能编译 EA。

2026-10-04 最新实际测试：第十轮完成17场新MT5原生回测，复用12条完全同版同条件证据，共29行；3个新候选编译0错误、0警告。每场独立500美元，GOLD/M5真实Tick模式、名义1:1000，六月及八月均为已使用开发区间，主比较250ms；不能相加为连续账户或组合。

本轮有实际进展的是S2：只把推进版风险上限从1%调到2%，六月净利14.84美元、八月14.28美元（250ms），解除部分最小手数限制；列为下一轮研究主候选，原1%源码／EX5留作回退。两个月仅1／2笔交易，不能认定稳定盈利。S1恢复机制收益改善不一致，保留原1%版；S3、S4、S5、S6保留研究参考；Scalping六月亏63.79美元、最大相对净值回撤15.96%，保留失败对照，未通过跨期盈利检查。全组没有晋级Champion。

详见[第十轮中文成绩](research/evidence/MT5_ITERATION10_SEVEN_20261004_CN.md)、[English results](research/evidence/MT5_ITERATION10_SEVEN_20261004_EN.md)、[完整数据与差额](research/evidence/MT5_ITERATION10_RESULTS_20261004.json)和[交付哈希](research/evidence/MT5_ITERATION10_DELIVERY_20261004.json)。本轮仅同步研究文档与哈希；MQ5默认配置、匹配EX5、SET/INI、日志、原始报告及恢复版保留在本地交付包。评分N/A，LEAN没有新运行，独立OOS、组合、提款、Demo及实盘验证未完成。

历史第九轮测试：第九轮七策略研究完成18场新MT5原生测试，另复用S5完全同版同条件的2场；八月、独立500美元账户、GOLD/M5、模型4、名义杠杆1:1000、0/250ms。新增S1风险对照／动态降风险、S2推进确认和当前手册Scalping候选；失败及持续停机如实保留，未晋级Champion。

七套C#信号层已编译、67项边界断言通过；LEAN实际运行遭Windows应用控制拦截，跨引擎回放和风险／成交／退出迁移尚未通过。详见[第九轮中文成绩](research/evidence/MT5_ITERATION9_SEVEN_20261004_CN.md)、[English results](research/evidence/MT5_ITERATION9_SEVEN_20261004_EN.md)、[复审](research/evidence/MT5_ITERATION9_REVIEW_20261004.json)和[交付身份](research/evidence/MT5_ITERATION9_DELIVERY_20261004.json)。源码默认值、匹配EX5和完整回测包保留在本地；本仓只同步研究报告与哈希，不公开EA源码、EX5和原始成交。

历史第八轮测试：第八轮S5请求终态修复已完成，编译0错误/0警告，5场原生测试全部严格核账通过。交易逻辑与1%风险未改；四场为六月/八月0、250ms，八月1000ms另列故障复现。当前测试杠杆1:1000；保证金率/Stop Out及真实成本仍未校准，不能据此证明500美元实盘承受能力。

查看[第八轮成绩](research/evidence/MT5_ITERATION8_S5_RESULTS_20261004_CN.txt)、[复审](research/evidence/MT5_ITERATION8_FINAL_REVIEW_20261004.json)和[交付身份](research/evidence/MT5_ITERATION8_DELIVERY_RECEIPT_20261004.json)。旧[第七轮失败与延迟证据](research/evidence/MT5_ITERATION7_DELAY_20261003_CN.md)和[第六轮恢复依据](research/evidence/MT5_ITERATION6_20261002_CN.md)保留。新旧MQ5/EX5和完整包在本地工作区；本次不公开重传EA源码、二进制或原始成交。均为已用开发数据，尚无独立验证、连续组合、提款或实盘盈利证明。
