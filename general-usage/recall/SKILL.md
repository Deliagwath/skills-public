---
name: general-usage-recall
description: Loads project knowledge relevant to what you are about to do from the knowledge base in docs/knowledge/ — what folders do, how to run things, known errors, conventions, and domain terms. Invoke at the start of work with a query (e.g. "recall the auth bug") or bare for general orientation. Reads only; to record what a session learned, use note.
---

Load what the project knowledge base already knows about the task at hand, then hand back. This is the **read** end of the base; to record new findings after working, use `note`.

**This skill never performs the task in the query** — `recall the auth bug` surfaces what the base knows about that area; it does not debug. Loading context is the whole job.

The store is a fixed set of files in `docs/knowledge/`, maintained by `note`:

| File | Holds |
|------|-------|
| `index.md` | Read-first map of the base + each file's last-verified date. |
| `map.md` | Directory/module structure, what each part does, entry points. |
| `commands.md` | How to build, run, test, lint; setup; required env. |
| `gotchas.md` | Reproducible errors and fixes, footguns, surprising behaviour. |
| `conventions.md` | Code patterns, naming, "how we do X here". |
| `glossary.md` | Domain and project-specific terms. |

---

## Steps

1. **Check the store exists.** If `docs/knowledge/` is missing or empty, say so plainly and suggest running `note` at the end of a session to start building it. Stop.
2. **Read `index.md` first** — it is cheap and tells you which files are worth opening.
3. **Scope to the query.** If a query names a task or area, read the files that bear on it (a bug → `gotchas.md` + the relevant part of `map.md`; "how do I run X" → `commands.md`). For a bare `recall` with no query, give general orientation from `map.md` and `commands.md`.
4. **Treat entries as a snapshot, not ground truth.** Each carries a source and a date, reflecting what was true when written. Before relying on a specific path, command, or flag, confirm it still exists. If an entry is now wrong, note it in your report so it can be fixed via `note` — do not silently work around it.

---

## Report

Summarise what the base knows that bears on the query — the relevant commands, gotchas, and structure. Do not dump file contents verbatim. Flag any entry that looks stale or contradicted, and end by handing control back to the user for the actual work.
