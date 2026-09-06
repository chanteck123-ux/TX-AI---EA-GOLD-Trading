# Resume FxPro research

Status: R-C01 FEE CORRECTION VALIDATION RUNNING.
Read FEE_CHECKPOINT.json and RUN_CHECKPOINT.json, then check the selected runtime
process before any launch. Run-FeeValidation.ps1 resumes its six preregistered
cases and reuses matching completed reports. Do not duplicate an active matrix.
Four R-C00 baselines/capacity and rejected S-C01 remain frozen.

Latest evidence:
- research/R-C01_PREREGISTRATION.md and R-C01_REVIEW.md: isolated fee correction.
- R-C01 source CCED6620 / EX5 F1F26A99: 0 errors, 0 warnings; full hashes in compile proof.
- Native fee math: 25 tests, 25,824 grid comparisons, zero failures.
- reports/R_C00_BASELINE_CN.html: four USD500 lanes plus eight Scalping capacities.
- reports/S_C01_REPORT_CN.html and S_C01_COMPARISON.json: same-capital comparison.
- research/rejected/S-C01_DISTANCE_ONLY_CN.md: no observed trading improvement.
- S-C01 is frozen; do not rerun unchanged experiments or retune the same ID.

Next research:
1. Complete the R-C01 matrix and compare_rc01.py audit before any new Candidate.
   This is an engineering correction, not strategy improvement or Champion proof.
2. Audit actual Scalping filter and first-touch events before naming S-C02. A high
   rejection counter does not prove the filtered trades would have been profitable.
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

Rank Net -> Equity DD -> PF -> complete Trades -> Win Rate -> Reject.
DD >30% rejects; 15-30% requires review; equity recovery >3; each lane >100
complete trades; zero rejects with actual requests; positive after-cost edge;
full OOS/stress evidence required. All four new Champion lanes remain NONE.
