# Verifying effect in a live system

A probe's Success signal names something in a running system — a route, a counter, a log, an in-flight event. This is the recipe for which legs you run yourself, which belong to the operator, and how to record each.

## Drive the experiment yourself when you can be the subject

When the signal requires an in-flight event (a delegating turn, a streamed answer, a queued call) and the system exposes a read route keyed to your own session or connection, generate the cheapest real instance of the required class (a trivial sub-task, a one-line request) and read the route for yourself. Judge the shape from the answer — fields present, counts, attribution. Record the id of the experiment you generated in Findings, so a resuming session can tell your traffic from the operator's.

## Fenced legs belong to the operator

A route that answers the fence's rejection before its own method or body check is, on an unauthenticated probe, a test of the fence. When the credential is not available to you, write the leg as operator-only: the exact request (method, path, parameters), the expected answer, and the side effect to confirm — e.g. the backend not seeing the request. Offer to run it if they hand you the credential. The leg stays `open` in Open questions until it runs, and goes into the Pending block with the same content.

## Negative log checks need provenance

"The log has no X line" is evidence when the log exists and belongs to the process you mean: check where the process's stdout/stderr fd points — or that the file grows while the process is alive — before claiming absence. When the log does not exist, record the check as *un-run*, with the reason, and state what *is* evidenced (the service came up, the request was served).

## Present zeros are values

A `0` the system reports with no null or unavailability marker is a present figure — the backend prices nothing, the queue is empty, the counter is cold. Report it as the system's own number, and as a value in downstream views.

## Rendered-config changes: scratch render, then negative control

When a repo renders a runtime home from a template (a config the daemon reads), verify in two runs and keep both results:

1. **Scratch render** — reproduce the installer's render exactly (every substitution it does, every file it writes into the home). When a check fails on a home missing one rendered file, complete the recipe and re-run before reading the failure. Delete any copied secrets afterwards.
2. **Negative control on the live home** — the same check run against the live, not-yet-re-rendered home. A new *declaration* check ("the key is present") fails there while the behavioural checks pass: that combination shows the check bites, and shows the state the change pins. Say which lines failed where.

A long-lived daemon resolves config once per process, so the re-render and restart put a declaration in force. Record them as the operator's owed steps with the exact commands; the live effect is evidenced after they run. A live home the harness protects from agent writes stays the operator's step: offer to run the installer.

## Split a dirty tree

When a file carries another workstream's uncommitted hunk and your change lands in the same file: `git stash push -- <their paths>` (message naming the line), commit your change against HEAD path-scoped, then `git stash pop` to return their hunks to the worktree uncommitted. Verify afterwards that the pending diff contains only their hunks, and that your committed region survived the pop. Reconciliation batches that touch a shared ledger may leave the ledger file uncommitted; name the other pending lines in the commit message.

## A new or changed read path: drive the worktree

When the change is a pure function of a store or live input — a projection, aggregate, filter — and the effect leg is a service restart you cannot run, import the changed function from the repo's worktree (its own venv) and drive it against the same live store the running service reads, while reading the running route for the old number. The pair — route (old code) and worktree function (new code) on the same input — is the restart's effect, recorded in the probe with the script's path. The after number evidences the *mechanism*; the stamp waits on the operator's restart and their read, and the probe says so.

The same drive is the **pre-commit gate** for a *new* read path — a check leg, a projection, a query door — over a live store: run it from the worktree against the real store, read-only, before the commit, and record what it returns in Findings. When the smoke and the stub suite disagree, fix the code to the shape the store has, and the fixture to match.

## Read-only doors over live stores

Build a no-write door on a barrier the store's engine enforces. For SQLite, check `PRAGMA journal_mode` first: a WAL-mode store fails to open under a `file:...?mode=ro` URI, while a normal connection under `PRAGMA query_only = ON` refuses every write. Keep a query-shape guard (a `SELECT` prefix, rejected at the API) as the second layer. The suite asserts the shape guard; the live smoke above asserts the engine path.

## One hand-off block

When a leg is the operator's, give them one short list: what to run, the expected answer, the side effect to check, and what to report back. Write the same content into the probe's Pending block before you respond, so the next session inherits it.
