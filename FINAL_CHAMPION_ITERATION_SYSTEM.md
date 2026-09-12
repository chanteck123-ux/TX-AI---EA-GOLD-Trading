# FINAL_CHAMPION_ITERATION_SYSTEM — Current EA Research and Development Plan

[中文版 / Chinese](FINAL_CHAMPION_ITERATION_SYSTEM_CN.md)

Saved update: 2026-09-12 (Asia/Kuala_Lumpur). Building on the user's selected risk-updated plan and SOP-ownership clarification, this edition adds the §13 research system for dynamic risk, trend/range identification, gold/USD related markets, and news and the economic calendar.

- Chinese source: `EA_旧版升级研究计划&codex重新研究开发计划&研究开发计划指南_CN_RISK_UPDATED.md`; SHA256: `88265662399010a383aa334dc2752fa1cba12bba912eff63f571fd8075251c66`.
- The original 12 sections are based on the supplied source, with strategy ownership distinguished under §2.2 as requested by the user. Section 13 is added, and dynamic-risk interfaces and task entry points in the original sections are synchronized. Base risk tiers, acceptance numbers, and historical results are preserved. Runtime risk may be reduced, paused, and gradually restored within fixed caps under a preregistered policy. The original upload and preceding Chinese and English versions remain traceable through Git history. The English edition is synchronized; the Chinese edition controls in the event of a translation ambiguity.
- The old Chinese and English master-plan contents have been replaced in the current version. References to old branch plans, the former master standard and "§29" are historical provenance only; they do not restore the superseded plan. The project's current scope follows the explicit provisions of this plan, confirmed SOPs and the user's subsequent explicit instructions.
- Dates 2026-09-06 / 2026-09-07, "this update", completed checkboxes and statements of work not performed belong to the source's historical record. This replacement only saves, translates and synchronizes the plan entry points. It does not implement a Candidate, compile an EA, run MT5 backtests, change a Champion or enable live trading. Saving the plan does not automatically start its embedded execution instructions.
- Source descriptions of old code, teaching materials, reports and contract specifications were not revalidated in this update. Check the current project, evidence and environment when execution is requested; do not force a rollback to a historical commit.
- Recovery reference: [English version before replacement](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/b0b36546f6b938e7d64be38b9c832f24d019efeb/FINAL_CHAMPION_ITERATION_SYSTEM.md), for historical traceability only.

---

# GSM GOLD 3-SOP EA Legacy-Version Upgrade Research and Development Plan (Fully Consolidated Edition · Risk-Tier Research Update)

Original plan date: 2026-09-06. Consolidated update: 2026-09-07. Risk research update: 2026-09-07. Execution agent: Windows Codex.

**Selected development route: conduct upgrade research within the existing GSM Gold 3-SOP EA project. Preserve the user's own confirmed SOP by default; strategies confirmed not to be user-authored may be optimized autonomously within an authorized research task under §2.2.**

Status: **The complete plan now includes risk-tier research; R13, R24, and R36 have not been implemented, compiled, or backtested in this update. This update has not modified EA source code, submitted anything to GitHub, enabled live trading, or produced any new promotion result.**

The original plan records its basis as main-repository commit `eb74280c53e474e0dbcb0c10c491705689922416`, the V4.00 delivery package, four uploaded textbooks, and six classroom screenshots. The existing top-level architecture and the complete report acceptance requirements in §11 remain in force: complete trade count >100 and native MT5 Recovery >3 remain explicit hard gates for this round and take precedence over more permissive rules for the same items in older documents. The original plan's supporting evidence index is [Source and Baseline Review](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/blob/e634b2b966244ecc7f0aa38ef3d76ba01b0f6369/research/github/SOURCE_AND_BASELINE_AUDIT_2026-09-06_CN.md).

This file updates the fully consolidated edition `EA_RESEARCH_DEVELOPMENT_PLAN_2026-09-07_CN_MERGED.md`; its foundations remain the user-uploaded `EA_RESEARCH_DEVELOPMENT_PLAN_2026-09-06_CN(1).md` and the already incorporated supplement on new methods. Following the user's request to “add it,” this update incorporates the 1%/3% default control and the independent 2%/4% and 3%/6% risk experiments into §2, §3, the task queue, risk interfaces, testing, delivery, and Codex instructions. It is not a separate supplement and does not change the official risk default to 3%/6%.

**Authorization boundary: registered risk tiers may be compared in independent research branches and offline backtests. Risk-only experiments keep their reference strategy and initial SL/TP fixed; they do not authorize relaxing live-trading risk, increasing capital, or automatically switching to a higher-risk tier. Strategy-rule changes follow the origin-based scope in §2.2.** The acceptance gates in §11 for net profit, drawdown, complete trade count, Recovery, and other items remain in force; the risk-tier basis of its consecutive-loss provisions remains as detailed in §3.2–§3.7.

> Material status: the source-code observations, historical figures, and textbook mappings retained in the body come from the original plan's records and do not mean that the repository or backtests have been reverified in this update. The supporting source review, top-level specification, source code, and reports are not packaged with this MD file; they must be checked in the current project during execution. The current project may have later commits; citing a historical commit in this file does not require a rollback to it.

## 1. Decisions for This Round

**Preserve the user's own confirmed SOP by default. Within an authorized research task, strategies confirmed not to be user-authored may have both their core rules and supporting methods autonomously proposed, modified, tested, analyzed, and improved under §2.2.** First align the baseline, risk, and entry definitions, then improve valid opportunities and position management item by item, without making “add more indicators” the primary task.

**Indicator-development delivery requirement:** After selecting indicators with a plausible use, integrate them into an EA candidate's decision path, perform actual compilation and backtests, compare results, and iterate. OBSERVE is a preliminary engineering check. Profitability does not have to be proven before integration, and analysis or indicator display alone does not constitute completed development. See §13.8 for the detailed process.

**Research system added 2026-09-12:** Extend NR02 to identify trends/ranges and separate volatility states; add NR07 related markets, NR08 news/calendar, and DR01 dynamic risk. Verify data and begin with read-only observation, then separately validate risk reduction, pauses, recovery, and independent emergency-management policies. See §13 for detailed states, data boundaries, and iteration. This is a plan update and does not automatically start development or live trading.

Legacy versions and Champions are used to verify implementation, reproduce history, and compare at the same risk, rather than as templates that new methods must copy. Existing indicators are not permanently prohibited; new formulations, uses, or combinations may be proposed, but their substantive differences from previous experiments must be explained. Do not bypass the user's own confirmed SOP. For a NON_USER strategy, register and freeze the candidate's revised qualification rules, compare them against its preserved reference, and keep each order traceable to the applicable version of those rules.

Priority order:

1. Verify the source code, SET files, original reports, and applicable gates for the four Champion tracks; rebuild the default control with R13, separately register R24/R36 feasibility with USD500 and their risk experiments, and retain a same-risk control for each tier.
2. First research the zone-selection biases already found in this repository's source code: composite-score zone selection in Scalping and valid older zones persistently occupying the active selection.
3. Audit First Touch, entry timing, filtered opportunities, and execution failures to identify reproducible problems.
4. Verify Intraday and Swing origins, then research trend evidence, entry location, profit protection, and any permitted core changes under §2.2; retain the locked trigger timing and fixed SL/TP for the user's current Scalping SOP.
5. Incorporate the approach path to a zone, market state, internal reversal quality, relative scale, execution audit, and profit-giveback protection into the existing P0–P6 queue; observe first, then activate candidates individually where authorization is explicit, as detailed in §12.
6. Only after a single strategy wins should it undergo a portfolio backtest as a Combined Candidate.

The objective order remains: Net Profit USD → Max Equity DD → PF → complete trade count → Win Rate. Drawdown has veto power; improvements in profit, frequency, and win rate all require same-risk evidence after costs.

## 2. Baselines and Scope

| Baseline track | In-package identifier | Purpose in this round |
|---|---|---|
| Scalping M5 | SC-S20 | Preserve unchanged as a historical control |
| Intraday M30 | IN-I32 | Preserve unchanged as a historical control |
| Swing D1/H4/M30 | SW-W37 | Preserve unchanged as a historical control |
| Three-strategy combination | C-C01 / V4.00 | Independent combined baseline; adding single-strategy profits is not a substitute |

The original plan records that source-code and ZIP hashes were checked and historical MetaEditor compile logs, MT5 reports, SET/INI files, and audit CSV files in the package were read, but MT5 was not rerun in that environment at the time. This update changes only the plan and does not repeat those checks. Retain existing Champions' historical titles, identity records, and original evidence; list their applicability under the latest mandate separately as `REVALIDATION_REQUIRED`. A historical name does not automatically mean the current round's gates have been passed. Label current comparison targets without verifiable evidence as “baseline pending verification”; do not rewrite history independently or grant new Champion status based on a filename.

The research and development boundary for this round remains: FxPro; Codex; USD500; the three strategies operate independently under OR logic; the user's current Scalping SOP uses fixed SL/TP with no break-even, trailing, partial exits, or runner; no artificial daily trade target; every new order must have an independently qualified Setup under its registered strategy version. The current Scalping SOP's restrictions do not apply to every strategy described as scalping. **The default risk control is R13: per-trade budget ≤1%, portfolio budget ≤3%; this update adds R24: ≤2%/≤4%, and R36: ≤3%/≤6%, solely for preregistered independent backtest research.** The tier is frozen for each run; the account-level portfolio budget is not allocated separately to each engine. Martingale, grids, adding positions because of floating losses, and using “100 confidence” to justify increased risk are prohibited; tiers must not be temporarily raised because no trades occur, losses are consecutive, or a backtest fails.

Rules from the old Aggressive/Balanced/Conservative modes, the nonfarm-payroll pending-order EA, and the Lewis EA are not automatically incorporated into this project. OANDA/FXCM/Pepperstone in classroom screenshots are teaching-chart sources and cannot alter the FxPro testing scope.

### 2.1 Rule Records Requiring Synchronization

The top-level `FINAL_CHAMPION_ITERATION_SYSTEM_CN.md` §29 and later research records contain unsynchronized definitions:

| Item | Top-level §29 | 2026-09-06 research record | Treatment in this plan |
|---|---|---|---|
| Broker | FxPro + Tradona | FxPro only | Current work starts with FxPro; do not independently expand broker scope or claim to have passed the two-broker gate |
| Sample | Assess by strategy; Swing may have fewer than 100 trades but requires stronger evidence | Every single-strategy track and the combination must have >100 complete trades | The user has explicitly specified for this round: >100 is a hard gate, with 200–500 recommended; Swing is not exempt; see §11 |
| Recovery | >3 is a target; falling short requires an explanation and more evidence | >3 is listed as a project gate | The user has explicitly specified for this round: native MT5 Recovery >3 is a hard gate, with an equity-based measure reported separately; see §11 |
| DD | >30% veto; 15%–30% strict review | Same risk direction | Enforce; do not cite only the general references in §7 while overlooking §29 |
| Risk research | Preserve historical risk as recorded in original files | Original research constraint of 1%/3% | The user adds offline R24 and R36 experiments in this update; R13 remains the default. Register each tier independently and do not turn experimental permission into official risk authorization |

The user's additions for this round have resolved the sample-count and Recovery items; do not wait for confirmation on them again. P0 records these requirements and checks the remaining unsynchronized items, particularly broker scope; current work still starts with FxPro. Complete verification of the remaining applicable specifications before final promotion, while continuing material mapping, static audits, and reproduction experiments.

### 2.2 Selected Route, Strategy Origin, SOP Lock, and Permitted Changes (Scope Clarified on 2026-09-12)

“Legacy-version upgrade research” has already been selected. Continue using the current project's engines and risk and execution architecture. Within an authorized research task, autonomy to improve a strategy depends on its recorded origin; it is not limited to supporting methods for a strategy confirmed not to be user-authored. This clarification does not start development or backtesting, authorize live trading, increase capital, or permit overwriting the official version.

| `strategy_origin` | Meaning and current classification | Research treatment |
|---|---|---|
| `USER_OWNED` | User-authored strategy; the user's current Scalping SOP is confirmed in this category | Preserve the confirmed SOP by default. If it needs revision, state the problem, evidence, and specific proposal, and handle the change according to the user's explicit instructions for that SOP. Existing authorization for compliant implementation fixes and supporting research remains valid. |
| `NON_USER` | Strategy confirmed not to be user-authored, with its source and supporting evidence recorded | Within an authorized research task, autonomously optimize signals, direction, zones, patterns, triggers, entries, exits, initial SL/TP, and position management; implement, test, and iterate. This permission covers core rules as well as supporting modules and requires no new per-iteration approval. |
| `UNKNOWN` | Origin has not yet been established; do not automatically classify Intraday or Swing as NON_USER | Check existing source material and user statements first. Preserve identified user-authored rules while resolving the remaining origin; continue independent authorized work. An unknown origin is not a reason to invent a new approval step for every experiment. |

This origin-based scope qualifies the SOP-lock, supporting-method-only, and Scalping-specific clauses throughout the plan, including §§1, 4, 5, 9, and 12. The current user-authored Scalping SOP's fixed-SL/TP and position-management restrictions do not extend to every scalping strategy. Record `strategy_origin` and its evidence before using NON_USER optimization authority; a filename, timeframe, or strategy family alone does not establish origin. For each experiment, preserve and freeze the reference rules and candidate rules separately, identify their actual differences, and compare them under declared conditions. Risk-only comparisons continue to freeze strategy logic and initial SL/TP; project risk caps, broker, capital, acceptance gates, and deployment boundaries are unchanged.

Before execution, establish `SOP_LOCK` and `IMPLEMENTATION_DIFF`, registering for each engine: `strategy_origin / origin_evidence / protected_user_rules / strategy_rules_changed / user_sop_changed`, original strategy rules, the user's confirmed locked rules where applicable, reference implementation/SET, candidate changes, permitted research scope, feature availability time, and whether the code matches its declared rule version. Retain all differences between original SOP parameters and historical Champion parameters listed in §4; do not interchange them automatically.

| Change category | Treatment in this round | Key boundary |
|---|---|---|
| Implementation fixes | May be fixed in independent candidates, with a bug reproduction and regression tests provided first | Must demonstrate that the code deviates from the confirmed SOP; do not disguise a change in definition as a bug fix |
| Supporting-method research | May be proposed, implemented, and tested autonomously; default to OBSERVE first, then ACTIVE at permitted locations | Preserve the user's confirmed SOP; NON_USER core-rule optimization uses the separate category below |
| NON_USER strategy optimization | Autonomously propose, modify, test, and improve core rules and supporting methods within the authorized research task | Record origin evidence and each rule change; freeze reference and candidate separately, retain reproducible controls, and comply with project risk and deployment limits |
| Cleanup of old add-on modules | Non-SOP research modules may be disabled, replaced, or rewritten individually | Classify first, retain switches and rollback capability; do not also delete necessary risk/execution protections |
| Changes to the user's own SOP | Record the problem, evidence, and concrete `SOP_CHANGE_PROPOSAL`; handle any necessary revision under the user's explicit instructions for that SOP | Do not mistake permission to optimize NON_USER strategies for a change to the user's confirmed SOP; do not add a new approval requirement to every already-authorized experiment |
| Risk-tier experiments | Test R13/R24/R36 and preregistered split-factor controls in independent candidates | Change only registered budget variables; leave SOPs, initial SL/TP, capital, contract, and other safety protections unchanged; do not optimize them simultaneously with new signal methods |

Record reference qualification, candidate qualification, and actual execution separately. Filtering experiments must not relabel a reference-qualified Setup that was filtered out as originally unqualified. Do not introduce waiting in the name of support when it conflicts with the user's confirmed immediate-entry SOP. The boundary prohibiting break-even, trailing, partial exits, and runners remains in force for the user's current Scalping SOP; NON_USER strategies may research those methods under their registered candidate rules.

Resolve conflicts involving the user's own SOP through the scope above, while continuing independent authorized work. Do not silently alter the user's confirmed SOP, shorten stops in a frozen risk-only comparison, temporarily raise the current run's risk tier, or remove safety gates to reach a trade count. NON_USER strategy changes, including initial SL/TP experiments, must be declared as strategy research with separate frozen controls. R24/R36 are independent research schemes explicitly added in this update, not an automatic relaxation route after R13 fails; they may be registered first and then tested, but poor results do not permit temporarily raising their caps further.

## 3. First Resolve USD500 Feasibility Under Actual Stop-Loss Risk

The historical combined SET uses a fixed 0.01 lot and 10% portfolio risk, with an additional small-account exception input permitting up to 5% per trade, but that test had the small-account Profile disabled; the fixed-volume path did not consistently enforce 1% per trade. All 25 trades in the FxPro combination had initial SL risk exceeding 1%; the standalone Scalping/Intraday total-risk SET values were still 20%. These results cannot be ranked directly by net profit against the new 1%/3% budgets. The historical Tradona Swing report also recorded one trade with 9.93% initial SL risk; risk must be checked trade by trade rather than only reading `RiskPercent=1` in the inputs.

First carry out the following two groups of foundational work; then establish independent supporting-module cleanup controls for new-method research under §3.1:

- **Historical reproduction group H0:** original source code, original SET, original dates, and original costs; its sole purpose is to verify that historical results are reproducible, with no live-trading connection.
- **Budget-standardization group B0:** in a separate research branch, first establish the R13 (1%/3%) default control, making only necessary risk-control changes and recording differences. R24/R36 copy the same reference logic, with separate same-tier controls carrying `risk_profile_id`, using the same risk engine and explicitly registered sizing modes; subsequent strategy Candidates must be paired against B0/K0/fixed baselines of the same tier and under the same sizing rules. This does not automatically create a new Champion.

For each actual Setup, first calculate:

`最小手数止损损失 = abs(OrderCalcProfit(方向, 品种, 最小手数, 入场价, SL))` — minimum-volume stop-loss loss = abs(OrderCalcProfit(direction, symbol, minimum volume, entry price, SL)).

`f_single = SingleRiskCapPct / 100` (R13=0.01, R24=0.02, R36=0.03)

`所需最低净值_单笔 = (最小手数止损损失 + 明确成本缓冲) / f_single` — required minimum equity per trade = (minimum-volume stop-loss loss + explicit cost buffer) / f_single.

These are only minimum-equity conditions for an individual trade; the remaining portfolio budget, margin, and all execution checks must still pass. They do not guarantee that a particular trade or portfolio can be executed.

`允许手数 = 向下对齐券商 volume step(扣除成本预留后的可用预算 / 单位手数止损损失)` — permitted volume = round down to the broker's volume step(available budget after cost reservation / stop-loss loss per unit of volume).

When costs vary with volume, iteratively reduce volume using the same cost model; after normalizing SL and volume to tick size/volume step, recalculate and verify finally that “stop-loss price-difference loss + cost buffer ≤ per-trade budget and ≤ remaining portfolio budget.” Reject the trade if calculation fails or a cap is exceeded; do not approve solely from the raw quotient of the formula.

OrderCalcProfit provides estimated profit/loss in the account currency; commission, holding costs, and a slippage buffer must be listed separately and must not be assumed to be fully included. [Official definition](https://www.mql5.com/en/docs/trading/ordercalcprofit)

Using historical CoursePip=0.10 and Scalping SL80 as an example, the price difference is 8.00; if the contract is indeed 100 ounces per lot and the minimum volume is 0.01 lot, the stop-loss price-difference loss alone is approximately USD8, already exceeding the budget for USD500 at 1%, namely USD5. This is a unit illustration; actual decisions must read the contract specifications and quotes applicable at the time.

If the minimum volume already exceeds the per-trade budget frozen for this run, output `MIN_LOT_OVER_RISK` and skip; if the individual trade is feasible but the remaining portfolio budget is insufficient, record `PORTFOLIO_RISK_FULL` separately. Report, tier by tier, which strategies/SLs cannot be executed with USD500; do not secretly add capital, switch contracts, shorten SOP stop losses, or relax risk within the same run. Smaller-contract/capital thresholds may be recorded for later selection, but this round does not switch to them automatically. If B0 at a tier cannot produce enough valid trades, label that tier `CAPITAL_CONSTRAINT`; this neither proves the strategy good or bad nor prevents the other registered independent R24/R36 experiments.

### 3.1 H0 / B0 / K0 / Candidate: Distinguish the Source of Improvement

Retain the original plan's meanings of H0 and B0; do not adopt B0/B1 from the supplement where the same names have different meanings. The added `K0` is only a research-control label and does not consume a registered Candidate ID.

| Control | What is retained or changed | What it can establish |
|---|---|---|
| H0 historical reproduction | Original source code, original SET, original risk, and costs | Historical reproduction only; cannot declare a winner by directly comparing net profit with candidates at different risk tiers |
| B0 same-risk baseline | On the version corresponding to H0, add only the listed risk-control adaptations; R13 is the default, with separate same-tier controls for R24/R36 | Execution feasibility and original-logic performance at the same tier; old research extensions have not yet been cleaned up by default |
| K0 supporting-module cleanup control | Start from B0 or an explicitly recorded fixed baseline, retain locked SOPs and necessary safety and execution rules, and disable non-SOP extensions individually | The effect of removing old additional restrictions; does not establish an advantage for a new method |
| Single-module Candidate | After freezing the corresponding K0/fixed baseline, add only one primary research variable | Marginal effect of the new method; compare against the same `reference_id` |

First register `OPTIONAL_MODULE_INVENTORY`, identifying whether each old module belongs to SOP, research add-on, risk, execution, or position management. Do not silently disable modules that cannot be classified. K0 may initially serve as a read-only core-signal audit layer; until authorization checks or capital-feasibility checks are complete, it must not be treated as a new executable baseline.

List differences and tests separately for every behavioral change from B0 to K0. Do not combine implementation fixes, supporting-module cleanup, and new methods under a single attribution of returns; if P1/P2 first fixes implementation, freeze a new `reference_id` with its fix record, use it in all subsequent paired experiments, and retain the unfixed control.

All executable B0/K0/Candidates must adhere to USD500, the same actual-risk calculation rules, and the risk tier frozen before that run. R13 is the default when no tier is declared; R24/R36 and split-factor controls must be explicitly declared and have their SET/INI files saved independently. Signal research may additionally report results in R units or virtual replays, which must be labeled `COUNTERFACTUAL_ONLY`; unexecutable signals cannot count as complete MT5 trades, and virtual results cannot bypass that tier's `CAPITAL_CONSTRAINT`. Where the original comparison target has not been reproduced, label it `BASELINE_NOT_REPRODUCED`; continue diagnosis but do not claim to have beaten it.

`B0-R13 / K0-R13 / B0-R24 / K0-R24 / B0-R36 / K0-R36` are control roles plus risk labels and do not replace existing Candidate IDs. Attach `reference_id + risk_profile_id + sizing_mode + source_hash` to every conclusion; for example, NR01's R24 candidate must be compared against the same R24 reference version, rather than using the net profit of an R13 run with fewer trades as evidence that “the new method won.”

### 3.2 Added Risk Research Tiers: Retain the Low-Risk Control Without Presuming That Higher Risk Wins

This section is based on the user's explicit authorization to “add it” following the previous risk discussion. **Permission to test does not mean a live-trading tier has been selected.** The figures are research budgets, not return targets, loss guarantees, or daily trading allowances.

| Tier | Planned per-trade risk cap | Planned account-portfolio risk cap | Per-trade/portfolio budget at current equity of USD500 | Purpose |
|---|---:|---:|---:|---|
| R13 default control | 1% | 3% | USD5 / USD15 | Retain the original constraints; quantify how many valid opportunities are blocked by minimum-volume and portfolio limits |
| R24 candidate A | 2% | 4% | USD10 / USD20 | Research feasibility and the drawdown cost of a moderate budget increase |
| R36 candidate B | 3% | 6% | USD15 / USD30 | Research opportunities, concurrency, consecutive losses, and tail losses under a wider budget |

Calculate budgets from **account equity at that time** on every occasion, rather than always using the initial USD500. Caps do not require full utilization on every trade; when 0.01 lot already meets the research objective for a Setup, do not proactively increase it to the maximum merely because R36 permits 3%. Do not temporarily raise base caps or rewrite the policy because of floating losses, consecutive losses, a high win rate, or “100% confidence.” Dynamic candidates under §13 may reduce risk, pause, and gradually recover within base caps under state rules frozen before the experiment; they do not automatically switch between R13/R24/R36.

The three SOPs scan and generate Setups independently but share the account-level portfolio budget. R36 does not mean each of the three strategies has 6%; nor does it guarantee that all three can open positions simultaneously. Every new order still requires independent SOP qualification, available budget, margin, and execution conditions.

Official/deployment default parameters remain R13. Save research parameters in separate directories and branches and label them explicitly `RESEARCH_ONLY`; this update places no orders and does not modify live SET files. Candidate implementations must check the runtime environment at the backtest entry point; this round's higher-risk research configurations must not be enabled outside the Tester environment. Future demo or live use requires separate approval and is not automatically granted by this plan. This is currently an implementation requirement for the protection; it has not yet been coded or verified.

### 3.3 USD500, Minimum Volume, and Original Stop Losses: Trade-by-Trade Feasibility Examples

The following only reuse historical unit examples from the original plan: assume a contract of 100 ounces per lot, minimum volume of 0.01 lot, and CoursePip=0.10; **these are not current FxPro contract specifications read in this update and must not automatically be written back into parameters.** Actual execution must read the relevant symbol's real contract specifications, quotes, tick size, and volume step. Preserve the differences between original SOPs and historical SETs as specified in §4.

| Historical example | Original stop-loss price distance | Stop-loss price-difference loss at 0.01 lot | Percentage of USD500 | R13 individual trade | R24 individual trade | R36 individual trade |
|---|---:|---:|---:|---|---|---|
| Scalping historical SL80 | USD8 | USD8 | 1.6% | Over cap | May pass only if cost buffer ≤USD2 | May pass only if cost buffer ≤USD7 |
| Intraday historical SL120 | USD12 | USD12 | 2.4% | Over cap | Over cap | May pass only if cost buffer ≤USD3 |
| Swing actual structural SL | Calculate by Setup | Calculate from contract | Calculate trade by trade | Verify trade by trade | Verify trade by trade | Verify trade by trade |

The table checks only individual-trade risk conditions; it does not guarantee that a position can be opened. The cost buffer must not be set to 0 simply to pass a gate; commissions, fees, the effect of spread already included, and added stress costs must be deduplicated under §11.

When both trades are being prepared for new entry at the same time and still use their initial SLs, the combined price-difference risk of the Scalping and Intraday examples above is approximately USD20, equivalent on a 500-dollar account to 4%, before additional cost buffers. The R13 portfolio budget of USD15 is insufficient; R24 also cannot let that Intraday trade pass its USD10 per-trade cap; R36 may accommodate both only if additional costs, margin, and existing exposure permit. The split-factor control of “3% per trade/4% portfolio” already exhausts the USD20 budget on price-difference risk, so it still fails if there is a positive additional cost reservation. When open positions have profits, SLs change, or equity changes, risk must be recalculated on the same basis rather than repeatedly adding old initial figures.

With a strict 1% per-trade limit, USD8 and USD12 of price-difference loss correspond to at least USD800 and USD1,200 in equity, respectively; these are only **mathematical lower bounds for an individual trade excluding cost buffers**, not recommendations to increase capital or guarantees of portfolio feasibility. Changing leverage does not change price-difference loss in this example while the contract, volume, and entry/SL prices remain unchanged; margin and stop-loss budgets are calculated separately.

### 3.4 Controlled Experiments: Distinguish “More Trades Become Executable” from “Position Size Increases”

First fix SOPs, signal methods, initial SL/TP, position management, dates, costs, contract specifications, and the execution model; do not tune new scoring, risk tiers, and exit parameters simultaneously. Freeze the sizing mode and number of experiments before each stage instead of searching all combinations without limit.

**Stage one: budget-gate feasibility (RG).** Use the same target-volume rule across tiers for every independent Setup; the first round may use the broker's minimum legal volume read from the platform rather than hard-coding 0.01 for every account. Every tier must still perform strict risk and margin checks and reject excess risk. This stage primarily answers which originally qualified opportunities the increased budget makes executable and which remain blocked; it does not force each tier to use its full risk allowance. Do not automatically use several times more volume at the 3% tier than at the 1% tier and report only “improved opportunities.”

**Stage two: actual position sizing (SZ).** Once feasibility is clear, fix the same sizing algorithm, identical target-risk rules, and all other parameters, then run each risk tier separately. If studying “derive volume from each tier's cap,” explicitly register it as a separate position-allocation experiment and report the effects of both volume changes and additional opportunities; do not combine it with stage one in a single table to claim signal superiority. Report fixed and dynamic sizing separately, pair comparisons on the same basis, and do not silently switch compounding modes.

The main report must list R13, R24, and R36. Because the main tiers change both per-trade and portfolio caps simultaneously, add at most the following three split-factor controls, registering them before running them and remaining within this update's 3%/6% research boundary:

| Control ID | Per-trade/portfolio cap | Main comparison and purpose |
|---|---|---|
| D23 | 2% / 3% | R13→D23 changes only the per-trade cap; D23→R24 changes only the portfolio cap |
| D33 | 3% / 3% | D23→D33 changes only the per-trade cap to observe the bottleneck of the original portfolio budget |
| D34 | 3% / 4% | R24→D34 changes only the per-trade cap; D33→D34 and D34→R36 each change only the portfolio cap |

These IDs are research-matrix labels, not new official operating tiers, and do not consume old Candidate numbers. The first round allows at most six budget combinations per frozen sizing mode, including the three main tiers; capital-constrained R13 does not have to be “tuned to PASS” before R24/R36 may proceed. If a split-factor control lacks enough samples because trades are unexecutable, retain the result rather than manufacturing orders to complete a curve.

First run budget experiments on the same reference logic, then freeze a research tier and test new supporting methods within that tier. If the reference code or signal method is subsequently modified, create a separate experiment and rerun the relevant same-tier controls; do not use old risk-experiment results to endorse new code. Run S-only, I-only, W-only, and an actual Combined test for every tier; do not substitute summed independent profits for a combined test.

### 3.5 Risk Calculation, Portfolio Reservations, and Over-Budget Handling

The following is the base-budget interface for fixed-risk controls, not completed MQL5 code. ACTIVE dynamic candidates under §13 additionally apply account/engine multipliers to calculate effective budgets. OFF/OBSERVE must not change actual budgets, and existing-position and reserved risk must not shrink with the multiplier:

```text
risk_profile_id       = R13 / R24 / R36 / preregistered split-factor control
single_cap_fraction   = SingleRiskCapPct / 100
portfolio_cap_fraction= PortfolioRiskCapPct / 100
single_budget_usd    = CurrentEquity × single_cap_fraction
portfolio_budget_usd = CurrentEquity × portfolio_cap_fraction
remaining_budget_usd = max(0, portfolio_budget_usd - AccountRiskUsedAndReserved)
new_setup_budget_usd = min(single_budget_usd, remaining_budget_usd)
```

`AccountRiskUsedAndReserved` must consistently include identified positions, pending orders, and in-flight requests; existing trades from other EAs or manual trading on the account must not be silently ignored. Distinguish initial SL risk, the risk of current equity falling to the SL, and cost buffers under §6, and preregister the basis actually used for gating; it must be identical across tiers. Exposure risk must be nonnegative; do not use locked floating profit or simple long/short netting to manufacture extra budget. Stress-test separately the possibility of simultaneous stop-loss executions across same-direction gold strategies. Reconcile and deduplicate filled portions, unfilled remainders, and in-flight records of the same order; do not reserve budget twice or release it prematurely.

Round volume down to volume step and finally recalculate SL price-difference loss, costs, and the remaining portfolio budget. If volume falls below the minimum, do not round up and falsely claim compliance; higher-risk tiers are no exception. A 3% per-trade cap permits that trade only within the current-equity budget, and a 6% portfolio cap does not permit a single 6% order.

Before each send, Portfolio must reserve the budget serially; settle or retain reservations for definitive failures, partial fills, and unknown requests according to server state. The three engines must not each read a stale balance and approve simultaneously. When budget or data are unclear, stop adding new risk while continuing to manage existing positions under the system's responsibility; insufficient risk budget does not mean all orders must be forcibly closed.

Market movement, equity decline, gaps, fill deviations, or dynamic budget reductions may cause budget breaches. Record `RISK_BUDGET_BREACH`, its cause, and amount; freeze new risk, while ENTRY_ONLY continues the original permitted management. Separately register MANAGED_EMERGENCY cancellation/reduction/exit experiments under §13.6, first checking SOP scope and authority over the positions being managed; do not mix them into pure risk-tier comparisons. Do not widen SL, add positions to floating losses, or temporarily raise caps. Recovery follows the frozen policy in §13. No tier promises that actual losses can never exceed its cap.

### 3.6 Consecutive-Loss and Portfolio-Risk Stress: Returns Must Not Hide Their Cost

Continue the §11 requirement to test 6 losses, 8 losses, the historically longest losing streak, and more adverse scenarios; each tier must use its own frozen budget and actual equity path, including fees, minimum volume, slippage, same-direction positions, and margin, rather than percentage-only mental arithmetic.

The following table is only a mathematical example: assume no concurrent positions, each trade loses exactly a fraction r of equity at that time, and there is no excess slippage or additional loss:

`连续n次损失后的净值降幅 = 1 - (1-r)^n` — the left-hand side is the equity decline after n consecutive losses.

| Actual loss per trade r | Cumulative decline after 6 consecutive losses | Cumulative decline after 8 consecutive losses |
|---|---:|---:|
| 1% | 5.85% | 7.73% |
| 2% | 11.42% | 14.92% |
| 3% | 16.70% | 21.63% |

These are not EA backtest results, forecasts of future losing streaks, or risk probabilities; actual results do not equal the table values when the tier allowance is not fully used. With fixed minimum volume, falling equity increases the percentage represented by the same stop-loss amount, so later trades may be rejected; do not assume that theoretical fractional volumes can continue to be executed.

Separately stress the portfolio cap for same-direction stop-loss executions across an entire basket, simultaneous deterioration of correlated positions, and adverse slippage; do not equate “8 consecutive individual-trade losses” with “8 consecutive portfolio losses.” Report at least peak budget utilization, minimum equity, maximum relative equity drawdown, longest losing streak and its total loss, risk breaches, and the minimum margin level. **The §11 drawdown target of ≤15%, strict review for >15% and ≤30%, and hard rejection for >30% are not relaxed for R24/R36.**

### 3.7 Report Decisions and Adoption Boundaries

Risk reports must distinguish three questions: **whether the capital permits execution, whether the signal has an advantage after costs, and whether assuming more risk is worthwhile.** More fills, higher net profit, or >100 trades in a tier cannot individually prove strategy improvement.

Same-tier controls primarily evaluate the marginal effect of a new method; cross-tier controls evaluate only the tradeoff from budgets and position allocation. Trace additional fills through stable SetupIDs: were they originally blocked by the per-trade cap, a full portfolio budget, margin, or another reason? How much additional profit/loss occurs now? Have volume, costs, or paths changed for trades executed in both versions? Do not describe an amplified equity curve caused by higher risk as improved predictive ability.

Report each tier independently: net profit/return, PF, maximum equity DD, native and equity-based Recovery, complete trade count, net expectancy and its uncertainty, average and maximum initial risk, peak current-exposure risk, volume distribution, number of risk rejections, profitable/loss-making additional opportunities, missed winners, and tail losses. For tiers with 0 trades or small samples, retain diagnoses such as `CAPITAL_CONSTRAINT / LOW_SAMPLE_SIZE`; do not combine virtual Setups, partial-exit Deals, or duplicate trades across different tiers to manufacture sample size.

Configurations formally proposed for promotion must still satisfy §11 for every independent track and the actual Combined test: >100 complete trades in the main period, native Recovery >3, net-profit and risk requirements, plus independent OOS and stress evidence. Insufficient samples when R13 serves only as a capital-constrained control do not automatically block R24/R36 research and do not prove that a higher-risk candidate has won; a candidate proposed for promotion must have its own valid reference under the **same tier and same sizing rules**, with complete evidence.

Tiers and sizing modes are also selection parameters: select and freeze them on the development/training segment before examining a validation segment not used for selection. Choosing the best tier after seeing OOS results makes that segment selection data; it cannot be renamed a blind test. Stress failures, low samples, and losing results for all tiers must be disclosed together; do not retain only the tier with the highest net profit.

Research conclusions may recommend retaining R13, continuing research on R24, rejecting R36, or requiring more evidence for all tiers; do not prefill an optimal answer. Retain the original Final Verdict enumeration and record the explanation for risk-tier selection separately. Even with research evidence, a higher tier **does not automatically replace the R13 deployment default or acquire live-trading permission**; formal configuration requires an explicit user selection, applicable capital, and an approval record. This authorization is sufficient to execute the offline experiments above, without repeatedly requesting confirmation for every preregistered run.

## 4. Mapping the Teaching Materials to the Program

| Knowledge layer | Verified source | The program must explicitly define | Role in this round |
|---|---|---|---|
| S&D | p4–6 Long Wick/Base Break/Impulsive; p7 First Touch; p8 50% pending entry for wide zones | Formation and confirmation times, departure, first-touch episode, invalidation, units | Cross-check core rules and engineering definitions item by item |
| S/R | p2 two or more touches; p4 role reversal; p6 quality; p7 false breakout | Independent touch counting, close back inside, a new object after role reversal | Keep types and lifecycles separate from S&D |
| 8 chart patterns | Chart p3–10; p11 confirmation → retest → entry | Pivot confirmation time, tolerance, span, breakout and retest | Establish recognition coverage and logs first; do not turn all patterns into hard gates at once |
| 36 candlestick labels | Candle p2–6; p6 confirmation and volume; p8 execution examples | Mathematical pattern definitions, context, direction, close confirmation, deduplication within each family | Retain multiple labels; strategies use their respective whitelists/candidates |
| Classroom screenshots | Long/short positioning, three types of traders, discipline and review | Record separately against each specific SOP | Evidence for context and workflow, not backtest performance |

The four books do not independently specify all timeframes/SL/TP for the complete three-engine system. Special treatment:

- **S&D First Touch and repeated S/R respect must not be merged into the same scoring rule.**
- For “30 points” in the teaching materials, no MT5 point value is defined; the two unit inputs in the existing code are 0.10, which is a convention of the current implementation. Also register the boundary at exactly 30 points in the teaching materials. Preserve the current values for reproduction; do not claim that the teaching materials prove the conversion.
- The Scalping Base document specifies 50/50, while the current SC-S20/combined SET uses 80/70; the former is the original SOP and the latter is the historical Champion parameter set. Record both; do not automatically revert to 50/50.
- The Intraday Base document specifies SL120/TP240, while the locked IN-I32 parameters are SL120/TP70; register them separately, and do not substitute the Base description for the actual SET.
- The candlestick teaching materials' global requirement for “confirmation at the next candle's close” and H4/D priority differs from the current execution at the close of the M5 candle that touches the zone. Additional waiting that conflicts with the user's current Scalping SOP is a `SOP_CHANGE_PROPOSAL`, handled under the user's explicit instructions for that SOP. A confirmed NON_USER strategy may separately test revised confirmation timing under §2.2. Internal-quality evidence must use only data available at the applicable version's declared decision time.
- The book does not specify the averaging window/source for the 1.5-times volume requirement. Current tick volume can serve only as a proxy for activity in that quote stream and must not be called actual centralized-market traded volume; observe first, and do not directly add a hard filter.
- Preplacing at 50% of a wide zone, the S/R Limit example, the Stop example after candlestick confirmation, and immediate market execution are different paths; audit them strategy by strategy, and do not convert all 3-SOP execution to pending orders. Preserve the user's confirmed entry path unless the user's instructions for that SOP establish a change. A confirmed NON_USER strategy may autonomously register and compare revised entry paths under §2.2.
- Write versioned programmatic definitions for Broken Zone, Departure thresholds, wick/ATR ratios, and pivot delays. The wording of the head-and-shoulders target is ambiguous; preserve that uncertainty rather than inventing a source definition. Any TP research follows §2.2, with a separately declared candidate definition and an unchanged reference.

Register every definition using: `rule_id / source_page / source_text_summary / engine / strategy_origin / origin_evidence / current_function / current_value / proposed_definition / available_at / strategy_rules_changed / user_sop_changed / status`. If a legacy registry retains `sop_changed`, define its meaning explicitly instead of forcing false for authorized NON_USER rule changes.

## 5. Research and Development Task Queue and Acceptance

The following table contains task IDs for the new plan, **not Candidate IDs that have already been registered or passed**. At execution time, read the existing registry first, then allocate S-/I-/W-/C-Candidate IDs, preserving the history of SC-S20, IN-I32, SW-W37, and C-C01. Each subexperiment changes only one main variable.

| Order / Task | Specific work | Required deliverables and exit criteria |
|---|---|---|
| P0 Baselines and feasibility | Freeze 4 baselines; inspect the current workspace and source/EX5/SET/INI/hash; verify strategy origins, contracts, units, risk, and already-used data; establish H0/B0 controls and the K0 extension-cleanup list | BASELINE_MANIFEST, MANDATE_MATRIX, RISK_FEASIBILITY for each tier, SOP_LOCK with origin evidence, OPTIONAL_MODULE_INVENTORY; do not pass off old 10% results as R13/R24/R36 results |
| P0-R Tiered risk research | R13 as the default control; R24/R36 and preregistered split-factor controls; first RG budget gating, then independent SZ lot-sizing research as needed; freeze the reference logic | RISK_PROFILE_MATRIX, audit of risk rejections and additional Setups, S/I/W/Combined for each tier, consecutive-loss/cost/tail stress tests; do not require R13 to PASS first, do not automatically enable live trading, and do not tune signals simultaneously |
| P0-M Market-data and dynamic-risk preparation | Inventory platform symbols/build, news/calendar, and historical versions under §13; extend NR02 and establish NR07/NR08 observations and the DR01 policy | Input availability, time alignment, snapshots, state definitions, and read-only consistency; register dynamic account risk, market-based risk adjustment, and emergency management separately, without changing the original P1/P2 repair scope |
| P1 Zone selection | P1a changes only Scalping ranking to the nearest valid zone, with quality used only as an equal-distance tie-break; P1b separately tests old-zone occupation and candidate reselection | Zone candidate list + price distances + old/new selection comparison; pass inside=0, near-weak/far-strong, equal-distance, and new-zone-appearance cases; preserve first-touch state |
| P2 First touch and missed trades | Start with read-only event replay, distinguishing formation → departure → first return episode → confirmation → consumption; a technical order rejection does not imply permission for a second fresh attempt | FirstTouch trace, LOST_OPPORTUNITIES; continuous ticks/continuous candles must not be counted repeatedly, and restarts must not reset fresh; create a separate Candidate for each change |
| P3 Intraday direction/location | Verify origin under §2.2; select the main cause from actual losses and the funnel; observe NR01/NR02 independently, then separately test trend evidence, entry location, or a permitted core-rule change | Single-variable description for I candidates; trace confirmation time and entry price. Preserve confirmed user-authored M30 eligibility and locked entry rules; a confirmed NON_USER strategy may autonomously test revised direction, qualification, or timing with frozen old/new controls |
| P4 Intraday/Swing management | Verify each strategy's origin; within its §2.2 scope, separately test cost-adjusted break-even, structure/ATR trailing, partial exits, or time exits; integrate NR06 into Swing and first audit ticket isolation and restarts | Freeze each experiment's initial R; protective SL only tightens, and no partial exit when 0.01 cannot be split legally. Protection functions remain unreachable for the user's current Scalping SOP; this restriction does not exclude other NON_USER scalping strategies from management research |
| P5 Patterns and evidence | Cover all 8 chart patterns/36 candlesticks individually; observe logs first, then select a few families for testing based on evidence; integrate NR03/NR04 and retain BOS/CHoCH/soft-scoring research entry points | Positive/negative cases, deduplication, and no future data; preserve pattern whitelists and close confirmation belonging to the user's locked SOP. Confirmed NON_USER strategies may test changed patterns or confirmation rules in separately registered experiments; report coverage and profitability validation separately |
| P6 Independent opportunities and the portfolio | First establish that position limits genuinely block eligible Setups; then study concurrent risk reservation separately; rerun combinations of winning individual strategies at the frozen tiers | Combined backtests under the same-tier risk and lot-sizing rules; list cross-tier R13/R24/R36 comparisons separately; audit same-direction exposure, margin, strategy attribution, and drawdown correlation; do not treat additional positions as a strategy advantage |

The P1 source-code evidence recorded in the original plan: `FindBestSDZone` ultimately selects the zone with the highest score; `UpdateSupplyDemandStates` searches only after active becomes invalid/used/broken/expired. `DistanceToZone` already correctly treats distance inside a zone as 0; reuse it and verify the semantics of its calls, rather than rewriting it without evidence. Recheck the current commit before implementation: if the issue is already fixed, verify regression behavior first and do not repeat the modification; any modification must also comply with SOP_LOCK.

P1a leaves the formal parameter structure unchanged; P1b must not treat “being replaced” as erasing historical touches. Preserve independent ZoneID state; a zone already touched must not regain fresh status through zone switching. When Swing shares a function, isolate it through engine parameters/strategy branches; this experiment must not incidentally alter Swing.

The current P2 Scalping path consumes the Zone before sending, including when no whitelist matches or indicator/gating checks fail. This is the existing intentional duplicate-prevention semantics; **first count lost opportunities only, and do not remove it directly**. When researching retryability, distinguish explicit server rejection, unknown status after timeout, partial fills, and absence of SOP qualification; unknown states must be reconciled, never blindly resent.

Existing labels also cannot be treated directly as causes: all 20 Scalping trades in the FxPro combination are marked `ChaseEntry=YES`, and 15 are profitable; directly filtering that label would eliminate this entire sample. The Intraday funnel has 391 FirstTouches, 380 EMARejected events, and ultimately 4 trades, but the fields are not mutually exclusive reasons. The only FxPro Swing order had MFE of USD48.94 and ended at USD0.66, which warrants research into profit retention but is insufficient for parameter tuning. Reconstruct the timeline for each Setup and freeze the comparison method in advance.

P5 continues the existing GitHub research index and preserves the original GH01–GH10 source mappings. Prioritizing the local implementation differences recorded in the original plan ahead of new external indicators does not cancel research into BOS/CHoCH and related methods. ONNX/online AI, Footprint, and large-scale indicator fusion remain deferred; rule-based scores must not be called actual success probabilities.

Register all new methods under §12. Their sources may be `ORIGINAL_RESEARCH`, `REDEFINED_EXISTING_METHOD`, or `EXTERNAL_REFERENCE`; new ideas are no longer required to originate from GitHub. Autonomous design here refers to research hypotheses and combinations for this project, not a claim that the underlying formulas are global firsts. Retesting old methods requires an explanation of a new use, new feature, or new causal hypothesis; merely renaming a method or repeating searches for the old optimum parameters does not count as new research. Reusing external code still requires recording its source and checking its license.

## 6. Program Interfaces and Execution Discipline

Follow the top-level sequence: **GSM SOP → Three independent engines → Optional evidence → Risk → Portfolio → Execution → MT5 → Audit**.

- Detectors output structured evidence and do not place orders. Engines generate candidates containing `engine_id, zone_id, setup_id, direction, signal_time, confirmation_time, expiry, planned_entry, SL, TP`.
- Risk reads actual contracts, current equity, existing exposure, pending orders and in-flight requests, plus the `risk_profile_id / single_cap / portfolio_cap / sizing_mode` frozen for this run. DR01 ACTIVE candidates also read the §13 policy/config, account/engine states, multipliers, and data health to calculate effective budgets consistently. Portfolio serially reserves risk and margin before sending. An undeclared tier defaults to R13; market scores must not automatically raise the base tier. NR02/NR07/NR08 output evidence and do not place orders independently. The EA executes locally; Python is used only for MCP monitoring.
- Enforce the single-trade budget uniformly across all lot-sizing modes; do not silently ignore failed risk calculations, exposure without SL, or account exposure that cannot be attributed. The new risk specification separately records initial-SL risk, the risk of a decline from current equity to SL, and the cost buffer; explicitly define how manual trades/other EAs/pending orders are included, and do not count the same risk twice.
- Repeated ticks for the same signal, delayed responses, restarts, rejections, and partial fills must not duplicate risk counting or order placement. On netting accounts, Magic alone cannot establish independence of the three strategies; explicitly verify behavior that currently requires Hedging, and do not remove that requirement without authorization.
- `OrderSend=true` does not prove a fill; record retcode and complete reconciliation using trade notifications and server Order/Deal/Position states. [Official OrderSend documentation](https://www.mql5.com/en/docs/trading/ordersend) [Trade transaction notifications](https://www.mql5.com/en/docs/event_handlers/ontradetransaction)
- When new positions are prohibited, continue permitted management of existing positions. Emergency actions under §13.6 operate only within registered candidate modes and ownership scope. Lock every modification to the ticket and strategy; do not modify another engine's position merely by matching symbol. Measuring whole-account risk does not confer authority to manage all orders.
- Risk budgets are pre-entry constraints; gaps/slippage may cause actual losses to exceed the tier's budget. Tests report overruns and tail losses, and must not claim that stop-losses guarantee losses never exceed 1%, 2%, 3%, or any portfolio cap. On an overrun, prohibit new risk and handle management and recovery under §3.5 and the frozen §13 policy; do not temporarily raise base caps.

Suggested stable reason codes: `NO_VALID_ZONE, NOT_FIRST_TOUCH, NO_REVERSAL, WRONG_TREND, LATE_ENTRY, DUPLICATE_SETUP, MIN_LOT_OVER_RISK, PORTFOLIO_RISK_FULL, MARGIN_INSUFFICIENT, SPREAD_TOO_HIGH, DATA_NOT_READY, REQUEST_UNKNOWN, BROKER_REJECT`. This is a proposed audit vocabulary; implement it after mapping existing fields.

“Reject=0” refers specifically to execution rejections/failures to be eliminated; normal SOP, risk, and spread rejections are valid controls. Do not remove filters to force the count to zero, or rename genuine broker rejects to conceal them.

### 6.1 New Module Interfaces and Behavioral Isolation

Manage each new module in three modes, `OFF / OBSERVE / ACTIVE`, configured separately for Scalping, Intraday, and Swing. If the original project already uses ASSIST/ENFORCE names, first map their actual permissions; reducing lot size, waiting, changing order type, or exiting early are all behavioral changes and must not be called “observation only.”

OBSERVE outputs evidence only and does not change SOP eligibility, direction, Zone/Setup lifecycle, risk reservation, orders, or positions. Under identical fixed test conditions, it should reconcile with OFF signal by signal and fill by fill; investigate code side effects, computation delay, or nondeterminism first if they differ, rather than immediately interpreting the difference as strategy improvement.

ACTIVE must list writable interfaces and every behavioral change in the experiment registration, applying the origin-based scope in §2.2. Preserve the user's current Scalping SOP's immediate execution and fixed SL/TP. Verify Intraday/Swing origin; confirmed NON_USER strategies may change registered core and management rules within project limits. Freeze each experiment's initial-risk definition and keep reference signal fields separate from candidate fields; modules must not overwrite “original SOP eligibility.”

The three engines operate as independent OR paths, not as mutual confirmation: one engine having no signal, unready data, or a local cooldown must not block another engine's independently valid Setup. Valid account-level risk, margin, or trading-safety limits may prevent new orders, but require an explicit reason; existing position management continues by the owning ticket.

## 7. Backtesting and Falsification Protocol

### 7.1 Data and Fair Controls

1. Inventory FxPro historical-data coverage starting from 2024-03, as known by the user; actual availability is determined by terminal download logs, and planned coverage must not be presented as already downloaded. Record server timezone and daylight saving time, symbol name, contract, gaps, Tick coverage, and terminal build.
2. Freeze each experiment's source, EX5, SET/INI, initial capital of USD500, leverage, costs, engine switches, start/end dates, and risk rules, explicitly identifying risk_profile_id, single-trade/portfolio caps, target lot-sizing rules, and RG/SZ mode. H0 uses the historical 1:100 for reproduction; later leverage changes must also be disclosed separately, and tier comparisons must not simultaneously change leverage or initial capital.
3. The historical period from 2026-05-01 to 08-26 and old Scalping validation segments have already been analyzed/used for parameter selection, and must not again be called untouched OOS for a new round. Preserve original labels in historical OOS fields and add the `REUSED_FOR_RESEARCH` status.
4. P0 inventories all previously viewed data ranges; only subsequent reserved segments that did not participate in selection may be used for final validation. If there is currently insufficient unused data, output `OOS_PENDING`. Walk Forward must freeze parameters after selection in each training window, then generate subsequent trades; merely slicing the same trade table must not be passed off as retraining.
5. Compile the actual source being delivered with MetaEditor, requiring 0 errors/0 warnings; MT5 must use `Every tick based on real ticks`. Also inspect generated-tick fallback where Ticks are missing; “100% history quality” must not be treated directly as proof that all Ticks are real. [Official MT5 Tick documentation](https://www.metatrader5.com/en/terminal/help/algotrading/tick_generation)

Each run must also fix warm-up, state initialization, and handling of positions across segment boundaries. An independent FULL run and restarted TRAIN/OOS runs produce different trade sets; do not require FULL to mechanically equal the sum of the two segments, or add overlapping reports to inflate the sample. Before reproduction experiments, complete the mapping between old SET/EX5 filenames in INI files and renamed delivery files, leaving the original files unchanged.

### 7.2 Validation Matrix

| Validation | Conditions |
|---|---|
| Strategy separation | Run S-only, I-only, W-only, and Combined separately; confirm the other engines' switches for each run |
| Costs/delay | Use actual spreads and commissions as the baseline; preregister spread +25%/+50%, additional adverse slippage, custom fixed 10/25/50ms delay, and native Random Delay as separate tests (see §11.6); list changes the native Tester cannot express separately as research simulations |
| Boundary correctness | Zero candle body/zero range, unready data, multiple signals in the same tick, broker minimum lot, partial fills, order timeout, restart, Stops/Freeze/TickSize |
| Parameter stability | Check neighboring values only on research/training segments, and do not use OOS results to select the optimum retrospectively |
| Direction and market conditions | Attribute results separately by BUY/SELL, trend/range/high volatility, and month; do not remove adverse periods |
| Sample and uncertainty | Counts of complete position trades and Setups; list partial-exit deals separately; estimate uncertainty using day/Setup blocks, and mark low-sample conclusions as unstable |
| Risk tiers | Main R13/R24/R36 reports and preregistered split-factor controls; first compare budgets under the same reference logic, then compare new methods at a fixed tier; run S/I/W/Combined separately at each tier, applying the same §11 thresholds |
| Dynamic risk and market data | Under §13, separately compare account states, trends/ranges, related markets, calendar/news, and emergency management; verify versions available at the time, recovery paths, data failure, restarts, cash flows, and account/engine scope |
| Promotion | Freeze acceptance criteria before the experiment; pass tests and clearly outperform the current benchmark at the same risk tier and under the same lot-sizing rules, then pass OOS/stress/portfolio/mandate checks; passing research does not automatically change the default deployment risk |

Before each experiment, register the maximum number of parameter combinations to be studied and the main variables; archive failures unchanged, and do not repeatedly inspect the same OOS to “tune until PASS.” Retain the original Champion when there is no clear advantage. Final Verdict uses the top-level enumeration: `REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER / NEW ENGINE CHAMPION / NEW 3-SOP COMBINED CHAMPION`. Record data, environment, or capital-feasibility blockers separately as `execution_status=BLOCKED_BY_DATA_OR_CAPITAL`; Final Verdict is then `RESEARCH FURTHER`, and no new promotion conclusion or fabricated PASS is allowed.

### 7.3 Single-Variable, Counterfactual, and Full-Account Controls for New Methods

Execute in the order “same-risk benchmark → clean up old extensions individually → OFF/OBSERVE consistency → single-module ACTIVE → a few preregistered combinations.” When enabling a new module for the first time, do not simultaneously change the lot-sizing algorithm, initial SL/TP, SOP trigger conditions, or exit rules. Provide separate controls for the effectiveness of new methods and the effectiveness of removing old restrictions.

Use stable `setup_id` values to record the outcome of the same opportunity across versions. Report originally profitable/losing opportunities that were filtered out, net amounts missed or saved, execution deviation, waiting time, MAE/MFE, and exit differences; do not use profit/loss labels known only afterward as entry features at the time.

Paired replay must use consistent initial risk, market data, costs, and original exit definitions, and must be labeled a “counterfactual estimate,” stating assumptions about price touches, fills, concurrency, and fees. Filtering or exit changes alter capital usage and subsequently executable trades, so per-trade differences cannot replace a rerun of the full account. Virtual Setups rejected by risk controls do not count toward the actual trading sample, and combined net profit cannot be calculated by directly adding three individual-strategy profits or counterfactual profits.

NR04 rolling scales, NR06 holding-time distributions, or any scoring thresholds may be estimated only from the current training window, then frozen for subsequent validation windows. Risk tiers and lot-sizing modes are also selection parameters, subject to §3.4/§3.7; do not use OOS to select the best risk tier and still call the test blind. Continue registering the usage status of old OOS data, all trial counts, and failed candidates under §7.1/§7.2; do not repeatedly reuse the same holdout segment to “tune until PASS.” Preserve missing states for undefined denominators, missing Ticks, or low samples, rather than fabricating high scores or high PF.

## 8. Deliverable Format for Each Round

Required deliverables: source diff and hash, SET/INI, actual compilation logs, raw MT5 reports, per-trade audit, signal funnel, incorrect-entry/missed-trade cases, comparison tables, OOS and stress evidence, and final conclusions.

| Version / Engine / Segment / RiskProfile / SizingMode | Net USD | Return % | Max Equity DD USD/% | PF | Complete trades | Win rate | Execution reject |
|---|---:|---:|---|---:|---:|---:|---:|
| New Candidate for this round | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED |

Supplement with Expected Payoff, actual average win/loss ratio, Recovery definition, costs, actual risk, peak margin, BUY/SELL differences, and changes relative to the benchmark. When there are no losses or no trades, use an appropriate undefined state for PF; do not insert a high value to pretend the test passed.

Apply §11 uniformly for full report fields, hard thresholds, diagnostic references, win-rate/win-loss-ratio formulas, drawdown and Recovery definitions, stress tests, and OOS requirements. Delivering only the one-row summary table above is not sufficient.

Subsequent chart reports must include equity and balance, drawdown, monthly returns, distributions by strategy and direction, and the signal funnel; use actual results only. This round delivers a plan, and no fictional equity curve has been generated.

### 8.1 Additional Deliverables for New Research

Add the following records to the original delivery requirements; filenames are suggestions and must first be adapted to the current directory and registry, without restructuring the entire project merely for naming.

| Deliverable | Required explanation |
|---|---|
| `SOP_LOCK` / `IMPLEMENTATION_DIFF` | Locked rules, actual implementation, historical parameter differences, basis for fixes, permitted extension points, and conflicts |
| `OPTIONAL_MODULE_INVENTORY` | Classification of old modules, reasons for retaining/disabling/replacing them, safety boundaries, and corresponding cleanup experiments |
| `BASELINE_MANIFEST` | Differences among H0/B0/K0/fixed benchmarks, source, SET, data, reference_id, risk_profile_id, and lot-sizing mode; H0 retains the old risk settings |
| `EXPERIMENT_REGISTER` | Hypothesis, source, owning SOP, permitted changes, parameter-combination budget, feature availability times, and frozen testing and acceptance rules |
| Signal and fill comparison CSV | Original SOP eligibility, module recommendations, statuses at each stage, distinction between actual fills and counterfactuals, duplicate counting, and risk rejections |
| Chinese research report | All metrics in original plan §8/§11, marginal effect of each module, effects of cleaning up old modules, missed profits, failure cases, and portfolio impacts |
| `SOP_CHANGE_PROPOSALS` | Necessary changes proposed for the user's own confirmed SOP, with problem, evidence, and concrete revision; handle under the user's explicit instructions for that SOP. Authorized NON_USER rule changes belong in their candidate registry and are not automatically limited to proposals |
| `RISK_PROFILE_MATRIX` / `RISK_FEASIBILITY` | R13/R24/R36 and split-factor controls, current contract evidence, minimum-lot risk for each Setup at USD500, costs, capital thresholds, and budget/margin rejections |
| `RISK_PROFILE_COMPARISON_CN.md` | Separate tables for within-tier method comparisons and cross-tier budget comparisons; separate RG/SZ, reasons for R13 constraints, additional profitable/losing opportunities, lot size and actual risk, DD/Recovery/consecutive losses/OOS/stress, and tier recommendations |
| `RISK_EVENT_AUDIT.csv` | For every trade and reservation: profile, current equity, single-trade/portfolio budgets, used/remaining/in-flight risk, target and actual lot size, rejection reason, overruns, server reconciliation, and configuration source |
| §13 dynamic-system deliverables | Input inventory, regime/related-market observations, news/calendar snapshots, dynamic policies, state transitions, cash-flow and emergency-action records; distinguish versions, hashes, and actual implementation/compilation/backtest status |

Record engineering checks, research differences, and final promotion separately. Complete data for an observation experiment does not mean the strategy has PASSED; reducing a large loss to a smaller loss may have research value, but cannot qualify for promotion without satisfying §11 requirements such as positive net profit. New statuses are diagnostic labels only; Final Verdict still uses the original §7.2 enumeration.

Risk comparisons must preserve at least the following blank table of main tiers, populated with actual values after testing; put split-factor controls in a separate table:

| Tier | Single-trade/portfolio cap | Valid Setups/actual complete trades | Single-trade/portfolio risk rejections | Net profit/PF | Maximum relative equity DD | Native/equity Recovery | OOS/stress | Status |
|---|---|---|---|---|---|---|---|---|
| R13 | 1% / 3% | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED |
| R24 | 2% / 4% | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED |
| R36 | 3% / 6% | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED | NOT_TESTED |

Every table must state engine, segment, reference, lot-sizing mode, fees, and the full run_id; do not add together different tiers or duplicate events.

## 9. First-Round Instructions for Windows Codex

> This round selects the legacy-version upgrade research route and adds tiered risk research. Read this complete plan, especially §2.2, §3.1–§3.7, §11, and §12; also read the current project's three SOPs, source review, top-level specification (including §29), latest mandate, and existing registry. First confirm the working directory, uncommitted changes, current commit, and official MT5 data directory. Do not overwrite the original version or force a rollback because of historical version numbers.
>
> Also carry out the research design added in §13: first inventory platform/data capabilities and observe NR02/NR07/NR08. Freeze DR01 base risk caps and policy for each round, while runtime risk reduces, pauses, and recovers according to its rules. Register account risk, market filters, and emergency exits separately. Do not treat news retrieval or AI analysis as validated functionality. Python is used only for MCP monitoring, and the user's current Scalping SOP continues to follow §2.2.
>
> Freeze the four V4.00 historical benchmarks and their evidence mappings, and complete P0's SOP_LOCK, strategy_origin and supporting evidence, per-tier risk feasibility, data-use inventory, and H0/B0 protocol. Register old supporting modules individually and establish the K0 cleanup control. Preserve the user's current Scalping SOP's fixed SL/TP and locked trigger timing; verify Intraday/Swing origin without assuming NON_USER. FxPro scope, USD500, the R13 default control, and every §11 acceptance threshold remain unchanged.
>
> Independently register P0-R tiers R13=1%/3%, R24=2%/4%, and R36=3%/6%; first compare budget gating under the same reference logic and identical target lot-sizing rules, then separately research actual lot-size management. Under §3.4, add at most the three split-factor controls D23/D33/D34, freezing the tier, lot-sizing mode, and other conditions for each run. Neither single-trade nor portfolio caps are targets that every trade must fully consume. When minimum lot size constrains R13, preserve CAPITAL_CONSTRAINT and continue other registered experiments; do not shorten stops, add capital, switch contracts, or temporarily switch tiers to force trades.
>
> Preserve same-tier B0/K0/fixed benchmarks at each tier, and run S-only, I-only, W-only, and Combined separately; report additional opportunities, risk rejections, actual lot sizes, net profit, DD, Recovery, net expectancy, 6/8 consecutive losses, and tail stress. Net profit at different risk levels cannot establish that a method wins, and tier selection must not peek at OOS. Label research configurations RESEARCH_ONLY, for Tester use only; do not overwrite deployment defaults or enable live trading.
>
> Apart from necessary P0 risk adaptations and independent P0-R experiments, the first strategy-side behavioral change retains original P1a priority: first reproduce the Scalping nearest-zone ranking issue in the current source, confirm that it is an implementation fix under the locked SOP, then register a single-variable Candidate, modify, compile, and test; if already fixed, provide regression evidence and proceed to P2. Do not add new scoring or change risk tiers while fixing zone selection; refreeze the relevant same-tier controls whenever the reference logic changes.
>
> Integrate NR01–NR06 into the original P0–P6 queue, starting with the corresponding read-only observations. Then apply §2.2: preserve the user's own confirmed SOP by default; within the authorized research task, autonomously propose, implement, test, and improve both core rules and supporting methods of confirmed NON_USER strategies, without new per-iteration approval. Ideas need not all originate from a Champion or GitHub. Freeze old and new rule versions for each comparison. Previously failed indicators may be repurposed with evidence, but old results must not be repackaged as new.
>
> ACTIVE scope comes from strategy origin and the registered candidate rules under §2.2. For a necessary change to the user's own SOP, state the problem, evidence, and specific proposal and follow the user's explicit instructions for that SOP; do not apply that limitation to confirmed NON_USER core-rule optimization. For each candidate, freeze the problem, hypothesis, permitted variables, trial budget, acceptance criteria, and rollback conditions in advance. Keep strategy logic and initial SL/TP fixed in risk-only experiments. Complete actual compilation, FxPro Real Tick testing, cost and delay stress, valid out-of-sample testing, individual-strategy audits, and actual portfolio audits in sequence, then decide from the evidence whether to retain, discard, or continue research.
>
> Record normal SOP/risk rejections separately from execution failures; when capital, data, or the Windows test environment is missing, register specific BLOCKED evidence and continue work independent of the blocker. Do not exceed registered tiers to force trades, count virtual fills toward the >100 threshold, repeatedly use old OOS as if it were a blind test, or overwrite the Champion. Do not relax DD/Recovery/sample or other thresholds for higher-risk tiers; permission for offline experiments in this round does not authorize an official higher-risk configuration. Without actual artifacts, do not write “compiled, backtested, or PASSED.”

## 10. Plan and Execution Status

### 10.1 Completed Items Recorded in the Original Plan (2026-09-06; Not Reverified This Time)

- [x] Verified the main GitHub repository, two reference repositories, and fixed commits.
- [x] Read the four teaching books and six screenshots, and listed key ambiguities.
- [x] Verified the identity of the V4.00 ZIP, MQ5, and EX5; read historical backtest evidence and key source-code paths.
- [x] Proposed a directly executable priority queue, independent variables, and acceptance criteria.
- [ ] New Windows MetaEditor compilation, new FxPro backtests, new OOS, and stress tests.
- [ ] New Candidate implementation and Champion promotion.

### 10.2 Integration Status for This Revision (2026-09-07)

- [x] Integrated “SOP unchanged; supporting methods may be autonomously proposed/modified/tested” into the legacy-version upgrade route.
- [x] Synchronized development boundaries, H0/B0/K0 controls, P0–P6 tasks, module permissions, and backtest and delivery requirements.
- [x] Preserved all §11 report thresholds, FxPro scope, USD500, the R13 default control, and historical parameter differences; synchronized consecutive-loss provisions to per-tier definitions.
- [x] Added R24/R36 research tiers, split-factor controls, minimum-lot feasibility, RG/SZ attribution, risk formulas, consecutive-loss stress, and research permissions.
- [x] Synchronized risk references in §2/§3/§5–§9/§11.3/§12, without turning research-tier authorization into a live-trading default.
- [x] Registered six new methods pending validation, the conflict-handling table, and first-round Codex execution instructions.
- [ ] Write this MD into the actual project, create a research branch, and update the project registry.
- [ ] Candidate code, risk configurations, per-Setup audits, actual backtests, and tier selection for R13/R24/R36 and split-factor controls.
- [ ] Current repository/SOP review, Candidate code modifications, MetaEditor compilation, MT5 backtests, and promotion.

## 11. Mandatory EA Trading Report Requirements (Added by the User in This Round)

Supplement date: 2026-09-06. The win-rate content repeatedly pasted by the user has been consolidated, distinguishing “project hard gates,” “suggested targets,” and “factual assertions requiring correction.” These are the reporting and promotion rules for a new round; do not rewrite old historical reports or rename old versions as having passed the new rules.

### 11.1 Core Metrics and Assessment

The following rules apply to the separate Scalping, Intraday, and Swing lines, and to Combined when actually run. Freeze the formal main test period before the experiment. Report OOS and each stress scenario in separate tables; do not substitute the best-looking period for the formal main table.

| Metric | Reporting Requirements | Assessment for This Project |
|---|---|---|
| Net Profit | Net profit in USD, initial capital, start and end dates, total return; report the annualization method separately when needed | `Return%=Net/InitialCapital×100`; net profit must be positive. Explain capital efficiency when returns are low; do not consider only the absolute amount |
| Profit Factor | Native PF, Gross Profit, Gross Loss, sample size, OOS, cost sensitivity | Use 1.3–1.8 as the user's diagnostic reference, with no upper limit of 1.8; PF≤1 indicates no positive-return edge; >2.5 or 3 triggers intensive review, without automatically classifying overfitting from PF alone |
| Max Equity DD | Maximum equity drawdown amount, the percentage corresponding to that amount drawdown, and the maximum relative equity drawdown percentage over the entire period | Apply thresholds to the maximum relative equity drawdown percentage over the entire period: ≤15% target; >15% and ≤30% requires strict manual review and cannot be automatically promoted; >30% is a hard rejection |
| Total Trades | Separately report native MT5 Trades, complete opened-and-closed trades, Setups, and Deals | Each line must have >100 complete trades (at least 101) in the frozen main test period; 200–500 is suggested, not an upper limit on trade count; insufficient samples prevent promotion |
| Recovery Factor | Native MT5 value and calculation reconciliation; additionally report Equity Recovery | Native MT5 Recovery must be >3.0; exactly 3.0 also fails the requirement; do not conceal equity risk by using only balance drawdown |
| Expected Payoff | Native value and net expectancy after costs calculated per complete trade, using consistent USD/complete-trade units | Must be significantly positive and cover real costs; a cost buffer of 3–5 times is a strong reference target, not a substitute for statistical significance |
| Win Rate | Profit Trades (% of total), average win, average loss, realized average win/loss ratio | No universal hard win-rate threshold; consider expectancy, direction, costs, and consecutive losses together |
| Forced-Liquidation Risk | Minimum margin level, Margin Call/Stop Out modes and thresholds, peak margin usage, abnormal floating losses | A triggered Stop Out, unexplained large floating losses, or reliance on holding losing positions until recovery prevents promotion; do not reach conclusions from line colors |

For example, an initial USD10,000 earning USD200 over one year does indeed yield a 2% return. Mark it `LOW_RETURN_REVIEW` and assess costs, drawdown, and comparable opportunity costs; do not claim it is necessarily “worse than a bank deposit” without checking the term, currency, and risk. No additional universal minimum annualized return has been set in this round.

More than 100 trades is a user acceptance requirement, not a guarantee of statistical stability. Do not pad the sample by adding overlapping TRAIN/FULL/OOS records, partial-closing Deals from the same Setup, or duplicate events from the same market conditions across brokers. If Swing has insufficient samples, extend the available evidence and retain `LOW_SAMPLE_SIZE`; do not lower the threshold or force trades. Disclose OOS samples and uncertainty separately; do not treat the main-period sample size as the OOS sample size.

### 11.2 Distinguish Equity Drawdown, Recovery, and Forced Liquidation

MT5's `STAT_EQUITY_DD` is the maximum equity drawdown in money; `STAT_EQUITYDD_PERCENT` is the percentage corresponding to that monetary drawdown; the maximum relative percentage over the entire period is `STAT_EQUITY_DDREL_PERCENT`. These three are not interchangeable. Use the last field for percentage risk thresholds. [Official statistical fields](https://www.mql5.com/en/docs/constants/environment_state/statistics)

Native MT5:

`MT5 Recovery = STAT_PROFIT / STAT_BALANCE_DD`

Additional calculation for this project:

`Equity Recovery = Net profit in USD over the same period / Maximum equity drawdown amount in USD`

Native Recovery>3 is a hard gate for this round. Also output Equity Recovery; if it is low, investigate floating losses and profit retention. No matter how high the native value is, it cannot override an equity DD rejection. When the denominator is 0, missing, or undefined, preserve the platform result as-is and explain why; do not insert 999 or infinity and automatically pass it. [Native Recovery definition](https://www.mql5.com/en/docs/constants/environment_state/statistics)

Balance reflects only settled account changes, while Equity also reflects unrealized profit and loss. Identify the two lines using the legend, fields, and values; do not hard-code “blue=Equity, green=Balance” from the user's original text. The official MT5 default Graph example is actually the reverse. Trace persistent or extreme adverse Balance-Equity divergence to orders, the duration of floating losses, and margin changes. [MT5 test chart and settings](https://www.metatrader5.com/en/terminal/help/algotrading/testing)

Margin Call warnings and Stop Out forced liquidations are different events. Read the thresholds according to the broker account's percentage/currency mode. In percentage mode, record `MarginLevel=Equity/Margin×100`; do not divide by 0 when no margin is in use. Diverging chart lines are an investigation clue; their shape alone cannot prove that forced liquidation has occurred. [Account margin properties](https://www.mql5.com/en/docs/constants/environment_state/accountinformation)

### 11.3 Win Rate, Expectancy, and Average Win/Loss Ratio

Calculate each complete trade's net return under the same rule, including commission, swap, and applicable fees. Let W be the proportion of winning trades and L the proportion of losing trades, with break-even trades listed separately; when break-even trades exist, W+L need not equal 1.

`Net Expectancy = W×AverageNetWin − L×abs(AverageNetLoss)`

`Realized Average R:R = AverageNetWin / abs(AverageNetLoss)`

In the simplified case with no break-even trades and ignoring additional costs: `BreakEvenWinRate=1/(1+R)`. If average wins and losses are already net of costs, do not deduct the same fees again; display the theoretical SL/TP ratio and realized average R:R separately.

| User-Provided Strategy Profile | Win-Rate Reference | Average Win:Average Loss Reference | Required Interpretation |
|---|---|---|---|
| Trend/breakout | 35%–45% | 2:1 or 3:1 and above | Examples only; do not call a strategy healthy from the range alone; 35% with 2R gives a pre-cost expectancy of only 0.05R |
| Range/scalping | 65%–80% | 1:1 or 0.8:1 | Costs, execution delay, and slippage compress small edges; test net expectancy |
| Grid/martingale | 85%–95%+ | Small-win/large-loss structures such as 1:5 or 1:10 | Used only to identify tail risk, not as candidate strategies for this EA; high win rate alone does not prove martingale use, nor justify claiming that every such strategy must blow up within one day |

These ranges are user-provided diagnostic examples, not official MT5 statistical distributions, promises of future win rates, or Pass/Fail gates applicable to all strategies. Increasing stakes after losses, hidden grids, removing SL, and similar behavior remain subject to the project's existing prohibitions.

Reports must include `Average profit trade`, `Average loss trade`, `Long Positions (won %)`, `Short Positions (won %)`, and each side's trade count, net profit, PF, expectancy, and realized R:R. If BUY is 80% and SELL is 20%, first check the samples, market conditions, and costs on both sides; the win-rate difference alone cannot establish a lack of short-selling ability or justify immediately disabling SELL. [MT5 report fields](https://www.metatrader5.com/en/terminal/help/algotrading/testing_report)

For consecutive losses, separately list the “longest losing streak in trades,” “total loss of that streak,” and “largest consecutive loss amount and its trade count”; do not confuse them. Test at least 6 losses, 8 losses, the longest historical losing streak, and more adverse scenarios. R13 retains 1% per trade/3% portfolio; the added R24/R36 and split controls use their own frozen budgets and actual equity paths, with profile definitions in §3.2–§3.6. A historical 60% win rate does not exclude consecutive losses; the probability of one specific independent sequence of 8 losses is also not the probability of an 8-loss streak occurring anywhere in the entire backtest. Stress analysis must consider correlated same-direction positions and slippage.

### 11.4 Consistent Units for Expected Payoff and Costs

Preserve both native `Expected Payoff` and `Total net trade return/Number of complete trades`. If they differ, reconcile trade/Deal aggregation and fee allocation; do not select the better value.

- Spread in points, gold price differences in dollars, and USD/trade cannot be compared directly. Use each trade's volume, tick size/value, and entry/exit quotes to convert the spread, round-trip commission, swap, and additional adverse slippage into USD/complete trade.
- Actual Bid/Ask execution already incorporates the spread's effect, and fees already deducted by the platform must not be deducted a second time; separately list “already included” and “additional stress costs.”
- Report `NetEdgeToCostRatio=Average net return after costs/Average estimated cost of the corresponding complete trades`. If costs are 0 or unknown, mark it undefined rather than reporting infinity. Use 3–5 times as the user's suggested cost-buffer target and specify the cost definition it uses.
- “Significantly greater than 0” cannot be asserted subjectively. Output sample size, interval estimates, and the calculation method. When using day/Setup block estimation, retain the correlation assumptions; mark low samples or an interval crossing 0 as `EDGE_UNCERTAIN` and continue research. If the lower confidence bound is to become an automatic gate, freeze the threshold before the experiment; do not change it after viewing OOS.

### 11.5 High-PF Review

Remove the probability assertion that “PF>2.5/3 means a 90% probability of overfitting”: the user's material provides no supporting statistical basis, and the official report definition does not supply such a probability. Retain the original intent that high PF warrants careful inspection.

When PF>2.5 or 3, register `HIGH_PF_REVIEW` and check whether the sample is extremely small, a few winners dominate, future bars/backfilled pivots are used, the number of parameter-selection attempts, costs are missing, buy/sell direction concentration, parameter neighborhoods, and repeated use of old OOS data. Reject on evidence when actual look-ahead/data leakage or false costs are found; high PF alone is not proof of wrongdoing. PF1.3–1.8 likewise cannot automatically pass.

### 11.6 MT5 Stress Tests: Real Ticks, Delay, and Slippage

Formal evidence must use `Every tick based on real ticks`; the correct name of the coarse mode is `1 minute OHLC`, not OHLV. OHLC/open-price modes are only for development checks. Even real-tick mode requires checks for historical gaps and fallback to generated ticks. [MT5 real and generated ticks](https://www.metatrader5.com/en/terminal/help/algotrading/tick_generation)

Register delay tests separately:

| Scenario | Actual Setting | Purpose |
|---|---|---|
| Zero delay | No Delay | Baseline/idealized diagnosis only; cannot be the sole qualifying evidence |
| Multiple low-delay scenarios | Custom Fixed Delay: 10, 25, 50ms; record actual support and saved values in the current build | Retains the user's 10–50ms range of interest; not random mode |
| Measured delay | Value measured on the current connection and more adverse fixed values, registered before testing | Matches the actual execution environment; 10–50ms cannot be assumed to represent the user's VPS |
| Native random | MT5 Random Delay: 90% at 0–8 seconds, 10% at 9–18 seconds | A separate, heavier stress scenario; must not be labeled as random 10–50ms |
| Custom random 10–50ms | Use only when genuinely implemented in a controlled simulator with its seed/distribution recorded | List separately as research simulation; do not claim it is a native MT5 option or promote based on it alone |

The official delay affects requests sent by the EA; triggering pending orders already on the server does not add the same network delay. Therefore, do not claim that enabling Delay fully simulates pending-order execution slippage. Separately reconcile slippage using requested versus executed prices, adverse quote stress, execution type, and liquidity assumptions; the allowed-deviation parameter is also not a switch guaranteed to produce fixed slippage. [MT5 Execution settings](https://www.metatrader5.com/en/terminal/help/algotrading/testing)

For every scenario, report each line's net profit, PF, maximum relative equity DD, Trades, execution rejections, execution-slippage distribution, actual risk, and changes from the baseline scenario. Lock acceptance criteria before the experiment; do not select passing scenarios and hide failing ones.

### 11.7 Out-of-Sample Validation

Training and OOS must not overlap in time. This example uses half-open intervals: TRAIN `[2020-01-01, 2025-01-01)`, OOS `[2025-01-01, 2026-01-01)`; it only illustrates boundaries and does not mean this project already has FxPro data for these years. Do not include all of 2025 in both periods.

Select and freeze source code, parameters, thresholds, and costs in TRAIN before opening OOS. Warm-up provides only history known at that time; future prices must not influence signals. Handle orders crossing the boundary consistently on both sides. If parameter selection continues after viewing OOS, that period becomes data already used in research, and a new unused validation period is required. Continue to handle the status of the existing old 2026 OOS according to §7.1. [MT5 Forward mechanism](https://www.metatrader5.com/en/terminal/help/algotrading/strategy_optimization)

OOS profitability adds supporting evidence; it does not prove stable predictive ability. Samples, drawdown, costs, parameter stability, market states, and portfolio effects still need assessment.

### 11.8 Final Delivery Checklist

- [ ] 4 separate result lines; comparisons use the same capital, risk, dates, contracts, costs, warm-up, and execution conditions.
- [ ] Net USD and Return%, native PF/Gross Profit/Gross Loss, three equity DD fields, with balance DD as supplementary information.
- [ ] Each line has >100 complete trades in the main period, with 200–500 suggested; list OOS/stress-scenario samples separately, without double counting.
- [ ] Native Recovery>3; list Equity Recovery separately, specifying denominators and any undefined values.
- [ ] Expected Payoff after costs, cost in USD/trade, cost-buffer ratio, and estimation uncertainty.
- [ ] Overall win rate, BUY/SELL, average wins/losses, realized R:R, break-even trades, longest losing streak, and pressure on capital.
- [ ] Check Equity/Balance against the legend; audit minimum Margin Level, Margin Call/Stop Out, floating losses, and margin.
- [ ] Real-tick coverage, actual fixed delay, native random delay, and additional slippage stress, with complete results for every scenario.
- [ ] Untouched, non-overlapping OOS, fixed parameters, and no future-data or result-selection leakage.
- [ ] After passing tests, the candidate must still beat the same-risk Champion; insufficient samples/missing data receive `RESEARCH FURTHER` with the blocker explained, and failures of hard rules prevent promotion.

This addition updates only the reporting standards and plan. No new backtest was run, and no new PASS or Champion was produced.

## 12. Research Modules for New Supporting Methods (Integrated into the Legacy-Version Upgrade Route, 2026-09-07)

### 12.1 Research Positioning

This section integrates the research ideas from the previous addendum. All proposals are currently hypotheses awaiting validation, not strategies proven to improve win rate, net profit, or trade count. For the user's own confirmed SOP, these methods provide evidence or permitted supporting behavior. For a confirmed NON_USER strategy, §2.2 also permits autonomous core-rule changes within the authorized research task; each candidate generates Setups under its own registered and frozen rule version.

Retain the legacy version/Champion for history and same-risk comparison; do not copy its supporting logic and present it as new research. Necessary architecture, correctly implemented SOP functions, risk calculations, and server reconciliation may be reused; do not rewrite already-correct shared code merely to pursue something “entirely new.”

Do not permanently prohibit methods such as EMA, Stochastic, MACD, ATR, or VWAP. A new use must specify the research question, where it operates, its difference from old experiments, and falsification conditions. Do not remove the user's confirmed SOP definitions in the name of “new research” or silently stack auxiliary indicators into mandatory conditions. A confirmed NON_USER strategy may test new or revised directional and qualification signals under §2.2; preserve the reference, register the changed rules, and attribute resulting orders to the candidate rather than claiming they met the unchanged reference SOP.

### 12.2 Mapping the Six Methods to the Original Task Queue

The NR numbers below are research topics in this plan only, not registered Candidate versions. Before implementation, read the registry and allocate separate IDs within the existing S-/I-/W-/C-ID scheme. The no-core-change limits in these supporting-method examples apply to the user's locked SOP and experiments that expressly freeze those rules. They do not remove §2.2 authority to register separate core-rule experiments for confirmed NON_USER strategies; references excluding Scalping mean the user's current Scalping SOP.

| Research Topic | Integration into Original Tasks | Main Applicable Engine | What to Record Only in the First Round | ACTIVE Boundaries and Questions Awaiting Validation |
|---|---|---|---|---|
| NR01 Quality of the path into the zone | P3; integrate Scalping after the P1/P2 audit | Intraday, Scalping | Speed of the move before reaching the zone, acceleration/deceleration, directional efficiency, and extent of retracement | Do not change zone or first-touch definitions; test supporting quality selection at authorized extension points, checking whether reduced losses come at the cost of missing too many winners |
| NR02 Market-regime stratification | P0-M/P3; extension in §13.2 | Record independently for each engine | Upward/downward trends, ranges, and transitions; record volatility states separately | OBSERVE does not change orders; register ACTIVE risk adjustments and strategy filters separately, protect the user's SOP, and do not require agreement across all timeframes by default |
| NR03 Internal quality of the reversal bar | P5, combined with the original trigger timeline from P2 | Scalping | Directional movement, movement retained at the close, and repeated retracement within the original qualified reversal bar | Do not add a required pattern or wait for an extra bar; study only quality differences known at the original confirmation time |
| NR04 Relative scale within comparable conditions | P5, after freezing the NR01/NR02/NR03 definitions | Scalping, Intraday | Percentiles or robust standardized values of supporting features relative to comparable past periods | Compare against a fixed-scale version; do not change SOP zone width, SL/TP, or core thresholds, and do not enable alongside multiple new modules |
| NR05 Execution and missed-trade audit | P0/P2/P6, throughout all experiments | All three engines | Timeline of original qualification, gates, risk reservation, order submission, responses, and execution | First substantiate issues such as software delays, erroneous locks, or duplicate states, then fix them independently; do not remove necessary risk and execution protections |
| NR06 Profit giveback protection | P4, first inspect the Swing signal funnel | Swing; register a separate candidate for Intraday | Actual MFE/MAE, original exits, profit retention, and holding time | At permitted management extension points, test either structure-based protection or floating-profit-condition protection; initial SOP/risk remain unchanged; not applicable to Scalping |

### 12.3 Method Definitions and Prohibition of Look-Ahead

**NR01: First study how price reaches the zone, rather than selecting direction again.** Fix the observation window, sampling frequency, and quotes used before the experiment. Separately record net movement, cumulative absolute movement, changes in movement speed, and reverse retracement before the decision. The full path after reaching the zone must not be backfilled into “pre-zone quality”; multiple Ticks within the same First Touch episode update evidence only and must not repeatedly create new Setups. Directional efficiency `abs(p_end-p_start)/sum(abs(delta_p))` may be used as a candidate expression; if the denominator is 0, mark missing or no movement rather than assigning a high score. First separately calculate net results for “accelerating into the zone” and “decelerating into the zone,” without presuming the latter is a good opportunity.

**NR02: Market regimes first provide explanatory evidence and do not independently generate orders.** Extend the unified trend/range system under §13.2, researching path efficiency, effective direction changes, the share of total movement contributed by a single move, and relative volatility. Register separate ACTIVE candidates when states feed DR01 or strategy filters. Freeze windows, time units, state transitions, and missing-data rules. Preserve compatibility with the original `REGIME_UNCERTAIN`, mapping it to UNKNOWN or an explicitly defined transition state. Examine complete samples first; do not retrospectively remove unfavorable months or directions based on validation results.

**NR03: Data ends at the original SOP confirmation time.** Register the OHLC version and real-tick-path version separately; do not call an internal path inferred only from OHLC real-tick evidence. For the Tick version, specify which Bid/Ask series or predefined quote midpoint is used and retain availability checks. The count of upward quotes is not aggressive buying, and the count of downward quotes is not actual seller-initiated trading volume; do not label proxy features as proven order-flow absorption. If the historical path is incomplete, record `DATA_NOT_READY` rather than synthesizing a “momentum exhaustion” conclusion.

**NR04: Relative scale replaces only the representation of supporting features.** Fix historical comparison windows, server-time-zone and daylight-saving mappings, warm-up, and minimum sample size; rolling statistics use only information preceding that time. If the baseline is insufficient, the scale denominator is 0, or market conditions fall outside coverage, record missing data and follow the preregistered handling rule. Do not assign high scores ad hoc or permit trades merely to increase the count. Keep all other parameters and behavior consistent in fixed-scale versus relative-scale comparisons, avoiding mixing new normalization and a new filter into one experiment.

**NR05: Audit the process chain before deciding what needs to change.** For each independent Setup, record the actual sequence and results of original SOP qualification, optional evidence, Risk, Portfolio, and Execution. Follow the actual code mapping; do not rearrange the architecture for the logs. If order status is unknown after a timeout, first reconcile server state; explicitly handle rejection, partial fill, full fill, and lack of SOP qualification separately. Scalping may fix demonstrable unnecessary software delays, but must not wait for a better price in violation of locked timing; do not force replacement trades for expired/invalid signals. First check definitions and timelines for old labels such as `WRONG_TREND`, `LATE_ENTRY`, and `SL_TOO_TIGHT`; do not directly treat them as causal conclusions or filter conditions.

**NR06: Experiment with protection rules separately, without assuming “earlier break-even is better.”** First audit why signals are scarce, risk constraints, and original position management, then separately register “protection after structural improvement” and “protection after reaching a floating-profit condition.” Do not add trailing, partial exits, and time exits all together on the first attempt. Freeze the initial R definition; SL may only tighten, and partial-closing volume must satisfy minimum lot size and volume step. Reaching a floating-profit threshold does not mean execution is possible at that price; record actual triggers, requests, executions, and costs. Separately report reduced profit giveback, large winners cut short, average net R, and maximum equity drawdown. A confirmed NON_USER strategy may autonomously register a time-decay exit experiment under §2.2; for the user's own SOP, a conflicting exit remains a specific SOP change proposal handled under the user's instructions for that SOP.

Register `available_at` for every feature and verify that it is no later than the corresponding decision time. Retrospective fields such as MAE/MFE and the original trade's final result may be used only for audits and training labels, not as inputs available at the time. Data outside the current training set must not influence window, threshold, or model selection. General formulas and rule-based scores do not equal actual win rates or success probabilities.

### 12.4 Module Modes and Gradual Activation

| Mode | What Is Allowed | What Is Not Allowed |
|---|---|---|
| OFF | Maintain the original control behavior corresponding to the experiment | No hidden score gates or residual state effects |
| OBSERVE | Calculate, display, and write separate logs; record missing data | Do not change original SOP qualification, direction, trigger time, lot size, SL/TP, exits, or Zone consumption |
| ACTIVE | Execute the registered candidate behavior permitted under §2.2, including declared NON_USER core-rule changes | Do not bypass the user's locked SOP, the candidate's frozen rules, safety gates, or the current risk profile; R13 is the default, higher-risk research requires separate registration, and behavior changes must not be disguised as observation |

Under the same test conditions, first perform paired OFF/OBSERVE checks of original qualification, Setup count, planned entries, orders, executions, and exits. If observation mode causes differences, first fix them or fully identify their cause; do not enter ACTIVE with unknown side effects.

Enable only one main variable in the first ACTIVE test. Register filtering, risk reduction, exit changes, and valid execution paths separately. Each engine must have independent switches and parameters; a successful Intraday test does not automatically enable the feature for Scalping/Swing. Retain every original qualified Setup affected by filtering in the opportunity audit table; do not hide low trade counts by changing log definitions.

### 12.5 Actual Execution Sequence Within the Old Plan

1. **P0 first:** Check the current workspace, strategy origins and their evidence, SOP_LOCK, parameter version, historical evidence, and data-use status. First check R13, then, under P0-R, register R24/R36 and split controls for USD500 feasibility and budget experiments. A constrained profile does not have to be tuned to PASS first. Document H0/B0/K0 provenance relationships, each profile's reference, and the scope of old-module cleanup before proceeding; do not blindly disable all indicators.
2. **Retain the original P1/P2 priority:** Reproduce and fix selection of the nearest valid zone, occupancy by old zones, and First Touch state according to the original plan; NR05 collects process-chain evidence in parallel. Freeze a traceable reference after fixing each issue; do not mix several changes into the first candidate.
3. **Add read-only evidence:** Integrate NR01/NR02 into Intraday observation and NR03 into Scalping observation; add NR04 to observation after the underlying features are clearly defined. Observation modules may record in the same batch, but must pass regression checks confirming no behavior change; this does not mean enabling multiple controllers at once.
4. **Activate candidates separately:** Based on verifiable differences in the training period, test one registered variable at a time under §2.2, including core-rule experiments for confirmed NON_USER strategies where appropriate. NR03 for the user's current Scalping SOP preserves original confirmation/immediate execution. Retain frozen reference and candidate controls, with OFF/OBSERVE checks for applicable supporting modules; do not add ad hoc thresholds to “rescue results.”
5. **Independent position-management research:** Verify origin and management scope under §2.2. For Swing, first establish valid Setups, risk blocks, and sample size, then research NR06; register Intraday management independently under P4. The user's current Scalping SOP does not enter break-even/trailing/partial-exit/runner research; that exclusion does not extend to other confirmed NON_USER scalping strategies.
6. **Combination and promotion:** Register a small number of two-module combinations only after individual modules have supporting evidence; then rerun S-only, I-only, W-only, and actual Combined. Apply §7 and §11 throughout; do not use a combination to conceal a failing individual line.

The first batch of the plan specifies only research topics and sequence, without prefilling optimal parameters, expected win rates, or daily order counts. When samples are low, capital is constrained, or data is blocked, retain the reason and continue feasible work; do not lower thresholds or claim the module has already proved effective.

### 12.6 Registry Card for Each Candidate

The following describes required fields, not completed experimental results. Fill formal values using the source code, configuration, environment, and artifacts from execution.

| Field | Required Content |
|---|---|
| Identity | `experiment_id`, actual Candidate ID, `reference_id`, engine, branch/commit, source-code and SET/INI hashes |
| Origin | `strategy_origin` = USER_OWNED / NON_USER / UNKNOWN, supporting origin evidence, and `idea_origin`; identify the user's confirmed SOP when applicable, and list source paths and license checks when reusing code |
| Problem and falsification | Actual cases, the hypothesis to validate, and results that would refute it; do not replace advance judgment with retrospective explanations |
| Permitted changes | Read/write interfaces, §2.2 scope, user-locked rules where applicable, module mode, and frozen reference/candidate rule versions; record `strategy_rules_changed` and `user_sop_changed` truthfully with the specific differences. A NON_USER candidate may have `strategy_rules_changed=true` and `user_sop_changed=false`; do not force all candidates to claim `sop_changed=false`. |
| Feature timing | Window, time units, quote source, `available_at`, missing-data/zero-denominator handling, and training/update rules |
| Experiment budget | Main variable, parameter ranges, maximum number of combinations, development/validation periods, and prior data-use status |
| Comparison basis | FxPro, USD500, risk engine, risk_profile_id, per-trade/portfolio caps, RG/SZ and target-volume rules, contract, warm-up, costs, execution delay, switches, and complete-trade/Setup aggregation |
| Acceptance and rollback | Engineering consistency, differences in signals/returns/costs, §11 hard gates, and out-of-sample/stress requirements; do not relax them after freezing based on observed results |
| Result evidence | Actual compilation logs, native MT5 reports, complete execution and signal CSVs, boundaries of counterfactual estimates, Chinese report, and original Final Verdict enum |

Report “how many losing opportunities were avoided and how many winning opportunities were missed,” rather than only the win rate of filtered orders. If a new method improves PF but has insufficient trade samples, nonpositive net profit, or risk above limits, research improvement cannot substitute for promotion. An observation module without behavior changes has no profit-improvement result of its own.

### 12.7 Applicability Differences from the Previous Addendum

The differences below are explicitly registered to prevent an executor from reading both files and mixing their rules. The user's 2026-09-12 clarification limits the blanket “SOP unchanged” interpretation to the user's own confirmed SOP; confirmed NON_USER strategies may undergo autonomous core and supporting-method optimization under §2.2. Other project constraints remain unchanged.

| Addendum or Old Proposal | Treatment in This Integrated Version | Reason/Applicable Section |
|---|---|---|
| B0=legacy version, B1=pure SOP | Retain H0=historical and B0=same-risk from the original plan; add K0=supporting-module cleanup | Avoid changing the meaning of identically named baselines; §3.1 |
| Every SOP is locked and all scalping strategies share the current Scalping restrictions | Protect the user's own confirmed SOP; confirm origin and autonomously optimize NON_USER strategies within authorized research | User clarification on 2026-09-12; §2.2. Do not assume Intraday/Swing origin or turn this into new per-iteration approval |
| Start with both FxPro and Tradona | Continue to start with FxPro only, without expanding the task to dual-broker validation | Scope in the uploaded main plan §2/§2.1 takes priority; historical Tradona information remains only an original record |
| Directly adopt SL50/TP50 and SL120/TP240 as current fixed values | Retain the original SOP and historical differences of SC-S20 80/70 and IN-I32 120/70; do not silently substitute values | §4 requires actual SET/unit checks; NON_USER SL/TP research is separately registered under §2.2, and risk-only comparisons keep initial SL/TP fixed |
| All research uses a fixed 0.01 lot | RG may use the same minimum valid lot size, still subject to that profile's risk/margin gates; SZ is a separate group, and virtual-R research is separately labeled counterfactual | §3 capital feasibility; do not fabricate executions or confuse volume increases |
| 1%/3% is the only risk allowed for experiments | The user has now added R24=2%/4%, R36=3%/6%, and split controls; R13 remains the default | §3.2–§3.7; offline research only, with no ad hoc profile switching, expanded SOP permissions, or automatic changes to formal configurations |
| v3.20 issues determine all current priorities | Do not assume the current version is still v3.20; retain this plan's P0→P1/P2 main sequence and advance new modules according to current evidence | The main file already contains V4.00 audit records; historical clues do not replace current verification |
| Unconditional confirmation waits, pullback routing, and early exits | For the user's own SOP, record conflicts as specific SOP_CHANGE_PROPOSAL items and follow the user's instructions; for confirmed NON_USER strategies, autonomously register and test changed candidate rules | Origin-based scope; §2.2/§4/§12.4 |
| New final verdicts such as KEEP_RESEARCH / MORE_TESTING | Do not replace the original Final Verdict enum; use only as research tags or explanations | Retain the §7.2 and §11 gates as written |
| Treat a legacy version or a file named Champion as qualified | Retain historical identity, with current applicability status REVALIDATION_REQUIRED; baselines lacking evidence await validation | §2; do not promote based on a name or rewrite old history |
| Time exits as default profit protection | Test separately under §2.2; NON_USER strategies may autonomously research them, while a conflict with the user's own SOP is handled as a specific proposal | Verify Intraday/Swing origin; the explicit Scalping exclusion applies to the user's current SOP, not all scalping strategies |

### 12.8 Summary and Sources of This File Revision

**Added and synchronized:** The selected legacy-version upgrade route, SOP lock/extension permissions, K0 supporting-module cleanup control, NR01–NR06 research topics, module modes, counterfactual and full-account comparisons, and candidate registry card; this round additionally includes R13/R24/R36 risk profiles, split controls, minimum-lot feasibility, RG/SZ groups, risk formulas for each profile, losing-streak stress, research permissions, and synchronized first-round Codex instructions.

**Retained:** The original P0–P6 main queue (with separate P0-R added), historical SC-S20/IN-I32/SW-W37/C-C01 identities, differences between actual SET and SOP parameters, FxPro scope, USD500, the R13 default of per-trade≤1%/portfolio≤3%, independent OR logic for the three strategies, fixed Scalping SL/TP and prohibited position-management functions, real-tick/OOS/stress discipline, and the full §11 reporting gates. In §11, only the profile-specific risk basis in the consecutive-loss clause has been synchronized; the remaining text is retained.

**Not executed:** GitHub writes, a fresh audit of current source code, EA changes, Candidate registration, MetaEditor compilation, MT5 backtests, OOS, or any Champion promotion. Pending tasks in this file are a plan for Windows Codex to execute, not work completed in this round.

Direct file sources for this merge:

- `EA_RESEARCH_DEVELOPMENT_PLAN_2026-09-07_CN_MERGED.md`: the direct editing base for this round; retains the complete legacy-version upgrade and new-method research content.
- `EA_RESEARCH_DEVELOPMENT_PLAN_2026-09-06_CN(1).md`: the original main file, providing the existing architecture, scope, original risk, parameter differences, queue, and acceptance rules. Risk-experiment permissions are explicitly updated according to the user's new requirements in this round.
- `GSM_Upgrade_Research_Addendum_CN.md`: source of the new supporting-research requirements; conflicts with the main file are explicitly handled in §12.7 rather than applied as a blanket overwrite.
- The user's explicit request: add the new research requirements to the selected legacy-version upgrade plan, keep the SOP unchanged, and allow suggestions, candidate modifications, and testing. This round further requests adding the previously discussed 1%/3% control and 2%/4% and 3%/6% risk research, then delivering the complete MD again. The risk profiles and mathematical examples are new content in this plan, not retroactively written as old-repository or historical-test conclusions.

Official-documentation links and project-file indexes from the original plan are retained as original references. No additional external fact verification was performed this round, and repository files, teaching materials, or old reports not included in this upload are not described as having been reread.

**Final execution principle: Continue upgrading within the old project. Preserve the user's own confirmed SOP by default and handle necessary changes under the user's explicit instructions for that SOP. Within an authorized research task, autonomously optimize both core rules and supporting methods of confirmed NON_USER strategies under §2.2. R13 remains the default, and R24/R36 remain separate risk experiments with fixed reference logic and initial SL/TP. First reproduce the problem and register the hypothesis, then modify the candidate and compare frozen old/new rules under the same risk and volume conditions. Judge risk tradeoffs by executable opportunities and drawdown cost; do not present larger positions as a strategy edge or automatically enable live trading based on a backtest. Saving this scope clarification does not start development or backtesting.**

## 13. Dynamic Risk, Market Regimes, Related Markets, and the News/Calendar System (Added 2026-09-12)

The user explicitly requested active risk adjustment in the research, together with trend/range identification, analysis of markets related to gold/USD, and news and economic-calendar scanning and analysis. The following research design is now included in the plan. General platform capabilities have been checked against official documentation; the symbols, build, data sources, and interfaces available in the user's terminal still require direct verification. All new modules have status `PLANNED / NOT_IMPLEMENTED / NOT_TESTED`. This does not mean an EA has been completed, data sources have been connected, or live trading has been enabled.

### 13.1 Module Responsibilities and Scope of This Addition

| Module | Responsibility | Outputs and boundaries |
|---|---|---|
| NR02 Market-regime scanning (extension of the existing module) | Distinguish upward/downward trends, ranges, transitions, and volatility states | Explainable states, evidence, and data quality; share definitions with the existing NR02 rather than creating a duplicate system |
| NR07 Gold/USD related-market analysis (new research topic) | Scan dollar, interest-rate, precious-metal, and other related inputs available through the platform | Changes in each input, correlation stability, conflicts, and missing data; correlations are not fixed directional commands |
| NR08 News and economic-calendar analysis (new research topic) | Identify scheduled events, release status, related news, and data validity periods | Event stages, sources, impact hypotheses, protection windows, and recovery conditions |
| DR01 Dynamic risk control (new research topic) | Combine account risk with market evidence registered for this candidate to reduce, pause, and gradually restore new risk; verify data and interfaces first, then validate effectiveness through EA candidate tests | State, multiplier, actual budget, actions, recovery evidence, and audit records |

These identifiers denote plan topics and do not replace formal Candidate IDs. Scanning and analysis are separate from trade execution: `Market/account data → State and event evidence → DR01 → Risk/Portfolio → Execution → Audit`; the original engines continue to produce traceable strategy Setups. The core rules of the user's current Scalping SOP remain protected under §2.2. New risk gates may reduce volume or pause additional risk in registered candidates; original qualifying Setups that are blocked must be recorded and must not be relabeled as “failing the SOP.” Changes to that SOP's direction, confirmation, SL/TP, or existing-position exit rules still require a separate statement of necessity, evidence, and the proposed approach, and must follow the user's explicit instructions for that SOP. NON_USER strategies may be optimized autonomously under §2.2.

The trading core and risk controls execute locally in MQL5. The AI Agent handles research, explanation, candidate development, and validation. Python is used only for this project's MCP monitoring, alerts, and log analysis; it must not become a required online dependency for order placement, stop-loss management, calendar protection, or risk recovery. An MCP disconnection must not stop the EA from managing existing positions. When the platform or EA stops, local scanning must not be represented as still running; accepted server orders are handled under the broker's rules.

### 13.2 Trend/Range Scanning System

Define structural states as `TREND_UP / TREND_DOWN / RANGE / TRANSITION / UNKNOWN`, and record volatility separately as `LOW / NORMAL / HIGH / SHOCK / UNKNOWN`. An upward trend may coexist with high volatility; high volatility is not synonymous with a range. Output states for the timeframes actually used by each strategy, record disagreements across timeframes, and do not add a default requirement that all timeframes must agree before entry.

Candidate evidence includes confirmed price structure, directional efficiency, moving-average slope, ADX and DI, and relative levels of ATR or Bollinger-band width. Reuse validated indicator interfaces where possible. ADX supplies evidence of trend strength; direction requires DI or price structure. ATR measures the magnitude of volatility and does not independently identify long/short direction. Begin with a small number of complementary combinations. Register windows, scales, switching thresholds, and minimum durations in the training segment; do not prefill supposedly universal optimal values. [MT5 ADX](https://www.metatrader5.com/en/terminal/help/indicators/trend_indicators/admi), [MT5 ATR](https://www.metatrader5.com/en/terminal/help/indicators/oscillators/atr)

Use closed bars by default. If a pivot requires confirmation from bars to its right, its availability time is the time that confirmation occurs. For each timeframe and symbol, check bar completion, the number of bars returned by `CopyRates`, series synchronization, `BarsCalculated`, and data age. Do not backfill incomplete higher-timeframe bars or count repeated stale quotes as fresh samples. Output UNKNOWN when data are insufficient or evidence conflicts. Define what a state-confidence measure calculates; do not present it as a trade win probability. [CopyRates](https://www.mql5.com/en/docs/series/copyrates), [BarsCalculated](https://www.mql5.com/en/docs/series/barscalculated)

Start with OBSERVE and summarize the original strategy's opportunities, net profit, costs, and drawdown by state. Then test separate candidates for “reducing new risk based only on state” and “filtering by state within the strategy's permitted scope.” Do not manufacture improvements by retrospectively excluding unfavorable months or states. Save `decision_time / symbol / timeframe / feature_cutoff / regime / volatility_state / evidence / data_status / state_since / config_hash` with every state output.

### 13.3 Gold/USD Related-Market Scanning

First create `MARKET_INPUT_INVENTORY`. Read the symbols available from the trading server and verify their descriptions, actual underlyings, quote currencies, contracts, suffixes, trading sessions, and historical coverage before selecting inputs. MetaQuotes platform capabilities do not mean the broker supplies every market to this account; matching names alone is insufficient. [SymbolsTotal](https://www.mql5.com/en/docs/marketinformation/symbolstotal)

| Candidate input | Purpose and verification requirements |
|---|---|
| The actual GOLD/XAUUSD symbol | Main-market prices, spreads, volatility, and quote activity; describe tick volume only as an activity proxy for that quote stream |
| Dollar-index products such as DXY/USDX | Observe dollar-basket strength; distinguish indices, futures, and broker CFDs, and verify product definitions and contract rolls. Do not assume symbol names or data availability. ICE's dollar index is a currency-basket product. [ICE description](https://www.ice.com/products/194/US-Dollar-Index-Futures) |
| Dollar currency pairs such as EURUSD and USDJPY | Use as separate proxy inputs and identify whether USD is the base or quote currency. They are also affected by the other currency and cannot directly stand in for DXY. Register components, weights, and formulas separately for any synthetic index |
| US Treasury nominal/real yields | Candidates include 2-year/10-year nominal yields and the 10-year TIPS yield; verify available sources first. FRED DGS10 and DFII10 are daily series and cannot be treated as real-time minute data. Record publication times and versions. [DGS10](https://fred.stlouisfed.org/series/DGS10), [DFII10](https://fred.stlouisfed.org/series/DFII10) |
| Silver and risk-sentiment proxies among available symbols | XAGUSD, equity indices, and volatility-related products are inputs awaiting validation. Verify each definition; do not label an arbitrary equity index a fear index or assume a permanently positive or negative relationship with gold |

These uses are research hypotheses. Gold's relationships with the dollar, interest rates, and the risk environment may change across periods; do not write rules such as “a rising dollar always means sell gold.” Authoritative market-attribution research can support the plausibility of candidate factors, but it does not directly establish short-horizon predictive effectiveness for this EA. [World Gold Council GRAM](https://www.gold.org/goldhub/tools/gold-return-attribution-model)

Use cross-market data that were already available at the decision time and align them by time. Compare rolling returns for price instruments and basis-point changes for yield series; do not apply price log returns to interest rates that may be zero or negative. Register windows, lags, effective paired-sample counts, correlation direction and stability, outlier handling, and the number of tests. Correlation does not establish causality or a reliable leading signal. A dollar index and its constituent currency pairs may supply overlapping information; check scores for double weighting.

For low-frequency, external, or revised data, record `provider / series_id / units / frequency / observation_time / published_at / available_at / retrieved_at / revision_id / stale_after / license_status`. A data date is not the time the data became available. Values published after the close and final revised values must not be fed back into earlier trading decisions. Output `UNAVAILABLE / STALE / UNKNOWN` for missing or unsynchronized data; do not silently substitute another symbol for the original input. After checking data availability, time alignment, and the absence of OBSERVE side effects, actually integrate a small number of inputs with plausible research hypotheses into ACTIVE offline EA candidates, feeding DR01 or decisions within the strategy's permitted scope. Integration for testing does not require prior proof of profitability; actual results determine retention, combination, or promotion, as detailed in §13.8. Do not require agreement across all related markets before allowing a trade.

### 13.4 News and Economic-Calendar Scanning and Analysis

**Calendar route.** Prefer the MQL5 Calendar API, scanning by currency, country, event ID, and importance. Initial areas of interest are USD-related employment, inflation, and Federal Reserve policy events; verify the actual list against the interface and source. Retain release time, reporting period, actual, forecast, previous, revised previous, and event units. The API uses trade-server time. Record historical time-zone/DST mappings to avoid mixing it with UTC or Beijing time. Handle missing values represented by `LONG_MIN` and the `10^6` numeric scaling; unreleased values must not be treated as 0. Encode “no event,” “not yet released,” “tentative time,” and “retrieval failure” separately. [Calendar API](https://www.mql5.com/en/docs/calendar), [Calendar data structures](https://www.mql5.com/en/docs/constants/structures/mqlcalendar)

**News-body route.** Content on the MT5 News tab depends on the broker and news provider. Calendar event descriptions are not full news articles, and being readable in the interface does not establish that an EA has a general full-text API. First inspect the actual build, available read-only tools, fields, historical coverage, and permissions; mark unavailable capabilities as UNAVAILABLE. Where necessary, research authorized publisher/data-provider APIs, RSS, or formal export files. In its release notes dated 2026-07-23 for Build 6060, MetaQuotes listed native MCP and AI capabilities, providing a possible route for later tool discovery. Those notes do not establish that this account has the build installed and do not provide a general News full-text tool list. [Platform fundamental-analysis help](https://www.metatrader5.com/en/terminal/help/charts_analysis/fundamental), [Build 6060](https://www.metatrader5.com/en/releasenotes/terminal/2447)

News analysis separately records original reports, republications, corrections, publication times, and receipt times, with deduplication and event association. Output topics, hypotheses about effects on gold/USD, evidence, and uncertainty. The calendar is not guaranteed to cover breaking news. Forecast surprises, importance, and AI sentiment are not direct buy/sell signals. Actual values may be used only after release and receipt; impact direction and persistence require independent validation. News text is analysis material and must not be treated as instructions to change configurations or execute trades. Record the source, model/prompt version, and generation time for AI summaries.

**Protection and recovery.** Before releases, research smaller new-order budgets, pausing new positions, and canceling this system's pending orders that would increase risk. During releases, continue local protection of existing positions. After releases, gradually restore risk based on fresh quotes, spread, volatility, minimum waiting periods, and data health. Event lists, pre-/post-release windows, and recovery conditions are candidate parameters; do not presume an optimal number of minutes. Early exits from existing positions are a separate management policy under §13.6. A news pause must not be interpreted as suspending stop-loss management.

**Execution and replay limits.** `WebRequest` is synchronous, requires permitted URLs, and cannot be called from indicators or the Strategy Tester. If MQL5 network collection is used, place it in an independent collector EA/script; the core EA reads only validated local snapshots with validity periods, preventing slow requests from blocking trading. Calendar functions cannot be used directly in the Tester. Calendar and news research must therefore export data in advance and replay them offline. [WebRequest](https://www.mql5.com/en/docs/network/webrequest), [Official calendar-replay guidance](https://www.mql5.com/en/book/advanced/calendar/calendar_cache_tester)

Snapshots retain sources, checksums, receipt times, event versions, and time-zone rules, and expose only information already received at the simulated time. Final historical values exported today are not equivalent to real-time snapshots from that period. If the initial historical forecast/actual values, revision times, or contemporaneous news versions are missing, explicitly mark that component as unverifiable. Label retrospective AI reanalysis of historical news as `BACKFILLED_RESEARCH`; do not represent it as the online result produced at the time. For auditable replay, prefer analysis outputs saved at the time. Register model/prompt changes separately; where contemporaneous outputs are missing, validate their trading value through forward collection. Continue collecting subsequent evidence where possible; do not claim to have demonstrated the backtested returns of the complete news-analysis system.

### 13.5 Dynamic Risk States, Budgets, and Recovery

Research freezes `policy_id / config_hash / base risk_profile_id / thresholds / state-transition rules`; runtime state, risk multiplier, and permitted volume may change according to that policy. R13, R24, and R36 continue to be tested separately, with no ad hoc switching between profiles within a run. The new DR01 may proactively reduce risk within that run's frozen cap and restore it in stages after conditions recover. Do not raise the cap to recover losses, because of news sentiment, or because of high confidence.

| Risk state | Entry evidence | New-risk behavior and exit requirements |
|---|---|---|
| NORMAL | Required data are healthy; account and execution risks are within registered ranges | Normal budget multiplier, still subject to per-trade, portfolio, and margin checks |
| CAUTION | Drawdown, consecutive losses, spread, volatility, or event risk reaches preregistered warning conditions | Reduce new-order/portfolio budgets; recovery is permitted only after indicators return to lower exit thresholds and remain there for sufficient time |
| DEFENSIVE | Risk deteriorates further without reaching a stop condition | Lower multiplier; reduced concurrency or blocking new pending orders may be tested separately. Do not attribute the combined effects of several actions to one improvement |
| HALT | Hard budget, margin, or data-integrity conditions fail, or a registered pause rule triggers | New-risk multiplier is 0; manage existing positions. Use §13.6 to determine whether to cancel orders or reduce positions urgently, with a recovery path specific to the trigger |
| RECOVERY | The pause cause has cleared, fresh checks of quotes, account, and inputs pass, and cooldown conditions are met | Restore risk in stages from a registered small multiplier. Return immediately to the appropriate protective state if conditions deteriorate again; do not restore full exposure in one step |

Account inputs include cash-flow-adjusted trading drawdown, consecutive losses measured using the complete-trade convention, current equity, portfolio SL risk, and margin. Market inputs include volatility, spread, event state, and age of valid data. Register trigger thresholds, entry/exit hysteresis, persistence, cooldown, multiplier steps, recovery stages, and concurrency limits before the experiment; this addition does not select live-trading numbers for the user. The levels in §11 of 15%/30% are report-acceptance thresholds, not automatic thresholds for this state machine. [MT5 account and margin properties](https://www.mql5.com/en/docs/constants/environment_state/accountinformation)

```text
0 <= account_multiplier <= 1
0 <= engine_multiplier <= 1
effective_single_budget = max(0, CurrentEquity) * single_cap_fraction * min(account_multiplier, engine_multiplier)
effective_portfolio_budget = max(0, CurrentEquity) * portfolio_cap_fraction * account_multiplier
remaining_budget = max(0, effective_portfolio_budget - AccountRiskUsedAndReserved)
new_setup_budget = min(effective_single_budget, remaining_budget)
HALT(ACCOUNT) => account_multiplier = 0
HALT(ENGINE) => engine_multiplier = 0
```

The fixed-risk control uses multipliers of 1; ACTIVE dynamic candidates select their multipliers under the frozen policy and record `scope=ACCOUNT / ENGINE`. The account multiplier controls the portfolio budget; the engine multiplier only further restricts that engine's per-trade budget. A local engine data or state anomaly does not automatically pause other independent engines, while account-level hard failures still restrict new risk globally. Include the full actual risk of positions, pending orders, and in-flight requests in `AccountRiskUsedAndReserved`; do not shrink it by applying a multiplier. Stop adding risk when equity or other critical inputs are invalid; the formula must not act as a fallback that allows trading. Calculate volume including costs under §3 and align it downward; skip the trade when the minimum volume exceeds the budget. A budget reduction may leave existing risk above the new budget. First freeze additional risk and record the reason for the excess; do not confuse “excess caused by a lower multiplier” with an immediate liquidation instruction. Combine multiple protective causes within the same scope using the strictest applicable limit. Hard limits take precedence over recovery and market scores; do not repeatedly multiply restrictions into an unregistered risk policy.

Recovery must avoid deadlock: HALT produces no new trades, so “new profits must occur before recovery” cannot be the sole recovery condition. Register separate paths for an event window ending, data repair, margin recovery, and cooldown/restricted recovery after a trading-drawdown trigger. List causes requiring manual release separately from those permitting automatic recovery. Recovery does not reset the true drawdown high-water mark or consecutive-loss history; it only changes the recorded operating stage. Validate its effectiveness using state duration, failed-recovery counts, and renewed-pause reasons. Persist and recheck state, account cash flows, and in-flight requests after restart; restarting must not restore NORMAL automatically.

Cash management also distinguishes actual equity from trading performance. Equity budgets always use the account's actual value at that time. Drawdown triggers use a preregistered cash-flow adjustment method, such as unitized equity with complete deposit/withdrawal timestamps, so profit withdrawals are not misclassified as trading losses and deposits do not conceal historical losses. When cash flows cannot be identified, uncertainty must not be used as evidence of recovery. Withdrawals are preregistered research scenarios only; no actual funds are transferred. Report cumulative withdrawals, remaining equity, remaining margin, and subsequently executable opportunities. Do not describe the entire balance or floating profit as withdrawable profit.

### 13.6 Existing Positions, Emergency Actions, and Data Degradation

Reducing risk on new orders and exiting existing positions are separate experiments. The initial control uses `ENTRY_ONLY`: reduce or pause additional risk while managing existing positions under their originally permitted rules. Register separate `MANAGED_EMERGENCY` candidates to research order cancellation, position reduction, and liquidation when necessary, triggered by account cash loss, actual margin safety buffers, or severe execution anomalies. Specify trigger units, position scope, action sequence, target risk, and completion conditions before changing code; do not simply copy broker stop-out thresholds or report DD thresholds.

Emergency actions first stop additional risk, verify and cancel this system's pending orders that would increase exposure, then manage this system's positions in the registered order and reconcile fills and remaining risk. Do not cancel protective stops or widen SL to escape a loss. Failed cancellations or requests with unknown status must not indefinitely block emergency position protection that has already triggered. After a bounded wait, reconcile and act through the preregistered path. Handle minimum volumes, inability to make a valid partial close, partial fills, rejection/timeouts, and disconnection retries. Do not claim a position has been reduced before server confirmation. Requests must be rate-limited, idempotent, and reconciled throughout to avoid duplicate closes or reverse positions. If early Scalping exits in this mode change the user's SOP, first identify the specific conflicts and proposed approach under §2.2. Adding this research does not automatically make it the Scalping default.

Account-risk statistics still include manual trades and other EAs. Separate management authority from measurement scope; do not modify orders with unknown ownership or without authority to manage them. Failure of required market, account, margin, or reconciliation data HALTs new risk while executable local protections continue. Mark related-market and news inputs individually as `REQUIRED / OPTIONAL`. Missing optional inputs yield UNKNOWN and disable the corresponding evidence. When data required by an enabled policy expire, reduce risk or pause under the frozen rules; do not interpret the condition as “no news/low risk.” MCP being offline does not itself mean EA data have failed, and must not block local actions.

Write snapshots completely before switching the active version. On reading, check account/server/symbol identity, configuration version, timestamps, checksum, and validity period. Scanning and network tasks have timeouts and resource budgets; core trading events do not wait for AI replies. Keep a policy disabled when its required data or action capabilities are unavailable. Do not claim a function can guarantee that the account will never be wiped out.

### 13.7 Iteration, Acceptance, and Delivery

The development sequence is: select indicators and their uses → implement EA integration and behavioral logic → compile the indicators and EA → verify data reading and the decision path → enable the candidate for MT5 backtesting → compare net profit USD, equity drawdown, PF, trade count, and costs → diagnose weaknesses and adjust/replace → recompile and retest. OBSERVE has explicit engineering exit criteria. Once these checks pass, proceed to candidate implementation and testing rather than remaining indefinitely in analysis. Section 13.8 makes actual integration a required development deliverable.

1. **Capability and data inventory:** Add symbol, build, calendar, news, and historical-data availability inventories to P0; extend NR02 and establish NR07/NR08 snapshots, time zones, and field definitions. First complete data and OBSERVE work that can proceed in parallel, while preserving the original P1/P2 sequence for repairing strategy implementation.
2. **Verify observation has no side effects:** Compare OFF/OBSERVE under identical conditions for original Setups, orders, volume, SL/TP, and exits. Fix data misalignment, future-data use, and restart problems before enabling control.
3. **Compare dynamic account risk separately:** Within the same base profile, strategy, capital, and costs, compare a fixed-budget baseline with a DR01 candidate adding only a drawdown/consecutive-loss risk policy. Preregister parameter ranges and the maximum number of combinations. Do not optimize signals, news, or exits in the same comparison.
4. **Add market information individually:** Test trend/range risk adjustment and calendar windows/recovery separately, followed by separate related-market and news-analysis tests where auditable data are available. Preserve the original control for each component and report additional losing trades blocked, winning trades missed, and cost changes. The number of filtered trades is not itself an achievement.
5. **Research emergency management and recovery independently:** Report ENTRY_ONLY and MANAGED_EMERGENCY separately. Verify repeated switching near thresholds, prolonged pauses, failed restricted recovery, missing data, disconnections, restarts, quote jumps, rejections, partial fills, and simultaneous portfolio deterioration. Report both the loss reduction from risk exits and the cost of cutting profitable trades short.
6. **Combinations and continued iteration:** Register a small number of combinations only after individual components have supporting evidence. Complete tests for each engine and the actual Combined system, using real ticks, cost/delay stress, and out-of-sample data not used for selection. Compare fixed/dynamic risk within the same base profile; report gains from increased risk separately. Diagnose weaknesses, try another evidence-based approach, and validate again. Preserve the best version supported by evidence under the current conditions, and archive failed candidates and every selection attempt.

New deliverables are `MARKET_INPUT_INVENTORY / REGIME_OBSERVATIONS / CROSS_MARKET_OBSERVATIONS / NEWS_CALENDAR_SNAPSHOTS / ADAPTIVE_RISK_POLICY / RISK_STATE_TRANSITIONS / CASHFLOW_ADJUSTMENT_AUDIT / EMERGENCY_ACTION_AUDIT`; adapt names to the repository first. Each record includes version, source, and status. Do not create files that falsely imply completion.

Reports continue to follow §11 for net profit USD, maximum equity-drawdown amount and maximum relative equity-drawdown %, PF, complete-trade count, and costs. Also report risk-multiplier distributions, time spent in each state, freeze/recovery counts, minimum margin, excess losses, missed and avoided trades, withdrawal scenarios, and data coverage. Cash-flow-adjusted drawdown is an additional diagnostic; it must not replace or conceal native MT5 drawdown. Use actual compilation logs, EX5, SET/INI, snapshot checksums, backtests, and out-of-sample reports to prove each stage reached separately. Preserve the original version when no clear advantage is demonstrated; meeting the thresholds does not automatically change live configurations.

This section has been added to the current Chinese and English plans. Optimal state thresholds have not yet been selected, account data have not been connected, and candidates have not been implemented, compiled, or backtested. Subsequent execution must be checked jointly against this section and §§2.2, 3, 7, and 11. Where older wording that “risk percentages remain unchanged” conflicts, this new authorization takes precedence: base caps and the policy remain fixed, while the runtime multiplier may vary within those caps under registered rules.

### 13.8 Actual Indicator Integration into EAs and Test Iteration (Required Development Work)

The user further clarified that development must actually integrate selected indicators with plausible uses into EA candidates and continue testing and iteration. Indicator inventories, observation logs, interface displays, or analysis reports cannot replace development deliverables. Here, “useful” initially means having a use and hypothesis to test; whether an indicator ultimately improves results must be determined by controlled comparisons after actual integration. Prior proof of profitability must not be required before allowing integration for testing.

1. **Select indicators and specify their uses.** First inspect the user's [MT5 indicator library](https://github.com/chanteck123-ux/gsm-mt5-indicators). Select indicators for existing problems and record versions, parameters, timeframes, data-availability times, and calling interfaces. Reuse suitable existing functionality where possible; missing functionality may be implemented as MQL5 modules in research candidates. Specify whether each indicator contributes to trend/range identification, signal selection, risk multipliers, entry, or exit. Do not blindly stack every indicator.
2. **Integrate indicators into the candidate code's decision path.** Use appropriate native MQL5 indicators, `iCustom`/`CopyBuffer`, or versioned source modules to actually read and consume outputs, connecting them to an engine or Risk interface permitted to change. Verify handles, buffers, units, EMPTY_VALUE, closed/unclosed-bar data, multi-timeframe readiness, and future-data use individually. Apply §2.2 to core changes affecting the user's current Scalping SOP; NON_USER strategies may be optimized autonomously. Merely displaying an indicator, loading a file, or generating observation logs must not be recorded as integration into trading decisions.
3. **Proceed to actual candidate tests after engineering checks.** OBSERVE is the preliminary stage for checking data and the absence of side effects. Once the checks pass and the research hypothesis is explicit, continue within the authorized scope to complete an ACTIVE offline candidate with an enable/disable switch; do not remain in observation indefinitely. Prior proof of improved returns is unnecessary, as is fresh confirmation for every iteration of an ordinary authorized candidate. If data or interfaces remain inadequate, record the specific problem, fix it, replace the input, or try another evidence-based method while continuing work that can proceed.
4. **Actually compile and verify integration.** Invoke MetaEditor to compile the corresponding source, retain actual logs and EX5 files, and verify EA/dependent-indicator versions, Tester loading paths, and packaging declarations. When specifying custom-indicator names dynamically, check dependency requirements such as `#property tester_indicator`. Use reproducible cases to record indicator values, read times, decision branches, generated/filtered Setups, volume or management requests, and actual responses, demonstrating that outputs participate in candidate decisions. Successful compilation does not establish profitability. [iCustom](https://www.mql5.com/en/docs/indicators/icustom), [CopyBuffer](https://www.mql5.com/en/docs/series/copybuffer)
5. **Backtest against the original under the same conditions.** Fix market data, initial capital, base risk, costs, and other conditions; compare the original/module-OFF version against the ACTIVE candidate. Initially change only one main variable at a time, then research a small number of combinations. Complete real-tick tests, cost/delay stress, and out-of-sample validation not used for parameter tuning. Report differences in net profit USD, equity drawdown, PF, complete-trade count, and costs, retaining missed profits and avoided losses. Report honestly when there are no orders or behavioral differences; do not fabricate improvements.
6. **Continue iteration based on results.** When performance is poor, diagnose indicator use, timing, parameters, excessive filtering, duplicated information, execution implementation, or other causes. Adjust parameters/use, replace or remove the indicator, then recompile and backtest. Preserve the best version supported by evidence under the current conditions, together with failure records, on every iteration. Keep the original when there is no clear advantage. After an individual component proves effective, integrate it into a combined candidate and validate again; do not add independent results together and call them portfolio performance.
7. **Deliver verifiable artifacts.** For every candidate, retain EA source, required indicator source/EX5 files and provenance, SET/INI configurations, compilation logs, integration and decision traces, backtest reports, differences under the same conditions, and the next-iteration decision. Reuse and distribute external source under its license. Record stages separately as “indicators selected / integrated into candidate code / compiled / backtested / validated / retained or rejected”; completing a plan does not substitute for these stages.

Once a research-development task starts, the integration, compilation, testing, and iteration above are work to carry through. The analytical modules in §§13.1–13.7 must be implemented through appropriate interfaces and validated in candidate-EA behavior, rather than only described in reports. This addition defines development delivery requirements; historical compilation/backtest status remains governed by actual artifacts.
