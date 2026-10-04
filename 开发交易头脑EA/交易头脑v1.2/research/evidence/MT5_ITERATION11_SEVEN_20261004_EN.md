# TradingBrain I11 research results — 2026-10-04

S2 improves in this development comparison: progress confirmation at2% with existing1R BE keeps June netUSD14.84 and increases August250ms net from14.28 to19.40, while maximum equityDD falls from17.17 to12.05 at unchanged explicit cost. Retain as the next research lead with only1/2 trades, not stable-profit acceptance. Same-close2% did not beat the incumbent. Scalping DD15 triggered, closed and stayed locked: June net−65.85,2.06 worse than parent, native equityDD5.88 lower; August unchanged. S1/S3/S4/S5/S6 remain prior research references. No Champion or live deployment.

Completed9 new native MT5 tests,3 clean source builds and19 exact-version evidence rechecks:28 rows. S1/S3/S4/S5/S6 retain prior tested sources; their rows are reused evidence. Every run is an independent USD500 GOLD/M5 account, real-tick model4, nominal leverage1:1000. June andAugust2026 are already-used development windows.250ms is the main comparison; August0ms is diagnostic. These are neither OOS nor an additive portfolio or continuous cash-flow path.

At August250ms the short changes from−5.11 to+0.01USD: requestedSL4333.95, actualexit4333.97, gross0.09 minus0.08 commission. The H4 long remains+19.39 and total fees0.16. August0ms net is19.34USD. All three June/August250ms positions show accepted BE modifications with EA SL readback; June and the August long still exit at originalTP. Risk-percentage policy and initialSL/TP/actual lots stay fixed, while path-dependent second-trade budget changes9.8978→10.0002USD. No independent tick-by-tick trigger-quote replay or guaranteed net breakeven; the inherited fee-history failure limitation remains.

Scalping retains the handbook entry, initial5.00 price-unit SL/TP,2% single/3% account risk, one position and server-day6 net wins OR6 losses. DD15 reduces the June native maximum equityDD by5.88USD, but net profit worsens by2.06USD and explicit cost falls0.08USD. August outcomes are identical to the parent. The June loss problem remains.

At2026.06.29 04:35:33 the EA logs peak510.75/equity434.12, a76.63USD or15.00342633% drawdown. Native order/deal87 closes owned position86,0.01lot,net−2.14USD. No entry follows; the lock remains at window end. MT5 separately reports maximum equityDD75.47USD and maximum relative equityDD14.81%. Both measurements are retained; there is no independent full equity-sample replay explaining their difference.15% is an action trigger, not a guaranteed future loss cap.

New native tests:

| Arm | NetUSD | EquityDD USD | Max relativeDD | NativePF/netPF | Lifecycles | Explicit costUSD | USD/round-trip lot |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S2_SAMECLOSE_RISK2_JUNE_D250 | +13.72 | 8.84 | 1.73% | 197.00 / N/A | 1 | 0.14 | 7.00 |
| S2_SAMECLOSE_RISK2_AUG_D250 | -7.74 | 13.25 | 2.62% | 0.00 / 0.00 | 1 | 0.14 | 7.00 |
| S2_SAMECLOSE_RISK2_AUG_D0 | -8.28 | 13.25 | 2.62% | 0.00 / 0.00 | 1 | 0.14 | 7.00 |
| S2_PROGRESS_RISK2_BE1_JUNE_D250 | +14.84 | 8.70 | 1.71% | 372.00 / N/A | 1 | 0.08 | 8.00 |
| S2_PROGRESS_RISK2_BE1_AUG_D250 | +19.40 | 12.05 | 2.38% | 243.50 / N/A | 2 | 0.16 | 8.00 |
| S2_PROGRESS_RISK2_BE1_AUG_D0 | +19.34 | 12.14 | 2.40% | 242.75 / N/A | 2 | 0.16 | 8.00 |
| SCALP_DD15_JUN_D250 | -65.85 | 75.47 | 14.81% | 0.54 / 0.53 | 43 | 5.51 | 12.81 |
| SCALP_DD15_AUG_D250 | +48.05 | 29.21 | 5.30% | 1.44 / 1.44 | 42 | 3.96 | 7.62 |
| SCALP_DD15_AUG_D0 | +41.74 | 29.44 | 5.35% | 1.38 / 1.38 | 42 | 3.90 | 7.65 |

Candidate-minus-reference comparisons (same market, dates, capital, delay and recorded cost model):

| Candidate | Reference | NetUSD delta | DDUSD delta | RelativeDD pp | Count delta | CostUSD delta |
| --- | --- | --- | --- | --- | --- | --- |
| S2_SAMECLOSE_RISK2_JUNE_D250 | S2_RISK2_JUNE_D250 | -1.12 | +0.14 | +0.03 | 0 | +0.06 |
| S2_SAMECLOSE_RISK2_JUNE_D250 | S2_BASE_JUNE_D250 | +6.87 | +4.42 | +0.86 | 0 | +0.06 |
| S2_SAMECLOSE_RISK2_AUG_D250 | S2_RISK2_AUG_D250 | -22.02 | -3.92 | -0.78 | -1 | -0.02 |
| S2_SAMECLOSE_RISK2_AUG_D250 | S2_BASE_AUG_D250 | -3.86 | +6.62 | +1.30 | 0 | +0.06 |
| S2_SAMECLOSE_RISK2_AUG_D0 | S2_RISK2_AUG_D0 | -22.54 | -3.97 | -0.78 | -1 | -0.02 |
| S2_SAMECLOSE_RISK2_AUG_D0 | S2_BASE_AUG_D0 | -4.13 | +6.62 | +1.30 | 0 | +0.06 |
| SCALP_DD15_JUN_D250 | SCALP_JUN_D250 | -2.06 | -5.88 | -1.15 | -1 | -0.08 |
| SCALP_DD15_AUG_D250 | SCALP_AUGUST_DELAY250 | 0.00 | 0.00 | 0.00 | 0 | 0.00 |
| SCALP_DD15_AUG_D0 | SCALP_AUGUST_DELAY0 | 0.00 | 0.00 | 0.00 | 0 | 0.00 |
| S2_PROGRESS_RISK2_BE1_JUNE_D250 | S2_RISK2_JUNE_D250 | 0.00 | 0.00 | 0.00 | 0 | 0.00 |
| S2_PROGRESS_RISK2_BE1_AUG_D250 | S2_RISK2_AUG_D250 | +5.12 | -5.12 | -1.01 | 0 | 0.00 |
| S2_PROGRESS_RISK2_BE1_AUG_D0 | S2_RISK2_AUG_D0 | +5.08 | -5.08 | -1.00 | 0 | 0.00 |

Recorded commission,swap andfees are already included in net. Spread embedded in fills is not subtracted twice. Round-trip cost uses matched opening standard lots; lot rounding/overnight holding affects the value. NativePF is preserved separately from complete-position netPF; no loss denominator means netPF isN/A. Full historical friction and actual broker margin/StopOut remain uncalibrated.

Score:N/A/SCORE_TARGETS_UNSET.35/25/20/10/10 weights remain, formal anchors unset. No arbitrary1000USD orPF2 full-score anchors.32 MQL pure policy assertions ran in each Scalping test; they do not establish native restart/storage/unknown-fill/partial-fill/cancellation/multi-instance fault coverage. This candidate supports zero external cash flow only; post-initial cash adjustments block new risk without resetting peak. Withdrawal/cash-flow-adjusted operation is unverified.

No new LEAN execution or accepted C# risk/fill/exit parity. No independentOOS, double-cost stress, withdrawal path, combined portfolio, Demo-forward, live deployment or Champion promotion. The USD1000/month objective has not been validated. Source defaults, matchingEX5,SET/INI,buildlogs,reports andhashes are packaged. I10 recoveryZIP and failed research references remain. New candidates are tester-only.
