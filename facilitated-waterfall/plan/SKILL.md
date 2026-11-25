---
name: facilitated-waterfall-plan
description: Creates an implementation plan from a Task document with related ADRs, drilling on ambiguities before writing concrete, numbered steps. Use when planning how to implement a specific task, or when a Task needs to be turned into executable steps with verification criteria.
---

Read the input Task and its related ADRs, then drill on the plan before writing it.

Find the input: interpret the argument naturally to locate the file in `docs/tasks/`. If no argument, scan and ask.

## Phase 1 — Read

Read the task (Goal, Notes). Follow `relates` to read each ADR (Decision, Consequences). Note every constraint the ADRs impose; the steps honour all of them.

**Inherit point:** for each file or directory the Task names, run `sp file <path>` (or `sp module <dir>`) and read by tier (`conventions` → Handbook → Inherit). That surfaces governing docs the Task doesn't link, and handbook gotchas for those files. State read depth before drilling. `sp` lives at `~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file. Without it, grep `docs/` for the paths.

## Phase 2 — Drill

Before writing, probe the plan with the user. Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases ("What happens when X?").
- **Push back** — test each answer; a decision is resolved when it holds under challenge.
- **Resolve inline** — capture decisions as they happen.

For each proposed step: is it atomic and completable without re-reading the ADR? Does it conflict with any ADR decision? For each verification item: is it observable without judgment?

Ask one question at a time. Give your recommended answer before waiting for a response.

**Unattended runs** (an overseer item, a background job) drive the drill against code and docs, recording each decision with the evidence that took it. The run's block channel carries the questions that are the operator's (whether/when to deploy, whether to touch another repo).

## Phase 3 — Write

Make the file with `sp new plan "<title>" --relates <task-id>,<adr-id>,…` (it numbers it, writes `docs/plans/NNN-slug.md` with `id: plan-NNN`, and prints the path), fill it as below, and run `sp check <plan-id>`. Without `sp`, number from the highest file in `docs/plans/`:

**Frontmatter:** `relates` includes the task id and all ADR ids read. Add an optional `intent:` line: one sentence saying what this Plan delivers toward the Task's Goal.

**Context** — one paragraph: why this task exists and what ADR constraints apply.

**Steps** — numbered, concrete, completable without re-reading the ADR.

**Verification** — observable checks: commands to run, behaviours to observe.

## Rules
- A step that requires a design decision no ADR covers is resolved during drilling or flagged explicitly.
- Each verification item is checkable without judgment; rewrite one that needs interpretation.
- **A step that copies a pattern from another repo** (a package layout, a build script, a config row) is written from that repo's actual files, opened in this pass: field names, which config array a row belongs in, which script drives the check. Cite the file and line you read, re-grep each citation as you write the step, and fix it in place before the final `sp check`.
- **Every body citation is verified in this pass** — a section number, a quoted line, an id you rely on: read the section before naming it, grep before quoting, and prefix the repo for an id outside this workspace's numbering (`conventions` → Artifact formats).
- **A step that needs something the tree does not have yet** — a verb, a field, a sibling repo's work — is designed inert until it lands (a flag defaulting off, a guard on the measured field), so the plan is whole and safe to build either way. An unattended run builds the inert step: it is reversible and inside this repo. The block channel carries the operator's act — turning the flag on, a deploy or restart, work in the other repo — asked once the inert build is committed.
