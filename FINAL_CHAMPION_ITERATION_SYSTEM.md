# Final Champion and GitHub Research Iteration System

## Authority

本文件是 GSM GOLD 3-SOP EA 从 2026-08-31 起的正式开发制度。若旧文档的指标顺序、Candidate 命名或 Combined 假设与本文件冲突，以本文件为准。

最终评价顺序固定为：

`Net Profit USD -> Max Equity Drawdown -> Profit Factor -> Trades -> Win Rate -> Reject`

Reject 必须为 0。DD 有风险否决权，不能用更高 Net 自动覆盖不可接受的回撤。

## Four Champion lines

1. `SCALPING_CHAMPION`：M5 Scalping 单独开启。
2. `INTRADAY_CHAMPION`：M30 Intraday 单独开启。
3. `SWING_CHAMPION`：D1/H4/M30 Swing 单独开启。
4. `COMBINED_CHAMPION`：三个已锁定单策略 Champion 重新组合后的完整 EA。

Combined 盈利不能证明三个策略都优秀；三个单策略盈利也不能证明 Combined 一定优秀。

## Candidate names

| Lane | Candidate | Branch |
|---|---|---|
| Scalping | `S-C01` | `research/scalping/<topic>` |
| Intraday | `I-C01` | `research/intraday/<topic>` |
| Swing | `W-C01` | `research/swing/<topic>` |
| Combined | `C-C01` | `research/combined/<topic>` |

`V3.21-GHxx` 只代表 GitHub Research Idea，不代表源码已经实现或回测。

## Fair single-strategy test

每个 Candidate 只能改变一个主要变量，且只能开启对应策略。Champion 与 Candidate 必须相同 Broker、Symbol、Capital、Leverage、Real Tick 日期、模型、Spread/Commission、Risk 和基础执行设置。

每个 Broker 固定输出：

| Version | Net USD | Max Equity DD | PF | Trades | Win Rate | Reject |
|---|---:|---:|---:|---:|---:|---:|

并输出 `Delta Net`、`Delta DD`、`Delta PF`、`Delta Trades`、`Delta Win Rate`。

Training 选参数，OOS 只验证。读取 OOS 后不得回头调参并仍称该段为 OOS。

## Strategy lanes

Scalping 研究只影响 Scalping Engine，包括 Zone、Departure、First Touch、Retest、closed reversal candle、Spread、Slippage、Entry Distance、SL/TP 和风险。

Intraday 研究只影响 Intraday Engine，包括 Trend、S&D、Zone、Candlestick、MTF、BOS/CHoCH、ATR/Structure SL、Entry Quality 和 Session。

Swing 研究只影响 Swing Engine，包括 D1 Framework、H4 Trend、S/R、S&D、Pullback、Candlestick、Structure、SMC、Trailing、Protection、ATR 和 Fibonacci。

未被研究的两个 Strategy Champions 必须锁定，源码与参数不得顺手修改。

## Combined candidate

任何 New Strategy Champion 都触发新的 Combined Candidate。Combined 必须重新编译和双经纪商 Real Tick，不得把三个独立净利润相加当作组合结果。

Portfolio Audit 至少检查：并发仓位、保证金、总风险、同向暴露、对向信号、Hedging/Netting、Capital Allocation、Position Sizing 和 Drawdown Overlap。

组合变差时，三个独立 Champion 继续保留；只建立 `C-Cxx` 研究 Portfolio Risk，不回写已锁定策略逻辑。

## Champion lock and history

每个 Strategy Champion 与 Combined Champion 都有版本、源码哈希、SET 哈希、报告指标和测试条件。只有相同条件下的 Candidate 真正打赢它，才能解除锁定。

历史链分别记录：

- Scalping：Previous -> Candidate -> New Champion。
- Intraday：Previous -> Candidate -> New Champion。
- Swing：Previous -> Candidate -> New Champion。
- Combined：Previous -> Candidate -> New Champion。

## Delivery ZIP

只有真正出现 New Combined Champion 才生成 Champion ZIP。至少包含：

```text
CODE/
SETS/
CONFIG/
REPORTS/SCALPING/
REPORTS/INTRADAY/
REPORTS/SWING/
REPORTS/COMBINED/
RESEARCH/CHAMPION_COMPARISON/
BEST_SCALPING/
BEST_INTRADAY/
BEST_SWING/
FINAL_REPORT_CN.html
CHAMPION_MANIFEST.txt
SHA256.txt
```

FINAL_REPORT 首页依次显示 Best Scalping、Best Intraday、Best Swing 和 Best Combined，字段顺序必须为 Net、DD、PF、Trades、Win Rate、Reject。

用户收到的 ZIP 与 GitHub `champion/current/` 必须是同一文件，文件名、版本、SHA256 和报告指标完全一致。

## GitHub assets

GitHub 分为两类长期资产：

1. Champion Archive：只保存 `champion/current/` 的当前 Champion ZIP 和 `champion/history/` 的旧 Champion ZIP。
2. Research Knowledge Base：保存来源、License、算法、相关 SOP、目标问题、独立实现思路、测试摘要、KEEP/REJECT 和失败原因。

失败 Candidate 不保存大型 ZIP，只保存 Markdown/CSV 摘要，防止未来重复测试同一个失败 Idea。

## Current state

截至 2026-08-31：

- Best Scalping Champion: `NONE`。
- Best Intraday Champion: `NONE`。
- Best Swing Champion: `NONE`。
- Best Combined Champion: `NONE`。
- V3.00 是历史参考，不是锁定 Champion。
- V3.10 与 V3.20 均不合格。
- Candidate 开发保持暂停，直到用户明确恢复。
