# Resume FxPro research

Status: RESEARCH DELIVERY VERIFIED 2026-09-07; NO NEW CHAMPION.
Read this update BEFORE the historical R-C01 notes below.

2026-09-06 approved plan: USD2000 / 1:100 main; USD500 separate; FxPro only.
Research branch: research/combined/codex/fxpro-research-delivery.
Current working source: src/GSM_FxPro_RESEARCH.mq5 plus local headers.
Four R-C01 USD2000 controls and initial research-OFF runs match exactly.
S-C02 EMA OFF was actually tested: -54.56 vs +129.18 USD, 83 vs20 positions;
reject it, keep Scalping EMA ON. I-C01 removes daily cap but still only4 trades.
W-C01 daily cap removal is tested; do not invent new Swing entry rules.

Latest code commit: 8326fbab6ee8beb2a0db77aa1f1663e08c4bff41, draft PR #5.
MQ5: 554B61976A0B04A152C22B33767D264D4B42925B02375702BF69608326946185.
EX5: 4CAE44BD57FCF18BE6206741DD0FA5BBD130C6AEB03A2D94C99A645F2200106A.
Real compile 0 errors / 0 warnings. Native runner rules20020 / integration24
checks pass; integration uses real header but mocked server faults. Python76 pass.

I-C02 initial and wait-only FIX1 failed. Actual native probe proved the root
cause: HistoryOrderSelect is required before reading the opening SL/TP.
Keep failed +7.66/1-trade evidence, never rank it as valid strategy performance.
FIX2 recovered all4 positions; net21.50 vs OFF28.66, no promotion. Memory restart
probe exactly reproduces FIX2; not an OS-level crash/restart test.
Final OFF four lanes also match R-C01 trade paths exactly.
C-C01 actual combined net151.34 vs158.50 at0ms. All fixed10/25/50 and native random
paired combined runs finished; candidates remain below controls with25 trades.
All 6 core and 17 stress-matrix cases completed. There are37 indexed development
records including preserved invalid engineering runs, not37 promotion passes.
USD500 all four lanes have zero fills: minimum lots exceed the1% budget.
USD5000 runner:100.48 vs control114.80,4 complete positions, one actual .04->.02
partial close with retcode10009. Normal partial exit verified, broker faults not.
ATR1.8/2.2 reproduce2.0 exactly; max recorded MFE is only about0.61 initialR,
so this is NOT evidence of an effective2R trailing stability test.
Native queue session80357 ended with exit0; no task-owned terminal/editor remains.
Always recheck processes and latest user instruction before any later launch.

Verified delivery: outputs/FXPRO_DELIVERY/FINAL_REPORT_CN.html.
768 files /121 local links passed; desktop1440 and mobile390 Playwright checks
and screenshot inspection passed. Source/EX5 unchanged. Exact SHA256 manifest:
443B4753137DE6B8D6865CBFD5D82B05D74F378A240D63CA701EC56EC1A6C43F.
ReportSHA256:2318BE3BEC985F54902DECE813B920CD78F8EFB19839229B23694F5CB353145F.
Verify read-only with scripts/build_study_delivery.py --verify-only
--output outputs/FXPRO_DELIVERY. Never overwrite this verified delivery.
Three other output directories are marked INCOMPLETE_DO_NOT_USE after packaging
path/link failures. Cleanup was policy-blocked; they are not delivery artifacts.
All required current matrices, audits and config exports are complete. Do not
rerun unchanged cases. GitHub stores research sources/configs/summaries only;
raw local evidence and EX5 are in the verified directory. No Champion ZIP.
Report-build scripts do not alter the frozen MQ5/MQH/EX5. Unfinished acceptance:
futureOOS/sample gates, native changed costs, OS restart and real broker fault
tests, concurrent portfolio tick-equity/margin audit. All Champion lanes NONE.

OOS rules and exact parameters are frozen in OOS_PREREGISTRATION.json. Appended
OOS_CALENDAR_CONFIRMATION.json confirms FxPro GOLD Sep7 early close20:25 and
Sep8 normal calendar. Official OOS [2026.09.08,2027.03.08), server dates.
No future quote/return data viewed; no live execution. Preserve original registry
and add any future calendar correction as evidence, never choose dates by profit.

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
