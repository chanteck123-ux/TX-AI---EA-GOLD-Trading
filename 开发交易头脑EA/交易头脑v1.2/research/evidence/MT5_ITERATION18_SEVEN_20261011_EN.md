# I18 seven-strategy research delivery

Delivery review: 2026-10-12, Asia/Kuala_Lumpur. Original compilation and native runs: 2026-10-11.

Claude Code authored seven candidates and execution tools. Codex reviewed, compiled and executed all fourteen native tests. All seven compiles produced zero errors and warnings; version/default/250 ms delay/accounting checks passed for all fourteen runs. Claude recomputed the reports and Codex reviewed the findings; this was not a blind third-party audit.

Each run used an independent USD500 GOLD M5 account, real-tick mode 4, nominal tester leverage 1:1000 and 250 ms delay. June and August 2026 are previously used development data and their profits are not added. Risk caps remain S1/S3/S5/S6 1%, S2/S4/Scalping 2%, original portfolio budget 3%.

| Strategy | June baseline → candidate net USD | August baseline → candidate net USD | Decision |
|---|---:|---:|---|
| S1 | 49.42 → 57.50 | 45.24 → 13.69 | Keep baseline |
| S2 | 14.84 → 14.84 | 19.40 → 19.40 | No improvement; keep baseline |
| S3 | 7.03 → -7.53 | 4.57 → -0.94 | Keep baseline |
| S4 | 66.14 → 70.89 | 102.03 → 45.35 | Keep original 1.25R |
| S5 | 6.59 → -1.47 | 11.53 → 11.30 | Keep first-bar progress check |
| S6 | 17.31 → 8.74 | 22.02 → 28.65 | Keep baseline |
| Scalping | -28.57 → -22.60 | 58.98 → 68.49 | Retain SPREAD20 as development best candidate only |

Scalping drawdown is 55.29 / 17.52 USD, versus 61.26 / 17.52; relative drawdown 10.54% / 3.05%, versus 11.67% / 3.10%. Recorded costs decrease by 1.86 / 0.26 USD. The protected M5 supply/demand retest and closed-bar reversal SOP, initial brackets and 2% risk cap are unchanged. Twenty MT5 Points correspond to a 0.20 quote-price difference under the observed Point=0.01 specification, not a USD tick value.

June improvement comes from six omitted trades totalling -5.97 USD, including avoided overnight charges; all remaining 38 trades match. August omits four trades totalling -5.48 USD and two subsequent automatic-size changes contribute a descriptive +4.03 USD difference. The latter is approximately 42.4% of +9.51, correcting the 'more than half' phrase in the Claude review. Spread and server-night-time overlap; a spread-only causal claim is unsupported. Daily6 did not reach its locking threshold, so threshold-stop and next-day recovery remain untested, although counts can change after filtering.

S6 logged seven/six first ATR evaluations, zero protective proposals/confirmations, with distance 13.5–26.4R. Its results do not demonstrate effective trailing. S2 native PF uses deal-level opening commissions; complete-position net PF has no loss denominator. EA over-budget exits are not broker Stop Out. Missing error files indicate no records rather than independently established zero errors. Recorded costs are matched commissions, swaps and fees; bid/ask effects already in fills are not deducted again.

Current retained MQ5/EX5 versions and compile logs are under MT5_Current_Research. All challengers, baseline recovery builds, matching native evidence, six embedded indicator source/binary pairs and hashes are retained. Score is N/A / SCORE_TARGETS_UNSET. This batch used seven main compiles, fourteen 250 ms runs, zero engineering repairs and zero 0 ms diagnostics. Cost stress, independent OOS, portfolio/withdrawals, LEAN parity, version-specific demo and live validation are not completed. June Scalping still loses money; no Champion, deployment or USD1000 monthly-profit claim is made.

Next research directions are evidence-based: revisit S1's overly strict slope gate; diagnose S2 downstream location/progress gates; check S3 breakout validity during pullback; retain S4 1.25R while testing exits separately; retain S5 early failure exit; register a trailing scale compatible with S6's initial risk; separate Scalping spread/time effects and perform independent validation. These additional changes/tests were not executed in I18.
