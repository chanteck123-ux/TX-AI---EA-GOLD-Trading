# R-C00: mandatory risk-normalized FxPro baseline

Status: DEVELOPMENT, not Champion. Origin: own frozen V4.00 main MQ5.
AI mode: SINGLE_AI. No third-party source copied.

## Authority override record

CN/EN governance section 29 aligns on broad ranking, but the latest explicit
user goal supersedes its older multi-broker and flexible sample/Recovery rules:
FxPro only; every engine and combined >100 complete trades; equity Recovery >3;
DD >30% rejects; 15-30% requires human review. This is an explicit override,
not an inferred CN/EN translation mismatch.

Scalping has fixed exits only. R-C00 disables its old optional BE function and
rejects a SET that enables it. The first actual Scalping optimization will be
nearest valid zone distance only; it is not included in R-C00.

## Scope and implementation

- Risk-based sizing only, per-order <=1% and aggregate <=3% current equity.
- OrderCalcProfit at actual quote plus disclosed adverse entry buffer; USD fee
  estimate 7/lot round-trip is sizing reserve only, not changed tester fees.
- Minimum lot cannot be forced. Floor broker steps; reduce to remaining budget.
- Manual/unknown exposure, pending orders, missing SL/history or unresolved
  execution results block new entries. No unprotected exposure is ignored.
- Opening order/deal history reconstructs initial per-lot risk. Persist outside
  Tester; tester starts its own state. Reserve max(initial,current SL risk) for
  remaining volume plus fee estimate and negative swap. BE does not release it.
- Actual loss may exceed planned risk on gaps, fees or slippage beyond buffer.
- Entry filters, zone choice, concurrent-position limits and other engine exits
  stay unchanged. Daily caps inherited from V4.00 remain a disclosed separate
  opportunity experiment, not silently removed in this risk-control baseline.
- Execution Boolean is not treated as proof of fill; require done/partial done
  plus a deal. Uncertain execution blocks further entries pending reconciliation.
- Real accounts explicitly disabled. This is research code, not live approval.

## Validation queue

1. Native MetaEditor compile and MQL risk-math tests.
2. Original fixed-lot evidence retained separately; all normalized runs use the
   same main-source provenance with individual lane SETs, not mixed binary hashes.
3. FxPro real-tick four-lane USD500 baseline and capital capacity diagnostics.
4. Audit event history, partial fills, persistence/restart and execution rejection.
5. S-C01 nearest zone only, versus R-C00 with identical risk parameters.
6. I-C01 runner and W-C01 later, before actual combined retest.

Historical 2026 data has already been examined and is not untouched OOS.
No new Champion package without all goal gates.
