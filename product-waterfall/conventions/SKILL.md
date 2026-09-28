---
name: product-waterfall-conventions
description: Shared conventions for the product-waterfall system — the product waterline that divides product commitment from execution mechanism, how it stacks on top of the facilitated-waterfall engineering waterline, the hooks between the two, the append-only rule, docs/PRODUCT.md ownership, artifact formats, the drilling technique, and signal classification. Loaded by direct and reflect; also invoke directly to audit whether product artifacts are still aligned with docs/PRODUCT.md.
---

Shared reference for the product-waterfall system. `direct` and `reflect` load this file for their rules; you can also invoke it directly to **audit** product alignment (see *Audit* below).

The system is a two-direction, in-repo, platform-agnostic documentation pipeline for product management. The files in `docs/` are the source of truth — no tracker, no external service. Work flows two ways and meets at the **product waterline**:

```
docs/PRODUCT.md ← Direction ← Epic? ← Story      (direct: intent descends to the line)
       ⭡                                  │
       │                                  ▼
  Probe → Decision               facilitated-waterfall top-down   (the seam)
```

- **direct → Direction → Epic? → Story** — top-down product authoring (see `direct`).
- **reflect → Probe → docs/PRODUCT.md** — signals carried upward (see `reflect`).
- **docs/PRODUCT.md** — the shared ledger at the product waterline. `reflect bootstrap` builds it; `reflect` is the only path to appending resolved decisions and product-level out of scope. `direct` reads it but may not write above the line.
- **Direction** — the product commitment artifact (what other tools call an Initiative). Must exist before any Epic or Story.
- **Epic is optional** — use it only when a Direction spawns several related Stories that need a manifest. Small work goes Direction → Stories directly.
- **Probe** — reflect's working memory; the only mutable artifact.

## The two waterlines

product-waterfall sits **on top of** facilitated-waterfall (FW). Each system has its own waterline; they stack, and the **Story** is the seam between them.

```
ABOVE PRODUCT LINE   ── Product identity                docs/PRODUCT.md — append-only;
                     ── Resolved decisions (D-NNN)      change only through reflect
                     ── Product-level out of scope (X-NNN)
═══════════════════ PRODUCT WATERLINE ═══════════════════
                     ── Strategic themes                docs/product/ — the PM reshapes
                     ── Direction → Epic? → Story       these through direct
  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ seam: Story ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
ABOVE ENG LINE       ── FW Direction · ADR              docs/directions, docs/adr
═══════════════════ ENGINEERING WATERLINE ═══════════════
BELOW                ── architecture → module → class   code — the engineer decides freely
```

A Story is **mechanism to the PM** (reshape it freely through `direct`) and **commitment to engineering** (FW may not change its outcome, acceptance criteria, or out of scope on its own). That is what makes it the hand-off unit.

Two hard rules follow, one per direction:

- **Descent guard (direct).** A descending change stops at a placed, bounded **Story** — never an FW Direction, Task, Plan, or code. Hand off to FW `top-down`.
- **Ascent guard (reflect).** An ascending signal may not silently overturn an above-the-line commitment (a resolved decision, a product-level out-of-scope entry) without surfacing the trade-off and recording explicit supersession in docs/PRODUCT.md. If the PM does not accept the trade-off, treat the signal as noise: monitor it and don't act on it.

## Hooks across the four skills

```
direct ──Story──▶ top-down ──Task──▶ bottom-up
  ▲                  │                  │
  │     conflicts with PRODUCT.md       │ Story can't be met / product commitment wrong
  │                  ▼                  ▼
  └──Affected────  reflect  ◀──────────┘ (or direct Refine, if only the Story moves)
```

| From → To | Trigger | What happens |
|-----------|---------|--------------|
| `direct` → `top-down` | A Story is written and placed | `direct` stops and offers the hand-off. `top-down` takes the Story as its entry and writes an FW Direction or Tasks whose `relates` include the Story's id. |
| `top-down` → `reflect` | Shaping an FW Direction contradicts a resolved decision or product-level out of scope | Hard stop. Load `reflect` with the conflict as the signal. |
| `bottom-up` → `direct` | The climb reaches a Story whose outcome, acceptance, or scope can't hold on contact with code, and no PRODUCT.md entry is touched | Load `direct` Refine for that Story. The PM decides; the Story gets a Revision entry. |
| `bottom-up` → `reflect` | The climb reaches docs/PRODUCT.md: a resolved decision or product-level exclusion is the obstacle | Load `reflect` with the engineering finding as the signal. An ADR can never supersede a product commitment. |
| `reflect` → `direct` / FW | A decision is superseded or a new one added | `reflect` greps `docs/` for the decision id and lists every **Affected** artifact in both layers, then recommends `direct` Refine for product artifacts and `bottom-up` for FW artifacts. It does not edit them. |

**Subroutine mode.** When one skill loads another, the caller names the entry (tier, artifact, or signal) and hands over the context it already gathered. The loaded skill does not re-scan. It runs only the phase requested, writes its artifacts, and returns the outcome so the caller can resume. Loading a product skill **always** involves the PM: product intent is never resolved autonomously.

## docs/PRODUCT.md — canonical structure

```
# Product Identity
One paragraph: who this product is for, the job it is hired to do, what makes it distinct.
Update rule: only when the product's fundamental purpose changes. Rare.

# Resolved Decisions
Append-only table of settled product decisions.
| Id | Decision | Rationale | Supersedes | Since |
Ids are D-001, D-002, … assigned sequentially. Never edit or renumber a row.
To reverse: add a new row whose Supersedes names the old id.

# Product-level Out of Scope
Append-only list of permanent exclusions.
- X-NNN — [Exclusion] — [Rationale]
To narrow: add a scoped entry alongside the existing one; never delete.

# Current Strategic Themes
Replaced each planning cycle.
| Theme | Direction | Status |
Update rule: direct appends on Direction creation. reflect may replace at cycle boundary.

# Domain Glossary
Product terms only — naming and boundaries, no implementation detail.
| Term | Meaning |
Update rule: any mode may append when a term resolves. Never redefine inline.
```

Other artifacts reference PRODUCT.md entries by anchor: `docs/PRODUCT.md#D-003`, `docs/PRODUCT.md#X-002`. That's how `reflect` finds what a supersession affects.

### Write rules by section

| Section | Who writes | How |
|---------|-----------|-----|
| Product identity | reflect bootstrap | Full rewrite only at product pivot |
| Resolved decisions | reflect only | Append; never edit existing rows |
| Product-level out of scope | reflect only | Append; never delete |
| Current strategic themes | direct (on create), reflect (on cycle shift) | direct appends; reflect may replace at cycle boundary |
| Domain glossary | any mode | Append only |

## Two glossaries

- **docs/PRODUCT.md → Domain Glossary** holds **product** terms: what users, the PM, and the business call things.
- **docs/CONTEXT.md** (FW) holds **engineering** terms: what the system calls things.

A term lives in exactly one. Before appending, check the other file. If the term is already there, reference it and don't redefine it. When an engineering term realises a product term (e.g. `Workspace` → `tenant`), the CONTEXT.md entry names the product term it implements. It does not restate the product term's meaning.

## Artifact formats

Every file carries frontmatter with at least `id` (the repo-relative path), `title`, `created`, and `relates: [...]`. `relates` points **upward** and is fixed at creation. An optional `tracker:` key may hold an external ticket key or URL if the team mirrors work elsewhere. Skills never read from or write to that tracker.

```
docs/PRODUCT.md                               Identity · Decisions · Out of scope · Themes · Glossary
docs/product/directions/NNN-slug.md           Problem · Appetite · Out of scope · Success signal · Constraints
docs/product/epics/NNN-slug.md                Capability · Scope · Out of scope · Success signal · Stories · Sequencing   (optional tier)
docs/product/stories/NNN-slug.md              Outcome · Acceptance criteria · Out of scope · Revisions?
docs/product/probes/probe-YYYY-MM-DD-slug.md  Signal · Classification · Governing decisions · Deliberation · Outcome · Affected · Changes
docs/product/probes/LEDGER.md                 Append-only record of resolved probes
```

- **Direction** `relates` lists the PRODUCT.md entries that constrain it (`docs/PRODUCT.md#D-003`). Epic → Direction; Story → Epic or Direction.
- **Epic (optional).** **Stories** is a manifest table of children with a `Depends on` column; **Sequencing** is the derived order (or "parallel"). Dependency edges live **only here**.
- **Story** has a single, testable user outcome. If the outcome contains "and", it's two Stories. Infrastructure, migration, and plumbing are **not** Stories. They belong to FW Tasks under the Story they serve.

## Numbering

Directions, Epics, and Stories are numbered sequentially from the highest existing file in their own directory. Allocate a whole breakdown batch atomically in one pass. Probes use collision-free dated ids (`probe-YYYY-MM-DD-slug`). Decision and exclusion ids (`D-NNN`, `X-NNN`) continue from the highest in docs/PRODUCT.md.

## Drilling technique

Every authoring stage uses this. Ask one question at a time. Give your recommended answer before waiting for a response.

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately. Cross-reference both glossaries.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen; don't batch.
- **Challenge against PRODUCT.md** — when a term or assumption conflicts with a resolved decision, call it out: "docs/PRODUCT.md has D-003 [X] as settled, but you seem to be assuming [Y]. Which takes precedence?"

## Signal classification

| Type | Examples | Outcome |
|------|----------|---------|
| Confirming | Data validating an existing decision | Record as supporting evidence; no PRODUCT.md change |
| Contradicting | Data challenging an existing decision | Deliberate at the waterline; may supersede |
| Gap | Area not covered by any resolved decision | May add a new resolved decision |
| Noise | One-off anecdote that does not generalise | Record in probe; no PRODUCT.md change |
| Scope creep | Request crossing product-level out of scope | Affirm the boundary; record why it was challenged |

Engineering findings handed over by `bottom-up` or `top-down` are signals like any other. Classify them explicitly before deliberating, and never skip straight to the decision.

## Append-only rule

- **docs/PRODUCT.md** decisions and exclusions, and **Directions**, are append-only. A changed decision is a new row whose `Supersedes` names the old id.
- **Epics and Stories** sit below the product line, so `direct` Refine may edit them in place **until something relates to them**. Once an FW artifact (or a child Story) cites one, record changes as dated entries under a **Revisions** section instead. Engineering then sees what moved and why.
- **Probes** are working memory: mutable while `open`, frozen when `resolved` or `abandoned`.

## Confirm-before-write rule

Every write operation follows this pattern:

1. Gather data (read files).
2. Draft the action (show exactly what will be created or modified).
3. Ask: "Confirm? [yes / edit / cancel]"
4. Execute **only** on explicit yes.

Never silently create, modify, or link anything.

## Audit

Read-only. Writes nothing; reports drift. Build the graph from frontmatter only (`grep -rH "^id:\|^relates:" docs/product/ docs/directions/ docs/tasks/`), then check:

- **Superseded governance.** A Direction, Epic, or Story whose `relates` cites a D-/X-id that a newer row supersedes, with no Revision acknowledging it.
- **Contradiction.** A Direction or Story whose Out of scope or Outcome contradicts a current resolved decision or product-level exclusion.
- **Stale theme.** A Current Strategic Themes row pointing at a Direction whose Stories are all delivered, or at a missing Direction.
- **Orphan Story.** A Story no FW Direction or Task relates to. This is not drift; it's the hand-off frontier. Report it separately.
- **Engineering over the line.** An FW ADR or Direction that changes a Story's outcome or acceptance, or contradicts docs/PRODUCT.md, without a matching Revision or reflect probe.
- **Open-probe drift.** A probe left `open` well past activity, or resolved without its Reconcile gate satisfied.
- **Glossary collision.** A term defined in both docs/PRODUCT.md and docs/CONTEXT.md.

Report violations first, one line each (`artifact  VERDICT  evidence`). Recommend fixes; don't apply them. A wrong product boundary is fixed through `reflect`, never by editing it in place.
