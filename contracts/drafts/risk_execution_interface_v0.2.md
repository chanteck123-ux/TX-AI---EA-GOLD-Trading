# Risk / Execution Interface v0.2 — 双 AI 联合审查候选

状态：DRAFT / NOT FROZEN。依据 Claude v0.1 review（blob 7c313de997ffb6a87eec26cd021342d7ca987e68）整合；尚未编译、回测或 Demo 验证。
范围：MQL5 EA Core ↔ Risk/Execution 接口、MT5 单执行器队列与验收。修改跨模块契约须双方批准。

## 1. 模块归属及禁止绕行
- Codex：Core、信号、指标接入、编译/回测执行器、Git 整合；Claude：RiskExecution、订单提交/改单/平仓、持仓保护、成交对账、验收用例。
- Core 只创建 TradeIntent / ExitIntent 并转发事件；**禁止**直接 OrderSend、CTrade.Buy/Sell/PositionClose/PositionModify。
- 所有实盘风险及保护在 EA 本地 MQL5 运行，不依赖 Python、外部 AI 或网络协调器。服务器已接受的 SL 与本地“期望 SL”分开保存。
- 所有距离和金额显式单位：_price（价格单位）、_points（MT5 Point）、_usd（仅 USD 账户；否则用 _account_ccy）、_pct、_seconds、_lots。读取 SYMBOL_POINT、SYMBOL_TRADE_TICK_SIZE、合约与账户币种；不得混用 pip、Point、价格单位。

## 2. OnInit / OnTick / OnTimer / OnTradeTransaction 契约
OnInit：读取 ACCOUNT_MARGIN_MODE、品种交易参数、持仓/挂单/成交历史、持久审批及在途状态；启动恢复对账。初始化失败时禁止新入场，但继续尽可能执行安全的持仓保护/告警。

OnTick **必须先处理持仓后才能执行任何新开仓门控或提前 return**：
1. execution.ReconcileState()：容忍部分数据不可用，标记不确定状态。
2. execution.ManagePositions()：已持仓的初始 SL 修复、保本、追踪、待处理保护动作和退出请求。
3. Core 更新新 K 线时钟/已评估标志（不可放在点差/新闻/时段门控之后）；信号只使用已收盘 K 线。
4. 执行仅针对新开仓的点差、时段、新闻、入场有效期等门控。
5. Core.BuildEntryIntent() → execution.EvaluateEntry(intent, approved) → execution.SubmitEntry(approved)。
6. Core 生成 ExitIntent 时，**不受入场门控影响**，经 execution.SubmitExit()；需要退出时应在步骤 2 的保护阶段或之前排入，不因步骤 4 return 丢失。
OnTimer：ReconcileState、ManagePositions、处理待保护/退出队列；无 Tick 时不得伪造新报价或宣称已执行。
OnTradeTransaction：Core 无条件转发 trans/request/result 至 execution.HandleTradeTransaction()；由执行模块按订单/成交/持仓标识做幂等对账，处理乱序、部分成交和服务器 retcode。事件只是线索，最终以服务器可核对的订单、持仓及成交记录为准。

## 3. 类型及函数（语义草案；MQL5 签名待编译确认）
- TradeIntent：candidate_id、strategy_id、magic、symbol、direction、signal_bar_time、created_at、expires_at、expected_entry_price、initial_sl_price、tp_price、risk_budget_account_ccy、max_price_deviation_price、配置版本/hash。
- ApprovedTrade：approval_id、intent_digest、approved_lots、expected_loss_account_ccy、portfolio_loss_account_ccy、issued_at、expires_at、quote/account/positions fingerprint。由 RiskExecution 内部签发和存档，结构体自身不构成授权。
- ExitIntent：exit_id、strategy_id、symbol、position_identifier/ticket、exit_kind(FULL/PARTIAL/EMERGENCY)、requested_lots、reason、expires_at。按当前实际持仓方向/数量及 volume step 约束，禁止净额账户意外反向开仓。
- ExecutionResult：status、retcode、order_ticket、deal_ticket、position_identifier、requested_lots、confirmed_lots、message、timestamp。状态 PENDING 不等于成交。
- RiskResult EvaluateEntry(const TradeIntent&, ApprovedTrade&)：**一次**用 OrderCalcProfit（或核实的合约属性）估算真实可用手数、初始 SL 损失、交易成本、现有持仓和在途订单的组合风险；无法满足最小手数不向上凑。
- ExecutionResult SubmitEntry(const ApprovedTrade&)：检查内部签发 ID、未使用、有效期、账户/价格/风险/品种条件；原子地占用审批并建立 strategy_id+symbol 在途锁，然后发单；同 ID 不可重复提交。
- ExecutionResult SubmitExit(const ExitIntent&)：幂等 exit_id、校验持仓/成交量，统一执行全平/减仓/紧急退出。
- ProtectionResult ManagePositions()：仅收紧保护性 SL；按正确 Bid/Ask、tick size 归一化；确认服务器修改成功才更新已生效 SL。
- ReconcileResult ReconcileState()：服务器持仓、挂单、成交历史和本地持久记录对账；不能把“读取失败”解释为“无持仓”。
- void HandleTradeTransaction(trans, request, result)：幂等处理请求/订单/成交，更新实际风险、在途及保护状态。

## 4. 入场时效及在途状态
- 新 K 线标记必须独立于门控更新；每个 strategy_id+symbol+signal_bar_time 只评估一次，或按事先冻结的显式重试政策处理。
- 仅使用已收盘 K 线信号；signal_bar_time 和 created_at、max_entry_delay_seconds、max_price_deviation_price 在 policy.json 登记。门控阻断后不能在同一根 K 线晚些时候悄悄追单。
- 在途状态：PENDING_SUBMIT → SENT → PARTIAL / FILLED / REJECTED / EXPIRED；PARTIAL 可能继续在途。超时**先对账**，确认无未完成订单及相关持仓/成交后才能解锁；数据不确定时保持阻挡并告警。
- 实际成交后以成交均价、累计成交量、佣金/预估剩余费用和有效 SL 重算单笔及组合风险；超过预登记容差时，按 policy 指定的减仓/暂停新入场/告警方案处理。不能把暂停新入场误称为已消除既有超额风险。
- 部分成交：保护已成交量；剩余挂单按预登记 cancel_remainder 或 keep_remainder 政策处理，防止重复补单；每次新增成交重新核对风险。

## 5. 账户模式、保护与净成本保本
- 读取 ACCOUNT_MARGIN_MODE。对冲：按 magic + POSITION_IDENTIFIER/position ticket 跟踪，正确处理 ticket 变化。净额：同品种仅一个真实持仓；v1 禁止不同策略共同占用该品种，返回 REJECT_NETTING_CONFLICT，不实现虚拟子仓。平仓前核对方向与数量。
- 初始 SL 必须按策略设定；若成交后发现缺失，优先补设，不能确认安全保护时执行预登记的紧急政策并告警。
- SL 只朝降低风险/锁利方向移动；多单新 SL 不得低于已生效 SL，空单不得高于已生效 SL。设置 minimum_sl_step_price；检查 SYMBOL_TRADE_STOPS_LEVEL、SYMBOL_TRADE_FREEZE_LEVEL、tick size、Bid/Ask；冻结区/距离不合法时不发请求，保留现有 SL，等待重试。服务器拒绝不能静默，pending protection 记录保留。
- 净收益保本：计算在**指定 SL 价格成交**时的净 P/L = OrderCalcProfit(方向, 品种, 实际手数, 实际成交均价, SL价格) + 已发生/预计佣金 + 已发生 swap + 预计其他平仓费用 - 预留滑点成本；求使净 P/L >= 0 的 SL（可用 tick size 离散搜索）。已体现在成交价中的点差**不重复扣**；佣金和 swap 使用带符号现金流避免重复。SYMBOL_TRADE_TICK_VALUE / TICK_SIZE 只作交叉检查，特殊合约优先 OrderCalcProfit。止损成交价可能因跳空/滑点偏离，故不保证净利非负。

## 6. 状态码和恢复
状态枚举（函数可附 retcode、错误文本、是否待处理）：
OK_CONFIRMED、OK_PENDING、REJECT_RISK、REJECT_VOLUME、REJECT_IN_FLIGHT、REJECT_NETTING_CONFLICT、REJECT_APPROVAL、REJECT_MARKET、REJECT_STOPS_LEVEL、RETRYABLE、FAIL_SERVER、DATA_UNAVAILABLE、PROTECTION_PENDING、RECONCILE_REQUIRED。
- OK_CONFIRMED 仅用于经服务器记录确认的动作；发送请求成功返回 OK_PENDING。
- REJECT_RISK / VOLUME / NETTING / APPROVAL / IN_FLIGHT：禁止提交，留审计记录。
- REJECT_MARKET：放弃入场；保护/退出保持待处理并在市场可用时重试。
- REJECT_STOPS_LEVEL：入场放弃或重新审批；保护保留旧 SL、待条件满足再试。
- RETRYABLE：按 policy 有限重试；先核对请求是否已被服务器接受，防止重复下单。
- FAIL_SERVER：记录原始 retcode；保护/退出进入告警及待处理队列。
- DATA_UNAVAILABLE / RECONCILE_REQUIRED：阻止新入场；继续能安全执行的保护；不确定在途锁不得释放。
- 任何失败不得放宽服务器已生效 SL。服务器拒绝后不得提前更新“已生效”状态。

## 7. 队列、实验与故障注入
- Claude 只新增不可变 research/queue/pending/<run_id>.json；Codex 单执行器是状态的**唯一写入者**，管理 running/completed/failed 和恢复。Git 文件不是互斥锁；执行器用本机文件锁及 run_id 去重。单一 MT5 Tester，不绕过终端占用。
- 每批 policy.json 在测试前双方审核冻结：测试数据、资金、账户模式、成本、评分锚点、实验次数上限、风险政策、max_entry_delay_seconds、max_price_deviation_price、approval_ttl_seconds、inflight_timeout_seconds、max_retry_count、post_fill_risk_tolerance_pct、partial_fill_remainder_policy、minimum_sl_step_price、emergency_unprotected_position_policy。无已冻结锚点总分 N/A；失败试验计入预算。
- 故障注入仅测试构建可编译启用（例如专用 TEST_FAULT_INJECTION 宏），生产构建不包含可开启故障注入的代码路径；部署检查二进制构建配置及哈希。模拟拒单、部分成交、断线和乱序事件；不能把注入测试当作 Demo 的真实服务器验证。

## 8. 验收矩阵（Claude 22 项，状态全部 NOT RUN）
| ID | 场景 | 通过条件 | 方式 |
|---|---|---|---|
| RE-01 | 点差门控 + 已持仓追踪 | 仍更新追踪 SL | T |
| RE-02 | 新闻门控 + 已持仓保本 | 仍执行保本 | T |
| RE-03 | 试图放宽 SL | 拒绝，旧 SL 不变 | T |
| RE-04 | 0.30 手部分成交 0.10 | 保护已成交量、剩余按 policy、重算风险 | F |
| RE-05 | 重启发现无 SL 持仓 | 补设或按紧急政策处理并告警 | T/D |
| RE-06 | 重启遗留在途锁但无服务器订单/持仓 | 核对后解除并记录 | F |
| RE-07 | 修改 SL 被拒 | 旧 SL 不变、保留待处理 | F |
| RE-08 | SL 修改遇冻结区 | 不提交、保留旧 SL | T |
| RE-09 | 审批已过期 | REJECT_APPROVAL | T |
| RE-10 | 同审批重复提交 | REJECT_APPROVAL | T |
| RE-11 | 审批后行情/点差大变 | 拒绝旧审批 | F |
| RE-12 | 在途再次触发信号 | REJECT_IN_FLIGHT | T |
| RE-13 | 滑点致风险超容差 | 执行登记的超额风险政策 | F |
| RE-14 | 净成本保本 | 成本不重复计点差，目标净 P/L >=0（假设按 SL 价成交） | T |
| RE-15 | 合规手数低于最小手 | REJECT_VOLUME，不向上凑 | T |
| RE-16 | 已有持仓再入场 | 组合风险计入已有及在途风险 | T |
| RE-17 | 减仓量超过实际持仓 | 不反向开仓 | T |
| RE-18 | 净额账户第二策略同品种入场 | REJECT_NETTING_CONFLICT | D |
| RE-19 | 休市时紧急退出 | 待处理，开市重试 | T |
| RE-20 | 跳空穿过 SL | 记录实际与预计损失差 | T |
| RE-21 | 对账部分读取失败 | 可安全保护的持仓仍执行 | F |
| RE-22 | 无 Tick | Timer 仍尝试对账和保护 | T |

T=策略测试器；F=故障注入；D=Demo。测试器的 Timer、跳空及部分成交模拟能力受环境限制，必要时辅以可控单元/集成测试，不伪称已验证服务器行为。

## 9. 尚待双方冻结的决定
1. 具体第一轮账户是对冲还是净额；RE-18 是否作为第一轮阻断验收。
2. 每批 policy 数值由 Claude 提案、Codex 审查后共同冻结；没有依据时保留 TBD，不预填“10%”等示例阈值。
3. 部分成交剩余量：策略在 TradeIntent 中可请求政策，但执行模块只允许 policy 白名单并负责落实；默认行为待定。
4. 净额账户 magic 与仓位归属的冲突判定、重启时持久记录存放与恢复机制、在途锁跨进程持久化格式。
5. 生产构建与测试构建的编译脚本/配置、故障注入不可达的验证办法。

## 10. 交接要求
每次交接附 candidate_id、run_id、branch、commit_sha、改动范围、已执行测试、源码/参数/EX5 哈希、编译日志、原始报告路径、未解决问题。审查完整受影响调用路径而非仅 diff。
