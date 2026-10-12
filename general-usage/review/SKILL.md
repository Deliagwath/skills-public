---
name: general-usage-review
description: Reviews code changes or facilitated-waterfall documents (Direction, Epic, Task, Plan) for correctness, quality, and consistency. When reviewing code, auto-discovers ADRs and plans as anchors. Use when reviewing a diff, branch, PR, or document artifact, or when the user asks for a review, feedback, or assessment of current work.
---

Review the current work and surface structured findings. Handle both code and documents. One-shot — report findings and stop. Do not fix.

---

## Phase 1 — Identify scope

Determine what is being reviewed. In order of precedence:

1. **Explicit argument** — a file path, PR number, branch name, or document name provided by the user
2. **Current diff** — run `git diff HEAD` (or `git diff main...HEAD` for branch review); if non-empty, use it
3. **Ask** — if scope is still unclear, ask the user before proceeding

Identify the type:

- **Code review** — the subject is source code, a diff, or a PR
- **Document review** — the subject is a facilitated-waterfall artifact (Direction, Epic, Task, or Plan in `docs/`)
- **Mixed** — both code and documents are in scope; run both phases

---

## Phase 2 — Gather anchors (code review only)

If the subject is code, look for facilitated-waterfall documents that constrain this work.

**Inherit point:** if `sp` is installed (`~/.agent-skills/facilitated-waterfall/scripts/sp`), run `sp docs <path>` for each changed file. It lists the live docs linked to that code, ranked and sized, and the handbook entries for it. Read them in rank order within the `budget` line's share, and skip `lookup` (sealed) docs unless one is needed. Put a read-depth line per anchor at the top of the report: `FULL`, `PARTIAL` or `NOT_READ`. Without `sp`, take the steps below as written.

1. Scan `docs/plans/` for a plan whose verification section references changed files or features
2. Follow the plan's `relates` links to find the associated Task, Epic, and any ADRs
3. Read every anchor fully — constraints, decisions, and verification criteria all matter
4. Check `docs/plans/LEDGER.md` for an entry matching the plan's id; note its date if present

If no documents are found, proceed without anchors and note this at the top of the report.

---

## Phase 3 — Review

### Code review

Evaluate the diff or changed files against:

- Correctness — does the code do what it is supposed to do?
- Anchor compliance — does it follow the plan, ADRs, and any stated constraints?
- Edge cases — are there obvious unhandled cases or missing guards?
- Consistency — does it match surrounding code style and conventions?
- Simplicity — is anything unnecessarily complex, duplicated, or over-engineered?
- Already implemented? — if the anchor plan already has a ledger entry, this diff is touching work marked done. Not automatically wrong, but flag it as a Concern: is this an intentional correction (should get its own ledger entry / new Task), or silent rework of completed work?

### Document review

Evaluate the artifact against its type:

- **Direction** — clear problem statement, bounded appetite, measurable success signal, explicit out-of-scope, no hidden assumptions?
- **Epic** — covers the direction's success signal, tasks are coherent and non-overlapping?
- **Task** — goal is specific, acceptance criteria are testable, no scope creep from the epic?
- **Plan** — steps are concrete and ordered, verification criteria are runnable, references ADRs where decisions were made? If it already has a ledger entry, treat any edit to the Plan file itself as a Bug/Violation — a ledgered Plan is done writing; corrections belong in a new ledger line, not a rewrite.

For any artifact: flag internal contradictions, missing sections, and links that point to non-existent files.

---

## Phase 4 — Report

Structure findings by severity. Only include sections that have findings.

Tag each finding (not open questions) with its likely cause, chosen by you, never asked of the user:
- `[CONTEXT-GAP]`: the anchors didn't say it, so the fix is to an ADR, a Task or a handbook entry;
- `[JUDGMENT-GAP]`: the anchors said it and the work missed it, so the fix is to the work;
- `[UNCLEAR]`: you can't tell which. This is allowed.

With no anchors found, every finding is `[CONTEXT-GAP]` or `[UNCLEAR]`.

```
## Review: <subject>
Anchors: <plan / ADRs used, or "none found">

### Bug / Violation
Findings that are incorrect or break a stated constraint. Each one needs to be addressed.
- [file:line or doc section] [JUDGMENT-GAP] <what is wrong and why>

### Concern
Risky, unclear, or likely to cause problems. Worth discussing before merging or moving forward.
- [location] [CONTEXT-GAP] <what the concern is and what could go wrong>

### Nit
Minor style, naming, or cleanup. Low priority — fix or ignore at your discretion.
- [location] [JUDGMENT-GAP] <what and why>

### Open questions
Things the review could not resolve — missing context, ambiguous intent, or anchors that don't cover this case.
- <question>

Causes: <n> CONTEXT-GAP · <n> JUDGMENT-GAP · <n> UNCLEAR
```

If there are no findings, say so plainly: "No findings. Looks good."

---

## Rules

- Do not fix. Surface only.
- Do not manufacture findings to appear thorough. If it looks good, say so.
- Every finding must include a location (file and line, or document section).
- Bugs and violations must cite the specific anchor or reason they are wrong.
- Open questions are not findings — do not inflate severity to force a resolution.
