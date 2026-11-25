---
name: facilitated-waterfall-observe
description: Closes work awaiting an observed effect from evidence of real use. Takes one awaiting Task (or a probe held open by an effect leg), reads where its Effect check says the effect shows, and leaves exactly one ledger line — done, effect not achieved, or checked. Reads and records; never stages the use, never fixes. Use when the frontier lists Tasks awaiting an observed effect, when asked whether something built is actually working in use, or to run an evidence pass.
---

Take one piece of built work whose effect has not been seen yet, look where that effect would show in normal use, and record what you found. One pass, one line. Read `conventions` for the ledger lines, the Effect check format and the commit step.

**Governing decision:** adr-0013 (and adr-0003, adr-0004 under it). An agent may write `done` or `effect not achieved` from evidence of real use it read. Every look leaves a line. The pass reads and records.

`sp` lives at `~/.agent-skills/facilitated-waterfall/scripts/sp`; test that file. Without it, read the ledgers and frontmatter by hand and append the line yourself, in the same format.

## Phase 1 — Take one item

- **A Task id** → confirm it is awaiting: `sp export <id>` returns the Task and its subtree, so select it — `sp export <id> | jq '.artifacts[] | select(.id == "<id>")'` — and read `frontier.class` `awaiting an observed effect` (or find its row in `sp frontier --awaiting`). Other states route elsewhere: a `done` Task is closed, an `effect not achieved` one is `bottom-up`'s trigger, an unbuilt one goes to `/plan` or `/implement`, and a `blocked` one waits for the operator.
- **A probe id** → see *A probe's effect leg* below.
- **Nothing named** → `sp frontier --awaiting` and take the first `awaiting` row, in the order listed (requested, never checked, then the oldest look).

Then read, by section:
- the Task's **Goal** and **Effect check** (`sp show <id> Goal "Effect check"`), and any `## Amendment` sections (`sp outline <id>` lists them);
- the **build date**: the Task's latest `implemented` line, or the latest of its Plans' lines (the selected entry's `.ledger`; `sp tree <id>` lists the Plans, whose entries carry their own). The evidence window opens there;
- each Plan's **Verification** (`sp show <plan-id> Verification`), to know what the mechanics already showed;
- the Task's earlier `checked` lines in `docs/tasks/LEDGER.md`: where the last pass looked, and what it was missing.

## Phase 2 — Settle the effect check

When the Task carries an `## Effect check` (or an `## Amendment, …: effect check`), use it as written.

Otherwise, work one out from the Goal and the code the build touched: where the effect would show in normal operation (**Where**: a store, route, log or command), what counts as **Seen**, what counts as **Not achieved**, and the **Earliest** real opportunity. Append it to the Task as `## Amendment, YYYY-MM-DD: effect check` with those four bullets, plus one line saying an `observe` pass derived it and from what. This amendment is the one edit a pass makes to a committed Task (`conventions` → Artifact formats), and the next pass reuses it. Run `sp check <id>`.

The Where is a place normal operation writes to. A test, a Verification step or the implemented line measures the mechanics. When the Goal truly has no effect beyond its Verification, say so in the amendment and write `checked` with "no effect beyond Verification: the operator decides whether this Task is done or abandoned".

## Phase 3 — Read the evidence

Read the Where for **use the system produced on its own** inside the window: after the build date, up to now.

- **Evidence is use the system produced.** Test requests, staged events, replayed Verification and runs you start yourself show mechanics only (adr-0013 §1); `verifying-live-effect.md`'s "drive the experiment yourself" belongs to a bottom-up probe.
- **Read-only.** Query the store, tail the log, open the route, run the read command. Leave the system you are reading — config, data, services, the code under test — as it is.
- **Negative checks need provenance, and present zeros are values** (`bottom-up/references/verifying-live-effect.md`). "No X in the log" counts when the log exists and belongs to the process. A `0` with no null marker is the system's own number.
- **Read durable records for transient artifacts.** A control file a run unlinks when it finishes (a stop file, a lock, a marker) is normally absent afterwards. Query the durable column the same code writes instead (a run row's `stop_requested` / `outcome`, the summary line in the run's own output).
- **Prove a removal with the same store's before.** When the build deleted a gate, a window or a filter, the store's own rows *before* the build stamp are the counterfactual: the refusal rows it used to write, how many, and the timestamp of the last one, which pins the switchover. Pair that with the in-window absence.
- **Record what you counted.** Note the command or query, the window, and what you filtered: rows counted, rows that match, rows dropped and why. That filter goes into the line. When two stores record the same act (the caller's wake log and the callee's own record), match them 1:1 within a small time tolerance and report both totals; count and name rows matched on one side only as another caller's traffic.
- **The operator's word is evidence.** When the operator tells you in this session that they saw the effect, the line records it as the operator's.

## Phase 4 — Write exactly one line

| What the reading showed | Line |
|---|---|
| The effect, as the check's **Seen** describes it, in real use inside the window | `sp ledger done <task-id> "<what was seen> — <store/path>, <window>"` |
| The check's **Not achieved**: the use happened and the effect did not follow | `sp ledger not-achieved <task-id> "<what was seen> — <store/path>, <window>"` |
| Neither: no real opportunity yet, the store is empty, or only part of the effect showed | `sp ledger checked <task-id> "looked at <where>, <window>; <what is still missing>"` |

**A `checked` line names the shape of the missing opportunity:** what would have to change for the leg to get an instance, and whether the current system can produce one at all. When the first real opportunity is structurally unreachable — a queue tier that is never picked while the higher tiers always have work — say so: "not yet" and "cannot yet unless X changes" send the next session to different work.

**`done` requires all of these;** when one is missing, write `checked` and say which:
- the line describes something the Plan's Verification and the implemented line do not;
- the evidence is use the system produced;
- the line names a store or path and a window;
- the whole effect showed. A partial effect takes `checked`, plus the `## Amendment` record `conventions` sets for a partially observed effect.

A Task that serves a Story (its `relates` chain reaches `docs/product/stories/`) is judged against the Story's Outcome: append `— story-NNN Outcome: met | not met` to the done or not-achieved text.

**Record a failure as found.** A failure becomes the `effect not achieved` line, `bottom-up`'s trigger, naming the failure precisely. The pass ends there, so the evidence describes the system as you read it.

Confirm the line landed: read it back from the kind's LEDGER.md, or check the row in `sp frontier` (it gains the `checked DATE` marker); the Task file has no Ledger section for `sp show`. Then commit the ledger line and any amendment as one batch (`conventions` → Commit), and nothing else from this pass. In a repo where `docs/` is not tracked, say so, and leave the line on disk.

## A probe's effect leg

Given an open probe whose only remaining work is an unrun effect leg (an Open question or Pending block waiting on real use), do the same reading for that leg. Then:
- append a dated block under the probe's **Findings** with what you read, where, the window and the filter;
- update that **Open question**: answered with the evidence, or still open with what is still missing;
- leave the probe's ledger and status to `bottom-up`'s Phase 5. When `bottom-up` routed you here, it runs Phase 5 next in the same session; otherwise the next `bottom-up` session on the probe does.

## Report

In a few lines: the item, the check used (as written, or derived and appended), where you looked and the window, what you counted, the line written, and the next item on `sp frontier --awaiting`. For an `effect not achieved` line, name `bottom-up` with that line as its trigger.

## Rules

- One pass, one item, one line.
- When the shared `docs/<kind>s/LEDGER.md` already holds another session's uncommitted lines (common in unattended runs, whose ticks write block lines), commit the amendment path-scoped, leave the ledger line in the working tree, and say so; `sp` reads the working tree, and the line survives a later revert.
- Evidence is use the system produced; Verification results stay on the implemented line; the pass reads and records.
- Unattended runs (overseer, a background job) follow the same rules. A question only the operator can answer, such as "is this effect still wanted?", goes into the `checked` line as what is still missing.
- A Task receives the Phase 2 amendment when it has no check, and no other edit.
