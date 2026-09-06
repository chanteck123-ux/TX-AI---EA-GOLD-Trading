# GSM GOLD 3-SOP EA 新一轮研究开发计划

日期：2026-09-06。执行主体：Codex。状态：**计划已完成；Candidate 未实现、未编译、未回测、未晋级。**

本计划依据主仓库 `eb74280c53e474e0dbcb0c10c491705689922416`、V4.00 交付包、四本上传教材与六张课堂截图制定。它是下一轮工作的执行清单，不替换现有顶层规范。证据见同目录 [来源与基线审阅](SOURCE_AND_BASELINE_AUDIT_2026-09-06_CN.md)。

## 1. 本轮决定

**先把基线、风险和进场定义校准，再逐项改善有效机会与持仓管理。** 不把“加更多指标”设为首要任务。

优先顺序：

1. 核对四条 Champion 的源码、SET、原始报告与适用门槛；重建同风险对照。
2. 先研究已在本仓源码发现的区域选择偏差：Scalping 综合评分选区、有效旧区持续占位。
3. 审计 First Touch、进场时机、被过滤机会与执行失败，找出可复现的问题。
4. Intraday 与 Swing 独立研究趋势、进场位置和利润保护；Scalping 保留固定 SL/TP。
5. 单策略胜出后，再作为 Combined Candidate 做组合回测。

目标顺序沿用：Net Profit USD → Max Equity DD → PF → 完整交易数 → Win Rate。回撤有否决权；盈利、频率与胜率的改善均需同风险、扣成本证据。

## 2. 基准和范围

| 基准线 | 包内标识 | 本轮用途 |
|---|---|---|
| Scalping M5 | SC-S20 | 原样保存，作为历史对照 |
| Intraday M30 | IN-I32 | 原样保存，作为历史对照 |
| Swing D1/H4/M30 | SW-W37 | 原样保存，作为历史对照 |
| 三策略组合 | C-C01 / V4.00 | 独立组合基准，不能用单策略利润相加代替 |

源码与 ZIP 哈希已核对。包里存在历史 MetaEditor 编译日志、MT5 报告、SET/INI 与审计 CSV；本轮读取了它们，**没有在本环境重新运行 MT5**。保留现有 Champion 的身份与历史；对最新 mandate 的适用状态单列 `REVALIDATION_REQUIRED`，不能把文件名直接当作最新门槛合格证。

本轮研发边界采用仓库 2026-09-06 研究记录所载约束：FxPro；Codex；单笔预算≤1%、组合预算≤3%；三策略独立 OR；Scalping 固定 SL/TP、不做保本/追踪/分批/runner；没有人为每日交易目标；每个新订单都必须有独立合格 Setup。禁止马丁、网格、因浮亏而补仓，以及用“置信度100”解释加大风险。

旧 Aggressive/Balanced/Conservative、非农挂单 EA 和 Lewis EA 的规则不自动并入本项目。课堂截图的 OANDA/FXCM/Pepperstone 是教学图源，不能改写 FxPro 测试范围。

### 2.1 需要同步的规则记录

顶层 `FINAL_CHAMPION_ITERATION_SYSTEM_CN.md` §29 与后续研究记录存在未同步口径：

| 项目 | 顶层 §29 | 2026-09-06 研究记录 | 本计划处理 |
|---|---|---|---|
| 券商 | FxPro + Tradona | FxPro only | 当前工作先做 FxPro；不擅自扩大券商范围，不宣称已过双券商门槛 |
| 样本 | 按策略判断，Swing可少于100但需更强证据 | 每条单策略与组合均>100完整交易 | 两套判定同时报告；不得为了凑数制造交易 |
| Recovery | >3为目标，未达到需解释与更多证据 | >3列作项目门槛 | 同时报告数值与两套状态，不自行降低标准 |
| DD | >30%否决，15%–30%严格审查 | 相同风险方向 | 执行；不能只引用§7通用参考而漏读§29 |

P0 先检索后续明确用户 mandate 并登记来源、日期、适用版本。未完成一致性登记前不作 Champion 晋级决定；资料映射、静态审计、FxPro 复现实验照常推进。此计划不要求用户现在重新确认已经明确的规则。

## 3. 先解决 USD500 与真实止损风险的可行性

历史组合 SET 使用固定0.01手、组合风险10%，另有小账户例外单笔上限5%输入，但该测试关闭了小账户Profile；固定手数路径并未始终强制单笔1%。FxPro组合25笔初始SL风险全部超过1%；独立Scalping/Intraday的总风险SET还是20%。这些成绩不能与新1%/3%预算直接按净利润排名。Tradona历史 Swing 报告还记录过一笔9.93%的初始SL风险；必须逐笔核对，不能只看输入里的 `RiskPercent=1`。

执行以下两组工作：

- **历史复现组 H0：** 原源码、原 SET、原日期、原成本，目的仅验证历史结果可复现，不接实盘。
- **预算统一组 B0：** 在单独研究分支建立1%/3%控制，只做必要风控改动并记录差异，先成为研究对照；其后的策略 Candidate 与 B0 使用同样风险引擎。这不是自动新 Champion。

每个实际 Setup 先计算：

`最小手数止损损失 = abs(OrderCalcProfit(方向, 品种, 最小手数, 入场价, SL))`

`所需最低净值 = (最小手数止损损失 + 明确成本缓冲) / 0.01`

`允许手数 = 向下对齐券商 volume step(扣除成本预留后的可用预算 / 单位手数止损损失)`

成本随手数变化时用同一成本模型迭代下调；在SL与手数按tick size/volume step标准化后，最终重新验算“止损价差损失 + 成本缓冲 ≤ 单笔预算且≤组合剩余预算”。计算失败或超额即拒绝，不能仅凭原始公式商值放行。

OrderCalcProfit 给出账户货币的估算盈亏；佣金、持仓成本和滑点缓冲必须另列，不能假定已全部包含。[官方定义](https://www.mql5.com/en/docs/trading/ordercalcprofit)

以历史 CoursePip=0.10、Scalping SL80 为例，价差是8.00；如果合约确为每手100盎司、最小0.01手，则仅止损价差损失约USD8，已超过USD500的1%预算USD5。这个例子是单位说明，实际判断必须读取当时合约与报价。

若最低手数已超预算，输出 `MIN_LOT_OVER_RISK` 并跳过。先报告哪些策略/SL在USD500不可执行；不能偷偷增资、换合约、缩短SOP止损或放宽风险让回测有单。可记录合规小合约/资金门槛供以后选择，本轮不自动切换。若 B0 无法形成足够有效交易，判为 `CAPITAL_CONSTRAINT`，不能宣称策略优化失败或成功。

## 4. 教材到程序的映射

| 知识层 | 已核实来源 | 程序必须明确 | 本轮定位 |
|---|---|---|---|
| S&D | p4–6 Long Wick/Base Break/Impulsive；p7 First Touch；p8宽区50%挂单 | 形成与确认时刻、departure、first-touch episode、失效、单位 | 核心规则与工程定义逐项对照 |
| S/R | p2两次以上触碰；p4角色翻转；p6质量；p7假突破 | 独立触碰计数、收盘收回、翻转新对象 | 与S&D分开类型和生命周期 |
| 8种图表 | Chart p3–10；p11确认→回测→进场 | pivot确认时间、容差、跨度、突破与回测 | 先做识别覆盖与日志，不一次全部变硬门槛 |
| 36蜡烛标签 | Candle p2–6；p6确认及量；p8执行示例 | 形态数学定义、背景、方向、收盘确认、族内去重 | 保留多标签，策略按各自白名单/候选使用 |
| 课堂截图 | 多空位置、三类交易员、纪律与复盘 | 与具体SOP分别记录 | 背景与流程依据，不是回测成绩 |

四本并未独立规定完整三引擎的全部周期/SL/TP。特别处理：

- **S&D First Touch 与 S/R 多次尊重不可合并为同一种加分规则。**
- 教材“30点”没有定义MT5点值；现有代码两个单位输入为0.10，属于当前实现约定。教材恰好30点的边界也要登记。保留现值供复现，不能称教材已证明换算。
- Scalping Base 文档写50/50，当前 SC-S20/组合 SET 为80/70；前者是原始SOP，后者是历史Champion参数，两个都记录，不自动改回50/50。
- Intraday Base文档写SL120/TP240，IN-I32已锁参数为SL120/TP70；必须分别登记，不能用Base说明代替实际SET。
- 蜡烛教材全局“下一根收盘确认”、H4/D优先和当前M5触区K收盘执行有差异；额外等待会改变策略，只能独立 Candidate 测试。
- 成交量1.5倍的平均窗口/来源未在书中明确。当前 tick volume 只能作为该报价流活动代理，不能叫集中市场真实成交量；先观察，别直接增加硬过滤。
- 宽区50%预挂、S/R Limit示例、蜡烛确认后Stop示例与即时市价执行属于不同路径；逐策略审计，不把所有3-SOP统一改成挂单。
- Broken Zone、Departure阈值、影线/ATR比、pivot延迟均写成有版本的程序化定义。头肩目标文字存在歧义，本轮不改TP。

所有定义登记：`rule_id / source_page / source_text_summary / engine / current_function / current_value / proposed_definition / available_at / sop_changed / status`。

## 5. 研发任务队列与验收

下表是新计划任务ID，**不是已注册或已通过的 Candidate ID**。执行时先读既有 registry，再分配 S-/I-/W-/C-Candidate ID，保留 SC-S20、IN-I32、SW-W37、C-C01 历史。每个子实验只改变一个主要变量。

| 顺序 / 任务 | 具体工作 | 必须交付与退出条件 |
|---|---|---|
| P0 基线与可行性 | 固定4条基线；检查包内源码/EX5/SET/INI/hash；核对合约、单位、风险、已使用数据；H0/B0对照 | BASELINE_MANIFEST、MANDATE_MATRIX、RISK_FEASIBILITY；不能用旧10%结果冒充新3% |
| P1 区域选择 | P1a仅改Scalping排序为最近有效区，质量仅作等距tie-break；P1b另测旧区占位与候选重选 | zone候选清单+价格距离+旧新选择对照；inside=0、近弱/远强、等距、新区出现案例通过；保留首触状态 |
| P2 首触与漏单 | 先做只读事件回放，区分形成→离区→第一轮回触→确认→消耗；技术拒单不等于允许第二次fresh | FirstTouch trace、LOST_OPPORTUNITIES；连续tick/连续K不反复计数，重启不重置fresh；每项修改另建Candidate |
| P3 Intraday方向/位置 | 从实际损失与漏斗选主因；趋势表达、晚入场、30点/50%路径分别实验 | I候选的单变量说明；M30趋势可观察；确认时间与入场价可追溯；不加入强制2/3或3/3 |
| P4 Intraday/Swing管理 | 各自测试成本后保本、结构/ATR追踪或分批之一；先审ticket隔离与重启 | 初始R固定、SL只收紧、0.01不可合法分批则不分批；Scalping保护函数不可触达 |
| P5 形态与证据 | 8图表/36蜡烛逐个覆盖；先日志观察，再按证据挑少数族测试；BOS/CHoCH/软评分保留研究入口 | 正反例、重叠标签去重、无未来数据；数量覆盖与盈利验证分别报告 |
| P6 独立机会与组合 | 先证实持仓上限确实挡住合格Setup；再单独研究并发风险预留；胜出单策略重新组合 | 相同风险下组合回测、同向暴露、保证金、策略归属与回撤相关性审计；不把增仓当策略优势 |

P1 源码依据：`FindBestSDZone` 最终按 score 最大值选区；`UpdateSupplyDemandStates` 只在 active 无效/used/broken/expired 后搜索。`DistanceToZone` 本身已正确处理区内距离为0，应复用并检验调用语义，不作无证据重写。

P1a 的正式参数形态不动；P1b 不得把“被替换”当作清除历史触碰。保留独立 ZoneID 状态，已触区不得借换区重置fresh。Swing共享函数时必须通过engine参数/策略分支隔离，本实验不得顺手改变Swing。

P2 的 Scalping 路径目前在发送前消费Zone，连无白名单/指标/门控未过也会消费。这是有意防重的现有语义，**只先统计损失机会，不直接删除**。研究可重试时区分服务器明确拒绝、超时未知、部分成交与无SOP；未知状态必须对账，不得盲重发。

现存标签也不能直接当因果：FxPro组合中Scalping20笔全部标`ChaseEntry=YES`，其中15笔盈利；直接过滤该标签会清空这批样本。Intraday漏斗有391次FirstTouches、380次EMARejected、最终4单，但字段不是互斥原因。Swing唯一FxPro订单MFE48.94美元、最终0.66美元，值得研究利润保留，却不足以据此调参。应逐Setup重建时间线，预先固定比较方式。

P5 延续既有 GitHub 研究索引，保留原 GH01–GH10 来源映射。此次把已确认的本仓实现差异排在外部新指标之前，不代表取消BOS/CHoCH等研究。ONNX/在线AI、Footprint、庞大指标融合继续后置；规则评分不称真实成功概率。

## 6. 程序接口与执行纪律

依据顶层顺序：**GSM SOP → 三独立引擎 → 可选证据 → Risk → Portfolio → Execution → MT5 → Audit**。

- 检测器输出结构化证据，不下单。引擎生成带 `engine_id, zone_id, setup_id, direction, signal_time, confirmation_time, expiry, planned_entry, SL, TP` 的候选。
- Risk读取真实合约、当前净值、现有敞口、挂单与在途请求，统一计算预算；Portfolio在发送前串行预留风险与保证金。
- 单笔预算在所有手数模式中统一强制；风险计算失败、无SL或无法归属的账户敞口不得静默忽略。新风险规范分别记录初始SL风险、从当前净值回落至SL的风险和成本缓冲；明确手动单/其他EA/挂单的纳入方式，同一风险不得重复计数。
- 相同信号tick、延迟回报、重启、拒绝和部分成交均不能重复计风险或重复下单。净额账户不能仅靠Magic声称三策略独立；当前要求Hedging的行为要明确验证，不擅自取消。
- `OrderSend=true`不证明已成交；记录retcode，并由交易回报和服务器Order/Deal/Position状态完成对账。[OrderSend官方说明](https://www.mql5.com/en/docs/trading/ordersend) [交易回报](https://www.mql5.com/en/docs/event_handlers/ontradetransaction)
- 禁止新仓时，仍执行所属策略既有持仓管理；所有修改锁定目标ticket与策略，禁止只按symbol误改另一引擎。
- Risk预算是建仓前约束，跳空/滑点可能使实际损失超过预算；测试必须报告超额和尾部损失，不能声称止损保证绝不超1%。

建议稳定原因码：`NO_VALID_ZONE, NOT_FIRST_TOUCH, NO_REVERSAL, WRONG_TREND, LATE_ENTRY, DUPLICATE_SETUP, MIN_LOT_OVER_RISK, PORTFOLIO_RISK_FULL, MARGIN_INSUFFICIENT, SPREAD_TOO_HIGH, DATA_NOT_READY, REQUEST_UNKNOWN, BROKER_REJECT`。这是审计词汇提案，映射旧字段后再落实。

“Reject=0”专指要消除的执行拒单/故障；正常SOP、风险、点差拒绝属于有效控制，不能为了归零而删过滤，也不能改名隐藏真实broker reject。

## 7. 回测与反证协议

### 7.1 数据和公平对照

1. FxPro历史数据从用户已知2024-03开始做覆盖盘点，实际可用范围以终端下载日志为准，不能把计划范围写成已下载。记录服务器时区与夏令时、品种名称、合约、缺口、Tick覆盖和终端build。
2. 冻结每个实验的源码、EX5、SET/INI、初始资金USD500、杠杆、成本、引擎开关、起止日期和风险规则。H0使用历史1:100以复现，后续改杠杆也须独立披露。
3. 历史2026-05-01至08-26及Scalping旧验证段已被分析/选参，不能再次称为新一轮 untouched OOS。历史OOS字段保留原标签，并加 `REUSED_FOR_RESEARCH` 状态。
4. P0盘点所有已看过的数据范围；只将未参与选择的后续保留段用于最终验证。若目前没有足量未用段，则输出 `OOS_PENDING`。Walk Forward在每个训练窗选参后冻结、再生成后续交易，不能只把同一份成交表切片冒充重新训练。
5. MetaEditor 对实际交付源码编译，要求0 errors/0 warnings；MT5使用 `Every tick based on real ticks`。还须检查缺Tick时的生成回退，不能把“历史质量100%”直接当全部真实Tick证明。[MT5官方Tick说明](https://www.metatrader5.com/en/terminal/help/algotrading/tick_generation)

每个run还必须固定预热、状态初始化与跨分段持仓处理。独立FULL与TRAIN/OOS重启会形成不同交易集，不能要求FULL机械等于两段相加，也不能把重叠报告相加凑样本。复现实验先补INI旧SET/EX5文件名与交付改名文件的映射，保持原文件不变。

### 7.2 验证矩阵

| 验证 | 条件 |
|---|---|
| 策略拆分 | S-only、I-only、W-only、Combined分别运行；每条确认其他引擎开关 |
| 成本/延迟 | 实际点差佣金基础；预先登记点差+25%/+50%、额外不利滑点、固定/随机延迟场景；无法由原生Tester表达的变更单列研究仿真 |
| 边界正确性 | 零实体/零波幅、未就绪数据、同tick多信号、broker最小手数、部分成交、订单超时、重启、Stops/Freeze/TickSize |
| 参数稳定性 | 只在研究/训练段检查相邻值，不因OOS结果挑回最优参数 |
| 方向与行情 | BUY/SELL、趋势/震荡/高波动、月份分别归因，不删除不利时期 |
| 样本与不确定性 | 完整持仓交易和Setup数量；分批deal单列；按日/Setup块估计不确定性，低样本标明结论不稳 |
| 晋级 | 实验前冻结接受标准；通过测试且同风险明确优于当前基准，再过OOS/压力/组合/mandate检查 |

每个实验先登记最多研究的参数组合与主要变量；失败原样归档，不反复看同一OOS“调到PASS”。无明确优势即保留原Champion。Final Verdict沿用顶层枚举：`REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER / NEW ENGINE CHAMPION / NEW 3-SOP COMBINED CHAMPION`。资料、环境或资金可行性阻塞写入独立`execution_status=BLOCKED_BY_DATA_OR_CAPITAL`，此时Final Verdict为`RESEARCH FURTHER`，不能新增晋级结论或伪造PASS。

## 8. 每轮交付格式

必须交付：源码差异及hash、SET/INI、真实编译日志、原始MT5报告、逐交易审计、信号漏斗、错误进场/漏单案例、对照表、OOS与压力证据、最终结论。

| Version / Engine / Segment | Net USD | Return % | Max Equity DD USD/% | PF | Complete trades | Win rate | Execution reject |
|---|---:|---:|---|---:|---:|---:|---:|
| 本轮新Candidate | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED |

补充 Expected Payoff、实际平均盈亏比、Recovery定义、成本、实际风险、保证金峰值、BUY/SELL差异与相对基准变化。无亏损或无交易时PF用适当未定义状态，不填高值装作通过。

后续图表报告需包含权益与余额、回撤、月度收益、按策略和方向分布、信号漏斗；只使用实际结果。本轮是计划交付，未生成虚构权益曲线。

## 9. 给 Windows Codex 的首轮指令

> 读取本计划、同目录来源审阅、顶层规范（含§29）及最新用户mandate。确认工作目录、未提交变更、正式MT5数据目录，先固定V4.00四条历史基准与hash。完成P0风险可行性、数据使用清单与H0/B0协议，再对Scalping最近区域排序建立第一个单变量Candidate。先复现具体错误选择案例，再改代码、编译、FxPro Real Tick、独立与组合审计。正常拒绝和执行失败分开记录。每轮只据证据KEEP/REJECT；失败不降低风控、不重用OOS充当盲测、不覆盖Champion。缺少环境或数据时写明确BLOCKED证据并保留可继续执行的文件，不能报告已回测。

## 10. 完成本计划时的状态

- [x] GitHub主仓库、两参考仓库与固定commit已核对。
- [x] 四本教材与六张截图已读取，关键歧义已列出。
- [x] V4.00 ZIP、MQ5、EX5身份已核对；已读历史回测证据及关键源码路径。
- [x] 已提出可直接执行的优先队列、独立变量与验收条件。
- [ ] Windows MetaEditor新编译、FxPro新回测、新OOS、压力测试。
- [ ] 新Candidate实现与Champion晋级。
