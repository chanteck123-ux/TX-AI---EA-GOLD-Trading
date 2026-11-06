# Codex review of Claude R2 — 2026-10-21

Status: CHANGES_REQUESTED; no formal-interface promotion.
Reviewed commit: fd5d27b417ff7181fea16526627f1be42395d2f6.
Reviewed files: risk_execution_interface_v1.1_draft.md (changed sections and surrounding lifecycle/persistence clauses); planB_v1.1_resolution_claude_review_20261021.md (full).
Remote main verified: 3718653b8f7bde02e2f52ef5ec47a6ec4c1c459d. Integration cherry-pick: 33b6e5b. Formal v1.0 unchanged.

## Accepted
X1–X9 integration direction accepted. D-1 through D-5 accepted in principle: ownership uncertainty cannot authorize trading, comment is only an unresolved-identity clue, diagnostic heartbeat names, stable in-flight key, schema 2 and separate heartbeat are appropriate. This is a document review, not native validation.

## Required before formal PR
1. R-1 is explicitly due before the formal PR, but remains only a deferred note. Add a concrete fail-closed migration rule for a changed server identity: discover possible prior scopes using project/login/symbol identity metadata; ambiguous matches block new risk, never silently merge unrelated brokerage accounts sharing a login. Corrupt/unreadable metadata cannot prove a fresh account. Migration needs explicit old/new identity mapping and reconciliation; no automatic transfer of ownership. Add a NOT RUN case. A server rename must not silently reset daily lock or approvals.
2. Section 3.1 rejects already-consumed setup_id, but schema 2 persists only active_setups, consumed approvals and S7 daily counted IDs. A terminal S1–S6 Setup can disappear from active_setups, then be submitted again with a new approval after restart. Require durable consumed_setup_ids (all seven strategies) or equivalent durable terminal ledger, written before the initial submission with approval/in-flight intent, retained across restart/day change. No pruning until a separately specified safe retention policy proves replay impossible. Add a restart/new-approval/same-Setup rejection case. S7 daily count IDs cannot substitute for global Setup deduplication.
3. Make state mutation authority explicit: observers and OWNERSHIP_UNCERTAIN instances must not write shared A/B state, holder heartbeat, consumed IDs or execution queues; diagnostic logs must be per-instance. Persisted ownership_state is diagnostic only and must never restore OWNER_HEALTHY at startup. Every load starts with authority unproven until fresh exclusive acquisition and reconciliation. Add a second-instance state-immutability case.

## Clarifications to fold into the same edit
- Scope all protection/cancel/exit wording and matrix expectations to the current exclusive owner; observers remain read-only even when a daily lock or missing SL is detected.
- No-SL supplementation must treat the absent SL as a distinct case before BUY/SELL monotonic comparisons (SELL desired SL <= zero is not valid logic).
- Section 6.1 rejects existing state/completion markers; RE-27 currently rejects any existing directory. Choose one consistent rule including runner-created empty directories.
- The review claims 39 new subcases for RE-28–31, which is correct (3+6+12+18); do not describe RE-29–31 alone as 39.

Owner: Claude updates draft/review in independent worktree; Codex reviews actual next commit. No trading implementation, compile, MT5, new performance result, PR or main merge in this review. Existing G4 platform probe is not RE-30 acceptance.
