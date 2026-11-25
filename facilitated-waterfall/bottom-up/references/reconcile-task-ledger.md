# Reconcile a waterfall repo's task ledger to the code

For the "bring `docs/tasks/LEDGER.md` and the frontier in line with the code" task — a reconciliation, not a build. Verify each Task's true state by climbing to the code, then record it. The frontier's derived labels are the starting hypothesis.

## Read the current state

```
sp frontier        # rows: resume (effect-not-achieved / open probe) · task (unplanned / awaiting) · + the counts
sp check           # breaking vs drift; "drift by key: intent N" is soft (missing intent lines), not breaking
sp tree <id>       # the relates subtree, each node's state
sp show <id> Goal  # a task's intent, to know what to verify
```

`sp` lives at `~/.agent-skills/facilitated-waterfall/scripts/sp`; run that file. When no `docs/tasks/LEDGER.md` exists, the first `sp ledger` line creates it.

## Pick each Task's state (climb to the code first)

- **Planned + built + effect observed in use** → `sp ledger done <id> "<the observed effect>"`. `done` is a ledger line in the kind's LEDGER.md (adr-0004), and it records the effect observed in use (adr-0003).
- **Built, and the effect did not show in use** → `sp ledger not-achieved <id> "<why it didn't show in use>"`. It becomes a *resume* row.
- **Plan-less (built through probes / code)** → `sp ledger implemented <id> "<mechanics evidence>"`: it moves from *unplanned* to *awaiting an effect*. Deliberately parked → `deferred`; killed → `abandoned`; un-parked → `reopened` (adr-0009).
- **Superseded** → the `superseded-by` edge (`sp supersede`).
- **Genuinely open, or old / no-intent and possibly superseded** → leave it unplanned and **surface** it for the human's supersede-or-plan call; a scope decision sits above the line.

## After the lines land

Re-run `sp frontier` and `sp check`: the built work has left the rows, the genuinely-open work and the not-achieved lines remain, and `check` stays 0 breaking. Then seal the probe (Phase 5) with a Reconciliation that names the lines written.

## Commit provenance

Before committing a repo's uncommitted code, run `git diff -- <file>` and `git show --stat <last commit>` to see whose stream it is. A sealed probe's "committed" claim covers what its own stream committed; flag another workstream's uncommitted diff to its owner and keep it out of your commit. The exception (conventions → Commit, rule 4): an append-only ledger line you can verify against the live state it claims is a completed record — commit the file whole and name the borrowed line in the commit message.
