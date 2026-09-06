# 外部参考仓库审查

## 审查范围

- 参考仓库：[`samw2591/gold-quant-trading`](https://github.com/samw2591/gold-quant-trading)。
- 默认分支：`main`；本次固定提交：`c8827bb939f791a4c6a02b010db979a45061cc04`。
- 审查方法：通过 GitHub 读取该提交的完整文件树、文档和相关源码，进行静态路径审查；未执行其交易程序，未复跑其回测，未验证其收益。
- 许可证：本次仓库元数据的 `license` 为 `null`，该提交文件树未发现 LICENSE／COPYING。没有把其实现复制到本项目；仅记录问题和借鉴分析方法。
- 该仓库为 Python＋MT4 桥接系统，策略包含 Keltner、MACD、ORB、RSI。它不是 GSM 三套 SOP，也不能成为本项目的 Champion。

## 具体发现与本项目处理原则

| 发现 | 固定提交的证据 | GSM Gold Python Analyzer 的处理原则 |
| --- | --- | --- |
| 上游承认旧回测提前读取尚未收盘的 H1，并以信号 bar 的 Close 作为成交价；文档要求旧实验重新验证。 | [activeContext.md](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/docs/memory-bank/activeContext.md)、[changelog.md](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/docs/memory-bank/changelog.md) | 不采信旧收益、PASS、零过拟合或零破产结论；历史否决实验也不能直接成为本项目的否决证据。 |
| 当前入场信号增加了已收盘 H1 限制，但 SL／TP 覆盖、调仓、entry_atr 和出场仍存在读取当前未闭合 H1 ATR／分位的路径。不能认定整个引擎已消除未来数据。 | [engine.py，入场与出场调度](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/backtest/engine.py#L328-L357)、[SL／TP 与手数](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/backtest/engine.py#L739-L775)、[H1 窗口](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/backtest/engine.py#L964-L1001) | 区分 bar 开始、结束、指标可用时间和决策时间；入场特征只能使用当时已知数据，出场调整也遵守相同边界。 |
| 共享追踪函数在浮盈回落至启动门槛以下时提前返回，即使之前已经激活且价格越过已有追踪线，也可能漏检。 | [exit_logic.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/strategies/exit_logic.py#L45-L67) | 激活状态与首次启动条件分离；已激活保护持续有效，重启恢复后不得重新等待启动门槛。 |
| OHLC 回测用同根 High 抬高 BUY 追踪线，再用同根 Low 检查触发，无法证明两者真实先后；SL／TP 同根触及固定按 SL 优先。 | [engine.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/backtest/engine.py#L394-L446) | OHLC 分析不能证明逐 Tick 成交路径；最终交易行为须通过 MT5 真实 Tick 核实。 |
| 名为 ATR 的字段实际为 14 根 High−Low 的简单均值，未计相对前收盘的跳空；ADX 内部则使用 True Range。RSI／EMA 的 EWM 初始化也不能假定与 MT5 相同。 | [signals.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/strategies/signals.py#L32-L80)、[runner.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/backtest/runner.py#L69-L95) | 指标必须声明公式、周期、平滑与初始化；分析代理指标不能冒充 EA 原指标。 |
| rr 是平均盈利／平均亏损而非 PF；零收益被放入亏损组；Sharpe 只用有平仓的日期并使用 ddof=0；max_dd_pct 是最大金额回撤对应的百分比。 | [stats.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/backtest/stats.py#L20-L66) | 分开定义 PF、实际盈亏比和零收益交易；最大金额回撤与最大相对回撤各自求最大值。 |
| 日常追踪文件的 equity 等于初始资金加已实现盈亏，不含浮盈亏；其回测引擎另有含未实现盈亏的权益曲线。 | [position_tracker.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/position_tracker.py#L231-L238)、[engine.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/backtest/engine.py#L359-L361) | 根据数据来源确认字段语义。只有已实现收益时报告余额回撤，净值回撤保持缺失。 |
| MT4 数据缺失会回退到 GC=F COMEX 期货；仓库历史文件为 Dukascopy Bid H1／M15／M5 bars，不是用户的 FxPro 原始 Tick。 | [README.md](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/README.md)、[data_provider.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/data_provider.py#L28-L44)、[备用品种](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/data_provider.py#L91-L95) | 缺 FxPro 数据就明确报告缺失，不自动换品种或供应商；这些 bars 不能证明 FxPro 从 2024-03 开始的真实 Tick 覆盖。 |
| 手数四舍五入后再抬到最低手数，可能突破预算；源码例子本身展示了 100 美元预算变为 112.5 美元风险。 | [signals.py](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/strategies/signals.py#L709-L735) | 使用实际合约、初始 SL、费用和向下手数步长；最小手数超预算时标为不可执行，不借用其资金参数。 |

追踪状态问题的静态构造例：BUY 开仓价 100、ATR 10、普通分位时，价格 106 可激活并产生 104.5 的追踪线。下一次价格 104，已越过保护线，但浮盈 4 小于启动门槛 5，函数会提前返回无退出理由。这是依据源码推导的反例，不是 MT5 回测结果。

## 可以借鉴的日志与研究流程

[`log_missed_signal()`](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/position_tracker.py#L212-L227) 记录时间、策略、方向、信号价、SL／TP、原始理由和拦截理由。这有助于复盘，但仅保留最近 500 条，缺少唯一候选 ID 和明确时区；部分[趋势门控](https://github.com/samw2591/gold-quant-trading/blob/c8827bb939f791a4c6a02b010db979a45061cc04/gold_trader.py#L394-L441)又在信号扫描前返回，不能将其记录数当作完整漏斗。

本项目采用追加式诊断事件，明确运行、候选、阶段、事件和时间；缺少事件就标为未观测。被过滤不等于错失盈利，历史成交也不能单独证明某项保护应当删除。

研究方法可借鉴单模块实验、成本压力、参数邻域、失败记录和开发／验证／最终 OOS 分离。最多三个候选改进必须从用户自己的 EA 证据出发；Python 筛选结果不等于 MT5 真实 Tick 验证，不以反复调参获得漂亮成绩为交付目标。
