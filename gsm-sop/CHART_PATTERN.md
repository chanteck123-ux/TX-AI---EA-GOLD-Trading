# GSM Chart Pattern SOP

## Core rule

The GSM Chart Pattern Handbook states the operating sequence as:

`Confirmation first -> Pattern second -> Price last`

Chart patterns are confirmation structures, not standalone prediction engines.

## Eight classical patterns

### Reversal family

1. Head & Shoulders
   - Bearish reversal structure.
   - Confirmation: neckline break; source examples also show break/retest continuation logic.

2. Inverse Head & Shoulders
   - Bullish reversal structure.
   - Confirmation: neckline break; source examples also show break/retest continuation logic.

3. Double Top
   - Bearish reversal.
   - Two similar peaks.
   - Confirmed when price breaks below the neckline.

4. Double Bottom
   - Bullish reversal.
   - Two similar lows.
   - Confirmed when price breaks above the neckline.

5. Rising Wedge
   - Bearish reversal tendency near an exhausted uptrend.

6. Falling Wedge
   - Bullish reversal tendency near an exhausted downtrend.

### Continuation family

7. Bull Flag
   - Bullish continuation after a strong upward impulse and a temporary consolidation/pause.

8. Bear Flag
   - Bearish continuation after a strong downward impulse and a temporary consolidation/pause.

## Context rule

The GSM summary slide groups chart patterns with market direction and location:

Bullish examples:
- Bull Flag
- Double Bottom
- Inverse Head & Shoulders
- Demand / Support Zone context

Bearish examples:
- Bear Flag
- Double Top
- Head & Shoulders
- Supply / Resistance Zone context

Therefore a recognized shape should not automatically trigger an order without confirmation and location context.

## Coding constraints

- Do not detect a pattern and immediately trade it without its confirmation condition.
- Use closed-bar/confirmed structure where required; avoid look-ahead.
- Neckline logic must be explicit for H&S / inverse H&S / double top / double bottom.
- Pattern recognition may be used as a confirmation score/module around a valid GSM setup.
- Pattern completion must be timestamp-safe in backtests; no future bars may be used to validate an earlier entry.
- GitHub chart-pattern code may be studied, but the GSM definitions remain authoritative unless the user explicitly changes them.
