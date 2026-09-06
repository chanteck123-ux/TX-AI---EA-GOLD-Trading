# 新研发计划：来源与基线审阅

审阅日期：2026-09-06。范围：GitHub固定版本、V4.00包内历史证据、四份上传PDF、六张PNG。方法：只读静态审查、原始报告/参数/审计表核对、教材文字及关键页视觉审查。**没有运行EA、外部脚本、MetaEditor或MT5回测。**

## 1. 固定来源与覆盖

| 来源 | 固定版本 / 覆盖 |
|---|---|
| [主仓库](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/tree/eb74280c53e474e0dbcb0c10c491705689922416) | `eb74280c53e474e0dbcb0c10c491705689922416`；完整文件树、顶层规范2244行、研究制度/报告、GSM映射、Champion包 |
| [GoldTraderEA](https://github.com/mehdi-jahani/GoldTraderEA/tree/ba329266c56372c36da9f81fac35983b9fc2e4a3) | `ba329266c56372c36da9f81fac35983b9fc2e4a3`；完整18文件树、README、主EA、S/R模块 |
| [EA_SCALPER_XAUUSD](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/tree/b0087e93c8af6690102c6698b8123186703a9240) | `b0087e93c8af6690102c6698b8123186703a9240`；完整文件树、README、许可/用途限制、主EA、风险接口/策略、执行类、WFA和DD测试 |
| V4.00交付包 | 校验ZIP/MQ5/EX5；只读展开文本证据；未做全源码无缺陷认证 |
| 教材 | S&D与S/R均9页并逐页看图；Chart11页、Candle8页全文，另核对关键页 |
| 课堂截图 | 六张均成功打开；此前临时路径读取错误在本次未复现 |

主仓库既有详细外部研究已在 [中文记录](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/eb74280c53e474e0dbcb0c10c491705689922416/docs/EXTERNAL_GITHUB_GOLD_EA_SOURCE_RESEARCH_CN.md) 保存。本轮在其基础上补充复核，不把未审读的模块计为本轮完整审计。

## 2. V4.00身份

包内manifest：`Version=V4.00`，`PackageRevision=INSTALL_FIX_1`，`Status=LOCKED_RESEARCH_BACKTEST_CHAMPION`，`LiveAuthorization=NO`。

| 对象 | 实读SHA256 |
|---|---|
| GSM_GOLD_3SOP_EA_V4.00_CURRENT_CHAMPION.zip | `43af3c393b6c226211115a1a1dbc70c88f0f07250fa332d22c04c3ed64eb80e2` |
| CODE/GSM_Gold_3SOP_EA_CHAMPION.mq5 | `ac9826e6ef4959562b9079a1ff9b8cbb35e5e8c2a913e431488ca5c900d1ff60` |
| BIN/GSM_Gold_3SOP_EA_CHAMPION.ex5 | `cbbb0ff7ec33de8e31acd7711f584a01a7e027a19eb446f593bff0da7f1b3269` |
| SETS/FxPro/GSM_Gold_3SOP_EA_COMBINED_CHAMPION.set | `a607db87cfb8c1cc2bc029acbe797b8b1e07f69a2eefee53a858999ebec26e1c` |

以上与对应清单/CSV一致。独立Scalping、Intraday、Swing有各自源码版本，不得只拿组合源码hash代表全部单策略原测试。

| 线 | ID | 历史已锁概要 |
|---|---|---|
| Scalping | SC-S20 | M5 Fresh S&D/Departure/First Touch/收盘反转；EMA30/100、RSI14；SELL额外H4方向条件；SL/TP80/70 course pips |
| Intraday | IN-I32 | M30 S&D/First Touch；EMA50/200及价格方向；RSI分方向区间；MACD观察；SL/TP120/70；低周期确认关闭 |
| Swing | SW-W37 | D1/H4/M30；H4区域与趋势、M30反转或假突破；结构SL、普通2R/高波动3R；BE0.5R、H4 ATR追踪 |
| Combined | C-C01 | 三引擎OR、各最多1单/总3单、固定0.01、总SL风险10% |

依据：包内`CHAMPION_MANIFEST.txt`、`BEST_*/CHAMPION.md`、各自FxPro SET及RESEARCH报告。SL/TP数字使用代码的课程单位约定，不是账户美元盈亏。

## 3. FxPro原始历史结果

以下7份原始HTM逐份核对。品种GOLD、初始USD500、固定0.01；INI为Model=4、杠杆1:100、Optimization=0、ExecutionMode=0。报告自述100%真实报价；本轮未核查终端原始Tick覆盖，不把该字段升级为独立数据认证。

| 线/段 | 报告期间 | Net USD | Max Equity DD USD/% | PF（原报告） | Trades | Win rate |
|---|---|---:|---|---:|---:|---:|
| SC-S20 FULL | 2026-01-05–08-26 | 64.39 | 15.95 / 3.10% | 2.53 | 20 | 75.00% |
| IN-I32 FULL | 2026-01-05–08-26 | 28.66 | 7.77 / 1.52% | 180.13 | 4 | 100.00% |
| IN-I32 OOS | 2026-05-01–08-26 | 14.08 | 3.72 / 0.74% | 177.00 | 2 | 100.00% |
| SW-W37 FULL | 2026-01-05–08-26 | 0.66 | 47.62 / 8.69% | 17.50 | 1 | 100.00% |
| SW-W37 OOS | 2026-05-01–08-26 | 0.66 | 47.62 / 8.69% | 17.50 | 1 | 100.00% |
| C-C01 FULL | 2026-01-05–08-26 | 93.71 | 57.69 / 9.48% | 3.21 | 25 | 80.00% |
| C-C01 OOS | 2026-05-01–08-26 | 68.57 | 57.69 / 9.89% | 5.08 | 15 | 86.67% |

执行拒单均为0。极少样本下的高PF/100%胜率不构成稳定盈利证明，必须连同成本、交易统计口径和原成交明细阅读；没有把这些数值写成新Candidate成绩。C-C01 FULL收益率为93.71/500=18.742%，属该历史配置/区间结果。

精确包内证据路径：

- `BEST_SCALPING/REPORTS/FxPro/V400_SC-S20_FULL_FxPro.htm`
- `BEST_INTRADAY/REPORTS/FxPro/V400_IN-I32_{FULL,OOS}_FxPro.htm`
- `BEST_SWING/REPORTS/FxPro/V400_SW-W37_{FULL,OOS}_FxPro.htm`
- `REPORTS/COMBINED/FxPro/V400_C-C01_{FULL,OOS}_FxPro.htm`
- 各BEST目录的`SETS/CONFIG/AUDIT`，以及组合`SETS/FxPro`、`CONFIG/FxPro`、`AUDIT/COMBINED/FxPro`。
- `RESEARCH/COMBINED_CANDIDATE_METRICS.csv`、`COMBINED_STRATEGY_METRICS.csv`和四条Champion研究报告。

### 3.1 风险与样本缺口

| 检查 | 实读发现 | 对下一轮的影响 |
|---|---|---|
| 单笔1% | 组合FULL 25笔`ActualSLRiskPercent`全部>1%；Scalp1.3979–1.6059%、Intraday2.0457–2.3450%、Swing2.7677% | 旧成绩不是1%合规证据 |
| 独立线 | Scalp止损额约USD8、Intraday约USD12；独立FxPro Swing唯一一笔USD15.50，3.1012% | USD500预算USD5与当前最小手数/SL不相容 |
| 总风险 | 单独Scalp/Intraday SET20%，Swing/组合10% | 必须重建同1%/3%研究对照 |
| LONG100 | Tradona长区间组合50笔，单独27/16/7 | 文件名不能当100笔；不能把重叠期间相加 |
| 旧OOS | Scalp研究报告承认2026验证段被用于迭代；其FULL又称cross-broker OOS | 不是下一轮 untouched OOS；包内也没有相同05-01起的独立Scalp OOS报告 |
| 历史覆盖 | FxPro此包只证实2026-01-05起的测试 | 用户已知2024-03起数据需单独覆盖核对 |
| 复现文件映射 | 部分INI指向旧SET/EX5名，交付包改了文件名；组合FULL SET可用hash对应，OOS命名SET未独立提供 | 先恢复可复现映射，保持原证据不变 |
| 启动状态 | FULL与分段独立运行的交易集不同 | 记录warm-up、状态重置与跨段持仓处理；FULL不必等于两段相加 |

### 3.2 实际源码定位

下列行号以包内`CODE/GSM_Gold_3SOP_EA_CHAMPION.mq5`为准。

| 位置 | 已观察行为 | 结论性质 |
|---|---|---|
| `PlaceStrategyTrade`约3565 | `enforceStrategyCap`只在阶梯ENFORCE、forcedMinimum、confidenceBoost或SmallAccountProfile非OFF时成立；实际SET这些条件关闭 | 固定手数路径的单笔1%不是统一硬门，且逐笔风险表支持 |
| `CalculateAccountOpenRiskPercent`约5643 | 按开仓至SL负值计风险；无SL/计算失败可能被跳过 | 静态风险覆盖缺口；须定义剩余权益风险、其他EA、挂单/在途处理 |
| `FindBestSDZone`4753起，4830–4837 | distance只是score惩罚，最后按最高score选区 | 不保证最近有效区；直接作为P1a研究依据 |
| `DistanceToZone`4894起 | 价格在区内返回0 | 基础距离函数已有正确语义，无需凭空修它 |
| `UpdateSupplyDemandStates`5976附近 | active仍有效时不搜索替换区 | 可能旧区占位，需以新更近区域案例验证收益影响 |
| `ExecuteScalpFirstTouch`2751起 | 无白名单/过滤/门控未过也会在发送前MarkZoneUsed | 现有防重选择；先统计，不直接宣称bug或删除 |
| `RegisterFirstTouch`6017起 | DEPARTED→FIRST_TOUCH，写时间/价格/触区K时间并持久化 | 已有原子首触机制；改区选择时必须保留历史状态 |
| `OnTick`2506起 | 分别运行三引擎，先管理持仓 | 研究需保留策略独立性与持仓管理时序 |

### 3.3 能帮助选实验的现存审计信息

- Intraday组合FULL：FirstTouches391、EMARejected380、EMAPassed11、最终4单。字段不是互斥的严格漏斗，需按ZoneID时间线核对再做归因。
- Scalping组合20笔全部`ChaseEntry=YES`，其中15笔盈利；5笔亏损有启发式`ENTRY_TOO_LATE`。不能直接据标签加硬过滤。
- Swing唯一FxPro订单MFE48.94美元、最终0.66美元，可形成利润保留假设，不能凭一单选择保本/追踪参数。
- Tradona长期Swing盈利受一笔初始SL风险9.93%的交易影响，需核对盈利集中度与风险差异，不能移植收益承诺。

## 4. 教材证据索引

PDF均以物理页码引用。原书和截图留在用户原附件；此研究提交只包含必要摘要、页码与hash，不复制原教材。

| 规则 | 教材依据 | 实现边界 |
|---|---|---|
| S&D三种形成 | Supply & Demand p4长影线、p5基底突破、p6强推动 | 无精确ATR/比例/根数，阈值是程序化定义 |
| First Touch | S&D p7，且明确Intraday硬纪律 | 一轮回触内部与第二次回来必须分清；不能每tick算一次 |
| 宽区中间挂单 | S&D p8：>30点用50% | 点值单位、恰30点、挂单到期与确认时序未完整定义 |
| S/R有效触碰 | Support & Resistance p2–3、p5 | 多次尊重与S&D首次交易是不同语义 |
| 翻转/假突破 | S/R p4、p7 | 收盘确认/回测阈值须版本化；旧区翻转不直接恢复fresh |
| 等位置 | S/R p8–9 | Limit预挂与到区收盘反弹两种描述要显式映射 |
| 形态流程 | Chart Pattern p11 | 清晰趋势、确认→回测→进场；不能只认出外形就下单 |
| 蜡烛确认 | Candlestick p6–7 | 下一根方向收盘、量≥1.5均量、高周期优先；平均窗与量来源未定义 |
| 蜡烛执行 | Candlestick p8 | 确认后Stop示例、结构SL与目标；不能自动替代三策略现有入场 |

八种图表形态已核实：Head & Shoulders(p3)、Inverse H&S(p4)、Double Top(p5)、Double Bottom(p6)、Rising Wedge(p7)、Falling Wedge(p8)、Bull Flag(p9)、Bear Flag(p10)。头肩目标原文表述存在歧义，本轮不自行改为另一常见公式。

36蜡烛是15多、15空、6中性标签，不是36个互不重叠的独立信号：

| PDF页 | 标签 |
|---|---|
| p2 | Hammer、Inverted Hammer、Bullish Marubozu、Bullish Engulfing、Bullish Harami、Piercing Line、Tweezer Bottom、Bullish Kicker |
| p3 | Morning Star、Morning Doji Star、Bullish Abandoned Baby、Three White Soldiers、Three Inside Up、Three Outside Up、Bullish Spinning Top |
| p4 | Hanging Man、Shooting Star、Bearish Marubozu、Bearish Engulfing、Bearish Harami、Dark Cloud Cover、Tweezer Top、Bearish Kicker |
| p5 | Evening Star、Evening Doji Star、Bearish Abandoned Baby、Three Black Crows、Three Inside Down、Three Outside Down、Bearish Spinning Top |
| p6 | Doji、Long-Legged Doji、Dragonfly Doji、Gravestone Doji、Spinning Top、Four-Price Doji |

Doji及重叠族须去重解释，不以中性标签直接指定方向。高/中/弱是教材分级，不是经验证的概率。Gap形态若改成无Gap变体需另命名。量化Detector须保留`formed_at/confirmed_at`，不得用未来pivot回填过去订单。

### 4.1 六张截图

| 截图时间（2026-08-23） | 实际内容 | 研发作用 |
|---|---|---|
| 144140 | 多空图表/蜡烛与Demand-Support、Supply-Resistance组合 | 位置背景；空头栏Inverted Hammer名称与详细手册语境不一，需保留来源差异 |
| 144352 | Scalper/Day/Swing特点 | 支持三独立引擎，不规定具体参数 |
| 145042 | Swing-OANDA、Day-FXCM、Scalp-Pepperstone图源 | 教学图源，不强制EA更换券商 |
| 163529 | 计划、纪律、记录与复盘 | 审计和迭代流程；图上99%/1%不是研究统计 |
| 170638 | 系统、接受亏损成本、无机会不进场 | 不为每日交易目标强行下单 |
| 171434 | GSM Full Recap | 课程主题目录；不代表四份PDF已包含全部Market Structure/Trendline资料 |

## 5. 外部仓库复核结论

| 来源 | 值得研究 | 本轮实读的限制/反例 |
|---|---|---|
| GoldTraderEA | 信号模块分层、蜡烛/价格行为、S/R | iMA句柄当价格、series尾部旧close、最小手数抬高、成功计数不以成交确认；README收益无对应报告；未见明确LICENSE |
| EA_SCALPER_XAUUSD | 统一风险接口、阻止原因、持仓管理与验证框架 | 用途限制明确；测试有镜像类而非生产类；WFA对既有成交切片而非完整逐窗选参重放；测试模式放宽本地点差门 |

精确补充依据：

- GoldTraderEA [主文件约840](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/GoldTraderEA.mq5#L840)与[风险/下单约898](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/GoldTraderEA.mq5#L898)；[S/R数据边界](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/SupportResistance.mqh)。MQL5 [iMA返回handle](https://www.mql5.com/en/docs/indicators/ima)。
- EA_SCALPER [LICENSE](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/LICENSE)为PolyForm Noncommercial；[TRADING_RESTRICTIONS](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/TRADING_RESTRICTIONS.md)明确列出实盘、prop和连接券商demo限制。本轮只阅读和记抽象研究问题，不复制源码/配置/受限实现。
- [Test_DDTracker](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Scripts/Tests/Test_DDTracker.mq5)使用镜像CTestableDDTracker；[walk_forward.py](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/scripts/oracle/walk_forward.py)对固定成交切片，两个负收益相除也可能满足APPROVED比值；[主EA约926](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Experts/EA_SCALPER_XAUUSD.mq5#L926)有tester本地点差上限放宽分支。存在其他风控门，不能据此断言全部点差控制都绕过。

这些观察支持“独立设计、直接验证生产实现、同成本对照”，不证明自有或外部策略有盈利优势。

## 6. 规则权威与未同步处

[顶层规范](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/eb74280c53e474e0dbcb0c10c491705689922416/FINAL_CHAMPION_ITERATION_SYSTEM_CN.md)最后修改2026-09-05，必须读至§29，DD>30%已是硬否决。2026-09-06[后续研究记录](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/eb74280c53e474e0dbcb0c10c491705689922416/docs/EXTERNAL_GITHUB_GOLD_EA_SOURCE_RESEARCH_CN.md)记有FxPro only、1%/3%、所有线>100、Recovery>3、Scalping固定SLTP、Codex执行。其提交没有显式修订顶层§29的双券商/分策略样本/Recovery解释。

本计划保留后续用户约束，先开展FxPro工作；最终报告并列两套判定，并核对新mandate。不因文档冲突降低门槛，也不因此停下已可完成的研究。

## 7. 本轮附件身份

| 上传文件 | SHA256 |
|---|---|
| Gold Secret Mastery (GSM) · Chart Pattern Handbook(4).pdf | `037a8b62d9da13370b91360ab11b9f84002c26e7bb9c401dbd6bb9417fe867db` |
| Gold Secret Mastery (GSM) · Supply & Demand Handbook(4).pdf | `0a3cff33ee28225eb99e0b9dfd1ca2703a3729e6cf040e96cb8c1a4a01e936bf` |
| Gold Secret Mastery (GSM) · Support & Resistance Handbook(4).pdf | `a730552a165caba4df41f3ed8c7d687c434dc1d2bacf6634dfd18aa0dfb76f08` |
| U.S.D 交易训练营 · Candlestick Pattern Handbook(5).pdf | `3944cde3c19880ba2f5b55f19be6d05ea9648a736e9f9be4c38f8f8852e80f08` |
| 屏幕截图 2026-08-23 144140(3).png | `0c58a9c92d7ab71dfa003dd2c738abccb4e783b722df5f1a806cc2cbdc5f9d61` |
| 屏幕截图 2026-08-23 144352(2).png | `f59dba5fd95da6f4c284ed8de8047ceda0a2a885b4077ba01931876750799a7f` |
| 屏幕截图 2026-08-23 145042(3).png | `b8fd96405ebf471d388e49228a6fc9a2d2f8539d138919647523367175cf6488` |
| 屏幕截图 2026-08-23 163529(2).png | `31bc7cf2bb2bea5f9270bae833707211f291d131e2a2b441ed42e2889d0bfd86` |
| 屏幕截图 2026-08-23 170638(2).png | `d0c067682a499f88900abea9bb585850c119d7dba89b3a89fa7a040dde2e26b2` |
| 屏幕截图 2026-08-23 171434(2).png | `2b3642cf1dccb15026cd9d19cce94fb97fbad1b0c6387ad330f1da1ef7029cb3` |
