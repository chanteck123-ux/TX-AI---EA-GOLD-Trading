# R-C01: currency-precision fee reservation

Status: preregistered risk-control correction. This is not a strategy optimization
or a Champion promotion. Based on R-C00, not the rejected S-C01 ranking change.

## Evidence and hypothesis

R-C00 USD1000 Scalping has 20 reconciled complete positions. Actual entry and
exit commissions were USD0.04 each at 0.01 lot; the linear USD7-per-lot roundtrip
estimate reserved USD0.07 instead of USD0.08. The difference also affects the
minimum-equity arithmetic boundary. R-C00 and its headers remain immutable.

Hypothesis: a separately rounded fee estimate for each side removes this observed
under-reservation while leaving all trading SOPs, SL/TP and risk percentages fixed.
The report must distinguish ENGINEERING_CORRECTION from strategy improvement.

## Model

- Read ACCOUNT_CURRENCY_DIGITS at runtime; do not assume every account uses cents.
- Estimated fee = twice the per-side fee rounded upward to the currency quantum.
- This is a conservative research assumption, NOT a claim that the broker always
  charges by this rule. The official property describes display precision, not
  the broker's commission tariff.
- Source: https://www.mql5.com/en/docs/constants/environment_state/accountinformation
- Snap only floating-point noise at positive integer boundaries; do not erase
  genuinely positive tiny fee estimates.
- Use the rounded amount both for new-order planning and open-position risk
  reservation. Never release initial-risk reservation merely because SL is at BE.
- Recalculate after the fresh quote/equity check. Floor lots; if min lot is too
  expensive, skip. A monotonic grid search handles nonlinear currency rounding.
- Retain 1% single / 3% aggregate caps. No changes to strategy or position limits.
- Partial fills/partial exits and actual changing broker fees remain separately
  audited; two rounded sides cannot guarantee coverage of arbitrary split fees.

## Frozen validation plan

1. Native arithmetic tests: 0.01-lot USD0.08, 0.02-lot USD0.14; invalid precision,
   zero and tiny fees, step alignment, monotonicity, no upsize, budget boundaries,
   aggregate exhaustion and retained risk after BE/partial volume.
2. Verify the USD837 old minimum boundary now rejects and USD838 passes for
   price-risk USD830 per lot plus rounded fees. This is technical arithmetic,
   not a funding recommendation or proof of strategy performance.
3. Full-source isolation: only research identity/include differs from R-C00;
   new risk header changes only fee-sensitive sizing/reservation/validation.
4. Actual MetaEditor 6182 compile, 0 errors; inspect all warnings.
5. Native FxPro real-tick Jan5-Aug26 2026, 1:100, 0ms: four USD500 lanes, plus
   Scalping USD1000 and USD2000 to exercise filled orders and exact-cent fees.
6. Compare SAME-capital R-C00 runs, same SET/INI except expert/output identities.
   Record the explicitly changed fee model, not falsely call its risk arithmetic
   identical. Commission charged by the tester must not be changed.

All historical dates have been viewed. No untouched OOS claim. No Champion ZIP.
Success means the known fee shortfall is absent in the tested cases and no
regression appears in isolated strategy logic or tested risk boundaries.
