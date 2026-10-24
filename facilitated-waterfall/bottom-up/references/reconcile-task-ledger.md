# Reconcile a waterfall repo's task ledger to the code

For the "bring `docs/tasks/LEDGER.md` and the frontier in line with the code" task — a reconciliation, not a build. Verify each Task's true state by climbing to the code, then record it. The frontier's derived labels are the starting hypothesis, never the ground truth.

## Read the current state

```
sp frontier        # rows: resume (effect-not-achieved / open probe) · task (unplanned / awaiting) · + the counts
sp check           # breaking vs drift; "drift by key: intent N" is soft (missing intent lines), not breaking
sp tree <id>       # the relates subtree, each node's state
sp show <id> Goal  # a task's intent, to know what to verify
```

`sp` is `~/.agent-skills/facilitated-waterfall/scripts/sp`, not on `PATH` — run that file, not `which sp`. If no `docs/tasks/LEDGER.md` exists, the first `sp ledger` line creates it.

## Pick each Task's state (climb to the code first)

- **Planned + built + effect observed in use** → `sp ledger done <id> "<the observed effect>"`. `done` = a ledger line in the kind's LEDGER.md alone (adr-0004), and it requires the effect actually observed in use (adr-0003).
- **Built but the effect never materialized** → the honest `sp ledger not-achieved <id> "<why it didn't show in use>"`. Becomes a *resume* row, not a stamp.
- **Plan-less (built through probes / code, never planned)** → `sp ledger implemented <id> "<mechanics evidence>"` — it moves from *unplanned* to *awaiting an effect* and drops off the unplanned rows. Deliberately parked → `deferred`; killed → `abandoned`; un-parked → `reopened` (adr-0009). Do **not** route these to `/plan`.
- **Superseded** → the `superseded-by` edge (`sp supersede`), not a done.
- **Genuinely open, or old / no-intent and possibly superseded** → leave unplanned and **surface** it for the human's supersede-or-plan call. Never stamp, never kill unilaterally — a scope decision is above the line.

## After the lines land

Re-run `sp frontier` and `sp check`; confirm the built work dropped out of the rows and only genuinely-open work + the honest not-achieved remain, and `check` stayed 0 breaking. Then seal the probe (Phase 5) with a Reconciliation that names the lines written. `done` is a ledger line alone — never a `status:` frontmatter write.

## Pitfall — commit provenance

Before committing a repo's uncommitted code, `git diff -- <file>` and `git show --stat <last commit>` to see whose stream it is. A sealed probe's "committed" claim covers only what ITS stream committed; an uncommitted diff sitting on top is often a *different* workstream's loose end — flag it to the owner, don't fold it into your reconciliation commit.
