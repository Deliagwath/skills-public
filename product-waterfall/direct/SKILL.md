---
name: product-waterfall-direct
description: Descends from product intent to the product waterline — shapes a Direction checked against docs/PRODUCT.md, breaks it into Epics and Stories under docs/product/, and stops at a placed, bounded Story ready to hand to facilitated-waterfall top-down. Also refines an existing Epic or Story, including when bottom-up finds a Story that can't hold on contact with code. The PM equivalent of facilitated-waterfall top-down.
---

Descend from intent toward the product waterline. Produce a committed Direction and the Epics/Stories beneath it, and **stop at a placed, bounded Story**. FW Directions, Tasks, ADRs, Plans, and code belong to `top-down` and `bottom-up`. Read `conventions` for the waterlines, the hooks, docs/PRODUCT.md structure, drilling technique, append-only rule, confirm-before-write rule, cutover rules, external-dependency grounding, and the plain-language rule.

**Find the entry.** Interpret the argument to locate the starting point and tier:

- A raw idea, goal, or problem statement → **Shape** (Direction)
- An existing Direction → **Breakdown** (Direction → Epics or Stories)
- An existing Epic → **Breakdown** (Epic → Stories)
- An existing Epic or Story needing enrichment or change → **Refine**
- Loaded by `bottom-up` with a Story and an engineering finding → **Refine** in subroutine mode (see `conventions` → Hooks)
- Ambiguous → ask: "Are you shaping a new Direction, breaking work down, or refining an existing Epic or Story?"

**Inherit point: entry.** When the entry names an existing Direction, Epic or Story, run `sp tree <id>` for what is under it and `sp trace <id>` for its intent trace, and `sp --role top-down docs D-NNN` for each D-/X-id it cites: the row, what supersedes it, and the docs citing it. `sp` is at `~/.agent-skills/facilitated-waterfall/scripts/sp`, if installed; its rules are FW `conventions` → Handbook → Inherit. Read `docs/handbook/index.md` if it exists. State read depth before the interview: the `sp` budget line (or `sp absent`), then each doc as `FULL` / `PARTIAL` / `NOT_READ`. A raw idea makes no call, and the statement says so. Without `sp`, walk `relates` upward and `grep -rn "PRODUCT.md#D-NNN" docs/`.

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

If it conflicts with a resolved decision or product-level out of scope, stop:

> "This conflicts with a settled product decision: [D-NNN / X-NNN]. To proceed, use `reflect` to process the signal driving this and decide whether the decision should be superseded."

If the stated problem's solution space rests on an unresolved premise — a choice of external component, repo or service the work would depend on (which one, or adopt at all) — settle the premise here, before 1d: run `conventions` → Grounding external dependencies on the candidates, present the capability delta (what the project already provides, with the citations that prove it), and resolve it with the PM. The sections it determines are drilled after.

### 1d — Drill the Direction

Interview the PM through each section using the drilling technique from `conventions`. One question at a time; give your recommended answer; push back.

**Problem** — "What is broken or missing, stated plainly?" Drill until specific and observable.

**Appetite** — "How much complexity and effort is this worth? A budget, not an estimate." Probe: "1-week spike, quarter-long, or somewhere between?"

**Out of Scope** — "What would a naive PM or engineer build that you don't want?" Collect at least two explicit exclusions. Cross-reference product-level out of scope.

**Success Signal** — "How will you know it worked?" Drill to an observable outcome: "time-to-first-payment drops below 5 minutes" rather than "users are happier." A durability signal is shaped non-destructively, and a recovery signal is a demonstrated restore — see `conventions` → Cutover and data-carrying units. A signal that leans on a third-party mechanism is grounded before it is written — see `conventions` → Grounding external dependencies.

**Constraints** — "What cannot change regardless of how this is solved?" (regulatory, contracts, timeline, team size). Cite the D-/X-ids that bind it.

### 1e — Write the Direction

Make the file with `sp new product-direction "<title>" --relates docs/PRODUCT.md#D-NNN,… --intent "…"`: it takes the next number, writes `docs/product/directions/NNN-slug.md` (`id: product-direction-NNN`) with its frontmatter and section headings, and prints the path. Fill it, then run `sp check <id>`. Without `sp`, number from the highest file in `docs/product/directions/` and write it by hand:

**Frontmatter:** `id` (`product-direction-NNN`), `title`, `created`, `relates: [docs/PRODUCT.md#D-NNN, …]` (the entries that constrain it, plus any related Direction from 1b). Optional `tracker:`.

**Body:** Problem · Appetite · Out of Scope · Success Signal · Constraints

Present the full draft and confirm before writing. The Direction is a commitment artifact, so it's append-only once written.

If a product term resolved during drilling: "Shall I add '[term]' to the docs/PRODUCT.md glossary? [yes / skip]" First check that docs/CONTEXT.md doesn't already define it.

Offer to log it under Current Strategic Themes: "Shall I add this Direction to Current Strategic Themes in docs/PRODUCT.md? [yes / skip]"

Then: "Direction written. Run `direct` on it when you're ready to break it down, or stop here." Breakdown is a separate invocation.

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

Propose the whole shape as one-line descriptions: 2–5 Epics, or 3–7 Stories. A Story is something a user can see, do, or benefit from. Note plumbing and infrastructure as engineering concerns for the Story they serve; `top-down` makes them Tasks. A migration is a Story when it carries a user-visible outcome — the user's data arrives and the user is told what did not — and it obeys the cutover rules in `conventions` → Cutover and data-carrying units; its mechanics are Tasks under it. Confirm the shape before drilling units.

### 2d — Drill each unit (one at a time)

**Epic:** Capability (noun phrase: what exists when done) · Scope · Out of Scope (at least two) · Success Signal · Stories manifest with `Depends on`

**Story:** Outcome (single testable user outcome; if it contains "and", split it) · Acceptance Criteria (observable, demonstrable by a user or a check) · Out of Scope

Challenge each against the parent's Out of Scope and against docs/PRODUCT.md.

### 2e — Draft, confirm, write

For each unit, present the full draft: "Confirm this one? [yes / edit / skip / cancel all]". On yes, write it with `sp`, which numbers each one under a lock:

- Epic → `sp new product-epic "<title>" --relates <product-direction-id>` (`docs/product/epics/NNN-slug.md`)
- Story → `sp new story "<title>" --relates <product-epic-id or product-direction-id>` (`docs/product/stories/NNN-slug.md`)

Run `sp check <id>` on each, and `sp tree <product-direction-id>` to see the batch. Without `sp`, allocate the batch's numbers in one pass and write the frontmatter by hand.

If the PM gets impatient, offer: "Want me to draft the remaining N units as a batch for review?" Confirm the batch, then write sequentially.

Dependency edges between Stories live in the Epic's Stories manifest and Sequencing.

### 2f — Hand off at the seam

Stop. Stories are the descent guard's floor. Offer:

> "N Stories written. Each is ready for engineering: run `top-down` on a Story to shape its FW Direction or Tasks. Want to start with [first in Sequencing]?"

Start `top-down` on a yes.

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

When the needed change would contradict a resolved decision or product-level exclusion, it belongs to `reflect`: stop and redirect there.

### 3c — Drill and fill

Use the drilling technique for each weak or missing section, or for the contested one. Acceptance Criteria are observable. Epic Out of Scope carries at least two exclusions. Engineering detail is `top-down`'s.

### 3d — Draft and apply

Show Added, Changed, Unchanged, then the full result. Confirm before writing.

- **Not picked up** → edit in place.
- **Picked up** → leave the original sections intact and append under `## Revisions`: `- YYYY-MM-DD — [what changed] — [why; cite the probe or finding]`. Then list the FW artifacts that relate to it and recommend `bottom-up` on each one the change affects.

In subroutine mode, return the outcome to `bottom-up`: the Revision text, or "Story holds; find a mechanism that meets it."

---

## Rules

- Read docs/PRODUCT.md before authoring anything.
- When a Direction, Epic, or Story would contradict a resolved decision or product-level exclusion, stop and redirect to `reflect`.
- Direction first: every Epic and Story has a Direction above it.
- Stop at the Story and hand off to `top-down`.
- `tracker:` is an optional link; the skill works from `docs/` alone.
- `direct` authors intent and closes no probe, so it writes nothing to `docs/handbook/`; `reflect` and `bottom-up` deposit at their close.
- Each phase, and the hand-off into `top-down`, is a deliberate invocation.
- Confirm before every write: Direction, Epic, Story, Revision, docs/PRODUCT.md entry.
