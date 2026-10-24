---
name: facilitated-waterfall-conventions
description: Shared conventions for the facilitated-waterfall system — the waterline that divides commitment from mechanism, the append-only rule, artifact formats, frontmatter and numbering, status and ledger, and the batch check and commit step. Loaded by top-down and bottom-up. The drilling technique, the product layer, and the handbook machinery are in its references/ files; the audit method lives in audit-doc.
---

Shared reference for the facilitated-waterfall system. `top-down` and `bottom-up` load this file for their rules.

The system is an append-only, in-repo documentation pipeline. Work flows two ways and meets at the **waterline**:

```
Direction → Epic? → Task → ADR        (top-down: intent descends to the line)
                      ⭡      │
                      │      ▼
                    Plan → Code        (bottom-up: fixes ascend to the line)
```

- **Direction → Epic → Task** — top-down authors these (see `top-down`).
- **Plan + Code** — bottom-up authors these (see `bottom-up`).
- **ADR** — the shared ledger at the waterline. Top-down writes it looking forward; bottom-up supersedes it on contact with code. Both write it.
- **Probe** — bottom-up working memory (`docs/probes/`); the only mutable artifact.
- **Epic is optional** — use it only when one Direction spawns several ordered or dependent Tasks that need a manifest. Small work goes Direction → Tasks directly.

## Section index

| Section | Holds |
|---------|-------|
| The waterline | the line, and its two guards (descent, ascent) |
| Product layer | pointer → `references/product-layer.md`: the stacked product waterline, the Story seam, the binding commitments |
| Drilling technique | pointer → `references/drilling.md`: the shared interview technique |
| Depth & autonomy | when to interview, when to drive alone; Plan depth by author-blind risk |
| Append-only rule | supersede vs amend; the probe exception |
| Artifact formats | frontmatter, kind-prefixed ids, the section skeletons, the intent trace |
| The `sp` script | every verb and its cold fallback; `sp check` after every write |
| Handbook | pointer → `references/handbook.md`: the inherit points, the close (deposit, promote, cut test, gate) |
| Numbering | sequential kinds; collision-free probe ids |
| Batch check | whole-graph verification after a multi-artifact write; `scripts/check-graph.py` |
| Commit | the commit step: prior uncommitted work first, logical batches, verify before committing |
| Status & ledger | the status rule, the derived states, the ledger lines |
| Compliance & audit | pointer → `audit-doc`: the audit method and the system-specific checks |

Need one rule — the status rule, a skeleton, one `sp` verb? Read just that section from the installed copy of this skill instead of loading the whole file.

## The waterline

Every change sits somewhere on a ladder of abstraction. The **waterline** is the fixed altitude between *mechanism* (reversible, local — the engineer decides freely) and *commitment* (recorded, cross-cutting, expensive to reverse — needs an accepted trade-off to change).

```
ABOVE  ── Direction (intent)          commitment: append-only; change needs
       ── ADR (decision)              accepted trade-off, recorded as a
══════════ WATERLINE ══════════       superseding artifact
       ── architecture / pattern      the last rung settled by judgment
BELOW  ── module → class → placement  mechanism: reversible; decide freely
```

Two hard rules follow, one per direction:

- **Descent guard (top-down).** A descending change may **not** run straight into implementation. It stops at the underside of the line and hands off a *placed, bounded unit* (a Task, optionally grouped in an Epic).
- **Ascent guard (bottom-up).** An ascending change may **not** overturn an above-the-line commitment (ADR decision, Direction constraint/scope) without surfacing the trade-off and recording **accepted** supersession. If the trade-off isn't accepted, the fix is wrong — find a below-the-line mechanism that honors the decision.

## Product layer (when present)

If the project also runs `product-waterfall` (`docs/PRODUCT.md`, `docs/product/`), a second waterline stacks **above** this one, and the product **Story** is the seam. The full picture — the stack, the entry from above, the binding commitments, the two glossaries — is in `references/product-layer.md`.

## Drilling technique

The shared interview technique — sharpen fuzzy language, probe with scenarios, push back, resolve inline, cross-reference with code, challenge against the glossary — is in `references/drilling.md`.

## Depth & autonomy

- **Autonomy scales to tier.** A gap at the level of a Direction, or of the product, is about intent, so always interview the human. A gap at the level of a Task or ADR, where the answer can be derived from code and existing docs, may be driven autonomously. Escalate only on genuine ambiguity.
- **Plan depth follows author-blind risk, not importance.** Work gets a Plan, a `design` interview or a `zoom-in` when its author is likely blind to how it can go wrong: it is unfamiliar ground, has hidden coupling, or would be expensive to discover late. It does not get one just because it matters. Important work that is well understood goes straight through; small but treacherous work gets the depth.

## Append-only rule

Artifacts are not edited in place once they record a decision. A changed decision is captured by appending a **new** ADR whose `supersedes` field names the old one — the history of *why* stays intact. The old one gets one key and nothing else: `superseded-by`, naming the new one, so a reader of the old file sees it first (adr-0005). `sp supersede <new> --of <old>` writes both edges in one step.

**Supersede only a whole replacement; amend a partial one** (adr-0008). Supersession seals the old artifact, so it is right only when no part of it still governs. When the new artifact takes over some parts and the rest still holds, it writes no edge. Its body opens with what it takes over, part by part, and it keeps its ordinary upward `relates` link where its tier allows one. The old artifact gets one appended section, `## Amendment, YYYY-MM-DD: <what changed>`, which names the new id and the parts taken, and says the rest still holds. Earlier text is never edited. The test: is the old artifact wrong (supersede), or does it hold with a carve-out (amend)? A net-new **extension** of an existing artifact — adding fields to its record, widening its scope, with nothing replaced — is an amendment in this same `## Amendment, YYYY-MM-DD:` section form (name the extending sibling, what was added, and that the rest still holds), never an in-place edit of a section's body: a non-probe artifact that records a decision is changed only by an appended, dated `## Amendment` section.

The sole exception is the **Probe** (`docs/probes/`), which is working memory: mutable while `open`, frozen when `reconciled`. Everything a probe *produces* (ADRs, Tasks, CONTEXT entries) is append-only.

## Artifact formats

Every file carries frontmatter with at least `id`, `title`, `created`, and `relates: [...]`. List fields (`relates`, `supersedes`, `superseded-by`) carry identical links in either YAML form — inline (`[a, b]`) or block (one `  - a` per line) — so a reader must parse both; a tool that reads only one form silently drops links, and a file's list form is never rewritten to suit a parser that missed the other form. `relates` links point **upward** (Epic→Direction, Task→Epic/Direction, Plan→Task, ADR→artifact) and are fixed at creation. The one sanctioned change after creation is a repair: `sp relate` adds a missing upward edge (it refuses a broken, ambiguous or downward link); an existing link is never rewritten or removed. With a product layer, an FW Direction or Task may also point up across the seam to a Story (`docs/product/stories/NNN-slug.md`).

**The `id` is kind-prefixed** (adr-0006): `direction-NNN`, `epic-NNN`, `task-NNN`, `plan-NNN`, `adr-NNNN`, `probe-YYYY-MM-DD-slug`; with a product layer, `product-direction-NNN`, `product-epic-NNN`, `story-NNN`. `NNN` is the file's number. Links (`relates`, `supersedes`, `superseded-by`) and prose name artifacts by this id: "see task-084", never "Task 084", "084" or a path. File names keep their `NNN-slug.md` form; a probe is the exception, its file name being the id itself (`probe-YYYY-MM-DD-slug.md`), because the slug already lives in the id. Older path ids and bare numbers still resolve when read, until `sp migrate` converts them. A superseded artifact carries `superseded-by: [<id>]`, a list, written only by the supersede step.

```
docs/directions/NNN-slug.md   Problem · Appetite · Out of scope · Success signal · Constraints · Risk?
docs/epics/NNN-slug.md        Goal · Scope · Out of scope · Tasks · Sequencing · Done when   (optional tier)
docs/tasks/NNN-slug.md        Goal · Notes
docs/plans/NNN-slug.md        Context · Steps · Verification · Risk
docs/adr/NNNN-slug.md         Context · Decision · Consequences · Alternatives   (optional supersedes)
docs/probes/<id>.md           Trigger · Governing docs · Findings · Open questions · Deliberation · Risk · Reconciliation
docs/CONTEXT.md               Glossary of resolved domain terms — no implementation detail
```

- **Epic (optional).** The **Tasks** section is a manifest table of children with a `Depends on` column; **Sequencing** is the derived order (or "parallel"). Dependency edges live **only here** — do not duplicate `Depends on / Blocks / Order:` onto individual Tasks. An Epic written before its Tasks are minted lists the planned children as `(planned)` rows with the note that files mint at the Epic → Tasks breakdown; replace each row with its id as it is minted.
- **Risk** (one line each: blast radius · rollback · cost-of-wrong) is required on Plans, optional on Directions.
- **`intent:` (optional).** A one-sentence frontmatter line saying what the artifact is *for*. The authoring stages write it once the interview has settled the Goal or Problem. Never invent one to fill the key.
- **Intent trace.** Walk `relates` upward from any artifact, following at each level the **first `relates` entry in list order that sits higher** (Plan → Task → Epic → Direction → Story → product Epic → product Direction); ADRs, probes and same-tier entries are passed over. Read each level's `intent:`. The result is one sentence per level, leaf to root. A level without `intent:` is reported as a gap (`<id>: no intent line`). It is never filled in by inference. Older artifacts predate the key, so a gap is information, not a defect. A broken link is reported, never followed. So is a link into another workspace (`repo:id` or a path outside `docs/`), which is not broken; a probe or ADR there is passed over like one here. `sp trace <id>` walks it.

- **The glossary is the canonical home for resolved terms** (`docs/CONTEXT.md`). When documents disagree about a term — a count, an example, a scope — fix the entry and let the documents defer to it; a stale example is fixed in place, in the same batch as the work that made it stale (the glossary has no history, so a stale example is a live misreading). A decision that *changed* still goes through the append-only machinery; the glossary entry just follows the current decision.

## The `sp` script

`sp` is at `~/.agent-skills/facilitated-waterfall/scripts/sp`. It is not on `PATH`: test that file, not `which sp`. Both waterfalls use it to read and write artifacts. `nav` is an older name for its read verbs and still works. Always pass an id or a target path, so it resolves the right workspace; give `-C <repo>` when the id alone doesn't say which.

| To | Run | Without `sp` (cold) |
|----|-----|---------------------|
| Make an artifact | `sp new <kind> "<title>" --relates <id>,… --intent "…"` | Take the next number from the highest file in the kind's directory, and write the frontmatter and sections of *Artifact formats* by hand |
| Supersede | `sp supersede <new> --of <old>` | Add `supersedes: [<old>]` to the new one and `superseded-by: [<new>]` to the old one, nothing else |
| Amend part of an artifact (adr-0008) | No verb: append `## Amendment, YYYY-MM-DD: …` to the old artifact by hand; no edge | Same |
| Repair a missing link | `sp relate <id> --to <parent id>` — adds one upward edge, refuses a broken, ambiguous or downward one | Add the parent's id to `relates` by hand |
| Record a Plan's mechanics verified | `sp ledger implemented <plan-id> "<N>/<N> checks passed"` | Append the line of *Status & ledger* |
| Record a Plan-less Task built (adr-0009) | `sp ledger implemented <task-id> "<evidence>"` | Same |
| Park or unpark work (adr-0009) | `sp ledger deferred <id> "<why; what reopens it>"` · `sp ledger abandoned <id> "<why>"` · `sp ledger reopened <id> "<why>"` | Same, in the kind's own ledger |
| Record an effect seen, or not | `sp ledger done <task-id|direction-id|epic-id> "<what was seen, where>"` · `sp ledger not-achieved <task-id> "<what was seen>"` | Same |
| Close a probe | `sp ledger reconcile <probe-id> "<outcome>"` (it also sets `status: reconciled`) | Append the probe ledger line and set the status |
| Check what you wrote | `sp check <id>` | — (`sp check` reports any drift later) |
| Orient on an artifact | `sp tree <id>` (descendants, their state, next free numbers), `sp trace <id>` | Walk `relates` by hand |
| List the not-done work | `sp frontier [<id>]` (orphans in `what-next`'s classes, shallowest stage first; `--awaiting` lists Tasks awaiting an observed effect) | `what-next`'s grep method |
| Read part of a doc | `sp outline <id>`, then `sp show <id> <heading or item id>…` | Read the file |

- **After every write, run `sp check <id>`** on what was written, and fix any `break` line before going on. Each line says what to do.
- **A `relates` entry into another workspace (`repo:id`) is reported as standing informational drift** (`names another workspace: not followed`) — expected, not a break line. Keep the link; do not remove it to silence the check.
- **A cross-workspace link that navigation actually needs is resolved in the named repo.** The check skips it; a question or a recommendation that must follow it does not — run `sp` against that repo (`-C <repo>` or the repo path), where the verbs and the cold column apply unchanged. Numbering restarts per repo, so a bare id is ambiguous across a multi-repo workspace: carry the `repo:` prefix when naming an artifact across the boundary, and resolve it when the user hands you a bare one. When the user names a *component* rather than an id, the owning repo is declared in the governing Direction's Constraints; confirm built-or-not in that repo's code tree, not only its docs.
- **Every `sp` answer starts with its summary.** Read it first; a `+N more` line means the answer was cut, and says how to narrow it.
- **Unsure how a verb works?** `sp <command> help` prints its page: usage, what it writes, examples, the next step. `sp help` lists every command.
- **Skills work without `sp`.** The cold column is the rule then; `sp check` reports any drift when the script is back. A skill never refuses to run for lack of it.
- **`sp` present but the runtime refuses to execute it** — a host guard failing closed on the script itself (e.g. the hermes gateway lifecycle guard: empty output, or a scan-budget refusal; see `hermes-agent` → troubleshooting) — is the missing-`sp` case for purposes of the skill: drive the cold column, or run `sp` from an unsupervised process. The refusal is a runtime defect to unblock, not a reason to skip the system.
- **`sp` can log its own calls.** With `SP_LOG` set to a path outside any repo, every call appends one record; `sp log` lists the failed and flagged ones, each with a rerun line, for `debugging:improve-sp`. Unset, `sp` writes no log.

## Handbook

The handbook (`docs/handbook/`, five fixed files) is the one store the knowledge skills write and read: `general-usage` `note` writes it, `recall` reads it. Its session machinery — the **inherit points** (the `sp` query per target, tiered reading, the budget share, the read-depth statement) and the **close** (deposit, promote or demote, the cut test, the reconciliation gate) — is in `references/handbook.md`. A cite to `conventions → Handbook → Inherit` or `→ Deposit at a close` means that file.

## Numbering

- **Directions, Epics, Tasks, ADRs, Plans** — numbered sequentially from the highest existing file in their directory. `sp new <kind>` takes the next number under a lock, so parallel sessions never collide; `sp tree <id>` shows the next free number per kind. Cold, allocate a whole breakdown batch in one pass.
- **Probes** — created ad hoc and in parallel, so they use **collision-free** ids: `probe-YYYY-MM-DD-slug` (`sp new probe "<title>"`). A sequential `NNN` is assigned only at reconcile, single-threaded, when a durable artifact is minted.

## Batch check

Per-file `sp check` is the reflex, but a multi-artifact write (a breakdown batch, a reconciliation) needs the whole graph. Run `~/.agent-skills/facilitated-waterfall/conventions/scripts/check-graph.py [repo root or docs dir]` (this skill's `scripts/`, linked there by `install.sh`): it reports same-repo `relates` / `supersedes` / `superseded-by` references that do not resolve, duplicate ids, and non-sequential numbering per kind. Cross-workspace entries (`repo:id`, or a path outside `docs/`) are expected and skipped — the same rule as `sp check`'s informational drift. Fix the breaks before committing.

## Commit

An artifact is durable when committed; an uncommitted batch is work in progress, never done. Before committing this session's work:

1. `git status` the repo. If *prior* uncommitted work exists (a previous session, possibly unrelated), commit it first as its own logical commit — never fold it into yours, and never write on top of a mixed tree. Judge committability before acting: a *complete* batch (reconciled, verified, its own logical unit) commits first; work that is *deliberately parked* — half-built, or whose own ledger line says deferred — is the user's WIP, not yours to finish: leave it in place, flag it to the user, and path-scope your commit (`git commit -- <your files>`) so it can never fold in.
2. Commit this session's work as logical batches: a reconciliation is one commit (the probe, the artifacts it produced, the amendments, the glossary entries, the ledger lines); a breakdown is one (the Epics or Tasks, plus the glossary entries they use).
3. Verify what you just wrote before the commit: markdown has no linter safety net, so a patch that landed non-exact can silently corrupt a region — read the changed region back (or `git diff` the batch), then `sp check` each artifact.

## Status & ledger

- **Probes** carry a written `status:`: `open` · `reconciled` · `abandoned`. They are the one mutable artifact.
- **Directions, Epics, Tasks and Plans never get a `status:` written**. Completion is recorded in ledgers, never by editing the artifact. Their state is derived from the `relates` graph, the ledgers and the codebase:
  - `todo`: no ledger line yet, and no sign of work started — no live (unimplemented) Plan beneath it, no `open` probe naming it, and no commit since its `created` date in its area: the paths its live Plan(s) touch, or, where it has none, the paths its own Steps or Goal name;
  - `in-progress`: no ledger line yet, but at least one of those signs is present;
  - **`implemented`**: the mechanics are verified. Every Verification item in the Plan passed, recorded as a `docs/plans/LEDGER.md` line by `implement` (`sp ledger implemented <plan-id> "N/N passed"`): `- <plan-id> — implemented DATE — verification: N/N passed`. A Task is implemented when all its Plans are. A Task built without a Plan gets its own line (adr-0009): `- <task-id> — implemented DATE — evidence: <commits, a reconciled probe, or paths>` in `docs/tasks/LEDGER.md` (`sp ledger implemented <task-id> "<evidence>"`, which is refused while the Task has a live Plan). Without that line, `sp` counts it as unplanned.
  - **`done`**: the **intended effect was observed** at a later real opportunity, in use and not in a replay of Verification. It is recorded as one line in `docs/tasks/LEDGER.md` (`sp ledger done <task-id> "<observed>"`): `- <task-id> — done DATE — effect: <what was observed, and where>`. A Direction or Epic finished without children (its work went through probes or code, never a breakdown) takes the same line in its own kind's ledger, `docs/directions/` or `docs/epics/LEDGER.md` (`sp ledger done <id> "<observed>"`, adr-0009 amendment). It is then not a childless row. Unlike a deferral, it parks nothing under it.
- **No done line means "not yet observed."** Write no placeholder. An observation that the effect did *not* happen is `- <task-id> — effect not achieved DATE — <what was observed>` (`sp ledger not-achieved`). That leaves the Task `implemented`, and it is a `bottom-up` trigger.
- An effect line must name an observation from use. **Restating the Verification result ("tests pass", "N/N checks") is not an effect.** It is the failure this record exists to catch, so leave the line unwritten instead.
- **A Task that serves a Story** (its `relates` chain reaches `docs/product/stories/`) is judged against the Story's **Outcome**, not only its own Goal. Its effect line says what was observed of that Outcome: `effect: <observed> — story-NNN Outcome: met | not met`. The format is unchanged otherwise, and `effect not achieved` stays a `bottom-up` trigger; its climb crosses the seam to the Story.
- **Parked work** (adr-0009). A Direction, Epic or Task set aside on purpose gets `- <id> — deferred DATE — <why; what would reopen it>`, and one that will not be built gets `- <id> — abandoned DATE — <why>`. Each goes in its own kind's ledger (`docs/directions/`, `docs/epics/`, `docs/tasks/LEDGER.md`), through `sp ledger deferred|abandoned <id> "…"`. `sp frontier` leaves the artifact and the structure under it off its rows, and counts them on a `parked` line. `- <id> — reopened DATE — <why>` (`sp ledger reopened`) brings it back. A replaced artifact is superseded instead, not abandoned.
- **Backfilling a pre-ledger `status:`** (adr-0009). When a repo drops its written status keys, each one that recorded what a line can hold becomes that line, dated the day of the backfill, saying it was backfilled from which status, and naming the evidence. A pre-ledger `done` or `implemented` on a Plan-less Task becomes an implemented line, **never** a done line, because pre-ledger "done" meant built. `deferred` becomes a deferred line. A status the ledger or the edges already imply (a ledgered Plan, `superseded-by`) needs no line.
- Ledgers are append-only. A correction is a new line; the later line wins. Lines name artifacts by id; older lines with paths stay valid.

## Compliance & audit

The audit method — collecting the boundaries, judging the code against each, the cause tags, the report — lives in `audit-doc`, which also carries the system-specific checks (waterline crossed without acceptance, stale glossary, open-probe drift, product line crossed). Invoke it directly; it is read-only and writes nothing. `conventions` holds no copy of it.
