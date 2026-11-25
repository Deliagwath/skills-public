---
name: facilitated-waterfall-top-down
description: Descends from intent to the waterline — shapes a Direction, breaks it into Epics/Tasks, and records ADRs — stopping at a placed, bounded unit rather than running into implementation. Use to start a new initiative, decompose work, or make an architectural decision. Also takes a product-waterfall Story as its entry. Loadable as a subroutine by bottom-up when a fix hits an above-the-line gap.
---

Descend from intent toward the waterline. Produce durable, committed artifacts and **stop at a placed, bounded unit** — a Task ready to implement. Implementation is `bottom-up`'s half. Read `conventions` for the drilling technique, the waterline, append-only, formats, and numbering.

**Find the entry.** Interpret the argument to locate the starting point and the tier to work at:
- A raw problem/goal, or nothing → start at **Shape** (Direction).
- An existing Direction → start at **Breakdown**.
- A design decision surfacing during breakdown → **Design** (ADR).
- A **reconciled probe that deferred a work item** (a "proposed task" in its Reconciliation), now approved by the operator → **Breakdown**. The probe is frozen evidence: the new artifact names it in body prose, and its `relates` stays off the probe. The deferred item is the settled scope, and the operator's approval confirms the tier. The probe's *Governing docs* point to the parent: set the Task's `relates` to the governing Direction of the area the probe established. Before hanging a Task under a thematically similar Epic, read that Epic's Out of scope; an explicit exclusion rules it out as parent.
- A product Story or Epic (`docs/product/stories/…`, `docs/product/epics/…`) → the **seam** from `product-waterfall` `direct`. Read it and walk its `relates` up to the product Direction and the `docs/PRODUCT.md` entries it cites. When the Story needs design or several ordered Tasks, start at **Shape**; when it is already focused, go to **Breakdown** into Tasks.

**Inherit point: entry.** When the entry names an area or a code path, run `sp --role top-down module <dir>` on it; when it names an existing artifact, run `sp --role top-down tree <id>` and `sp trace <id>` (`conventions` → Handbook → Inherit), and state read depth before the interview. A raw problem with no path makes no call, and the statement says so. `sp` lives at `~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file. Without it, the text rules there apply.

When `bottom-up` invokes this skill as a subroutine, the caller names the tier and hands over the gathered context: author the one artifact requested from that context and return.

**Product check.** When `docs/PRODUCT.md` exists, read its Resolved Decisions and Product-level Out of Scope before authoring. These sit above both waterlines (`conventions` → Product layer). When the work would contradict one, stop: load `product-waterfall` `reflect` with the conflict as the signal, and resume on its outcome. Product decisions change only through `reflect`.

## Descent guard

Stop at the underside of the waterline. Top-down's output is a Task (optionally grouped in an Epic) plus any ADRs the decisions warranted. Once the work is *placed* (which module/pattern, what the bounded unit is), hand off; Plans and code belong to `plan`, `implement` and `bottom-up`.

---

## Phase 1 — Shape (Direction)

Interview until all five sections are precise, then make the file with `sp new direction "<title>" --intent "<one sentence>"` (it numbers it and writes the frontmatter and section skeleton; cold, write `docs/directions/NNN-slug.md` by hand), fill the sections, and run `sp check <direction-id>`. Cover in order; drill each vague answer until it holds:

1. **Problem** — what is broken or missing, stated plainly.
2. **Appetite** — how much complexity/effort this is worth (a budget, not an estimate).
3. **Out of scope** — what a naive engineer would build that you don't want.
4. **Success signal** — how you'll know it worked. Observable.
5. **Constraints** — what holds regardless of how it's solved.

Add **Risk** (one line: blast radius · rollback · cost-of-wrong) when the initiative is hard to reverse. Update `docs/CONTEXT.md` when a domain term resolves. Frontmatter `relates: []`.

**Intent line.** Every Direction, Epic and Task written here may carry a one-sentence `intent:` in frontmatter, drawn from its settled Problem or Goal; write it once the Problem or Goal has settled. Walking up `relates`, these lines compose into the intent trace (`conventions` → Artifact formats).

**From a Story.** The Story has settled the intent. Inherit its Outcome and Acceptance criteria as the Success signal, and its Out of scope (plus its parents' Out of scope) as Out of scope. Drill the engineering sections (Appetite, Constraints, Risk) and any engineering scope the Story doesn't cover. Set `relates: [<story id>]`. When drilling shows that the Story's outcome or acceptance can't hold, stop and hand it to `direct` Refine.

## Phase 2 — Breakdown (Epic? → Task)

Decompose the Direction into the units that will be implemented. **This is the descent spine** — it turns intent into placed, bounded work.

**Decide the tier first.** Read the input and recommend:
- **Direct to Tasks** — when the Direction is focused; skip the Epic tier.
- **Epic then Tasks** — when the work spans several related Tasks that need an ordering or shared manifest.

Confirm the tier with the user before producing output.

**Drill each unit.** For each proposed Task: probe its Goal until it is a single, testable outcome, then ask where that outcome will show in use — the Task's **Effect check** (Where · Seen · Not achieved · Earliest; `conventions` → Artifact formats, adr-0013 §3). The Where is a place normal operation writes to; a Goal with no effect beyond its Verification says so in one line. Challenge scope: "what would a naive engineer add here?" For each proposed Epic: confirm its Scope and Out of scope against the Direction.

**Own the horizontal structure in the Epic (when used).** The Epic's **Tasks** section is the manifest — a table of children with a `Depends on` column; **Sequencing** derives the order (or "parallel"). Dependency edges live in the manifest only, so re-ordering touches the Epic alone.

**Write**, one artifact at a time, confirming each:
- Epic → `sp new epic "<title>" --relates <direction-id>` (`docs/epics/NNN-slug.md`) — Goal · Scope · Out of scope · Tasks · Sequencing · Done when.
- Task → `sp new task "<title>" --relates <epic-id or direction-id>,<adr-id>,…` (`docs/tasks/NNN-slug.md`) — Goal · Effect check · Notes. When breaking a Story down directly (no FW Direction), use `--relates <story-id>`. Run `sp check <id>` on each file written; `sp tree <direction-id>` shows the whole batch. The union of the Tasks' Goals covers the Story's Acceptance criteria.

Allocate the whole batch of numbers atomically (`conventions` → Numbering). Update `docs/CONTEXT.md` on resolved terms.

## Phase 3 — Design (ADR)

Record an ADR when all three hold:
1. **Hard to reverse** — the cost of changing your mind later is meaningful.
2. **Surprising without context** — a future reader will ask "why this way?"
3. **A real trade-off** — there were genuine alternatives.

**Inherit point.** Before writing, run `sp --role top-down docs <symbol|path> --type adr` on what the decision touches, to find the ADRs already governing it. A `supersedes … (lookup)` pointer names a sealed predecessor; open it when the successor may not restate what you need.

Interview down each branch of the design tree, resolving dependencies one at a time. Challenge decisions that contradict a parent Direction or an existing ADR. When a term resolves, update `docs/CONTEXT.md` inline.

Make it with `sp new adr "<title>" --relates <id of the artifact that raised it>` (`docs/adr/NNNN-slug.md`) — **Context · Decision · Consequences · Alternatives** (rejected options *and why*). When it replaces an earlier decision, run `sp supersede <new adr-id> --of <old adr-id>`: it writes `supersedes` on the new one and `superseded-by` on the old one. Then `sp check` on both. The ADR sits at the waterline, where `bottom-up` also appends when code disagrees: write it to read cleanly from either direction.

## Rules

- Stop at the waterline and hand off the Task.
- ADRs are sparse: a decision that is not hard-to-reverse *and* surprising *and* a real trade-off is a Task Note.
- Intent (a Direction) is the human's: interview. A Task/ADR whose answer is derivable from code and existing docs you may resolve yourself, surfacing genuine ambiguity.
- When the operator's statement conflicts with a recorded artifact (in any repo), read the governing artifact in its owning repo and cite it before writing the resolution down. A conflict that survives that reading is resolved by supersession or amendment.
- Commit before ending (`conventions` → Commit): prior uncommitted work in the repo first, on its own, then this session's batch as a logical commit.
