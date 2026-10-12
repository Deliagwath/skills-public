---
id: task-001
title: "Entries Are Recorded"
created: 2026-09-01
intent: An entry with a date, an amount and a memo is stored and listed in date order.
relates:
  - epic-001
---

# Task 001: Entries Are Recorded

## Goal

`Ledger.record(entry)` in `src/tally/ledger.py` stores an `Entry(day, cents, memo)`;
`Ledger.entries()` lists them in date order, entries of one day in the order recorded.

## Notes

- Decision: amounts are integer cents (adr-0002).
