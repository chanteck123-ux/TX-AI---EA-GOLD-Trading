# Iteration9 seven-strategy research results

2026-10-04, Codex-only. Completed18 fresh MT5 native runs and reused2 exact-version, same-condition S5 runs from I8. Seven C# signal decision layers compile and67 semantic assertions pass. Windows application control blocked LEAN execution; no new cross-engine replay or risk/fill/exit equivalence was established.

Each run starts with an independent USD500 account, GOLD/M5, August1 to September1,2026 exclusive, model4 real ticks, nominal tester leverage1000, configured0 or250ms delay. This is repeatedly used development data. Independent account profits must not be added into a USD500 portfolio return or described as a long-term monthly average.

| Arm | Delay ms | Net USD | Equity DD USD | Max relative DD | Native PF | Net lifecycle PF | Complete positions | Win rate | Explicit fees USD | USD/round-trip lot |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| S1_BASE_AUG_D0 | 0 | 32.30 | 32.08 | 5.68% | 1.430 | 1.434 | 45 | 42.22% | 4.79 | 9.038 |
| S1_BASE_AUG_D250 | 250 | 45.24 | 28.04 | 4.89% | 1.638 | 1.646 | 45 | 40.00% | 4.79 | 9.038 |
| S1_DYNAMIC_AUG_D0 | 0 | 55.95 | 46.27 | 7.68% | 1.435 | 1.439 | 52 | 36.54% | 6.47 | 8.403 |
| S1_DYNAMIC_AUG_D250 | 250 | 73.33 | 42.07 | 6.84% | 1.597 | 1.606 | 53 | 41.51% | 6.56 | 8.410 |
| S1_RISK2_AUG_D0 | 0 | 102.56 | 67.37 | 10.06% | 1.483 | 1.487 | 54 | 37.04% | 8.54 | 7.237 |
| S1_RISK2_AUG_D250 | 250 | 91.32 | 61.95 | 9.48% | 1.596 | 1.604 | 43 | 46.51% | 7.47 | 7.252 |
| S2_BASE_AUG_D0 | 0 | -4.15 | 6.63 | 1.32% | 0.000 | 0.000 | 1 | 0.00% | 0.08 | 8.000 |
| S2_BASE_AUG_D250 | 250 | -3.88 | 6.63 | 1.32% | 0.000 | 0.000 | 1 | 0.00% | 0.08 | 8.000 |
| S2_PROGRESS_AUG_D0 | 0 | -4.66 | 10.67 | 2.11% | 0.000 | 0.000 | 1 | 0.00% | 0.08 | 8.000 |
| S2_PROGRESS_AUG_D250 | 250 | -4.63 | 10.67 | 2.11% | 0.000 | 0.000 | 1 | 0.00% | 0.08 | 8.000 |
| S3_BASE_AUG_D0 | 0 | 14.02 | 12.16 | 2.36% | 2.221 | 2.234 | 6 | 50.00% | 0.48 | 8.000 |
| S3_BASE_AUG_D250 | 250 | 4.57 | 12.03 | 2.33% | 1.398 | 1.401 | 6 | 33.33% | 0.48 | 8.000 |
| S4_BASE_AUG_D0 | 0 | 95.54 | 33.09 | 5.71% | 1.439 | 1.442 | 55 | 49.09% | 5.06 | 7.667 |
| S4_BASE_AUG_D250 | 250 | 102.03 | 33.22 | 5.59% | 1.462 | 1.464 | 56 | 50.00% | 5.14 | 7.672 |
| S6_BASE_AUG_D0 | 0 | 23.07 | 16.83 | 3.12% | 2.334 | 2.353 | 11 | 54.55% | 0.88 | 8.000 |
| S6_BASE_AUG_D250 | 250 | 22.02 | 16.05 | 2.98% | 2.908 | 2.942 | 10 | 50.00% | 0.80 | 8.000 |
| S5_AUGUST_DELAY0_L1000 (I8 reuse) | 0 | 10.99 | 6.78 | 1.35% | 2.425 | 2.487 | 11 | 72.73% | 0.88 | 8.000 |
| S5_AUGUST_DELAY250_L1000 (I8 reuse) | 250 | 11.53 | 6.83 | 1.36% | 2.535 | 2.604 | 11 | 72.73% | 0.88 | 8.000 |
| SCALP_AUGUST_DELAY0 | 0 | 41.74 | 29.44 | 5.35% | 1.380 | 1.383 | 42 | 64.29% | 3.90 | 7.647 |
| SCALP_AUGUST_DELAY250 | 250 | 48.05 | 29.21 | 5.30% | 1.440 | 1.440 | 42 | 64.29% | 3.96 | 7.615 |

Net profit already includes recorded fees. Spread embedded in fill prices is not deducted twice. Explicit commission/swap/fees per matched round-trip standard lot is not a calibrated all-in friction estimate. Cent rounding and size mix affect cost per lot. Native maximum equity DD in dollars and maximum relative equity DD can have different peaks. Scalping native PF/DD use report precision; net lifecycle PF is independently computed. Partial exits are grouped into one completed position, not independent observations.

| Candidate / reference | Net delta USD | DD delta USD | Relative DD delta pp | Fee delta USD | Position delta |
|---|---:|---:|---:|---:|---:|
| S1_RISK2_AUG_D0 / S1_BASE_AUG_D0 | 70.26 | 35.29 | 4.37 | 3.75 | 9 |
| S1_DYNAMIC_AUG_D0 / S1_RISK2_AUG_D0 | -46.61 | -21.10 | -2.37 | -2.07 | -2 |
| S1_DYNAMIC_AUG_D0 / S1_BASE_AUG_D0 | 23.65 | 14.19 | 2.00 | 1.68 | 7 |
| S2_PROGRESS_AUG_D0 / S2_BASE_AUG_D0 | -0.51 | 4.04 | 0.79 | 0.00 | 0 |
| S1_RISK2_AUG_D250 / S1_BASE_AUG_D250 | 46.08 | 33.91 | 4.59 | 2.68 | -2 |
| S1_DYNAMIC_AUG_D250 / S1_RISK2_AUG_D250 | -17.99 | -19.88 | -2.65 | -0.91 | 10 |
| S1_DYNAMIC_AUG_D250 / S1_BASE_AUG_D250 | 28.09 | 14.03 | 1.95 | 1.77 | 8 |
| S2_PROGRESS_AUG_D250 / S2_BASE_AUG_D250 | -0.75 | 4.04 | 0.79 | 0.00 | 0 |

Reference defaults remain S1/S2/S3/S5/S6 at1%, S4 at2%. New research candidates are S1 fixed2%, S1 dynamic2/1/0.5%, and S2 next-closed-M5 progress confirmation. The new handbook Scalping candidate uses a2% ceiling, single position and3% aggregate budget. Every trading input was verified against its source default and effective SET. These are ceilings, not a promise of fully used risk.

S1 fixed2% earns more but increases drawdown and triggers the original persistent10% emergency lock in both runs, on August26 and21 respectively. Three and six full quoted trading days remain locked. The250ms native relative DD9.483% and EA trigger DD10.00137% are separate measurements. Dynamic S1 changes only the budget for NEW entries; initial SL/TP, signal and exit logic, existing exposure accounting and emergency threshold remain unchanged. Its detailed observed transitions and operation limits are retained in the dynamic review.

Both dynamic S1 runs have no observed emergency or daily lock. Each has17 positions budgeted at2%, followed by35/36 at1%. Versus fixed2%, net falls46.61/17.99 dollars, DD falls21.10/19.88 and explicit cost falls2.07/0.91. Versus1%, net rises23.65/28.09 but DD rises14.19/14.03. This is a risk-policy trade-off, not improved signal edge. Neither the0.5% tier nor restoration occurred. Requiring24 hours of valid observed quotes with no gap over120 seconds makes recovery vulnerable to daily market closure and DD qualification resets; native restoration coverage is not claimed.

S4 has no emergency locks in either run; its two daily pauses per run were individually verified to reset the next day. S6 has neither emergency nor daily locks. Normal resumed pauses are distinguished from persistent shutdown.

The direct S2 source parent is FIRST_VISIT, whereas the retained table reference is SAME_CLOSE. This compares the complete confirmation chain, not a one-variable ablation that merely adds a waiting candle. S2 progress produces one trade in each run, losing0.51/0.75 more than the retained reference with4.04 more DD. Of38 first-contact zones,22 were EMA-incompatible at contact. Of8 T0 candidates,4 invalidated before T1 and2 failed T1 body/progress;2 armed,1 traded. The other requires9.68 dollars at minimum lot versus roughly4.953 dollars of budget. Integration is real but improvement is not demonstrated. Keep risk-only and exit-only follow-up experiments separate.

S3 uses the same6 setups at0.01 lots. The August28 final trade exceeds its5.0461-dollar budget after a delayed fill raises initial risk to5.15; the minimum-size position is fully closed for-0.04. Its0ms counterpart exits at TP for+9.60. That difference-9.64 and the other5 trades+0.19 reconcile the total-9.45. Do not disable this corrective risk control to improve the report.

New Scalping follows the current user handbook core: M5 nearest valid zone, observed retest and closed directional reversal. It removes former extra EMA/RSI/H4 gates and uses research SL/TP of5.00 instrument price units, with the previous8/7-price source preserved for recovery. Daily cumulative6 NET wins OR6 NET losses blocks new entries;3 wins plus3 losses does not. Both native daily ledgers reconcile; neither run reached a6-win or6-loss day. Actual threshold locking, restarts, multi-instance and partial-fill fault injection remain unproven. In250ms,38 protective modifications have server confirmation; the remaining positions already had protection. No failed modification was observed, so failure retry is not established. The6.31-dollar delay difference is primarily one position crossing from0.01 to0.02 lots; it is not evidence that delay adds edge. Old-versus-new Scalping changes multiple rules and conditions, preventing single-component causal attribution.

All aggregate scores, component scores and score differences are N/A / SCORE_TARGETS_UNSET. Weights35/25/20/10/10 are preserved without inventing anchors or reweighting. The USD1000 monthly challenge and external PF examples are not scoring targets. Full raw metrics, lifecycle definitions and bound run IDs are in FINAL_RESULTS.json; MANIFEST.json maps original paths to copied members and hashes.

Native engineering/accounting checks passed for18 new runs;2 unchanged S5 results are clearly reused.0ms is supported by configuration/start identity;250ms additionally has the bound native Agent setting. These do not measure per-fill real network latency. Tester margin/Stop Out values remain uncalibrated against broker rules; nominal leverage1000 does not prove real USD500 capacity. Historical cost calibration, unused OOS, new adverse-cost stress, portfolio and withdrawal paths are incomplete.

C# implementation is limited to signal formulas and timing. Native H4/D1 warm-up bars were extended, overlapping historical fields reconciled, and67 pure assertions passed. QuantConnect.Queues.dll was refused by Windows application control0x800711C7 before a successful LEAN replay. Failure logs are preserved; system controls were not bypassed. The environment must be resolved through its authorized administration before full-engine replay and parity work can continue.

Ten current matching MQ5/EX5 pairs are supplied: six references, three research variants and new Scalping, plus one older Scalping pair for recovery. Its historical June/1000ms/nominal100-leverage evidence is separate and excluded from the20-row comparison. Parameters are baked into source defaults; compile logs, SET/INI and native reports are included. Extract before use. Place the desired EX5 in the fixed terminal MQL5/Experts folder and select GOLD/M5 in Strategy Tester. Source compilation requires included TB_C7 indicator files at the matching Indicators path and the existing MetaEditor standard library. Paths in historical tools stay bound to the original workspace; the package is not an automatic installer. No chart deployment, Demo-forward or live trading occurred. Prior recovery versions remain intact.

No Champion, live readiness, monthlyUSD1000 result or reliable future profit is claimed. The next registered batch should address the recorded operational and statistical weaknesses without deleting failed evidence.
