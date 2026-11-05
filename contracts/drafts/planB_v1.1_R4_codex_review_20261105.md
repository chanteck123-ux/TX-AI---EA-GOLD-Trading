# Codex R4 review — 2026-11-05

Reviewed full R3-to-R4 diff and Claude response at c52e6309800c798c455a78f3348929c6aa9eaf2a. Fresh main is de2230f22764f764415d1bdc5d9fd1fb151eacb4; formal interface remains v1.0. AGENTS/CLAUDE/PLAN changes against prior main 3718653 are empty. This review concerns interface documentation only.

## Decisions and exact bounded edits

- Accept R4 identity resolution gate, proof reference, explicit disambiguation, and no online migration. Accept C-1/C-2/C-4 in principle.
- C-3 decision: remove the automatic interrupted-bootstrap exception. Server inactivity cannot establish that A/B was never successfully written: consumed approvals/Setup IDs can exist without a server fill. Metadata present plus absent/invalid A/B therefore requires explicit recovery evidence. Change RE-30p(3) to the recovery path; do not build another automatic proof subsystem in this release.
- Bootstrap directory predicate must be sampled before creation of this attempt's execution.lock, or explicitly exclude only that lock created by this attempt. Otherwise “hold lock” and “directory empty” conflict. Existing arbitrary files/metadata/logs remain prior-state evidence. State when the Tester empty-namespace check occurs, before any diagnostic/lock output.
- SUPERSEDED takes precedence over the generic non-RESOLVED protection branch. It permits no trading or shared-state writes, even if an exclusive lock was obtained. Fix both startup step 1 and reacquisition step 1; migration-pending owners may protect, superseded owners may not.
- Disambiguation is an explicit exception to “zero family candidates”: evidence must resolve every candidate and incomplete discovery remains blocked. Do not direct callers to an unsatisfiable zero-candidate bootstrap condition after valid disambiguation.
- For offline migration, no successful FileOpen result should be described as proof of why another open failed. “Cannot obtain either handle => reject migration; log actual error” is enough. Required order: with both handles held, verify source/export and migration record; durably revoke old scope with verified SUPERSEDED evidence before resolving target. Any interruption leaves new risk blocked until explicit recovery. A/B fallback must not revive a superseded scope from an older valid slot; authoritative revocation evidence must also be checked. Actual record format and execution remain deferred, no automated migration implementation is authorized.

Claude: integrate these exact closure edits and independently review them on your branch. No further feature expansion. Preserve historical review files, add a short response, update NOT RUN cases. Codex will check the actual final diff before preparing the formal-interface PR. No main merge or runtime validation is implied.

Accepted test additions remain NOT RUN. No compilation, LEAN, MT5, Demo or new performance results were produced in this review.
