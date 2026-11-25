---
name: facilitated-waterfall-bottom-up
description: Works a concrete task or fix from the code up to the waterline — locates the code, climbs the abstraction ladder to check it sits in the right place against the governing docs, resolves at the line, implements below it, and reconciles what it learned back into the durable record. Hands product-level conflicts to product-waterfall direct or reflect. Records working memory in docs/probes/. Use when handed a bug, change request, a pointer to a named artifact, or a task rooted in existing code.
---

Take a concrete trigger — a bug, a change request, a task — and carry it up to the waterline from the code side. Find the quick fix, then **look up**: is it in the right spot, the right class, the right module, the right architecture? Settle where it belongs, honor the commitments above the line, implement below it, and feed what you learned back up. Read `conventions` for the drilling technique, the waterline, append-only, formats, and numbering.

The working document is a **Probe** (`docs/probes/<id>.md`) — the one mutable artifact, your working memory across sessions and context windows. Open it when there is something to carry (*When to open a probe*); once open, its header is where a fresh agent resumes.

## Ascent guard

Anything **below** the waterline is yours to change — placement, class, module, pattern are reversible mechanism. A commitment **above** the line (an ADR decision, a Direction constraint or scope) changes only through a surfaced trade-off and a recorded, **accepted** supersession. Without that acceptance, go back down and find a mechanism that honors the decision.

---

## When to open a probe

The climb (Phases 2–3) always runs. The probe file exists when something must outlive this session (adr-0011). Work **without a probe** while all of these hold: the trigger is a concrete fix, this session can finish it, and every governing decision re-read so far still holds.

Open one with `sp new probe` (Phase 1) as soon as any of these is true, and carry what the session already found into it, dated:

- a governing verdict comes out `amendment candidate`, or the fix needs an above-the-line or product-level change;
- an Open question, or the work itself, will outlive this session;
- the trigger is an artifact pointer, an `effect not achieved` line or a `sp log` record;
- the fix mutates live or deployed state, so the rollback point needs a home.

Where a phase below says to record something in the probe and none is open, hold it in the session. When it needs a second reader, open one.

**A probe-less close** skips Phase 5 and leaves three things:

- **The reply** states the read depth and the verdict on each governing doc, under the same rules Phases 2–3 set for the probe.
- **The commit message** says what changed and why, and names the governing ids.
- **A handbook entry**, when the next session in this area would act differently knowing the lesson (`conventions` → Handbook → Deposit, step 1 alone). Its Source names the symbol and path.

A Task the fix completes takes its ledger line. Write a Plan when author-blind risk calls for one.

## Resuming an open probe

When the trigger names a probe that is already `open`, resume it. **First**, append a dated block recording what this session re-read. It goes under Findings, or at the file's tail when the probe's earlier dated blocks live there — the log stays in one place:

```
**YYYY-MM-DD — Resumed.** Read depth:
- adr-0007 — FULL
- task-012 — PARTIAL (Goal only)
- direction-003 — NOT_READ (known from this probe's summary)
```

List every Governing doc. A doc you know only from the probe's own text is `NOT_READ`: the probe is testimony; the docs are the ground truth. Then re-read what the next step depends on: take an inherit point (`conventions` → Handbook → Inherit) with `sp file` on the path the next step touches (or `sp tree <id>` on the artifact it touches), and put its budget line at the head of the block. Continue from that map. The session that creates the probe states its read depth in Phase 2 instead.

When the next step is a **wall-clock wait** — a cross-repo prerequisite, an operator act, a scheduled run — the block records and ends. Its map goes all `NOT_READ`, justified per doc by the doc tree not having moved since the last full read, and states *no verdict owed*: a wait's premises are world measurements (re-measure them, below). Check the doc tree with `git log --since <that read> -- <docs dir>`, the `--since` before `--`, and confirm the paths exist first, since `git log` prints nothing for a missing path. A wait for an **effect in real use** takes an `observe` pass (*Routing a pointer trigger*).

**Re-measure the premise.** A probe's dated Findings carry *measurements of the world* — a cross-repo task's state, an installed tool's behavior, a live system, a test baseline — and those move while a probe waits. On resume, re-run the query behind every premise the next step depends on, and record the fresh numbers as dated findings. Every number in the re-measurement block comes from a query this session. When a fresh measurement refutes an earlier finding, append the refutation and leave the earlier finding as written. A downstream artifact that still encodes the old premise is *named* stale in the probe (which line, what the fresh measurement says); its correction belongs to the session that owns it.

When the probe's place is the middle of a plan build — a stopped run recorded its built steps and its next step — load `implement` and run the plan's remaining steps from the probe's map. The resume re-measurement and the climb run on entry; the plan, as the probe carries it, is the step list.

## Phase 1 — Anchor

State the trigger and the candidate quick-fix in one or two lines.

- **A pointer to a named artifact** — a repo, a Direction, an Epic, or a probe, by id or by name, with or without a repo prefix. Resolve it to open work with `sp tree <id>` and `sp frontier` in the named repo (conventions → The `sp` script), and route it per *Routing a pointer trigger*. Ask the user what they want done when nothing open matches.
- **A record from `sp log`**, handed over by `debugging:improve-sp`: the call, its rerun line and the verdict that `sp` is at fault. Reproduce it from the rerun line first. The fix goes in `sp`, with a regression case in `test.sh` on the suite's fixture.
- **An `effect not achieved` line** in `docs/tasks/LEDGER.md`: the Task's mechanics were verified, and its intended effect did not show up in use. Climb from what was built to why it didn't work. When the Task serves a Story, the climb reaches the Story's Outcome: a wrong mechanism is fixed below the line, and a Story that can't hold goes to `direct` Refine (or a D-/X-entry to `reflect`), as in Phase 3.

When a probe is due (*When to open a probe*), create it with `sp new probe "<title>" --relates <governing id>,…`. It writes the id (`probe-YYYY-MM-DD-slug`), `status: open` and the section skeleton, and prints the path (without `sp`, write them by hand). Keep the title a few words: it becomes the id used in every link, command and ledger line. Fill the **Trigger** section. Authoring above the line waits for Phase 3.

**Routing a pointer trigger.** List every open probe under the pointer and read each one's **Open questions** for what it still needs; `sp frontier` gives all open probes the same `bottom-up` label, and the Open questions tell them apart. Take the first case that applies:

1. **A probe whose only open leg is an effect wait** (built and verified, waiting on real use) → load `observe` and run one evidence pass on that leg (adr-0013 §5). When the pass records the effect or its failure, close the probe with Phase 5 in this session; otherwise continue down this list.
2. **An open probe with a workable leg** (an Open question to resolve, a plan build to continue, a fix to finish) → resume it per *Resuming an open probe*, in `sp frontier` order.
3. **Otherwise** → take the first non-probe frontier row under the pointer: an `effect not achieved` line is this skill's trigger; an unplanned Task goes to `plan`, then `implement`; an unimplemented Plan goes to `implement`; a Task awaiting an observed effect goes to `observe`; built work with no ledger line is reconciled (Phase 5's ledger gate).

Name the row you took and why in the reply.

## Phase 2 — Situate

Locate the code (`grep`/`find`/`git log`). **Inherit point:** `sp file <trigger path>` (`conventions` → Handbook → Inherit) gives the docs linked to it, ranked, with the handbook and the budget share. When the trigger names an artifact ("direction-021"), run `sp tree <id>` and `sp trace <id>` first: where it stands, what is under it, and what is next. `sp` lives at `~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file. Without it, the text rules in `conventions` apply.

**Live state.** When the trigger concerns deployed or live state (installed software, running services, pinned checkouts, a whole machine), the live system is the code. Take a **read-only inventory** — package-manager lists, install roots, `git status` of each pinned checkout, the live outdated list, service and process state, and the install or setup scripts that made each of them — and record it in **Findings**, dated, with the paths and commands. The gap between the docs (intent) and the live system (what runs) is often the finding.

- **Stored data of a live stream** (a queue, candidate or draft files, a JSON store): recompute the generator that wrote it, classify each stored row as still-produced, stale, or superseded, and record the delta. Record rows that carry no provenance stamp (timestamp, source, the rule that made it) as a finding of their own.
- **A referenced repo's working tree**: when it holds uncommitted work, attribute it — mtime against your session's window, and a diff read for what it adds — and record it as a dated finding. A referenced repo is read-only ground; its work in progress stays as you found it.

**Governing docs.** Walk `relates` **upward** from the artifact that governs this area and collect every constraint — ADRs, the Task/Epic scope, the Direction. `sp` finds docs on evidence; the walk completes the set. Read by tier, constraint sections first (`sp show <id> Decision`, `sp show <id> Constraints "Out of scope"`). When the chain crosses into the product layer, keep walking: the Story, its product Epic/Direction, and the `docs/PRODUCT.md` D-/X-entries they cite. Record them in **Governing docs**. When none exist, write "code ahead of docs" — a finding to reconcile later.

Head the Governing docs section with the **intent trace**: one sentence per level, leaf to root, taken from each artifact's `intent:` along the first `relates` entry in list order that sits higher (`conventions` → Artifact formats). Where a level has none, write `<id>: no intent line`. `sp trace <id>` derives it, showing a missing line as `(title)`. The climb tests the fix against this trace.

Below the trace, state the **read depth at entry** (`conventions` → Handbook → Inherit): the budget line, each doc as `FULL` / `PARTIAL` / `NOT_READ`, what was trimmed over the share, and any sealed doc opened and why.

## Phase 3 — Climb & deliberate

From the fix's natural home, climb the ladder one rung at a time, asking each rung's question, all the way to the waterline. A clean below-the-line home is necessary and not sufficient: the top rungs are where you *test the recorded decision against what the code just told you*.

```
placement (right spot?) → class (right abstraction?) → module (right owner?)
→ architecture/pattern (consistent?) → ══ WATERLINE ══ → ADR / Direction (still true?)
→ ┄┄ seam ┄┄ Story (still achievable?) → ══ PRODUCT WATERLINE ══ → docs/PRODUCT.md (still true?)
```

The last two rungs exist when a product layer governs this area (see `conventions` → Product layer).

**Explore the code first.** Read the code the fix touches *and* the code the governing ADR describes, and reason from the source. When the trigger **proposes a mechanism that already exists** in one or more forms — different dialects, layers, or repos — locate every instance, record them in **Findings**, and frame the proposal as unification or generalization. The decisions that constrain the existing instances enter the climb.

**Measure the data behind an aggregate.** When the fix groups, counts, or rolls up records already in a stream or envelope, query the store the records land in and measure join and attribution completeness: the fraction of source rows the aggregate can attach to, and whether each record carries the fields the grouping keys on. A large unattributed fraction rules out a consumer-side roll-up; a field the record lacks is derived where the join happens. Put the coverage number and its filter in Findings — counted, attached, dropped — before the placement rung settles.

**Inherit point:** on entering a module you haven't situated yet, `sp module <dir>` first. Record what you find in **Findings** (dated, append-only). Record the climb in **Deliberation**: which rung each candidate settled or failed at, and whether the line was hit. Keep **Open questions** (each with "what would resolve it") and **Risk** (blast radius · rollback · cost-of-wrong) current as you go.

**Test each governing decision.** For every ADR that governs this area, hold its Decision against your Findings: are its Context and assumptions true in the code today? Does the fix contradict, erode, or route *around* it? A decision the fix can only satisfy by working around it is a sign the ADR may be stale. Write a verdict for each governing ADR in Deliberation — `still holds — <why>` or `amendment candidate — <what reality changed>` — **before** you resolve. Verdicts go on docs you re-read this session, per the read-depth map (Phase 2 at entry, or the resume block); a `NOT_READ` doc takes no verdict, and its re-read is an open question.

**Price a mutation into a pinned area.** When the fix — or the operator act it depends on — lands in a path a recorded guard pins (a hash manifest over data, a recorded baseline, a sealed or pinned store), copy the repo to a scratch directory (excluding VCS metadata), apply one simulated edit of the intended kind, and run the repo's own gate against the copy. Record the pin values before and after in Risk, and the gate's verdict as a dated Finding. A pinned area with no rebaseline path makes the mutation an above-the-line decision for the operator to accept. When the mutation is an operator act, show this cost in the probe before asking for the act.

**Resolve at the line:**
- **Fits below the line *and* every governing decision still holds** (verdicts recorded) → mechanism change. Proceed to implement.
- **Requires an above-the-line change** → classify it:
  - *Correction* (the recorded decision is wrong on contact with code) → surface the trade-off, get explicit acceptance, then append a **superseding ADR** through the `design` discipline (load `top-down` Phase 3), which writes both edges with `sp supersede <new adr> --of <old adr>`. Record the acceptance in Deliberation.
  - *Net-new intent* (a missing decision, Task, or Direction) → **load `top-down`** at the matching tier, then resume:
    - Missing decision → `top-down` Phase 3 (ADR).
    - Missing work unit → `top-down` Phase 2 (Breakdown → Task).
    - Missing/mis-stated problem → `top-down` Phase 1 (Shape → Direction).
  For the **Direction** case, resume means **reconcile the probe** (Phase 5): the placed, bounded unit is now the Direction, and its build (Breakdown → Tasks → Plan) is a separate top-down descent with its own probe(s). Reconcile once the Direction is authored, any amendment is recorded, and every Open question is resolved or deferred.
- **Requires a product-level change** (product layer only) → hand it to the PM:
  - *The Story can't hold* (Outcome, Acceptance, or Out of scope is wrong on contact with code, with no `docs/PRODUCT.md` entry involved) → **load `product-waterfall` `direct`** Refine on the Story, passing this probe's Findings. Resume with its Revision, or with "Story holds" and a mechanism that meets it.
  - *A product decision or exclusion is the obstacle* (a D-/X-entry) → **load `product-waterfall` `reflect`**, with this finding as the signal and this probe as `relates`. Resume on its verdict: `holds` → go back down and honour it; `superseded` → continue against the new decision.
  - Record the hand-off and its outcome in Deliberation.

**Autonomy scales to tier** (`conventions` → Depth & autonomy): a **Direction**-level or product-level gap is intent — interview the human. A **Task/ADR** gap whose answer is derivable from code and existing docs you may drive yourself, escalating on genuine ambiguity.

## Phase 4 — Implement

Implement below the line once Phase 3 has resolved: a verdict recorded per governing ADR, and every `amendment candidate` carried through the Correction path. Derive the **Plan** from the Task and governing ADRs when the work needs step-decomposition, judged by author-blind risk (`conventions` → Depth & autonomy); write it with `sp new plan "<title>" --relates <task-id>,<adr-id>,…` (Context · Steps · Verification · Risk), then `sp check <plan-id>`. A Plan may span several sibling Tasks. **Inherit point:** before editing a file outside what Phases 2–3 situated, `sp file <path>`; its handbook gotchas are the reflexes for that move. Skeleton first, then body. Append verification results to the probe's Findings. Report done when every Verification item passes and every ADR decision holds.

**An operation on live or deployed state** (a service update, a config reload, a daemon restart):
- Record the rollback point (prior commit, prior config, prior version) in **Risk** at the moment of mutation.
- Confirm the state transition happened — new PID / port / version, process alive and stable — before running any verification.
- The first read after a restart is cold: re-run the smoke before calling it a failure.
- When an effect leg lives in a running service — an in-flight event, a fenced route, a log, a counter — follow `references/verifying-live-effect.md`: which legs you drive yourself, which belong to the operator, and how to record the ones you cannot run.

**A state-dependent suite** — pass/fail depends on what the tree holds at run time (open items, ledger lines, the fixture a scratch copy carries): pin a tree that reproduces the red, prove red→green on it, and run at HEAD too; when HEAD moves during the run, record the moved commits and re-verify at the new one. `references/verifying-test-suite.md` is the recipe.

**A new read path over live state:** write the test stub in the store's real shape (a key with its value, the real section shape), then run the new path from the worktree against the actual store, read-only, before the commit. When the smoke and the suite disagree, fix the code to the store's shape and the fixture to match. `references/verifying-live-effect.md` carries the drive pattern and the read-only-door recipe.

## Phase 5 — Reconcile (the return path)

Distill the probe into durable record, then freeze it. The probe moves to `reconciled` when **all** gates pass:

- Every **Open question** is resolved or explicitly deferred.
- Every Deliberation **conflict** is fixed in code or recorded as a superseding ADR with accepted trade-off. A product-level conflict closes through a Story Revision or a resolved `reflect` probe.
- Every **docs/CONTEXT.md** term the work touched is verified against the current code and updated if stale.
- The artifacts produced or updated are listed in **Reconciliation** (new/superseded ADR, updated Task, new Direction, CONTEXT entries), and their `relates` link back to this probe. Confirm each listed edit on disk with `git status --porcelain -- <path>` (or `git diff --stat`) before naming it; where a claimed edit is absent, record the correction in the probe as a dated finding.
- **The Task ledger states match the code.** A `done` line records the effect observed in use (adr-0003); where the effect did not show up, the line is `effect-not-achieved`. A Plan-less Task that was built is recorded `implemented` / `deferred` / `abandoned` (adr-0009). Reconcile each `unplanned → /plan` and `awaiting` frontier row against the code. Work that is genuinely open, or old / no-intent and possibly superseded, is surfaced for the human's supersede-or-plan call. `sp` recipe: `references/reconcile-task-ledger.md`.
- **Deposit** is done (`conventions` → Handbook → Deposit at a close): the probe's lessons are deposited, entries it relied on are promoted, and the cut test has run if triggered. Reconciliation carries the Deposit line, naming what was added, promoted, demoted or retired, or `nothing durable`. When `docs/handbook/` is missing and something is durable, create it as `note` Bootstrap does: five files, and an `index.md` with `last verified: never` and `last pruned: never · 0 entries`.

**The Reconciliation body is a map for the resuming reader.** For a probe that carried a **fix**, four legs:
1. Which Findings moved which clause above the line, and the artifact each delta was written into (amendments, supersessions, new ADRs), plus the verdicts re-checked and **unchanged**.
2. Every Open question answered, or deferred with what would resolve it.
3. What this session changed, split above/below the line, and what was deliberately left undone (an operator-only act, a cross-repo leg, a live-service effect).
4. The rollback point.

For a probe that carried a **build**, the legs are: the trigger (answered, or deferred with what would resolve it), the effect as observed in use (with the filter behind every count), the boundary (what this run touched and left alone), the risk, the decision (the ledger lines written), and the deposit.

Close it with `sp ledger reconcile <probe-id> "<one-line outcome>"`: it appends `- <probe-id> — reconciled DATE — <outcome>` to `docs/probes/LEDGER.md` and sets `status: reconciled` (without `sp`, do both by hand). Then run `sp check` on every artifact the probe produced, the whole-graph check (`conventions` → Batch check), and the commit step (`conventions` → Commit). A reconciliation commits as one batch — the probe, its artifacts, amendments, glossary entries, ledger lines — after prior uncommitted work in this stream has committed on its own. Check whose that prior work is with `git diff -- <file>` against the last commit; another workstream's diff is flagged to its owner and left out of your commit. A probe not worth pursuing is set `status: abandoned` and kept as a "why we didn't" record.

## Rules

- Implementation lives below the waterline; a commitment above it changes through recorded acceptance.
- Phase 3 runs on every trigger: explore the code, climb to the waterline, record a verdict on every governing ADR. Without a probe the verdicts go in the reply.
- A fix that works only by routing around an ADR → record an amendment candidate and investigate.
- **Judge effect against the text that governs now.** A `done` line claims the effect under the current governing Direction and Task; where one was amended after the work, the moved part belongs to the amending artifact.
- Above-the-line artifacts are authored through `top-down`, for the full drilling discipline.
- **Keep the probe's header current** (Trigger · status · Governing docs · Open questions). Before a session ends with the probe open — user away, execution blocked, awaiting an observed effect — append the dated findings and the pending open question to the probe. A run stopped after sealing its probe (a wall-clock limit, a stop signal) appends one run-ends block after the Reconciliation — the stop reason, what landed, what remains on the frontier — and commits it; that is the only append to a reconciled probe.
- **Use absolute paths in file-tool calls** aimed at a specific repo. File tools resolve relative paths against the session CWD, which a terminal call in another repo can move.
- **Editing a probe or doc:**
  - Re-read the exact region before appending, including after a compaction or a `sp` run (the `sp check` header prints `regenerated` when it rewrote a file).
  - After a patch that reports a non-exact match, read the diff it returns before the next edit to that file.
  - When the file was restructured under you, write the whole file.
  - With the full current text and a clean tree, apply several insertions as one scripted pass: each anchored on one distinctive line, each anchor asserted to occur exactly once, one write.
  - Read the file raw in that script (a paginating reader returns a prefix past its ~100K-character budget), and normalize the trailing newline before splitting.
  - When a test fails on code you patched before a compaction, print the function's source from disk and evaluate each condition in-process to locate the fault.
- **Read a protocol verb's source before calling it** when unsure what it touches, writes or returns.
- **A negative claim about the docs** ("no Direction/ADR for X") rests on a topic search: `sp -C <repo> search "<topic>"` in every repo of the workspace (adr-0011), reading the hits; add `--sealed` for history questions. Without `sp`, grep `docs/`. A parent probe's conclusions are testimony; the current tree wins.
- **State the filter behind any count** from a ledger or the doc tree: what counted, what was human-attested, what was excluded.
- Reconcile before closing; an `open` probe with unresolved questions is what `conventions` audit flags.
