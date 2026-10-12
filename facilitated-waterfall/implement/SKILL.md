---
name: facilitated-waterfall-implement
description: Reads a Plan and related ADRs, resolves ambiguities through drilling, implements the code, and verifies against both the plan and architectural decisions. Use when implementing a planned task from documentation, or when code changes need to follow a documented plan with ADR constraints.
---

Read the input Plan and its related ADRs, drill on ambiguities, implement, then verify against both.

Find the input: interpret the argument naturally to locate the file in `docs/plans/`. If no argument, scan and ask.

## Phase 1 — Read

Read the plan (Context, Steps, Verification). Follow `relates` to read each ADR (Decision, Consequences). Read at least one matching file in the codebase before writing — existing patterns are constraints, not suggestions.

**Inherit point:** for each file the Steps will touch, run `sp file <path>` and read by tier (`conventions` → Handbook → Inherit). Its handbook gotchas are the reflexes for those edits. State read depth before drilling. `sp` is `~/.agent-skills/facilitated-waterfall/scripts/sp`, not on `PATH`: test that file, not `which sp`. Without it, grep `docs/` for the paths instead.

## Phase 2 — Drill

Before implementing, surface and resolve ambiguities. Apply throughout:

- **Sharpen fuzzy language** — when a step or ADR uses vague terms, propose a precise interpretation immediately.
- **Probe with scenarios** — for any step where the outcome is unclear, state a concrete scenario and confirm the expected result.
- **Push back** — do not interpret generously and proceed. A step is unambiguous when it holds under challenge.
- **Resolve inline** — capture clarifications as they happen, don't batch.

Ask one question at a time. Give your recommended interpretation before waiting for a response. Flag any step that conflicts with an ADR before implementing it.

## Phase 3 — Implement

Follow plan steps in order. Skeleton first (signatures and structure), then body. Before writing any non-obvious decision, state the assumption and why.

## Phase 4 — Verify

Check the implementation against:
1. Each item in the Plan's **Verification** section — run commands, observe behaviours.
2. Each **ADR Decision** — confirm the implementation honours it.

Surface any gap explicitly. Do not report done if any verification item fails or any ADR decision is violated.

## Phase 5 — Record

Once every Verification item passes and no ADR is violated, run `sp ledger implemented <plan-id> "<N>/<N> checks passed"`. It appends this line to `docs/plans/LEDGER.md` (without `sp`, append it by hand, creating the file with no header):

```
- <plan-id> — implemented <date> — verification: <N>/<N> checks passed
```

This is the only record that a Plan is **implemented**, meaning its mechanics are verified. Plans are never edited to mark themselves complete, the same way a changed ADR is superseded rather than rewritten. If a later session finds this entry was wrong, the fix is a new line stating the correction, never an edit to this one.

`implemented` is not `done`. Done means the Task's intended effect has been observed in real use (see `conventions` → Status & ledger), and a Verification pass can't show that. End your report by saying so in one line: the effect is not yet observed, and what would show it, such as an observable sign in use and where to look. Write nothing for it. The absence of a done line already means "not yet observed".

## Rules
- Do not implement beyond the plan's scope.
- Do not skip verification.
- If a new ambiguity surfaces during implementation, stop and drill before continuing.
- Do not append a ledger entry unless every verification item passed and no ADR was violated.
