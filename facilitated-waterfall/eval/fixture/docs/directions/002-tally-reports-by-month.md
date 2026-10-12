---
id: direction-002
title: "Tally Reports by Month"
created: 2026-09-10
intent: Each month the team gets one report it can trust without opening the ledger.
relates:
  - direction-001
---

# Direction 002: Tally Reports by Month

## Problem

Once a month the treasurer copies the ledger into a spreadsheet, sorts it by
category, adds the columns by hand and pastes the totals into an email. It takes an
evening. Twice this year the email disagreed with the bank: once because an entry
dated the last day of the month was left out, once because a correction entry was
counted in the wrong month. The rest of the team does not open the ledger; they read
the email. So the email is the ledger, for everyone but the treasurer, and nothing
checks it.

The ledger itself (direction-001) is exact: entries are integer cents (adr-0002),
recorded once, never edited in place, and `balance(upto)` answers any day. What is
missing is a view over a month that a reader can trust without redoing the sums.

Three questions come up every month, in this order:

1. What did we start the month with, and what did we end it with?
2. Where did the money go, by category?
3. What changed since last month's report, if a late entry was recorded after it
   was sent?

The third question matters because entries are sometimes recorded days late. A
report sent on the 2nd may be wrong by the 5th. Today nobody knows, and the next
month's opening balance silently disagrees with the last month's closing one.

## Appetite

Three weeks for the first report, inside `src/tally/`. A library function and a
plain-text rendering. No web page, no PDF, no email sending: the treasurer pastes
the text. If the first report takes longer than three weeks, cut the "what changed"
section (question 3) before cutting anything else, and ship it as a follow-up.

## Out of scope

- Sending the report. The treasurer pastes it.
- Budgets and forecasts. A report states what happened, never what should have.
- Several currencies. The ledger has one (adr-0002's Context).
- Editing entries from the report. The report is read-only; a correction is a new
  entry in the ledger (direction-001 Constraint 2).
- Categories as a hierarchy. One level of category per entry is enough for the team
  as it is.
- Importing bank statements (direction-003). The report reads whatever the ledger
  holds, however it got there.
- Any report period other than a calendar month. Quarters and years are sums of
  months and can wait.

## Success signal

1. **The report agrees with the bank.** For each of the last six months, the
   report's closing balance equals the bank statement's closing balance, to the cent.
   Today two of six disagree.
2. **Opening equals last closing.** For every month after the first, the report's
   opening balance equals the previous report's closing balance, as re-run today.
3. **It takes minutes, not an evening.** The treasurer produces the month's report
   in under five minutes, measured on the next two month-ends.
4. **Late entries are visible.** When an entry dated in a reported month is
   recorded after that month's report was produced, the next report names it under
   "changed since last report", with its amount and the month it belongs to.

**Counter-signals, each a stop condition:**
- The treasurer still re-adds the columns by hand to check the report, after the
  second month.
- A reader asks the treasurer what a line in the report means, more than once a
  month.

## Constraints

1. **The report is computed from the ledger alone.** No second store of totals; a
   report re-run for a past month gives the same figures unless an entry was recorded
   late, and then it says so.
2. **Exact amounts throughout.** Sums are in integer cents (adr-0002); rendering to
   `12.30` happens only at the last step, and never feeds back into a sum.
3. **Month boundaries follow the ledger's days.** An entry dated the last day of a
   month belongs to that month. The closing balance of a month is
   `balance(upto=last day)`, which counts entries dated on that day (task-002).
4. **One category per entry.** An entry without a category is reported under
   "uncategorised", never dropped.
5. **Plain text, fixed width.** The rendering fits 80 columns and survives being
   pasted into an email client that reflows proportional text.
6. **No new dependency.** The standard library only, as for the ledger.

## Risk

- **A wrong report is believed more than a wrong ledger,** because more people read
  it. Guard: success signal 1 is checked on six past months before the first report
  is sent, and every report prints its closing balance next to the ledger's
  `balance(upto)` for the same day.
- **Late entries make reports disagree with each other.** Guard: Constraint 1 and
  the "changed since last report" section; a report never hides a disagreement.
- **Categories drift.** People type "Food", "food" and "groceries". Guard: none in
  this Direction; the report lists categories as recorded, so the drift is visible.
  A later Direction may normalise them.

## Notes on the report's shape

The team agreed on the following sections, in this order, from the treasurer's last
three emails:

- **Header:** the month, the date the report was produced, and the ledger's entry
  count at that moment, so a later re-run can tell whether entries were added.
- **Opening balance:** `balance(upto=day before the first)`.
- **By category:** one line per category, sorted by absolute amount, largest first;
  money in and money out in separate columns; a total line.
- **Closing balance:** `balance(upto=last day)`, and beside it opening plus the
  category total, which must agree. A disagreement is printed, never corrected.
- **Changed since last report:** entries dated in an earlier reported month whose
  record time is after that month's report was produced. Empty most months.

The treasurer's emails also carried a free-text "notes" paragraph. It stays in the
email, not in the report: the report is computed, and a note is not.

## Worked example

September 2026, as the treasurer's email had it, and as the report should print it:

```
Tally report — September 2026        produced 2026-10-02 · 61 entries
Opening balance (to 2026-08-31)                               4,210.55
By category                                in            out
  rent                                                1,200.00
  groceries                                             612.40
  donations                             950.00
  utilities                                             184.17
  interest                                0.01
  uncategorised                                          23.00
  total                                 950.01        2,019.57
Closing balance (to 2026-09-30)                               3,140.99
  check: opening + total                                      3,140.99  agrees
Changed since last report                                         none
```

Notes on the example:

- The interest line is the 0.01 entry that was missing until 2026-10-01; with it,
  the closing balance agrees with the bank.
- "uncategorised" holds one entry recorded without a category (Constraint 4).
- The `check` line is the closing check from "Notes on the report's shape". It
  prints `agrees` or the difference; it never adjusts either figure.
- The header's entry count (61) is what a later re-run compares against to fill
  "changed since last report".

## Open threads from the shaping conversation

- Whether "record time" exists. The ledger stores an entry's day, not when it was
  recorded. Success signal 4 needs the second. This may need a decision about
  recording a timestamp on `Entry`, which touches task-001 and adr-0002's Context.
- Whether a report is stored. Constraint 1 says no second store of totals, but
  "changed since last report" needs to know when the last report was produced. A
  stored production date and entry count, not totals, may be enough.
- Whether the closing check (opening plus category total equals closing) can ever
  fail if the ledger is exact. It can, if an entry has a day outside the month but
  is counted in a category line by mistake. That is the bug the check is for.
