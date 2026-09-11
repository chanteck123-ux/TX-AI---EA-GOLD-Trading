# I-C02 first integration: recovery timing failure

Run: I_C02_Intraday_USD2000_D0_20260906_230430.
Frozen source SHA256: 07DACCB7B8F6E4A8A32A43B9FD573DE91278EED808925B868C20D594DF590528.
Real FxPro tick evidence: first entry at 2026.04.08 21:18:45 had broker-confirmed
SL4708.16, TP4727.16, volume0.01. Immediate history-based initial-risk lookup was
not ready. Runner recovery incorrectly latched permanent fail-closed state.
Native result +7.66 USD, 1 complete position is NOT valid strategy comparison.
Diagnostic: RUNNER_RECOVERY_FAILED_CLOSED, EXECUTION_UNRESOLVED_RECONCILIATION_REQUIRED.

Root cause hypothesis: opening order history is not necessarily ready in the
same transaction/tick as the new position. Keep server SL/TP untouched, allow a
bounded new-position synchronization wait, and still fail closed on persistent
or pre-existing inconsistent state. Never reconstruct initial R from moved SL.
This is an engineering correction, not tuning a profitability threshold.

## Corrected diagnosis from a native probe

The wait-only FIX1 did NOT repair the failure. Do not present the timing
hypothesis above as established cause. OpeningHistoryProbe, 2026-09-06 23:20,
demonstrated HistorySelectByPosition succeeds, yet HistoryOrderGetDouble returns
false/error4754. Explicit HistoryOrderSelect immediately returns the correct
SL/TP, both on the entry tick and at test end. The same missing selection exists
in the frozen R-C01 risk-recovery header. The research copy now explicitly
selects the opening order in BOTH runner recovery and initial-risk reservation.

R-C01 is NOT changed. Re-run all four OFF controls using the corrected research
binary. Any differences must be labeled engineering/control changes, not runner
alpha. Test the runner against this corrected OFF control before making a
performance claim. No risk or position cap was increased. The 5-second bounded
wait remains as protection against genuinely delayed history, not as the fix.
The native mock now requires explicit opening-order selection, matching the
observed API precondition, so this regression can no longer pass silently.

Retain this run and source snapshot. Retest as I_C02_FIX1 after new compile and
native regression fixture, with the exact same market/risk parameters.
OOS has not been used. No Champion promotion. Mock-only tests did not expose
the asynchronous opening-history delay; add that fault to the fixture.
