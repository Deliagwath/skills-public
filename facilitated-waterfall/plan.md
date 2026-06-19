---
name: facilitated-waterfall-plan
description: Creates an implementation plan from a Task document with related ADRs, drilling on ambiguities before writing concrete, numbered steps. Use when planning how to implement a specific task, or when a Task needs to be turned into executable steps with verification criteria.
---

Read the input Task and its related ADRs, then drill on the plan before writing it.

Find the input: interpret the argument naturally to locate the file in `docs/tasks/`. If no argument, scan and ask.

## Phase 1 — Read

Read the task (Goal, Notes). Follow `relates` to read each ADR (Decision, Consequences). Note every constraint the ADRs impose — these are non-negotiable in the steps.

## Phase 2 — Drill

Before writing, probe the plan with the user. Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen, don't batch.

For each proposed step: is it atomic and completable without re-reading the ADR? Does it conflict with any ADR decision? For each verification item: is it observable without judgment, or does it require interpretation?

Ask one question at a time. Give your recommended answer before waiting for a response.

## Phase 3 — Write

Number sequentially from the highest existing file in `docs/plans/`. Write `docs/plans/NNN-slug.md`:

**Frontmatter:** `relates` includes the task id and all ADR ids read.

**Context** — one paragraph: why this task exists and what ADR constraints apply.

**Steps** — numbered, concrete, completable without re-reading the ADR.

**Verification** — observable checks only (commands to run, behaviours to observe). Not aspirational statements.

## Rules
- If a step requires a design decision not covered by an ADR, resolve it during drilling or flag it explicitly.
- Verification items must be checkable without judgment — if it requires interpretation, rewrite it.
