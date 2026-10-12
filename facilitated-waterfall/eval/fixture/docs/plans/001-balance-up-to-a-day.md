---
id: plan-001
title: "Balance up to a day"
created: 2026-09-02
intent: balance(upto) is one pass over the sorted entries.
relates:
  - task-002
  - adr-0002
---

# Plan 001: Balance up to a day

## Context

task-002, in `src/tally/ledger.py`. Entries are kept sorted by `record` (task-001).

## Steps

1. Walk the sorted entries, adding `cents` while the entry's day is on or before
   `upto`; stop at the first later one.

## Verification

1. Empty ledger: 0.
2. Entries before `upto` only: their sum.
3. An entry dated `upto`: counted.
4. Entries after `upto`: not counted.

## Risk

Off-by-one at the boundary day. Guard: Verification 3.
