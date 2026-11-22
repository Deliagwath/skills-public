---
name: facilitated-waterfall-observe
description: Closes work awaiting an observed effect from evidence of real use. Takes one awaiting Task (or a probe held open by an effect leg), reads where its Effect check says the effect shows, and leaves exactly one ledger line — done, effect not achieved, or checked. Reads and records; never stages the use, never fixes. Use when the frontier lists Tasks awaiting an observed effect, when asked whether something built is actually working in use, or to run an evidence pass.
---

Take one piece of built work whose effect has not been seen yet, look where that effect would show in normal use, and record what you found. One pass, one line. Read `conventions` for the ledger lines, the Effect check format and the commit step — not repeated here.

**Governing decision:** adr-0013 (and adr-0003, adr-0004 under it). An agent may write `done` or `effect not achieved` from evidence of real use it read. Every look leaves a line. The pass reads and records; it never fixes.

`sp` is `~/.agent-skills/facilitated-waterfall/scripts/sp` (test that file, not `which sp`). Without it, read the ledgers and frontmatter by hand and append the line yourself, in the same format.

## Phase 1 — Take one item

- **A Task id** → confirm it is awaiting: `sp export <id>` returns the Task *and* its subtree, so select it — `sp export <id> | jq '.artifacts[] | select(.id == "<id>")'` — and read `frontier.class` `awaiting an observed effect` (or find its row in `sp frontier --awaiting`). Anything else is not this skill's: a `done` Task is closed, an `effect not achieved` one is `bottom-up`'s trigger, an unbuilt one needs `/plan` or `/implement`, and a `blocked` one waits for the operator.
- **A probe id** → see *A probe's effect leg* below.
- **Nothing named** → `sp frontier --awaiting` and take the first `awaiting` row. The order is the record (requested, never checked, then the oldest look); don't re-rank it.

Then read, by section, not whole:
- the Task's **Goal** and **Effect check** (`sp show <id> Goal "Effect check"`), and any `## Amendment` sections (`sp outline <id>` lists them);
- the **build date**: the Task's latest `implemented` line, or the latest of its Plans' lines (the selected entry's `.ledger`; `sp tree <id>` lists the Plans, whose entries carry their own). The evidence window opens there;
- each Plan's **Verification** (`sp show <plan-id> Verification`). You read it to know what a `done` line must *not* restate;
- the Task's earlier `checked` lines in `docs/tasks/LEDGER.md`: where the last pass looked, and what it was missing.

## Phase 2 — Settle the effect check

If the Task carries an `## Effect check` (or an `## Amendment, …: effect check`), use it as written.

If it has none, work one out from the Goal and the code the build touched: where the effect would show in normal operation (**Where**: a store, route, log or command), what counts as **Seen**, what counts as **Not achieved**, and the **Earliest** real opportunity. Append it to the Task as `## Amendment, YYYY-MM-DD: effect check` with those four bullets, plus one line saying it was derived by an `observe` pass and from what. That amendment is the one legal edit to a committed Task (`conventions` → Artifact formats); write it once, so the next pass reuses it. Run `sp check <id>`.

A Where that is a test, a Verification step or the implemented line is not a Where. It measures the mechanics, and reading it would stamp a replay `done`. If the Goal truly has no effect beyond its Verification, say so in the amendment and write `checked` with "no effect beyond Verification: the operator decides whether this Task is done or abandoned". Never write `done` for it.

## Phase 3 — Read the evidence

Read the Where for **use the system produced on its own** inside the window: after the build date, up to now.

- **Never generate the use.** No test request, no staged event, no replayed Verification, no run you start yourself. `verifying-live-effect.md`'s "drive the experiment yourself" proves mechanics inside a bottom-up probe. Here a staged instance never earns `done` (adr-0013 §1).
- **Read-only.** Query the store, tail the log, open the route, run the read command. Change nothing in the system you are reading. That includes config, data, services and the code under test.
- **Negative checks need provenance, and present zeros are values** (`bottom-up/references/verifying-live-effect.md`). "No X in the log" counts only if the log exists and belongs to the process. A `0` with no null marker is the system's own number.
- **Record what you counted.** Note the command or query, the window, and what you filtered: rows counted, rows that match, rows dropped and why. That filter goes into the line.
- **The operator's word is evidence.** If the operator tells you in this session that they saw the effect, that counts, and the line says it is the operator's.

## Phase 4 — Write exactly one line

| What the reading showed | Line |
|---|---|
| The effect, as the check's **Seen** describes it, in real use inside the window | `sp ledger done <task-id> "<what was seen> — <store/path>, <window>"` |
| The check's **Not achieved**: the use happened and the effect did not follow | `sp ledger not-achieved <task-id> "<what was seen> — <store/path>, <window>"` |
| Neither: no real opportunity yet, the store is empty, or only part of the effect showed | `sp ledger checked <task-id> "looked at <where>, <window>; <what is still missing>"` |

**Before writing `done`, refuse it if** any of these hold. Write `checked` instead and say why:
- the line could be written from the Plan's Verification or the implemented line alone;
- the evidence is an instance you or a test produced;
- the line names no store or path, or no window;
- only part of the effect showed. `done` is all-or-nothing. A partial effect takes `checked`, plus the `## Amendment` record that `conventions` requires for a partially observed effect.

A Task that serves a Story (its `relates` chain reaches `docs/product/stories/`) is judged against the Story's Outcome: append `— story-NNN Outcome: met | not met` to the done or not-achieved text.

**Never fix in the pass.** A failure you find becomes the `effect not achieved` line, which is `bottom-up`'s trigger. If you repaired it first, the evidence would describe a system that did not exist when you read it. Name the failure precisely in the line and stop.

Then commit the ledger line and any amendment as one batch (`conventions` → Commit). Commit nothing else of this pass. In a repo where `docs/` is not tracked, say so, and leave the line on disk.

## A probe's effect leg

Given an open probe whose only remaining work is an unrun effect leg (an Open question or Pending block waiting on real use), do the same reading for that leg. Then:
- append a dated block under the probe's **Findings** with what you read, where, the window and the filter;
- update that **Open question**: answered with the evidence, or still open with what is still missing;
- write no ledger line for the probe and do not reconcile it. Closing it is `bottom-up`'s Phase 5, which the next session on the probe runs.

## Report

Say in a few lines: the item, the check used (as written, or derived and appended), where you looked and the window, what you counted, the line written, and the next item on `sp frontier --awaiting`. If the line is `effect not achieved`, name `bottom-up` with that line as its trigger.

## Rules

- One pass, one item, one line. Never write a second line to "correct" a look in the same pass.
- Never stage the use. Never restate Verification as an effect. Never fix.
- Unattended runs (overseer, a background job) follow the same rules. A question only the operator can answer, such as "is this effect even wanted any more?", goes into the `checked` line as what is still missing, not into a block.
- Old Tasks stay valid untouched. Only the amendment from Phase 2 is written to a Task, and only when the Task has no check.
