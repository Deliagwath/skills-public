---
name: facilitated-waterfall-implement
description: Reads a Plan and related ADRs, resolves ambiguities through drilling, implements the code, and verifies against both the plan and architectural decisions. Use when implementing a planned task from documentation, or when code changes need to follow a documented plan with ADR constraints.
---

Read the input Plan and its related ADRs, drill on ambiguities, implement, then verify against both.

Find the input: interpret the argument naturally to locate the file in `docs/plans/`. If no argument, scan and ask.

## Phase 1 — Read

Read the plan (Context, Steps, Verification). Follow `relates` to read each ADR (Decision, Consequences). Read at least one matching file in the codebase before writing — existing patterns are constraints, not suggestions.

**Inherit point:** for each file the Steps will touch, run `sp file <path>` and read by tier (`conventions` → Handbook → Inherit). Its handbook gotchas are the reflexes for those edits. `sp` is `~/.agent-skills/facilitated-waterfall/scripts/sp`, not on `PATH`: test that file, not `which sp`. Without it, grep `docs/` for the paths instead.

**Plan facts are a dated snapshot, not the current truth.** Between planning and building the world moves: ledger lines accrue and clear, verbs ship, counts shift, and the exact defaults or states a plan was blocked on flip. Re-measure every plan-stated fact the build depends on (a count, an exit code, a presence, a flag default, a list of rows) before building on it, and again for the Verification pass — the evidence rule `conventions` applies to plan lines as much as ledger lines, and anything carried in from a summary or a prior session is suspect until re-verified. A fact that has moved is not silently adapted, and the plan is not blocked over it: a Plan sits at the append-only rule's other end (`conventions` → Append-only), so a wrong line is fixed in place with a dated inline correction marker, and the probe finding that drove the correction carries the record. An operator unblock line on the ledger that states a decision overrides the plan body — the build takes that decision from the unblock, not from the plan text it supersedes. Reserve a stop for the case the re-measurement shows the plan's premise has fallen through (a step that no longer applies, a Goal the tree outgrew): surface it rather than building against a dead premise.

**The tree is shared and moves under a long run.** The operator, a parallel session or tooling can commit, edit or revert between your steps — your own earlier commit included. A patch that fails to match on a file this session never edited is the tell of an external move: run `git status` and `git log --oneline` (a plain revert of your commit names you, a manual fix names the operator), re-read the region, and adapt the step to the current state — recording the external move in the working probe as a dated note, never silently undoing it. If your own earlier commit was reverted, name who did it before deciding what it means: a deliberate revert by the operator or a parallel session is their word — write a fresh block that supersedes it and says so, never re-add the reverted content verbatim, and do not speculate about the reason in the record; a mechanical unwind by the run protocol of a failed run's commits (## Gated runs) is bookkeeping, not a word about the content — the probe keeps the record, and the fresh run re-lands the work. Uncommitted lines in a shared file (a kind's ledger, the glossary) that are not yours stay out of your commit (Commit, rule 4 in `conventions`) and get flagged in the probe when stale.

## Phase 2 — Drill

Before implementing, surface and resolve ambiguities. Apply throughout:

- **Sharpen fuzzy language** — when a step or ADR uses vague terms, propose a precise interpretation immediately.
- **Probe with scenarios** — for any step where the outcome is unclear, state a concrete scenario and confirm the expected result.
- **Push back** — do not interpret generously and proceed. A step is unambiguous when it holds under challenge.
- **Resolve inline** — capture clarifications as they happen, don't batch.

Ask one question at a time. Give your recommended interpretation before waiting for a response. Flag any step that conflicts with an ADR before implementing it.

**A step that specializes an ADR is not a step that conflicts with it.** The ADR holds the commitment in general form, the plan the mechanism in a specific reading, and the plan wins the implementation: it is the later, more specific source, and the code builds the plan, not the ADR's intent. Do not widen the code toward the ADR's broader wording because it feels safer or more defensive — that silently deviates from the plan, and its narrower scope is usually the actual decision the ADR left open. Record which reading was taken, and why, in the probe, so a later reader arriving via the ADR is not misled; if the ADR's general wording keeps pulling builds back toward the broader reading, the durable fix is a dated `## Amendment` on the ADR naming the plan's reading — a waterline act needing the operator's acceptance, so propose it, never amend it unilaterally. The shape that does conflict — a plan line that *contradicts* an ADR decision, a replacement of it rather than a reading of it — stops the build until the trade-off is surfaced and accepted supersession is recorded (`conventions` → ascent guard).

## Phase 3 — Implement

Follow plan steps in order. Skeleton first (signatures and structure), then body. Before writing any non-obvious decision, state the assumption and why.

## Phase 4 — Verify

Check the implementation against:
1. Each item in the Plan's **Verification** section — run commands, observe behaviours.
2. Each **ADR Decision** — confirm the implementation honours it.

**Settle a coarse leg per feature, not per hit.** A Verification leg phrased as a whole-file or whole-package search ("grep for `X|Y` finds no registration") is a word-level proxy for a feature-level claim. Run the leg's command verbatim for the record, then attribute every hit to the feature that owns it — a sibling feature's legitimate use of the same pattern, and a word match inside a comment, are not violations of a leg scoped to one feature. The claim is decided by the symbol-level search for the actual registration call, and the report carries both: the literal output and the scoped verdict, so the reader can see why hits are not failures.

Surface any gap explicitly. Do not report done if any verification item fails or any ADR decision is violated.

**Attribute a suite failure to a clean baseline before calling it yours.** A full suite on a shared tree can fail for reasons the tree's baseline carries, so reproduce each failure in a clean `git worktree` at `HEAD` (same command, clean checkout) before attributing it to your diff. A failure that reproduces on clean `HEAD` is pre-existing: report it with the reproduction, and do not repair it inside your batch — the repair is a different task with its own record, and silently fixing unrelated red folds another workstream's fix into your commit.

**Delegating the test-writing.** When the verification work is a large test-writing effort (several test homes, each with its own fixtures and style), hand it to a subagent — the parent keeps the mechanism and the record context, and the child is context-blind, so the brief must stand alone. It needs, all of it: (1) a per-file summary of what changed — signatures, new fields, semantics, not a diff dump; (2) the existing test home per behaviour, and the repo's exact runner command; (3) the repo's test-style rules — every new block cites its source artifact in a comment, no existing assertion is weakened, extend an existing home before creating a new file; (4) hard boundaries — do not modify non-test source files, and if a test reveals a genuine mechanism bug, report it verbatim instead of fixing it (the fix is the parent's call, because the parent holds the ADR verdicts); (5) a safety note when the tree is shared — name files carrying another workstream's uncommitted edits as off-limits, and say that credential-bearing config files must never be quoted in output. Demand an output schema with exact pass/fail counts and verbatim failure output, then re-run the same suite yourself: a child's summary is a self-report, not evidence.

## Phase 5 — Record

Once every Verification item passes and no ADR is violated, run `sp ledger implemented <plan-id> "<N>/<N> checks passed"`. It appends this line to `docs/plans/LEDGER.md` (without `sp`, append it by hand, creating the file with no header). The argument renders verbatim after an auto-prepended `verification: ` — pass the bare summary (`"6/6 passed"`), never a string of its own that begins with `verification:`, or the line stutters and the ledger entry must be patched.

```
- <plan-id> — implemented <date> — verification: <N>/<N> checks passed
```

This is the only record that a Plan is **implemented**, meaning its mechanics are verified. Plans are never edited to mark themselves complete, the same way a changed ADR is superseded rather than rewritten. If a later session finds this entry was wrong, the fix is a new line stating the correction, never an edit to this one.

`implemented` is not `done`. Done means the Task's intended effect has been observed in real use (see `conventions` → Status & ledger), and a Verification pass can't show that. End your report by saying so in one line: the effect is not yet observed, and what would show it, such as an observable sign in use and where to look. Write nothing for it. The absence of a done line already means "not yet observed".

## Gated runs — building a plan under a repo-provided run protocol

Some repos run plan builds as autonomous, ticked runs under a run protocol (overseer's is `prompts/protocol.md`); the run is handed one rather than deriving it from this skill. When the build is gated, the protocol — not the plan's step count — sets the boundaries:

- **The step boundary is a protocol command.** Commit only that step's paths (path-scoped; never a mixed tree), then ask the protocol whether to continue before starting the next step — after every step, including ones that look trivial.
- **A stop signal ends the run, not the plan.** The cause may be a requested stop or an external switch flipping; the handling is the same. Finish the current step green — the suite runs, the commit lands — then write where you are into the working probe as a dated Findings block: what is done (commits, what was verified), what is next (the exact next step with `file:line`, and the remaining order), and any open question. Commit the probe and end. Never start the next step to "get to the end", and never heroically finish the remaining plan in one push: the remaining steps ride the frontier's resume row into the run that resumes.
- **A stopped run keeps its commits.** Revert is for failed steps only; green work is never unwound on a stop.
- **A failed run is unwound; do not fight the unwind.** A mechanism failure — a failed step, or the run's real-time limit (a ticked bound such as overseer's 2 h: it is wall clock, and an interactive, steered session can easily outlive it) — reverts every commit the run made, blocks the item with a recorded question, and closes the run row, on the mechanism's own schedule, without your seeing it. After a long gap or a compaction resume, verify the run is still yours before acting: your SHAs in `git log` with Reverts over them, a blocked ledger line you never wrote, `should-stop` now answering stop. When the run is dead, the response is fixed: no re-landing the reverted work, no next step, and no further work commits under the closed run id — the one commit a dead run still takes is the probe itself, its place record. Save your place in the working probe as a dated Findings block — the reverted commits by SHA, the exact next step with `file:line`, the open question — and restore verbatim, marked as a restoration, any findings text the unwind stripped from the probe file (`git show <reverted commit> -- <probe>`) so the resuming run finds the probe self-contained. Commit the probe, call the block channel (the mechanism's own block line means it answers `already blocked`, so your new question goes into the probe as a finding rather than a ledger line), and end. The unwound content is fully recoverable from git; the operator unblocks and starts the fresh run; and a limit-fail is a designed halt the system was built and verified for, not a defect to work around by committing again.
- **An incomplete build records no ledger line.** `implemented` is all-or-nothing across the plan's Verification; a build stopped mid-way writes only its probe place — no `implemented`, no `done` — and the resuming run owns the Verification pass.

## Rules
- Do not implement beyond the plan's scope.
- Under a gated run, a stop signal is obeyed at the current step boundary (## Gated runs): finish green, record the place, end; the plan's remaining steps belong to the resuming run.
- A run the mechanism has failed is over even though your session lives (## Gated runs): no re-landing of reverted commits, no next step under the closed run — save the place in the probe, commit it, end.
- An external move in the tree (## Phase 1) is checked, understood and recorded in the probe — never silently reverted; a step is rebuilt against the state the tree is in, not the state the plan assumed.
- Do not skip verification.
- If a new ambiguity surfaces during implementation, stop and drill before continuing.
- Do not append a ledger entry unless every verification item passed and no ADR was violated.
