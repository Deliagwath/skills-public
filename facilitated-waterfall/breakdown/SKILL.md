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

For each proposed Epic or Task: probe its Goal until it is a single, testable outcome. Challenge its Out of scope — "what would a naive engineer add here?" For Tasks, also probe Acceptance Criteria until each item is observable and testable without judgment — the same bar `plan` applies to Verification. Confirm boundaries with the adjacent artifacts before writing.

## Output

Produce artifacts one at a time, confirming each before moving to the next:
- Direction → Epics: `sp new epic "<title>" --relates <direction-id> --intent "…"` per Epic (`docs/epics/NNN-slug.md`)
- Epic → Tasks: `sp new task "<title>" --relates <epic-id>,<adr-id>,… --intent "…"` per Task (`docs/tasks/NNN-slug.md`)

`sp` (`~/.agent-skills/facilitated-waterfall/scripts/sp`) numbers each one under a lock, so parallel sessions never collide, and writes the frontmatter and section headings. Run `sp check <id>` on each file, and `sp tree <input id>` to see the batch. Without `sp`, allocate the batch's numbers in one pass from the highest existing file and write the frontmatter by hand.

Each file: frontmatter (`id` kind-prefixed, as `epic-NNN` / `task-NNN`; `title`, `created`, `relates: [<input id>]`, and an optional `intent:` line, one sentence drawn from the settled Goal, never invented) + body:

**Epic body:** Goal · Scope · Out of scope

**Task body:** Goal · Acceptance Criteria · Notes

Number sequentially from the highest existing file in the target directory.

Update `docs/CONTEXT.md` when a domain term is resolved. Glossary only — no implementation detail.
