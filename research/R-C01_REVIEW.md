# R-C01 review before real-tick validation

## Self review

- Full EA text matches R-C00 after restoring research identity and risk include.
- All four fee-sensitive functions are isolated in a new risk header. Immutable
  R-C00 and rejected S-C01 file hashes are checked by automated tests.
- Scalping position manager still returns without profit protection. No entry,
  fixed SL/TP, risk percentage, daily limit or position limit is changed.
- Per-side upward rounding is an explicit estimate, not a broker tariff override.
- Maximum affordable volume is searched on the existing anchored volume grid;
  no rounding upward to the minimum lot and no increase over the linear bound.
- Fresh-quote validation recalculates the rounded fee and logs its components.
- MetaEditor 6182: 0 errors, 0 warnings. Compile archive:
  reports/compile/GSM_FxPro_R_C01_20260906_213537/COMPILE.json.
- Native FeeRiskTests: 25 tests, zero failures, 25,824 grid comparisons. Run:
  R_C01_UnitTests_USD500_D0_20260906_213344.
- 37 local Python checks passed before the strategy validation matrix.

## Red team

- ACCOUNT_CURRENCY_DIGITS is display precision, not evidence of a universal
  commission rounding rule. Reconcile against actual native deals by volume.
- Two rounded legs do not cover arbitrary partial-fill/partial-exit fees. Such
  trades remain unsupported by the complete-position cost auditor, not silently
  counted as additional complete trades.
- The 30-point adverse-price allowance is an assumption, not a stop-loss fill
  guarantee. Prior native SL fills included a larger adverse price movement.
- A passed monetary arithmetic test does not prove restart recovery, margin,
  pending-order, modification-failure or live execution integration.
- Zero trades at USD500 cannot validate actual commissions or execution rejects.
- Existing linear baseline stays frozen. Report the fee model difference even
  when parameters, final lots and trading outcomes are identical.
- All tested dates are already viewed; no untouched OOS or Champion claim.

Verdict before backtest: PROCEED_WITH_PREREGISTERED_ENGINEERING_VALIDATION_ONLY.
