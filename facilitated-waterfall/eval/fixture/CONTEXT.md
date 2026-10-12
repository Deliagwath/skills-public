# Context: tally

- **Entry** — one movement of money: a day, an amount in integer cents (adr-0002), a
  memo. Never edited in place; a correction is a new entry.
- **Ledger** — the ordered list of entries (`src/tally/ledger.py`).
- **Balance up to a day** — the sum of every entry dated on or before that day
  (task-002).
