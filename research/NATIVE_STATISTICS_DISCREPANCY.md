# Native recovery definition discrepancy

SPEC_MISMATCH: reference definition versus observed terminal statistic, NOT a
CN/EN governance translation mismatch. Preserve all evidence and do not rewrite
native values to match a formula.

MQL5 official statistics documentation (read 2026-09-06) defines
STAT_RECOVERY_FACTOR as STAT_PROFIT / STAT_BALANCE_DD:
https://www.mql5.com/en/docs/constants/environment_state/statistics

Observed FxPro MT5 build6182 CONTROL_Swing_USD2000_D0_20260906_225700:
native net=0.66; maximum balance DD=0.04; maximum equity DD=47.62.
Native HTML recovery=0.01; OnTester STAT_RECOVERY_FACTOR=0.013859722805543854.
This matches net/equityDD (about0.01386), NOT net/balanceDD (about16.5).
The report adapter must label it NativeRecovery, preserve the raw CSV's legacy
NativeBalanceRecovery key, and show independently calculated balance/equity
ratios. Do not infer undocumented engine behavior as a general MT5 rule.

The project's promotion gate remains independently calculated equity recovery>3.
This sample fails that gate regardless of the native discrepancy. Flag
NATIVE_RECOVERY_DEFINITION_MISMATCH and BALANCE_EQUITY_DIVERGENCE_REVIEW.
No claim that balance DD proves a low-floating-risk strategy.
