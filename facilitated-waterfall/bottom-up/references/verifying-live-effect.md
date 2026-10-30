# Verifying effect in a live system

A probe's Success signal names something in a running system — a route, a counter, a log, an in-flight event. Verification is the part most likely to be faked: an unobserved leg quietly becomes a claimed one, and a stamped `done` hides it. This is the recipe for which legs you run yourself, which belong to the operator, and how to record the rest.

## Drive the experiment yourself when you can be the subject

If the signal requires an in-flight event (a delegating turn, a streamed answer, a queued call) and the system exposes a read route keyed to your own session or connection, you do not need the operator to produce the event: generate the cheapest real instance of the required class (a trivial sub-task, a one-line request) and read the route for yourself. Judge the shape from the answer — fields present, counts, attribution. Record the id of the experiment you generated in Findings, so a resuming session can tell your own traffic from the operator's.

## Fenced legs belong to the operator

A route that answers the fence's rejection before its own method or body check is, on an unauthenticated probe, a test of the fence — not of the route. If the credential is not available to you, write the leg as operator-only: the exact request (method, path, parameters), the expected answer, and the side effect to confirm — e.g. the backend never seeing the request. Offer to run it if they hand you the credential. Never fabricate the answer of a leg you did not run; it stays `open` in Open questions and goes into the Pending block with the same content.

## Negative log checks need provenance

"The log has no X line" is evidence only if the log exists and belongs to the process you mean: check where the process's stdout/stderr fd points — or that the file grows while the process is alive — before claiming absence. If the log does not exist, the check is *un-run*, not *passed*: record it as such, with the reason, and state what *is* evidenced (the service came up, the request was served).

## Present zeros are values

A `0` the system reports with no null or unavailability marker is a present figure — the backend prices nothing, the queue is empty, the counter is cold. Read it as the system's own number and say so. Do not convert it to "missing data", and do not let a downstream view paint it as an error.

## Rendered-config changes: scratch render, then negative control

When a repo renders a runtime home from a template (a config the daemon reads), verify in two runs and keep both results:

1. **Scratch render** — reproduce the installer's render exactly (every substitution it does, every file it writes into the home). A FAIL on a home missing one rendered file is an artifact of an incomplete recipe, not a defect in your change: complete the recipe and re-run before reading the failure. Delete any copied secrets afterwards.
2. **Negative control on the live home** — the same check run against the live, not-yet-re-rendered home. A new *declaration* check ("the key is present") must FAIL there while the behavioural checks pass. That combination is the proof the check bites *and* the shape of the holds-by-accident state the change is pinning. Say which lines failed where.

A declaration the live process has not yet read is not in force: a long-lived daemon resolves config once per process, so the re-render and restart are what make the declaration real. Record them as the operator's owed steps with the exact commands, and never let the commit stand as evidence of the live effect. A live home the harness protects from agent writes stays the operator's step — offer to run the installer, don't hand-edit the rendered file.

## A dirty tree is split, never folded

When a file carries another workstream's uncommitted hunk and your change must land in the same file, do not commit their work and do not defer yours indefinitely: `git stash push -- <their paths>` (message naming the line), commit your change against HEAD path-scoped, then `git stash pop` to return their hunks to the worktree uncommitted. Verify afterwards that the pending diff contains only their hunks, and that your committed region survived the pop. Reconciliation batches that touch a shared ledger (LEDGER) may leave the ledger file itself uncommitted — name the other pending lines in the commit message.

## One hand-off block

When a leg is the operator's, give them one short list: what to run, the expected answer, the side effect to check, and what to report back. Write the same content into the probe's Pending block *before* you respond — the file, not the transcript, is what the next session inherits.
