# GSM GOLD 3-SOP EA — Final Champion, Optimization, Optional AI Research & Program Governance Standard

## 0. Authority and Current Assumption

This file is the **highest-level development, optimization, validation, research, program-governance, and Champion-management standard** for GSM GOLD 3-SOP EA.

If any older document conflicts with this file on metric order, Candidate naming, Combined assumptions, Research handling, AI collaboration, or program flow, this file takes precedence.

Current operating assumption: a formally validated `REAL CURRENT CHAMPION` already exists:

```text
SCALPING M5 CHAMPION
INTRADAY M30 CHAMPION
SWING CHAMPION
3-SOP COMBINED CHAMPION
```

From this point forward:

```text
CHAMPION = the only formal baseline
Candidate VS Champion = the only promotion path
```

Final evaluation order is fixed:

```text
#1 Net Profit USD
#2 Max Equity Drawdown
#3 Profit Factor
#4 Trade Count
#5 Win Rate
```

`Reject` target must be 0.

`Max Equity Drawdown` has risk-veto authority: a higher Net Profit cannot automatically justify unacceptable drawdown, margin stress, or blow-up risk.

---

# 1. Highest-Level System Architecture

```text
GSM SOP AUTHORITATIVE FOUNDATION
        ↓
3 INDEPENDENT STRATEGY ENGINES
  ├─ SCALPING M5
  ├─ INTRADAY M30
  └─ SWING D1/H4/M30
        ↓
OPTIONAL OPTIMIZATION / RESEARCH MODULES
        ↓
SIGNAL / EVIDENCE / CONFIDENCE
        ↓
RISK ENGINE
        ↓
PORTFOLIO MANAGER
        ↓
EXECUTION ENGINE
        ↓
MT5
        ↓
REAL TICK
        ↓
TRAIN / OOS
        ↓
FxPro / Tradona
        ↓
WHEN REQUIRED: WALK FORWARD / STRESS TEST
        ↓
TRADE AUDIT + MISSED OPPORTUNITY AUDIT
        ↓
Candidate VS Champion
        ↓
REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER / NEW CHAMPION
```

GSM SOP defines what valid trading logic is.

GitHub, external EAs, AI, or any other Research source only provides ideas worth testing. No Research logic may enter a Champion without independent validation.

---

# 2. Four Champion Lines

The system permanently maintains four independent Champion lines:

1. `SCALPING_CHAMPION`: M5 Scalping enabled alone.
2. `INTRADAY_CHAMPION`: M30 Intraday enabled alone.
3. `SWING_CHAMPION`: D1/H4/M30 Swing enabled alone.
4. `COMBINED_CHAMPION`: full 3-SOP EA rebuilt from the three locked engine Champions.

At all times the system must be able to answer:

```text
Current Scalping Champion = ?
Current Intraday Champion = ?
Current Swing Champion = ?
Current Combined Champion = ?
```

A Champion line must never have two formal Champions at the same time.

Each Champion must be traceable by:

- Version
- Source SHA256
- SET SHA256
- Broker
- Symbol
- Capital
- Risk Budget
- Actual Risk
- Real Tick Period
- OOS Period
- Metrics
- Final Report

A profitable Combined result does not prove every Engine is individually strong; profitable standalone Engines do not prove the Combined portfolio is strong.

---

# 3. Candidate Naming and Provenance

Canonical Candidate IDs:

| Lane | Candidate | Suggested Branch |
|---|---|---|
| Scalping | `S-C01` | `research/scalping/<origin>/<topic>` |
| Intraday | `I-C01` | `research/intraday/<origin>/<topic>` |
| Swing | `W-C01` | `research/swing/<origin>/<topic>` |
| Combined | `C-C01` | `research/combined/<origin>/<topic>` |

Suggested `origin` values:

```text
user
standard
codex
claude
single-ai
hybrid
external
github
```

Candidate provenance must be recorded, for example:

```text
USER_SOP_OPTIMIZATION
STANDARD_RESEARCH
CODEX
CLAUDE
SINGLE_AI
CODEX_CLAUDE
EXTERNAL_RESEARCH
GITHUB_RESEARCH
```

Origin does not change the promotion standard.

A Research ID is only a research record; it does not mean the source code was implemented, compiled, or backtested successfully.

---

# 4. GSM SOP and Research Must Remain Separate

GSM SOP belongs to:

```text
AUTHORITATIVE STRATEGY FOUNDATION
```

Research belongs to:

```text
EXPERIMENTAL / EXTERNAL RESEARCH SOURCE
```

Research may:

- improve the program implementation of GSM SOP
- find SOP implementation mistakes
- identify wrong entries
- identify missed entries / no-trade causes
- create Candidates
- propose new Entry / Exit hypotheses
- propose indicator, risk, execution, or Portfolio modules

But never:

```text
Research Idea
→ directly modify the formal Champion
```

Required path:

```text
Research Idea
↓
Candidate
↓
Candidate VS Champion
↓
Fair Validation
↓
Clear Win
↓
Promotion Only Then
```

If a Candidate changes GSM Base SOP, it must explicitly record:

```text
GSM_BASE_SOP_CHANGED = YES / NO
```

---

# 5. Three Strategy Engines

## 5.1 SCALPING M5

Core flow:

```text
M5
↓
Find current nearest valid S&D by CURRENT PRICE DISTANCE
↓
Fresh Zone
↓
Departure
↓
First Touch / Retest
↓
Reversal Confirmation
↓
Entry
↓
SL / TP
↓
Exit
```

Key rule:

```text
Nearest Zone = valid zone nearest to current price
NOT the most recently formed zone
```

BUY:

```text
Valid Demand
+
First Touch / Retest
+
Bullish Reversal
```

SELL:

```text
Valid Supply
+
First Touch / Retest
+
Bearish Reversal
```

Research areas may include:

- Candle Quality
- Spread Cost Gate
- Entry Quality
- Real Tick Robustness
- Regime Filter
- ATR
- Market Structure
- Liquidity
- Execution Timing
- Cost-aware Exit

No artificial daily trade cap. Never manufacture low-quality trades merely to increase Trades.

---

## 5.2 INTRADAY M30

Base / Benchmark:

```text
M30 Market Direction
↓
Nearest Valid M30 Supply / Demand
↓
Define Zone
↓
Wait Price Enter Zone
↓
Entry
↓
SL
↓
TP
↓
Management
```

Principle: actively look for valid opportunities; zero trades on a day is acceptable; never force one trade per day.

The following must remain Candidate-only until proven:

- M15 Confirmation
- M5 Confirmation
- Any 2 of 3
- 3 of 3
- EMA
- BOS
- CHoCH
- FVG
- Order Block
- Liquidity
- Candlestick Confirmation
- ATR Stop
- Structure Stop
- Session Filter
- VWAP
- Volume
- AI Score

All must be A/B tested fairly against the Current Intraday Champion.

---

## 5.3 SWING

The formal Swing Base is defined by the currently validated Champion Code / Authoritative SOP. Research must not invent a new Swing Base without source authority.

Research areas may include:

- D1 Framework
- H4 Trend
- Support / Resistance
- Supply / Demand
- Pullback
- Candlestick
- Market Structure
- SMC
- Trailing / Protection
- ATR
- Fibonacci

The other two Strategy Champions not under study must remain locked; their source code and parameters must not be casually modified.

---

# 6. Fair Candidate VS Champion Test Protocol

Each Candidate should change one major variable and enable only the corresponding Engine.

Champion and Candidate should use the same:

- Broker / Data Source
- Symbol
- Capital
- Leverage
- Real Tick Period
- Tester Model
- Spread / Commission
- Slippage Assumption
- Risk Budget
- Position Sizing Rules
- Session Conditions
- Base Execution Settings

Each Broker report must output:

| Version | Net USD | Max Equity DD | PF | Trades | Win Rate | Reject |
|---|---:|---:|---:|---:|---:|---:|

Also output:

- Delta Net
- Delta DD
- Delta PF
- Delta Trades
- Delta Win Rate

Training is for parameter selection. OOS is for validation only.

After reading an OOS result, parameters must not be retuned and the same period still called OOS.

## 6.1 Risk-Normalized Comparison

Forbidden:

```text
Candidate uses higher Risk / Lot
Champion uses lower Risk / Lot
then only Net Profit is compared
```

If risk differs, first perform:

```text
RISK-NORMALIZED COMPARISON
```

Report:

- Requested Risk
- Actual Risk
- Lot
- SL Distance
- Margin Usage

---

# 7. Champion Evaluation System

Official priority is permanently fixed:

```text
1. Net Profit USD
2. Max Equity Drawdown
3. Profit Factor
4. Trade Count
5. Win Rate
```

Supporting metrics must include:

- Return % on Initial Capital
- Max Equity Drawdown USD
- Max Equity Drawdown %
- Balance Drawdown as secondary context only
- Relative Drawdown
- Average Win
- Average Loss
- Realized Average R:R
- Expected Payoff / Expectancy
- Break-even Win Rate
- Recovery Factor
- Long Win Rate / Short Win Rate
- BUY Performance / SELL Performance
- Maximum Consecutive Losses
- Spread / Commission / Slippage Sensitivity
- OOS Performance
- Walk Forward Stability
- Parameter Robustness
- Market Regime Performance

Win Rate must never be judged in isolation.

## 7.1 Net Profit must be normalized by capital

Absolute Net Profit alone is insufficient.

Every report must calculate:

```text
Return % = Net Profit USD / Initial Capital × 100
```

A strategy that earns a small absolute amount on a large account can be statistically valid but commercially unattractive. Therefore both `Net Profit USD` and `Return %` must be reported.

This does not change the official Champion ranking order. `Net Profit USD` remains #1, while `Return %` is a mandatory interpretation metric.

## 7.2 Profit Factor interpretation

Profit Factor must be interpreted together with sample size, drawdown, OOS, costs, and parameter stability.

Useful diagnostic reference bands:

```text
PF < 1.00      = losing system on the tested sample
PF 1.00-1.20   = weak / marginal edge
PF 1.20-1.50   = usable but needs robustness confirmation
PF 1.50-2.00   = strong if supported by sufficient sample and OOS
PF > 2.00      = very strong, but inspect sample size and overfitting risk carefully
PF > 2.50-3.00 = not automatically invalid; requires heightened scrutiny
```

A high PF is **not** proof of overfitting by itself. It becomes suspicious when combined with one or more of:

- very low trade count
- one short favorable market regime
- sharp OOS collapse
- parameter cliff behavior
- unrealistic spread / commission / slippage assumptions
- future-data or look-ahead defects
- one-sided BUY/SELL dependence

Flag when appropriate:

```text
PF_OVERFIT_SUSPECT
```

## 7.3 Max Equity Drawdown is the primary drawdown metric

Always prioritize `Equity Drawdown`, not Balance Drawdown, because open-position floating losses are economically real.

Required output:

```text
Max Equity DD USD
Max Equity DD %
Max Balance DD USD / % (secondary only)
```

Diagnostic reference bands:

```text
<= 15%     = preferred / controlled
15%-30%    = caution zone
> 30%      = high-risk zone
> 50%      = severe capital-risk zone
```

These bands are risk diagnostics, not universal hard pass/fail thresholds unless explicitly configured for the Champion mandate. Max Equity DD retains veto authority.

Large divergence between Balance and Equity must trigger:

```text
BALANCE_EQUITY_DIVERGENCE
HIDDEN_FLOATING_LOSS_RISK
```

## 7.4 Trade-count adequacy is strategy-dependent

Do not force one universal `>100 trades` rule across all strategies.

Preferred evidence guidance:

```text
Scalping: preferably > 200; 300-1000+ is better when feasible
Intraday: preferably > 100
Swing: do not mechanically force > 100; extend years and market regimes instead
```

Small samples must be flagged:

```text
LOW_SAMPLE_SIZE
LOW_SAMPLE_WINRATE
```

The lower the sample size, the stronger the requirement for longer date ranges, regime diversity, OOS, Walk Forward, and cross-broker confirmation.

## 7.5 Recovery Factor

```text
Recovery Factor = Net Profit / Maximum Drawdown Amount
```

Diagnostic interpretation:

```text
< 1.0  = weak
1.0-2.0 = marginal
2.0-3.0 = good
> 3.0  = strong
```

`Recovery Factor > 3` is desirable but is **not** a universal standalone hard gate. It must be interpreted with DD, sample size, OOS and strategy type.

## 7.6 Expected Payoff and cost coverage

Expected Payoff must be positive and must survive realistic costs.

For short-horizon strategies, especially Scalping, report:

```text
Expected Payoff / Trade
Average Spread Cost / Trade
Average Commission / Trade
Estimated Slippage Cost / Trade
Total Estimated Cost / Trade
Edge-to-Cost Ratio
```

Where practical:

```text
Edge-to-Cost Ratio = Expected Payoff / Estimated Total Cost per Trade
```

A large safety buffer is preferred. A 3x-5x cost buffer can be used as a strong reference target for cost-sensitive strategies, but it is not a universal hard threshold because units and execution models differ by broker and symbol.

Flag:

```text
EXPECTED_PAYOFF_TOO_SMALL
SPREAD_COST_EDGE_TOO_SMALL
```

## 7.7 Balance-vs-Equity integrity check

If the Balance curve looks smooth while Equity repeatedly drops far below it, investigate:

- holding large floating losses
- grid behavior
- martingale behavior
- delayed loss realization
- recovery-only exit logic
- margin-call proximity

A strategy with attractive Balance statistics but severe Equity stress must not pass Champion review without explicit tail-risk evidence.

```text
TEST PASS
≠
BEAT CHAMPION
```

A profitable Candidate does not automatically replace the Champion.

If the result is only close:

```text
KEEP CURRENT CHAMPION
```

Only when evidence clearly shows:

```text
Candidate > Current Champion
```

may the result be:

```text
PROMOTE TO NEW CHAMPION
```

---

# 8. Win Rate / Expectancy / Realized R:R Validation Standard

MT5 Win Rate is normally reported as:

```text
Profit Trades (% of total)
```

Win Rate is a diagnostic metric, not a standalone proof of strategy quality. A high Win Rate can coexist with poor expectancy, weak R:R, hidden tail risk, or one-sided market dependence.

## 8.1 Mandatory MT5 companion fields

Every Champion and Candidate report must read Win Rate together with at least:

```text
Profit Trades (% of total)
Average profit trade
Average loss trade
Long Positions (won %)
Short Positions (won %)
Maximum consecutive losses
```

When available, also retain Maximum consecutive wins, gross profit/loss, and direction-specific trade counts.

## 8.2 Core formulas

```text
Expectancy =
(Win Rate × Average Win)
-
(Loss Rate × abs(Average Loss))
```

```text
Realized Average R:R =
Average Profit Trade
/
abs(Average Loss Trade)
```

Define:

```text
R = Average Win / abs(Average Loss)
```

Theoretical break-even Win Rate:

```text
Break-even Win Rate = 1 / (1 + R)
```

Examples:

```text
1:1 → 50.0%
2:1 → 33.3%
3:1 → 25.0%
```

Theoretical R:R and realized average R:R must be reported separately when they differ. Champion evaluation must care more about realized results than nominal SL/TP design.

## 8.3 Strategy-type interpretation

Reference ranges are diagnostic, not hard universal promotion thresholds:

| Strategy profile | Typical Win Rate behavior | Typical payoff structure | Main risk |
|---|---:|---:|---|
| Trend / Breakout | often lower, e.g. 35%-45% | often 2:1, 3:1 or higher | long losing streaks, regime dependence |
| Scalping / Range | often higher, e.g. 65%-80% | often around 1:1 or lower | spread, commission, slippage, latency |
| Grid / Martingale | may show 85%-95%+ | many small wins, rare large losses | catastrophic tail loss / margin failure |

A very high Win Rate is not automatically good. A 90%+ system with severe negative skew can be materially worse than a 40%-50% system with strong realized R:R and positive expectancy.

## 8.4 BUY / SELL direction audit

Every engine report should separately show:

```text
BUY Trades
BUY Win Rate
BUY Net Profit
BUY Profit Factor
SELL Trades
SELL Win Rate
SELL Net Profit
SELL Profit Factor
```

A large directional imbalance must trigger investigation rather than automatic rejection. Determine whether the cause is:

- market regime
- insufficient sample
- asymmetric strategy logic
- coding defect
- one-direction structural dependency

Flag where justified:

```text
ONE_SIDE_DEPENDENCY
```

## 8.5 Consecutive-loss stress

Maximum Consecutive Losses must be read together with Max Equity DD and Risk per Trade.

Required stress sequence:

```text
Historical Max Consecutive Losses = N
Stress Case 1 = N + 2
Stress Case 2 = N + 4
```

Inspect:

- projected DD
- free margin
- margin level
- position-sizing survival
- recovery requirement
- account ruin risk

Flag:

```text
LOSS_STREAK_RISK
```

## 8.6 Mandatory Win Rate diagnostic flags

Use when supported by evidence:

```text
HIGH_WINRATE_BAD_RR
NEGATIVE_EXPECTANCY
ONE_SIDE_DEPENDENCY
LOSS_STREAK_RISK
SPREAD_COST_EDGE_TOO_SMALL
LOW_SAMPLE_WINRATE
HIDDEN_TAIL_RISK
```

## 8.7 Strategy-specific emphasis

```text
SCALPING
→ Win Rate + Realized R:R + Expected Payoff + Spread + Commission + Slippage + Delay

INTRADAY
→ medium Win Rate is acceptable when Net + DD + PF + Expectancy are strong

SWING
→ lower Win Rate is acceptable when Average Win materially exceeds Average Loss and DD is controlled
```

## 8.8 Required detailed Champion report columns

```text
Strategy
Net Profit USD
Return %
Max Equity DD USD
Max Equity DD %
Profit Factor
Recovery Factor
Trades
Win Rate
Average Win
Average Loss
Realized Average R:R
Break-even Win Rate
Expected Payoff / Expectancy per Trade
Maximum Consecutive Losses
Long Win Rate
Short Win Rate
BUY Net / PF
SELL Net / PF
Reject
Diagnostic Flags
```

The official top-level ranking remains unchanged:

```text
Net Profit USD
→ Max Equity Drawdown
→ Profit Factor
→ Trade Count
→ Win Rate
```

The additional fields explain whether that ranking result is robust and economically credible.

## 8.9 MT5 Strategy Tester robustness protocol

Formal Champion validation must use:

```text
Every tick based on real ticks
```

for all formal Real Tick evidence unless a specific test is explicitly labeled as a lower-fidelity diagnostic run.

Execution robustness must test realistic transaction friction. Depending on tester/broker capabilities, include multiple delay/slippage conditions rather than only `No Delay`.

Reference execution-delay scenarios may include approximately:

```text
10 ms
25 ms
50 ms
```

or broker-realistic random delay ranges. These are stress scenarios, not fixed universal constants.

For each scenario report the change in:

- Net Profit
- Max Equity DD
- PF
- Trades
- Win Rate
- Expected Payoff
- Reject / execution errors

Flag:

```text
DELAY_SLIPPAGE_FRAGILE
```

## 8.10 Train / OOS protocol

Training data is for model and parameter selection.

OOS data is for validation only.

Example structure:

```text
Train: earlier period
OOS: later untouched period
```

After OOS results are read, any retuning creates a new experiment and the previously viewed period cannot continue to be called untouched OOS for that same Candidate.

Flag:

```text
OOS_COLLAPSE
OOS_CONTAMINATION
```

A promising Candidate should also be evaluated across market regimes and, when required, Walk Forward, cost stress, execution stress, parameter-neighborhood stability, and Monte Carlo / trade-order randomization.

---

# 9. Combined Candidate and Portfolio Rules

Any New Engine Champion must trigger a new Combined Candidate.

The Combined Candidate must be recompiled and rerun on dual-broker Real Tick. Never add standalone engine Net Profits together and call that the Combined result.

Portfolio Audit must include at least:

- Concurrent Positions
- Margin Usage
- Aggregate Risk
- Same-direction Exposure
- Opposite-signal Conflict
- Hedging / Netting
- Capital Allocation
- Position Sizing
- Drawdown Overlap
- Strategy Correlation
- Portfolio Interaction

If the Combined result gets worse:

- keep the New Engine Champion
- keep the Current Combined Champion locked
- create a new `C-Cxx` Portfolio-Risk Candidate only
- do not rewrite locked Engine logic

---

# 10. External EA / GitHub / AI Research Boundary

External EAs, GitHub projects, screenshot parameters, third-party model interpretations, and AI-generated ideas all belong to the Research Layer.

External-source path:

```text
Source / Screenshot / Repository / AI Hypothesis
        ↓
Evidence Classification
        ↓
Read License / Source if available
        ↓
Separate FACT from HYPOTHESIS
        ↓
Clean-room Specification
        ↓
Single-module Candidate
        ↓
Compile
        ↓
Real Tick
        ↓
Train / OOS
        ↓
FxPro + Tradona
        ↓
Walk Forward / Stress Test if promising
        ↓
Candidate VS Current Champion
```

If source code is unavailable, parameter names must not be guessed into internal state-machine behavior.

Research references include:

- `docs/EXTERNAL_EA_TEST_2_41_RESEARCH_CN.md`
- `docs/GSM_GOLD_AI_RESEARCH_LAB_CN.md`
- `docs/GSM_GOLD_SINGLE_AI_RESEARCH_LAB_CN.md`

---

# 11. Research Modules Extracted from External EA 2.41

All of the following are Research Candidates only. They are not GSM SOP and are not default Champion modules.

## 11.1 Fast Adverse Move Guard

Goal: react when a new position is rapidly proven wrong, rather than mechanically waiting for the fixed SL.

Do not directly copy fixed `120 sec / 50 points / 20 points` settings.

Candidate example:

```text
MAE = maximum adverse excursion after entry

IF
MAE > K × ATR
AND elapsed_time <= FastWindow
AND adverse_momentum_is_strengthening
THEN
    Freeze same-direction new entries
    Set state = FAST_ADVERSE_MOVE
```

Scalping, Intraday, and Swing parameters must be tested separately.

## 11.2 Recovery / Resume State Machine

```text
NORMAL
  ↓
FAST_ADVERSE_MOVE
  ↓
FREEZE
  ↓
RECOVERY_CONFIRM
  ↓
NORMAL
```

Requirements:

- keep states minimal
- log every state transition
- record trigger reason / timestamp / price / strategy / direction
- state must be reconstructable after MT5 / VPS restart

## 11.3 Direction Basket Risk

Track:

```text
BUY_Basket_Floating_PnL
SELL_Basket_Floating_PnL
BUY_Total_Open_Risk
SELL_Total_Open_Risk
BUY_Total_Lots
SELL_Total_Lots
```

If one direction reaches its risk limit, it may be frozen independently; the other direction must still pass Portfolio Conflict Check.

## 11.4 Daily Account Circuit Breaker

Candidate controls may include:

- DailyProfitLimitUSD
- DailyLossLimitUSD
- DailyLossPercent
- DailyEquityDrawdownPercent

Must explicitly define:

- Balance / Equity basis
- Reset time
- Broker Server Time
- whether only New Entry is blocked
- whether Existing Positions remain managed
- resume conditions

## 11.5 Optional Evidence Voting

Do not combine every indicator into one giant AND condition.

```text
Core GSM SOP = Trade Eligibility

Optional Evidence = Quality Evidence
  ├─ EMA
  ├─ ADX
  ├─ DI
  ├─ ATR Regime
  ├─ CCI
  ├─ FVG
  ├─ Candle
  ├─ S&D Quality
  └─ Market Structure

Evidence Score / Votes
        ↓
Pass / Reject / Risk Multiplier / Position Size Tier
```

Principle:

```text
SOP determines trade eligibility
Optional Evidence only measures evidence strength
```

## 11.6 ADX + DI Roles

- ADX = Trend Strength
- +DI / -DI = Directional Evidence

## 11.7 ATR-Normalized FVG Quality

```text
ValidFVG = FVG_Size >= ATR × MinFvgAtrRatio
```

FVG always remains in the Optimization Layer. It must not replace the GSM Supply/Demand Base Zone without Real Tick A/B proof.

---

# 12. Point / Pip / Price / Money Conversion Rule

Never hardcode:

```text
100 points always = fixed X USD
```

Read actual Broker specifications:

```text
SYMBOL_POINT
SYMBOL_DIGITS
SYMBOL_TRADE_TICK_SIZE
SYMBOL_TRADE_TICK_VALUE
SYMBOL_TRADE_CONTRACT_SIZE
SYMBOL_VOLUME_MIN
SYMBOL_VOLUME_MAX
SYMBOL_VOLUME_STEP
SYMBOL_TRADE_STOPS_LEVEL
SYMBOL_TRADE_FREEZE_LEVEL
```

The program must record:

- Raw Points
- Price Distance
- Lot
- Requested Risk USD / %
- Actual Risk USD / %

---

# 13. EA Main Program Flow and Research Hooks

## 13.1 OnInit

```text
Read Broker / Symbol / Account Mode
↓
Read Contract Specs
↓
Load Champion Inputs
↓
Initialize 3 Strategy Engines
↓
Initialize Optional Evidence Modules
↓
Initialize Risk Engine
↓
Initialize Direction Basket Risk
↓
Initialize Daily Circuit Breaker
↓
Restore Recovery / Freeze State
↓
Initialize Portfolio Manager
↓
Initialize Execution + Audit
```

## 13.2 OnTick

```text
UPDATE MARKET DATA
↓
UPDATE ACCOUNT / EQUITY / MARGIN
↓
UPDATE BUY / SELL BASKET RISK
↓
CHECK DAILY ACCOUNT CIRCUIT BREAKER
↓
MANAGE EXISTING POSITIONS
↓
CHECK FAST ADVERSE MOVE GUARD
↓
UPDATE RECOVERY / FREEZE STATE
↓
RUN SCALPING ENGINE
↓
RUN INTRADAY ENGINE
↓
RUN SWING ENGINE
↓
COLLECT CORE GSM SIGNALS
↓
OPTIONAL EVIDENCE SCORE / VOTES
↓
RESOLVE SIGNAL CONFLICT
↓
PORTFOLIO RISK CHECK
↓
BROKER / SPREAD / COST / MARGIN CHECK
↓
EXECUTION
↓
LOG ORDER + STATE + BLOCK REASON
↓
UPDATE DASHBOARD / AUDIT
```

Every Research Hook must be independently switchable off so that the pure Current Champion Baseline can always be rerun.

---

# 14. Trade Audit and Missed Opportunity Audit

Every new module must leave a `Blocked Reason / Trigger Reason`.

At minimum consider:

```text
FAST_ADVERSE_FREEZE
RECOVERY_NOT_CONFIRMED
BUY_BASKET_RISK
SELL_BASKET_RISK
DAILY_LOSS_CIRCUIT
DAILY_EQUITY_DD_CIRCUIT
EVIDENCE_SCORE_LOW
ADX_DI_REJECT
FVG_QUALITY_LOW
PF_OVERFIT_SUSPECT
BALANCE_EQUITY_DIVERGENCE
HIDDEN_FLOATING_LOSS_RISK
LOW_SAMPLE_SIZE
LOW_RECOVERY_FACTOR
EXPECTED_PAYOFF_TOO_SMALL
DELAY_SLIPPAGE_FRAGILE
OOS_COLLAPSE
OOS_CONTAMINATION
```

Must distinguish:

```text
NO VALID SETUP
VALID SETUP BLOCKED BY RESEARCH MODULE
PROGRAM MISSED VALID SETUP
```

Otherwise it is impossible to tell whether a Candidate improved trade quality or merely reduced trade count.

---

# 15. AI Research Is Optional, Not Mandatory

AI Research is not part of GSM Base SOP and is not a mandatory Champion certification step.

Official mode selector:

```text
AI_RESEARCH_MODE = OFF
AI_RESEARCH_MODE = SINGLE_AI
AI_RESEARCH_MODE = DUAL_AI
```

Regardless of mode, the following must not change:

- GSM SOP authority
- Candidate VS Champion system
- Fair Test Protocol
- Real Tick
- Train / OOS
- FxPro / Tradona
- Risk Rules
- Portfolio Audit
- Champion Evaluation Order

AI only determines:

```text
who performs research/review and how that review is organized
```

AI does not decide the final Champion.

---

# 16. AI_RESEARCH_MODE = OFF

Do not use the Single-AI or Dual-AI Research Lab.

Flow:

```text
GSM SOP
↓
Current Champion
↓
Trade Audit / Missed Audit
↓
Research Hypothesis
↓
Candidate
↓
Compile
↓
Standard Code Audit
↓
MT5 Real Tick
↓
Train / OOS
↓
FxPro / Tradona
↓
Candidate VS Champion
```

This mode does not require:

- Single-AI Self Review
- Single-AI Red Team
- Dual-AI Cross Review

But code correctness, fair testing, risk audit, and Champion promotion standards still apply.

---

# 17. AI_RESEARCH_MODE = SINGLE_AI

May use:

```text
Codex
or
Claude Code
```

The architecture is model-agnostic. Unified role:

```text
SINGLE AI RESEARCH ENGINEER
```

It may perform:

- Strategy Researcher
- MQL5 Developer
- Code Reviewer
- Debugger
- Backtest Analyst
- Risk Reviewer
- Optimization Researcher

Main Single-AI risk:

```text
same model develops
+
same model reviews
+
same model declares itself correct
```

Therefore, when `SINGLE_AI` is enabled, the process must be phase-separated:

```text
PHASE 1 — RESEARCHER
↓
PHASE 2 — DEVELOPER
↓
PHASE 3 — SELF CODE REVIEWER
↓
PHASE 4 — RED TEAM REVIEWER
↓
PHASE 5 — MT5 DATA ANALYST
↓
PHASE 6 — CHAMPION JUDGE
```

Each phase must reread facts, code, and test evidence rather than inheriting the prior phase's subjective conclusion.

## 17.1 Single-AI Research Phase

First research only; do not modify Production.

Required output:

```text
Research ID
AI Model
Engine
Current Champion
Observed Problem
Evidence
Hypothesis
Expected Benefit
Expected Risk
Files Likely Affected
SOP Impact
Experiment Plan
```

## 17.2 Single-AI Development Phase

```text
Champion Snapshot
↓
Create Candidate Branch / Candidate File
↓
Modify only experiment-required content
↓
Preserve all other test conditions
```

Requirements:

- minimum necessary modification
- traceable reason for every change
- no hidden Risk / Lot increase
- no unrelated rewrites
- never overwrite Current Champion

## 17.3 Single-AI Self Code Review

At minimum check:

1. duplicate entries
2. missed entries
3. unclosed-bar usage
4. Look-ahead
5. CopyBuffer / CopyRates
6. Timeframe
7. Position / Order / Deal handling
8. Magic Number
9. Hedging / Netting
10. SL / TP normalization
11. Stops Level / Freeze Level
12. Spread / Slippage
13. Risk / Lot calculation
14. Volume min / max / step
15. accidental modification of other Engines
16. GSM Base SOP changes
17. hidden risk
18. obvious Overfitting path
19. Broker Reject / Retcode logging
20. Recovery / Freeze State reconstruction

Review result may only be:

```text
PASS
or
FAIL + FIX LIST
```

No Critical Finding may remain open before the next phase.

## 17.4 Single-AI Red Team

The Red Team must assume:

```text
Candidate may be wrong
```

Actively test whether:

- profit comes from higher Risk
- DD worsens
- it only works in one year
- trade quality is sacrificed to increase Trades
- only BUY or SELL is optimized
- Spread sensitivity is excessive
- Slippage sensitivity is excessive
- small parameter changes cause collapse
- live executability is reduced
- the result is Backtest Noise
- profit source is unexplained
- future data is used

The Red Team's purpose is not to prove the Candidate is good. Its job is to try to disprove it.

---

# 18. AI_RESEARCH_MODE = DUAL_AI

Codex and Claude Code are both treated as complete:

```text
MQL5 Research Engineer
+
MQL5 Developer
+
Code Reviewer
+
Backtest Analyst
+
Strategy Researcher
```

Do not lock roles into:

```text
Codex develops only
Claude reviews only
```

Default protocol: independent research first, conclusions exchanged later, to reduce anchoring.

```text
CURRENT CHAMPION
        │
        ├───────────────┐
        │               │
        ▼               ▼
     CODEX            CLAUDE
 Independent        Independent
 Hypothesis A       Hypothesis B
        │               │
        ▼               ▼
 Candidate A        Candidate B
        │               │
        └──────┬────────┘
               ▼
          CROSS REVIEW
               │
               ├─ Keep A
               ├─ Keep B
               ├─ Reject both
               └─ Build Hybrid Candidate C
                       ↓
                 MetaEditor Compile
                       ↓
                 MT5 Real Tick
                       ↓
              Candidate VS Champion
```

A Hybrid Candidate must document the origin of every change. Do not blindly stack all A+B ideas and destroy attribution.

---

# 19. Unified Code Review and Quantitative Audit Checklist

Regardless of Research source, minimum review checklist:

1. duplicate entry logic
2. missed-entry logic
3. incorrect use of unclosed candles
4. Look-ahead
5. CopyBuffer / CopyRates correctness
6. Timeframe correctness
7. Position / Order / Deal confusion
8. Magic Number isolation
9. Hedging / Netting compatibility
10. SL / TP normalization
11. Broker Stops Level / Freeze Level compliance
12. Spread / Slippage handling
13. Risk / Lot calculation
14. Volume min / max / step
15. accidental modification of other Engines
16. GSM Base SOP change disclosure
17. Overfitting
18. hidden risk increase for profit
19. changed test conditions used to beautify results
20. unexplained profit source
21. Broker Reject / Retcode logging
22. Freeze / Recovery state reconstruction
23. Real Tick model correctness
24. Equity-vs-Balance divergence
25. sample-size adequacy for the strategy type
26. OOS contamination
27. delay / slippage sensitivity
28. Expected Payoff after costs

No Candidate may be promoted while a Critical Finding remains open.

---

# 20. Candidate Promotion Gate

To truly beat a Champion, at minimum require:

```text
1. Code correctness
2. No future data / look-ahead
3. No hidden risk increase
4. Valid Real Tick evidence
5. OOS does not collapse
6. Walk Forward acceptable when required
7. Stress test acceptable
8. Critical risk metrics not unacceptably worse
9. Overall evidence clearly better than Current Champion
```

A profitable Candidate only proves research value, not New Champion status.

---

# 21. Automatic Reject Rules

Any one of the following triggers rejection:

- Future Data
- Look-ahead
- hidden Lot increase
- hidden Risk % increase
- removal of core SL
- hidden Martingale / Grid Tail Risk increase
- undisclosed maximum-position increase
- cherry-picked backtest period
- deleted losing periods
- reduced Commission / Spread to beautify results
- unfair comparison conditions
- huge Equity DD exchanged for Net Profit
- severe single-period Overfitting
- hidden Broker Reject / Execution Failure
- retuning after OOS and still calling the same period OOS
- unexplained abnormal profit
- missing critical validation data
- formal Champion evidence not based on Real Ticks without explicit lower-fidelity labeling

Result:

```text
AUTOMATIC REJECT
```

---

# 22. Experiment Registry

Every experiment must record:

```text
Experiment ID
AI Research Mode (OFF / SINGLE_AI / DUAL_AI)
Research Source
AI Model(s) if used
Engine
Candidate Version
Candidate Origin
Current Champion Version
Strategy Source
Research Hypothesis
Observed Evidence
Modified Files
Modified Rules
GSM Base SOP Changed (YES/NO)
Initial Capital
Return %
Risk Budget
Actual Risk
Test Protocol
Broker / Symbol / Date Range
Tester Model
Real Tick Used (YES/NO)
Delay / Slippage Scenario
Champion Metrics
Candidate Metrics
Delta Metrics
Max Equity DD USD / %
Max Balance DD USD / %
Recovery Factor
Expected Payoff
Edge-to-Cost Ratio
Sample Size
Standard Review Result
Self Review Result
Red Team Result
Codex Review
Claude Review
OOS Result
Walk Forward Result
Stress Test Result
Audit Result
Blocked / Trigger Reasons
Final Verdict
Promotion Decision
Reason
```

Fields that do not apply must be recorded as:

```text
N/A
```

Never fabricate Review or Test results.

Final Verdict may only be:

```text
REJECT
KEEP CURRENT CHAMPION
RESEARCH FURTHER
NEW ENGINE CHAMPION
NEW 3-SOP COMBINED CHAMPION
```

---

# 23. Champion Lock and History

Every Strategy Champion and Combined Champion must retain:

- Version
- Source Hash
- SET Hash
- Test Protocol
- Metrics
- Final Report

A Champion can only be unlocked when a Candidate under equivalent conditions clearly beats it.

Lineage:

```text
Previous Champion
↓
Candidate
↓
New Champion
```

Old Champions are never deleted.

---

# 24. Git / Version Isolation

```text
main / production
└── current formal Champion reference

champion/
├── current/
└── history/

research/
├── scalping/<origin>/<topic>
├── intraday/<origin>/<topic>
├── swing/<origin>/<topic>
└── combined/<origin>/<topic>

research summaries / rejected results
└── Markdown / CSV only
```

Failed Candidates do not keep large ZIP packages; keep Markdown / CSV summaries only.

New Champion promotion:

```text
Old Current Champion
→ champion/history/

Winning Candidate
→ champion/current/
```

Full lineage must be preserved.

---

# 25. Champion ZIP Delivery Standard

Generate a Champion ZIP only when a real New Combined Champion exists.

Minimum contents:

```text
CODE/
SETS/
CONFIG/
REPORTS/SCALPING/
REPORTS/INTRADAY/
REPORTS/SWING/
REPORTS/COMBINED/
REPORTS/OOS/
REPORTS/STRESS/
RESEARCH/CHAMPION_COMPARISON/
BEST_SCALPING/
BEST_INTRADAY/
BEST_SWING/
FINAL_REPORT_CN.html
CHAMPION_MANIFEST.txt
SHA256.txt
```

The FINAL_REPORT front page must show in order:

```text
Best Scalping
Best Intraday
Best Swing
Best Combined
```

Field order is fixed:

```text
Net -> Max Equity DD -> PF -> Trades -> Win Rate -> Reject
```

Detailed pages must additionally show Return %, Equity DD USD/%, Recovery Factor, Expected Payoff, Realized R:R, Buy/Sell split, consecutive-loss statistics, cost sensitivity, and diagnostic flags.

The ZIP delivered to the user and GitHub `champion/current/` must be the exact same file, with matching filename, version, SHA256, and report metrics.

---

# 26. Final Universal Champion Iteration Loop

Research input may come from:

```text
USER
STANDARD RESEARCH
GITHUB
EXTERNAL EA
SINGLE AI
DUAL AI
```

Unified flow:

```text
CURRENT CHAMPION
↓
READ FINAL REPORT
↓
READ TRADE AUDIT
↓
READ MISSED OPPORTUNITY AUDIT
↓
IDENTIFY BIGGEST WEAKNESS
↓
SELECT RESEARCH SOURCE
↓
SELECT AI_RESEARCH_MODE = OFF / SINGLE_AI / DUAL_AI
↓
FORM TESTABLE HYPOTHESIS
↓
BUILD ONE CANDIDATE
↓
COMPILE
↓
REVIEW GATE
  ├─ OFF: STANDARD CODE AUDIT
  ├─ SINGLE_AI: SELF REVIEW + RED TEAM
  └─ DUAL_AI: CROSS REVIEW
↓
MT5 REAL TICK
↓
TRAIN / OOS
↓
FXPRO / TRADONA
↓
WALK FORWARD / STRESS TEST when required
↓
RISK + PORTFOLIO AUDIT
↓
COMPARE WITH CURRENT ENGINE CHAMPION
```

Failure path:

```text
REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER
↓
SAVE RESEARCH SUMMARY
↓
DO NOT TOUCH CHAMPION
```

Success path:

```text
NEW ENGINE CHAMPION
↓
LOCK IT
↓
REBUILD 3-SOP COMBINED CANDIDATE
↓
FULL COMBINED REAL TICK + OOS
↓
PORTFOLIO AUDIT
↓
COMPARE WITH CURRENT COMBINED CHAMPION
↓
IF BETTER → NEW 3-SOP COMBINED CHAMPION
↓
FINAL REPORT CN
↓
CHAMPION ZIP
↓
SHA256
↓
GITHUB ARCHIVE
```

---

# 27. Final Decision Authority

Codex, Claude Code, Single AI, Dual AI, GitHub Research, and external EAs do not have final decision authority.

Final authority comes from:

```text
Code Correctness
+
Fair Candidate VS Champion
+
MT5 Real Tick
+
OOS
+
Walk Forward when required
+
Stress Test
+
Risk Audit
+
Portfolio Audit
+
Champion Evaluation Order
```

Final evaluation order remains permanently fixed:

```text
#1 Net Profit USD
#2 Max Equity Drawdown
#3 Profit Factor
#4 Trade Count
#5 Win Rate
```

Any Automatic Reject condition, Look-ahead, hidden risk increase, unacceptable DD, OOS collapse, or execution abnormality may veto promotion.

---

# 28. Final Principle

GSM SOP is responsible for: **how to trade**.

Research is responsible for: **what is worth testing next**.

AI Research is an **optional research tool, not a mandatory Champion process**.

When `AI_RESEARCH_MODE = OFF`:

```text
Do not use the AI Research Lab
Research, development, backtesting, validation, and Champion promotion can still proceed normally
```

When `AI_RESEARCH_MODE = SINGLE_AI`:

```text
Use phase separation + Self Review + Red Team
Reduce single-model confirmation bias
```

When `AI_RESEARCH_MODE = DUAL_AI`:

```text
Use independent research + Cross Review + optional Hybrid Candidate
```

MetaEditor is responsible for: **proving that the source code compiles correctly**.

MT5 Real Tick + OOS + Dual Broker + Walk Forward / Stress Test are responsible for: **providing statistical validation and robustness evidence for the Candidate**.

Champion System is responsible for: **deciding which version remains**.

Core rule:

```text
Research may continue indefinitely.
Champion must not change casually.

Not:
A new version looks good, so replace it.

Instead:
Only replace the Champion when a Candidate clearly beats it under fair conditions.
```

All Research Sources, all AI Modes, all new modules, and all Candidates follow the same rule:

```text
Research First
↓
Testable Hypothesis
↓
Candidate
↓
Required Review
↓
Evidence
↓
Candidate VS Champion
↓
Champion Only If Proven
```