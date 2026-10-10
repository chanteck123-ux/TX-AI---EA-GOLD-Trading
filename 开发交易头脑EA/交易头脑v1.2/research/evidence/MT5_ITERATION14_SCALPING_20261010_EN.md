# I14 teacher Scalping reversal-ratio research

2026-10-10. Claude Code read the original teaching materials and authored the candidate and tools. Codex reviewed the changes, compiled the MQ5 with 0 errors / 0 warnings, and executed two native MT5 tests. **Keep the parent; candidate P is not promoted.**

The rejection branch now requires a zone-side wick/body ratio of at least 0.8 and wick/range of at least 0.40, compared in integer ticks. These are research settings inspired by a teaching example, not numerical rules specified by the teacher. The protected M5 supply/demand retest and closed reversal core, zone lifecycle, directional body, engulfing branch, risk and exits remain unchanged.

Conditions: independent USD500 accounts for June and August 2026; GOLD M5, real-tick mode 4, 250 ms delay, leverage 1:1000, single position, 2% single-trade / 3% aggregate risk, initial SL/TP both 5.00 price units. Both months are previously used development data, not holdouts or a continuous portfolio.

| Month/version | Net USD | Equity DD USD / relative DD | Net PF | Complete trades | Explicit costs USD | USD per round-trip standard lot |
|---|---:|---|---:|---:|---:|---:|
| June parent | -63.79 | 81.35 / 15.96% | 0.5574 | 44 | 5.59 | 12.7045 |
| June P | -69.42 | 81.20 / 16.12% | 0.6343 | 61 | 7.64 | 12.5246 |
| August parent | +48.05 | 29.21 / 5.30% | 1.4400 | 42 | 3.96 | 7.6154 |
| August P | +68.03 | 29.21 / 5.31% | 1.3863 | 61 | 6.14 | 7.4878 |

June worsened by USD5.63, August improved by USD19.98. The preregistered requirement of better net profit in both months was not met. More trades increased total commission/swap costs, already included in net profit. The risk-percentage cap was unchanged, but actual lots changed with equity: August's common 42 trades earned USD63.07 versus USD48.05, with nine volume changes; nineteen new trades earned USD4.96. About USD15.02 of the USD19.98 difference comes from common-trade sizing on the divergent account paths, not new entry signals. This is historical accounting decomposition, not a fixed-lot counterfactual or additive strategy edge.

Requested initial SL/TP distances were 5.00 price units. After fills, observed TP distance was 5.00 and SL distance 3.87–5.00, with no protective widening. Daily6 was not triggered in either month; non-violation was checked, but threshold pause/recovery behavior was not exercised.

August passed normal strict verification. June's original check failed because one old-dated tester log disappeared after the run. The original failure and capture remain unchanged. A new audit-only verifier locked to that exact run checked complete current agent logs, every closed-bar predicate, source/default/build bindings, trade accounting, risk, protection, Daily6 and terminal restoration. Recovery passed; the missing old log's contents remain unverified. No native rerun was used.

692 T0 evaluations were independently recomputed against exported M5 bars. This does not verify tick-level touch order, the full zone lifecycle, nearest-zone selection, restart or partial-fill fault handling. Score is N/A / SCORE_TARGETS_UNSET. No LEAN run, OOS, Demo, live deployment or Champion claim. S1–S6 and previous I11–I13 packages are preserved.
