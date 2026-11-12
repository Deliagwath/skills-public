---
name: general-usage-survey
description: Scans a project's situation — or the user's whole portfolio when the ask is "what am I working on" — and provides an honest assessment of what exists, what's unclear, what's adjacent, and what's blocking progress. Use when assessing current status, checking progress, or getting a landscape view, single project or across many, without drilling into details or strategy.
---

Scan the current situation and give me an honest picture of where things stand. Don't drill into specifics and don't pull back to strategy — stay at the level we're operating at right now.

<supporting-info>

## Gathering evidence

### One project

Read the docs that state state first — ledgers, decision files, status files: state is recorded, not inferred. Then `git status` for the uncommitted tree and `git log` for what recently landed. In a waterfall repo, `sp frontier` run from the repo root is the one-pass source for the not-done work, and the uncommitted tree is the work the frontier cannot see; those two are the whole inventory. Artifact bodies are for the drill, not the survey.

### A portfolio of the user's projects

When the ask spans projects — "what am I working on, and what's left on any of them":

1. **Enumerate the workstreams before reading anything.** `find <home> -maxdepth 1 -mtime -21 -not -name '.*'` for recently active top-level dirs, and classify each: a waterfall or product repo (`docs/` with ledgers), a live service, or a plain project dir. A dormant dir gets one line, not a section.
2. **Per waterfall repo, in order:** `cd <repo> && sp frontier` — its summary line and rows are the state; `git status --porcelain` for the WIP; the ledger's last lines for what just landed. Do not read artifact bodies here; the frontier is the inventory.
3. **Per non-waterfall project:** list files newest-first, open its ledger, notes or status file, and extract the open items it names.
4. **Live services get a restart-debt check:** `ps -axo pid,lstart,command` plus `launchctl list`. If the running tree started before the newest implemented batch, the "awaiting an observed effect" work is blocked on one operator restart — report it as the single cheapest unblock, not as a list of per-task debts.
5. **Classify every uncommitted tree** into a complete verified batch (say to commit it) and deliberately parked WIP (leave it, flag it) — the rule lives in `facilitated-waterfall-conventions` → Commit; the survey reports the split.

The report is one section per workstream — what exists, what's left, what's parked — then a "cheapest unblock" section, then a short recommended order. Close by stating what the survey did not verify — docs and ledgers were read; test suites and live behavior were not re-run — so every count reads as recorded, not re-measured.

## What to cover

Work through each area that's relevant. Skip anything that doesn't apply.

### What exists
What's already in place? What's working, what's partial, what's absent?

### What's unclear
Where is the current state ambiguous or contradictory? Surface gaps between what's assumed and what's actually true.

### What's adjacent
What sits next to the current work that could interact with it — positively or as a risk?

### What's blocking
Is anything preventing forward motion right now? Name it specifically.

## During the session

### Report what you find, don't interpret strategy
This is not the moment to question whether the direction is right (`zoom-out`) or drill into design decisions (`zoom-in`). Report the lay of the land.

### Flag contradictions between stated and actual state
If the user describes something as done but the code or docs say otherwise, surface it: "You said X is complete, but I'm seeing Y — which is current?"

### Be specific about unknowns
Don't say "this area needs more work." Say what specifically is missing or unresolved.

</supporting-info>
