# GSM Supply & Demand SOP

## Core principle

Supply and Demand are **zones, not single lines**.

- Supply: an area where selling pressure previously overwhelmed buying pressure.
- Demand: an area where buying pressure previously overwhelmed selling pressure.

The source material instructs the trader to read how the zone was formed and then trade the **first return / First Touch**.

## Zone formation types

### Type 01 — Long Wick

- Long upper wick can mark a Supply zone.
- Long lower wick can mark a Demand zone.
- The wick represents a fast rejection area and is treated as a zone origin rather than a single precise price.

### Type 02 — Base Break

- Price consolidates in a base and then breaks away strongly.
- Break down from the base -> Supply origin.
- Break up from the base -> Demand origin.

### Type 03 — Impulsive

- Strong bearish impulse -> Supply origin.
- Strong bullish impulse -> Demand origin.
- The source notes that Long Wick and Impulsive can sometimes appear together, which can make the zone clearer.

## Entry doctrine — First Touch Only

A fresh zone is treated as having its cleanest reaction on the first return.

Process:

`Zone forms -> price leaves -> wait -> first return to zone -> evaluate/execute according to strategy SOP`

Do not automatically treat second and third returns as equally fresh.

For program logic, zone state must therefore be explicit, for example:

- `FRESH`
- `FIRST_TOUCH_ACTIVE`
- `USED`
- `BROKEN`

The exact implementation names are flexible, but the First Touch state must not be lost.

## Zone size > 30 PT

The GSM source states that when a zone is larger than 30 points, entry should not simply be taken at the outer edge; the zone midpoint / 50% area is used as the entry reference.

Because broker point conventions can differ for XAUUSD, Codex must not guess the numeric conversion between GSM points and broker `_Point`. The project must explicitly map the GSM unit to each broker/symbol before coding or testing.

## Coding constraints

- Draw/track a zone, not a one-price line.
- Preserve the origin and freshness of each zone.
- Do not mark a zone `USED` before the true first return occurs.
- Do not let bar-only bookkeeping miss an intra-bar First Touch if the strategy requires tick-level touch detection.
- A broken zone must not continue to be treated as fresh.
- GitHub FVG/OB/SMC logic may be tested as confluence, but cannot silently replace this GSM Supply & Demand SOP.
