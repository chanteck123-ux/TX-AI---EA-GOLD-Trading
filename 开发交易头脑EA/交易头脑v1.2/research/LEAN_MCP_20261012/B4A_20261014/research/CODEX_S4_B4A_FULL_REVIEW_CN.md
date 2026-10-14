# S4 B4A 全月独立核对 — 2026-10-14

结论：已完成实际 LEAN 全八月回测及 Codex 分层逐笔比较。修正按 flags 更新 Bid/Ask 后，75个已武装信号、34条门控决策、56笔预留、56笔入场、56笔完整交易在比较器规定字段与容差内全部与原生 D4BF2385 一致。29次保本请求、28次确认及同一笔未确认事件也一致。不是新策略盈利改善，而是报价模型修正。

条件：USD500、GOLD、2026年八月已使用开发数据、250ms、S4风险2%、双槽、BE1.25R、TP1.5R。原入场、风控、退出及共享核心不变。首次smoke失败、修正smoke通过及全月证据均保留；全月复用通过smoke的同一DLL，没有重新编译全月DLL。

| 指标 | MT5原生基线 | LEAN B1 | LEAN B4A |
|---|---:|---:|---:|
| 净利润USD | 102.03 | 36.58 | 102.03 |
| 完整交易净PF | 1.464343 | 1.178631 | 1.464343 |
| 完整交易 | 56 | 56 | 56 |
| 已记录佣金USD | 5.14 | 4.97 | 5.14 |
| LEAN/EA逐Tick回撤USD | 35.88 | 37.05 | 35.88 |
| LEAN/EA逐Tick相对回撤% | 6.071916 | 6.458867 | 6.071916 |

MT5测试器原生最大净值回撤另为33.22USD / 5.5903205117%。这与EA自身CaptureEquity记录是两个口径：原生D4BF2385_equity_curve.csv期末明确记录max_equity_dd=35.88、max_equity_dd_pct=6.0719160921，与B4A一致。证据及CSV哈希见CODEX_S4_B4A_NATIVE_CUSTOM_DD.json。不得把两者差值宣称为策略退化，也不抹除原生值。B4A RESULT逐Tick最大回撤在核心每Tick计算，equity_curve.csv仅每分钟输出，不能凭该CSV单独重建完整最大回撤。原生统计算法的精确差异尚未证明。

全月20,513,403原始行逐行匹配，1行初始报价未就绪跳过，20,513,402行进入核心；无无效报价、无未匹配原始行、无窗外Tick。225次内部对账，最大TPV差约3e-12，数量、费用、清算估值与缓存无不匹配。当前13项源码及config/result/compile.log合计16项哈希核对全部通过。匹配DLL SHA256：2cb73f6ed9b7ab46a3769ec5e1f531461082d263f2a2ff487b0cd157771b3b57。

比较器只证明其比较字段与容差内一致，不证明所有毫秒级事件或完整账户路径一致。保留250ms到期后下一行处理、同步OrderSend阻塞/跳过回调、保证金与Stop Out校准、未暴露隔夜费等既有模型限制。无跨期/OOS、成本压力、Demo或实盘验证；评分N/A / SCORE_TARGETS_UNSET，无Champion。

本轮没有修改或编译MQL5，不提供虚构的新EX5；原MQ5/EX5保持恢复点。Claude独立复审已请求，收到后单独记录，不把请求等同完成。

证据：CODEX_S4_B4A_LAYERED_COMPARISON.json、CODEX_S4_B4A_IDENTITY_CHECK.json、CODEX_S4_B4A_NATIVE_CUSTOM_DD.json及runs/S4B4A_FULLAUGUST_D250_20261013T155148Z_3f926243。

Claude独立复审已完成：S4_B4A_FULL_REVIEW_CN.md及独立重跑比较器报告S4_B4A_CLAUDE_LAYERED_COMPARISON.json，同口径回撤和比较字段结论一致。其标题中的‘不是路径不同’只解读为本次已检查字段与最大回撤结果一致；没有完整逐Tick原生序列对照，不能外推全路径或所有时间语义一致。后续研究在既有授权内先登记再执行，无须把文档中的建议当作新增许可要求。
