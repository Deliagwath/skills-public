---
name: facilitated-waterfall-plan
description: Creates an implementation plan from a Task document with related ADRs, drilling on ambiguities before writing concrete, numbered steps. Use when planning how to implement a specific task, or when a Task needs to be turned into executable steps with verification criteria.
---

Read the input Task and its related ADRs, then drill on the plan before writing it.

Find the input: interpret the argument naturally to locate the file in `docs/tasks/`. If no argument, scan and ask.

## Phase 1 — Read

Read the task (Goal, Notes). Follow `relates` to read each ADR (Decision, Consequences). Note every constraint the ADRs impose — these are non-negotiable in the steps.

**Inherit point:** for each file or directory the Task names, run `sp file <path>` (or `sp module <dir>`) and read by tier (`conventions` → Handbook → Inherit). That surfaces governing docs the Task doesn't link, and handbook gotchas for those files. State read depth before drilling. `sp` is `~/.agent-skills/facilitated-waterfall/scripts/sp`, not on `PATH`: test that file, not `which sp`. Without it, grep `docs/` for the paths instead.

## Phase 2 — Drill

Before writing, probe the plan with the user. Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen, don't batch.

For each proposed step: is it atomic and completable without re-reading the ADR? Does it conflict with any ADR decision? For each verification item: is it observable without judgment, or does it require interpretation?

Ask one question at a time. Give your recommended answer before waiting for a response.

## Phase 3 — Write

Make the file with `sp new plan "<title>" --relates <task-id>,<adr-id>,…` (it numbers it, writes `docs/plans/NNN-slug.md` with `id: plan-NNN`, and prints the path), fill it as below, and run `sp check <plan-id>`. Without `sp`, number from the highest file in `docs/plans/`:

**Frontmatter:** `relates` includes the task id and all ADR ids read. Add an optional `intent:` line: one sentence saying what this Plan delivers toward the Task's Goal.

**Context** — one paragraph: why this task exists and what ADR constraints apply.

**Steps** — numbered, concrete, completable without re-reading the ADR.

**Verification** — observable checks only (commands to run, behaviours to observe). Not aspirational statements.

## Rules
- If a step requires a design decision not covered by an ADR, resolve it during drilling or flag it explicitly.
- Verification items must be checkable without judgment — if it requires interpretation, rewrite it.
