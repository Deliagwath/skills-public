Review the current implementation against its plan and ADRs, fix what can be fixed autonomously, and surface decisions that require the programmer to resolve. Each review cycle spawns a fresh subagent so findings are never influenced by the accumulated context of previous cycles.

You are the supervisor. You orchestrate the loop, apply fixes, and make escalation decisions. You do not do the reviewing yourself.

---

## Phase 1 — Anchor (supervisor, once)

Identify what the implementation is measured against. In order of preference:

1. A plan file (`docs/plans/`) linked to the current work
2. ADRs referenced by that plan
3. A task or epic the plan relates to

If none exist, ask the user what the implementation is supposed to do before proceeding.

Read every anchor document fully. Produce a compact anchor brief — a summary of constraints, steps, and verification items the reviewer will use. This brief is passed to every reviewer subagent.

## Phase 2 — Spawn reviewer (each cycle)

Spawn a fresh subagent. Pass it:

1. The anchor brief from Phase 1
2. A summary of what was fixed in the previous cycle (empty on the first cycle)
3. This instruction: "Review the current implementation against the anchor. For each finding, state what is wrong, where it is, and what the correct behaviour should be according to the anchor. Do not fix anything. Return a findings list only."

Wait for the subagent to return its findings before proceeding.

## Phase 3 — Classify findings (supervisor)

For each finding returned by the subagent, classify it:

**Autonomous fix** — the correct resolution is unambiguous given the anchor. No new decision is required.

Examples: a bug with a clear correct behaviour defined in the plan, a missed step, a failing test with an obvious cause, a type error, a deviation from the plan with an obvious correction.

**Human decision** — the correct resolution requires a judgement call not covered by the anchor. Fixing it autonomously would be guessing.

Examples: the plan is silent on an edge case that surfaced, two valid approaches exist and neither is ruled out by the ADRs, a bug with multiple valid fixes with different trade-offs, anything that suggests the plan or ADR itself needs revision.

Do not blur the line. If uncertain, treat it as a human decision.

## Phase 4 — Fix (supervisor)

Apply all autonomous fixes in one pass. Run any available tests, linters, or type checkers after fixing. Note any new failures — they enter the next cycle's findings.

## Phase 5 — Escalate (supervisor, if blocked)

If any human-decision findings remain, surface them one at a time:

- State the finding concisely
- State why it cannot be resolved autonomously
- Present the options you see, with your recommended resolution
- Wait for the programmer's answer before continuing

After each resolution, apply any follow-on fixes, then continue the loop.

## Loop

Return to Phase 2 and spawn a new reviewer subagent. Continue until one of:

**Clean** — the subagent returns no findings. Report done, summarise what was fixed across all cycles.

**Blocked** — a human decision is needed. Escalate, then resume once resolved.

**Scope change** — a finding reveals the plan or an ADR needs revision, not the implementation. Stop the loop. Surface this explicitly: "This finding suggests the anchor needs updating before implementation can continue." Let the programmer decide how to proceed.

---

## Rules

- Never fix a human-decision finding autonomously.
- Do not loop indefinitely on the same finding. If the same finding recurs after a fix attempt, escalate it as a human decision regardless of original classification.
- Do not expand scope. Out-of-plan findings are noted as open items — not implemented.
- The reviewer subagent only reports. It never fixes. All fixes go through the supervisor.
