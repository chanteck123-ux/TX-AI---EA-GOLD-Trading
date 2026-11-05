# 方案 B 第一阶段：Codex 本地取证与复核

报告日期：2026-10-19（用户端 Asia/Kuala_Lumpur）。原生日志保留机器原始日期：前两次 Demo 失败为 2026-10-18，最终成功以 native_demo_log.txt 原始时间为准；不改写历史时间。

执行者：Codex。Git 操作账号：chanteck123-ux。研究分支：research/plan-b-local-evidence-20261018。重新 fetch 后 origin/main=3718653b8f7bde02e2f52ef5ec47a6ec4c1c459d。没有合并 main、改变正式接口或部署交易策略。正式 RiskExecution 仍为 v1.0；v1.1 是草案。

## 1. af55185 五项正式复核

1. 审查提交：af551855bc4cc40470f44cad57cff553570f2102。保存完整元数据和 diff：AF55185_COMMIT.txt、AF55185_DIFF.patch。
2. 文件及范围：contracts/drafts/planB_v1.1_consistency_check_claude_20261018.md 第三节，新增 15 行、删除 5 行。逐行审阅该提交，并对照现行 AGENTS、正式 v1.0、v1.1 草案及用户本次执行指令。
3. Codex 结论：**该提交第三节的范围划分符合方案 B，未发现阻断性文档冲突**。明确分开 G1/G3/G4/G5 前置取证与 Claude 实现后的 RE-29/30/31 验收；S7 槽位 TBD 不阻断接口规格但阻断其新增风险/新回测；探测只允许 Demo/Tester。这个结论不扩大为整份 v1.1 可冻结。
4. 未执行/仍需验证：未实现新 RiskExecution；RE-29/30/31 运行验收 NOT RUN；七策略并行、S4 完整跨引擎一致性、OOS、成本压力及 Demo 策略前瞻均未由本次证明。该核对文件第四节仍需按 AGENTS 的具体 PR 用户授权门禁修订，不能照旧文自行替换正式接口或合并。
5. 职责及安排：Codex 负责 Core、指标/信号、LEAN C#、模块整合与固定 MT5 唯一测试队列；Claude 负责 RiskExecution、持久化、租约、日锁和故障注入。第一阶段证据交 Claude 独立复核；不代其宣称通过。后续接口冲突须共同解决，独立 PR 还需用户针对该 PR 明确批准合并。

## 2. 源码身份和 G1 Magic

本轮定位的是 I18 **保留版本 MT5_Current_Research**，不是 I18 全部新候选。七份 MQ5、对应 EX5 和编译日志共 21 项 SHA256 与 I18 selection 匹配，详见 I18_SOURCE_IDENTITY.json（绝对路径、行号、哈希、候选名）。这是历史构建身份核验，没有重编译七个策略。

| 策略 | I18 保留候选 | Magic | 声明行 |
|---|---|---:|---:|
| S1 | TB500_S1_TRIGGER_M5_SL_R2 | 6101 | 88 |
| S2 | TB500_S2_PROGRESS_RISK2_BE1_I11 | 6201 | 85 |
| S3 | TB500_S3_H1_SLOPE_PRICE | 6301 | 88 |
| S4 | TB500_S4_BE125 | 6401 | 84 |
| S5 | TB500_S5_REQUEST_FINALITY_V1 | 6501 | 86 |
| S6 | TB500_S6_DISTINCT_TRIGGER_BE1 | 6601 | 86 |
| S7 Scalping | TB500_Scalping_SPREAD20_I18 | 26082152 | 485 |

S1–S6 是初始化全局数组 g_magics，并非 const/input 或随机生成；每个六引擎源码含全部六个值，保留配置只启用其对应引擎。S7 是 input InpScalpMagic，但所选版本 OnInit 强制为 26082152，并拒绝所有非 Tester 执行。不要将这个研究版直接挂 Demo/实盘。

草案映射见 MAGIC_MAP_DRAFT.json。七个选定身份互不重复。Intraday=26082102、Swing=26082303 存在于 S7 多引擎旧源码，参加冲突检查，但不是 S7 身份。实际读取 I10 原源码，SHA256=79faf1f66caf71d5bba88c657810ca582b611c402708b113531460554ebcdc1a，第483行为 26082152；当前 I18 同值。I15 恢复源码已核验 SHA256=cbc629f049f701061c9cbe76e263ed42caef0d53b013b87fbcd79abfe8a0b5de。没有依据增加其他历史 S7 magic。

固定终端已安装源码扫描发现 332 个文件、432 条相关声明，保存 G1_INSTALLED_SOURCE_OVERLAPS.json；这是历史文件复用，**不代表 332 个 EA 正在运行**。Demo 探测前后实际仓位和挂单均为 0。未核对其他终端/机器的活动 EA 与未来下单，因此账户范围冲突保证仍为 NOT VERIFIED；新执行层启动时必须检查身份/所有权，不能只靠本表宣布全账户无冲突。

## 3. G3 槽位源码核对

证据：G3_G5_S7_SOURCE_EXCERPTS.txt、G3_S4_SOURCE_EXCERPTS.txt，行号对应上述保留源码。

| 项目 | 实际实现与结论 | 状态 |
|---|---|---|
| S7 持仓上限 | InpTotalMaxOpenPositions=1（501）、InpScalpMaxOpenPositions=1（601）；6905–6958按持仓数检查 | SOURCE VERIFIED |
| S7 挂单 | 1944–1948单独拒绝已有归属挂单时的新风险；不是 CountOpenPositions 内统一算 slot | SOURCE VERIFIED |
| S7 在途 | 1938–1956检查并持久化 inflight，发请求前预留 | SOURCE VERIFIED |
| 部分成交/撤单 | 1958–1988部分或未知继续保留在途；终态/成交量核对后释放请求。在途释放不代表残余持仓消失 | SOURCE VERIFIED，运行边界 NOT RUN |
| S7 平仓 | CountOpenPositions 直到实际仓位消失才减少；不是仅发送平仓就释放 | SOURCE VERIFIED，运行边界 NOT RUN |
| S4 两槽 | g_slots={1,1,1,2,1,1}；RiskGate 先检查 request active，再检查槽位；snapshot计持仓/挂单并处理在途预留 | SOURCE VERIFIED |
| S4 第二槽 | 第一请求在途未结束时被挡，之后在风险预算允许下可第二槽；正常路径与原两槽不矛盾 | 静态符合；部分成交/拆分持仓迁移仍需 RE-29 |

可提出 S7 max_slots=1 草案，但须注明现行是“持仓上限+挂单/在途门控”，不冒充已实现 v1.1 一 Setup 一 Slot。S4 部分成交可能形成多个持仓，旧实现与新 Setup 统计必须另测。当前不启动新的 S7 交易批次。

## 4. G4 原生平台能力

固定终端：C:\Users\A\AppData\Roaming\MetaQuotes\Terminal\523FF71FCA93BC15AC28868379E0D478，所有启动实查 /portable。公共根：C:\Users\A\AppData\Roaming\MetaQuotes\Terminal\Common；测试文件实际位于其 Files\TB_PLANB_G4\<run_id> 下。

| run_id | 探测 | 结果 |
|---|---|---|
| G4_60513548b83f49f59dbd21e3405f5e10_A | Tester 本地/common 写入、关闭、重读，缺失文件失败 | PASS |
| G4_60513548b83f49f59dbd21e3405f5e10_B | 独立 run_id 写入，读取 A 验证未改写 | PASS |
| G4D_2ec93af69f1640aab780be4418bab806 | Demo 双图表 | FAIL：创建/排队应用模板成功但无 worker 初始化和交换 |
| G4D_0420a5ff88e34c2e81c114d131777a6f | Demo 双图表，修正启动配置 | FAIL：同样未完成交换 |
| G4D_3abe0765c0ac401a8007c34a0662a9d2 | Demo 双图表，加初始化等待、同步读取实际 EA 名称与模板取证 | PASS |

最终 Demo 原生日志确认 tester=0、mode=DEMO；两个不同 ChartID=132772944655437239/132772944655437240，分别初始化 A/B。同一个 run_id 下 A 写 PING、B读后写ACK、A读后写DONE，控制器核对完整双方 ID；前后 positions=0、orders=0。探针源码无交易 API，无 include；交易权限关闭，expertmode=0。结束后仅关闭本探针创建的图表，终端退出，原 common.ini/terminal.ini 按原字节恢复并核验哈希。配置备份含账户信息，仅本地 private 保存，不进入 Git。

Tester 编译 0 errors/0 warnings；三个 Demo 尝试各自两个源文件均保存 0 errors/0 warnings 原生日志及 EX5。Tester 缺失文件得到 INVALID_HANDLE/-1、错误5004；正常37字节写入后 FileFlush/FileClose 再读一致。没有做权限拒绝或磁盘故障注入。Demo worker 失败打开会返回空串等待，控制器超时判失败；真实日志已保留两次失败，不能从 ChartApplyTemplate 的 true 单独判断已加载。

首次 Enabled=0 不允许 EA 使用；后改 Enabled=1、AllowLiveTrading=0 并设置 Charts/ProfileLast 独立空白 profile。第二次仍失败，最终增加同步诊断/初始化等待后通过。**未单独隔离并证实全部失败根因**，不把猜测写成已证实平台缺陷。原始源码/参数/模板/日志/结果均在 G4/；原机器时间不重写。重试次数为3，不隐去失败。

边界：证明平台支持共享文件和人为 run_id 命名空间。没有证明自动防串跑、原子状态提交、租约互斥、重启恢复、崩溃接管、跨终端竞争或 RE-30 已通过。两个 tester run 使用开发日期2026-08-03至04、Model4，只运行文件探针；不是 Real Tick 策略成绩，也未读取冻结 OOS。

## 5. G5 对照 PLAN §4.1

| 计划项目 | 当前 I18 源码证据 | 缺口/验收 |
|---|---|---|
| 累计6盈或6亏 | 1712按 wins>=6 OR losses>=6；从历史重算，不是连续计数 | SOURCE VERIFIED；实际阈值触发 NOT OBSERVED |
| 服务器换日 | DayStart(TimeCurrent)，以服务器日分组；最终结束日计数 | 历史时区/DST、午夜无Tick/恢复 RE-31 NOT RUN |
| 完整Setup | 从 position 归并原入场 order；终态及全部平仓后计数（1881–1900） | 不按每个 Deal 数笔；复杂部分成交/晚费用仍需运行验收 |
| 净成本 | 累加 profit+commission+swap+fee；净零另列，不重复扣成交价点差 | 延迟入账/未关联费用及历史完整性未证明 |
| 跨日持仓 | 最终平仓服务器日期 DayStart（1897） | SOURCE VERIFIED，边界运行 NOT RUN |
| 重启/多实例 | account/server/symbol/USER_SCALP 作用域文件；FILE_COMMON；独占文件句柄/持久化后回读 | 现行CSV单文件不是 v1.1 A/B持久化；实际重启/争用 NOT RUN |
| 换Magic | 文件键不含magic，但选定 OnInit 强制 magic=26082152 | 不可据此宣称任意magic迁移不丢计数；待正式 identity map 机制 |
| 排除其他策略/手工 | magic匹配 **OR** GSM50_S_ 注释前缀被认作归属 | 不能严格保证排除伪造/复用注释的其他/手工单；Claude须收紧归属方案 |
| 日锁与挂单 | Maintain重算、无效/日锁/在途时取消归属挂单；AllowNewRisk先核对日锁与在途 | 仅源码，不宣称实际撤单和阈值锁定已通过 |
| 换日与其他锁 | 每日计数/日锁更新，在途字段独立保留 | 新风险层各锁隔离仍要 RE-31 |
| 旧连续暂停 | InpScalpPauseAfterStreak/Hours仍存在，UpdateScalpPause只有定义无调用；8820注释说明日规则替代 | 不重新启用旧连续暂停；本轮未改变用户SOP |

当前研究版 OnInit（2040以后）拒绝全部非 Tester，故局部函数非 Tester 分支不能被描述成“该版本已在 Demo/live 绕过日锁开仓”。这是对 Claude 预冻结 review X10 的范围纠正；X11应记录旧函数不可达，而非直接推定旧暂停正在运行。

I10历史标签 PASS_OBSERVED_NATIVE_DAILY_NET6_6 不代表观察到六盈/六亏日期；相关 observed_locked_days 为空。I18也未观察到触发日。RE-31a–l 完整验收仍 NOT RUN。G5完成的是现状及差异取证，不是日锁合格证。

## 6. 阅读范围、未决项与下一步

已阅读本次执行指令、根AGENTS/CLAUDE、项目README/CLAUDE、PLAN重点§2.1/4.0/4.1/6/8/9、COLLABORATION、正式v1.0、v1.1全文差异、核对表、454dc9a旧取证、I18选择和交付文件，以及当前七源码相关身份/槽位/日锁路径。CURRENT.json已解析并读取I18与当前相关字段，未逐项重审全部历史轮次。

指标库核对提交 c1a0021f2a6db562f9e791e620c08352a743e6ca；已读README/manifest、套装使用与验证说明、SMC/SND/SNR接口全文，以及ADX接口/验证。ATR/VFI的组合读取曾截断，尚需补齐；没有宣称逐个指标全部源码审计。既往合成指标检查不等于这轮策略成绩。接入前需继续验证闭柱、EMPTY_VALUE、MTF、参数槽、历史快照及对应EX5身份。

G1/G3/G5：SOURCE EVIDENCE COMPLETE WITH LIMITATIONS；G4：PLATFORM PROBE PASS WITH FAILED ATTEMPTS RETAINED。跨账户活动EA冲突、RE-29/30/31、策略收益/晋级依然未验证。评分 N/A / SCORE_TARGETS_UNSET。

交 Claude 按核对表第三节独立复核这些证据，重点确认保留版而不是全部I18候选、S4部分成交槽位差异、S7严格归属和历史费用完整性。Claude a36d57d 的预冻结审阅还提出稳定实例身份、map hash规范化、租约原子性与无Tick时钟等设计问题；由双方在草案讨论解决。RE-30双终端竞争不是用户本阶段G4前置条件，不新增固定终端以满足它。

本次没有替换正式接口、改现行交易源码、启动七策略新回测或形成新收益成绩。第一阶段双方复核尚未完成，暂不准备正式升级PR，更不合并main。上一轮S4 B5证据保留，完整执行一致性仍不能据本探针标为通过。

平台参数参考：[MT5启动配置](https://www.metatrader5.com/en/terminal/help/start_advanced/start)、[模板加载语义](https://www.mql5.com/en/book/applications/charts/charts_tpl)。结论以本目录原生日志为准。
