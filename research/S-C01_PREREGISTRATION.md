# S-C01: distance-only Scalping zone ranking

Status: preregistered before implementation and before any S-C01 tester results.
Source: own verified V4.00 / R-C00 source, `FindBestSDZone`; no external source copied.
Authoritative instruction: the current user-approved goal selects nearest-zone
distance as the first Scalping experiment. This is not a new indicator strategy.

## Control and observation

R-C00 source SHA256:
989F19C997F5B095A67727BF0C88492B3777F2CCF2682A02D954DBBE18CAE19A

Frozen control EX5 SHA256:
BB77B5D947614A9D1796E02E2F3382945C1FCAFD5DF68EFF1FF8D387368957EB

Four USD500 real-tick lanes have native reports and hash/SET/condition audits.
The USD1000 Scalping capacity run has 20 complete trades, net USD64.39,
native PF2.53, relative equity DD1.57%, win75%, broker rejects0. It is a
development control, NOT a qualifying Champion. Other capital runs are in progress.

Current ranking maximizes freshness + impulse strength - ATR-scaled distance.
It therefore need not select the smallest current-price distance. This mismatch
is observable in source; no claim is made that fixing ranking will improve profit.

## One variable

For `STRATEGY_SCALPING` only, among zones passing the existing builder's
eligibility, departure and freshness checks, minimize `DistanceToZone(mid, zone)`.
Keep the same current bid/ask midpoint. Distance is zero inside the zone.
Exact ties retain the first candidate encountered, with deterministic traversal.
Keep the existing quality score for downstream diagnostics/scoring.

Intraday/Swing retain old ranking and all entry/exit parameters. Keep the original
SL/TP, volume policy, risk caps, filters, session, first-touch and de-duplication.
Scalping still has no break-even, trailing, partial exit or runner.

This experiment does NOT claim to repair all nearest-zone issues. Active zones
remain latched until invalid/used; the downstream used-zone registry is unchanged.
It tests ranking at the existing selection moment, not continuous zone replacement.

## Frozen tests

Finish and audit the control Scalping capacity matrix first. Candidate tests:

1. USD500, 1:100, FxPro GOLD, M5, real ticks, Jan5-Aug26 2026, 0ms.
2. USD1000, exactly the same market/execution conditions and risk policy.
3. Only consider additional capacity or stress runs after assessing these results.

Compare each capital against its SAME-capital R-C00 run, never against the
historical USD500 fixed-lot net profit. Rank Net, Equity DD, PF, complete Trades,
Win, Reject. Report costs, BUY/SELL, signal funnels and delta.

All these dates have already been viewed. They are development data, not
untouched OOS. Even a higher net profit cannot promote S-C01 without the user's
full sample, risk, cost, OOS and stress gates.

## Known red-team constraints

- Minimum-lot affordability may still force zero USD500 trades.
- Nearest ranking may reduce opportunity capture because zone latching and the
  used registry are intentionally unchanged.
- Existing EMA/RSI/regime filters may dominate ranking effects.
- There are only 20 control trades at USD1000; a few outcomes can dominate PF.
- Native stop fills can exceed the configured deviation assumption.
- The current fee estimate can understate rounded 0.01-lot commissions by USD0.01.
  Preserve this disclosed assumption for fair comparison, but require a separate
  risk-policy correction before any production/Champion acceptance.

Verdict options: REJECT, RESEARCH_FURTHER, KEEP_CONTROL. No automatic promotion.
