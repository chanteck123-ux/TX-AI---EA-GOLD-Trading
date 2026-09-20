# Runtime recovery, 2026-09-06

The user confirmed update completion at this resumed turn. Inspection found
both old FxPro test copies were still build 6140. A separate installed MT5
copy already contained build 6182. The three generic MetaQuotes executables
were verified as Authenticode Valid, signed by MetaQuotes Ltd., before use.
Their original installed folder was named Tradona Markets MT5 Terminal; this
is disclosed as executable provenance, not the broker/data used for testing.

scripts/prepare_runtime.py staged those three executables in an isolated local
runtime. Only the existing FxPro-MT5 Demo history, ticks and symbol databases
were copied: 2,151 files verified byte-for-byte by SHA256. No Tradona account,
history or symbol database was used. Existing local FxPro connection records
were reused without publishing their contents. Live trading, startup experts
and DLL imports remain disabled. No old runtime or system service was changed.

The actual native probe report R_C00_UnitTests_USD500_D0_20260906_201921 identifies
FxPro Markets Ltd. / FxPro-MT5 Demo / Build 6182 / GOLD. Agent logs state
generating based on real ticks and RISK_TEST_SUMMARY Tests=25 Failures=0.
This proves the tester runs on the selected FxPro dataset, not strategy profit.

The reviewed R-C00 source remained unchanged:
989F19C997F5B095A67727BF0C88492B3777F2CCF2682A02D954DBBE18CAE19A.
It was recompiled with build 6182: 0 errors, 0 warnings.
The frozen EX5 for new baseline runs is:
BB77B5D947614A9D1796E02E2F3382945C1FCAFD5DF68EFF1FF8D387368957EB.
Do not mix these run metrics with the earlier 6140 diagnostic binaries.

Native portable-mode documentation:
https://www.metatrader5.com/en/terminal/help/start_advanced/start
