---
name: facilitated-waterfall-conventions
description: Shared conventions for the facilitated-waterfall system — the drilling technique, the append-only rule, the waterline that divides commitment from mechanism, artifact formats, frontmatter and numbering rules, and the read-only audit/compliance checks. Loaded by top-down and bottom-up; also invoke directly to audit an implementation against the boundaries its governing documents set.
---

Shared reference for the facilitated-waterfall system. `top-down` and `bottom-up` load this file for their rules; you can also invoke it directly to **audit** an implementation against its governing documents (see *Compliance & audit* below).

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

If the project also runs `product-waterfall` (`docs/PRODUCT.md`, `docs/product/`), a second waterline stacks **above** this one, and the product **Story** is the seam: mechanism to the PM, commitment to engineering. See `product-waterfall` `conventions` for the full picture.

```
docs/PRODUCT.md (D-/X-ids) ═══ PRODUCT WATERLINE ═══ product Direction → Epic? → Story
   ┄┄ seam: Story ┄┄  FW Direction · ADR ═══ ENGINEERING WATERLINE ═══ architecture → code
```

- **Entry from above.** `top-down` accepts a Story (or product Epic) as input; the FW Direction or Tasks it writes carry the Story's id in `relates`.
- **Product commitments bind engineering.** A Story's Outcome, Acceptance criteria, and Out of scope, its parents' Out of scope, and every `docs/PRODUCT.md` resolved decision (D-NNN) and product-level exclusion (X-NNN) are above-the-line constraints for any FW artifact beneath them.
- **An ADR never supersedes a product commitment.** When one must move, hand off: a Story → `direct` Refine; a D-/X-entry → `reflect`. Both always involve the PM.
- **Two glossaries.** `docs/PRODUCT.md` holds product terms; `docs/CONTEXT.md` holds engineering terms. A term lives in exactly one — check the other before appending; a CONTEXT.md entry that realises a product term names it rather than redefining it.

Without a product layer, none of this applies — FW works standalone.

## Drilling technique

Every authoring stage shares this. Ask one question at a time. Give your recommended answer before waiting for a response.

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen, don't batch.
- **Cross-reference with code** — when the user states how something works, check whether the code agrees. Surface contradictions; the disagreement is itself a finding.
- **Challenge against the glossary** — when a term conflicts with `docs/CONTEXT.md`, call it out: "Your glossary defines X as Y, but you seem to mean Z — which is it?"

If a question can be answered by exploring the codebase, explore instead of asking.

## Depth & autonomy

- **Autonomy scales to tier.** A gap at the level of a Direction, or of the product, is about intent, so always interview the human. A gap at the level of a Task or ADR, where the answer can be derived from code and existing docs, may be driven autonomously. Escalate only on genuine ambiguity.
- **Plan depth follows author-blind risk, not importance.** Work gets a Plan, a `design` interview or a `zoom-in` when its author is likely blind to how it can go wrong: it is unfamiliar ground, has hidden coupling, or would be expensive to discover late. It does not get one just because it matters. Important work that is well understood goes straight through; small but treacherous work gets the depth.

## Append-only rule

Artifacts are not edited in place once they record a decision. A changed decision is captured by appending a **new** ADR whose `supersedes` field names the old one — the history of *why* stays intact. The old one gets one key and nothing else: `superseded-by`, naming the new one, so a reader of the old file sees it first (adr-0005). `sp supersede <new> --of <old>` writes both edges in one step. The sole exception is the **Probe** (`docs/probes/`), which is working memory: mutable while `open`, frozen when `reconciled`. Everything a probe *produces* (ADRs, Tasks, CONTEXT entries) is append-only.

## Artifact formats

Every file carries frontmatter with at least `id`, `title`, `created`, and `relates: [...]`. `relates` links point **upward** (Epic→Direction, Task→Epic/Direction, Plan→Task, ADR→artifact) and are fixed at creation. With a product layer, an FW Direction or Task may also point up across the seam to a Story (`docs/product/stories/NNN-slug.md`).

**The `id` is kind-prefixed** (adr-0006): `direction-NNN`, `epic-NNN`, `task-NNN`, `plan-NNN`, `adr-NNNN`, `probe-YYYY-MM-DD-slug`; with a product layer, `product-direction-NNN`, `product-epic-NNN`, `story-NNN`. `NNN` is the file's number. Links (`relates`, `supersedes`, `superseded-by`) and prose name artifacts by this id: "see task-084", never "Task 084", "084" or a path. File names keep their `NNN-slug.md` form. Older path ids and bare numbers still resolve when read, until `sp migrate` converts them. A superseded artifact carries `superseded-by: [<id>]`, a list, written only by the supersede step.

```
docs/directions/NNN-slug.md   Problem · Appetite · Out of scope · Success signal · Constraints · Risk?
docs/epics/NNN-slug.md        Goal · Scope · Out of scope · Tasks · Sequencing · Done when   (optional tier)
docs/tasks/NNN-slug.md        Goal · Notes
docs/plans/NNN-slug.md        Context · Steps · Verification · Risk
docs/adr/NNNN-slug.md         Context · Decision · Consequences · Alternatives   (optional supersedes)
docs/probes/<id>-slug.md      Trigger · Governing docs · Findings · Open questions · Deliberation · Risk · Reconciliation
docs/CONTEXT.md               Glossary of resolved domain terms — no implementation detail
```

- **Epic (optional).** The **Tasks** section is a manifest table of children with a `Depends on` column; **Sequencing** is the derived order (or "parallel"). Dependency edges live **only here** — do not duplicate `Depends on / Blocks / Order:` onto individual Tasks.
- **Risk** (one line each: blast radius · rollback · cost-of-wrong) is required on Plans, optional on Directions.
- **`intent:` (optional).** A one-sentence frontmatter line saying what the artifact is *for*. The authoring stages write it once the interview has settled the Goal or Problem. Never invent one to fill the key.
- **Intent trace.** Walk `relates` upward from any artifact, following at each level the **first parent that sits higher** (Plan → Task → Epic → Direction → Story → product Epic → product Direction); ADRs, probes and same-tier entries are passed over. Read each level's `intent:`. The result is one sentence per level, leaf to root. A level without `intent:` is reported as a gap (`<id>: no intent line`). It is never filled in by inference. Older artifacts predate the key, so a gap is information, not a defect. A broken link is reported, never followed. `sp trace <id>` walks it.

## The `sp` script

`sp` is at `~/.agent-skills/facilitated-waterfall/scripts/sp`. It is not on `PATH`: test that file, not `which sp`. Both waterfalls use it to read and write artifacts. `nav` is an older name for its read verbs and still works. Always pass an id or a target path, so it resolves the right workspace; give `-C <repo>` when the id alone doesn't say which.

| To | Run | Without `sp` (cold) |
|----|-----|---------------------|
| Make an artifact | `sp new <kind> "<title>" --relates <id>,… --intent "…"` | Take the next number from the highest file in the kind's directory, and write the frontmatter and sections of *Artifact formats* by hand |
| Supersede | `sp supersede <new> --of <old>` | Add `supersedes: [<old>]` to the new one and `superseded-by: [<new>]` to the old one, nothing else |
| Add a link | `sp relate <id> --to <parent id>` | Add the parent's id to `relates` |
| Record a Plan's mechanics verified | `sp ledger implemented <plan-id> "<N>/<N> checks passed"` | Append the line of *Status & ledger* |
| Record an effect seen, or not | `sp ledger done <task-id> "<what was seen, where>"` · `sp ledger not-achieved <task-id> "<what was seen>"` | Same |
| Close a probe | `sp ledger reconcile <probe-id> "<outcome>"` (it also sets `status: reconciled`) | Append the probe ledger line and set the status |
| Check what you wrote | `sp check <id>` | — (`sp check` reports any drift later) |
| Orient on an artifact | `sp tree <id>` (descendants, their state, next free numbers), `sp trace <id>` | Walk `relates` by hand |
| Read part of a doc | `sp outline <id>`, then `sp show <id> <heading or item id>…` | Read the file |

- **After every write, run `sp check <id>`** on what was written, and fix any `break` line before going on. Each line says what to do.
- **Every `sp` answer starts with its summary.** Read it first; a `+N more` line means the answer was cut, and says how to narrow it.
- **Unsure how a verb works?** `sp <command> help` prints its page: usage, what it writes, examples, the next step. `sp help` lists every command.
- **Skills work without `sp`.** The cold column is the rule then; `sp check` reports any drift when the script is back. A skill never refuses to run for lack of it.
- **`sp` can log its own calls.** With `SP_LOG` set to an absolute path outside any repo (`export SP_LOG=/path/to/sp.log` in your shell profile), every call appends one record: argv, cwd, workspace, exit code, stderr. `sp log` lists the failed and flagged ones, each with a rerun line; `debugging:improve-sp` turns them into fixes. Unset, `sp` writes no log.

## Handbook

The handbook is a workspace's short, graded lessons for working in it. It lives at `docs/handbook/` and is the one store that the knowledge skills (`note`, `recall`) write and read. Other skills cite this section rather than restating it.

| File | Holds |
|------|-------|
| `index.md` | Read-first: one line per file with its `last verified` date, and one `last pruned: DATE · N entries` line. |
| `map.md` | Purpose and entry points only, one line per area. Structure is derived by `sp module <path>`, never written down. |
| `commands.md` | How to build, run, test and deploy; setup; required env. |
| `gotchas.md` | Lessons in the shape Moment / Reflex / Instead / Because. |
| `conventions.md` | "How we do X here", each with its reason. |

- **Five files, fixed.** A fact is routed to one of them or dropped. Terms go to `docs/CONTEXT.md` (and product terms to `docs/PRODUCT.md`), never to the handbook.
- **Entries.** Each is atomic, with `Because:` (or `not recorded`), `Stage:` (`provisional · established · canonical · superseded`) and an optional `· portable`. `note` holds the full entry rules.
- **Anchors name symbols.** A new entry points at code as `` `Symbol.member` (path) ``, with no line number, so it survives edits. `sp def` resolves it, with grep as the fallback. Older `path:line` anchors stay valid.
- **Warrants.** A probe can be an entry's warrant. The origin probe goes in the source (`` Source: `Sym.member` (path) · probe-<id> ``), and a promotion records the probe that justified it (`Stage: established ← probe-<id>`).
- **Research is the contrast.** Long-form material lives in `docs/research/` and is lookup-only: it is never inherited and never pruned. An existing `docs/knowledge/` is treated the same way. It is never written to, moved or renamed.
- **Nothing leaves the handbook except into a probe.** A removed entry (wrong, stale, superseded, merged away or idle) is moved word for word, with its reason, into the probe that removed it. It becomes sealed history, which is looked up and never deleted. `docs/` may be gitignored, so a plain deletion could not be recovered.
- **`sp`** (*The `sp` script*) is how a session reads the handbook's links. Always pass the target path, so it resolves the right workspace.

### Inherit

A session reads what its workspace knows at fixed **inherit points**: moments the skill already passes through. Each skill names its points and the `sp` query for each. This is how to take one.

1. **Ask `sp` about the target**, never cwd:
   - a code path: `sp file <path>`, `sp module <dir>` or `sp docs <symbol|path>`;
   - an artifact (a doc-shaped trigger, such as "direction-021"): `sp tree <id>` for where it stands and what is next, and `sp trace <id>` for its intent trace;
   - a product decision or exclusion: `sp docs D-NNN`. It gives the `docs/PRODUCT.md` row, what supersedes it, and the docs that cite it as `PRODUCT.md#D-NNN`.

   Pass `--role top-down` from `top-down` and `direct`. With no target yet, make no call, and say so.
2. **Read by tier.** Read `always` (`docs/handbook/index.md`) first. Then read `on-match` docs in rank order, at the lines `sp` lists, until the `budget` line's share is used. Of a governing doc, read the constraint sections first, with `sp show`: an ADR's Decision (`sp show adr-0005 Decision`), a Direction's Constraints and Out of scope, a Task's Goal. `sp outline <id>` lists a doc's sections and item ids with their sizes. `lookup` docs are sealed. Open one only for a stated reason, such as a `supersedes … (lookup)` pointer to a decision the successor may not restate.
3. **Over share, trim and say so.** On `over share: trim on-match`, stop at the share and name what was left unread. The budget never blocks the work.
4. **Take the intent trace** from `sp trace <id>` on the nearest governing artifact.
5. **State read depth at entry**, in the same shape as a resume block. Put the `sp` budget line (or `sp absent` / `no target path`) first, then one line per doc: `FULL`, `PARTIAL (<sections>)` or `NOT_READ (<why>)`, then each sealed doc opened and why. A probe carries this at the head of Governing docs, and other skills put it at the top of their output.

**Without `sp`**, take the same points by the text rules: walk `relates` upward, grep `docs/` for the path and its symbols, read the constraint sections first, and leave sealed artifacts (reconciled or abandoned probes, ledgered Plans, superseded ADRs) unread unless needed. The read-depth statement still applies.

### Deposit at a close

A probe's close turns what it learned into handbook entries, and keeps the handbook small. `bottom-up` Phase 5 runs this before `reconciled`. The model decides every step; there is no confirmation step with the human, because entries start `provisional` and the cut test prunes them.

1. **Deposit.** For each Finding, ask: *would the next session in this area act differently knowing it?* If yes, and it was not already carried into an ADR, a Task or `docs/CONTEXT.md`, write it as an entry in the file it routes to. Use `note`'s format, `Stage: provisional`, with `Because:` taken from the Finding (or `not recorded`), and a symbol-anchored source with this probe as the warrant: `` Source: `Sym.member` (path) · probe-<id> ``. If an entry on the same subject exists, update it instead.
2. **Promote or demote.** An entry the probe names as relied on, without surprise, moves up one stage, `Stage: established ← probe-<id>`. "Names" means in a read-depth block, a Finding or a Deliberation line. An entry the probe found wrong is fixed in place, or removed into the probe, and the change is said loudly. Never promote on a hunch: no citation, no warrant.
3. **Cut test, when triggered.** The **area** is the paths this probe changed or anchored. Its entries are the ones `sp file` / `sp module` links into those paths. Without `sp`, grep the handbook for those paths and symbols. Run the test when either trigger holds:
   - **size:** `sp`'s `handbook` footer line for the area reads `over: cut test due at close`. The area's entries may use a quarter of the role's inheritance share; with no budget set, this trigger is off;
   - **fence:** this probe's work makes the last Task of an Epic, or the last Epic of a Direction, `implemented` (read from the ledgers).

   Truth comes first: re-verify each entry in the area against the code, and fix or remove the wrong ones. Then ask of each true entry: *has this changed a decision since the area was last pruned?* Look for a citation in a probe, or a mistake it would have prevented.
   - **Earns its place:** keep it.
   - **True but idle, above `provisional`:** demote it one stage.
   - **True but idle, `provisional`:** retire it into this probe.
   - **The code already says it:** retire it.
   - **`canonical`:** cut only with a stated reason.

   Only the area's entries are in scope. A whole-handbook prune at every close is not.
4. **Gate.** Reconciliation carries one **Deposit** line naming each entry added, promoted, demoted or retired, by file and subject, or the words `nothing durable`. Retired entries follow, verbatim, each with its reason. Update `last verified` in `index.md` for each file touched. If the cut test ran, also update `last pruned: DATE · N entries`.

## Numbering

- **Directions, Epics, Tasks, ADRs, Plans** — numbered sequentially from the highest existing file in their directory. `sp new <kind>` takes the next number under a lock, so parallel sessions never collide; `sp tree <id>` shows the next free number per kind. Cold, allocate a whole breakdown batch in one pass.
- **Probes** — created ad hoc and in parallel, so they use **collision-free** ids: `probe-YYYY-MM-DD-slug` (`sp new probe "<title>"`). A sequential `NNN` is assigned only at reconcile, single-threaded, when a durable artifact is minted.

## Status & ledger

- **Probes** carry a written `status:`: `open` · `reconciled` · `abandoned`. They are the one mutable artifact.
- **Directions, Epics, Tasks and Plans never get a `status:` written**. Completion is recorded in ledgers, never by editing the artifact. Their state is derived from the `relates` graph and the ledgers:
  - `todo` / `in-progress`: no ledger line yet;
  - **`implemented`**: the mechanics are verified. Every Verification item in the Plan passed, recorded as a `docs/plans/LEDGER.md` line by `implement` (`sp ledger implemented <plan-id> "N/N passed"`): `- <plan-id> — implemented DATE — verification: N/N passed`. A Task is implemented when all its Plans are, or, if it has no Plan, on codebase evidence.
  - **`done`**: the **intended effect was observed** at a later real opportunity, in use and not in a replay of Verification. It is recorded as one line in `docs/tasks/LEDGER.md` (`sp ledger done <task-id> "<observed>"`): `- <task-id> — done DATE — effect: <what was observed, and where>`.
- **No done line means "not yet observed".** Write no placeholder. An observation that the effect did *not* happen is `- <task-id> — effect not achieved DATE — <what was observed>` (`sp ledger not-achieved`). That leaves the Task `implemented`, and it is a `bottom-up` trigger.
- An effect line must name an observation from use. **Restating the Verification result ("tests pass", "N/N checks") is not an effect.** It is the failure this record exists to catch, so leave the line unwritten instead.
- **A Task that serves a Story** (its `relates` chain reaches `docs/product/stories/`) is judged against the Story's **Outcome**, not only its own Goal. Its effect line says what was observed of that Outcome: `effect: <observed> — story-NNN Outcome: met | not met`. The format is unchanged otherwise, and `effect not achieved` stays a `bottom-up` trigger; its climb crosses the seam to the Story.
- Ledgers are append-only. A correction is a new line; the later line wins. Lines name artifacts by id; older lines with paths stay valid.

## Compliance & audit

Read-only. Invoke directly to check whether what was built stayed inside what was decided. Writes nothing — reports drift.

**Collect the boundaries.** From the target artifact, walk `relates` upward to its governing docs (`sp trace <id>`) and sideways to every ADR. `sp check <id>` on each says whether its frontmatter can be trusted for the walk. Extract only constraints: ADR Decisions (non-negotiable), Plan Steps + Verification, Task/Epic Scope + **Out of scope**, Direction Constraints + Appetite + Out of scope.

**Check each against reality.** For every boundary, judge the code: **Conforms** / **Drifts** (diverges from a Plan step without a documented reason) / **Violates** (does what an ADR forbids or an Out-of-scope line excludes) / **Unverified** (a Verification check that doesn't pass) / **Not implemented**. State evidence for every verdict — file+line, command output, or commit. Run cheap Verification commands where a Plan lists them.

**Waterline & probe checks (system-specific):**
- **Waterline crossed without acceptance** — a probe (or commit) that overturns an ADR/Direction commitment with no recorded accepted trade-off. This is a violation.
- **Stale glossary** — a `docs/CONTEXT.md` term whose definition no longer matches the code it pins to (e.g. a named field/module that moved or changed shape).
- **Open-probe drift** — a probe left `open` well past activity, or closed without its Reconciliation gate satisfied (see `bottom-up`).
- **Product line crossed** (product layer only) — an ADR, Direction, or code that changes a governing Story's Outcome/Acceptance or contradicts a `docs/PRODUCT.md` D-/X-entry, with no matching Story Revision or `reflect` probe. This is a violation.

**Tag each non-conforming verdict by cause.** You assign the tag; never ask the human to.
- `CONTEXT-GAP`: the governing docs did not say it, so the fix belongs in an ADR, a Task or a handbook entry.
- `JUDGMENT-GAP`: the docs said it and the work missed it, so the fix belongs in the code.
- `UNCLEAR`: you can't tell which of the two it is.

**Report**, violations first, grouped by severity, ending with a count line:

```
adr-0004                       VIOLATED    JUDGMENT-GAP  src/cache.ts:88 blocking read in request path
probe-2026-08-17-x             VIOLATED    JUDGMENT-GAP  supersedes adr-0008 with no accepted trade-off
docs/CONTEXT.md → "usage"      STALE       CONTEXT-GAP   pins app/lib/llm/usage.ts; file is now canonical-usage.ts
plan-005                       UNVERIFIED  UNCLEAR       `npm run e2e:auth` fails (2 specs)
direction-001                  CONFORMS                  no scope-creep against Out of scope

Causes: 1 CONTEXT-GAP · 2 JUDGMENT-GAP · 1 UNCLEAR
```

A run of CONTEXT-GAPs means the anchors need work; a run of JUDGMENT-GAPs means the work does.

Recommend, do not apply. **Code wrong** → fix code to honor the boundary. **Boundary wrong/outdated** → append a superseding ADR; never edit the original. When code and docs disagree, that disagreement *is* the finding — don't silently pick a side.
