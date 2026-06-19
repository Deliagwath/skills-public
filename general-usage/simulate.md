---
name: simulate
description: Traces every execution branch of a target function, route, method, or system and writes detailed findings to the working directory. Use when analyzing code execution paths, understanding system behavior, or documenting how a component works across all scenarios.
---

Trace every execution branch of the target and write the findings to the working directory.

The target is whatever the user specifies — a single function, route, or method; or a system (service, module, feature area). If no target is given, ask for one before proceeding.

---

## Step 0 — Determine scope

Before tracing anything, classify the target:

**Single entry point** — one function, method, route, or handler. Proceed directly to Phase 1.

**System** — a service, module, or named feature that composes multiple entry points (e.g. "the auth service", "the orders API", "the payment module"). Proceed to the System path below.

---

## System path

When the target is a system:

### Enumerate entry points

Scan the codebase and list every entry point the system exposes:
- HTTP routes / RPC methods
- Event and message queue consumers
- Cron or scheduled jobs
- Public functions called by other systems

Present the list to the user and confirm it is complete before proceeding. Flag any entry points that look unused or deprecated.

### Delegate

Spawn a subagent per entry point if the environment supports it, running all traces in parallel. If subagents are not available, process entry points sequentially — announce which one is being traced before starting each.

Each subagent or sequential pass runs the full single-entry-point trace (Phases 1–5 below) and writes its output to `simulate-<system>/<entry-point>.md`.

### Index

After all traces are complete, write `simulate-<system>/index.md`:

```
# Simulate: <system>

## Entry points
<list of entry points with link to their file and a one-line summary>

## Shared side effects
<side effects that appear across multiple entry points — shared tables, shared services, shared queues>

## Concurrency notes
<interactions between entry points — shared locks, race conditions that span calls>

## Open questions
<ambiguities that cut across the system, not specific to one entry point>
```

---

## Single entry point path (Phases 1–5)

### Phase 1 — Locate

Find the target in the codebase. Identify:
- The exact file and line where it is defined
- Its signature: parameters, types, return type
- What triggers it: HTTP route, event, cron, direct call, message queue, etc.

### Phase 2 — Trace upward (callers)

Walk every caller of the target:
- What code paths invoke it, and under what conditions?
- What inputs are passed at each call site?
- Is it called concurrently from multiple places?

If the target is an HTTP handler, identify the route, middleware chain, and authentication/authorisation gates that precede it.

### Phase 3 — Trace downward (execution branches)

Walk every branch inside the target exhaustively. For each branch:
- What condition triggers it?
- What does it do — compute, delegate, mutate, return, throw?
- Follow every nested call recursively until you reach a leaf (I/O, return, throw, or external boundary)

Do not stop at the first level. Chase each call into its implementation.

### Phase 4 — Map side effects

For every branch, record:

**Data mutations** — what is written, updated, or deleted, in which database/table/collection/key, and under what condition.

**External calls** — services, APIs, queues, caches touched. For each: what is sent, what is expected back, what happens if it fails.

**Events emitted** — messages published, webhooks fired, jobs enqueued.

**Concurrency risks** — any shared state that could be raced, locks acquired, transactions opened and their isolation level.

### Phase 5 — Map return values and errors

For every branch that returns or throws:
- What is the return value or error type?
- What does the caller receive?
- Are there error paths that are silently swallowed or only partially handled?

### Output

Write `simulate-<target>.md` (single file) or `simulate-<system>/<target>.md` (when part of a system trace).

```
# Simulate: <target>

## Entry point
<file, line, signature, trigger>

## Callers
<each caller, conditions, inputs passed>

## Execution branches
<branch 1>
  Condition: ...
  Path: ...
  Side effects: ...
  Returns: ...

<branch 2>
  ...

## Side effects summary
<consolidated list of all mutations, external calls, events>

## Return values and errors
<consolidated list>

## Concurrency notes
<any races, locks, transaction boundaries>

## Open questions
<anything the code leaves ambiguous — missing error handling, undocumented assumptions, surprising behaviour>
```

If a single branch is too large to fit alongside others, split it into its own file and reference it from the main file.
