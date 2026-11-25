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
- When a step copies a pattern from another repo (a package layout, a build script, a config row), open that
  repo's actual files before writing the step. A step written from the pattern's name gets every detail wrong
  that matters: field names, which config array a row does *not* belong in, which script drives the check.
  Cite the file and line you read, so the implementer can re-check it — and the number must come from this
  pass's own read of that file, never from a compacted summary or a sibling plan's citation: it goes stale the
  moment that repo's file moves, and a plausible-but-wrong number only fails when the implementer re-checks.
  Re-grep each citation as you write the step, and fix it in place before the final `sp check`. The same pass covers a citation that is not a file:line — a section number of a doc you read, a quoted line, an id you rely on: read the section before naming it, grep before quoting, and prefix the repo for an id that does not sit in this workspace's numbering, since `sp check` verifies frontmatter links only and never a body citation.
- Unattended runs (an overseer item, a background job) cannot run Phase 2's one-question-at-a-time interview.
  Drive the drill against code and docs, record each decision with the evidence that took it, and reserve the
  run's block channel for the questions that are genuinely the operator's (whether/when to deploy, whether to
  touch another repo) rather than for anything derivable from the tree.
- When a step needs something the tree does not have — a verb, a field, a sibling repo's work — do not refuse the plan and do not invent the missing half: design the step inert until it lands (a flag defaulting off, a guard on the measured field) so the plan is whole and safe to build either way. Building the inert step is not a question: it is reversible and inside this repo, so an unattended run builds it. What goes on the block channel is the act that is the operator's — turning the flag on, a deploy or restart, work in the other repo — asked once the inert build is committed (overseer:probe-2026-11-23-overnight-run-lessons F3).
