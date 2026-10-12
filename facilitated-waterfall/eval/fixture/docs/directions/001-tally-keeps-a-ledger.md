---
id: direction-001
title: "Tally Keeps a Ledger"
created: 2026-09-01
intent: A small team records money in and out and can ask its balance on any day.
relates: []
---

# Direction 001: Tally Keeps a Ledger

## Problem

The team keeps its money in a spreadsheet. Two people edit it, rows go missing, and
nobody trusts the balance it shows for a given day.

## Appetite

Two weeks. A library, no user interface: `src/tally/`.

## Out of scope

- Several currencies.
- Importing bank statements (direction-003).

## Success signal

The balance on any past day, asked of the ledger, equals the bank's figure for that
day, to the cent.

## Constraints

1. Amounts are exact: no rounding anywhere (adr-0002).
2. An entry is never edited in place; a correction is a new entry.

## Risk

A wrong balance is believed. Guard: task-002's tests compare against a hand total.
