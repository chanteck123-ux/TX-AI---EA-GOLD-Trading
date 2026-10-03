# S5：已被 TP 平仓后的管理请求审计修复

状态：**UNIMPLEMENTED；仅是修复规格，没有修改 EA、验证器或产生新测试。**

本次 I7 的 S5 八月 1000ms 原生回测已完成，但严格审计失败，必须保留为 AUDIT_INVALID。不要重跑覆盖失败，也不要修改本轮冻结解析器把它改为 PASS。问题是一个管理请求缺少有证据、可关联的非成功终态，不是有证据显示期末还留着仓位。

## 固定父版本与证据

- MQ5：`C:/Users/A/Documents/Codex/2026-09-10/v1-2-ea-mt5/work/repair_research/mt5_iteration6_20261002/S5_M5_FIRST_PROGRESS/source/TB500_S5_M5_FIRST_PROGRESS.mq5`
  - SHA256：`d9bcb8e386574c9b66c8895b881e1b12ba47aac88e9d154fc2ab419efe582b08`
- EX5：`C:/Users/A/Documents/Codex/2026-09-10/v1-2-ea-mt5/work/repair_research/mt5_iteration6_20261002/S5_M5_FIRST_PROGRESS/session/private/builds/ac7fc29af7474d3c8fc2488c7202c6d1/TB500_S5_M5_FIRST_PROGRESS.ex5`
  - SHA256：`ab9a9a530ae98351ef9e128784fe18fa020abf7989451f1b87424ef03d76071a`
- 原输入：上述 `S5_M5_FIRST_PROGRESS/native_params.json`；SHA256 `65e28f7d48c4ce75f8f9c7ab031f5dfc5d328084f7cb99c6d68fb89ef94499a7`。
- 本次失败 run_id：`1A6A42FD`；USD500、GOLD、真实 Tick 模型4、八月2026、1000ms。仅为已使用开发期。
- 完整失败复审：`C:/Users/A/Documents/Codex/2026-09-10/v1-2-ea-mt5/work/repair_research/mt5_iteration7_20261003/independent_review/S5_AUGUST_DELAY1000_STRICT_FAILURE_REVIEW.json`
  - SHA256：`5b2ce99e245a2b227c2a347f0b31ef1b71cfa6e82b199e4771d0fa1a9bed2016`
  - 绑定注册、原生 receipt、HTML、失败 stderr、恢复记录、27个原生文件和32个冻结输入/工具文件。

## 已核实的触发过程

1. 2026.08.28 08:30:01，native order/deal22 做空0.01手，实际开仓4581.85；原SL4586.90，TP4581.43。
2. EA 记录初始实际风险5.22 USD，高于当时预算5.0829，提交 `ENTRY_RISK_OVERRUN_REQUESTED`，request_id12、position22、0.01手。
3. native order/deal23已由 TP 全平：买入4580.94，comment=`tp 4581.43`；完整仓历史净额+0.83，exit_reason=5。这只是孤立生命周期证据，不是本月可接受成绩。
4. 该超预算市价平仓请求返回 retcode10036、send_return0；它**没有被证明执行成功**，不能把服务器TP成交归给它。
5. 源码3147行清除 `manage_pending`、登记 `MANAGEMENT_REJECT`。2855行的通用 `POSITION_CLOSED` 不含独立请求终态关系。相关原始时间字段可能采用旧 quote 时间；不要凭缓存审计时间强行推出毫秒内事务先后。
6. 冻结审计器列出1笔 `UNRESOLVED_EXECUTION_RESULTS`。现有 `MANAGEMENT_ENDED_POSITION_CLOSED` 仅支持 kind1、零数量的SL修改；不得借给kind2市价平仓。
7. 这不是期末补漏：11个完整仓/22笔deals已闭环，8月31日期末空仓，最后成交8月28日，期末快照后没有成交。native end supplement正确拒绝覆盖请求异常。

## 本候选只允许解决这个问题

请 Claude 提出最小代码补丁：管理请求返回已平仓时，先核对对应 owned position 的真实成交历史、开平量、剩余量、策略归属与真实结束原因，再记录**与该 request_id、请求类型、position identity 绑定的非成功终态**。必须区分“仓位已由别的原因结束”和“本请求成功成交”，不伪造 `MANAGEMENT_CONFIRMED` 或成功返回值。

若历史尚未可用、只有ticket消失、仍有余量、属于另一策略/请求，保留可重试或待对账状态；重启及重复回调不能重复终结、重复下单或重复计盈亏。MQL5自身处理，不依赖AI/Python在线。保存请求身份所需的状态；具体字段/事件名由Claude提出，先复审再冻结。

不改S5入场、第一根M5进度检查、初始SL/TP、风险1%、手数、成本规则、S4风险、其他策略和用户Scalping SOP。不要通过放宽预算、删除风险超标检测、忽略10036、接受所有POSITION_CLOSED或移除严格检查来绕过问题。原源码默认值保持一致；新文件名和candidate_id，不覆盖父版本。

## 修复验证与交付

先给出最小diff及请求状态转移说明，由Codex和Claude复审。若新终态需要新的解析支持，另建有版本的验证政策并事前登记；冻结的I7审计器及I7失败结论保持不动。

验证至少包含：①真实TP全平后10036的非成功终态；②没有历史/只丢ticket时不误判；③部分平仓仍有余量；④其他请求/策略/position不能借用结果；⑤重复、乱序回调及重启幂等；⑥成本和完整仓只记一次；⑦原正常SL修改、正常市价平仓及超预算保护未退化。不得为了造出PASS弱化原失败条件。

必要编译后，用新候选预登记受影响原生测试，至少覆盖相同八月1000ms触发场景及已有正常场景。新成绩只能使用新候选、新源码/EX5、新报告与新验证记录；若价格行为未改变，也需检查逐笔差异。源码默认值、EX5、参数、编译日志、测试证据与SHA256配套交付。此文件不代表上述开发或测试已开始。

## v2 补充：修复后对照不能复用旧基准

源码修复后须冻结新candidate_id、新MQ5/EX5及版本化验证政策，重新跑同一八月的250ms与1000ms一对原生测试；不能把旧源码的250ms结果充当新源码的同版本基准。此为后续有界规格，不增加本轮I7的10次预算，也未启动新测试。正常路径的信号、订单、初始SL/TP、手数和成本逐笔回归；差异按真实执行路径归因，不能宣称审计修复自然提高盈利。必要的工程边界测试另记，不无限追加参数搜索。

已逐一核对本轮选定S1–S6六个源码：它们都有相同的10036清pending并记MANAGEMENT_REJECT分支，详见COMMON_MANAGEMENT_SCOPE_REVIEW.json。但本轮10次实际原生结果只在S5八月观察到这一种send_return=0请求。共享分支说明应安排针对性回归；不代表所有策略都已发生此故障，也不代表审查了全部旧版本。Scalping不在本次共享分支检查范围。第一步仍限定S5审计修复；扩展共享模块前逐个确认影响并单独登记，不能自动批量替换全部EA。

价格说明：4581.85到TP4581.43相差0.42是GOLD报价的价格单位，不等于0.42个MT5 Point。此诊断不据此变更止损、目标或风险。
