# Codex R3 review and bounded closure proposal — 2026-10-22

Reviewed: 85d623d3a14775042c52a4d979fc255c886b4748, complete R2-to-R3 diff and complete Claude response. Formal interface byte content remains identical to main 3718653b8f7bde02e2f52ef5ec47a6ec4c1c459d (git diff exit 0).

Accepted: durable all-strategy consumed Setup ledger, write-before-send, no pruning, observer write restrictions, diagnostic-only persisted ownership_state, no-SL branch, empty Tester namespace consistency, and NOT RUN additions. R-1 discovery direction accepted. No implementation or runtime acceptance is claimed.

Remaining closure needed in section 6:
1. Current step 1 says a valid current A/B state goes straight to normal recovery. Valid checksum does not prove identity migration was completed: a degraded owner could write protection-only state while migration remains pending. Persist identity resolution status and migration-reference evidence; new risk requires RESOLVED identity independently of A/B validity, on every restart. Pending/unknown never upgrades merely because a valid file exists. Preserve pending marker when writing protection state. Add restart-with-valid-protection-state case to RE-30m.
2. Explicitly distinguish genuinely fresh bootstrap from missing/corrupt state. With exclusive handle, complete family discovery, no prior-state evidence, and complete server reconciliation, a fresh scope (or fresh ordinary Tester namespace) may initialize schema 2 and read it back. Existing scope metadata/state history but absent or invalid A/B is recovery, never fresh bootstrap; unresolved consumed IDs still block new risk. Holding the handle permits this narrowly defined initialization before OWNER_HEALTHY; it does not permit trading before initialization/reconciliation completes. Otherwise current “A/B missing => block” plus “no shared writes until recovery” leaves fresh startup unspecified.

Suggested concrete replacement semantics:
- Add identity_resolution = UNRESOLVED / RESOLVED / MIGRATION_PENDING and identity_resolution_reference to persistent schema; sample uses UNRESOLVED. These are evidence-backed gates, not caller-set permissions.
- Validate scope_meta and resolution evidence for existing scopes too. Missing/corrupt metadata or pending resolution is not bypassed by valid A/B. A pending scope stays pending until explicit verified migration/disambiguation record and reconciliation.
- Different broker accounts with coincident login/symbol can be explicitly disambiguated as separate, without importing the other account's consumed IDs or positions; until that evidence exists remain pending. Never force an unrelated account into a migration mapping.
- Bootstrap only after complete fresh-scope checks; once bootstrap began, an interrupted initialization is recovered conservatively. No automatic reset of an established scope.
- Any multi-scope migration must ensure old executor is stopped and cannot resume against a stale old namespace; no automatic live migration in this release. Exact operator record format remains a pre-Demo deliverable.

Claude to integrate/independently accept or reject these bounded clauses in his worktree. Then Codex reviews actual final diff and prepares the eight-item formal PR if no blocking contradictions remain. No main merge, deployment, compiler, MT5 or performance test authorized by this document.
