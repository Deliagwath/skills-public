---
id: probe-2026-10-01-balance-off-by-a-cent-on-rounding
title: "Balance off by a cent on rounding"
created: 2026-10-01
status: open
relates:
  - task-002
  - adr-0002
---

# Probe: Balance off by a cent on rounding

## Trigger

The treasurer (2026-10-01): September's `balance(upto=2026-09-30)` is 1 cent below
the bank's closing figure. Suspected rounding in `src/tally/ledger.py`.

## Governing docs

Intent trace:
- task-002: balance(upto) sums every entry dated on or before the given day.
- epic-001: Entries are recorded once and the balance on any day is exact.
- direction-001: A small team records money in and out and can ask its balance on
  any day.

Read depth at entry: task-002 — FULL; adr-0002 — FULL; epic-001 — FULL;
direction-001 — FULL.

## Findings

**2026-10-01 — Situate.**
- F1. `Entry.cents` is an `int` and `balance` only adds ints: no rounding exists in
  the ledger (adr-0002 holds in the code).
- F2. The bank's statement carries a 0.01 interest line dated 2026-09-30 that was
  never recorded. Recorded today as a new entry; the balances now agree.

## Open questions

- Q1. Is there rounding in the ledger? → resolved: no (F1).
- Q2. Where does the cent come from? → resolved: an unrecorded interest line (F2).

## Deliberation

- D1. No code change: the ledger is exact; the missing cent was a missing entry.
- Verdicts: adr-0002 — still holds: amounts are integer cents in the code (F1).

No line is crossed. Nothing to implement.

## Risk

- **Blast radius:** none; no code changed.
- **Rollback:** not needed.
- **Cost-of-wrong:** low.

## Reconciliation
