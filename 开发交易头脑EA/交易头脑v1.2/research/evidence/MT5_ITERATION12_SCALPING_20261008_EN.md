# I12 Scalping challenger research — 2026-10-08

Claude Code implemented two candidates; Codex reviewed, compiled and ran four native MT5 tests. Both compilations had zero errors and warnings. All four final R4 accounting, defaults, risk, daily-six and protection audits passed. Audit-only corrections preserved original failures and did not rerun or change strategy code.

Each run used an independent USD500 account, GOLD/M5, Model4, nominal leverage1:1000 and250ms execution delay. June and August2026 are previously used development data, not OOS. Neither challenger replaced the registered Daily6 parent. Existing S1–S6 research versions remain unchanged.

| Candidate | Month | Net USD | Equity DD USD | Relative equity DD % | Net PF | Complete trades | Explicit cost USD | Net change versus parent USD |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| C1 ATR initial SL/TP | June | -66.33 | 80.53 | 16.00 | 0.5262 | 31 | 4.55 | -2.54 |
| C1 ATR initial SL/TP | August | 38.19 | 29.06 | 5.27 | 1.2689 | 42 | 3.48 | -9.86 |
| C2 T0–T2 closed-bar confirmation | June | -68.91 | 110.64 | 21.03 | 0.7503 | 95 | 8.81 | -5.12 |
| C2 T0–T2 closed-bar confirmation | August | 23.75 | 28.26 | 5.25 | 1.1072 | 85 | 7.16 | -24.30 |

C1 changes initial price distance and actual dollar risk; it is not a pure signal comparison. C2 adds trades but also cost and larger June drawdown. Independent accounts cannot be added as a portfolio or continuous return. No conditional zero-delay runs were added.

Delivery is a local research supplement containing source defaults, matching EX5, MQH, SET/INI, compile logs, native reports, failed audit chain and hashes. The I11 seven-strategy ZIP remains intact. The supplement has202 members independently verified by SHA256; ZIP SHA256: ae00dc0e826aef693b437db3cb7acbc6aaeed5be1d359ab345ac71899eb1ab5a.

Score: N/A / SCORE_TARGETS_UNSET. No new candidate C# mirror or LEAN run, independent OOS, cost stress, portfolio, withdrawals, Demo or live acceptance. Restart, concurrent-instance and partial-fill fault injection remain unverified. No Champion or chart deployment. Only research documents and hashes are synchronized to this repository; EA source, EX5 and raw fills remain local.
