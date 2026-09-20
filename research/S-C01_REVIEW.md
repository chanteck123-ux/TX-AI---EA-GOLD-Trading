# S-C01 pre-backtest review

Codex SINGLE_AI. Self review and adversarial review are roles of the same agent,
not independent human/second-model approval.

## Self review

- Full-source restoration test proves that only the FindBestSDZone body,
  research version/description and the new ranking include differ from R-C00.
- Only STRATEGY_SCALPING takes the minimum-distance branch. Other strategies
  retain strict score comparison. Exact ties retain existing traversal order.
- Existing score values, eligibility, departure, touch counts, closed-bar
  construction (index >=3), active-zone latch, entry and execution remain unchanged.
- Scalping manager remains return-only; no protection path added.
- Protected V4.00 source and R-C00 source hashes unchanged.
- Native ZoneRankTests: 10 named tests, 8800 comparison cases, 0 failures.
- Local Python suite: 25 tests pass, including full-source isolation and report
  reconciliation. These are not a substitute for execution/protection integration.
- Native candidate compile: MetaEditor 6182, 0 errors, 0 warnings.

Candidate source SHA256:
1C851244DD2A321C2E44917DE8B9371F24E6A74E1E06E52AE36188245BE50F6E

Candidate EX5 SHA256:
CB66003F414FE444F4F68B0CF1876F525D3BDFBBFDD717CAB34E2232E33EE44B

Ranking header SHA256:
6867FA8AC17D44FE1D7D246467D0C3F866CA67E889D2A58F286444AA455910B9

## Red team

1. This is ranking at acquisition, not a complete continuously nearest valid
   zone SOP repair. Downstream used-zone rejection and pinned zones may dominate.
2. Selecting a different zone changes subsequent state history. Higher or lower
   trade count is a result, not proof of better opportunities.
3. No new future data or forming-candle confirmation added; however, this review
   does not certify every preexisting V4.00 indicator/pattern algorithm.
4. Legacy chart/startup text may still identify the V4.00-derived baseline.
   Actual identity is the MQ5/EX5 hash, tester expert name and run ID, not panel text.
5. The disclosed fee rounding underestimate, stop-fill gaps and missing untouched
   OOS are still unresolved. No production/Champion acceptance is allowed.
6. Both datasets were predeclared: USD500 and USD1000, same FxPro period/risks.
   Do not change parameters after viewing these results under the same ID.

Decision before performance tests: ALLOW DEVELOPMENT BACKTEST ONLY.
Promotion and real-account operation: NOT APPROVED.
