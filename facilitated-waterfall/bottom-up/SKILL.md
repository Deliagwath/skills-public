---
name: facilitated-waterfall-bottom-up
description: Works a concrete task or fix from the code up to the waterline — locates the code, climbs the abstraction ladder to check it sits in the right place against the governing docs, resolves at the line, implements below it, and reconciles what it learned back into the durable record. Hands product-level conflicts to product-waterfall direct or reflect. Records working memory in docs/probes/. Use when handed a bug, change request, or task rooted in existing code.
---

Take a concrete trigger — a bug, a change request, a task — and carry it up to the waterline from the code side. Find the quick fix, then **look up**: is it in the right spot, the right class, the right module, the right architecture? Settle where it belongs, honor the commitments above the line, implement below it, and feed what you learned back up. Read `conventions` for the drilling technique, the waterline, append-only, formats, and numbering — not repeated here.

The working document is a **Probe** (`docs/probes/<id>.md`) — the one mutable artifact, your working memory across sessions and context windows. Create it at Anchor; it carries the investigation so a fresh agent resumes from its header, not from zero.

## Ascent guard

You may change anything **below** the waterline freely — placement, class, module, pattern are reversible mechanism. You may **not** overturn a commitment **above** the line (an ADR decision, a Direction constraint or scope) without surfacing the trade-off and recording **accepted** supersession. If the trade-off isn't accepted, the fix is wrong — go back down and find a mechanism that honors the decision.

---

## Resuming an open probe

If the trigger names a probe that is already `open`, don't create a new one. Resume it. **Before any other action**, append a dated block under its Findings recording what this session actually re-read:

```
**YYYY-MM-DD — Resumed.** Read depth:
- adr-0007 — FULL
- task-012 — PARTIAL (Goal only)
- direction-003 — NOT_READ (known from this probe's summary)
```

List every Governing doc. Anything you know only from the probe's own text is **inherited, not read**: mark it `NOT_READ`. The probe is testimony, not ground truth. Continue from the map, not from the summary's next step. This is a statement, not a gate: go on and re-read what the next step depends on. To re-read, take an inherit point (`conventions` → Handbook → Inherit) with `sp file` on the path the next step touches (or `sp tree <id>` on the artifact it touches), and put its budget line at the head of the block. The session that creates the probe states its read depth in Phase 2 instead.

## Phase 1 — Anchor

State the trigger and the candidate quick-fix in one or two lines. A trigger can be a record from `sp log`, handed over by `debugging:improve-sp`: the call, its rerun line and the verdict that `sp` is at fault. Reproduce it from the rerun line before anything else; the fix goes in `sp` with a regression case in `test.sh` on the suite's fixture, never with the record's private paths. A trigger can also be an `effect not achieved` line in `docs/tasks/LEDGER.md`. In that case the Task's mechanics were verified but its intended effect did not show up in use, so climb from what was built to why it didn't work. If the Task serves a Story, the climb must reach the Story's Outcome: a wrong mechanism is fixed below the line, and a Story that can't hold goes to `direct` Refine (or a D-/X-entry to `reflect`), as in Phase 3. Create the Probe with `sp new probe "<title>" --relates <governing id>,…`: it writes the collision-free id (`probe-YYYY-MM-DD-slug`), `status: open` and the section skeleton, and prints the path (`conventions` → *The `sp` script*; without `sp`, write them by hand). Keep the title a few words — `sp` slugifies it into the id and the file name, and that id propagates into every link, command, and ledger line. Then fill the **Trigger** section. No authoring above the line yet.

## Phase 2 — Situate

Locate the code (`grep`/`find`/`git log`). When the trigger concerns **deployed or live state** (installed software, running services, pinned checkouts, a whole machine) rather than a code path, the code is the live system: take a **read-only inventory** — package-manager lists, install roots, `git status` of each pinned checkout, the live outdated list, service and process state, and the install or setup scripts that made each of them — and fold it into **Findings** dated, with the paths and commands. The docs tree records intent; the live system records what is actually declared and running, and the gap between them is often the finding itself. **Inherit point:** `sp file <trigger path>` (`conventions` → Handbook → Inherit) gives the docs linked to it, ranked, with the handbook and the budget share. When the trigger names an artifact instead of a code path ("direction-021"), run `sp tree <id>` and `sp trace <id>` first: where it stands, what is under it, and what is next. `sp` is `~/.agent-skills/facilitated-waterfall/scripts/sp`, not on `PATH`: test that file, not `which sp`. Without it, the text rules there apply. Then walk `relates` **upward** from whatever artifact governs this area to collect every constraint — ADRs, the Task/Epic scope, the Direction. `sp` finds docs only on evidence, so the walk is what makes the set complete. Read what it finds by tier, constraint sections first (`sp show <id> Decision`, `sp show <id> Constraints "Out of scope"`). If the chain crosses into the product layer, keep walking: the Story, its product Epic/Direction, and the `docs/PRODUCT.md` D-/X-entries they cite. Record them in **Governing docs**. If none exist, write "code ahead of docs" — that is itself a finding to reconcile later.

Head the Governing docs section with the **intent trace**: one sentence per level, leaf to root, taken from each artifact's `intent:` along the first `relates` entry in list order that sits higher (`conventions` → Artifact formats). Where a level has none, write `<id>: no intent line`. Never compose one from the body. `sp trace <id>` derives it, showing a missing line as `(title)`. The trace is what the climb tests the fix against, so a gap there is worth knowing before Phase 3.

Below the trace, state the **read depth at entry** (`conventions` → Handbook → Inherit): the budget line, each doc as `FULL` / `PARTIAL` / `NOT_READ`, what was trimmed over the share, and any sealed doc opened and why.

## Phase 3 — Climb & deliberate

This is the heart, and it is the step most easily skipped — the pull toward a quick fix is to find a clean home for the code and start writing. Resist it. From the fix's natural home, climb the ladder one rung at a time, asking each rung's question. **Do not stop at the first rung where the change fits** — a clean below-the-line home is necessary but not sufficient. Always carry the climb all the way to the waterline and read the governing ADR(s) and Direction. The point of reaching the top is not to ask permission; it is to *test the recorded decision against what the code just told you*.

```
placement (right spot?) → class (right abstraction?) → module (right owner?)
→ architecture/pattern (consistent?) → ══ WATERLINE ══ → ADR / Direction (still true?)
→ ┄┄ seam ┄┄ Story (still achievable?) → ══ PRODUCT WATERLINE ══ → docs/PRODUCT.md (still true?)
```

The last two rungs exist only when a product layer governs this area (see `conventions` → Product layer). When it does, the climb reads them too.

**Explore the code before you conclude anything.** Read the code the fix touches *and* the code the governing ADR describes — reason from the source, not from the doc's summary of it. When the trigger **proposes a mechanism that already exists** in one or more forms — different dialects, layers, or repos — locate every existing instance, record them in **Findings**, and frame the proposal as unification or generalization rather than net-new: the governing decisions that constrain the existing instances constrain the proposal too, so they enter the climb even though the proposed code does not exist yet. **Inherit point:** on entering a module you haven't situated yet, `sp module <dir>` first. Record what you find in **Findings** (dated, append-only — what investigation revealed about reality). Record the climb in **Deliberation**: which rung each candidate settled or failed at, and whether the line was hit. Keep **Open questions** (each with "what would resolve it") and **Risk** (blast radius · rollback · cost-of-wrong) current as you go.

**Test each governing decision — don't just obey it.** For every ADR that governs this area, hold its Decision against your Findings and ask: are its Context and assumptions still true in the code as it stands today? Does the clean fix you found quietly contradict, erode, or route *around* the decision? A decision you can only satisfy by working around it is a signal the ADR may be stale — not that your fix is clever. Write an explicit verdict for each governing ADR in Deliberation — `still holds — <why>` or `amendment candidate — <what reality changed>` — **before** you resolve. Skipping straight from a below-the-line home to implementation without recording these verdicts is the drift this phase exists to prevent.

**Resolve at the line:**
- **Fits below the line *and* every governing decision still holds** (verdicts recorded) → mechanism change. Proceed to implement. No ceremony.
- **Requires an above-the-line change** → classify it:
  - *Correction* (the recorded decision is simply wrong on contact with code) → surface the trade-off, get explicit acceptance, then append a **superseding ADR** through the `design` discipline (load `top-down` Phase 3), which writes both edges with `sp supersede <new adr> --of <old adr>`. Record the acceptance in Deliberation.
  - *Net-new intent* (a missing decision, Task, or Direction) → **load `top-down`** at the matching tier to author it properly, then resume:
    - Missing decision → `top-down` Phase 3 (ADR).
    - Missing work unit → `top-down` Phase 2 (Breakdown → Task).
    - Missing/mis-stated problem → `top-down` Phase 1 (Shape → Direction).
  For the **Direction** case, "then resume" means **reconcile the probe** (Phase 5), not implement: the probe is working memory for the *climb*, and the placed, bounded unit is now the Direction. Its build (Breakdown → Tasks → Plan) is a separate top-down descent that opens its own probe(s). Reconcile once the Direction is authored, any amendment is recorded, and every Open question is resolved or deferred — even though no Task or Plan sits under the Direction yet.
- **Requires a product-level change** (product layer only) → never resolve it with an ADR. Hand it to the PM:
  - *The Story can't hold* (Outcome, Acceptance, or Out of scope is wrong on contact with code, but no `docs/PRODUCT.md` entry is involved) → **load `product-waterfall` `direct`** Refine on the Story, passing this probe's Findings. Resume with its Revision, or with "Story holds", in which case find a mechanism that meets it.
  - *A product decision or exclusion is the obstacle* (a D-/X-entry) → **load `product-waterfall` `reflect`**, with this finding as the signal and this probe as `relates`. Resume on its verdict: `holds` means go back down and honour it; `superseded` means continue against the new decision.
  - Record the hand-off and its outcome in Deliberation.

**Autonomy scales to tier** (per `conventions` → Depth & autonomy): a **Direction**-level or product-level gap is intent — always interview the human. A **Task/ADR** gap whose answer is derivable from code + existing docs, you may drive autonomously, escalating only on genuine ambiguity.

## Phase 4 — Implement

Only below the line, only after Phase 3 resolves — meaning a per-ADR verdict is recorded and every `amendment candidate` has been carried through the Correction path, not deferred. Do not open a Plan while any governing ADR is still an unresolved amendment candidate. Derive the **Plan** from the Task + governing ADRs when the work needs step-decomposition, which is judged by author-blind risk, not importance (`conventions` → Depth & autonomy); write it with `sp new plan "<title>" --relates <task-id>,<adr-id>,…` (Context · Steps · Verification · Risk), then `sp check <plan-id>`. A Plan may span several sibling Tasks. **Inherit point:** before editing a file outside what Phases 2–3 situated, `sp file <path>`; its handbook gotchas are the reflexes for that move. Skeleton first, then body. **When the implementation is an operation on live or deployed state** — a service update, a config reload, a daemon restart — rather than a repo edit, two rules add: confirm the state transition actually happened (new PID / port / version, process alive and not crash-looping) *before* running any verification, because a silently failed apply step makes the verification measure the pre-change state — and the first read after a restart is cold, so re-run the smoke before calling it a failure. Record the rollback point (prior commit, prior config, prior version) in **Risk** at the moment of mutation, not when something later looks wrong. Append verification results to the Probe's Findings. Do not report done if any Verification item fails or any ADR decision is violated.

## Phase 5 — Reconcile (the return path)

Distill the probe into durable record, then freeze it. The Probe cannot move to `reconciled` until **all** gates pass:

- Every **Open question** is resolved or explicitly deferred.
- Every Deliberation **conflict** is either fixed-in-code or recorded as a superseding ADR with accepted trade-off — never silently dropped. A product-level conflict is closed only by a Story Revision or a resolved `reflect` probe.
- Every **docs/CONTEXT.md** term the work touched is verified against the current code and updated if stale.
- The artifacts produced/updated are listed in **Reconciliation** (new/superseded ADR, updated Task, new Direction, CONTEXT entries), and their `relates` link back to this probe.
- **The Task ledger states match the code, not the frontier's labels.** A `done` line requires the effect observed in use (adr-0003) — where the effect never showed up, write the honest `effect-not-achieved` line, never a stamped done. A Plan-less Task that was actually built is recorded `implemented` / `deferred` / `abandoned` (adr-0009), not routed to `/plan`. The frontier's `unplanned → /plan` / `awaiting` rows are a derived, stale-able signal: reconcile each against the code, not the label. Work that is genuinely open, or old / no-intent and possibly superseded, is left and surfaced for the human's supersede-or-plan call — never killed unilaterally. `sp` recipe: `references/reconcile-task-ledger.md`.
- **Deposit** is done (`conventions` → Handbook → Deposit at a close). The probe's lessons are deposited, entries it relied on are promoted, and the cut test has run if it was triggered. Reconciliation carries the Deposit line, which names what was added, promoted, demoted or retired, or says `nothing durable`. If `docs/handbook/` is missing and something is durable, create it as `note` Bootstrap does: five files, and an `index.md` with `last verified: never` and `last pruned: never · 0 entries`.

Close it with `sp ledger reconcile <probe-id> "<one-line outcome>"`: it appends `- <probe-id> — reconciled DATE — <outcome>` to `docs/probes/LEDGER.md` and sets `status: reconciled`. Without `sp`, do both by hand. Then run `sp check` on every artifact the probe produced, then the whole-graph check (`conventions` → Batch check), then the commit step (`conventions` → Commit): a reconciliation commits as one batch — the probe, the artifacts it produced, the amendments, the glossary entries, the ledger lines — after any prior uncommitted work in the repo has committed on its own. Before committing that prior work, verify it is actually prior work in *this* stream (`git diff -- <file>` against the last commit): a diff left by another workstream is a loose end to flag to its owner, not something to fold into your reconciliation commit. A probe abandoned (not worth pursuing) is set `status: abandoned` and kept as a "why we didn't" record.

## Rules

- Implementation lives below the waterline. Never overturn a commitment above it without recorded acceptance.
- Never jump from trigger to Plan. Phase 3 — explore the code, climb to the waterline, and record a verdict on every governing ADR — is mandatory, not optional, even when a clean below-the-line fix is obvious.
- A quick fix that only works by routing around an ADR is evidence the decision may be stale — investigate and record an amendment candidate, don't quietly implement past it.
- Don't hand-author above-the-line artifacts ad hoc — load `top-down` so they get the full drilling discipline.
- The probe is working memory: keep the header (Trigger · status · Governing docs · Open questions) accurate so any session resumes from it. If this session must end while the probe is still open — user away, command execution blocked, awaiting an observed effect — append the dated findings you already have and the pending open question to the probe *before* responding: the file, not the transcript, is what the resuming session inherits.
- After a context compaction, re-read the exact region of a document before appending to it — a paraphrased anchor from a summarized context will not match; take the matcher's "did you mean" hint and re-anchor from the current text.
- Reconcile before closing. An `open` probe with unresolved questions is drift `conventions` audit will flag.
