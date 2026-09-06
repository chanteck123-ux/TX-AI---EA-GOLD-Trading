# Resume FxPro research

Status: APPROVED FXPRO RESEARCH IMPLEMENTATION ACTIVE; NO NEW CHAMPION.
Read this update BEFORE the historical R-C01 notes below.

2026-09-06 approved plan: USD2000 / 1:100 main; USD500 separate; FxPro only.
Research branch: research/combined/codex/fxpro-research-delivery.
Current working source: src/GSM_FxPro_RESEARCH.mq5 plus local headers.
Four R-C01 USD2000 controls and initial research-OFF runs match exactly.
S-C02 EMA OFF was actually tested: -54.56 vs +129.18 USD, 83 vs20 positions;
reject it, keep Scalping EMA ON. I-C01 removes daily cap but still only4 trades.
W-C01 daily cap removal is tested; do not invent new Swing entry rules.

I-C02 first native integration exposed opening-order-history timing failure.
Keep its +7.66/1-trade result as INVALID ENGINEERING EVIDENCE, not profitability.
See research/I-C02_ENGINEERING_FAILURE.md. A bounded recovery wait is now added.
Latest compile and RUN_CHECKPOINT identify the exact tested binary and active
queue; source alone does not identify dependencies. Reconcile processes first.
Pending: corrected runner native fixture, I_C02_FIX1 real ticks/restart,
final OFF regression, actual combined, native delays, USD500, cost sensitivity,
report/delivery hashes/GitHub. Future six-month OOS remains unobserved/PENDING.
Do not publish Champion ZIP. No actual account trading is enabled.

## Historical R-C01 checkpoint (superseded queue status)

Status then: R-C01 ENGINEERING VALIDATION COMPLETE; NO NEW CHAMPION.
All six preregistered runs and their comparisons are complete. Do not rerun them
unchanged. Read FEE_CHECKPOINT.json and RUN_CHECKPOINT.json, then check the selected
runtime process on resume. No task-owned tester job remained at this checkpoint.
Four R-C00 baselines/capacity and rejected S-C01 remain frozen.

Latest evidence:
- reports/R_C01_REPORT_CN.html and R_C01_COMPARISON.json: six verified pairs.
- reports/SCALP_OPPORTUNITY_AUDIT_CN.md and JSON: 1,195 touches reconciled;
  221 invalidated at their nominal M5 close, 974 evaluated, 205 core-qualified,
  20 final signal passes. EMA/RSI rejects overlap; do not add counters blindly.
- research/R-C01_PREREGISTRATION.md and R-C01_REVIEW.md: isolated fee correction.
- R-C01 source CCED6620 / EX5 F1F26A99: 0 errors, 0 warnings; full hashes in compile proof.
- Native fee math: 25 tests, 25,824 grid comparisons, zero failures.
- reports/R_C00_BASELINE_CN.html: four USD500 lanes plus eight Scalping capacities.
- reports/S_C01_REPORT_CN.html and S_C01_COMPARISON.json: same-capital comparison.
- research/rejected/S-C01_DISTANCE_ONLY_CN.md: no observed trading improvement.
- S-C01 is frozen; do not rerun unchanged experiments or retune the same ID.

Next research:
1. R-C01 is retained as a tested engineering correction, not a Champion. Source
   and parameters are now frozen; R-C00 remains the immutable original reference.
   Six same-capital performance/complete-trade-signature deltas are zero. Actual
   fee shortfall is zero in the 20-trade USD1000 and 20-trade USD2000 cases.
2. Before naming S-C02, read SCALP_OPPORTUNITY_AUDIT_CN.md. Seventy-three logged
   core signals fail only the EMA stage while RSI passes. A one-variable EMA
   ablation is a hypothesis, NOT proven profitable missed trades. Do not revive
   the 221 already broken zones. No S-C02 has been created or tested yet.
   USD500 affordability remains a separate constraint: current fixed SL/TP and
   1% risk cannot force minimum lots. Do not secretly raise risk or tighten SL.
3. Intraday/Swing capacity, Intraday runner, native execution/protection/restart
   fixtures, untouched OOS and realistic friction remain unfinished.
4. All four qualifying Champion lanes remain NONE. Do not create a Champion ZIP.

1. Read the latest user message and local CHECKPOINT.json. Do not resume if paused.
2. Verify the immutable V4.00 package/source and current source/include/EX5 hashes.
3. Check task-owned processes and existing reports before starting anything.
   Run scripts/Inspect-Environment.ps1 for a read-only executable/payload,
   process and service-state fingerprint. A checkpoint alone is not a live job.
   UPDATE_STILL_PENDING_NO_LIVE_TEST means there is no tester run to wait on.
   A changed fingerprint is a reason to inspect, not automatic test permission.
4. The isolated runtime in RUNTIME_CHECKPOINT.json passed a native FxPro Demo
   probe on build 6182. Read research/RUNTIME_RECOVERY.md for executable/data
   provenance. Old test copies remain unchanged and are no longer selected.
   Do not stop/reconfigure the eight existing MetaTester services or elevate.
5. Keep the completed four USD500 / 1:100 risk-normalized lanes on source
   989F19C9 and binary BB77B5D9 immutable (full hashes in compile/run evidence).
   Reconcile RUN_CHECKPOINT.json before any new launch.
   Earlier completed diagnostics used an earlier R-C00 revision and incomplete
   dependency snapshots. They are not final proof for the current binary.
6. Preserve the original fixed-lot results separately. Zero normalized trades
   do not prove a worse trading edge; the minimum-lot risk is unaffordable at
   the requested 1% budget. Do not raise risk or change SL to hide this.
7. The specified Scalping capital diagnostics and S-C01 are complete. Its only
   variable was Scalping nearest zone distance. Trade signatures at USD1000
   matched the control exactly: net64.39, DD1.57%, PF2.53, 20 trades, win75%.
   Intraday/Swing remain locked. No scalp profit protection.
8. Follow with separate native risk/execution integration tests, untouched OOS
   protocol, realistic friction, and later Intraday runner/Swing research.
9. Save every result with source, headers, EX5, SET, INI, terminal and report
   hashes. Historical viewed data cannot be relabeled untouched OOS.
10. GitHub research branch only. No main/current replacement or Champion ZIP.

R-C01 final local checks: 50 Python tests; native fee math 25 named tests plus
25,824 grid comparisons. These do not replace native protection, execution,
partial-fill or restart integration. Observed 0.01-lot fee budget is USD0.08;
currency display precision is a research-estimation input, not a tariff promise.

Rank Net -> Equity DD -> PF -> complete Trades -> Win Rate -> Reject.
DD >30% rejects; 15-30% requires review; equity recovery >3; each lane >100
complete trades; zero rejects with actual requests; positive after-cost edge;
full OOS/stress evidence required. All four new Champion lanes remain NONE.
