# I17 Scalping later cost-breakeven triggers

Two clean compilations and four native development tests completed; four strict evidence checks passed, no repair reruns. Both T35 and T40 fail the preregistered development retention rule. Keep I16 C1F/P0 and I15 C1 recovery builds. June remains negative.

Only the favorable price-move trigger changes from 2.50 to 3.50/4.00. Protected M5 supply/demand retracement and closed-bar reversal entry, requested initial SL/TP 5/5 price units, single position, Daily6, 2% single/3% portfolio risk ceilings remain unchanged. Equal 0.01 lot is conditional on risk approval, never rounded up.

Independent USD500 GOLD M5 accounts; Model4 real-tick mode, 250ms delay, tester leverage1000; June and August 2026 are already-used development months and never added. Reuse four frozen I16 controls without rerunning them.

|Month|Version|Net USD|Equity DD USD|Max relative equity DD|Native / net PF|Trades|Cost USD|
|---|---|---:|---:|---:|---:|---:|---:|
|June|C1F|−28.57|61.26|11.67%|0.64 / 0.6347|44|4.90|
|June|T35|−47.37|75.46|14.51%|0.60 / 0.5982|44|4.90|
|June|T40|−59.00|81.55|15.85%|0.56 / 0.5611|44|5.59|
|August|C1F|48.75|15.85|2.96%|1.83 / 1.8428|42|3.36|
|August|T35|48.62|15.85|2.96%|1.66 / 1.6654|42|3.36|
|August|T40|48.84|15.85|2.93%|1.62 / 1.6273|42|3.36|

Identical entry keys, entry prices, lot sizes and initial protection match all 44/42 trades across candidate and both controls. Against C1F, June T35 preserves four cut winners (+21.38) but loses eight rescues (−40.21), with a further +0.03, net −18.80. T40 preserves five winners (+26.36), loses eleven rescues (−56.75), and changes a third exit (−0.04), net −30.43. August T35 net delta −0.13; T40 +0.09. These are equal-lot exit differences, not increased-risk gains. Costs are already included in net profit.

T40 August has 26 requests, 25 confirmed and one failed. Position24 hits its original TP during the 250ms modification delay; modification returns false/retcode3 after closure. Its net profit is 5.11. Failure is recorded and not treated as an effective stop. Other three runs confirm all requests. Strict evidence PASS is not a claim of zero execution anomalies. Legacy August333/334 entry lookup is preserved; registered M5-grid check resolves334/334 with zero missing rows.

Score N/A / SCORE_TARGETS_UNSET. No OOS, new LEAN, cost stress, withdrawals, demo/live or deployment proof; S1–S6 unchanged and not retested. Complete tick timing/missed triggers, restart, partial fills, multiple instances, actual broker costs and margin remain unverified. MQ5 defaults match the report and corresponding EX5; SET overrides four audit labels only. TESTER_ONLY binaries reject non-tester use. Review and hashes accompany delivery; tools require the original frozen workspace and are not a standalone portable engine.

Further research should examine one causally available exit-persistence hypothesis rather than continue a blind trigger sweep; retain the protected entry core, preregister any new small comparison and reserve fresh validation data after freezing.
