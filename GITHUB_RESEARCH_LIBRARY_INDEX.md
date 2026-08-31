# GSM GOLD 3-SOP EA GitHub Research Library Index

## Storage rule

This index stores research knowledge only. It does not store copied external source code or failed Candidate ZIPs.

An external idea must pass:

`Read -> License -> Understand -> Clean-room reimplementation -> Single-strategy Candidate -> Compile -> Real Tick -> Train/OOS -> FxPro + Tradona -> Champion comparison`

Research IDs such as `V3.21-GHxx` are ideas, not implemented or validated Candidates.

## Champion evaluation order

All Strategy Champion and Combined Champion comparisons use this priority order:

1. Net Profit USD
2. Max Equity Drawdown
3. Profit Factor
4. Trade Count
5. Win Rate

Drawdown remains a risk veto even though the primary objective is Net Profit USD.

## GSM source doctrine used to judge GitHub ideas

External GitHub ideas are Optimization Candidates only. They must not silently replace the GSM Base SOP.

Current source-level constraints recorded from the user's GSM materials:

- Supply & Demand: zone, not line; prioritize fresh First Touch; do not trade repeated used zones as if fresh.
- Support & Resistance: zone, not line; repeated touches increase significance; distinguish major/minor and good/bad zones.
- Candlestick: strongest when occurring at/near relevant support/resistance/zone; confirmation is required by the handbook framework.
- Chart Pattern: treat patterns as confirmation structures, not standalone prediction engines; confirmation comes before pattern/price execution.
- Three engines remain independently researchable: Scalping M5, Intraday M30, Swing.

## Priority sources — Batch A

### mehdi-jahani/GoldTraderEA

- Repository: https://github.com/mehdi-jahani/GoldTraderEA
- Reviewed commit: `ba329266c56372c36da9f81fac35983b9fc2e4a3`
- License observed: no repository license
- Code copied: NO
- Study modules: Candle Patterns, Support/Resistance, Multi-Timeframe
- Intended lanes: Intraday and Swing confirmation/quality Candidates

### francomascareloai/EA_SCALPER_XAUUSD

- Repository: https://github.com/francomascareloai/EA_SCALPER_XAUUSD
- Reviewed commit: `b0087e93c8af6690102c6698b8123186703a9240`
- License observed: PolyForm Noncommercial with repository restrictions
- Code copied: NO
- Study modules: Market Structure, BOS/CHoCH, Order Block, FVG, Liquidity, Risk Architecture, Entry Optimizer, ONNX
- Intended lanes: primarily Intraday; later Swing, Combined risk, and AI score research

### frank-quant/ai-trading-videos

- Repository: https://github.com/frank-quant/ai-trading-videos
- Reviewed commit: `3b0c48c47ffeb42b0a2aecbdcaeb99618c9bc4e7`
- License observed: MIT
- Code copied: NO
- Study module: Research methodology, Candidate comparison, Train/OOS discipline

## Priority sources — Batch B (added 2026-08-31)

### samw2591/gold-quant-trading

- Repository: https://github.com/samw2591/gold-quant-trading
- Reviewed commit: `c8827bb939f791a4c6a02b010db979a45061cc04`
- License observed: no LICENSE file observed in reviewed root
- Code copied: NO
- Architecture: Python signal engine + MT4 execution bridge, JSON/file communication
- Study modules: Keltner breakout, MACD + EMA100 trend, NY ORB, M15 RSI mean reversion, ATR sizing, daily loss/cooldown, sentiment/news observation, economic-calendar guard
- Research engineering value: extensive backtest/A-B/cost-adjusted/consistency scripts; useful for Champion-vs-Candidate methodology and anti-lookahead discipline
- Intended lanes: research framework first; Intraday trend/session ideas second; not a direct MQL5 module source
- Warning: author-reported backtests are not GSM validation. Re-test independently.

### RobertN1D/GOLD-EA-MT5-WITH-OPENAI

- Repository: https://github.com/RobertN1D/GOLD-EA-MT5-WITH-OPENAI
- Reviewed commit: `20ccd77cab7838842a6c9571702ac94c0216cd7c`
- License observed: no LICENSE file observed in reviewed root
- Code copied: NO
- Architecture: MT5 XAUUSD M1 EA with RSI/EMA/ATR/Bollinger + AI BUY/SELL/WAIT layer, dashboard, telemetry, order retry handling and tick-level trailing
- Study modules: AI context builder/parser, AI timeout/fallback, execution telemetry, tracked-ticket trailing, broker rejection handling
- Intended lanes: later AI Confidence/Ranking research; execution/telemetry research now
- Rule: AI must not directly replace GSM direction/entry logic. Test `Base SOP` vs `Base SOP + AI score` only after core SOP is stable.

### n30dyn4m1c/gold-pro-scalper

- Repository: https://github.com/n30dyn4m1c/gold-pro-scalper
- Reviewed commit: `7794c91e6803d8ede4bec5ee36001dd46c5dade3`
- License observed: MIT
- Code copied: NO
- Architecture: MQL5 XAUUSD/GOLD M1 mean-reversion and dual mean-reversion/breakout variants
- High-value study modules: closed-bar/once-per-bar decisioning, Z-score extremes, ADX ranging/trend separation, round-trip cost gate, real-tick robustness, server-side TP, volatility-aware/wide stop design, loss cooldown, separate magic numbers
- Intended lanes: Scalping engineering research, especially `SPREAD_COST`, real-tick noise, late/false exit, execution cadence and regime detection
- Rule: mean-reversion entry itself does not replace GSM M5 S&D First-Touch SOP. Candidate modules must be isolated.
- Risk warning: repository includes very aggressive small-account risk tiers; do not inherit them automatically.

### Lin-Thet-Zaw/xauusd5mTimeFrameAndDailyTFrame

- Repository: https://github.com/Lin-Thet-Zaw/xauusd5mTimeFrameAndDailyTFrame
- Reviewed commit: `1fb31b5c639aa7b5b043dcff5f47cd8f6e030648`
- License observed: no LICENSE file observed in reviewed root
- Code copied: NO
- Repository reality: reviewed root contains several compiled `.ex5` files and a README; compiled binaries are not reverse-engineered or treated as transparent research evidence
- README study ideas: H1 trend filter, M15 confirmation, M5 execution, broker request-rate/HFT safety, pending-order expiry hazards, Fibonacci retracement/swing confirmation concepts, break-even/trailing examples
- Intended lanes: execution safety and MTF/Fibonacci concept research only
- Warning: performance claims in README remain author claims until independently reproduced with inspectable source and our Real Tick conditions.

### foeed/FvgGold-EA

- Repository: https://github.com/foeed/FvgGold-EA
- Reviewed commit: `a8a521c2c6e619a5f9fc7f80cad63242d1e236b5`
- License observed: MIT
- Code copied: NO
- Architecture: MQL5 XAUUSD M15 FVG EA with Order Block confluence, H1 EMA50/200 trend, London/NY killzone, quality scoring, break-even and daily loss guard
- Study modules: FVG detection, displacement score, freshness score, HTF alignment score, premium/discount context, OB overlap, zone-edge pending entry
- Intended lanes: Intraday and Swing zone-quality Candidates; later confluence-score research
- Rule: FVG/OB are Optimization Layers. They do not replace GSM Supply/Demand Base zones unless Real Tick A/B proves a better Candidate under the same SOP constraints.
- Warning: README performance claims must be re-run under FxPro + Tradona Real Tick and OOS before any Champion decision.

## Current research mapping by problem

### WRONG_TREND

Priority study sources:
- francomascareloai: BOS/CHoCH/Market Structure, MTF
- samw2591: EMA100 + ADX trend separation, ORB/session context
- foeed: H1 EMA50/200 HTF alignment score

### SL_TOO_TIGHT

Priority study sources:
- francomascareloai: dynamic risk / entry / stop architecture
- n30dyn4m1c: real-tick robust stop and cost-aware exit design
- foeed: zone-edge + buffer logic

### LATE_ENTRY / SPREAD_COST

Priority study sources:
- francomascareloai: Entry Optimizer
- n30dyn4m1c: round-trip cost gate, closed-bar/tick robustness, turn confirmation
- RobertN1D: order execution retries, ticket telemetry, trailing behavior

### First Touch / Zone Quality

Priority study sources:
- mehdi-jahani: S/R and candle modules
- foeed: FVG freshness + OB overlap as optional confluence
- GSM source doctrine remains authoritative for First Touch behavior

### Swing low trade count

Priority study sources:
- mehdi-jahani: higher-TF confirmation
- francomascareloai: Market Structure / SMC
- Lin-Thet-Zaw: Fibonacci retracement concept (README only; verify independently)

### AI / ML — later stage only

Priority study sources:
- RobertN1D: AI request/context/fallback architecture
- francomascareloai: ONNX / regime concepts
- samw2591: sentiment pipeline and non-blocking observation approach

AI is initially `score/rank/observe`, not an autonomous replacement for the GSM SOP.

## Current priority problems

1. WRONG_TREND
2. SL_TOO_TIGHT
3. LATE_ENTRY
4. First Touch Detection
5. Swing low trade count

## Champion boundary

Current status on 2026-08-31:

- Best Scalping Champion: `NONE`
- Best Intraday Champion: `NONE`
- Best Swing Champion: `NONE`
- Best Combined Champion: `NONE`

No `champion/current/` directory or Champion ZIP may be created until a Candidate passes the formal dual-broker Real Tick and OOS gates.

When a real Champion exists, GitHub should store only the Champion ZIP for release/archive. Research notes and rejected-result summaries may remain as text knowledge so future Codex sessions do not repeat the same exploration.
