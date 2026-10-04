# TradingBrain seven strategy iteration ten results

Completed17 new native MT5 tests and reused12 exact-version/condition results,29 rows total. Three new source-default candidates compiled cleanly: S1 accumulated eligible-time recovery, S2 risk-only2%, and S2 original1% plus existing cost-offset breakeven at1R. No new chart, Demo or live deployment.

S2 is the useful new research lead: changing only the progress variant risk ceiling from1% to2% admitted previously unaffordable minimum-lot setups, yielding USD14.84 in June and14.28 in August at250ms. It is the next research candidate with the original1% source/EX5 retained for rollback, not stable-profit acceptance: there are only1/2 trades. S1 recovery changes were inconsistent, so retain the1% reference. S3/S4/S5/S6 remain research references. Scalping lost63.79 in June with15.96% maximum relative equityDD; retain the failed reference, not cross-period profitability acceptance. No Champion promotion.

## Fixed conditions

Independent USD500 starts, GOLD/M5, real-tick model4, nominal1:1000. June2026 and August2026 are previously used development data, not OOS. Server-clock monthly ranges are [June1,July1) and [August1,September1). Main comparison250ms; each new candidate also has August0ms. These separate resets and strategies cannot be added into a portfolio or continuous account curve. June journal/report counts23,679,824 ticks/6,023 bars and August20,513,403/5,796 agree; no reported fallback was found, which is narrower than proving an archived tickstream or actual network latency.

## Retained research references

Each paired value is June/August at250ms. Retention is not Champion or deployment acceptance.

| Strategy | Profile | NetUSD | Max equityDD USD | Complete trades | Decision |
| --- | --- | ---: | ---: | ---: | --- |
| S1 | Original1%, existing BE exit | +49.42 / +45.24 | 27.09 / 28.04 | 27 / 45 | Retain; new recovery candidate not consistently better |
| S2 | Progress confirmation,2% ceiling, research candidate | +14.84 / +14.28 | 8.70 / 17.17 | 1 / 2 | New research lead; only1/2 trades, original1% rollback retained |
| S3 | Original1%, retain fill-risk overrun correction | +7.03 / +4.57 | 9.66 / 12.03 | 4 / 6 | Retain; no buffer fitted to one historical trade |
| S4 | Original2% | +66.14 / +102.03 | 41.47 / 33.22 | 50 / 56 | Retain; all3 June daily pauses resumed |
| S5 | Original1% | +6.59 / +11.53 | 2.07 / 6.83 | 7 / 11 | Exact-version evidence reused; few trades |
| S6 | Original1% | +17.31 / +22.02 | 18.63 / 16.05 | 15 / 10 | Retain; no June daily pause/emergency lock |
| Scalping | Current handbook2%, failed reference | -63.79 / +48.05 | 81.35 / 29.21 | 44 / 42 | June loss; retain failed research reference, no risk increase |

## S1: recovery changed exposure, not proven signal improvement

June new recovery and old dynamic both returned-44.86 with equityDD46.18: no recovery eligibility and minimum-lot constraints persisted at0.5%. The1% reference returned49.42/45.24 in June/August; its June58.45 winner versus-9.03 from the other26 trades shows concentration, not a counterfactual strategy. At August250ms the new candidate returned80.63, up7.30 with DD+0.59 and explicit costs+0.96: seven shared-setup position-size changes explain+7.29 and one extra position+0.01; netPF decreased. At0ms it returned53.21, down2.74, DD+2.74 and costs+1.65. Retain the1% reference. Each run passed25 policy assertions; each August path restored risk once, June never did. The250ms partial overrun reduction was identical in both versions and preceded recovery; it is not recovery benefit.

## S2:2% removes a capacity constraint, with very few observations

June progress1% made no trades;2% admitted the identical setup whose minimum-lot planned risk7.54 exceeded5. The new ceiling10 allowed0.01lot, recorded initial risk7.34(1.468% of start capital), not forced use of2%. Net/DD/cost deltas were+14.84/+8.70/+0.08. August250ms changed-4.63 to14.28, with deltas+18.91/+6.50/+0.08 and1to2 complete trades. A new long contributed19.39 after the old9.68 minimum-lot budget constraint was removed; the shared losing short was still0.01lot but entered135seconds earlier at a0.48 lower sell price, changing-4.63 to-5.11. The net difference is19.39 minus0.48. August0ms produced14.26 net,17.22 DD and2 trades. Capacity and path changed, not the signal logic. Next compare same-close versus progress at the same2% ceiling and assess costs/cross-period coverage.

## S2 breakeven is evaluated separately from the risk study

The BE candidate keeps the progress parent1% budget, entry and initialSL/TP, enabling only existing1R cost-offset BE. June still made0 trades. August250ms changed-4.63 to+0.03 and DD10.67 to6.01 with the same0.08 explicit cost: at02:33:01 SL4334.43 was requested and confirmed by EA POSITION_SL readback, then the02:54:26 native exit and comment show SL4334.43. Price profit0.11 minus commission0.08 gives0.03 net. Entry4334.54/0.01lot, originalSL4338.96, budget5 and recorded initial risk4.59 remained identical to the parent. August0ms net0.00, DD6.01. This is one observed exit improvement, not stable efficacy. Risk2 plusBE has not been tested; separate benefits cannot be added.

## S3/S4/S5/S6: cross-period coverage without fitting one trade

S3 already reserves0.02 price units; increasing to0.20 excludes3of6 original August quotes, while a smaller fitted buffer risks screening only one adverse fill. No such new candidate was run; fill-risk remediation remains. S4 June66.14/DD41.47/50trades versus August102.03/DD33.22/56; all3 June daily pauses resumed next day and no reservation appeared while locked. S6 June17.31/DD18.63/15 versus August22.02/DD16.05/10. S5 exact I8 June6.59/7 and August11.53/11 were reused, not rerun.

## Scalping: unchanged-source June check and independent protection/day-lock review

June250ms net-63.79, DD81.35(max relative15.96%),44 trades,16wins/28losses; reused August48.05,DD29.21,42 trades. Retain the failed reference, no risk increase or cross-period profit acceptance. This source has2% per-trade/3% aggregate open risk, one-position and margin admission checks, and server-day6net wins OR6net losses; no account peak-equity drawdown stop exists, so generic10% emergency rules do not apply. Maximum June daily net losses were4; the lock was not triggered. InitialSL/TP and post-fill recenter protection exist, while ManageScalpingPosition returns directly with no ongoingBE/trail. The unused UpdateScalpPause definition is not an active6-consecutive-loss pause. Preregister and test cumulative account-DD protection separately while preserving handbook core entries.

## Candidate minus exact parent

Negative DD difference means less drawdown. The risk-only comparison measures exposure/capacity, not signal alpha. No risk/exit candidates were silently combined.

| Candidate | Parent | NetUSD delta | EquityDD USD delta | RelativeDD pp delta | Explicit costUSD delta | Complete trades delta |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| S1_ACTIVE_JUNE_D250 | S1_DYNAMIC_JUNE_D250 | +0.00 | +0.00 | +0.00 | +0.00 | +0 |
| S2_RISK2_JUNE_D250 | S2_PROGRESS_JUNE_D250 | +14.84 | +8.70 | +1.71 | +0.08 | +1 |
| S2_BE1_JUNE_D250 | S2_PROGRESS_JUNE_D250 | +0.00 | +0.00 | +0.00 | +0.00 | +0 |
| S1_ACTIVE_AUG_D250 | S1_DYNAMIC_AUG_D250 | +7.30 | +0.59 | +0.01 | +0.96 | +1 |
| S2_RISK2_AUG_D250 | S2_PROGRESS_AUG_D250 | +18.91 | +6.50 | +1.29 | +0.08 | +1 |
| S2_BE1_AUG_D250 | S2_PROGRESS_AUG_D250 | +4.66 | -4.66 | -0.92 | +0.00 | +0 |
| S1_ACTIVE_AUG_D0 | S1_DYNAMIC_AUG_D0 | -2.74 | +2.74 | +0.45 | +1.65 | +0 |
| S2_RISK2_AUG_D0 | S2_PROGRESS_AUG_D0 | +18.92 | +6.55 | +1.30 | +0.08 | +1 |
| S2_BE1_AUG_D0 | S2_PROGRESS_AUG_D0 | +4.66 | -4.66 | -0.92 | +0.00 | +0 |

## All native metrics

Source column 新 means new I10; 复用 means reused I8/I9. PF is native / net complete-lifecycle PF; an absent net-loss denominator is undefined, not a perfect score. No-trade native PF0 is preserved. Counts reflect complete lifecycle trades, not extra independent observations from partial exits.

| Arm | Source | NetUSD | EquityDD USD | Max relative equityDD% | Native/netPF | Complete trades | Explicit costUSD | USD/roundtrip standard lot |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| S1_BASE_JUNE_D250 | 新 | +49.42 | 27.09 | 5.41 | 1.790 / 1.795 | 27 | 3.09 | 9.97 |
| S1_DYNAMIC_JUNE_D250 | 新 | -44.86 | 46.18 | 9.23 | 0.001 / 0.000 | 11 | 1.08 | 7.71 |
| S2_BASE_JUNE_D250 | 新 | +6.85 | 4.42 | 0.87 | 172.250 / N/A | 1 | 0.08 | 8.00 |
| S2_PROGRESS_JUNE_D250 | 新 | +0.00 | 0.00 | 0.00 | 0.000 / N/A | 0 | 0.00 | N/A |
| S3_BASE_JUNE_D250 | 新 | +7.03 | 9.66 | 1.91 | 1.914 / 1.924 | 4 | 0.32 | 8.00 |
| S4_BASE_JUNE_D250 | 新 | +66.14 | 41.47 | 7.41 | 1.324 / 1.326 | 50 | 4.30 | 7.82 |
| S6_BASE_JUNE_D250 | 新 | +17.31 | 18.63 | 3.62 | 2.095 / 2.112 | 15 | 0.86 | 5.73 |
| S1_ACTIVE_JUNE_D250 | 新 | -44.86 | 46.18 | 9.23 | 0.001 / 0.000 | 11 | 1.08 | 7.71 |
| S1_ACTIVE_AUG_D250 | 新 | +80.63 | 42.66 | 6.84 | 1.575 / 1.583 | 54 | 7.52 | 8.17 |
| S1_ACTIVE_AUG_D0 | 新 | +53.21 | 49.01 | 8.14 | 1.404 / 1.408 | 52 | 8.12 | 10.02 |
| S2_RISK2_JUNE_D250 | 新 | +14.84 | 8.70 | 1.71 | 372.000 / N/A | 1 | 0.08 | 8.00 |
| S2_RISK2_AUG_D250 | 新 | +14.28 | 17.17 | 3.40 | 3.773 / 3.795 | 2 | 0.16 | 8.00 |
| S2_RISK2_AUG_D0 | 新 | +14.26 | 17.22 | 3.41 | 3.785 / 3.807 | 2 | 0.16 | 8.00 |
| S2_BE1_JUNE_D250 | 新 | +0.00 | 0.00 | 0.00 | 0.000 / N/A | 0 | 0.00 | N/A |
| S2_BE1_AUG_D250 | 新 | +0.03 | 6.01 | 1.19 | 1.750 / N/A | 1 | 0.08 | 8.00 |
| S2_BE1_AUG_D0 | 新 | +0.00 | 6.01 | 1.19 | 1.000 / N/A | 1 | 0.08 | 8.00 |
| SCALP_JUN_D250 | 新 | -63.79 | 81.35 | 15.96 | 0.560 / 0.557 | 44 | 5.59 | 12.70 |
| S1_BASE_AUG_D250 | 复用 | +45.24 | 28.04 | 4.89 | 1.638 / 1.646 | 45 | 4.79 | 9.04 |
| S1_DYNAMIC_AUG_D0 | 复用 | +55.95 | 46.27 | 7.68 | 1.435 / 1.439 | 52 | 6.47 | 8.40 |
| S1_DYNAMIC_AUG_D250 | 复用 | +73.33 | 42.07 | 6.84 | 1.597 / 1.606 | 53 | 6.56 | 8.41 |
| S2_BASE_AUG_D250 | 复用 | -3.88 | 6.63 | 1.32 | 0.000 / 0.000 | 1 | 0.08 | 8.00 |
| S2_PROGRESS_AUG_D0 | 复用 | -4.66 | 10.67 | 2.11 | 0.000 / 0.000 | 1 | 0.08 | 8.00 |
| S2_PROGRESS_AUG_D250 | 复用 | -4.63 | 10.67 | 2.11 | 0.000 / 0.000 | 1 | 0.08 | 8.00 |
| S3_BASE_AUG_D250 | 复用 | +4.57 | 12.03 | 2.33 | 1.398 / 1.401 | 6 | 0.48 | 8.00 |
| S4_BASE_AUG_D250 | 复用 | +102.03 | 33.22 | 5.59 | 1.462 / 1.464 | 56 | 5.14 | 7.67 |
| S6_BASE_AUG_D250 | 复用 | +22.02 | 16.05 | 2.98 | 2.908 / 2.942 | 10 | 0.80 | 8.00 |
| SCALP_AUGUST_DELAY250 | 复用 | +48.05 | 29.21 | 5.30 | 1.440 / 1.440 | 42 | 3.96 | 7.62 |
| S5_JUNE_DELAY250_L1000 | 复用 | +6.59 | 2.07 | 0.41 | 8.242 / 10.282 | 7 | 0.56 | 8.00 |
| S5_AUGUST_DELAY250_L1000 | 复用 | +11.53 | 6.83 | 1.36 | 2.535 / 2.604 | 11 | 0.88 | 8.00 |

Explicit costs are matched commission/swap/fees per opening standard lot. Net already includes them and realized bid/ask spread; neither is deducted twice. This is not a fully calibrated historical friction estimate. Win/loss statistics, average net outcomes and longest loss streak remain in FINAL_RESULTS.json and the native reports.

## Verification and use boundaries

S1 earns recovery time only between observed eligible healthy endpoints up to120 seconds apart. Longer gaps earn0; health/DD-eligibility loss resets credit. Restart retains the tier but discards recovery credit.86,400 eligible seconds restores only one level; original2% ceiling, old exposure accounting and10% emergency rule remain.25 embedded MQL assertions are separate from observed recovery/fault path coverage.

S2 BE uses unchanged original priceR and estimates allocated entry cost, exit cost, accrued negative swap and slippage offset. SL only tightens; old initial risk is not reduced. The inherited history-read failure boundary may leave entrycost0; normal backtests do not prove that fault path or risk-free exits.

Scalping source/defaults unchanged: M5 nearest valid supply/demand retest and closed reversal, SL/TP5.00 price units,2% single/3% aggregate open-risk budget and server-day cumulative6net wins OR6net losses. Daily lock is strategy-scoped. Native coverage for threshold/restart/partial/multi-instance/cancellation remains separately reported.

Score remains N/A / SCORE_TARGETS_UNSET with35/25/20/10/10 weights; no invented anchors. Existing I9 C# signal compilation and67 assertions are historical, not new I10 engine results. LEAN remains blocked by Windows application control0x800711C7; only existing OS logs were read, with no security bypass. Full risk/fill/exit migration and cross-engine acceptance are incomplete.

Tester GOLD margin rate1e-6 and StopOut0 are uncalibrated; nominal leverage1000 is not broker-real capacity proof. No independentOOS, double-cost stress, combined continuous account, withdrawal, Demo, Champion or live verification, and no USD1000/month proof. Observed drawdown is not a future loss bound.

MT5 folders contain paired source defaults/EX5/build logs; evidence includes matched SET/INI, native reports, scores and audits. Research use only. Do not treat seven separately tested EAs on one account as a validated portfolio. MANIFEST maps originals to portable evidence and hashes; frozen scripts still reference original workstation paths. Previous I9 recovery ZIP remains unchanged, identified in evidence/recovery.
