# 两个 GitHub 黄金 EA 仓库：源码研究记录

检查日期：2026-09-06。执行者：Codex。用途：后续 FxPro GSM 3-SOP Candidate 开发参考。

**结论：两库都有研究价值，但都不能直接作为你的新 Champion，也不适合整套移植。**
本轮未修改 EA、SET、Champion ZIP 或实盘设置；未运行外部脚本、第三方 EA、编译或交易回测。下面是静态源码检查，不是收益验证。

## 1. 固定版本与阅读范围

| 来源 | 本次线上 HEAD 与本地 HEAD | 文件数 | 判断 |
|---|---|---:|---|
| [GoldTraderEA](https://github.com/mehdi-jahani/GoldTraderEA/tree/ba329266c56372c36da9f81fac35983b9fc2e4a3) | `ba329266c56372c36da9f81fac35983b9fc2e4a3` | 18 | 形态与价格行为研究来源 |
| [EA_SCALPER_XAUUSD](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/tree/b0087e93c8af6690102c6698b8123186703a9240) | `b0087e93c8af6690102c6698b8123186703a9240` | 1,054 | 工程架构与验证方法研究来源 |

已完成全部 1,072 个 tracked 文件的路径、分类、Git blob、工作文件 SHA256 和大小清单；支持的文本类型另做内容索引。**自动扫描不等于逐行读懂。**
本轮对 27 个文件进行指定范围阅读或数据解析，重点是信号、区域、风险、执行、持仓管理和验证链路。精确范围在 `REVIEW_COVERAGE.csv`。
987 个文件成功进行文本索引；12 个文件未通过严格 UTF-8 读取，保留文件和 hash 清单但不声称已读懂；另 73 个二进制或未归类文件未载入内容。具体状态见 `FILE_INVENTORY.csv`。
第二库含 524 个标准库、工具库或备份目录文件，不把这些误算成 524 个原创策略。其 `MQL5/Include/EA_SCALPER/` 有 59 个项目文件，均已建立模块索引。
未逐行审计其全部历史文档、所有 Python 脚本和标准库，也未验证二进制模型。不要把本报告描述成“全仓库无缺陷认证”。

## 2. 使用边界

- GoldTraderEA：本次完整 tracked 清单没有独立 LICENSE/COPYING/NOTICE；README 的公开源码措辞不是明确的复用许可。不得据此复制源码进正式产品。
- EA_SCALPER_XAUUSD：根目录 https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/LICENSE 是 PolyForm Noncommercial 1.0.0；https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/TRADING_RESTRICTIONS.md 还明确限制实盘、资管/考核、商业及连接券商的模拟执行等用途。
- 本轮没有复制算法实现、配置或二进制。将通用概念与来源实现分开记录，未来依据 GSM SOP 和自己的接口、测试独立设计。改名、改写或声称“独立实现”并不自动消除许可问题；具体受限实现需要许可核查，不能照搬。

## 3. 有用的内容怎样带回来

| 研究内容 | 源码入口 | 对我们的用途 | 本轮决定 |
|---|---|---|---|
| 蜡烛分类、实体/影线、吞没、星形组合 | A `CandlePatterns.mqh` | Intraday/Swing 到区后确认；统一闭合 K 线输入 | 保留概念，重订数学定义 |
| 局部高低点与重复反应的 S/R | A `SupportResistance.mqh` | 给 Intraday/Swing 区域评分 | 候选；不能取代 Scalping Fresh/First Touch |
| 跨周期方向与区域上下文 | A `MultiTimeframe.mqh`；B `CMTFManager.mqh` | 分开记录方向、位置、确认质量 | 先评分观察；不直接增加硬过滤 |
| 结构高低点、BOS、CHoCH | B `CStructureAnalyzer.mqh` | 审计 WRONG_TREND | 仅研究概念，源实现存在关键问题 |
| 最优位置、可接受区间、等待到期 | B `CEntryOptimizer.mqh` | 记录晚进、追价、正常收盘确认的区别 | 候选；先观察再测试拦截 |
| 区域有效/已测试/失效状态 | B `EliteOrderBlock.mqh`、`EliteFVG.mqh` | 检查区域生命周期、去重、最近区域 | 有用；必须重新满足 GSM 离开/首次回踩语义 |
| 统一风险判定及原因列表 | B `CUnifiedRiskPolicy.mqh` | 风险预算、消息、信号漏斗 | 工程设计参考；不导入其 prop-firm 时间规则 |
| 初始风险、分阶段管理、重启恢复 | B `CTradeManager.mqh` | Intraday/Swing 利润保护 | 参考状态机概念；必须逐仓隔离 |
| 消融实验、时间切分、延迟/成本压力 | B `scripts/backtest/`、`scripts/oracle/` | 单变量 Candidate 与反证检查 | 方法参考；不替代 FxPro MT5 Real Tick |
| ONNX、Footprint、复杂形态和大量指标 | 两库其他模块 | 后续研究库 | 暂缓，不进入第一轮正式逻辑 |

“保留”只表示值得研究，不表示证明盈利或获准进入 Champion。

## 4. GoldTraderEA 的具体风险

### A01：趋势过滤把句柄当价格

`GoldTraderEA.mq5:843-851` 将 `iMA` 返回结果用于价格比较；MQL5 中它返回指标句柄，不是均线值。另一个被称为当前收盘价的值取自 series 数组尾部，是旧数据。此处不能用于复制趋势判定。
[固定源码](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/GoldTraderEA.mq5#L843) · [MQL5 iMA 定义](https://www.mql5.com/en/docs/indicators/ima)

### A02：蜡烛定义与闭合信号不一致

`CandlePatterns.mqh:43,113,171-329` 使用当前形成中的 K 线；吞没判断允许仅凭实体相对大小通过，未必真的吞没；晨星/暮星阈值把绝对价格乘比例，不能理解成实体恢复比例。我们的同名形态必须重新定义并测试，不能继承这些结果。
[固定源码](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/CandlePatterns.mqh#L243)

### A03：S/R 重复反应不等于 Fresh S&D

`SupportResistance.mqh:109-137` 按价格附近的 K 线数计数，未区分相邻 K 线与独立离开后回踩；包含形成水平本身。上层只保证至少 100 条数据，验证循环却可能访问 200 条。不能直接用作 First Touch 引擎。
[固定源码](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/SupportResistance.mqh#L109)

### A04：手数与下单成功记录不符合我们的要求

风险手数不足时会被抬至最小手数；默认还使用固定手数。`SafeOpenBuyPosition/SellPosition` 调用无返回值的下单包装后直接计数并返回成功，不能把这个计数当实际成交。另有全账户持仓限制和实测/回测处理节奏差异。
[手数与执行](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/GoldTraderEA.mq5#L898)

### A05：README 收益不是我们的证据

README 给出的历史收益、PF 等是作者声明；这 18 个 tracked 文件没有配套的原始 MT5 报告、测试 SET/INI、编译产物与对应的 hash 链。不能填入 GSM 成绩表。
[README](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/README.md)

## 5. EA_SCALPER_XAUUSD 的具体风险

### B01：结构时间顺序与方向校验

`AnalyzeStructure` 接收周期参数却读取当前图表周期。series 数据从近向远扫描并追加，末尾被当作最新结构。下破事件在设置看空方向前执行验证；清零后的方向实际是枚举值 0，即看多。需重新设计时间顺序、闭合确认与事件方向，不能直接移植 BOS/CHoCH。
[结构入口与识别](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/CStructureAnalyzer.mqh#L311)

### B02：最近区域、触碰与到期语义

OB/FVG 的最近区域距离，在价格位于区域内部时不一定为零，可能选中旁边较近边缘的区域。触碰更新函数在持续处于区域内时反复加次数，不能当“独立回踩次数”。EntryOptimizer 每次计算重建有效期，调用者每次重算会刷新计时，必须按 Setup 固定初始时间。
[OB 距离](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/EliteOrderBlock.mqh#L609) · [FVG 状态](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/EliteFVG.mqh#L525) · [Entry 生命周期](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/CEntryOptimizer.mqh#L254)

### B03：多仓管理并未完整实现

`ManagePositionByIndex` 只更新仓位存在、数量和极值；完整状态机仍走单一 active trade。部分修改又按 Magic+Symbol 搜索而非锁定目标 ticket。保存状态按槽位命名，读取时没有校验保存 ticket 是否匹配。不能满足三策略多 Setup 的独立管理。
[多仓路径](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Execution/CTradeManager.mqh#L2249)

### B04：归一化可能反过来放大手数

`MathUtils` 会先补足最小手数再向下取整，且固定两位小数。主 EA 的部分风险缩减若低于最小手数也不生效。对小资金账户不能因此声称仍满足 1% 风险；分批平仓也可能把预期半仓变成全仓。
[手数工具](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Core/MathUtils.mqh#L20) · [执行前手数](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Experts/EA_SCALPER_XAUUSD.mq5#L1623)

### B05：亏损后的 Recovery Entry 不是我们的增机会规则

入口有因现有浮亏而允许继续寻找 Recovery Entry 的路径；这与“每个独立 Setup 自己通过 SOP 和风险预算”不同。即使仓位倍率没有翻倍，也不能把亏损驱动的补单逻辑带进来。
[Recovery 入口](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Experts/EA_SCALPER_XAUUSD.mq5#L978)

### B06：有名称不代表有完成的算法

OB 的一些机构/成交量/结构验证函数直接返回固定真假值；较旧架构文档与实际默认开关也不完全一致。需要跟踪真实调用路径，不能按照模块名称宣布功能具备。该仓库 README 自己明确标记为研发中。
[占位实现](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/EliteOrderBlock.mqh#L587)

### B07：利润保护需按我们的规则重建

源管理器的保本只加固定 2 points，不能声称覆盖所有手续费、隔夜费与滑点。移动止损存在注释与实际取紧方向不一致的情况；重启与多仓问题见 B03。借鉴分阶段管理概念，不采用其参数及订单操作。
[BE 源码](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Execution/CTradeManager.mqh#L1156)

### B08：Footprint 数据缺失可能变成方向偏差

当 tick 没有 BUY/SELL 标记且 last 为零时，代码退回 bid 再与 bid/ask 中间价比较；正点差下会落入卖方分类。零成交量又可替换为 1。对于这种输入，结果是代理指标而非真实主动卖出量，不能包装成机构订单流证据。
[方向计算](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/CFootprintAnalyzer.mqh#L601)

### B09：测试方法与最终验证必须分开

推荐 Python 回测器包含 ONNX mock、自定义摩擦和可抽样数据路径，不能等价于我们编译后的 EA 在 FxPro MT5 的真实 Tick。`models/wfa_results.json` 本次实际解析失败，文件在 passed 字段处结束。
[回测说明](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/scripts/backtest/README.md) · [WFA 数据](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/models/wfa_results.json)

### B10：模型选择不能继续称 untouched OOS

`train_wfa.py` 用 OOS accuracy 选择最终模型。它可以是研究选择流程，但这些 OOS 已参与选择，不能再作为该赢家的 untouched 验证。分类准确率的比值也不是交易 PF、Recovery 或净利润。
[模型选择](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/scripts/ml/train_wfa.py#L323)

## 6. 后续 Candidate 的研究顺序

这些是待验证研究条目，不是已建立或已胜出的 Candidate。首先核对 FxPro 基线的实际漏斗和交易证据，再选择一个条目。

| 条目 | 一次研究的问题 | 必须增加的反证测试 |
|---|---|---|
| R01 最近有效区域 | 当前价格最近的有效区域是否被旧区或评分挤掉 | 价格在区内、距离相等、旧区失效、新区出现；Nearest 与质量评分分开 |
| R02 合格机会并发 | 同策略多个独立 Setup 是否被机械持仓限制挡住 | 同 Tick 风险预留、请求超时、重复 Tick、重启、拒单、部分成交；不以浮亏为开单理由 |
| R03 方向与收盘确认 | 错误趋势来自索引/周期错误还是策略定义 | 递增/递减高低点、闭合时刻、跨周期映射、同一时点禁止未来信息 |
| R04 入场位置与到期 | 等收盘后正常开单与真正追价能否区分 | 固定 Setup 到期、刚触碰、离区扩张、等待后回区、成本后 R:R |
| R05 Intraday/Swing 管理 | 阶段管理能否减少回吐并保留趋势 | ticket/strategy 硬隔离、0.01 不分仓、初始 R 不变、止损只收紧、重启不重复减仓 |
| R06 区域质量评分 | 独立反应次数是否有价值 | 相邻 K 线不重复计数、未离开不算回踩、used/broken 区不重置成 fresh |

ONNX、复杂形态、大量指标融合及 Recovery Entry 不在这一轮优先实现名单。R02 的并发变化必须单独披露并做风险标准化，不能把增加暴露得到的利润当策略改善。

## 7. 必须保留的用户约束

- 只开发 FxPro；Codex 单独执行。三策略独立 OR，不要求彼此同时有信号。
- Scalping 仅固定 SL/TP，完全不参与保本、移动止损、分批出场或尾仓管理。
- Intraday/Swing 的利润保护独立研究；任何外部规则只能作为 Candidate，GSM SOP 仍是基础。
- 合格独立 Setup 只要风险及执行检查通过即可尝试，不设人为每日交易次数上限；不制造重复信号，不做马丁、网格或摊平补仓。
- 单笔风险上限 1%，组合上限 3%；手数表只作参考，按实际 SL 和合约规格计算，向下适配手数，不足最小手数则跳过。
- 正式排序：净利润 USD → 最大净值回撤 → PF → 完整交易数 → 胜率 → Reject。
- DD 超过 30% 否决；15%-30% 人工复核；Recovery >3；各单策略及组合完整交易数 >100；拒单 0。这些是项目晋级门槛，不是盈利保证。
- 真实 MetaEditor 编译、FxPro 真实 Tick、风险同条件比较、未参与调参的 OOS、成本/延迟压力与策略归属审计通过后才能考虑晋级。

## 8. 保存与续做

本包：中文记录、1,072 文件清单、项目模块索引、27 文件阅读范围、自动复核脚本及结果。**本轮尚未发布 GitHub，未更新正式仓库的 main。**
主工程已有未提交修改，本轮未覆盖；外部两库仍是干净固定副本。
继续时先看 `CHECKPOINT.json`，然后定位 `REVIEW_COVERAGE.csv`。未读模块标记为 INDEX_ONLY；需要采用时必须完整读其实现与依赖并复查许可证。

V4.00 受保护基线在本轮前后核验：

- ZIP SHA256：`43AF3C393B6C226211115A1A1DBC70C88F0F07250FA332D22C04C3ED64EB80E2`
- MQ5 SHA256：`AC9826E6EF4959562B9079A1FF9B8CBB35E5E8C2A913E431488CA5C900D1FF60`

这些 hash 只证明文件一致，不表示满足最新 Champion 风险与样本要求。本轮所有策略结果仍为 NOT_TESTED，不输出虚构的 Net、DD、PF 或胜率。
