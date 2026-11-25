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
- **Epic is optional** — use it when one Direction spawns several ordered or dependent Tasks that need a manifest. Small work goes Direction → Tasks directly.

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

To use one rule — the status rule, a skeleton, one `sp` verb — read that section from the installed copy of this skill.

## The waterline

Every change sits somewhere on a ladder of abstraction. The **waterline** is the fixed altitude between *mechanism* (reversible, local — the engineer decides freely) and *commitment* (recorded, cross-cutting, expensive to reverse — changes through an accepted trade-off).

```
ABOVE  ── Direction (intent)          commitment: append-only; change needs
       ── ADR (decision)              accepted trade-off, recorded as a
══════════ WATERLINE ══════════       superseding artifact
       ── architecture / pattern      the last rung settled by judgment
BELOW  ── module → class → placement  mechanism: reversible; decide freely
```

Two rules follow, one per direction:

- **Descent guard (top-down).** A descending change stops at the underside of the line and hands off a *placed, bounded unit* (a Task, optionally grouped in an Epic). Implementation is a separate step.
- **Ascent guard (bottom-up).** An ascending change alters an above-the-line commitment (ADR decision, Direction constraint/scope) through a surfaced trade-off and a recorded, **accepted** supersession. Without acceptance, find a below-the-line mechanism that honors the decision.

## Product layer (when present)

When the project also runs `product-waterfall` (`docs/PRODUCT.md`, `docs/product/`), a second waterline stacks **above** this one, and the product **Story** is the seam. The full picture — the stack, the entry from above, the binding commitments, the two glossaries — is in `references/product-layer.md`.

## Drilling technique

The shared interview technique — sharpen fuzzy language, probe with scenarios, push back, resolve inline, cross-reference with code, challenge against the glossary — is in `references/drilling.md`.

## Depth & autonomy

- **Autonomy scales to tier.** A gap at the level of a Direction, or of the product, is about intent: interview the human. A gap at the level of a Task or ADR, where the answer can be derived from code and existing docs, may be driven autonomously, escalating on genuine ambiguity.
- **Plan depth follows author-blind risk.** Work gets a Plan, a `design` interview or a `zoom-in` when its author is likely blind to how it can go wrong: unfamiliar ground, hidden coupling, or expensive to discover late. Important, well-understood work goes straight through; small but treacherous work gets the depth.

## Append-only rule

An artifact that records a decision keeps its text once committed. A changed decision is captured by appending a **new** ADR whose `supersedes` field names the old one, so the history of *why* stays intact. The old one gets one key: `superseded-by`, naming the new one, so a reader of the old file sees it first (adr-0005). `sp supersede <new> --of <old>` writes both edges in one step.

**Supersede a whole replacement; amend a partial one** (adr-0008). Supersession seals the old artifact, so it fits when no part of it still governs. When the new artifact takes over some parts and the rest still holds, it writes no edge: its body opens with what it takes over, part by part, and it keeps its ordinary upward `relates` link where its tier allows one. The old artifact gets one appended section, `## Amendment, YYYY-MM-DD: <what changed>`, naming the new id and the parts taken, and saying the rest still holds. The test: is the old artifact wrong (supersede), or does it hold with a carve-out (amend)? A net-new **extension** — adding fields to its record, widening its scope, nothing replaced — is an amendment in the same section form, naming the extending sibling, what was added, and that the rest still holds. A committed decision artifact changes only by an appended, dated `## Amendment` section.

The exception is the **Probe** (`docs/probes/`), which is working memory: mutable while `open`, frozen when `reconciled`. Everything a probe *produces* (ADRs, Tasks, CONTEXT entries) is append-only. A probe grows by appending: new evidence lands in a dated block that continues the existing finding/question numbering, and an answered question is *marked* — struck through with the date, the resolver, and a pointer to where it is handled, original wording kept under the strike. A new `relates` edge on a probe goes through `sp relate` (one call per edge; it validates the link). After every write to a probe, run `sp check <id>` (one argument) before going on.

**A draft is not yet an artifact.** An above-the-line artifact that has never been committed and never read by another session is this batch's draft: correct a false or unverifiable line in it — a citation to a file that does not exist, a quote its own file cannot support, a term naming a mechanism nobody chose — **in place** while the batch is open, with the reason in the probe or commit message. Supersession and `## Amendment` apply to decisions that were held and recorded. Once the batch commits, the append-only rule binds the artifact.

**A Plan records mechanism** (the below-waterline rung), so the `## Amendment` form does not bind it. Fix a factually wrong line in a Plan (a command that no longer exists, a path that moved, a file the tree has outgrown) in place with an inline dated correction marker; the probe finding that drove the correction carries the record. A `status:` or a completion stays in the ledger. The test, a rung lower: is the line wrong (fix in place, marker + probe record), or does it still hold (leave it)?

## Artifact formats

Every file carries frontmatter with at least `id`, `title`, `created`, and `relates: [...]`. List fields (`relates`, `supersedes`, `superseded-by`) carry identical links in either YAML form — inline (`[a, b]`) or block (one `  - a` per line). Readers parse both, and a file keeps the list form it was written in. Frontmatter is a delimited block — opening `---`, the keys, a **closing `---`** line, then the first section; the section skeletons below list sections, not delimiters:

```yaml
---
id: probe-2026-11-25-some-topic
title: "a short title"
created: 2026-11-25
status: open
relates:
  - task-012
---
```

A file missing the closing `---` is a `sp check` **break** (`no closing ---`): the keys cannot be parsed.

`relates` links point **upward** (Epic→Direction, Task→Epic/Direction, Plan→Task, ADR→artifact) and are fixed at creation. After creation, `sp relate` may add a missing upward edge (it refuses a broken, ambiguous or downward link); existing links stay as written. With a product layer, an FW Direction or Task may also point up across the seam to a Story (`docs/product/stories/NNN-slug.md`).

**The `id` is kind-prefixed** (adr-0006): `direction-NNN`, `epic-NNN`, `task-NNN`, `plan-NNN`, `adr-NNNN`, `probe-YYYY-MM-DD-slug`; with a product layer, `product-direction-NNN`, `product-epic-NNN`, `story-NNN`. `NNN` is the file's number. Links (`relates`, `supersedes`, `superseded-by`) and prose name artifacts by this id: "see task-084". File names keep their `NNN-slug.md` form; a probe's file name is the id itself (`probe-YYYY-MM-DD-slug.md`). Older path ids and bare numbers still resolve when read, until `sp migrate` converts them. A superseded artifact carries `superseded-by: [<id>]`, a list, written by the supersede step.

**Verify every body citation against the live file as you write it.** A `file:line`, a section number or a quoted line carries the weight of a link, and `sp check` and the batch checker read frontmatter only. So: read the section you name; `grep -n` the line you quote; re-read a commit stamp with `git log -1 --format='%h %ad %s' --date=iso-strict` before quoting its hash and date; and prefix the repo on an id that lives in another repo (a bare id means this repo's numbering). Anything carried in from a prior pass, a compacted summary, or memory is re-verified first — the evidence-string rule of *Status & ledger*, applied to doc bodies.

```
docs/directions/NNN-slug.md   Problem · Appetite · Out of scope · Success signal · Constraints · Risk?
docs/epics/NNN-slug.md        Goal · Scope · Out of scope · Tasks · Sequencing · Done when   (optional tier)
docs/tasks/NNN-slug.md        Goal · Effect check · Notes
docs/plans/NNN-slug.md        Context · Steps · Verification · Risk
docs/adr/NNNN-slug.md         Context · Decision · Consequences · Alternatives   (optional supersedes)
docs/probes/<id>.md           Trigger · Governing docs · Findings · Open questions · Deliberation · Risk · Reconciliation
docs/CONTEXT.md               Glossary of resolved domain terms — no implementation detail
```

- **Epic (optional).** The **Tasks** section is a manifest table of children with a `Depends on` column; **Sequencing** is the derived order (or "parallel"). Dependency edges live in this table only. An Epic written before its Tasks are minted lists the planned children as `(planned)` rows, noting that files mint at the Epic → Tasks breakdown; replace each row with its id as it is minted.
- **Effect check (Task)** (adr-0013 §3). Where the Task's effect will show and how a later evidence pass judges it, as four bullets: **Where** (a store, route, log or command), **Seen** (what counts as the effect observed in use), **Not achieved** (what counts as its failure), **Earliest** (the first real opportunity for it to show). `breakdown` and `top-down` write it on every new Task. A Goal with no observable effect beyond its Verification — a refactor, pure mechanism — takes one line under the heading saying so, and reaches its end through the plan ledger. A Task written without the section stays valid (direction-002, Retrofitting); it gets one when an evidence pass (`observe`) first looks at it, as an appended `## Amendment, YYYY-MM-DD: effect check`. The check says where to look; the evidence is what the pass reads there.
- **Risk** (one line each: blast radius · rollback · cost-of-wrong) is required on Plans, optional on Directions.
- **`intent:` (optional).** A one-sentence frontmatter line saying what the artifact is *for*. The authoring stages write it once the interview has settled the Goal or Problem, and leave the key out until then.
- **Intent trace.** Walk `relates` upward from any artifact, following at each level the **first `relates` entry in list order that sits higher** (Plan → Task → Epic → Direction → Story → product Epic → product Direction); ADRs, probes and same-tier entries are passed over. Read each level's `intent:`. The result is one sentence per level, leaf to root. A level without `intent:` is reported as a gap (`<id>: no intent line`), as written — older artifacts predate the key. A broken link is reported and not followed. So is a link into another workspace (`repo:id` or a path outside `docs/`), which is not broken; a probe or ADR there is passed over like one here. `sp trace <id>` walks it.

- **The glossary is the canonical home for resolved terms** (`docs/CONTEXT.md`). When documents disagree about a term — a count, an example, a scope — fix the entry and let the documents defer to it. The glossary has no history: fix a stale example in place, in the same batch as the work that made it stale. A decision that *changed* still goes through the append-only machinery; the glossary entry follows the current decision.

## The `sp` script

`sp` is at `~/.agent-skills/facilitated-waterfall/scripts/sp`; a profile install may also put a copy on `PATH`. Test that file. Both waterfalls use it to read and write artifacts. `nav` is an older name for its read verbs and still works. Pass an id or a target path so it resolves the right workspace; give `-C <repo>` when the id alone doesn't say which. `-C` is a global flag and sits before the subcommand (`sp -C <repo> frontier`). Equivalently, `cd` into the repo and run the bare verb.

| To | Run | Without `sp` (cold) |
|----|-----|---------------------|
| Make an artifact | `sp new <kind> "<title>" --relates <id>,… --intent "…"` | Take the next number from the highest file in the kind's directory, and write the frontmatter and sections of *Artifact formats* by hand |
| Supersede | `sp supersede <new> --of <old>` | Add `supersedes: [<old>]` to the new one and `superseded-by: [<new>]` to the old one, nothing else |
| Amend part of an artifact (adr-0008) | No verb: append `## Amendment, YYYY-MM-DD: …` to the old artifact by hand; no edge | Same |
| Repair a missing link | `sp relate <id> --to <parent id>` — adds one upward edge, refuses a broken, ambiguous or downward one | Add the parent's id to `relates` by hand |
| Record a Plan's mechanics verified | `sp ledger implemented <plan-id> "<N>/<N> checks passed"` | Append the line of *Status & ledger* |
| Record a Plan-less Task built (adr-0009) | `sp ledger implemented <task-id> "<evidence>"` | Same |
| Park or unpark work (adr-0009) | `sp ledger deferred <id> "<why; what reopens it>"` · `sp ledger abandoned <id> "<why>"` · `sp ledger reopened <id> "<why>"` | Same, in the kind's own ledger |
| Request work, or withdraw it (task-035) | `sp ledger requested <id> "<note>"` · `sp ledger withdrawn <id> "<why>"` — a Direction, Epic, Task, Plan or open probe; refused when done, superseded, deferred, abandoned or parked, for a closed probe, an implemented Plan, an ADR or a product artifact | Same, in the kind's own ledger |
| Mark work blocked on the operator, or clear it | `sp ledger blocked <id> "<question — working probe>"` · `sp ledger unblocked <id> "<what was decided>"` — what a request takes, under the same refusals; refused when already blocked | Same, in the kind's own ledger |
| Record an effect seen, or not | `sp ledger done <task-id|direction-id|epic-id> "<what was seen, where>"` · `sp ledger not-achieved <task-id> "<what was seen>"` | Same |
| Record a look that saw nothing yet (adr-0013) | `sp ledger checked <task-id> "looked at <where>; <what is still missing>"` — only a Task awaiting an observed effect | Same |
| Close a probe | `sp ledger reconcile <probe-id> "<outcome>"` (it also sets `status: reconciled` — a product probe: `resolved`) | Append the probe ledger line and set the status |
| Check what you wrote | `sp check <id>` | — (`sp check` reports any drift later) |
| Orient on an artifact | `sp tree <id>` (descendants, their state, next free numbers), `sp trace <id>` | Walk `relates` by hand |
| List the not-done work | `sp frontier [<id>]` (orphans in `what-next`'s classes, shallowest stage first, requested rows first within a class; `--awaiting` lists Tasks awaiting an observed effect, and `--awaiting --all` prints the whole uncut list — the default can be cut by a `+N more` line) | `what-next`'s grep method |
| Give a program the graph (adr-0010) | `sp export [<id>]` — one JSON document on stdout, `version` 1: each artifact's id, kind, path, title, intent, links, derived state, latest ledger line, frontier row and the request in force. For programs; it has no summary line and is never cut, so a model reads `tree`, `frontier` and `show` | — (run `sp`) |
| Search the docs for a topic (adr-0011) | `sp search "<pattern>"` — live docs only, one row per doc with its first matching line; sealed docs (closed probes, ledgered Plans, superseded ADRs) are counted, and `--sealed` lists them when the question is about history | `grep -rniE "<pattern>" docs/`, reading sealed docs only for history questions |
| Read part of a doc | `sp outline <id>`, then `sp show <id> <heading or item id>…` | Read the file |

- **After every write, run `sp check <id>`** on what was written, and fix any `break` line before going on. `check` takes **one** argument: a multi-artifact batch is one call per artifact. Each line says what to do.
- **A `relates` entry into another workspace (`repo:id`)** shows as standing informational drift (`names another workspace: not followed`). Keep the link.
- **Follow a cross-workspace link in the named repo.** Run `sp` against that repo (`-C <repo>` or the repo path), where the verbs and the cold column apply unchanged. Numbering restarts per repo: carry the `repo:` prefix when naming an artifact across the boundary, and resolve a bare id the user hands you. When the user names a *component* rather than an id, the owning repo is declared in the governing Direction's Constraints; confirm built-or-not in that repo's code tree as well as its docs.
- **Every `sp` answer starts with its summary.** Read it first; a `+N more` line means the answer was cut, and says how to narrow it.
- **Patch against the file as it is on disk now.** `sp check` prints `regenerated` in its header when it re-normalizes an artifact, and in a multi-session workspace another writer may commit between your reads. Re-read the region (and, for an append-only log, its tail) before patching: after a compaction, after an `sp` run, and when the edit tool reports the file changed since your last read. A compaction replays this session's earlier reads as they were then, so re-read every file you intend to patch afterwards. Prose files soft-wrap: a multi-line `old_string` must match the on-disk line breaks; when a patch on a long prose span fails, retry with a short unique single-line fragment (a `file:line` token, a parenthetical). A patch that fails on a file this session never edited means an external move — diagnose it first (the Commit section). When the file has been restructured, write the whole probe (the only mutable artifact).
- **Use absolute paths in file-edit tools when the target repo is not the session's cwd.** They resolve relative paths against the cwd; a refusal naming another repo's path is the sign. `sp` takes the same disambiguation via `-C <repo>`.
- **The `next` line of `sp tree` lists the next free number per kind.** Verify an id with `sp outline` before citing it: `names no doc` means the id is free.
- **To learn a verb,** `sp <command> help` prints its page: usage, what it writes, examples, the next step. `sp help` lists every command.
- **Skills work without `sp`.** The cold column is the rule then; `sp check` reports any drift when the script is back.
- **This table and the installed script can differ in both directions.** Confirm a verb in `sp help` (or `sp <command> help`) before relying on it. When the verb is missing, take the cold column — for a look that saw nothing yet, append the `checked` line by hand or record the look in the probe's findings, noting the verb is pending — and carry on. When the installed script carries something this doc does not name, record the gap in the probe as a dated finding.
- **When the runtime refuses to execute `sp`** — a host guard failing closed on the script (for example, the hermes gateway lifecycle guard: empty output, or a scan-budget refusal; see `hermes-agent` → troubleshooting) — treat it as the missing-`sp` case: drive the cold column, or run `sp` from an unsupervised process, and report the refusal as a runtime defect to unblock.
- **`sp` can log its own calls.** With `SP_LOG` set to a path outside any repo, every call appends one record; `sp log` lists the failed and flagged ones, each with a rerun line, for `debugging:improve-sp`. Unset, `sp` writes no log.

## Handbook

The handbook (`docs/handbook/`, five fixed files) is the one store the knowledge skills write and read: `general-usage` `note` writes it, `recall` reads it. Its session machinery — the **inherit points** (the `sp` query per target, tiered reading, the budget share, the read-depth statement) and the **close** (deposit, promote or demote, the cut test, the reconciliation gate) — is in `references/handbook.md`. A cite to `conventions → Handbook → Inherit` or `→ Deposit at a close` means that file.

## Numbering

- **Directions, Epics, Tasks, ADRs, Plans** — numbered sequentially from the highest existing file in their directory. `sp new <kind>` takes the next number under a lock, so parallel sessions get distinct numbers; `sp tree <id>` shows the next free number per kind. Cold, allocate a whole breakdown batch in one pass.
- **Probes** — created ad hoc and in parallel, so they use **collision-free** ids: `probe-YYYY-MM-DD-slug` (`sp new probe "<title>"`). A sequential `NNN` is assigned at reconcile, single-threaded, when a durable artifact is minted.

## Batch check

After a multi-artifact write (a breakdown batch, a reconciliation), check the whole graph with `~/.agent-skills/facilitated-waterfall/conventions/scripts/check-graph.py [repo root or docs dir]` (this skill's `scripts/`, linked there by `install.sh`). It reports same-repo `relates` / `supersedes` / `superseded-by` references that do not resolve, duplicate ids, and non-sequential numbering per kind. It skips cross-workspace entries (`repo:id`, or a path outside `docs/`).

- **An anchored path link inside `docs/`** (`docs/PRODUCT.md#D-029`) reports `— file missing`, because the checker appends `.md`. The anchor exists; count these lines with the pre-existing drift.
- **Use the shipped script** and filter its output to the files this batch wrote. Those lines must be clean; fix their breaks before committing.
- **Report pre-existing drift as a count with its filter** ("0 break, N drift, none naming this batch"), naming the classes (anchor lines, a missing number in a kind, missing `intent:` on old artifacts, downward `relates`, cross-workspace entries). That backlog stays out of this batch.

## Commit

An artifact is durable once committed; an uncommitted batch is work in progress. Before committing this session's work:

1. **Read `git status`, both columns.** Staged work from a prior session (left-column `A`/`M`) goes into any unscoped `git commit`, so a dirty index counts as a mixed tree. When *prior* uncommitted work exists, judge it first:
   - a *complete* batch (reconciled, verified, its own logical unit) commits first, as its own commit;
   - work that is *deliberately parked* — half-built, or whose own ledger line says deferred — is the user's: leave it in place, flag it, and path-scope your commit (`git commit -- <your files>`).
2. **Commit this session's work as logical batches.** A reconciliation is one commit (the probe, the artifacts it produced, the amendments, the glossary entries, the ledger lines); a breakdown is one (the Epics or Tasks, plus the glossary entries they use).
3. **Verify what you wrote before the commit.** Read the changed region back (or `git diff` the batch), then `sp check` each artifact. Read a ledger diff's hunks directly (`sed -n` / `cut`): ledger entries begin with `- `, so an added entry reads `+- ` and a filter such as `grep -v '^[+-][+-]'` hides it.
4. **Shared append targets** — the ledgers (one per kind) and the glossary — may hold another stream's uncommitted lines. Check `git diff -- <file>`:
   - only your lines → commit the file;
   - your lines plus another stream's *finished* ledger lines that you verified against the live state they claim (a block row, a run row, the store the line names) → commit the file and name the borrowed lines in the gate and the commit message (an append-only ledger line is a completed record; a user approving the bundle counts too);
   - anything else (prose, or foreign lines you cannot verify) → write your line, leave the file uncommitted, path-scope the commit to the rest of the batch, and tell the user the line awaits the file's next commit.

   Hold a file back too when its lines, even all yours, assert facts (a date, a count, a verified stamp) about *another uncommitted* file in the batch — for example, a handbook `index.md` date over uncommitted entries. It commits with or after that file.

## Status & ledger

- **Probes** carry a written `status:`: `open` · `reconciled` · `abandoned` (a product probe: `open` · `resolved` · `abandoned` — the `sp` verb is shared, the vocabulary is per system). They are the one mutable artifact.
- **Directions, Epics, Tasks and Plans carry no `status:`.** Completion is recorded in ledgers. Their state is derived from the `relates` graph, the ledgers and the codebase:
  - `todo`: no ledger line yet, and no sign of work started — no live (unimplemented) Plan beneath it, no `open` probe naming it, and no commit since its `created` date in its area: the paths its live Plan(s) touch, or, where it has none, the paths its own Steps or Goal name;
  - `in-progress`: no ledger line yet, but at least one of those signs is present;
  - **`implemented`**: the mechanics are verified. Every Verification item in the Plan passed, recorded as a `docs/plans/LEDGER.md` line by `implement` (`sp ledger implemented <plan-id> "N/N passed"`): `- <plan-id> — implemented DATE — verification: N/N passed`. A Task is implemented when all its Plans are. A Task built without a Plan gets its own line (adr-0009): `- <task-id> — implemented DATE — evidence: <commits, a reconciled probe, or paths>` in `docs/tasks/LEDGER.md` (`sp ledger implemented <task-id> "<evidence>"`, refused while the Task has a live Plan). Without that line, `sp` counts it as unplanned.
  - **`done`**: the **intended effect was observed** at a later real opportunity, in use. It is recorded as one line in `docs/tasks/LEDGER.md` (`sp ledger done <task-id> "<observed>"`): `- <task-id> — done DATE — effect: <what was observed, and where>`. A Direction or Epic finished without children (its work went through probes or code) takes the same line in its own kind's ledger, `docs/directions/` or `docs/epics/LEDGER.md` (`sp ledger done <id> "<observed>"`, adr-0009 amendment). It is then not a childless row, and it parks nothing under it.
- **No done line means "not yet observed."** An observation that the effect did *not* happen is `- <task-id> — effect not achieved DATE — <what was observed>` (`sp ledger not-achieved`). That leaves the Task `implemented`, and it is a `bottom-up` trigger.
- **A partially-observed effect writes no state line; its standing record is an `## Amendment` section** (adr-0013 adds that the pass may write a `checked` line, which is not state). `done` is all-or-nothing: a signal observed in one shape but not its own, or with a verification leg left undriven, stays without a done line. A leg the operator *declines* to run was not tested, so it takes no `effect not achieved` either. The record is an appended `## Amendment, YYYY-MM-DD:` section on the artifact whose effect it is (usually the Task): it names the probe that holds the measurement, says which legs are observed and which rest on static evidence or a declined leg, and says the rest still holds.
- **A look that saw nothing yet** (adr-0013 §4). An evidence pass (`observe`) that finds neither the effect nor its failure writes `- <task-id> — checked DATE — looked at <where>; <what is still missing>` (`sp ledger checked`). The verb takes only a Task awaiting an observed effect; a look at a Task whose latest effect line is `effect not achieved` goes in the working probe's dated findings. Like a request, a look is **not state**, read from the verb after the id: the Task stays `implemented` and awaiting, and a later `done` or `effect not achieved` line wins. `sp frontier --awaiting` routes the class to `observe` and orders it never-checked first, then the oldest look; `sp export` carries the date as `last_checked`.
- **Who writes the effect line** (adr-0013 §1). An agent may write `done` or `effect not achieved` from evidence of real use it read — rows, log lines or views the system produced in normal operation after the build — naming the store and the time window. Evidence excludes an instance the agent staged itself, a replay of Verification, and a restated `implemented` line. The operator's word is evidence too; the line then says it is the operator's.
- **An effect line names an observation from use.** A Verification result ("tests pass", "N/N checks") belongs on the implemented line; with no observation from use, leave the effect line unwritten.
- **A Task that serves a Story** (its `relates` chain reaches `docs/product/stories/`) is judged against the Story's **Outcome** as well as its own Goal. Its effect line says what was observed of that Outcome: `effect: <observed> — story-NNN Outcome: met | not met`. The format is unchanged otherwise, and `effect not achieved` stays a `bottom-up` trigger whose climb crosses the seam to the Story.
- **Parked work** (adr-0009). A Direction, Epic or Task set aside on purpose gets `- <id> — deferred DATE — <why; what would reopen it>`; one that will not be built gets `- <id> — abandoned DATE — <why>`. Each goes in its own kind's ledger (`docs/directions/`, `docs/epics/`, `docs/tasks/LEDGER.md`), through `sp ledger deferred|abandoned <id> "…"`. `sp frontier` leaves the artifact and the structure under it off its rows and counts them on a `parked` line. `- <id> — reopened DATE — <why>` (`sp ledger reopened`) brings it back. A replaced artifact is superseded.
- **Requested work** (task-035). The operator marks an open Direction, Epic, Task, Plan or open probe for work with `- <id> — requested DATE — <note>` in its kind's ledger (`sp ledger requested`); a later `- <id> — withdrawn DATE — <why>` (`sp ledger withdrawn`) cancels it. A request is **not state**: it changes no done, implemented or parked status, and it is read from the verb after the id. `sp frontier` marks requested rows and lists them first within their class (direction-006 amendment 2026-11-01), and `sp export` carries the line as `request`.
- **Blocked work** (overseer:adr-0003). Work that stopped on a question only the operator can answer gets `- <id> — blocked DATE — <question — working probe>` in its kind's ledger (`sp ledger blocked`). A later `- <id> — unblocked DATE — <what was decided>` (`sp ledger unblocked`), written by the operator's own session on the item, clears it. A block is **not state**, read from the verb after the id. `sp frontier` moves a blocked artifact into the `blocked` rows, listed first with its question; `sp export` carries the line as `blocked`. Unattended work skips blocked rows and leaves `unblocked` to the operator. The verb refuses an item already blocked: append a second question to the working probe as a dated note on the existing question, so one unblock answers both.
- **Backfilling a pre-ledger `status:`** (adr-0009). When a repo drops its written status keys, each one that recorded what a line can hold becomes that line, dated the day of the backfill, saying it was backfilled from which status, and naming the evidence. A pre-ledger `done` or `implemented` on a Plan-less Task becomes an implemented line (pre-ledger "done" meant built). `deferred` becomes a deferred line. A status the ledger or the edges already imply (a ledgered Plan, `superseded-by`) needs no line.
- Ledgers are append-only. A correction is a new line; the later line wins. Lines name artifacts by id; older lines with paths stay valid.
- **An evidence string cites what you measured or can point to.** Quote a count you ran this session, or name the artifact that records it (the probe line, the commit). Re-run a count remembered from a prior session or a compacted summary before citing it.

## Compliance & audit

The audit method — collecting the boundaries, judging the code against each, the cause tags, the report — lives in `audit-doc`, which also carries the system-specific checks (waterline crossed without acceptance, stale glossary, open-probe drift, product line crossed). Invoke it directly; it is read-only.
