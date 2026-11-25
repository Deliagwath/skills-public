---
name: facilitated-waterfall-audit-doc
description: Audits an implementation against the boundaries its governing documents set — ADR decisions, Plan steps, Task/Epic scope, Direction constraints. Walks the relates graph to collect every constraint, checks the code against each, and reports conformance and drift. Read-only; writes nothing. Use to verify that what was built stays inside what was decided.
---

Audit an implementation against the boundaries its governing documents drew. The question is "does what was built stay inside what was decided?"

This skill is **read-only**. It reports drift.

**Find the input:** interpret the argument to locate a starting artifact across `docs/directions/`, `docs/epics/`, `docs/tasks/`, `docs/plans/`, and any ADRs. The argument may also be a code path — then find the artifact that governs it via the relates graph. If no argument, ask what to audit.

## Phase 1 — Collect the boundaries

Read the target and walk `relates` **upward** to its governing artifacts (Plan → Task → Epic → Direction; `sp trace <id>`) and **sideways** to every ADR it references. Run `sp check <id>` on each artifact you walk, and report a broken or ambiguous link as a boundary you could not collect. Read each constraint section with `sp show <id> <section>`. From each, extract the constraints — what the implementation must stay within:

- **ADR** — Decision and Consequences. Non-negotiable.
- **Plan** — Steps (what was to be built) and Verification (observable checks).
- **Task / Epic** — Scope and especially **Out of scope**.
- **Direction** — Constraints, Appetite, and Out of scope.
- **Ledger** — check `docs/plans/LEDGER.md` for an entry matching the Plan's id. Note the claimed date and verification summary as a boundary to check.

**Inherit point:** for each path the implementation touches (a code-path argument, or the files from Phase 2), run `sp docs <path>` (`conventions` → Handbook → Inherit). A live doc linked to the code but missing from the `relates` walk is a boundary too; note it as found by link. `sp` lives at `~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file. Without it, grep `docs/` for the paths.

List every boundary you collected before touching the code. These are the audit criteria. State read depth with them.

## Phase 2 — Locate the implementation

Find the code that corresponds to the artifact: `grep`/`find` for the symbols, files, and features it names; `git log --oneline -- <paths>` for the commits that built it. Note what exists and what is absent.

## Phase 3 — Check each boundary against reality

For every boundary from Phase 1, judge the implementation:

- **Conforms** — code respects the decision/scope/step, with evidence.
- **Drifts** — code diverges from a Plan step or decision without a documented reason.
- **Violates** — code does something an ADR forbids or an Out-of-scope line excludes (scope creep), or contradicts a documented decision.
- **Unverified** — a Plan Verification check that does not pass, or can't be run.
- **Not implemented** — a boundary with no corresponding code at all.
- **Ledger stale** — the ledger claims the Plan was implemented, but its Verification items no longer pass against current code.
- **Unrecorded** — the code conforms to the Plan, but no ledger entry exists for it.

Run cheap Verification commands where the Plan lists them. State evidence for every judgment — file and line, command output, or commit.

## Phase 4 — Report

Tag every non-conforming verdict with its likely cause; you assign the tag:
- `CONTEXT-GAP`: the governing docs did not say it, so the fix routes to an ADR, a Task or a handbook entry.
- `JUDGMENT-GAP`: the docs said it and the build missed it, so the fix routes to code.
- `UNCLEAR`: you can't tell which.

Present findings grouped by severity, violations first, and end with a count line:

```
adr-0004                       VIOLATED       JUDGMENT-GAP  src/cache.ts:88 does blocking read in request path
task-003                       DRIFT          CONTEXT-GAP   added password reset — Plan silent on recovery flow
plan-005                       UNVERIFIED     UNCLEAR       `npm run e2e:auth` fails (2 specs)
plan-006                       LEDGER STALE   JUDGMENT-GAP  marked implemented 2026-05-01, but `npm run e2e:billing` now fails
plan-007                       UNRECORDED     JUDGMENT-GAP  code complete, no ledger entry — append one
direction-001                  CONFORMS                     no scope-creep against Out of scope

Causes: 1 CONTEXT-GAP · 3 JUDGMENT-GAP · 1 UNCLEAR
```

A run of CONTEXT-GAPs says the anchors need improving; a run of JUDGMENT-GAPs says the work does.

For each violation or drift, recommend the corrective action and name who owns the call:

- **Code is wrong** → fix the code to honor the boundary.
- **Boundary is outdated** → record the changed decision by appending a new ADR that supersedes the old one (the system is append-only).

Recommend; the user decides and applies.

## Rules

- Read-only: the output is a report.
- Boundaries come from the governing docs; ground truth comes from the code. A disagreement between them is the finding: report both sides.
- A ledger entry is a claim, like any ADR or Plan. Corrections are new ledger lines.
- A changed decision is recorded by appending a superseding ADR.
- Every verdict carries a file, line, command, or commit.
