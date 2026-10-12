---
id: task-002
title: "Balance Up To a Day"
created: 2026-09-02
intent: balance(upto) sums every entry dated on or before the given day.
relates:
  - epic-001
---

# Task 002: Balance Up To a Day

## Goal

`Ledger.balance(upto)` in `src/tally/ledger.py` returns the sum, in cents, of every
entry dated **on or before** `upto`. An entry dated `upto` itself counts: the bank's
end-of-day figure includes it.

## Notes

- Decision: amounts are integer cents (adr-0002), so the sum is exact.
- Plan: plan-001.
