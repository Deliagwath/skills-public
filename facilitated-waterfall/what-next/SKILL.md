---
name: facilitated-waterfall-what-next
description: Surveys the project's docs and codebase to recommend the single best next action, or to enumerate all the work that remains. Finds the frontier of the waterfall — the shallowest stage with unfinished work — using the relates graph and codebase evidence. Use when you want to know what to work on next, what is left, or when starting fresh in a project.
---

Find the **frontier** of the project — the boundary between what's been done and what hasn't — and recommend the single best next action.

The waterfall is a pipeline: Direction → Epic? → Task → Plan → Code. Work flows down. An **orphan** is a live artifact whose next stage is missing; the **frontier** is the shallowest stage that has orphans.

**Source of truth:** the `relates` graph, the ledgers and the codebase. `relates` links point upward (Epic→Direction, Task→Epic, Plan→Task) and are fixed at creation (`sp relate` adds a missing upward edge), so they are reliable. A child's existence proves its parent was broken down; the codebase proves a Plan was implemented.

**Constraint:** the survey reads frontmatter only. Take the graph from `sp frontier`, or `id` and `relates` from frontmatter with shell commands.

## Phase 1 — Build the graph

**With `sp`** (`~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file), Phases 1–2 are two calls, bodies unread:
- `sp frontier`: every orphan of Phase 2, one row per artifact in its highest class, resume work first, then the stages shallowest first. Each row gives its stage, its id, the skill that closes it, and its `intent:` line or `no intent line`. State comes from the ledgers, probe status and supersession, as in Phase 2.
  - The summary line counts the Tasks awaiting an observed effect; `sp frontier --awaiting` lists them, and `--awaiting --all` prints the whole list. A `+N more` line means the output was cut; count from the uncut list.
  - An `unsure` line, or a row marked `unsure`, means a `relates` link there is broken or ambiguous.
  - A row marked `requested ·` carries an operator request (`sp ledger requested`, not withdrawn): weigh it first among equals. A `requested` line counts requests whose artifact has no row (broken down, sealed or parked) and names the first.
  - A `blocked` row (`sp ledger blocked`, listed first) is work stopped on the operator and carries the question: recommend answering it through `bottom-up` on the item, which ends with `sp ledger unblocked`.
- `sp check --all`: broken or ambiguous links make the graph unreliable there. Name them in the recommendation.

**Row order is class, then requested, then id.** Within a class, rows with a request in force come first (direction-006 amendment 2026-11-01), then by id. The `--awaiting` rows sit below every frontier row, never-checked first, then the oldest `checked` look (adr-0013). A larger id in a shallower class therefore prints above a smaller id in a deeper one. When the operator questions the order, show each row's class and check each artifact's class against its latest ledger line; direction-006 C3 owns the class order. Re-ranking across classes, or ranking by a declared sequence, is an amendment to direction-006 through `top-down` Phase 3. `sp` models no dependency relation, so an Epic's declared sequencing is not a rank key.

`sp frontier` already joins every tree. `sp frontier <id>` narrows to one Direction or Epic when the answer is cut (`+N more`); `--all` widens the cut output to every Direction when the ask is the whole repo.

**Without `sp`**, extract from frontmatter with `~/.agent-skills/facilitated-waterfall/what-next/scripts/frontmatter-graph.sh` (this skill's `scripts/`, linked there by `install.sh`; run with `sh`, first arg the repo root): one line per artifact, `kind|id|relates|intent`, with `relates` captured in both YAML forms. The grep below is its fallback:

```sh
# id + relates for every artifact, no bodies.
# `relates` appears in two YAML forms — inline `[a, b]` and block (`  - a` lines);
# the `  - ` arm catches the block form (keep only the lines sitting under `relates:`).
for d in product/directions product/epics product/stories directions epics tasks plans; do
  echo "=== $d ==="
  grep -rH "^id:\|^relates:\|^  - \|^intent:" docs/$d/ 2>/dev/null
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

These are the classes `sp frontier` lists, in its order; its fixture (`scripts/test.sh` case 39) tests them, so a change here changes it too. Cold, compute them by joining the extraction output on `relates` (split the field on commas, strip brackets and quotes) in a small script written to scratch and run via terminal (in an unattended session `execute_code` may be refused). When the run is scoped to one Direction or Epic (or one repo), compute the classes within that subtree and give the project-wide counts as one line of context. A link names an artifact by id or, in older docs and ledger lines, by path; both count. A **child** is a live artifact on a lower stage of the same layer; superseded artifacts, ADRs and probes are not children. Each artifact is listed once, in its highest class:

- **Childless product Directions** — no product Epic's or Story's `relates` contains its id.
- **Unengineered Stories** — no FW Direction's or Task's `relates` contains the Story's id. This is the hand-off frontier.
- **Open probes** — any `status: open` probe, in either layer. Resuming it ranks above starting new work in the same area.
- **Childless Directions** — no Epic's or Task's `relates` contains this Direction's id, and its latest `docs/directions/LEDGER.md` line is not `done` (adr-0009 amendment). A Direction broken straight into Tasks has children.
- **Childless Epics** — no Task's `relates` contains this Epic's id, and its latest `docs/epics/LEDGER.md` line is not `done`. An Epic whose own `## Tasks` manifest names a minted Task in another workspace (`repo:task-NNN`) is broken down there: `sp frontier` shows it as `Tasks in <repo>`, and its state is read in that repo (see *Multi-repo workspaces*).
- **Partly broken-down Epics** — an Epic with at least one minted Task (here, or `repo:task-NNN` in its manifest) whose `## Tasks` manifest still has `(planned)` rows, and whose latest `docs/epics/LEDGER.md` line is not `done`. It ranks with the childless Epics and closes with `/breakdown` of the rows still planned (task-035). Directions keep no planned-Epics manifest.
- **Unplanned Tasks** — no live Plan's `relates` contains this Task's id, and its latest `docs/tasks/LEDGER.md` line is neither `done` nor a Plan-less `implemented` (adr-0009; that one is awaiting an observed effect).
- **Unimplemented Plans** — every Plan whose id has no entry in `docs/plans/LEDGER.md`. A Plan with a ledger entry is implemented.

Sanity-check the counts against the ledger lines you just read. A stage that comes out almost entirely orphan, or an orphan the ledger contradicts (a Task whose Plan is in the plan ledger, counted "unplanned"), points at the extraction or the links: re-check 2–3 artifacts' raw frontmatter — inline vs block `relates`, id vs path form. When the links are genuinely under-maintained, say so in the recommendation and let Phase 3's codebase check decide.

A superseded artifact is sealed and is not an orphan. A Direction, Epic or Task whose latest line in its kind's ledger is `deferred` or `abandoned` is **parked** (adr-0009): it and the structure under it are in no class, counted on one line, until a later `reopened` line. Open probes under a parked artifact remain resume work. State comes from the ledgers, not from a written `status:` on a Direction, Epic, Task or Plan (`conventions` → Status & ledger).

One more class sits **below every frontier class**, as guidance:

- **Awaiting an observed effect**: an implemented Task — it has a Plan and every live Plan relating to it has a plan-ledger line — with no done or effect-not-achieved line in `docs/tasks/LEDGER.md` (a `checked` line from an earlier look keeps it here; adr-0013). Its mechanics were verified, and its intended effect in use is not yet seen. A Task built without a Plan qualifies by its own `implemented` line in `docs/tasks/LEDGER.md` (adr-0009); built work with no such line turns up in Phase 3's codebase check, and the fix is to record the line. A Task with a later `effect not achieved` line is a `bottom-up` trigger and ranks with open probes.

The **frontier** is the shallowest stage that has orphans — where the pipeline is blocked and work is most leveraged. Resolve upper stages before lower ones: nothing downstream of a Direction with no Epics can proceed.

## Phase 3 — Verify candidates against reality

The graph shows where docs are missing. For Directions, Epics and Tasks, check the codebase too: code is often written before its doc, so an orphan there may already be built. A Plan without a ledger entry is genuinely unimplemented (`docs/plans/LEDGER.md` records completion; a stale ledger is `audit-doc`'s question).

Take the top ~3 frontier candidates (shallowest orphans first). For each, read its own body if needed (`sp show <id> Goal`), then check reality:

- `grep`/`find` for the symbols, files, or features the artifact describes.
- `git log --oneline -- <relevant paths>` for commits touching that area.
- For a Plan, run its Verification commands when they're cheap shell checks.
- Judge each: **already done in code** (recommend documenting or skipping), **partial**, or **genuinely not started**.

Replace a candidate that is already implemented with the next-shallowest orphan. Use `git log` recency to break ties between equally-leveraged candidates.

## Phase 4 variant — full inventory (when the ask is "what's left", not "what's next")

When the operator asks for the *list* of what remains, the deliverable is the complete inventory, closed by a short "what I'd do first" (at most three lines, the sharpest levers, one sentence each).

Report in this order:

1. **Open probes** — each with what its `## Open questions` still needs.
2. **Frontier rows** by class — unplanned Tasks, unimplemented Plans, each with its intent line and its governing parent.
3. **Awaiting an observed effect** — the full list from `sp frontier --awaiting --all`, grouped by governing parent (first `relates` entry that sits higher), with the count and the ledger filter stated: how many rows have their own task-ledger line, how many are implemented through plan-ledger lines only.
4. **Parked** in one line (the `parked` line's counts).
5. **`sp check --all` classified by drift key** — the background classes in one line each (cross-workspace relates, pre-ledger written status, missing intent); breaks and downward `relates` named individually, each with its fix.
6. **The uncommitted git tree** as a WIP row.
7. **Multi-repo workspace** — one summary line per sibling tree, showing which repo holds what.

State the filter behind every count: frontier rows and drift lines are labels derived from the ledgers and the graph.

## Phase 4 — Recommend three, ranked

Present three next actions, ranked best-first. Each maps a frontier gap to the skill that closes it:

| Frontier | Action |
|----------|--------|
| No directions | Propose a problem statement from `README.md` (first 30 lines); `/shape` |
| `docs/product/` exists but no `docs/PRODUCT.md` | `reflect bootstrap` |
| Open probe | Resume it: `bottom-up` (`docs/probes/`) or `reflect` (`docs/product/probes/`). A probe whose only open leg is an effect wait: `observe` on it (adr-0013 §5), plus the next workable row |
| Product Direction with no Epics/Stories | `direct` Breakdown on that Direction |
| Story with no FW Direction/Task | `top-down` on that Story |
| Direction with no Epics | `/breakdown` on that Direction |
| Epic with no Tasks | `/breakdown` on that Epic |
| Task with no Plan | `/plan` on that Task |
| Plan not implemented | `/implement` on that Plan; name the failing/missing verification |
| Code exists but no doc | Document the built work so the graph reflects it; `/audit-doc` to check it stayed inside the ADRs/Plan |
| Effect not achieved (task ledger) | `bottom-up` with that ledger line as the Trigger |
| Awaiting an observed effect | `observe` on that Task (adr-0013): it reads where the Task's Effect check says the effect shows and leaves one line, `done`, `effect not achieved` or `checked`. When the operator says the effect has been seen, `observe` records that too, as their word |
| Everything implemented | Propose a new Direction angle from a gap in the README/codebase; `/shape` |

Rank by leverage: shallower frontier stages unblock more downstream work. "Awaiting an observed effect" ranks below every frontier row and takes a slot when fewer than three frontier gaps exist; otherwise give its count in one line. Give each recommendation one sentence of rationale naming the evidence. When fewer than three distinct gaps exist, recommend fewer.

**Multi-repo workspaces.** When the governed docs carry cross-workspace links (`repo:id`), prerequisites and consumers can sit in sibling repos, and the cross-repo epic's amendment or sequencing — read in the named repo — defines the order. Rank by it, and name the cross-repo task(s) in the recommendation. When grouping rows by governing parent, a `repo:`-prefixed or path-form link is a parent edge: group under the sibling repo it names. Before asserting who consumes what, read which surface the consumer consumes (a route, a feed, in-process events) in its latest amendment.

**Intent trace.** Under each recommendation, show the composed intent: one sentence per level, leaf to root, from the `intent:` lines gathered in Phase 1, following the first `relates` entry in list order that sits higher (`conventions` → Artifact formats; `sp trace <id>` gives it). Where a level has no `intent:`, write `<id>: no intent line`.

## Phase 5 — Offer to act

Ask:

> Want me to start with #1, or pick another?

If the user picks one, invoke the suggested skill with the context already gathered.

## Rules

- The relates graph and the codebase are ground truth.
- The cold extraction captures `relates` in both YAML forms (inline and block list).
- Cross-check candidates against the codebase before recommending, and replace any that are already built.
- Phases 1–2 read frontmatter only: `sp frontier` and `sp check --all`, or grep cold. Phase 3 reads bodies with `sp show <id> Goal`.
- Phase 3 inspects at most ~3 candidates.
- Resolve shallower frontier stages before deeper ones.
- A frontier row's rank comes from its class, then its id.
- In a multi-repo workspace, rank against the cross-repo epic's current sequencing, read in the named repo, and assert a consumption relationship after reading the consumer's latest amendment.
- Recommend three ranked actions, or fewer when fewer real gaps exist.
- State the filter behind any count taken from a ledger or the doc tree.
