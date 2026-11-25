---
name: facilitated-waterfall-implement
description: Reads a Plan and related ADRs, resolves ambiguities through drilling, implements the code, and verifies against both the plan and architectural decisions. Use when implementing a planned task from documentation, or when code changes need to follow a documented plan with ADR constraints.
---

Read the input Plan and its related ADRs, drill on ambiguities, implement, then verify against both.

Find the input: interpret the argument naturally to locate the file in `docs/plans/`. If no argument, scan and ask.

## Phase 1 — Read

Read the plan (Context, Steps, Verification). Follow `relates` to read each ADR (Decision, Consequences). Read at least one matching file in the codebase before writing: existing patterns are constraints.

**Inherit point:** for each file the Steps will touch, run `sp file <path>` and read by tier (`conventions` → Handbook → Inherit). Its handbook gotchas are the reflexes for those edits. `sp` lives at `~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file. Without it, grep `docs/` for the paths.

**Re-measure the plan's facts.** A plan's facts are dated: ledger lines, verbs, counts and defaults move between planning and building. Before building on a plan-stated fact (a count, an exit code, a presence, a flag default, a list of rows), re-run the query behind it, and again for the Verification pass.
- A fact that has moved → fix the plan line in place with a dated inline correction marker, recorded in the probe finding that drove it (`conventions` → Append-only), and build on the fresh value.
- An operator unblock line on the ledger that states a decision → build that decision; it overrides the plan body.
- The plan's premise has fallen through (a step that no longer applies, a Goal the tree outgrew) → stop and surface it.

**Track the shared tree.** The operator, a parallel session or tooling can commit, edit or revert between your steps. When a patch fails to match on a file this session never edited:
1. Run `git status` and `git log --oneline` to see who moved it (a plain revert of your commit names its author; a manual fix names the operator).
2. Re-read the region and adapt the step to the current state.
3. Record the external move in the working probe as a dated note.

When your own earlier commit was reverted, name who did it first:
- a deliberate revert by the operator or a parallel session is their word: write a fresh block that supersedes it and says so, with new content, and record the revert without guessing at its reason;
- a mechanical unwind of a failed run's commits by the run protocol (*Gated runs*) is bookkeeping: the probe keeps the record, and the fresh run re-lands the work.

Another stream's uncommitted lines in a shared file (a kind's ledger, the glossary) stay out of your commit (`conventions` → Commit, rule 4); flag stale ones in the probe.

## Phase 2 — Drill

Before implementing, surface and resolve ambiguities. Apply throughout:

- **Sharpen fuzzy language** — when a step or ADR uses vague terms, propose a precise interpretation immediately.
- **Probe with scenarios** — for any step where the outcome is unclear, state a concrete scenario and confirm the expected result.
- **Push back** — a step is unambiguous when it holds under challenge.
- **Resolve inline** — capture clarifications as they happen.

Ask one question at a time. Give your recommended interpretation before waiting for a response. Flag any step that conflicts with an ADR before implementing it.

**Specializing an ADR vs conflicting with it.**
- *A step that specializes an ADR* — the ADR holds the commitment in general form, the plan a specific reading of it — is built as the plan states, at the plan's scope. Record in the probe which reading was taken and why. When the ADR's general wording keeps inviting the broader reading, propose a dated `## Amendment` on the ADR naming the plan's reading; it is a waterline act for the operator to accept.
- *A step that contradicts an ADR decision* — a replacement rather than a reading — stops the build until the trade-off is surfaced and accepted supersession is recorded (`conventions` → ascent guard).

## Phase 3 — Implement

Follow plan steps in order. Skeleton first (signatures and structure), then body. Before writing any non-obvious decision, state the assumption and why.

## Phase 4 — Verify

Check the implementation against:
1. Each item in the Plan's **Verification** section — run commands, observe behaviours.
2. Each **ADR Decision** — confirm the implementation honours it.

Surface any gap explicitly. Report done when every Verification item passes and every ADR decision holds.

**Scope a coarse leg to its feature.** For a Verification leg phrased as a whole-file or whole-package search ("grep for `X|Y` finds no registration"), run the command verbatim for the record, then attribute every hit to the feature that owns it; a sibling feature's use of the same pattern, or a match inside a comment, sits outside a leg scoped to one feature. Decide the claim with a symbol-level search for the actual registration call, and report both the literal output and the scoped verdict.

**Attribute a suite failure against a clean baseline.** Reproduce each failure in a clean `git worktree` at `HEAD` with the same command. A failure that reproduces there is pre-existing: report it with the reproduction and leave its repair to its own task and record.

**Delegating the test-writing.** When the verification work is a large test-writing effort (several test homes, each with its own fixtures and style), hand it to a subagent. The parent keeps the mechanism and the record; the child starts without context, so the brief stands alone and carries all of:
1. a per-file summary of what changed — signatures, new fields, semantics;
2. the existing test home per behaviour, and the repo's exact runner command;
3. the repo's test-style rules — every new block cites its source artifact in a comment, existing assertions stay as strong as they are, extend an existing home before creating a new file;
4. boundaries — the child edits test files only, and reports a genuine mechanism bug verbatim for the parent to fix (the parent holds the ADR verdicts);
5. on a shared tree, the files carrying another workstream's uncommitted edits (off-limits), and that credential-bearing config stays out of output.

Require an output schema with exact pass/fail counts and verbatim failure output, then re-run the same suite yourself and report your own run.

## Phase 5 — Record

Once every Verification item passes and every ADR holds, run `sp ledger implemented <plan-id> "<N>/<N> checks passed"`. It appends this line to `docs/plans/LEDGER.md` (without `sp`, append it by hand, creating the file with no header). `sp` prepends `verification: ` to the argument, so pass the bare summary (`"6/6 passed"`).

```
- <plan-id> — implemented <date> — verification: <N>/<N> checks passed
```

This line is the record that a Plan is **implemented**: its mechanics are verified. The Plan file itself stays unmarked. A correction to the entry is a new line stating it.

`implemented` is not `done`: done means the Task's intended effect has been observed in real use (`conventions` → Status & ledger). End your report with one line saying the effect is not yet observed and what would show it — an observable sign in use, and where to look. The absent done line records the rest.

## Gated runs — building a plan under a repo-provided run protocol

Some repos run plan builds as autonomous, ticked runs under a run protocol (overseer's is `prompts/protocol.md`), handed to the run. Under a gated build, the protocol sets the boundaries:

- **The step boundary is a protocol command.** Commit only that step's paths (path-scoped), then ask the protocol whether to continue before starting the next step — after every step.
- **A stop signal ends the run at the current step.** Whatever its cause (a requested stop, an external switch), finish the current step green — the suite runs, the commit lands — then write a dated Findings block in the working probe: what is done (commits, what was verified), what is next (the exact next step with `file:line`, and the remaining order), and any open question. Commit the probe and end. The remaining steps ride the frontier's resume row into the resuming run.
- **A stopped run keeps its commits.** Revert applies to failed steps only.
- **A failed run is unwound by the mechanism.** A failed step, or the run's real-time limit (wall clock, such as overseer's 2 h; an interactive session can outlive it), makes the mechanism revert every commit the run made, block the item with a recorded question, and close the run row on its own schedule. After a long gap or a compaction resume, check the run is still yours: your SHAs in `git log` with Reverts over them, a blocked ledger line you did not write, `should-stop` answering stop. When the run is closed:
  1. Save your place in the working probe as a dated Findings block — the reverted commits by SHA, the exact next step with `file:line`, the open question.
  2. Restore, marked as a restoration, any findings text the unwind stripped from the probe (`git show <reverted commit> -- <probe>`), so the probe is self-contained.
  3. Commit the probe — the one commit a closed run takes.
  4. Put your question in the probe as a finding (the block channel answers `already blocked`, since the mechanism wrote the block line), and end.

  The unwound work is recoverable from git, and the operator unblocks and starts the fresh run.
- **An incomplete build records no ledger line.** `implemented` covers the plan's whole Verification; a build stopped mid-way writes only its probe place, and the resuming run owns the Verification pass.

## Rules
- Implement within the plan's scope.
- Under a gated run, obey a stop signal at the current step boundary: finish green, record the place, end.
- A closed run ends the build in this session: save the place in the probe, commit it, end.
- Record an external move in the tree in the probe, and build each step against the tree as it is.
- Run every Verification item.
- When a new ambiguity surfaces during implementation, stop and drill before continuing.
- Append the ledger entry when every Verification item passed and every ADR holds.
