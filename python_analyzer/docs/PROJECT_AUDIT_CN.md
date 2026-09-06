# 当前 GSM 黄金 EA 项目审计

本文件记录本次实际读取的源码、参数、SOP、报告与资料边界。Analyzer 是离线研发工具；本次未连接账户、未编译 EA、未运行 MT5，也未修改原版 EA 和参数。

## 版本与证据状态

| 项目 | 实际读取结果 |
|---|---|
| 仓库 | `chanteck123-ux/TX-AI---EA-GOLD-Trading` |
| main | `eb74280c53e474e0dbcb0c10c491705689922416` |
| 冻结 R-C01 | `research/combined/codex/fee-rounding`，`44930b495f900008f3ef211c0256725cebb432e6` |
| 最新研究实现 | `research/combined/codex/fxpro-research-delivery`，`8326fbab6ee8beb2a0db77aa1f1663e08c4bff41` |
| 最新主文件 | `src/GSM_FxPro_RESEARCH.mq5`，MetaEditor 属性版本 `4.23` |
| 计划文档分支 | `research/codex/ea-plan-20260906`，`f0b690d15ef4f726eca0c771d2357bab0487e233` |
| 合格 Champion | Scalping、Intraday、Swing、Combined 均为 `NONE` |

以上为此次读取时的固定提交，后续分支可能继续更新。R-C01 是冻结工程基线；交付示例来自更早的 V4.00 真实历史回测，应称为“历史待验证基准”。文件名中的 `CHAMPION` 仅保留原始名称，不代表满足当前验收标准。

主要证据：[最新研究 README](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/8326fbab6ee8beb2a0db77aa1f1663e08c4bff41/README_RESEARCH_CN.md)、[续做记录](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/8326fbab6ee8beb2a0db77aa1f1663e08c4bff41/research/RESUME.md)、[当前源码](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/8326fbab6ee8beb2a0db77aa1f1663e08c4bff41/src/GSM_FxPro_RESEARCH.mq5)。

## 三策略实际边界

| 引擎 | Magic | 读取到的实际行为 |
|---|---:|---|
| Scalping | 26082152 | M5，Fresh 区域、Departure、First Touch、收盘反转、RSI 和 EMA。当前冻结 SET 使用课程 SL80/TP70，即价格距离8/7。没有保本、追踪、部分平仓或尾仓。 |
| Intraday | 26082102 | M30 方向与区域，每 tick 检查 First Touch。冻结 SET 为 SL120/TP70，即价格距离12/7；不能用源码默认 TP240 覆盖。默认未启用收盘确认；虽然 `InpIntradayConfirmationTF=M5`，不代表确认模块已生效。 |
| Swing | 26082303 | D1/H4 框架、H4 区域，默认 M30 反转或假突破确认。已有保本及 H4 ATR 追踪，止损只能收紧。 |
| Combined | 保留各自 Magic | 三引擎以 OR 独立运行、独立状态和统计。每策略一仓、组合三仓；组合成绩必须来自实际 Combined 运行。 |

源码 `OnTick` 先管理已有持仓，再分别执行三个引擎。策略开关停新仓，不应取消已有仓位的必要管理。最新用户要求的 Intraday/Swing M15 或 M5 进场属于后续研究要求，读取到的实现仍有 M30 默认路径；不能把计划文字当成已经实现或通过回测的行为。

原 ZIP 的 `DOCS/SOP_*.md` 含 V3.20 快照，例如 Scalping 50/50、Intraday 120/240。Analyzer 应同时记录资料版本、实际 SET 与源码，不用旧快照覆盖当前冻结参数。无法消解的差异标记 `SPEC_MISMATCH`。

## 已有研究结果：哪些不能再当成未经测试的想法

1. S-C02 仅关闭 Scalping EMA 的真实测试已被拒绝。同条件 USD2000、1:100、2026.01.05–2026.08.26、真实 Tick、0ms：净利润从 +129.18 变为 -54.56 USD，最大净值回撤从1.57%变为7.76%，PF从2.54变为0.92，完整仓从20增至83。更多交易未带来改善；本轮继续保留 EMA。
2. I-C01 取消每日次数上限后仍只有4笔交易，不能把次数上限当成已经证实的主要瓶颈。
3. I-C02 首轮 +7.66 USD、1笔完整仓被标记为工程无效证据，不可用于比较尾仓收益。最初的历史同步延迟解释只是假设；原生探针发现缺少 `HistoryOrderSelect`。仅等待的 FIX1 未修复，研究副本 FIX2 增加显式选择后，需要重测四组 OFF 控制及 runner 候选。

这些为远程研究记录，不是本次 Analyzer 重新执行的实验。远程 tree 没有上述新研究 `reports/runs` 原始 HTM、SET、INI、日志、DEALS 文件；摘要中的 Windows 路径与哈希不能替代取得原始文件。

证据：[S-C02 已拒绝记录](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/8326fbab6ee8beb2a0db77aa1f1663e08c4bff41/research/rejected/S-C02_EMA_ABLATION_CN.md)、[I-C02 工程失败及修正说明](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/8326fbab6ee8beb2a0db77aa1f1663e08c4bff41/research/I-C02_ENGINEERING_FAILURE.md)。

## 本版真实导入样本

`examples/fxpro_v400/source_manifest.json` 记录原始路径、SHA256、编码及口径。样本为同一次 `V400_C-C01_FULL_FxPro` Combined 回测，包括原生 HTM、TRADE_REVIEW、SIGNAL_AUDIT、SIGNAL_FUNNEL 和实际 SET。它与明确标记的合成演示数据分别使用。

原始报告：FxPro-MT5 Demo，Build6140，GOLD，USD500，1:100，2026.01.05–2026.08.26，声明“100%真实报价”。旧版使用固定0.01手，实际初始风险可超过新研究1%上限，因此不可与新风险标准化2000USD结果直接排名。

| 范围 | 完整仓数 | 净利润 USD |
|---|---:|---:|
| Scalping | 20 | 64.39 |
| Intraday | 4 | 28.66 |
| Swing | 1 | 0.66 |
| 本次真实 Combined | 25 | 93.71 |

组合25仓中盈利20、亏损5；按完整仓净额计算 PF 为 `135.29 / 41.58 = 3.2537277537`。原生 HTML PF 是 `3.21`，应原样保留并注明口径差异。TRADE_REVIEW 的 `Profit` 来源于持仓生命周期 Profit、Commission、Swap、Fee 合计，不能再重复扣费用。

原生报告最大余额回撤金额为9.32 USD，对应1.66%；最大相对余额回撤为1.72%，对应8.73 USD。最大净值回撤金额57.69 USD，最大相对净值回撤9.48%。金额最大的回撤与百分比最大的回撤不能混用。

原生 HTM 的成交表没有 Magic 或 PositionID。该旧版简单持仓可结合 TRADE_REVIEW 的 PositionID、ExitDeal 与订单、成交细节核对；复杂或模糊关联应标记未验证，不能只按时间或买卖方向猜测。原生 HTM 引用的四张 PNG 不在解包目录，Analyzer 自行生成图表；原 HTM 不作任何修改。

## 日志与漏斗口径

已有开关：`InpEnableFilterAuditLogs`、`InpEnableSignalAuditCSV`、`InpEnableTradeReviewCSV`。现有函数 `PrintFilterAudit`、`WriteSignalAuditCSV`、`WriteSignalFunnelCSV`、`PassStrategyFilters` 及 `OnTradeTransaction` 可供诊断副本扩展，不必重新设计交易逻辑。

- SIGNAL_AUDIT 是已记录的候选评估事件，包含 SOP、Magic、方向、ZoneID、ClusterID、RawCore、IndicatorPassed、ConfidencePassed、GatePassed、Accepted 与 RejectReason。
- SIGNAL_FUNNEL 是每轮/每策略的累计计数。EMA 与 RSI 拒绝可重叠，扫描区域、形态数量也不是逐级嵌套集合；不能直接用相邻计数相减归因。
- 关闭的引擎仍可能扫描到区域。读取 SET 的启用状态后再解释，不能将这些扫描称为本轮有效开仓候选。
- 最小手数超预算属于发送订单之前的本地阻挡，不属于券商拒单；没有请求时拒单为0不证明执行可靠。
- 仅凭成交记录不能确定没开单原因；缺少日志时输出“无法判断”。

已取得样本中，Scalping 1195次 FirstTouches、205次 HardSOPPassed、20次最终Gate及成交；Intraday 391次HardSOP、5次Confidence、4次成交；Swing 8次FirstTouches、5次HardSOP、1次成交。EMA/RSI计数重叠，不能相加声称错失多少独立盈利机会。

源码函数名 `HeuristicLossClassification` 已说明亏损分类是启发式标签。真实样本的20个Scalp仓都标记 ChaseEntry=YES、5亏仓都标记 ENTRY_TOO_LATE；这不证明全部亏损由追价造成。MFE/MAE 来自逐tick价格浮盈估计，不含完整交易费用，且退出跳价可能使最终净利大于记录MFE；不能把这些数据当成完整净值路径或确定因果。

最新研究 `src/StudyEvidence.mqh` 另外导出 `_DEALS.csv` 和 `_NATIVE_STATS.csv`。DEALS含 Deal、PositionID、Magic、Symbol、Entry、Type、Volume、Price、Profit、Commission、Swap、Fee、TimeMsc、Order、Reason。Entry=0为入场，1/3为退出；2为反转，需明确适配。只有累计入出量匹配的持仓才计为完整交易，分批退出不能增加完整交易数。

## 原生 Recovery 差异

仓库记录 FxPro build6182 的 Swing 控制：Net=0.66、BalanceDD=0.04、EquityDD=47.62，原生Recovery=0.0138597228，与权益分母一致；这与当时官方文档的余额分母定义存在差异。适配器保留原值并显示 `NativeRecovery`，保留原 CSV 遗留字段名 `NativeBalanceRecovery` 以便追溯，同时独立计算余额与权益两种比值，标记 `NATIVE_RECOVERY_DEFINITION_MISMATCH`。不将单个终端观察推广为所有 MT5 的定义。

证据：[原生统计差异记录](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/8326fbab6ee8beb2a0db77aa1f1663e08c4bff41/research/NATIVE_STATISTICS_DISCREPANCY.md)。

## 数据覆盖与仍缺资料

当前取得的10份 FxPro 原生HTM最早开始2026-01-05，最晚结束边界2026-08-26。报告声明的真实Tick质量属于报告证据；本次未取得原始Tick/OHLC、tkc/bi5或可独立复核的覆盖清单。

- 2024-03开始的真实Tick覆盖未证实；2024-03至2026-01-04没有可用覆盖证据。
- 原始Tick完整性、缺口、跨日及交易时段缺失尚不能独立检查。
- 缺少完整权益时序；不能用余额曲线冒充权益曲线，也不能由仓位MFE/MAE拼成组合权益曲线。
- 未取得服务器时区与DST映射；保留服务器未知时区，不擅自转换为UTC或马来西亚时间。
- 旧样本未包含原始合约规格日志。课程单位、Symbol Point、Tick Size需分别记录，不假定相同。
- 缺少当前候选的完整原生报告、逐笔成交、执行日志和费用/延迟/规格快照。摘要可作为历史证据索引，不能代替原始导入。
- 2026已查看区间全部属于已观察历史；文件名中的旧“OOS”不能重新标记为最终未见样本外。

选定的五份原始示例文件已检查表头、设置、报告元数据和文本，未发现个人姓名、登录号、密码、邮箱或账户凭据；保留的是公开券商/演示服务器名称及本次回测的模拟订单ID、Magic。没有打包账户配置或终端缓存。

## 下一轮最多三个验证方向

1. **工程风险恢复**：优先验证开仓历史显式选择修正与四组OFF控制一致性，分开检查风险预留及runner恢复；工程修复不冒充新增收益。
2. **进场位置/周期**：在保持高周期SOP、固定保护和风险预算的前提下，Intraday或Swing先单独比较一个M15/M5触发模块；现有标签先作为假设，不根据少量亏损直接删保护。
3. **利润保护阶段**：针对已有Swing回吐观察与Intraday尾仓，分别验证成本保本、服务器确认、追踪状态和重启恢复；一次只改一个引擎的一个退出模块。

候选最终行为仍需同数据、同资金、同风险、同费用的 MT5 真实Tick回测。低样本、工程失败、数据不足、最终样本外或压力测试未完成时维持“待验证”；结果不好如实保留，不重复试验直到偶然碰出好成绩。
