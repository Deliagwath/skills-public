---
name: facilitated-waterfall-breakdown
description: Breaks a Direction into Epics, or an Epic into Tasks with iterative probing and boundary testing. Use when decomposing high-level work into manageable units, splitting Directions into Epics, or breaking Epics into Tasks.
---

Break a Direction into Epics, or an Epic into Tasks.

**Find the input:** interpret the argument naturally to locate the file. If no argument, scan `docs/directions/` or `docs/epics/` and ask the user to pick.

**Determine scope:**
If the user specifies epic or task level, use it. Otherwise read the input and recommend:
- **Epics** — when the work spans multiple concerns, teams, or weeks.
- **Tasks** — when the input is focused enough to decompose directly.

Confirm scope with the user before producing any output.

## Drilling technique

Ask one question at a time. Give your recommended answer before waiting for a response. Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases ("What happens when X?").
- **Push back** — test each answer; a decision is resolved when it holds under challenge.
- **Resolve inline** — capture decisions as they happen.
- **Verify claims against the record** — when the operator's statement conflicts with a recorded artifact (in any repo), read the governing artifact in its owning repo and cite it before writing the resolution down. A conflict that survives that reading is resolved by supersession or amendment.

For each proposed Epic or Task: probe its Goal until it is a single, testable outcome. Challenge its Out of scope: "what would a naive engineer add here?" For Tasks, also probe Acceptance Criteria until each item is observable and testable without judgment — the bar `plan` applies to Verification. Confirm boundaries with the adjacent artifacts before writing.

## Output

Produce artifacts one at a time, confirming each before moving to the next:
- Direction → Epics: `sp new epic "<title>" --relates <direction-id> --intent "…"` per Epic (`docs/epics/NNN-slug.md`)
- Epic → Tasks: `sp new task "<title>" --relates <epic-id>,<adr-id>,… --intent "…"` per Task (`docs/tasks/NNN-slug.md`)
- Direction → Tasks: `sp new task "<title>" --relates <direction-id>,<adr-id>,… --intent "…"` per Task (`docs/tasks/NNN-slug.md`), when **Determine scope** chose Tasks directly.

`sp` (`~/.agent-skills/facilitated-waterfall/scripts/sp`) numbers each one under a lock and writes the frontmatter and section headings. Run `sp check <id>` on each file, and `sp tree <input id>` to see the batch. Without `sp`, allocate the batch's numbers in one pass from the highest existing file and write the frontmatter by hand.

Each file: frontmatter (`id` kind-prefixed, as `epic-NNN` / `task-NNN`; `title`, `created`, `relates: [<input id>]`, and an optional `intent:` line, one sentence drawn from the settled Goal) + body:

**Epic body:** Goal · Scope · Out of scope · Tasks · Sequencing · Done when (the Tasks table lists `(planned)` rows for children not yet minted; `conventions` → Artifact formats)

**Task body:** Goal · Effect check · Notes (the conventions skeleton). Write the Acceptance Criteria as testable bullets in the Goal, in the form the repo's existing Tasks use.

**Effect check** (adr-0013 §3; `conventions` → Artifact formats). Before confirming each Task, ask where its Goal's effect will show in use, and drill it until each bullet names something a later reader can open: **Where** (a store, route, log or command that normal operation writes to), **Seen**, **Not achieved**, **Earliest** (the first real opportunity). When the Goal has no effect beyond its Verification (a refactor, pure mechanism), write that as one line under the heading.

Number sequentially from the highest existing file in the target directory.

Update `docs/CONTEXT.md` in the same batch: each domain term resolved, each term the new artifacts *use*, and each example the new work makes stale (fix it in place; `conventions` → Artifact formats). Glossary only — no implementation detail.

## Multi-repo breakdowns

When the work lands in repos other than the one hosting the input (an epic in a neutral front-door repo whose children's work lands in owning repos):

- **Mint all Task files in the repo that hosts the Epic**, so the frontier, ledger and graph (each per-workspace) stay in one place. The Epic's Tasks table carries a `Repo` column naming where each Task's work lands. Refresh the table's note line in the same edit; it is companion text to the rows, so it changes without an amendment section.
- **Relate to artifacts that exist.** For a contract (e.g. an ADR) that a sibling Task in the same batch will author, state in the body that it is authored under that Task's plan, and add the edge with `sp relate` once it is minted.
- **Split a deferred question by owning repo.** A question whose resolution spans two repos becomes one half per Task, each resolving its own half, so the Tasks stay file-disjoint and parallel.

**Before committing the batch:** verify the whole graph — every same-repo `relates` reference resolves, ids unique, numbers sequential per kind (`conventions` → Batch check; `~/.agent-skills/facilitated-waterfall/conventions/scripts/check-graph.py` works without `sp`). Then the commit step (`conventions` → Commit): prior uncommitted work in the repo commits first, on its own.
