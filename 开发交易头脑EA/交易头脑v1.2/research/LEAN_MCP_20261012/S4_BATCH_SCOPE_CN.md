# S4 retained-version LEAN migration — first executable batch

2026-10-12; user requested continue, existing Claude Code + Codex mode persists. Engine probe02 now completed with official CSharp BasicTemplateFrameworkAlgorithm; probe01 remains historical blocked evidence. Do not change Windows settings.

Claude writes source, both review, Codex compiles and runs. Write new implementation under lean/algorithms/S4 and supporting registered files in this project. Reuse I9 signal sources and existing native quote/bar data; do not overwrite I9, I18 or retained MQL5/EX5.

Exact reference: outputs/TradingBrain_I11_Seven_Strategies_20261004/MT5/S4/TB500_S4_BE125/TB500_S4_BE125.mq5 (SHA256 f6abe1abc8d9cfca27e6483f344aab03110b9df11b8d1b458e3fce432d63be47; independently checked exact hash). Refer LEAN_MIGRATION_MAP.json for reference; source defaults control and must be read. Do not apply generic earlier15%/single-slot plan to this two-slot retained version.

Frozen data: August2026 FxPro native tick conversion manifest quantconnect_20260920/data/LEAN_TICK_MANIFEST.json and I9 native bars; August is already-used development, not OOS. Use original closed native bars for correct tick-volume; never count quote rows as native tick_volume. Existing August mapping UTC+3 applies only that verified period.

Budget: compile + meaningful C# fixtures; first Aug1–3 development integration smoke; then one full August baseline only if source/data/engineering checks pass. No parameter search or new strategy changes this migration batch. Capital500 USD, recorded MT5 defaults/risk/cost/slot constraints; uncalibrated cost/margin/fill assumptions labelled, never infer broker parity from nominal1000 leverage. Source defaults chosen before output.

Goal: S4 signals computed by actual C# logic; lifecycle orders, sizing, stop/target, BE1.25R, two slots/portfolio, risk-overrun management and account gates must be explicitly implemented or named missing. Do not silently feed recorded MT5 signals into trades. Indicators/source math must be checked, no same-name substitution.

Use genuine QCAlgorithm and local Lean engine. Where nativeMT5 semantics require engineering model, document and audit it; if unsupported, stop at bounded engineering state rather than claiming complete migration. Compare clocks/indicators/signals first then sizing/protection/orders/cost. Output source-bound fixtures, buildable csproj, small parameterized PS runner for Codex, migration gap log, decision/order/protection traces and RESULT.json. No Python research runner; Python only MCP monitoring/tests. No MT5/native terminal changes or Git changes by Claude.

Research stages: stage owner appends research/STAGES.jsonl with sid S4, candidate_id, run_id, status, utc, evidence. Codex invokes tools to monitor. Scores N/A / SCORE_TARGETS_UNSET; no Champion/live readiness.

When ready write S4_TOOLS_READY.json binding source hashes and self-review, Codex executes build and smoke. Claude must not execute LEAN or MT5 concurrently. Safe C# fixture compilation/self-check allowed if no terminal ownership conflict; Codex reserves actual strategy engine run.
