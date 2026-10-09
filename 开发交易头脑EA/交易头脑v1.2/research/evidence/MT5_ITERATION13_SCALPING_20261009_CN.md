# I13 Scalping 背景门研究报告（C1 H4 对齐、C2 ADX 逆向排除）

## 结论（来自正式证明，不是推荐入市）

- C1_H4_ALIGN：两个开发月的净 USD 没有同时高于父版（六月 43.41，八月 -13.35），**不替换，保留父版**。
- C2_ADX_ADVERSE_R1：两个开发月的净 USD 没有同时高于父版（六月 14.70，八月 -14.57），**不替换，保留父版**。

范围：GOLD M5，真实 Tick 模型 4，500 USD，杠杆 1:1000，执行延迟 250 ms；2026 年 6 月和 8 月是**已使用过的开发月，不是样本外**；两个月账户相互独立，不相加。固定评分政策为 N/A（SCORE_TARGETS_UNSET）。对照只用父版正式验证（I10 六月、I9 八月）的账户数字；任何"被门拦下的父版交易子集"都不是成绩，本报告不使用。

## 1. 逐月对父版（均来自正式证明）

| 候选 | 月份 | 父版净 USD | 候选净 USD | 差额 | 父版笔数 | 候选笔数 | 父版 PF | 候选 PF |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| C1_H4_ALIGN | JUNE | -63.79 | -20.38 | 43.41 | 44 | 16 | 0.56 | 0.60 |
| C2_ADX_ADVERSE_R1 | JUNE | -63.79 | -49.09 | 14.70 | 44 | 39 | 0.56 | 0.61 |
| C1_H4_ALIGN | AUGUST | 48.05 | 34.70 | -13.35 | 42 | 23 | 1.44 | 1.83 |
| C2_ADX_ADVERSE_R1 | AUGUST | 48.05 | 33.48 | -14.57 | 42 | 37 | 1.44 | 1.40 |

说明：C2_R1 六月这一场的原生测试已完整结束（23,679,824 ticks / 6,023 bars，Test passed），但运行包装器保存日志时因 MT5 自动轮换日志而报 JOURNAL_ROTATED。Codex 在不重跑的前提下恢复了全部产物，由专门的“恢复审计”验证器出具单独的正式证明；原始 FAILED 回执原样保留，这一场不是原 runner 的成功。

| 候选 | 月份 | 父版净值回撤 USD（%） | 候选净值回撤 USD（%） | 父版每往返手成本 | 候选每往返手成本 | 父版净期望/笔 | 候选净期望/笔 |
|---|---|---:|---:|---:|---:|---:|---:|
| C1_H4_ALIGN | JUNE | 81.35 (15.96%) | 31.29 (6.12%) | 12.70 | 8.00 | -1.45 | -1.27 |
| C2_ADX_ADVERSE_R1 | JUNE | 81.35 (15.96%) | 62.55 (12.37%) | 12.70 | 13.31 | -1.45 | -1.26 |
| C1_H4_ALIGN | AUGUST | 29.21 (5.30%) | 13.94 (2.74%) | 7.62 | 8.00 | 1.14 | 1.51 |
| C2_ADX_ADVERSE_R1 | AUGUST | 29.21 (5.30%) | 15.59 (2.87%) | 7.62 | 7.90 | 1.14 | 0.90 |

## 2. 门的三个阶段（放行 ≠ 请求 ≠ 成交）

| 候选 | 月份 | 评估 | 放行 | 拒绝 | 缺数据 | 放行后被后续门拒绝 | 已准备订单 | 请求被接受 | 真实成交完整笔数 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| C1_H4_ALIGN | JUNE | 46 | 17 | 29 | 0 | 1 | 16 | 16 | 16 |
| C2_ADX_ADVERSE_R1 | JUNE | 46 | 40 | 6 | 0 | 1 | 39 | 39 | 39 |
| C1_H4_ALIGN | AUGUST | 43 | 23 | 20 | 0 | 0 | 23 | 23 | 23 |
| C2_ADX_ADVERSE_R1 | AUGUST | 43 | 38 | 5 | 0 | 1 | 37 | 37 | 37 |

被门拒绝的首次触碰仍被消耗（父版语义），所以门改变的是之后整个信号序列，不是简单地删掉几笔交易。

## 3. 接口故障的如实记录

C2 的原始版本在库指标 `GSM_ADX_Trend_Meter` 的初始化上失败（日志重复出现"算法枚举无效"）。**我们两边（Claude 与 Codex）的接口复核都漏掉了库文档里的规则**：`iCustom` 显式传参时，每个 `input group` 占一个字符串位置槽（文档第 143 行起，位置 0 是算法分组，ADXMethod 在位置 1）。冻结的 C2 传入 `(0,14)`，于是 `14` 落进 ADXMethod。这个原因来自库文档和指标源码；对修复版的**原生证明**是指标自己在日志里输出的 `GSM_ADX_INIT | GOLD M5 | method=0 period=14`。原始 C2 六月尝试没有任何策略成绩，也没有被用于任何对比；随后又因为把约 2.7 GB 的 agent 日志一次读入内存而失败，完整原始日志已压缩保存并有哈希。

修复版证明：日志中的库初始化行 1 条，method=0，period=14，状态 LIBRARY_INSTANCE_INITIALISED_WITH_WILDER_14。

## 4. 没有证明的东西

- 两个开发月已被使用，不是样本外；没有独立验证、Demo、Champion 或部署。
- LEAN 对 I13 候选仍是**待办**：没有新候选的信号镜像和新的 LEAN 运行；旧的 Windows 应用控制阻断没有被绕过。
- 严格单进单出归组，不支持部分成交；重启、多实例、异步事务未测试。
- 成本和保证金未校准；评分为 N/A。
- Node 的 Wilder ADX / H4 EMA 复制品只是诊断，不是库值或经纪商 H4 的证明；库值的审计依据是 EA 在每次决策时记录的缓冲区值。

## 5. C# 离线镜像（NOT_LEAN）

标签 OFFLINE_CSHARP_MIRROR_NOT_LEAN；输入为 MT5 原生导出的 bars 和 EA 的 I13_GATE 日志，**不是自己生成的输入**。
- C1_JUNE (C1_H4_EMA50_200): EQUAL_WITHIN_DECLARED_TOLERANCE（比较 46 个决策，最大差 4.983121471013874E-09，决策翻转 0）
- C1_AUGUST (C1_H4_EMA50_200): EQUAL_WITHIN_DECLARED_TOLERANCE（比较 43 个决策，最大差 4.977664502803236E-09，决策翻转 0）
- C2_JUNE (C2_ADX_M5_WILDER14): EQUAL_WITHIN_DECLARED_TOLERANCE（比较 46 个决策，最大差 4.955785115612343E-09，决策翻转 0）
- C2_AUGUST (C2_ADX_M5_WILDER14): EQUAL_WITHIN_DECLARED_TOLERANCE（比较 43 个决策，最大差 4.986233648196503E-09，决策翻转 0）
状态 NOT_PROVEN_EQUAL 表示实际差额超出了事先声明的容差或存在决策翻转，已如实报告。

## 6. 证据链

- 对比数据：`COMPARISON_I13_VS_PARENT.json` sha256 `4adc8fe2eaca18f97c00e1466a32c92d5a3ef889af1223886d32f262c553b58c`
- C1_H4_ALIGN JUNE：证明 `VERIFICATION_C1_JUNE_DELAY250.json` `e543deb459c9f9557a84d5cd5087264cd302ea7252fd21f2f387d033b40556a4`；父版证明 `9bb69ad4047eb273866c45a3b6925c94f0355d536a1afb6e5bc7b386808afc52`
- C2_ADX_ADVERSE_R1 JUNE：证明 `RECOVERED_VERIFICATION_C2_JUNE_DELAY250_REPAIR1.json` `ce9259bb5c280967dd4b190ebda54f3170a4cb0f905933c12a59b9ebb596a2a5`；父版证明 `9bb69ad4047eb273866c45a3b6925c94f0355d536a1afb6e5bc7b386808afc52`
- C1_H4_ALIGN AUGUST：证明 `VERIFICATION_C1_AUGUST_DELAY250.json` `f39f7cd5b73bd02e98d69d77f2431005ff562ec28e9abb742c5850de28dceef6`；父版证明 `d9c3cd283cc22a2683337d15955d8c617f008d1ab28269ef305d3dd5cf89bcd8`
- C2_ADX_ADVERSE_R1 AUGUST：证明 `VERIFICATION_C2_AUGUST_DELAY250.json` `77bfc843dcd56d58e7e33ac82f75d07b1e7290e87cd197689962d3efde2f716e`；父版证明 `d9c3cd283cc22a2683337d15955d8c617f008d1ab28269ef305d3dd5cf89bcd8`
- 共享尝试账本：已用 5 / 8，失败不清零。
