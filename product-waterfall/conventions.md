---
name: product-waterfall-conventions
description: Shared conventions for the product-waterfall system — the waterline that divides product commitment from execution mechanism, the append-only rule, PRODUCT.md ownership, artifact formats, the drilling technique, the probe pattern, and signal classification. Loaded by direct and reflect; also invoke directly to audit whether active Initiatives are still aligned with PRODUCT.md.
---

Shared reference for the product-waterfall system. `direct` and `reflect` load this file for their rules.

The system is a two-direction, in-repo documentation pipeline for product management. Work flows two ways and meets at the **waterline**:

```
PRODUCT.md ← Direction doc ← Initiative     (direct: intent descends to the line)
                  ⭡               │
                  │               ▼
             Probe → Decision     Epic / Story / Task    (reflect: signals ascend to the line)
```

- **direct → Direction doc → Initiative** — top-down authors these (see `direct`).
- **reflect → Probe → PRODUCT.md** — bottom-up processes these (see `reflect`).
- **PRODUCT.md** — the shared ledger at the waterline. `reflect bootstrap` builds it; `reflect signal` is the only path to appending resolved decisions. `direct` reads it but may not write above the line.
- **Direction doc** — the commitment artifact that must exist before a tracker Initiative is created. Lives in `docs/product/directions/`.
- **Probe** — bottom-up working memory (`docs/product/probes/`); the only mutable artifact.

## The waterline

Every product decision sits on a ladder of abstraction. The **waterline** is the fixed altitude between *mechanism* (replaceable, sprint-level — the team executes freely) and *commitment* (recorded, cross-cutting, expensive to reverse — needs a deliberate PM decision to change).

```
ABOVE  ── Product identity              commitment: append-only; change needs
       ── Resolved decisions            explicit PM decision with rationale,
       ── Product-level out of scope    recorded as a superseding entry
══════════════ WATERLINE ══════════════
       ── Current strategic themes      below the line but structured —
BELOW  ── Direction docs                replaced each cycle
       ── Initiatives / Epics           mechanism: tracker-level execution
       ── Stories / Tasks
```

Two hard rules follow, one per direction:

- **Descent guard (direct).** A descending change may not run straight into a tracker ticket. It stops at the underside of the line and produces a Direction doc — a placed, bounded statement of problem, appetite, and out of scope — before anything is created in the tracker.
- **Ascent guard (reflect).** An ascending signal may not silently overturn an above-the-line commitment (a resolved decision, product-level out of scope) without surfacing the trade-off and recording explicit supersession in PRODUCT.md. If the trade-off is not accepted, the signal is noise — monitor it, do not act on it.

## PRODUCT.md — canonical structure

PRODUCT.md lives at the workspace root. It is the persistent product reality — the PM equivalent of `CONTEXT.md` in facilitated-waterfall.

```
# Product Identity
One paragraph: who this product is for, the job it is hired to do, what makes it distinct.
Update rule: only when the product's fundamental purpose changes. Rare.

# Resolved Decisions
Append-only table of settled product decisions.
| Decision | Rationale | Supersedes | Since |
Update rule: reflect signal only. Append new rows. Never edit existing.
To reverse: add a new row with Supersedes pointing to the old one.

# Product-level Out of Scope
Append-only list of permanent exclusions.
Update rule: reflect signal only. Append new entries. Never delete.
To narrow: add a scoped entry alongside the existing one.

# Current Strategic Themes
Replaced each planning cycle.
| Theme | Direction doc | Tracker key | Status |
Update rule: direct appends on Direction/Initiative creation. reflect may replace at cycle boundary.

# Domain Glossary
Canonical product terms — naming and boundaries only, no implementation detail.
| Term | Meaning |
Update rule: any mode may append when a term resolves. Never redefine inline.
```

### Write rules by section

| Section | Who writes | How |
|---------|-----------|-----|
| Product identity | reflect bootstrap | Full rewrite only at product pivot |
| Resolved decisions | reflect signal only | Append; never edit existing rows |
| Product-level out of scope | reflect signal only | Append; never delete |
| Current strategic themes | direct (on create), reflect (on cycle shift) | direct appends; reflect may replace at cycle boundary |
| Domain glossary | any mode | Append only |

## Artifact formats

Every file carries frontmatter with at least `id`, `title`, and `created`. Direction docs and probes also carry `relates: [...]` pointing upward.

```
PRODUCT.md                                 Identity · Decisions · Out of scope · Themes · Glossary
docs/product/directions/NNN-slug.md        Problem · Appetite · Out of scope · Success signal · Constraints
docs/product/probes/probe-YYYY-MM-DD.md    Signal · Classification · Governing decisions · Deliberation · Outcome · Changes
```

Direction docs are numbered sequentially from the highest existing file in `docs/product/directions/`. Probes use collision-free dated ids.

## Drilling technique

Every authoring stage uses this. Ask one question at a time. Give your recommended answer before waiting for a response.

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately. Cross-reference with the PRODUCT.md Domain Glossary.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen; don't batch.
- **Challenge against PRODUCT.md** — when a term or assumption conflicts with a resolved decision, call it out: "PRODUCT.md has [X] as a settled decision, but you seem to be assuming [Y] — which takes precedence?"

## Signal classification

| Type | Examples | Outcome |
|------|----------|---------|
| Confirming | Data validating an existing decision | Record as supporting evidence; no PRODUCT.md change |
| Contradicting | Data challenging an existing decision | Deliberate at the waterline; may supersede |
| Gap | Area not covered by any resolved decision | May add a new resolved decision |
| Noise | One-off anecdote that does not generalise | Record in probe; no PRODUCT.md change |
| Scope creep | Request crossing product-level out of scope | Affirm the boundary; record why it was challenged |

Classify explicitly before deliberating. Never skip to the decision.

## Append-only rule

Artifacts are not edited in place once they record a decision. A changed decision is captured by appending a new entry whose `Supersedes` field names the old one — the history of *why* stays intact. The sole exception is the **Probe**, which is working memory: mutable while `open`, frozen when `resolved`. Everything a probe *produces* (PRODUCT.md entries, Direction docs) is append-only.

## Confirm-before-write rule

Every write operation follows this pattern:

1. Gather data (read files, fetch tracker tickets)
2. Draft the action (show exactly what will be created or modified)
3. Ask: "Confirm? [yes / edit / cancel]"
4. Execute **only** on explicit yes

Never silently create, modify, or link anything.
