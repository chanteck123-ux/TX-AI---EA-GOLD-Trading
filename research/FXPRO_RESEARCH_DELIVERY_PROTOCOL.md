# FxPro research delivery protocol

Authority: user-approved implementation plan, 2026-09-06. SINGLE_AI (Codex).
Research/demo files may be delivered before acceptance; no Champion ZIP or live
approval. V4.00, R-C00, R-C01, S-C01 and their evidence remain immutable.

## Rule reconciliation

The complete CN/EN governance documents and seven gsm-sop files were read in
planning. No substantive CN/EN mismatch was found. Superseded by the latest user
mandate: dual broker -> FxPro only; variable trade-count target -> each lane >100
complete positions; recovery guideline -> equity recovery >3. Section 0's
assumption of four certified Champions is not supported by current evidence.
All four qualifying Champion lanes remain NONE. R-C01 is an engineering baseline.

## Fixed benchmark

USD2000, leverage 100, FxPro GOLD, Model 4, 2026-01-05 inclusive to 2026-08-26
exclusive. These already-viewed dates are development data, NEVER untouched OOS.
USD500 is a separate affordability diagnostic. Per-order planned risk <=1% of
equity, aggregate initial-risk budget <=3%, floor volume, include fees and pending
requests. Preserve each lane's frozen original SET except declared overrides.
No forced minimum lot, tighter SL, martingale, grid, or hidden exposure increase.

## Preregistered sequence

1. Complete R-C01 USD2000 four-lane baselines; reuse verified Scalping run.
2. S-C02: only Scalping EMA hard gate OFF. RSI, H4 regime, first touch, reversal,
   fixed 80/70 course SL/TP unchanged. Existing EMA input remains its switch.
3. I-C01: only Intraday daily trade cap 4 -> 0 (unlimited eligible opportunities).
4. I-C02: separate runner switch, compare ON/OFF on otherwise identical I-C01
   conditions. No entry changes. Closed D1/H4 existing trend logic must align.
   0.5 initial R -> confirmed cost BE -> remove TP; original TP -> legal half
   close; 2R -> closed H4 close +/- ATR(14)*2, tighten only with BE floor.
   Original R, original TP, original volume and execution state are immutable.
   Minimum-lot positions are never enlarged/split illegally. Ambiguous partial
   close requests are not blindly retried. Unknown recovery state fails closed.
5. W-C01: only Swing daily cap 2 -> 0. Keep D1/H4/M30 and existing management.
6. C-C01: actual combined research run. One position per strategy, three total,
   aggregate <=3%. No sum-of-standalone-results surrogate. No Champion label.

I-C02 is an exit experiment, not a proven GSM source rule. All other optional
indicators/AI/SMC modules remain unchanged. External sources are idea-only;
no external implementation is copied.

## Validation and verdict

Compile with actual MetaEditor; 0 errors and audit warnings. Require closed bars,
ownership isolation, floor sizing, invalid-stop handling, failure/timeout,
restart and partial-close tests. Each OFF control must reproduce its parent.
Run 0/10/25/50ms fixed delays and native Random separately, never label native
Random as 10-50ms. Run cost and parameter-neighborhood sensitivity without
selecting parameters from a purported OOS result.

Rank Net USD -> max relative equity DD -> PF -> complete positions -> win rate
-> rejects. DD>30 rejects, 15-30 requires human review. Equity recovery is net /
max monetary equity DD; native MT5 balance-recovery is separately labeled.
Require >100 complete trades per lane and genuine untouched OOS, positive
after-cost expectancy, zero broker rejects, and portfolio audit. Partial exits
are not new complete positions. Show low-sample/unknown evidence, never zero-fill
missing statistics. Large PF is a scrutiny flag, not a made-up overfit probability.

## OOS and interruption

After final code/config freeze, preregister the next complete FxPro trading day
and six calendar months of subsequent data, before looking at that period.
No early stopping by profitability. Missing/future data is PENDING, not PASS.
Do not automatically trade a live account while collecting evidence.
Checkpoint each stage and hash. On resume reconcile processes and outputs first.
Research may stop for missing future data without fabricating Champion evidence.
