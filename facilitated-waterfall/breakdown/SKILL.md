---
name: facilitated-waterfall-breakdown
description: Breaks a Direction into Epics, or an Epic into Tasks with iterative probing and boundary testing. Use when decomposing high-level work into manageable units, splitting Directions into Epics, or breaking Epics into Tasks.
---

Break a Direction into Epics, or an Epic into Tasks.

**Find the input:** interpret the argument naturally to locate the file. If no argument, scan `docs/directions/` or `docs/epics/` and ask the user to pick.

**Determine scope:**
If the user specifies epic or task level, use it. Otherwise read the input and recommend:
- **Epics** — if the work spans multiple concerns, teams, or weeks.
- **Tasks** — if the input is focused enough to decompose directly.

Confirm scope with the user before producing any output.

## Drilling technique

Ask one question at a time. Give your recommended answer before waiting for a response. Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen, don't batch.
- **Verify claims against the record** — when the operator's statement conflicts with a recorded artifact (in any repo), read the governing artifact in its owning repo before writing the resolution down, and cite it; a conflict that survives verification is a supersession or amendment, not a fact.

For each proposed Epic or Task: probe its Goal until it is a single, testable outcome. Challenge its Out of scope — "what would a naive engineer add here?" For Tasks, also probe Acceptance Criteria until each item is observable and testable without judgment — the same bar `plan` applies to Verification. Confirm boundaries with the adjacent artifacts before writing.

## Output

Produce artifacts one at a time, confirming each before moving to the next:
- Direction → Epics: `sp new epic "<title>" --relates <direction-id> --intent "…"` per Epic (`docs/epics/NNN-slug.md`)
- Epic → Tasks: `sp new task "<title>" --relates <epic-id>,<adr-id>,… --intent "…"` per Task (`docs/tasks/NNN-slug.md`)
- Direction → Tasks: `sp new task "<title>" --relates <direction-id>,<adr-id>,… --intent "…"` per Task (`docs/tasks/NNN-slug.md`), when **Determine scope** chose Tasks directly. Epics are optional; a Direction with Epics, and an Epic with Tasks, work as before.

`sp` (`~/.agent-skills/facilitated-waterfall/scripts/sp`) numbers each one under a lock, so parallel sessions never collide, and writes the frontmatter and section headings. Run `sp check <id>` on each file, and `sp tree <input id>` to see the batch. Without `sp`, allocate the batch's numbers in one pass from the highest existing file and write the frontmatter by hand.

Each file: frontmatter (`id` kind-prefixed, as `epic-NNN` / `task-NNN`; `title`, `created`, `relates: [<input id>]`, and an optional `intent:` line, one sentence drawn from the settled Goal, never invented) + body:

**Epic body:** Goal · Scope · Out of scope · Tasks · Sequencing · Done when (the Tasks table lists `(planned)` rows for children not yet minted; `conventions` → Artifact formats)

**Task body:** Goal · Acceptance Criteria · Notes — the conventions' skeleton is Goal · Notes, so where the repo's existing tasks fold the criteria into the Goal as testable bullets, keep that form; do not introduce a section shape the skeleton does not list.

Number sequentially from the highest existing file in the target directory.

Update `docs/CONTEXT.md` when a domain term is resolved — including any term the new artifacts *use* (it must land in the glossary in the same batch), and any stale example the new work makes wrong (fix it in place; `conventions` → Artifact formats). Glossary only — no implementation detail.

## Multi-repo breakdowns

When the work lands in repos other than the one hosting the input (an epic in a neutral front-door repo whose children's work lands in owning repos):

- **Mint all Task files in the repo that hosts the Epic.** The frontier, ledger and graph stay whole in one place — a ledger line and `sp check` are per-workspace, so fragmenting the files fragments the tracking the breakdown exists to keep. The work *effects* land in the owning repos; say so in the Epic's Tasks table (the `Repo` column is where the work lands, not where the file lives), and refresh the table's instructional note line in the same edit — it is the rows' companion text, not a recorded decision, so no amendment section.
- **Never `relates` to an artifact that does not exist yet.** An id a sibling Task in the same batch will author is an unresolved reference and fails `sp check`. Relate to what exists; state in the body that the contract (e.g. the ADR) is authored under that Task's plan, and add the edge with `sp relate` once it is minted — the one sanctioned post-creation repair.
- **Split a deferred question by owning repo.** One open question whose resolution spans two repos becomes one half per Task, each resolving its own half (both sides of the double path it reads). That keeps the Tasks file-disjoint and parallel instead of adding a `Depends on` edge or amending the epic's sequencing.

**Before committing the batch:** verify the whole graph, not just per file — every same-repo `relates` reference resolves, ids unique, numbers sequential per kind (`conventions` → Batch check; its `scripts/check-graph.py` works without `sp`). Then the commit step (`conventions` → Commit): prior uncommitted work in the repo commits first, on its own.
