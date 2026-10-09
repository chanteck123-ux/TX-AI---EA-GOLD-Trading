# I13 Scalping background-gate research report (C1 H4 alignment, C2 ADX adverse exclusion)

## Conclusion (from formal proofs, not a trading recommendation)

- C1_H4_ALIGN: net USD is not above the parent in both development months (June 43.41, August -13.35); **not replaced, the parent is kept**.
- C2_ADX_ADVERSE_R1: net USD is not above the parent in both development months (June 14.70, August -14.57); **not replaced, the parent is kept**.

Scope: GOLD M5, real-tick model 4, 500 USD, leverage 1:1000, 250 ms execution delay. June and August 2026 are **already-used development months, not out-of-sample**; the two monthly accounts are independent and are not summed. The fixed score policy is N/A (SCORE_TARGETS_UNSET). The comparison uses only the parent's formal verification accounts (I10 June, I9 August); no "parent-trade subset blocked by the gate" is a result and none is used here.

## 1. Month by month against the parent (all from formal proofs)

| Candidate | Month | Parent net USD | Candidate net USD | Delta | Parent trades | Candidate trades | Parent PF | Candidate PF |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| C1_H4_ALIGN | JUNE | -63.79 | -20.38 | 43.41 | 44 | 16 | 0.56 | 0.60 |
| C2_ADX_ADVERSE_R1 | JUNE | -63.79 | -49.09 | 14.70 | 44 | 39 | 0.56 | 0.61 |
| C1_H4_ALIGN | AUGUST | 48.05 | 34.70 | -13.35 | 42 | 23 | 1.44 | 1.83 |
| C2_ADX_ADVERSE_R1 | AUGUST | 48.05 | 33.48 | -14.57 | 42 | 37 | 1.44 | 1.40 |

Note: the native test of the C2_R1 June run finished completely (23,679,824 ticks / 6,023 bars, Test passed), but the runner wrapper reported JOURNAL_ROTATED while saving logs because MT5 rotated the agent log automatically. Codex recovered all artifacts without a rerun and a dedicated recovered-audit verifier issued a separate formal proof; the original FAILED receipt is preserved unchanged and this run is not an original-runner success.

| Candidate | Month | Parent equity DD USD (%) | Candidate equity DD USD (%) | Parent cost per round-trip lot | Candidate cost per round-trip lot | Parent net expectancy/trade | Candidate net expectancy/trade |
|---|---|---:|---:|---:|---:|---:|---:|
| C1_H4_ALIGN | JUNE | 81.35 (15.96%) | 31.29 (6.12%) | 12.70 | 8.00 | -1.45 | -1.27 |
| C2_ADX_ADVERSE_R1 | JUNE | 81.35 (15.96%) | 62.55 (12.37%) | 12.70 | 13.31 | -1.45 | -1.26 |
| C1_H4_ALIGN | AUGUST | 29.21 (5.30%) | 13.94 (2.74%) | 7.62 | 8.00 | 1.14 | 1.51 |
| C2_ADX_ADVERSE_R1 | AUGUST | 29.21 (5.30%) | 15.59 (2.87%) | 7.62 | 7.90 | 1.14 | 0.90 |

## 2. The three stages of a gate (release is not a request and a request is not a fill)

| Candidate | Month | Evaluated | Released | Rejected | Unavailable | Rejected by later gates after release | Orders prepared | Requests accepted | Server fills (complete trades) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| C1_H4_ALIGN | JUNE | 46 | 17 | 29 | 0 | 1 | 16 | 16 | 16 |
| C2_ADX_ADVERSE_R1 | JUNE | 46 | 40 | 6 | 0 | 1 | 39 | 39 | 39 |
| C1_H4_ALIGN | AUGUST | 43 | 23 | 20 | 0 | 0 | 23 | 23 | 23 |
| C2_ADX_ADVERSE_R1 | AUGUST | 43 | 38 | 5 | 0 | 1 | 37 | 37 | 37 |

A first touch rejected by a gate is still consumed (parent semantics), so a gate changes the whole later signal sequence; it is not a simple deletion of some trades.

## 3. Honest account of the interface failure

The original C2 failed to initialise the library indicator `GSM_ADX_Trend_Meter` (the journal repeats "algorithm enum invalid"). **Both reviews, Claude's and Codex's, missed the rule in the library document**: with explicit `iCustom` parameters every `input group` occupies a string positional slot (from line 143 of the document; slot 0 is the algorithm group, ADXMethod is slot 1). The frozen C2 passed `(0,14)`, so `14` landed in ADXMethod. This cause comes from the library document and the indicator source; the **native proof** for the repaired version is the indicator's own journal line `GSM_ADX_INIT | GOLD M5 | method=0 period=14`. The original C2 June attempt produced no strategy metric and is used in no comparison; it then failed again while copying a ~2.7 GB agent journal into memory, and the full raw journal is archived with hashes.

Repaired version proof: 1 library init line(s), method=0, period=14, status LIBRARY_INSTANCE_INITIALISED_WITH_WILDER_14.

## 4. What is not proven

- Both development months were already used; no out-of-sample, independent validation, Demo, Champion or deployment.
- LEAN for the I13 candidates is **pending**: no candidate signal mirror in LEAN and no new LEAN run; the old Windows application-control block was not bypassed.
- Strict single-entry/single-exit grouping, partial fills unsupported; restart, multi-instance and asynchronous transactions not tested.
- Costs and margin are uncalibrated; the score is N/A.
- The Node Wilder ADX / H4 EMA replicas are diagnostics, not proof of library values or broker H4; the audit of record is the buffer values the EA logged at every decision.

## 5. C# offline mirror (NOT_LEAN)

Label OFFLINE_CSHARP_MIRROR_NOT_LEAN; inputs are the MT5-exported bars and the EA's I13_GATE journal, **not inputs generated by the mirror**.
- C1_JUNE (C1_H4_EMA50_200): EQUAL_WITHIN_DECLARED_TOLERANCE (46 decisions compared, max difference 4.983121471013874E-09, decision flips 0)
- C1_AUGUST (C1_H4_EMA50_200): EQUAL_WITHIN_DECLARED_TOLERANCE (43 decisions compared, max difference 4.977664502803236E-09, decision flips 0)
- C2_JUNE (C2_ADX_M5_WILDER14): EQUAL_WITHIN_DECLARED_TOLERANCE (46 decisions compared, max difference 4.955785115612343E-09, decision flips 0)
- C2_AUGUST (C2_ADX_M5_WILDER14): EQUAL_WITHIN_DECLARED_TOLERANCE (43 decisions compared, max difference 4.986233648196503E-09, decision flips 0)
A status of NOT_PROVEN_EQUAL means the actual difference exceeded the pre-declared tolerance or a decision flipped; it is reported as found.

## 6. Evidence chain

- Comparison data: `COMPARISON_I13_VS_PARENT.json` sha256 `4adc8fe2eaca18f97c00e1466a32c92d5a3ef889af1223886d32f262c553b58c`
- C1_H4_ALIGN JUNE: proof `VERIFICATION_C1_JUNE_DELAY250.json` `e543deb459c9f9557a84d5cd5087264cd302ea7252fd21f2f387d033b40556a4`; parent proof `9bb69ad4047eb273866c45a3b6925c94f0355d536a1afb6e5bc7b386808afc52`
- C2_ADX_ADVERSE_R1 JUNE: proof `RECOVERED_VERIFICATION_C2_JUNE_DELAY250_REPAIR1.json` `ce9259bb5c280967dd4b190ebda54f3170a4cb0f905933c12a59b9ebb596a2a5`; parent proof `9bb69ad4047eb273866c45a3b6925c94f0355d536a1afb6e5bc7b386808afc52`
- C1_H4_ALIGN AUGUST: proof `VERIFICATION_C1_AUGUST_DELAY250.json` `f39f7cd5b73bd02e98d69d77f2431005ff562ec28e9abb742c5850de28dceef6`; parent proof `d9c3cd283cc22a2683337d15955d8c617f008d1ab28269ef305d3dd5cf89bcd8`
- C2_ADX_ADVERSE_R1 AUGUST: proof `VERIFICATION_C2_AUGUST_DELAY250.json` `77bfc843dcd56d58e7e33ac82f75d07b1e7290e87cd197689962d3efde2f716e`; parent proof `d9c3cd283cc22a2683337d15955d8c617f008d1ab28269ef305d3dd5cf89bcd8`
- Shared attempt ledger: 5 of 8 used; failures are not reset.
