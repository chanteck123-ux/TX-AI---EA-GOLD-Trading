# I16 Scalping native equal-volume diagnosis

Two sources compiled with zero errors/warnings. Four main native tests and four strict verifications passed; no repair reruns. Claude authored candidates/tools; Codex reviewed, froze, compiled, executed and verified.

At 0.01 lots per trade, dynamic cost break-even improves June by USD35.22 but reduces August by USD10.27. June remains negative. This is a diagnosis, with no promotion rule or deployed-version change.

| Month | Exit | Net USD | Equity DD USD | Maximum relative equity DD | Native PF / net PF | Complete trades | Costs USD |
|---|---|---:|---:|---:|---:|---:|---:|
| June | Original P0 | -63.79 | 81.35 | 15.96% | .56 / .5574 | 44 | 5.59 |
| June | Cost BE C1F | -28.57 | 61.26 | 11.67% | .64 / .6347 | 44 | 4.90 |
| August | Original P0 | +59.02 | 15.85 | 2.90% | 1.75 / 1.7587 | 42 | 3.36 |
| August | Cost BE C1F | +48.75 | 15.85 | 2.96% | 1.83 / 1.8428 | 42 | 3.36 |

Conditions: independent USD500 accounts, GOLD M5, Model4 real-tick mode, 250ms, tester leverage1:1000; June2026.06.01–07.01 and August08.01–09.01. Previously used development data, not OOS; results are not added. Single/portfolio risk ceilings2%/3%, single position, original entry, requested initial SL/TP price distances5/5 and Daily6 retained. Each actual fill is0.01; an insufficient automatic risk budget rejects rather than rounds volume up. Score N/A SCORE_TARGETS_UNSET.

All44/42 monthly entries match by zone/time/direction, with identical entry and initial protection levels and no unmatched trades. Exits differ on19/10 trades. June equity DD fallsUSD20.09 and4.29percentage points; August USD DD is unchanged and relative DD rises.06points. Costs already included in net, not deducted again; June costs fallUSD.69 through swap, August costs are equal. Costs per matched round-trip standard lot: JuneP0 12.7045/C1F11.1364, August both8.0000USD.

Original automatic-sizing August netUSD48.05 becomesUSD59.02 at fixed volume; I15C1 automaticUSD58.98 becomesUSD48.75. The matched entries/exits support a meaningful account-sizing-path contribution, rather than an unconditional exit improvement. Fixed volume is a diagnostic, not a deployed sizing recommendation.

All four native captures are complete and configuration restoration was verified. Registered closed-M5-grid checks cover358/358June and334/334August rows; I15's original333/334 record remains unchanged. One first-pass tool test failed under a continuously relocking scanner fixture; the failed record was kept, the fixture changed to controlled brief/persistent locks, and only affected checks rerun. The39-check aggregate links unchanged results. Production retry policy was not widened.

Limits: repeated development data, no promotion; no unused OOS, cost stress, extra0ms, LEAN, Demo or live tests. Logged protection updates and native ledger checks do not establish full tick timing, restart, multiple instances or partial fills. Real-tick mode/History Quality does not independently establish tick coverage. Actual broker costs/margin remain uncalibrated. S1–S6 unchanged/unretested. Default MQ5, matching EX5, SET/INI, logs, reports and attempt ledgers are retained; candidates remain TESTER_ONLY.

Next hypothesis: a later cost-BE trigger may reduce prematurely cut August winners. Register a separate small comparison before changes, preserve the2.50trigger recovery point, and do not switch rules by known month or increase risk to hide June losses.
