# Codex independent monitor review — first pass

2026-10-12. NOT ACCEPTED YET. Claude owns source; Codex coordinates/tests.

Actual unit run: 25 tests, 2 failures, 1 skipped (symlink creation unavailable). MCP raw stdio initialize/list test passed. This is not the all-tool client verification.

Failures:
- PathPolicy.test_escape_absolute_outside_and_unknown_root_are_denied: secret_root:x returns PRIVATE_OR_CREDENTIAL_FILE rather than OUTSIDE_ALLOWED_ROOTS. Reject unknown colon prefixes/Windows ADS explicitly.
- Sources.test_baseline_then_added_modified_deleted_with_hashes: Windows normcase lowercases displayed names (algo.cs/new.cs/old.cs vs actual mixed-case names). Keep lookup normalization separate from original display path.

Required revisions:
- Route internally discovered run logs, summaries, receipt, stages and source enumeration through the same path/reparse policy; direct glob/open must not bypass it. Check ancestors, not merely final file.
- Baseline hashes must be available for a later diff. A changed mtime alone is metadata activity; distinguish content changed vs touched.
- Recent log timestamp is activity evidence, not proof an OS process remains alive. No process observation currently exists. Report unknown liveness.
- I9 has seven signal-layer sources. Inventory it accurately; do not conflate older C7 S1/S4 with I9 or complete migration.
- Explicitly report scan/output truncation. Do not imply all files tracked when caps hit.

Independent reference-source checks: seven migration-map paths exist and all seven SHA256 match listed hashes. This does not verify the proposed LEAN risk/exit semantics.

LEAN engine smoke: blocked before algorithm execution by application control 0x800711C7, QuantConnect.Messaging.dll. No Windows policy changed. No new strategy LEAN result.
