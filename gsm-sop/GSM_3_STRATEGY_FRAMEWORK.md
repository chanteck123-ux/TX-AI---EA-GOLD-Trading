# GSM 3-Strategy Framework

## Three trader types

### Scalper / 短线交易员

Source slide characteristics:
- Hold time is short.
- Profit/loss is realized quickly.
- Psychological pressure can be high because losses also arrive quickly.

Project mapping: `SCALPING_ENGINE`.

### Day Trader / 日内交易员

Source slide characteristics:
- Seeks an outcome within the trading day.
- Emphasizes a stable trading mindset.

Project mapping: `INTRADAY_ENGINE`.

### Swing Trader / 趋势交易员

Source slide characteristics:
- Holds trades longer.
- Targets larger point moves.
- Must tolerate longer floating P/L and greater exposure to outside factors.

Project mapping: `SWING_ENGINE`.

## Bullish setup stack shown in GSM summary

The bullish-market summary slide combines three layers:

1. Chart Pattern
   - Bull Flag
   - Double Bottom
   - Inverted Head & Shoulders
2. Candlestick Pattern
   - Doji
   - Hammer
   - Bullish Engulfing
3. Location
   - Demand / Support Zone

Interpretation for automation: pattern/candle evidence is evaluated in context of a bullish market and a relevant demand/support location; it is not a license to trade a pattern in the middle of nowhere.

## Bearish setup stack shown in GSM summary

1. Chart Pattern
   - Bear Flag
   - Double Top
   - Head & Shoulders
2. Candlestick Pattern
   - Doji
   - Inverted Hammer / bearish rejection context shown in the slide
   - Bearish Engulfing
3. Location
   - Supply / Resistance Zone

The detailed Candlestick Handbook classifies Doji as neutral/indecision and requires confirmation. Therefore Doji is context evidence, not a standalone BUY/SELL trigger.

## TrainingView setup references shown in GSM material

The classroom slide shows:
- Swing — OANDA
- Day — FXCM
- Scalp — Pepperstone

Record these as GSM training-chart references. They are not automatically hard-coded as EA broker requirements.

## System / discipline doctrine

The GSM slides emphasize a repeatable process rather than impulse trading:

- Trade with a system and a plan.
- Treat losses as part of trading cost.
- Do not enter when the required setup is absent.
- Record, review and optimize trading logic rather than adjusting only by feeling.
- Aim for controlled losses and larger gains over a series of trades, not a single jackpot trade.

## Champion research implication

The EA research process should therefore preserve:

`Rule -> Execute -> Record -> Review -> Candidate -> Backtest -> Compare -> Keep/Reject`

This complements, but does not replace, the formal Champion ranking order:

1. Net Profit USD
2. Max Equity Drawdown
3. Profit Factor
4. Trade Count
5. Win Rate
