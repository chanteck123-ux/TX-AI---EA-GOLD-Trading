# 2026-09-06 MT5 startup update event

R_C00_Intraday_USD500_D0_20260906_190900 did not start a backtest.
The FxPro side terminal delegated startup to its LiveUpdate helper; no report
was produced. After waiting, only that task-owned stalled helper was stopped.
The eight pre-existing MetaTester cloud-agent services were not changed.

The completed initial Scalping diagnostic used terminal 6140 and recorded
zero trades, zero rejects, 100% real tick history. Its first compile binary was
not archived before a second compile; keep that limitation explicit, do not
use it as final hash-complete promotion evidence.

Subsequent runs use the other existing FxPro portable terminal. Every new build
archives its EX5; new runs record executable version/hashes and include-file
hashes. Fair comparisons must use matching recorded environments, not silently
mix results across a terminal update. A missing report is not a zero-trade result.

The alternate terminal completed the Intraday diagnostic, then also entered a
stalled LiveUpdate startup on R_C00_Swing_USD500_D0_20260906_191524. Swing has
no test result. The exact cause of the updater stall has not been established.
An attempt to stop MetaTester-1 returned access denied; none of the eight
services were stopped or reconfigured. No privilege escalation was attempted.
Only the two verified task-owned updater processes were stopped. No terminal
test process remained at the checkpoint. The user was asked to complete the
FxPro/MetaTester update locally and reply when done.

Do not retry an identical stalled launch hourly. Wait for user confirmation or
a verifiable terminal/environment change, then inspect processes and resume
the latest frozen revision. The newest reviewed source was compiled with zero
errors and zero warnings, but has not completed a backtest. Earlier R-C00
results are explicitly attributed to their earlier source and binary hashes.

Official automatic update behavior:
https://www.metatrader5.com/en/terminal/help/start_advanced/autoupdate
