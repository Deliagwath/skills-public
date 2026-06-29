---
name: facilitated-waterfall-audit-doc
description: Audits an implementation against the boundaries its governing documents set — ADR decisions, Plan steps, Task/Epic scope, Direction constraints. Walks the relates graph to collect every constraint, checks the code against each, and reports conformance and drift. Read-only; writes nothing. Use to verify that what was built stays inside what was decided.
---

Audit an implementation against the boundaries its governing documents drew. The question is not "is this done?" — it is "does what was built stay inside what was decided?"

This skill is **read-only**. It reports drift. It never mutates artifacts.

**Find the input:** interpret the argument to locate a starting artifact across `docs/directions/`, `docs/epics/`, `docs/tasks/`, `docs/plans/`, and any ADRs. The argument may also be a code path — in that case, find the artifact that governs it via the relates graph. If no argument, ask what to audit.

## Phase 1 — Collect the boundaries

Read the target and walk `relates` **upward** to its governing artifacts (Plan → Task → Epic → Direction) and **sideways** to every ADR it references. From each, extract only the constraints — the things the implementation is not allowed to violate:

- **ADR** — Decision and Consequences. Non-negotiable.
- **Plan** — Steps (what was to be built) and Verification (observable checks).
- **Task / Epic** — Scope and especially **Out of scope**.
- **Direction** — Constraints, Appetite, and Out of scope.

List every boundary you collected before touching the code. These are the audit criteria.

## Phase 2 — Locate the implementation

Find the code that corresponds to the artifact: `grep`/`find` for the symbols, files, and features it names; `git log --oneline -- <paths>` for the commits that built it. Note what exists and what is absent.

## Phase 3 — Check each boundary against reality

For every boundary from Phase 1, judge the implementation:

- **Conforms** — code respects the decision/scope/step, with evidence.
- **Drifts** — code diverges from a Plan step or decision without a documented reason.
- **Violates** — code does something an ADR forbids or an Out-of-scope line excludes (scope creep), or contradicts a documented decision.
- **Unverified** — a Plan Verification check that does not pass, or can't be run.
- **Not implemented** — a boundary with no corresponding code at all.

Run cheap Verification commands where the Plan lists them. State evidence for every judgment — file and line, command output, or commit.

## Phase 4 — Report

Present findings grouped by severity, violations first:

```
docs/adr/004-no-sync-io.md     VIOLATED    src/cache.ts:88 does blocking read in request path
docs/tasks/003-auth.md         DRIFT       added password reset — outside Plan steps
docs/plans/005-auth.md         UNVERIFIED  `npm run e2e:auth` fails (2 specs)
docs/directions/001.md         CONFORMS    no scope-creep against Out of scope
```

For each violation or drift, recommend the corrective action and name who owns the call:

- **Code is wrong** → fix the code to honor the boundary.
- **Boundary is wrong / outdated** → the decision changed; record it by appending a new ADR that supersedes the old one. Never edit the original decision in place — this is an append-only system.

Recommend, do not apply. Surface the drift; let the user decide.

## Rules

- Read-only. Write nothing. The output is a report, not a mutation.
- Boundaries come from the governing docs; ground truth comes from the code. When they disagree, that disagreement *is* the finding — don't silently pick a side.
- A changed decision is recorded by appending a superseding ADR, never by editing the original.
- State evidence for every judgment — no verdict without a file, line, command, or commit behind it.
