---
id: adr-0002
title: "Amounts Are Integer Cents"
created: 2026-09-01
relates:
  - task-001
supersedes:
  - adr-0001
---

# ADR 0002: Amounts Are Integer Cents

## Context

adr-0001's floats drifted: a month of entries summed to 1 cent off the bank's figure.
direction-001 Constraint 1 asks for exact amounts. Every amount so far is in one
currency with two decimal places.

## Decision

Store every amount as an `int` count of cents (`Entry.cents`). Parse `12.30` as
`1230`; never hold an amount as a float.

## Consequences

Sums are exact. A currency with three decimal places, or a rate applied to an
amount, does not fit and would need a new decision.

## Alternatives

- `Decimal`: exact too, slower, and every caller must pass a context.
- Floats with rounding at display: the drift stays in the sums.
