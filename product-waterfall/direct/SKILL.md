---
name: product-waterfall-direct
description: Descends from product intent to the product waterline — shapes a Direction checked against docs/PRODUCT.md, breaks it into Epics and Stories under docs/product/, and stops at a placed, bounded Story ready to hand to facilitated-waterfall top-down. Also refines an existing Epic or Story, including when bottom-up finds a Story that can't hold on contact with code. The PM equivalent of facilitated-waterfall top-down.
---

Descend from intent toward the product waterline. Produce a committed Direction and the Epics/Stories beneath it, and **stop at a placed, bounded Story**. Do not cross into engineering: FW Directions, Tasks, ADRs, Plans, and code belong to `top-down` and `bottom-up`. Read `conventions` for the waterlines, the hooks, docs/PRODUCT.md structure, drilling technique, append-only rule, and confirm-before-write rule.

**Find the entry.** Interpret the argument to locate the starting point and tier:

- A raw idea, goal, or problem statement → **Shape** (Direction)
- An existing Direction → **Breakdown** (Direction → Epics or Stories)
- An existing Epic → **Breakdown** (Epic → Stories)
- An existing Epic or Story needing enrichment or change → **Refine**
- Loaded by `bottom-up` with a Story and an engineering finding → **Refine** in subroutine mode (see `conventions` → Hooks)
- Ambiguous → ask: "Are you shaping a new Direction, breaking work down, or refining an existing Epic or Story?"

---

## Phase 1 — Shape (Direction)

### 1a — Read docs/PRODUCT.md

Read `docs/PRODUCT.md` before anything else. Extract resolved decisions (hard constraints), product-level out of scope (hard constraints), current strategic themes (fit check), and the domain glossary (canonicalisation). If it doesn't exist, proceed with explicit flags and recommend running `reflect bootstrap` first.

### 1b — Dedup check

Check whether an existing Direction overlaps:

```sh
grep -rH "^title:" docs/product/directions/ 2>/dev/null
```

Read only the bodies of plausible matches. If a close match exists, ask: "This looks similar to [id]: [title]. Same Direction or distinct?" Same → go to Breakdown or Refine on it. Distinct → note it for `relates`, proceed.

### 1c — Alignment check

Before drilling, present the alignment picture:

> "Before we shape this, here's how it sits against your current product direction:
> Active themes: [from docs/PRODUCT.md]
> Relevant resolved decisions: [D-ids that touch the stated problem]
> Potential scope conflicts: [X-ids the problem might touch]
> Does this complement an active theme, or is it a new one?"

If it conflicts with a resolved decision or product-level out of scope: **hard stop**.

> "This conflicts with a settled product decision: [D-NNN / X-NNN]. To proceed, use `reflect` to process the signal driving this and decide whether the decision should be superseded. I won't write a Direction that contradicts settled product direction."

### 1d — Drill the Direction

Interview the PM through each section using the drilling technique from `conventions`. One question at a time; give your recommended answer; push back.

**Problem** — "What is broken or missing, stated plainly?" Drill until specific and observable.

**Appetite** — "How much complexity and effort is this worth? A budget, not an estimate." Probe: "1-week spike, quarter-long, or somewhere between?"

**Out of Scope** — "What would a naive PM or engineer build that you don't want?" Require at least two explicit exclusions; don't accept "nothing is out of scope". Cross-reference product-level out of scope.

**Success Signal** — "How will you know it worked? Observable outcome, not aspiration." Reject "users are happier." Accept "time-to-first-payment drops below 5 minutes."

**Constraints** — "What cannot change regardless of how this is solved?" (regulatory, contracts, timeline, team size). Cite the D-/X-ids that bind it.

### 1e — Write the Direction

Number sequentially from the highest file in `docs/product/directions/`. Write `docs/product/directions/NNN-slug.md`:

**Frontmatter:** `id`, `title`, `created`, `relates: [docs/PRODUCT.md#D-NNN, …]` (the entries that constrain it, plus any related Direction from 1b). Optional `tracker:`.

**Body:** Problem · Appetite · Out of Scope · Success Signal · Constraints

Present the full draft and confirm before writing. The Direction is a commitment artifact, so it's append-only once written.

If a product term resolved during drilling: "Shall I add '[term]' to the docs/PRODUCT.md glossary? [yes / skip]" First check that docs/CONTEXT.md doesn't already define it.

Offer to log it under Current Strategic Themes: "Shall I add this Direction to Current Strategic Themes in docs/PRODUCT.md? [yes / skip]"

Then: "Direction written. Run `direct` on it when you're ready to break it down, or stop here." Do not auto-chain.

---

## Phase 2 — Breakdown (Direction → Epics? → Stories)

### 2a — Read the governing context

Read the parent (Direction or Epic) fully; it's the scope authority for the session. Walk its `relates` up to the Direction and to the docs/PRODUCT.md entries it cites. Resolved decisions and product-level out of scope constrain every unit proposed.

### 2b — Check for existing children

```sh
grep -rlH "<parent id>" docs/product/epics/ docs/product/stories/ 2>/dev/null
```

If children exist, present them and ask: "Adding more, or done?"

### 2c — Decide the tier and propose the shape

Recommend a tier:

- **Direction → Stories directly** when the Direction is focused.
- **Direction → Epics → Stories** only when the work spans several capabilities that each need a manifest.

Propose the whole shape as one-line descriptions: 2–5 Epics, or 3–7 Stories. A Story is something a user can see, do, or benefit from. Plumbing, migrations, and infrastructure are **not** Stories; note them as engineering concerns for the Story they serve, and `top-down` will make them Tasks. Confirm the shape before drilling units.

### 2d — Drill each unit (one at a time)

**Epic:** Capability (noun phrase: what exists when done) · Scope · Out of Scope (at least two) · Success Signal · Stories manifest with `Depends on`

**Story:** Outcome (single testable user outcome; if it contains "and", split it) · Acceptance Criteria (observable, demonstrable by a user or a check) · Out of Scope

Challenge each against the parent's Out of Scope and against docs/PRODUCT.md.

### 2e — Draft, confirm, write

Allocate the whole batch of numbers atomically. For each unit, present the full draft: "Confirm this one? [yes / edit / skip / cancel all]". On yes, write:

- Epic → `docs/product/epics/NNN-slug.md`, `relates: [<direction id>]`
- Story → `docs/product/stories/NNN-slug.md`, `relates: [<epic id or direction id>]`

If the PM gets impatient, offer: "Want me to draft the remaining N units as a batch for review?" Confirm the batch, then write sequentially.

Dependency edges between Stories go **only** in the Epic's Stories manifest and Sequencing. Never put them on the Stories themselves.

### 2f — Hand off at the seam

Stop. Stories are the descent guard's floor. Offer:

> "N Stories written. Each is ready for engineering: run `top-down` on a Story to shape its FW Direction or Tasks. Want to start with [first in Sequencing]?"

Do not start `top-down` without a yes.

---

## Phase 3 — Refine (enrich or change an Epic or Story)

### 3a — Identify and situate

Read the Epic or Story. Walk `relates` up to its Direction and cited docs/PRODUCT.md entries. Check whether its Direction's theme is still active. Then check whether anything already builds on it:

```sh
grep -rlH "<story or epic id>" docs/ 2>/dev/null
```

If any FW Direction, Task, or child Story relates to it, it's **picked up**. Changes must be recorded as Revisions (see `conventions` → Append-only).

### 3b — Assess gaps

Compare against the format in `conventions`. Classify each section as Missing, Weak, or Complete, and present the result as a table. When loaded by `bottom-up`, also present the engineering finding: which acceptance criterion or scope line can't hold, and why.

If the needed change would contradict a resolved decision or product-level exclusion, stop. It isn't a Refine. Redirect to `reflect`.

### 3c — Drill and fill

Use the drilling technique for each weak or missing section, or for the contested one. Acceptance Criteria must be observable. Epic Out of Scope needs at least two exclusions. Never invent engineering detail; that's `top-down`'s job.

### 3d — Draft and apply

Show Added, Changed, Unchanged, then the full result. Confirm before writing.

- **Not picked up** → edit in place.
- **Picked up** → leave the original sections intact and append under `## Revisions`: `- YYYY-MM-DD — [what changed] — [why; cite the probe or finding]`. Then list the FW artifacts that relate to it and recommend `bottom-up` on each one the change affects.

In subroutine mode, return the outcome to `bottom-up`: the Revision text, or "Story holds; find a mechanism that meets it."

---

## Rules

- Read docs/PRODUCT.md before authoring anything. No exceptions.
- Hard-stop if a Direction, Epic, or Story would contradict a resolved decision or product-level exclusion. Redirect to `reflect`.
- Direction first. Never write an Epic or Story without a Direction above it.
- Stop at the Story. Never write FW Directions, Tasks, ADRs, Plans, or code; hand off to `top-down`.
- Never call an external tracker. `tracker:` is an optional link only.
- Do not auto-chain between phases or into `top-down`. Each is a deliberate invocation.
- Confirm before every write: Direction, Epic, Story, Revision, docs/PRODUCT.md entry.
