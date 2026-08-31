# GSM Candlestick SOP

## Core usage sequence

The Candlestick Pattern Handbook uses this process:

1. Identify the pattern.
2. Confirm it.
3. Execute with planned entry, stop and target.

The source emphasizes that candlestick patterns matter most around Support / Resistance rather than in isolation.

## Confirmation doctrine

The handbook states that a single candle is only a hint and that confirmation should be obtained before acting.

Therefore:
- Doji / Spinning Top = weak or neutral information by themselves.
- Stronger reversal structures receive more weight when they occur at an appropriate zone and are confirmed.

## Bullish examples in the handbook

Examples include:
- Hammer
- Inverted Hammer
- Bullish Marubozu
- Bullish Engulfing
- Bullish Harami
- Piercing Line
- Tweezer Bottom
- Bullish Kicker
- Morning Star
- Morning Doji Star
- Three White Soldiers
- Three Inside Up
- Three Outside Up
- Bullish Spinning Top

## Bearish examples

Examples include:
- Hanging Man
- Shooting Star
- Bearish Marubozu
- Bearish Engulfing
- and the corresponding bearish multi-candle reversal/continuation structures listed in the handbook.

## Stop / target doctrine from the handbook

- Protective stop is placed beyond the pattern wick/invalidating structure.
- Target is planned toward the next relevant Support / Resistance area.

These are source-level candlestick guidelines. If a specific 3-SOP engine has an explicitly fixed SL/TP rule, that engine-specific rule must be documented separately and takes precedence for that engine until the user changes it.

## GSM summary-slide context

Bullish side shows:
- Doji
- Hammer
- Bullish Engulfing
- Demand / Support Zone

Bearish side shows:
- Doji
- bearish upper-wick / inverted-hammer-style rejection context
- Bearish Engulfing
- Supply / Resistance Zone

The detailed handbook treats Doji as indecision, so Doji must not independently determine BUY or SELL direction.

## Coding constraints

- Use completed candles for confirmed pattern logic unless an engine SOP explicitly requires intra-bar detection.
- Do not use future candles in backtests.
- Pattern strength, zone location and confirmation should be separately loggable.
- Candlestick logic is not allowed to open a trade solely because a shape appears in the middle of the chart.
- GitHub candle engines may help implementation quality, but must not redefine the GSM pattern meaning without explicit approval.
