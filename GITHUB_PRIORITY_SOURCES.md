# GitHub Priority Research Sources

## Mandatory rule

这两个来源由用户指定为 Priority Sources。研究人员必须深入实际源码，不得只读 README；任何进入 GSM 的逻辑都必须独立重新设计、独立实现、独立编译与回测。外部作者的收益数字或完成度声明不能替代我们的证据。

## Source A: mehdi-jahani/GoldTraderEA

- Pinned commit: `ba329266c56372c36da9f81fac35983b9fc2e4a3`
- Priority: Candlestick、Support/Resistance、Price Action、MTF。
- License gate: 未发现根 LICENSE、COPYING、NOTICE 或明确源码使用授权，因此 `Can Copy Code = NO`。
- README 中 PF 2.8、287% return、14.2% drawdown、68% win rate 只登记为作者声明。未见可由本项目复现的原始 MT5 报告，不能作为 Candidate 或 Champion 成绩。

优先提取 Idea：closed-candle reversal group、repeated-touch S/R validation、不同时间框架方向信息。不得沿用其 forming-candle、固定 H4/D1/W1 或固定百分比 tolerance 实现。

## Source B: francomascareloai/EA_SCALPER_XAUUSD

- Pinned commit: `b0087e93c8af6690102c6698b8123186703a9240`
- Priority: Structure、BOS/CHoCH、Entry Quality、ATR/Structure SL、MTF soft score、Risk、Execution；SMC 与 ONNX 排后。
- License gate: PolyForm Noncommercial 1.0.0，并有 `TRADING_RESTRICTIONS.md`。`Can Copy Code = NO` for GSM。
- 项目 README 明确说明仍是 active research/engineering、不是完成产品、不保证盈利且不 production-ready。这是工程研究库，不是可直接交易的 EA。

允许的 GSM 行为仅限：阅读、静态审计、记录抽象 Idea、clean-room 独立实现。禁止把其源码或派生实现接入 FxPro/Tradona 实盘、Demo/Paper 或商业场景。

## Evidence hierarchy

1. 我们保存的 pinned commit 与源码观察。
2. MetaEditor `0 errors, 0 warnings`。
3. FxPro Real Tick Train/OOS。
4. 冻结参数后的 Tradona Real Tick OOS。
5. 三策略拆分、信号漏斗、Loss/Missed Audit 与 Broker Reject。
6. Champion 对比与 KEEP/REJECT 决策。

README 宣称、Star 数、截图和作者回测表不进入第 2 至第 6 层。

## Candidate order

`GH01 BOS -> GH02 CHoCH -> GH03 Entry Quality -> GH04 ATR/Structure SL -> GH05 Intraday Candle -> GH06 Swing Candle -> GH07 S/R Validation -> GH08 MTF Soft Score -> GH09 SMC Zone Quality -> GH10 Risk Architecture`

ONNX/AI/ML 当前为 `PARKED`。每个 Candidate 只能改变一个主要变量；失败项保留在 `research/rejected/`，不能悄悄并入下一项。



## Local provenance

- Local research commit: `48cbb00`
- Champion EA source changed: `NO`
- External source code copied: `NO`
