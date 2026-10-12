---
name: facilitated-waterfall-what-next
description: Surveys the project's docs and codebase to recommend the single best next action. Finds the frontier of the waterfall — the deepest stage with unfinished work — using the relates graph and codebase evidence. Use when you want to know what to work on next, or when starting fresh in a project.
---

Find the **frontier** of the project — the boundary between what's been done and what hasn't — and recommend the single best next action.

The waterfall is a pipeline: Direction → Epic → Task → Plan → Code. Work flows down. The frontier is the deepest stage that has artifacts but whose next stage is missing for some of them.

**Source of truth:** the `relates` graph, the ledgers and the codebase. `relates` links point upward (Epic→Direction, Task→Epic, Plan→Task) and are fixed at creation, so they are reliable. A child's existence proves its parent was broken down; the codebase proves a Plan was implemented.

**Constraint:** never read file bodies during the survey. Take `id` and `relates` from `sp tree`, or from frontmatter with shell commands only.

## Phase 1 — Build the graph

**With `sp`** (`~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file), the graph comes in a few calls, bodies unread:
- `sp tree <direction-id>` for each Direction (and each product Direction): every descendant with its state from the ledgers (Plans implemented, done or not-achieved lines, probe status, superseded-by), and the next free number per kind. A Direction is listed by `ls docs/directions/`.
- `sp check --all`: links that are broken or ambiguous make the graph unreliable there. Name them in the recommendation rather than reason past them.

**Without `sp`**, from frontmatter by shell:

```sh
# id + relates for every artifact, no bodies
for d in product/directions product/epics product/stories directions epics tasks plans; do
  echo "=== $d ==="
  grep -rH "^id:\|^relates:\|^intent:" docs/$d/ 2>/dev/null
done
echo "=== open probes ==="
grep -rlH "^status: open" docs/probes/ docs/product/probes/ 2>/dev/null
echo "=== plan ledger (implemented) ==="
cat docs/plans/LEDGER.md 2>/dev/null
echo "=== task ledger (done / effect not achieved) ==="
cat docs/tasks/LEDGER.md 2>/dev/null
git log --oneline -20
```

If `docs/directions/` and `docs/product/` are both empty or missing, this is a greenfield project — skip to Phase 4 with "no directions."

**Product layer.** When `docs/product/` exists, the pipeline starts higher: product Direction → Epic? → Story → (seam) → FW Direction/Task → Plan → Code. Product stages are shallower than every FW stage.

## Phase 2 — Find orphans (cheap, no body reads)

From the grep output alone, compute the orphans at each stage by joining `relates` links:

- **Childless product Directions** — no product Epic's or Story's `relates` contains its id.
- **Unengineered Stories** — no FW Direction's or Task's `relates` contains the Story's id. This is the hand-off frontier.
- **Open probes** — any `status: open` probe, in either layer. Resuming it ranks above starting new work in the same area.
- **Childless Directions** — no Epic's `relates` contains this Direction's id.
- **Childless Epics** — no Task's `relates` contains this Epic's id.
- **Unplanned Tasks** — no Plan's `relates` contains this Task's id.
- **Unimplemented Plans** — every Plan whose id has no entry in `docs/plans/LEDGER.md`. A Plan with a ledger entry is implemented — no Phase 3 check needed for it.

One more class sits **below every frontier class**, because it is guidance, not blocked work:

- **Awaiting an observed effect**: a Task that is implemented, meaning every Plan relating to it has a plan-ledger line, but that has no line in `docs/tasks/LEDGER.md`. Its mechanics were verified, but nobody has yet seen it have its intended effect in use. A Task built without a Plan qualifies on codebase evidence (Phase 3). A Task with a later `effect not achieved` line is not in this class. It is a `bottom-up` trigger, and it ranks with open probes.

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
| `docs/product/` exists but no `docs/PRODUCT.md` | `reflect bootstrap` |
| Open probe | Resume it: `bottom-up` (`docs/probes/`) or `reflect` (`docs/product/probes/`) |
| Product Direction with no Epics/Stories | `direct` Breakdown on that Direction |
| Story with no FW Direction/Task | `top-down` on that Story |
| Direction with no Epics | `/breakdown` on that Direction |
| Epic with no Tasks | `/breakdown` on that Epic |
| Task with no Plan | `/plan` on that Task |
| Plan not implemented | `/implement` on that Plan; name the failing/missing verification |
| Code exists but no doc | Document the built work so the graph reflects it; `/audit-doc` to check it stayed inside the ADRs/Plan |
| Effect not achieved (task ledger) | `bottom-up` with that ledger line as the Trigger |
| Awaiting an observed effect | Read the Task's Goal. Ask whether the effect has been seen in use, and where to look. If it has, record it with `sp ledger done <task-id> "<what was observed, and where>"` (`conventions` → Status & ledger). Never append a restated Verification result. |
| Everything implemented | Propose a new Direction angle from a gap in the README/codebase; `/shape` |

Rank by leverage: shallower frontier stages unblock more downstream work, so they rank higher. "Awaiting an observed effect" ranks below every frontier row. It takes a slot only when fewer than three frontier gaps exist. Otherwise mention the count in one line, so that it never becomes a nag list. Give each recommendation one sentence of rationale naming the evidence. If fewer than three distinct gaps exist, recommend fewer — don't pad.

**Intent trace.** Under each recommendation, show the composed intent: one sentence per level, leaf to root, from the `intent:` lines gathered in Phase 1, following the first parent that sits higher (`conventions` → Artifact formats; `sp trace <id>` gives it). Where a level has no `intent:`, write `<id>: no intent line`. That is information, not a defect, so don't fill it in from the body.

## Phase 5 — Offer to act

Ask:

> Want me to start with #1, or pick another?

If the user picks one, invoke the suggested skill with the context already gathered.

## Rules

- The relates graph and the codebase are ground truth.
- Code can exist ahead of docs — always cross-check candidates against the codebase before recommending, and drop any that are already built.
- Phase 1–2 are frontmatter-only (`sp tree`, `sp check`, or grep). No body reads until Phase 3; then `sp show <id> Goal` rather than the whole file.
- Phase 3 inspects at most ~3 candidates; body reads stay O(few), independent of project size.
- Resolve shallower frontier stages before deeper ones — unblock the pipeline top-down.
- Recommend three ranked actions; recommend fewer only if fewer real gaps exist — never pad.
