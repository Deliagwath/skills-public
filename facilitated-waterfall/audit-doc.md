---
name: facilitated-waterfall-audit-doc
description: Audits a single facilitated-waterfall artifact (Direction, Epic, Task, or Plan), checks the codebase for evidence of implementation, proposes a status (draft or done) for the target and all related files, then writes the updates after confirmation. Use when you need to determine whether a specific artifact has been implemented, or to sync status across a relates graph.
---

Audit a single artifact and cascade status updates to its related files.

**Find the input:** interpret the argument naturally to locate the file across `docs/directions/`, `docs/epics/`, `docs/tasks/`, and `docs/plans/`. If no argument, scan all four directories and ask the user to pick.

## Phase 1 — Read the graph

Read the target file. Extract its `relates` frontmatter. Follow every `relates` link and read those files too. Repeat one level deep — if a related file has its own `relates`, read those as well.

Build a mental map: target + all connected artifacts, each with their current `status`.

## Phase 2 — Audit the codebase

For each artifact in the graph, search the codebase for evidence that the work has been done:

- **Plan** — run or inspect each item in its Verification section. If commands are listed, run them. If behaviours are listed, find the relevant code.
- **Task** — search for code that fulfils the Goal. Look at files likely touched by the work.
- **Epic** — check whether all related Tasks are `done`.
- **Direction** — check whether all related Epics are `done`.

State your evidence explicitly for each artifact: what you found, what you didn't find, and what that implies about status.

## Phase 3 — Propose

For each artifact in the graph, propose either `draft` or `done` with a one-line rationale. Present all proposals together before asking for confirmation:

```
docs/tasks/003-auth.md          draft → done   (login handler found in src/auth.ts)
docs/epics/001-user-auth.md     draft → done   (all 3 tasks are done)
docs/plans/005-auth-plan.md     draft → done   (verification steps pass)
```

If the evidence is ambiguous, say so and recommend `draft` until confirmed.

Ask the user to confirm, correct, or skip any individual file before writing.

## Phase 4 — Write

For each confirmed update, change the `status` field in the file's frontmatter from `draft` to `done`. Do not change any other content.

## Rules

- Never change status without explicit user confirmation.
- Never modify file content beyond the `status` frontmatter field.
- If a related file is already `done`, skip it — do not re-propose.
- If evidence is missing entirely, propose `draft` and explain what was not found.
