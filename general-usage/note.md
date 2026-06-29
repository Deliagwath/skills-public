---
name: general-usage-note
description: Records what a working session learned into a project knowledge base in docs/knowledge/ — a fixed set of files capturing how to run things, reproducible errors, what folders do, conventions, and domain terms. Invoke at the end of a session (usually bare) to harvest and bank the findings, or with "prune" to clean stale notes. To read the base back, use recall.
---

Records what a session turned up into a project knowledge base, so the next session starts ahead of this one. This is the **write** end of the base; to read it before working, use `recall`.

The store is a **fixed set of six files** in `docs/knowledge/` — knowledge is routed into these, never spread across new ones. That is what keeps the base small (< 10 files) and prunable by construction.

| File | Holds |
|------|-------|
| `index.md` | Read-first map of the base: one line per file + each file's last-verified date. |
| `map.md` | Directory/module structure, what each part does, entry points, where key things live. |
| `commands.md` | How to build, run, test, lint, deploy; setup steps; required env. |
| `gotchas.md` | Reproducible errors and their fixes, footguns, surprising behaviour, time-wasters. |
| `conventions.md` | Recurring code patterns, naming, "how we do X here", architectural norms. |
| `glossary.md` | Domain and project-specific terms and their meaning. |

Pick the mode:

- `docs/knowledge/` missing or empty → **Bootstrap**, then continue to Write.
- Argument is `prune` (or "clean up / verify the base") → **Prune**.
- Otherwise → **Write**.

---

## Bootstrap

Run only if `docs/knowledge/` does not exist or is empty.

Create the directory and all six files. Each content file gets a one-line header comment stating what it holds and nothing else — no invented entries. Create `index.md` listing the five content files with `last verified: never`. Then continue to Write.

---

## Write

Capture what the session learned. The facts usually live in **the preceding conversation**, not in any argument — the user types `/note` after the work is done to bank what just happened.

### 1 — Harvest from the conversation

Re-read the session and pull out what is durable and was non-obvious. Look especially for:

- **Commands that were corrected** — the trail matters. "`npm test` and `npx test` both fail; `pnpm test` works (this repo is pnpm-only)" belongs in `commands.md`. Record the working answer *and* the dead ends, so the next session does not repeat them.
- **Errors that were reproduced and resolved** → `gotchas.md`, with how to trigger and how to fix.
- **Structure that became clear** — what a folder does, where an entry point is → `map.md`.
- **Conventions noticed** → `conventions.md`. **Terms pinned down** → `glossary.md`.

Discard what was one-off or specific to this conversation. A list of candidate facts before writing is good; confirm the set with the user if it is large.

### 2 — Verify before recording

Only record what is true. If a fact was *discovered* (inferred from code or output), confirm it still holds — re-read the file, re-run the command. If it was *stated by the user*, take it as given but mark it user-asserted if it cannot be checked. Never record a guess as fact; if you must record something uncertain, mark it `(unverified)`.

### 3 — Route to exactly one file

Pick the single best-fit file using the table above. A fact belongs in one place. If it seems to fit two, choose by primary use:

- "X folder handles auth, entry point is `src/app.ts`" → `map.md`
- "tests run with `pnpm test:int`, needs Docker up" → `commands.md`
- "import fails unless `NODE_OPTIONS=--no-warnings`; reproduces on clean clone" → `gotchas.md`
- "all API handlers return `Result<T>`, never throw" → `conventions.md`
- "a 'tenant' is a billing account, not a user" → `glossary.md`

Do **not** create a new file. If nothing fits, it probably is not durable project knowledge — drop it.

### 4 — Dedup, then write atomic dated entries

Before adding, search the target file for an existing entry on the same subject. If one exists, **update it in place** — do not append a near-duplicate. Each entry is atomic (one fact), titled, sourced, and dated:

```
### <short subject>
<the fact>. Source: `path:line` or `command`. Verified: 2026-06-29.
```

For `glossary.md`, term + definition is enough (no source line needed).

### 5 — Touch the index

Update the target file's `last verified` date in `index.md`. If the file was empty before, change its index line from `last verified: never` to today.

Confirm what was recorded and where. Keep it to one or two lines.

---

## Prune

Maintenance pass to stop rot. Run on request, or proactively when a file has grown long enough to be hard to scan.

1. Read every content file.
2. For each entry, re-verify against the current codebase. Then:
   - **Wrong / contradicted by current code** → fix it or delete it. A fixed error in `gotchas.md` that no longer reproduces should go.
   - **Duplicated or overlapping** → merge into one entry. Consolidating is always preferred over splitting into another file.
   - **Unverifiable** (source gone, can't reproduce) → mark `(stale)`; delete on the next pass if still unverifiable.
3. Refresh `last verified` dates in `index.md` for every file touched.

Report what was fixed, merged, and removed.

---

## Rules

- Six files, fixed. Never add a seventh — route instead, or drop the fact.
- Verify discovered facts against code before recording. Mark anything uncertain `(unverified)`.
- One fact per entry; dedup before writing; update in place rather than appending duplicates.
- Every non-glossary entry carries a source and a date so it can be re-verified and pruned.
- Do not record what the code already makes obvious, or what only matters to the current conversation. Record what was non-obvious or hard-won.
- Knowledge is a snapshot, not truth. When an entry conflicts with the live codebase, the codebase wins — fix the entry.
