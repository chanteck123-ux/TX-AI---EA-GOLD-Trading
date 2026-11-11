# Claude 阅读断点（2026-11-08 第六次更新，按用户选定的"分层完成"执行）
- 分层计划见 `CLAUDE_TIERED_COMPLETION_PLAN_20261107_CN.md`。
- **Codex 复核安排（用户 2026-11-08）**：等全部读完后统一交给 Codex 复核一次。期间新增的 Q/R/E 条目都是"待汇总、尚未发出"。

## QuantSkills
- 源码批次 S001–S022 已完成，另完成第 2 层 S-DATA1（csv/jsonl 结构核对）。
- **UNREAD 4,032**（FULL_READ 2,192，PARTIAL 11，DIFF_VERIFIED 4,089）。
- 第 1 层（执行和风控路径）基本完成：
  - agent-future-trading：执行、结算、盘中执行、PM 风险门、trader.py 全文；portfolio_manager.py 只读了风险函数，约 1,150 / 13,790 行，状态为 PARTIAL。
  - b11 止盈止损、b12 日内仓位的源码；两者的 test.py 仍未读。
  - 已用关键词搜索其余未读代码，命中 55 个文件，清单在 `quantskills-learning-20261022/claude-full-review/coverage/unread_exec_keyword_hits_20261107.txt`。经核实，macro-driven-rotation 的"对账"是研究报告与数据的核对，portfolio-guardian 是因子健康监控，两者共 46 个代码文件标为**第 4 层延后**。
- 第 1 层可选补充：portfolio_manager.py 中与仓位预算有关的函数，即 `_apply_position_budget_policy_for_new_entry`（第 1840 行）、`_one_lot_probe_risk_check`（第 2113 行）、`_step4_capital_plan`（第 2753 行）。
- 之后进入第 3 层：各技能的 tests 和 test.py 先按结构归组。

## Kronos
- 论文正文与全部表格已读完（2026-11-08，REVIEW2 D3）；图片只读了图注。
- E1、E2、E7、E8、E9 留到最后统一交给 Codex 复核。

## LEAN
- L001–L016 已完成；第 2 层完成 L-DATA2、L-DATA3、L-DATA4（Tests/TestData）；第 3 层已从 L017 开始（用户 2026-11-08 选 A：第 3、4 层全部做完）。
- 当前覆盖：**UNREAD 3,289**（2026-11-10，L156 之后；Tests 约 664 个、Common 1,972 个、Data 652 个、lean.ico 1 个；FULL_READ 比 L148 之后增加 195 个）。
- **L149–L156（2026-11-09 至 11-10）**：
  - Tests 代码清单 `tests_code.txt` 共 846 个，第 1–195 个（T1–T8）已 FULL_READ。范围：Tests/Algorithm、Framework、Api、Brokerages、Common/Brokerages、Commands、Auxiliary、Common/Data 合成器。
  - 待汇总新增：R49（RiskExecution：穿零拆单、券商消息锁序、或有订单的重建与支持矩阵、撤单幂等、FXCM 价格区间）、R50（合成器回调里 `Consolidated` 仍是上一根）、R48(e)（FileCommandHandler 使用 TypeNameHandling.All）。
  - 测试会写入实际 Data 目录（SPDB 及 factor/map zip），运行前须备份。
  - 笔记为 `batches/L149-_tests_CN.md`。
  - 下一步：Tests 第 196–846 个（T9 起），然后是 Common 1,972 个，最后是 Data。
- **L143–L148（2026-11-09）**：
  - 小目录全部完成：代码批次 M1–M7 共 210 个文件，非代码文件 87 个。
  - 待汇总新增 R48：Optimizer 和 Report 只用 Sharpe 等口径；QuantBook 的胜率口径；Jupyter 容器无认证。
  - 笔记为 `L143-L148_misc_CN.md`。
  - 下一步：Tests 859 → Common 1,972 → Data 652（zip 只记录方法）。
- **L137–L142（2026-11-09）**：
  - Engine 目录剩余 208 个文件全部完成，UNREAD 0。
  - 待汇总新增 R47：填充 bar 复制前一根 OHLC，且会进入合成器、指标和形态；填充分辨率取全局最小值；交易时段外的 bar 被丢弃。
  - 笔记为 `L137-L142_engine_CN.md`。
  - 下一步：剩余小目录，即 ToolBox 57、Report 54、Brokerages 33、Optimizer 18、Logging 15、Research 14 等，之后是 Tests 859 和 Common 1,972。
- **L125–L136（2026-11-09）**：
  - Indicators 目录 233 个文件全部完成，UNREAD 0。
  - 待汇总新增 R42–R46：
    - R42：ATR 的平滑方式随构造方式不同；
    - R43：EMA 和 Wilders 均以 SMA 起步；
    - R44：Stochastic 慢线公式及 MAX/MIN 相等值的处理；
    - R45：IndicatorBase 不拦截时间相等的重复输入，多品种指标须时间对齐；
    - R46：Pivot 确认延迟、ZigZag 重绘、IntradayVwap 在 CFD 上不可用、SharpeRatio 指标的单位问题。
  - 笔记为 `L125-L129_indicators_CN.md` 和 `L130-L136_indicators_CN.md`。
  - 下一步：Engine 目录（208 个）。
- **L115–L124（2026-11-08 至 11-09）**：
  - Algorithm 目录 59 个文件全部完成。之前的第 1 层阅读漏掉了这个目录下的下单入口，本次已补读。
  - 待汇总新增 R39（回测订单上限 10,000 后算法停止；休市时市价单被改成 MOO；Liquidate 会撤掉 SL/TP）、R40（默认纽约时区与服务器日；SetBrokerageModel 的调用顺序；回测日志合并重复消息；最小订单保证金为组合价值的 0.1%）、R41（CFD 上的 TradeBar 历史和指标；MAX/MIN 默认取收盘价；预热会重置指标；K 线形态不会自动预热）。
  - 笔记为 L115–L124 的 5 份。
  - 下一步：Indicators 目录（233 个）。
- **L109–L114（2026-11-08）**：Algorithm.Framework 86 个文件全部 FULL_READ。新工具 `tools/dump_src.sh <base> <list> <out>`。笔记为 `L109-L114_framework_tier4_CN.md`。新增待汇总 R38（Framework 风险模型按 bar 检查后市价平仓，不是止损单；组合回撤模型只处理本期 targets）。下一步：Algorithm 剩余的 59 个。
- **断点（2026-11-08）**：
  - 第 4 层 C# 示例 L025–L071 和 Python 示例 L072–L108 全部完成，**Algorithm.CSharp 与 Algorithm.Python 均为 UNREAD 0**。
  - Python 用 `tools/next_batch_py.sh` 和 `tools/print_example_py.sh`，清单是 scratchpad 里的 `py_unread_sorted.txt`，共 470 行，已经读完。
  - 笔记最后一份为 `L104-L108_python_tier4_final_CN.md`。
  - 下一步：Algorithm.Framework（86 个）→ Algorithm 剩余的 59 个 → Indicators、Engine → Tests 859 个 → Common 1,972 个 → 其余小目录。
  - 待汇总新增 R31（年化交易日数）、R32（QuoteBar 取中间价）、R33（两种胜率口径）、R34（decimal 与 double 在均线交叉处的差异）、R35（括号单子单延迟成交、撤销 OCO 会连带撤掉止损、OTO 市价子单与父单同时成交；补充 2：等待触发的子单不计入 open remaining quantity）、R36（OrderEvent.quantity 是订单数量而不是本次成交量；异步市价单的撤单竞态）、R37（自定义成交和购买力模型须在报告中登记）。
- 各批笔记在 `lean-full-review-20261101/claude/batches/`，近几批是：
  - L013：统计口径、结果采样、主循环、Paper 券商、品种属性与交易时段；
  - L014：交易管理器补完、交易时段数据库；
  - L015：回测结果分析器与 ResultsAnalyzer；
  - L016：基准夏普、无风险利率、IResultHandler。
- `LiveTradingResultHandler` 和 `RegressionResultHandler` 标为第 4 层延后，原因是 V1.2 中 LEAN 只用于研究。
- **第 1 层已基本完成。** 第 3 层结构归组无效（898 和 470 个示例各自成一组），改为用 `tools/print_example.sh` 逐个文件阅读。V1.2 相关示例 173 / 173 个已全部读完（L017–L024），另读了 2 个 XAUUSD 历史数据示例和 AlgorithmSettings.cs；新增待汇总 R28（CFD/外汇默认无 swap）、R29、R30。下一步：其余示例（C#、Python、Framework），然后是 Tests。

## 方案 B
- b7ee115 已推送，等待 Codex 复审。这是另一项独立任务，不受上面"统一复核"安排的影响。
- 2026-11-08：Codex 已复审 R5 并开 Draft PR #20（801674f）。Claude 对 P1 的独立复审已提交 f608bc0（分支 `review/claude-pr20-r5-20261108`）。结论：R5 五项和 C2 接受，C1 须修正锁来源检查（RE-30p (5) 与 (7b) 矛盾）。等待 Codex 修改，再复核这几行。PR 保持 Draft，未取得用户合并批准。
