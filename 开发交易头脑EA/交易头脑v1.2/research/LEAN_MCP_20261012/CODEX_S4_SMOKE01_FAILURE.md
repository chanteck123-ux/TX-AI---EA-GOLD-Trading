# S4 first actual LEAN smoke — failed reconciliation, retained
Run S4B1_SMOKE_D250_20261012T090135Z_c3a0007a: engine completes,923807ticks,8actualQCorders,4closedslots; ledger17.36USD is NOT ACCEPTED performance. quantity/fee/fill price mismatches0; maxTPVgap0.07>0.05 gate ->FAILED. No fullAugust run.

Root cause found by source: vendor/Lean/Common/Securities/SecurityHolding.cs477-508 TotalCloseProfit defaults includeFees=true, obtains estimated liquidation fees and chooses longbid/shortask. UnrealizedProfit calls it. SecurityPortfolioManager.cs455-459 adds CFDUnrealizedProfit to cash. At second entry netshort0.02, predicted liquidation fee ceil(0.02*3.5*100)/100=0.07. LEAN504.62 vs unadjusted slot-at-net-close504.69; end both517.36 with no remaining exposure.

Required: fixed source-derived LEAN net-side + estimated liquidation fee bridge. Keep MT5side/equity and LEANTPV separate; no min-of-candidate-mark selection, no looser tolerance. Add meaningful fee-convention fixture, preserve sourcehash/test/run identities, recompile and repeat same short interval. Claude owns repair.
