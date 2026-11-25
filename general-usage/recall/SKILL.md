---
name: general-usage-recall
description: Loads project knowledge relevant to what you are about to do from the project handbook in docs/handbook/ — what each area is for, how to run things, known errors and their reflexes, and conventions. Invoke at the start of work with a query (e.g. "recall the auth bug") or bare for general orientation. Reads only; to record what a session learned, use note.
---

Load what the project handbook already knows about the task at hand, then hand back. This is the **read** end of the handbook; to record new findings after working, use `note`.

**The job is loading context.** `recall the auth bug` surfaces what the handbook knows about that area; the debugging itself follows, after control returns to the user.

The store is five fixed files in `docs/handbook/`, maintained by `note`:

| File | Holds |
|------|-------|
| `index.md` | Read-first: each file's last-verified date, and when the handbook was last pruned. |
| `map.md` | Purpose and entry points, one line per area. |
| `commands.md` | How to build, run, test, lint; setup; required env. |
| `gotchas.md` | Reproducible errors and fixes, footguns, surprising behaviour. |
| `conventions.md` | Code patterns, naming, "how we do X here". |

Terms live in `docs/CONTEXT.md` (and product terms in `docs/PRODUCT.md`), not in the handbook. An existing `docs/knowledge/` directory is research: open it when the query needs long-form background, and read it as background rather than graded entries.

---

## Steps

1. **Check the store exists.** If `docs/handbook/` is missing or empty, say so plainly and suggest running `note` at the end of a session to start building it. Stop.
2. **Read `index.md` first** — it is cheap and tells you which files are worth opening.
3. **Scope to the query.** If a query names a task or area, read the files that bear on it (a bug → `gotchas.md` + the relevant line of `map.md`; "how do I run X" → `commands.md`). For a bare `recall` with no query, give general orientation from `map.md` and `commands.md`. `map.md` names purposes, not structure. For the layout of an area, run `sp module <path>` (at `~/.agent-skills/facilitated-waterfall/scripts/sp`, if installed) or list the directory.
4. **Treat entries as testimony, not ground truth.** Each carries a source and a date, reflecting what was true when written. A source names a symbol, `` `Symbol.member` (path) ``; resolve it with `sp def` or a grep before relying on it. An older source may be `path:line`. Before relying on a specific path, command, or flag, confirm it still exists. When an entry is now wrong, name it in your report so `note` can fix it.
5. **Read the stage and the reason.** An entry may carry a `Stage:`. It is one of the following:
   - `provisional`: seen once, so weigh it lightly;
   - `established`: held up again (`← probe-<id>` names the probe that justified it);
   - `canonical`: a rule of the workspace;
   - `superseded → <successor>`: use the successor.

   Stage is maturity. Freshness (`(unverified)`, `(stale)`, and an old Verified date) is a separate question; report both. A `Because:` line tells you when the practice applies. When the situation at hand lacks the reason, say so and weigh the rule accordingly. A `gotchas.md` entry's **Reflex** is the move to avoid; surface it when the query heads that way. Entries without these fields are still valid. Report them as they are.

---

## Report

Summarise what the handbook knows that bears on the query: the relevant commands, gotchas, and structure. Give each entry you rely on with its stage, for example "(established)". Summarise rather than quote whole files. Flag any entry that looks stale or contradicted. An entry marked `portable` needs no special handling here; the tag is for whoever later wants lessons that hold beyond this repo. End by handing control back to the user for the actual work.
