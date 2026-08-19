---
name: facilitated-waterfall-conventions
description: Shared conventions for the facilitated-waterfall system — the drilling technique, the append-only rule, the waterline that divides commitment from mechanism, artifact formats, frontmatter and numbering rules, and the read-only audit/compliance checks. Loaded by top-down and bottom-up; also invoke directly to audit an implementation against the boundaries its governing documents set.
---

Shared reference for the facilitated-waterfall system. `top-down` and `bottom-up` load this file for their rules; you can also invoke it directly to **audit** an implementation against its governing documents (see *Compliance & audit* below).

The system is an append-only, in-repo documentation pipeline. Work flows two ways and meets at the **waterline**:

```
Direction → Epic? → Task → ADR        (top-down: intent descends to the line)
                      ⭡      │
                      │      ▼
                    Plan → Code        (bottom-up: fixes ascend to the line)
```

- **Direction → Epic → Task** — top-down authors these (see `top-down`).
- **Plan + Code** — bottom-up authors these (see `bottom-up`).
- **ADR** — the shared ledger at the waterline. Top-down writes it looking forward; bottom-up supersedes it on contact with code. Both write it.
- **Probe** — bottom-up working memory (`docs/probes/`); the only mutable artifact.
- **Epic is optional** — use it only when one Direction spawns several ordered or dependent Tasks that need a manifest. Small work goes Direction → Tasks directly.

## The waterline

Every change sits somewhere on a ladder of abstraction. The **waterline** is the fixed altitude between *mechanism* (reversible, local — the engineer decides freely) and *commitment* (recorded, cross-cutting, expensive to reverse — needs an accepted trade-off to change).

```
ABOVE  ── Direction (intent)          commitment: append-only; change needs
       ── ADR (decision)              accepted trade-off, recorded as a
══════════ WATERLINE ══════════       superseding artifact
       ── architecture / pattern      the last rung settled by judgment
BELOW  ── module → class → placement  mechanism: reversible; decide freely
```

Two hard rules follow, one per direction:

- **Descent guard (top-down).** A descending change may **not** run straight into implementation. It stops at the underside of the line and hands off a *placed, bounded unit* (a Task, optionally grouped in an Epic).
- **Ascent guard (bottom-up).** An ascending change may **not** overturn an above-the-line commitment (ADR decision, Direction constraint/scope) without surfacing the trade-off and recording **accepted** supersession. If the trade-off isn't accepted, the fix is wrong — find a below-the-line mechanism that honors the decision.

## Drilling technique

Every authoring stage shares this. Ask one question at a time. Give your recommended answer before waiting for a response.

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen, don't batch.
- **Cross-reference with code** — when the user states how something works, check whether the code agrees. Surface contradictions; the disagreement is itself a finding.
- **Challenge against the glossary** — when a term conflicts with `CONTEXT.md`, call it out: "Your glossary defines X as Y, but you seem to mean Z — which is it?"

If a question can be answered by exploring the codebase, explore instead of asking.

## Append-only rule

Artifacts are not edited in place once they record a decision. A changed decision is captured by appending a **new** ADR whose `supersedes` field names the old one — the history of *why* stays intact. The sole exception is the **Probe** (`docs/probes/`), which is working memory: mutable while `open`, frozen when `reconciled`. Everything a probe *produces* (ADRs, Tasks, CONTEXT entries) is append-only.

## Artifact formats

Every file carries frontmatter with at least `id`, `title`, `created`, and `relates: [...]`. `relates` links point **upward** (Epic→Direction, Task→Epic/Direction, Plan→Task, ADR→artifact) and are fixed at creation.

```
docs/directions/NNN-slug.md   Problem · Appetite · Out of scope · Success signal · Constraints · Risk?
docs/epics/NNN-slug.md        Goal · Scope · Out of scope · Tasks · Sequencing · Done when   (optional tier)
docs/tasks/NNN-slug.md        Goal · Notes
docs/plans/NNN-slug.md        Context · Steps · Verification · Risk
docs/adr/NNNN-slug.md         Context · Decision · Consequences · Alternatives   (optional supersedes)
docs/probes/<id>-slug.md      Trigger · Governing docs · Findings · Open questions · Deliberation · Risk · Reconciliation
CONTEXT.md                    Glossary of resolved domain terms — no implementation detail
```

- **Epic (optional).** The **Tasks** section is a manifest table of children with a `Depends on` column; **Sequencing** is the derived order (or "parallel"). Dependency edges live **only here** — do not duplicate `Depends on / Blocks / Order:` onto individual Tasks.
- **Risk** (one line each: blast radius · rollback · cost-of-wrong) is required on Plans, optional on Directions.

## Numbering

- **Directions, Epics, Tasks, ADRs, Plans** — numbered sequentially from the highest existing file in their directory. Allocate a whole breakdown batch atomically in one pass to avoid collisions when siblings are worked in parallel.
- **Probes** — created ad hoc and in parallel, so they use **collision-free** ids: `probe-YYYY-MM-DD-slug`. A sequential `NNN` is assigned only at reconcile, single-threaded, when a durable artifact is minted.

## Status & ledger

- `status:` frontmatter is a documented enum: `todo` · `in-progress` · `implemented` · `done` (probes: `open` · `reconciled` · `abandoned`).
- Each tier may keep a `LEDGER.md` recording completions (`<id> — implemented DATE — verification: N/N passed`). Append on close.

## Compliance & audit

Read-only. Invoke directly to check whether what was built stayed inside what was decided. Writes nothing — reports drift.

**Collect the boundaries.** From the target artifact, walk `relates` upward to its governing docs and sideways to every ADR. Extract only constraints: ADR Decisions (non-negotiable), Plan Steps + Verification, Task/Epic Scope + **Out of scope**, Direction Constraints + Appetite + Out of scope.

**Check each against reality.** For every boundary, judge the code: **Conforms** / **Drifts** (diverges from a Plan step without a documented reason) / **Violates** (does what an ADR forbids or an Out-of-scope line excludes) / **Unverified** (a Verification check that doesn't pass) / **Not implemented**. State evidence for every verdict — file+line, command output, or commit. Run cheap Verification commands where a Plan lists them.

**Waterline & probe checks (system-specific):**
- **Waterline crossed without acceptance** — a probe (or commit) that overturns an ADR/Direction commitment with no recorded accepted trade-off. This is a violation.
- **Stale glossary** — a `CONTEXT.md` term whose definition no longer matches the code it pins to (e.g. a named field/module that moved or changed shape).
- **Open-probe drift** — a probe left `open` well past activity, or closed without its Reconciliation gate satisfied (see `bottom-up`).

**Report**, violations first, grouped by severity:

```
docs/adr/0004-no-sync-io.md    VIOLATED    src/cache.ts:88 blocking read in request path
docs/probes/2026-08-17-x.md    VIOLATED    supersedes adr/0008 with no accepted trade-off
CONTEXT.md → "usage"           STALE       pins app/lib/llm/usage.ts; file is now canonical-usage.ts
docs/plans/0005-auth.md        UNVERIFIED  `npm run e2e:auth` fails (2 specs)
docs/directions/001.md         CONFORMS    no scope-creep against Out of scope
```

Recommend, do not apply. **Code wrong** → fix code to honor the boundary. **Boundary wrong/outdated** → append a superseding ADR; never edit the original. When code and docs disagree, that disagreement *is* the finding — don't silently pick a side.
