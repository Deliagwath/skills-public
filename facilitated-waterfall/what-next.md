---
name: facilitated-waterfall-what-next
description: Surveys the project's docs and codebase to recommend the single best next action. Finds the frontier of the waterfall — the deepest stage with unfinished work — using the relates graph and codebase evidence. Use when you want to know what to work on next, or when starting fresh in a project.
---

Find the **frontier** of the project — the boundary between what's been done and what hasn't — and recommend the single best next action.

The waterfall is a pipeline: Direction → Epic → Task → Plan → Code. Work flows down. The frontier is the deepest stage that has artifacts but whose next stage is missing for some of them.

**Source of truth:** the `relates` graph and the codebase. `relates` links point upward (Epic→Direction, Task→Epic, Plan→Task) and are fixed at creation, so they are reliable. A child's existence proves its parent was broken down; the codebase proves a Plan was implemented.

**Constraint:** never read file bodies during the survey. Extract `id` and `relates` from frontmatter with shell commands only.

## Phase 1 — Build the graph

```sh
# id + relates for every artifact, no bodies
for d in directions epics tasks plans; do
  echo "=== $d ==="
  grep -rH "^id:\|^relates:" docs/$d/ 2>/dev/null
done
echo "=== ledger ==="
cat docs/plans/LEDGER.md 2>/dev/null
git log --oneline -20
```

If `docs/directions/` is empty or missing, this is a greenfield project — skip to Phase 4 with "no directions."

## Phase 2 — Find orphans (cheap, no body reads)

From the grep output alone, compute the orphans at each stage by joining `relates` links:

- **Childless Directions** — no Epic's `relates` contains this Direction's id.
- **Childless Epics** — no Task's `relates` contains this Epic's id.
- **Unplanned Tasks** — no Plan's `relates` contains this Task's id.
- **Unimplemented Plans** — every Plan whose id has no entry in `docs/plans/LEDGER.md`. A Plan with a ledger entry is implemented — no Phase 3 check needed for it.

The **frontier** is the shallowest stage that has orphans — that's where the pipeline is blocked and work is most leveraged. Resolve upper stages before lower ones: a Direction with no Epics matters more than a Plan with no code, because nothing downstream can proceed without it.

## Phase 3 — Verify candidates against reality

The graph tells you where docs are missing. For Directions/Epics/Tasks it does **not** tell you whether the work itself is done — people routinely implement code without writing the doc first, so an orphan there may already be built. Always cross-check those against the codebase before recommending. Plans are the exception: `docs/plans/LEDGER.md` records completion explicitly, so a Plan without a ledger entry can be trusted as genuinely unimplemented — no cross-check needed unless you suspect the ledger itself is stale (that's `audit-doc`'s job, not this one's).

Take the top ~3 frontier candidates (shallowest orphans first). For each, read **only** its own body if needed, then check reality:

- `grep`/`find` for the symbols, files, or features the artifact describes.
- `git log --oneline -- <relevant paths>` for commits touching that area.
- If it's a Plan, run its Verification commands when they're cheap shell checks.
- Judge each: **already done in code** (doc is just missing — recommend documenting or skipping), **partial**, or **genuinely not started**.

Drop any candidate that turns out to be already implemented — replace it with the next-shallowest orphan. Use `git log` recency only to break ties between equally-leveraged candidates; momentum is a weak signal, not a classifier.

## Phase 4 — Recommend three, ranked

Present three next actions, ranked best-first. Each maps a frontier gap to the skill that closes it:

| Frontier | Action |
|----------|--------|
| No directions | Propose a problem statement from `README.md` (first 30 lines); `/shape` |
| Direction with no Epics | `/breakdown` on that Direction |
| Epic with no Tasks | `/breakdown` on that Epic |
| Task with no Plan | `/plan` on that Task |
| Plan not implemented | `/implement` on that Plan; name the failing/missing verification |
| Code exists but no doc | Document the built work so the graph reflects it; `/audit-doc` to check it stayed inside the ADRs/Plan |
| Everything implemented | Propose a new Direction angle from a gap in the README/codebase; `/shape` |

Rank by leverage: shallower frontier stages unblock more downstream work, so they rank higher. Give each recommendation one sentence of rationale naming the evidence. If fewer than three distinct gaps exist, recommend fewer — don't pad.

## Phase 5 — Offer to act

Ask:

> Want me to start with #1, or pick another?

If the user picks one, invoke the suggested skill with the context already gathered.

## Rules

- The relates graph and the codebase are ground truth.
- Code can exist ahead of docs — always cross-check candidates against the codebase before recommending, and drop any that are already built.
- Phase 1–2 are frontmatter-only. No body reads until Phase 3.
- Phase 3 inspects at most ~3 candidates; body reads stay O(few), independent of project size.
- Resolve shallower frontier stages before deeper ones — unblock the pipeline top-down.
- Recommend three ranked actions; recommend fewer only if fewer real gaps exist — never pad.
