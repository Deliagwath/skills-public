---
name: facilitated-waterfall-top-down
description: Descends from intent to the waterline — shapes a Direction, breaks it into Epics/Tasks, and records ADRs — stopping at a placed, bounded unit rather than running into implementation. Use to start a new initiative, decompose work, or make an architectural decision. Loadable as a subroutine by bottom-up when a fix hits an above-the-line gap.
---

Descend from intent toward the waterline. Produce durable, committed artifacts and **stop at a placed, bounded unit** — a Task ready to implement. Do not cross into implementation; that is `bottom-up`'s half. Read `conventions` for the drilling technique, the waterline, append-only, formats, and numbering — they are not repeated here.

**Find the entry.** Interpret the argument to locate the starting point and the tier to work at:
- A raw problem/goal, or nothing → start at **Shape** (Direction).
- An existing Direction → start at **Breakdown**.
- A design decision surfacing during breakdown → **Design** (ADR).

When invoked as a subroutine by `bottom-up`, the caller names the tier and hands you the gathered context — do not re-scan; author the one artifact requested and return.

## Descent guard

Stop at the underside of the waterline. Top-down's output is a Task (optionally grouped in an Epic) plus any ADRs the decisions warranted — never code, never a Plan. The moment the work is *placed* (which module/pattern, what the bounded unit is), hand off.

---

## Phase 1 — Shape (Direction)

Interview until all five sections are precise, then write `docs/directions/NNN-slug.md`. Cover in order; drill each vague answer until it holds:

1. **Problem** — what is broken or missing, stated plainly.
2. **Appetite** — how much complexity/effort this is worth (a budget, not an estimate).
3. **Out of scope** — what a naive engineer would build that you don't want.
4. **Success signal** — how you'll know it worked. Observable, not aspirational.
5. **Constraints** — what cannot change regardless of how it's solved.

Optionally add **Risk** (one line: blast radius · rollback · cost-of-wrong) when the initiative is hard to reverse. Update `CONTEXT.md` when a domain term resolves. Frontmatter `relates: []`.

## Phase 2 — Breakdown (Epic? → Task)

Decompose the Direction into the units that will be implemented. **This is the descent spine** — it turns intent into placed, bounded work.

**Decide the tier first.** Read the input and recommend:
- **Direct to Tasks** — if the Direction is focused; skip the Epic tier.
- **Epic then Tasks** — only if the work spans several related Tasks that need an ordering or shared manifest.

Confirm the tier with the user before producing output.

**Drill each unit.** For each proposed Task: probe its Goal until it is a single, testable outcome. Challenge scope — "what would a naive engineer add here?" For each proposed Epic: confirm its Scope and Out of scope against the Direction.

**Own the horizontal structure in the Epic (when used).** The Epic's **Tasks** section is the manifest — a table of children with a `Depends on` column; **Sequencing** derives the order (or "parallel"). Dependency edges live *only* in the manifest — never duplicate them onto Tasks, so re-ordering never means editing Tasks.

**Write**, one artifact at a time, confirming each:
- Epic → `docs/epics/NNN-slug.md` — Goal · Scope · Out of scope · Tasks · Sequencing · Done when. `relates: [<direction id>]`.
- Task → `docs/tasks/NNN-slug.md` — Goal · Notes. `relates: [<epic id or direction id>, <adr ids>]`.

Allocate the whole batch of numbers atomically (see `conventions` → Numbering). Update `CONTEXT.md` on resolved terms.

## Phase 3 — Design (ADR)

Record an ADR **only** when all three hold:
1. **Hard to reverse** — the cost of changing your mind later is meaningful.
2. **Surprising without context** — a future reader will ask "why this way?"
3. **A real trade-off** — there were genuine alternatives.

Interview down each branch of the design tree, resolving dependencies one at a time. Challenge decisions that contradict a parent Direction or an existing ADR. When a term resolves, update `CONTEXT.md` inline.

Write `docs/adr/NNNN-slug.md` — **Context · Decision · Consequences · Alternatives** (rejected options *and why*). Set `relates` to include the artifact that raised it; add `supersedes: [<adr id>]` when it replaces an earlier decision. The ADR sits at the waterline: this is the same file `bottom-up` appends to when code disagrees — author it so either entry direction reads cleanly.

## Rules

- Stop at the waterline. Never emit a Plan or code — hand off the Task.
- ADRs are sparse. If a decision isn't hard-to-reverse *and* surprising *and* a real trade-off, it's a Task Note, not an ADR.
- When authoring intent (Direction), the human decides — always interview. When authoring a Task/ADR whose answer is derivable from code and existing docs, you may resolve autonomously and surface only genuine ambiguity.
