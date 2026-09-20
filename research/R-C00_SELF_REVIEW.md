# R-C00 self review and red team

## Confirmed before strategy optimization

- Frozen V4.00 ZIP and MQ5 hashes match. No main/Champion edits.
- Native compiler passes; arithmetic test EA reports 25 checks, zero failures,
  plus a sweep of 770 account balances. This is not trade execution validation.
- Single-risk bypass in manual/minimum-lot legacy paths is unreachable in R-C00.
- Unknown SL/calculation/exposure fails closed. BE does not release reserved risk.
- Scalping management function has no mutation code; OnInit rejects scalp BE.
- No historical signal, SL/TP parameter or concurrent-position limit was altered.

## Review fixes before freezing the reference

- Fill Boolean alone replaced with done/partial-done and deal checks.
- Persist failure cannot populate an in-memory success cache.
- Invalid equity/requested risk checked before technical minimum calculation.
- Zero-trade explanation distinguishes disabled engines and risk-layer rejection.
- Risk-block logs rate limited to prevent tick-sized repeated log flooding.
- Build dependency hashes and binary archives added after first diagnostic.
- Startup updater handoffs and terminal executable hashes tracked explicitly.

## Still unproven / red-team objections

- Native risk arithmetic tests do not prove broker execution, restart, partial
  fills or server stop modification behavior. These need integration fixtures.
- Existing Intraday/Swing protection managers remain legacy code in R-C00;
  runner, cost-adjusted BE and comprehensive server-result checks are not done.
- Any unresolved execution freezes new entries; automated reconciliation is not
  implemented. This is fail-closed research behavior, not production readiness.
- Seven USD per lot fees and deviation-based entry buffer are estimates.
  Actual losses may exceed the plan, especially gap fills and prolonged swaps.
- Concurrent separate copies of this EA are not supported; use one combined EA.
- Scalar cached initial risk needs explicit partial-fill/restart integration
  tests before accepting its persistence behavior for a Champion.
- Disabled engines still do some legacy indicator/zone bookkeeping; no trades.
- Legacy daily/concurrent limits remain in R-C00 and may suppress opportunities;
  do not remove them inside the nearest-distance experiment.
- Historical OOS is already viewed. No untouched OOS proof and no promotion.

## Current verdict

RESEARCH FURTHER. R-C00 is a new control, not a strategy Champion.
