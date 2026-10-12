# Codex S4 source review notes — 2026-10-12

Read actual MQL5 defaults, RiskGate, PortfolioSnapshot, UpdateAccountGuard, ManagePositions and OnTick; read C7 Scan4/Emit/Gate and historical fullmonth signal parity report. This is partial source review, not a complete audit of all180446 bytes.

- S4 zero-based sid3. Native sid4 exclusion in ManagePositions refers S5, not S4.
- S4 target is1.5R (RiskGate rr=s.sid==3?1.5:2), not2R.
- Adverse chase check is directional dir*(entry-ref)>0.25ATR, favorable pullback allowed; other engines use absolute difference.
- Initial risk uses min(balance,equity) for budget. entry stress adds dir*2ticks and stop stress subtracts dir*2ticks; per-lot cost allowance=10+5=15USD. Actual fee ledger distinct from sizing allowance; no duplicate spread deduction.
- Portfolio initial risk is recomputed from each current accepted SL with1-side exit stress + cost allowance, not blindly original nominal risk; equity risk uses current close-side unrealized-to-SL loss +cost. Match actual source before generalizing user architecture rules.
- Native day loss resets by mapped UTC day, not FxPro server day. ScalpingDaily6 uses server day but is not this S4 gate.
- Management precedes scanning/new-risk gates. Emergency exit cancels pending and closes; daily lock blocks new entries, existing management continues.
- BE uses initial entry/SL price distance; remaining-volume proportional actual entry charges + estimated exit charge 5USD/lot + negative accrued swap +2ticks slippage, rounded protectively. Stop only tightens; server acceptance matters.
- Historical C7 fullmonth S4 quote mismatch example: same-ms exportedbid4052.89 vs native planned4052.69 changed calculatedTP by0.50 and reversed SL vsTP outcome. These historical runs had30000 capital, not current500. Preserve as model difference evidence; never copy original prices into research or claim profit delta strategy improvement.
- LEAN one-symbol net holdings != MT5 hedging slot lifecycle; require per-slot audit and honest netting-model limitation; core ledger should tie QC engine orders/fills to slot events rather than showing pseudo orders while engine portfolio flat.

Data recheck: 26 tick ZIPs and6native bar files match existing manifests;20,513,403declared August rows. Hash recheck only, not independent new row quality audit. August previously useddevelopment, notOOS.
