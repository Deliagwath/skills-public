---
id: direction-003
title: "Tally Imports Bank Statements"
created: 2026-09-20
intent: A bank statement file becomes ledger entries without retyping, and never twice.
relates:
  - direction-001
---

# Direction 003: Tally Imports Bank Statements

## Problem

The treasurer types every bank line into the ledger by hand, about 60 a month.
Typos happen, and a line typed twice doubles an amount.

## Appetite

One week, in `src/tally/`. One bank, one file format: the bank's CSV export
(`date,description,amount`, amounts as `-12.30`).

## Out of scope

- Other banks or formats.
- Guessing categories from descriptions.
- A user interface: a function the treasurer calls.

## Success signal

1. A month's CSV becomes that month's entries with no typing; the ledger's
   `balance(upto=last day)` then equals the statement's closing balance.
2. Importing the same file twice adds nothing the second time.

## Constraints

1. Amounts are parsed to integer cents (adr-0002), never through a float.
2. Each imported entry is recorded through `Ledger.record` (task-001); no other
   write path into the ledger.
3. A line is a duplicate when its date, amount and description match a line already
   imported. Duplicates are skipped and counted, never silently dropped.
4. A line that does not parse stops the import before anything is recorded, and
   names the line.

## Risk

A bad parse records wrong amounts. Guard: Constraint 4, and success signal 1 checked
on the first three months.
