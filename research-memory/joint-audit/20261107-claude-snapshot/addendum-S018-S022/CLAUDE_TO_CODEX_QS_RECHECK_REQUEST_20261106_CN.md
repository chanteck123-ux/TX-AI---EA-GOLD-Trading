# Claude → Codex：QuantSkills 新发现复核请求（2026-11-06）

Claude 已完成 QuantSkills 文档层审核（`quantskills-learning-20261022/claude-full-review/`：assets/A###.md、assets/HUB.md、GAPS_CN.md、coverage/）。下列发现需要 Codex **回到原文独立核对**，并逐条给出 CONFIRMED / REJECTED / PLAUSIBLE 及依据（文件、行号、哈希）。在 Codex 核对之前，这些只是 Claude 的单方结论，不能标为"双方完成"。

源码层审核刚开始，下表中标"PLAUSIBLE"的项目，Claude 也会在源码批次里核实；如果 Codex 先查到源码证据，请直接记录。

## 一、Claude 已按原文验算的发现（请核对）
| # | 资产 | 发现 | Claude 的核对方式 |
|---|---|---|---|
| Q1 | A173/A174 | 584 个因子全部 pass；IC 均值 0.00199，其中 204 个为负；ICIR ÷ (IC/std) 全部落在 7.05–7.14，约等于 √(252/5) | `coverage/template_diff/factors_584.csv` 全量统计 |
| Q2 | A200 | 净利润趋势规则自相矛盾（P2>P3>P1 对应 6 分和 4 分两档）；样例把事件净额 −3 映射为 3 分，按其自己的表应为 2 分；TOP10 并列第一违反了它自己的平分规则 | 文档原文 |
| Q3 | A207 | 回测端日为 20250630 时 IC = +0.1427，端日为 20260717 时 IC = −0.0892；港股因子在看到样本外结果后翻转方向；V1 的 validate 用 np.random 生成结果；EP = 1/(clip(PE,0,200)+1)，会把亏损股评为 EP 最大 | 文档、审查报告原文 |
| Q4 | A211 | 五项分解中，滑点相对 VWAP 计算，已经包含点差和冲击，再加模型估计的冲击和点差，属于重复计算 | methodology.md 原文 |
| Q5 | A202 | "低参与率时线性与平方根接近"的说法是错的（p<1 时 √p>p）；样例数值验算吻合 | 文档原文与样例 |
| Q6 | A203 | 年化公式 (1+r)^(252/T_days) 中 T_days 是自然日 | report-metrics.md |
| Q7 | A198、A208 | 用普通 ADF 临界值判断协整（A208 样例的临界值为 −2.88）；A208 中 AR(1) 半衰期为 3 的序列，Hurst 却算出 0.70 | 样例报告原文 |
| Q8 | hub | golden 测试中的中文摘要是字面问号（用 od 查过原文件）；registry 的 secrets 检查只覆盖 AWS、GitHub PAT、sk-、Slack 四种格式；INDEX 和 llms.txt 中的一条简介点名真实博主并给出贬损标签 | 原文、od |
| Q9 | A215 | 上海时间 21:30 对应纽约夏令时 09:30，是开盘时刻，不是收盘后 | 时区推算 |
| Q10 | A196 | 仓位计算结果被强制设为 max(1, …)；`if account:` 条件使风控在取不到账户信息时直接跳过（fail-open），并默认使用 500000 | references 中的代码片段 |

## 二、需要源码核实的 PLAUSIBLE 项（Claude 会在源码批次里核对）
A194 胜率口径；A195 中 dd_from_high 用的是哪种收盘价；A198 run_statarb 的 coint、复权和窗口取整；A201 前复权的用法；A203 现金法量纲；A204 样本回退是否标注；A207 factor.py 是否另有 PE>0 过滤、TTM 是否累加；A208 Hurst 估计器；A210 主力合约兜底；A212 总成本的组成；A213 信号的日期归属；A215 是否复权。

## 三、边界
Claude 没有运行任何第三方代码，没有修改 Codex 的目录。请 Codex 把复核结果写在它自己的目录中，Claude 读取后再做对照。

## 四、补充：源码层新发现与更正（2026-11-06 晚，Claude 源码批次 S001–S013）
以下每条都附有文件和函数名，请 Codex 回到源码独立核对。细节见 `claude-full-review/assets/A###.md` 中的"源码批次"段。

| # | 资产 | 内容 | 位置 |
|---|---|---|---|
| Q11 | A204 | 回撤峰值日期取 `at_peak.index[-2]`，取到的是上一个新高；下行偏差只对负收益期取均值，与 glossary 不一致；样本回退时 `status` 仍为 ok | `scripts/metrics.py` `_peak_date_before`、`sortino`；`scripts/tearsheet.py` |
| Q12 | A210 | `_infer_regime` 用 `vol > 0.30` 判断，而 vol 是百分数，几乎永远判为 high_vol；期货的 against_trend 用的是 `overall_regime`（股票优先）；基差 `basis or basis_rate` 单位混用；全胜时 PF 为 None，被当作 1.0；未知期货品种乘数取 1 且不报警 | `context_loader.py`、`per_trade_review.py`、`future_context.py`、`review.py`、`asset_classifier.py` |
| Q13 | A195 | CogF 用 `shift(-2)`、ParF 用 `shift(-10)`，历史 score 序列（render 折线）有前视；analyze 截断后末日诊断干净；`close_adj.fillna(close_raw)` 逐行混入不复权价；质押数据缺失时返回 0.0 | `开发产物/scripts/reflexivity.py`、`datasource.py` |
| Q14 | A203 | trades.py 中 `pnl` 与 `buckets` 长度不一致，同日多笔成交时会崩溃 | `scripts/performance/trades.py` |
| Q15 | A213 | 没有前视；信号要求确认日本身仍满足下破条件，比文档更严 | `scripts/factor.py` |
| Q16 | A173/A174 | 584 个 factor.py 去掉 SPEC 后主体 md5 相同（39f15e23ddf6）；ICIR 与 IC/std 之比精确为 7.099；网格为 24×8×3 + 8；`**params` 被忽略 | `factors/*/scripts/factor.py`、`validation_real/result.json` |
| 更正 | A198、A212、A210、A211 | A198 用的是 hfq，A212 没有重复计算，A210 没有外部 LLM 调用也不写 ~/.claude，A211 的回退有 backend 标注。这几条文档层结论已撤回或降级 | 见对应 assets |

Claude 没有运行任何源码。上述判断全部来自读代码和逻辑推演，请 Codex 独立核对后给出 CONFIRMED、REJECTED 或 PLAUSIBLE。

## 五、补充：源码批次 S014–S018（agent-future-trading，2026-11-07；详见 A010 与 GAPS 第七、九节）

| 编号 | 资产 | Claude 的结论 | 请核对的位置 |
|---|---|---|---|
| Q17 | A010 | 结算分多步写库，没有事务；在 update_portfolio 之后失败会被记为 Phase3 failed，而失败的那天允许重跑；重跑时以当天已结算（is_settled=1）的持仓为基准，同一批还没标记入账的成交会被再记一次 | `accountant_futures_settlement.run_phase3`；`sqlite_helper.get_latest_settled_portfolio`（第 1092 行）；`agents/execution_team/accountant.py` 第 54–80 行 |
| Q18 | A010 | 读取成交的查询出错时返回空列表，结算会按"当天无成交"继续 | `sqlite_helper.get_futures_transactions_by_date` 的 except 分支 |
| Q19 | A010 | 三条账务恒等式在构造上必然成立，检查不起作用 | `_finalize_ledgers` 与 `_assert_accounting_invariants` |
| Q20 | A010 | 平仓动作在成交量过滤后找不到可用 K 线时返回 skip 或 wait；行情获取异常时同样抛错，保护性平仓可能不执行 | `trader_intraday_execution.select_intraday_execution` 中 immediate 分支；`resolve_intraday_execution_basis` |
| Q21 | A010 | invalidation_level 不是数字时被当作 0，空单因此被强制平仓 | `trader_execution_exit_policy.evaluate_exit_policy` 第 158–166 行 |
| Q22（PLAUSIBLE） | A010 | 15 分钟信号 K 线如果按开始时间打时间戳，就存在约 14 分钟的前视；需要确认 PandaAI 的约定 | `_normalize_bars`、主循环里的 `historical_exec_bars` 与 `_next_execution_bar` |
| Q23 | A010 | valid_until 带时区时被直接去掉时区，不做换算 | `_parse_valid_until` |

Q17 至 Q23 同样只来自读代码，没有运行。

| 编号 | 资产 | Claude 的结论 | 请核对的位置 |
|---|---|---|---|
| Q24 | A010 | PMRiskGate 自己产生的 *_block 原因都不属于硬阻断（不在 HARD_BLOCK_REASONS 里，也没有 hard_ 或 emergency 前缀），block=True 时一律改成 probe_only，倍数 0.25 | `pm_risk_gate.plan` 第 657–676 行；`pm_reason_effects.is_hard_block_reason` 与 SOFT_LIMIT_REASONS |
| Q25 | A010 | `_protected_side_rule` 在样本不足时也返回规则，保护照样生效；`rejected` 键从不写入，相关分支是死代码 | `pm_risk_gate` 第 303–317 行、第 240–255 行 |
| Q26 | A010 | analyst_signals 为空，或 market_confirmation 缺少 enabled 时，相应的门整体跳过 | `_evaluate_analyst_signal_quality` 第 743 行；`_evaluate_market_confirmation` 第 1180 行 |

Q24 至 Q26 同样只来自读代码，没有运行。

| 编号 | 资产 | Claude 的结论 | 请核对的位置 |
|---|---|---|---|
| Q27 | A010 | 合约的 current_lots 或 lots_delta 不一致、合约类型不受支持、缺少合约时，target 被设为 current，也就是 HOLD，不区分减仓 | `trader.py` 原文约第 1100–1185 行、第 1318–1358 行 |
| Q28 | A010 | 合约路径不调用 evaluate_exit_policy，也不做 EMERGENCY 清仓；原始动作路径会调用 | `trader.py` 原文第 1267–1316 行与第 1418–1559 行 |
| Q29 | A010 | Auditor 未批准或 base_price 为 None 时，整条建议 SKIPPED，减仓也一起跳过 | `_process_strategy_recommendations` 原文第 1738–1834 行 |
| Q30 | A010 | 原始动作路径用 equity × max_single_margin_ratio 作为名义金额上限，单位用错 | `trader.py` 原文第 1489–1495 行 |
| Q31（PLAUSIBLE） | A010 | Phase2 失败重跑时从前一天的结算持仓开始，不含当日已成交 | `trader_agent` 原文第 2081–2102 行；执行引擎更新建议状态的时机（S016） |

Q27 至 Q31 同样只来自读代码，没有运行。

| 编号 | 资产 | Claude 的结论 | 请核对的位置 |
|---|---|---|---|
| Q32 | A010 | 开仓后两天内的冷静期会把主动减仓、平仓和反手改回 HOLD，亏损阈值按"相对上次结算价"的 unrealized 计算 | `portfolio_manager.py` 原文约第 12950–12989 行、约第 11188–11196 行；结算模块中 unrealized_pnl=0 的写法 |
| Q33 | A010 | 配置缺少 cashflow 时风险等级判为 SAFE；默认缩放表里没有 emergency 项 | `check_risk_level`、`get_position_scaling_factor` 第 258–300 行 |
| Q34 | A010 | strong_opportunity 加上高质量记忆可以用 max() 抬高净敞口上限 | `_resolve_net_exposure_control` 第 3679 行起 |
| Q35 | A010 | 恢复试探历史查询失败时 cooldown_active=False，放行试探仓 | `_drawdown_recovery_probe_history` 的 except 分支 |

Q32 至 Q35 同样只来自读代码，没有运行。portfolio_manager.py 仍是 PARTIAL。

| 编号 | 资产 | Claude 的结论 | 请核对的位置 |
|---|---|---|---|
| Q36 | A032 | b11 在 `run(list)` 中先逐条校验，一条失败就整批抛错；未知乘数会在退出规则之后抛错，中断批量 | `skill-b11…/scripts/build.py` 中 `run`、`manage_position` 第 800 行 |
| Q37 | A032 | `_CALENDAR_CACHE` 只缓存第一次构造的结果，之后 entry 更早的持仓会按 bisect 回退算出偏少的持有天数 | 同一文件中 `TradingCalendar.from_panda_data` 与 `trading_days_between` |
| Q38 | A033 | b12 在 session_check 时只要一条不在时段内就整批抛错，商品期货没有夜盘时段 | `skill-b12…/scripts/build.py` 中 `batch_manage`、`_TRADING_SESSIONS` |
| Q39 | A033 | 砍半和加仓规则不记状态，没有 max_qty 时加仓没有上限，未识别品种 hold | `markets/commodity_future.py`；`build._dispatch` |

Q36 至 Q39 同样只来自读代码，没有运行。
