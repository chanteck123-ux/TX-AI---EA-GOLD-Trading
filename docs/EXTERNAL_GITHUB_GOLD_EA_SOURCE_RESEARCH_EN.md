# Two GitHub Gold EA Repositories: Source-Code Research Record

Review date: 2026-09-06. Executor: Codex. Purpose: reference material for later FxPro GSM 3-SOP Candidate development.

**Conclusion: both repositories have research value, but neither can be treated as a new Champion or migrated wholesale into this project.**
No EA, SET, Champion ZIP, or live-trading settings were modified in this review. No external script, third-party EA, compilation, or trading backtest was executed. The findings below are from static source inspection, not profitability validation.

## 1. Pinned revisions and review scope

| Source | Remote HEAD and local HEAD used | Files | Assessment |
|---|---|---:|---|
| [GoldTraderEA](https://github.com/mehdi-jahani/GoldTraderEA/tree/ba329266c56372c36da9f81fac35983b9fc2e4a3) | `ba329266c56372c36da9f81fac35983b9fc2e4a3` | 18 | Research source for patterns and price action |
| [EA_SCALPER_XAUUSD](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/tree/b0087e93c8af6690102c6698b8123186703a9240) | `b0087e93c8af6690102c6698b8123186703a9240` | 1,054 | Research source for engineering architecture and validation methods |

A complete inventory was produced for all 1,072 tracked files, including path, classification, Git blob, working-file SHA256, and size. Supported text types were also content-indexed. **Automated scanning is not the same as line-by-line understanding.**
This review performed targeted reading or data parsing on 27 files, focused on signals, zones, risk, execution, position management, and validation flow. Exact coverage is recorded in `REVIEW_COVERAGE.csv`.
987 files were successfully text-indexed; 12 failed strict UTF-8 decoding, so their files and hashes are retained without claiming their contents were understood; another 73 binary or unclassified files were not content-loaded. Exact status is recorded in `FILE_INVENTORY.csv`.
The second repository contains 524 standard-library, utility-library, or backup-directory files; these must not be miscounted as 524 original strategy modules. Its `MQL5/Include/EA_SCALPER/` directory contains 59 project files, all module-indexed.
This review did not line-by-line audit every historical document, every Python script, all standard libraries, or binary models. Do not describe this report as a “full-repository defect-free certification.”

## 2. Usage boundaries

- GoldTraderEA: the full tracked-file inventory reviewed here contained no standalone LICENSE/COPYING/NOTICE file. Public-source wording in the README is not a clear reuse license. Do not use it as authorization to copy source into the formal product.
- EA_SCALPER_XAUUSD: the root [LICENSE](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/LICENSE) is PolyForm Noncommercial 1.0.0; [TRADING_RESTRICTIONS.md](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/TRADING_RESTRICTIONS.md) also restricts live trading, asset-management/evaluation use, commercial use, and broker-connected simulated execution.
- This review copied no algorithm implementation, configuration, or binary. General concepts are recorded separately from source implementation. Future work must be independently designed around GSM SOP, our own interfaces, and our own tests. Renaming, rewriting, or claiming “independent implementation” does not automatically remove licensing concerns; restricted implementations still require license review and must not be copied.

## 3. What is useful and how to bring it back safely

| Research topic | Source entry point | Potential use for us | Decision in this review |
|---|---|---|---|
| Candle classification, body/wick, engulfing, star combinations | A `CandlePatterns.mqh` | Post-zone confirmation for Intraday/Swing; standardized closed-bar inputs | Keep concept, redefine mathematics |
| Local highs/lows and repeated S/R reactions | A `SupportResistance.mqh` | Zone scoring for Intraday/Swing | Candidate only; must not replace Scalping Fresh/First Touch |
| Multi-timeframe direction and zone context | A `MultiTimeframe.mqh`; B `CMTFManager.mqh` | Record direction, location, and confirmation quality separately | Observe as scoring first; do not add a hard filter directly |
| Structure highs/lows, BOS, CHoCH | B `CStructureAnalyzer.mqh` | Audit `WRONG_TREND` | Research concept only; source implementation has critical issues |
| Optimal location, acceptable range, timeout | B `CEntryOptimizer.mqh` | Distinguish late entry, chasing, and normal closed-bar confirmation | Candidate; observe before testing a blocker |
| Zone valid/tested/invalid state | B `EliteOrderBlock.mqh`, `EliteFVG.mqh` | Zone lifecycle, deduplication, nearest-zone logic | Useful; must be rebuilt to satisfy GSM departure/first-retest semantics |
| Unified risk decision and reason list | B `CUnifiedRiskPolicy.mqh` | Risk budget, news, signal funnel | Engineering reference; do not import prop-firm timing rules |
| Initial risk, staged management, restart recovery | B `CTradeManager.mqh` | Intraday/Swing profit protection | Reference state-machine concept; strict per-position isolation required |
| Ablation, time split, latency/cost stress | B `scripts/backtest/`, `scripts/oracle/` | Single-variable Candidates and falsification checks | Methodology reference; does not replace FxPro MT5 Real Tick |
| ONNX, Footprint, complex patterns, many indicators | Other modules in both repositories | Future research library | Deferred; not in first formal logic round |

“Keep” means worth researching, not proven profitable or approved for Champion integration.

## 4. Specific risks in GoldTraderEA

### A01: Trend filter compares indicator handle as if it were a price

`GoldTraderEA.mq5:843-851` uses the return value of `iMA` in a price comparison; in MQL5, `iMA` returns an indicator handle, not the moving-average value itself. Another value described as the current close is taken from the tail of a series array and is stale data. This must not be copied into our trend logic.
[Pinned source](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/GoldTraderEA.mq5#L843) · [MQL5 iMA definition](https://www.mql5.com/en/docs/indicators/ima)

### A02: Candle definitions and closed-signal semantics are inconsistent

`CandlePatterns.mqh:43,113,171-329` uses the currently forming candle; engulfing may pass on relative body size alone without true engulfment; morning/evening-star thresholds multiply absolute price by a ratio and cannot be interpreted as body-recovery percentage. Our same-named patterns must be redefined and tested independently.
[Pinned source](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/CandlePatterns.mqh#L243)

### A03: Repeated S/R reaction is not Fresh S&D

`SupportResistance.mqh:109-137` counts candles near price without distinguishing adjacent candles from independent departures and retests, and it includes the level-forming event itself. The upper layer guarantees only 100 data points while the validation loop may access 200. This cannot be used directly as a First Touch engine.
[Pinned source](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/SupportResistance.mqh#L109)

### A04: Lot sizing and order-success accounting do not meet our requirements

When risk sizing is below minimum volume, the code can lift it to minimum lot; fixed lot is also the default. `SafeOpenBuyPosition/SellPosition` calls a no-return order wrapper, then immediately increments counters and returns success, so the counter cannot be treated as proof of actual fill. There are also whole-account position limits and differences between live/test handling cadence.
[Lot sizing and execution](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/GoldTraderEA.mq5#L898)

### A05: README performance is not our evidence

Historical returns and PF in the README are author claims. These 18 tracked files do not include the corresponding original MT5 reports, test SET/INI, compiled artifact, and complete hash chain. Those numbers must not be entered into GSM scorecards.
[README](https://github.com/mehdi-jahani/GoldTraderEA/blob/ba329266c56372c36da9f81fac35983b9fc2e4a3/README.md)

## 5. Specific risks in EA_SCALPER_XAUUSD

### B01: Structure chronology and direction validation

`AnalyzeStructure` accepts a timeframe parameter but reads the current chart timeframe. Series data is scanned newest-to-oldest and appended, then the tail is treated as the latest structure. A downside-break event is validated before bearish direction is set; after reset, the direction defaults to enum value 0, which is bullish. Time ordering, closed-bar confirmation, and event direction must be redesigned rather than copied.
[Structure entry and detection](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/CStructureAnalyzer.mqh#L311)

### B02: Nearest-zone, touch-count, and expiry semantics

For OB/FVG, nearest-zone distance is not guaranteed to be zero while price is inside the zone, so another zone with a closer edge may be selected. Touch-update logic increments repeatedly while price remains inside the zone and cannot be interpreted as independent retests. EntryOptimizer rebuilds the validity deadline on each calculation; repeated recalculation by callers can refresh the timer. Setup start time must be fixed per Setup.
[OB distance](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/EliteOrderBlock.mqh#L609) · [FVG state](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/EliteFVG.mqh#L525) · [Entry lifecycle](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/CEntryOptimizer.mqh#L254)

### B03: Multi-position management is not fully implemented

`ManagePositionByIndex` updates position existence, count, and extrema only; the complete state machine still runs through a single active trade. Some modifications search by Magic+Symbol instead of a locked target ticket. Saved state is named by slot, and restore does not verify that saved ticket matches the live position. This does not satisfy independent management for three strategies with multiple Setups.
[Multi-position path](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Execution/CTradeManager.mqh#L2249)

### B04: Volume normalization can increase risk instead of reducing it

`MathUtils` first lifts volume to minimum lot, then rounds down, and assumes two decimal places. Some risk reductions in the main EA also fail when reduced volume drops below minimum. Small accounts therefore cannot claim compliance with 1% risk merely because normalization succeeded; partial close may also turn an intended half-close into a full close.
[Lot utility](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Core/MathUtils.mqh#L20) · [Pre-execution sizing](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Experts/EA_SCALPER_XAUUSD.mq5#L1623)

### B05: Loss-driven Recovery Entry is not our opportunity-expansion rule

The entry flow can continue searching for a Recovery Entry because an existing position is in floating loss. That differs from our rule that every independent Setup must pass SOP and risk budget on its own. Even without doubling volume, loss-driven add-on logic must not be imported.
[Recovery entry](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Experts/EA_SCALPER_XAUUSD.mq5#L978)

### B06: A module name does not prove a completed algorithm

Some institutional/volume/structure checks in the OB implementation return constant true/false values. Older architecture documents and actual default switches are also not fully aligned. Real call paths must be traced; feature names alone do not prove the feature is implemented. The repository README itself marks the project as under development.
[Placeholder implementation](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/EliteOrderBlock.mqh#L587)

### B07: Profit protection must be rebuilt to our rules

The source break-even only adds a fixed 2 points and cannot be claimed to cover all commissions, swap, and slippage. Trailing-stop comments and actual tightening direction are inconsistent in places; restart and multi-position issues are covered in B03. The staged-management concept may be studied, but not its parameters or order operations.
[BE source](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Execution/CTradeManager.mqh#L1156)

### B08: Missing Footprint data can turn into directional bias

When a tick has no BUY/SELL flag and `last` is zero, the code falls back to bid and compares it to the bid/ask midpoint; with positive spread, this falls into seller classification. Zero volume may also be replaced with 1. Under such inputs, the result is a proxy signal, not evidence of genuine aggressive selling, and must not be presented as institutional order-flow evidence.
[Direction calculation](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/MQL5/Include/EA_SCALPER/Analysis/CFootprintAnalyzer.mqh#L601)

### B09: Research backtesting and final validation must stay separate

The recommended Python backtester uses ONNX mocks, custom friction, and sampled-data paths. It is not equivalent to our compiled EA running FxPro MT5 Real Tick. `models/wfa_results.json` failed parsing in this review and ends at the `passed` field.
[Backtest documentation](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/scripts/backtest/README.md) · [WFA data](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/models/wfa_results.json)

### B10: Model selection can no longer call the same data untouched OOS

`train_wfa.py` selects the final model using OOS accuracy. That may be valid as a research-selection process, but those OOS observations participated in selection and cannot still be used as untouched validation for the chosen winner. A classification-accuracy ratio is also not trading PF, Recovery, or Net Profit.
[Model selection](https://github.com/francomascareloai/EA_SCALPER_XAUUSD/blob/b0087e93c8af6690102c6698b8123186703a9240/scripts/ml/train_wfa.py#L323)

## 6. Research order for later Candidates

These are research items awaiting validation, not established or winning Candidates. First verify the actual FxPro baseline funnel and trade evidence, then select one item.

| Item | Single research question | Mandatory falsification tests |
|---|---|---|
| R01 Nearest valid zone | Is the nearest valid zone by current-price distance being displaced by an old zone or quality score? | Price inside zone, equal distance, old zone invalidation, new zone arrival; keep Nearest and quality scoring separate |
| R02 Concurrent qualified opportunities | Are multiple independent Setups in the same strategy being blocked by a mechanical position limit? | Same-tick risk reservation, request timeout, duplicate tick, restart, reject, partial fill; never use floating loss as an entry reason |
| R03 Direction and closed-bar confirmation | Does wrong trend come from indexing/timeframe bugs or from strategy definition? | Increasing/decreasing highs/lows, close timing, cross-timeframe mapping, no future information at the same timestamp |
| R04 Entry location and expiry | Can normal post-close entry be distinguished from genuine chasing? | Fixed Setup expiry, first touch, expansion away from zone, re-entry after waiting, post-cost R:R |
| R05 Intraday/Swing management | Can staged management reduce giveback while preserving trends? | Hard ticket/strategy isolation, no partial on 0.01 lot, initial R unchanged, stop only tightens, restart does not repeat reduction |
| R06 Zone-quality scoring | Do independent reaction counts add value? | Adjacent candles do not double-count, no departure means no retest, used/broken zones never reset to fresh |

ONNX, complex pattern fusion, large indicator stacks, and Recovery Entry are not priorities for the first implementation round. Any R02 concurrency change must be disclosed separately and risk-normalized; profit gained by increasing exposure must not be presented as strategy improvement.

## 7. User constraints that must remain in force

- FxPro only; Codex executes alone. The three strategies operate independently under OR logic and do not require simultaneous confirmation.
- Scalping uses fixed SL/TP only and is completely excluded from break-even, trailing stop, partial exit, and runner management.
- Intraday/Swing profit protection is researched independently; any external rule remains Candidate-only, with GSM SOP as the foundation.
- Any qualified independent Setup may be attempted if risk and execution checks pass; no artificial daily trade cap, no duplicate signals, no martingale, grid, or averaging-down add-ons.
- Per-trade risk cap 1%, combined account cap 3%; lot tables are references only. Size from actual SL and contract specs, round down to broker step, and skip when minimum lot exceeds risk budget.
- Official ranking: Net Profit USD → Max Equity Drawdown → PF → complete trade count → Win Rate → Reject.
- DD above 30% rejects; 15%-30% requires manual review; Recovery >3; each standalone strategy and Combined must have >100 complete trades; Reject = 0. These are project promotion gates, not profitability guarantees.
- Real MetaEditor compilation, FxPro Real Tick, risk-matched comparison, untouched OOS, cost/latency stress, and strategy-attribution audit must pass before promotion can be considered.

## 8. Saving and continuation

This package includes the Chinese record, the 1,072-file inventory, project module index, 27-file review coverage, automated review script, and results. At the time of the Codex review, it had not yet been published to the main repository; this bilingual research record is now archived in the project repository as documentation only and does not modify the formal EA, SET, Champion ZIP, or live settings.
The main project already had uncommitted changes at review time; this review did not overwrite them. The two external repositories remained clean pinned copies.
When continuing, read `CHECKPOINT.json` first, then locate `REVIEW_COVERAGE.csv`. Unread modules are marked `INDEX_ONLY`; before adopting any such module, fully read its implementation and dependencies and re-check its license.

V4.00 protected baseline was verified before and after this review:

- ZIP SHA256: `43AF3C393B6C226211115A1A1DBC70C88F0F07250FA332D22C04C3ED64EB80E2`
- MQ5 SHA256: `AC9826E6EF4959562B9079A1FF9B8CBB35E5E8C2A913E431488CA5C900D1FF60`

These hashes prove file identity only; they do not prove compliance with the latest Champion risk and sample requirements. All strategy results in this review remain `NOT_TESTED`; no Net, DD, PF, or Win Rate values are fabricated.
