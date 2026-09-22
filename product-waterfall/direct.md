---
name: product-waterfall-direct
description: Descends from product intent to the waterline — shapes a Direction doc checked against PRODUCT.md, then creates tracker artifacts (Initiative, Epic, Stories/Tasks). Stops at a placed, bounded unit rather than running into execution. The PM equivalent of facilitated-waterfall top-down.
---

Descend from intent toward the waterline. Produce a committed Direction doc and tracker artifacts, and **stop at a placed, bounded unit**. Do not cross into execution — sprint assignment and sub-tasks are downstream concerns. Read `conventions` for the waterline, PRODUCT.md structure, drilling technique, append-only rule, and confirm-before-write rule.

**Find the entry.** Interpret the argument to locate the starting point and tier:

- A raw idea, goal, or problem statement → start at **Shape** (Direction doc + Initiative)
- An existing Initiative needing decomposition → start at **Breakdown** (Initiative → Epics)
- An existing Epic needing decomposition → start at **Breakdown** (Epic → Stories/Tasks)
- An existing ticket needing enrichment → **Refine**
- Ambiguous → ask: "Are you shaping a new initiative, breaking work down, or refining an existing ticket?"

---

## Phase 1 — Shape (Direction doc + Initiative)

### 1a — Read PRODUCT.md

Read `PRODUCT.md` at the workspace root before anything else. Extract: resolved decisions (hard constraints), product-level out of scope (hard constraints), current strategic themes (fit check), domain glossary (canonicalisation). If PRODUCT.md does not exist, proceed with explicit flags and recommend running `reflect bootstrap` first.

### 1b — Dedup check

Search for existing tracker Initiatives that overlap (JQL + full-text search). If a close match exists: "This looks similar to [ticket]: [summary]. Same initiative or distinct?" Same → go to Refine. Distinct → note as `Relates` candidate, proceed.

### 1c — Alignment check

Before drilling, present the alignment picture:

> "Before we shape this, here's how it sits against your current product direction:
> Active themes: [from PRODUCT.md]
> Relevant resolved decisions: [any that touch the stated problem]
> Potential scope conflicts: [any product-level out of scope the problem might touch]
> Does this complement an active theme, or is it a new one?"

If it conflicts with a resolved decision or product-level out of scope: **hard stop**.

> "This conflicts with a settled product decision: [decision]. To proceed, use `reflect signal` to process the signal driving this and decide whether the decision should be superseded. Do not create a ticket that contradicts settled product direction."

### 1d — Drill the Direction

Interview the PM through each section using the drilling technique from `conventions`. One question at a time; give your recommended answer; push back.

**Problem** — "What is broken or missing, stated plainly?" Drill until specific and observable.

**Appetite** — "How much complexity and effort is this worth? A budget, not an estimate." Probe: "1-week spike, quarter-long, or somewhere between?"

**Out of Scope** — "What would a naive PM or engineer build that you don't want?" Require minimum two explicit exclusions. "Nothing is out of scope" is not accepted — probe until real exclusions emerge. Cross-reference with PRODUCT.md product-level out of scope.

**Success Signal** — "How will you know it worked? Observable outcome, not aspiration." Reject "users are happier." Accept "time-to-first-payment drops below 5 minutes."

**Constraints** — "What cannot change regardless of how this is solved?" (regulatory, API contracts, timeline, team size)

### 1e — Write the Direction doc

Number sequentially from the highest existing file in `docs/product/directions/`. Write `docs/product/directions/NNN-slug.md`:

**Frontmatter:** `id`, `title`, `created`, `ticket:` (blank until tracker key known), `relates: []`

**Body:** Problem · Appetite · Out of Scope · Success Signal · Constraints

Present the full draft. Confirm before writing. The Direction doc is the commitment artifact — it is append-only once written.

If a new product term resolved during drilling: "Shall I add '[term]' to the PRODUCT.md glossary? [yes / skip]"

### 1f — Create the tracker Initiative

Compose the Initiative from the Direction doc:

- **Summary:** concise problem-oriented title
- **Body:** Context (link to Direction doc) · Requirements (appetite + constraints) · Acceptance Criteria (success signal) · Out of Scope (minimum two) · Technical Notes (N/A) · Dependencies (Relates candidates from dedup)
- **Labels:** confirm with the PM — never silently infer at Initiative level

Present the full draft. Confirm before creating.

On confirm: create the Initiative in the tracker. Update the Direction doc's `ticket:` frontmatter with the created key.

Offer to add this Initiative to PRODUCT.md Current Strategic Themes: "Shall I log this under Current Strategic Themes in PRODUCT.md? [yes / skip]"

Then: "Direction doc written and Initiative created. Use `direct` with the Epic breakdown option when you're ready to define Epics — or stop here." Do not auto-chain.

---

## Phase 2 — Breakdown (Initiative → Epics, or Epic → Stories/Tasks)

### 2a — Identify parent and tier

Fetch the parent ticket. Validate the type — Initiative → Epics tier; Epic → Stories/Tasks tier. If the user provides a Story/Task, redirect: "Use a sub-task breakdown tool for that level."

### 2b — Read the governing Direction doc

Find the Direction doc whose `ticket:` frontmatter matches the Initiative key. Read it fully — this is the scope authority for the session. If none exists, warn and proceed with the ticket description as the scope reference.

Read PRODUCT.md resolved decisions and product-level out of scope. These constrain every unit proposed.

### 2c — Check for existing children

Fetch existing children. If present: present them and ask "Adding more, or done?"

### 2d — Propose the shape

Before drilling individual units, propose the full breakdown shape to the PM:

- Initiative → Epics: propose 2–5 Epics as one-line capability descriptions
- Epic → Stories/Tasks: propose 3–7 Stories/Tasks

Story vs. Task heuristic: user can see/do/benefit from it → Story; infrastructure/migration/plumbing → Task.

Confirm the shape before drilling units.

### 2e — Drill each unit (one at a time)

**For an Epic:** Capability (noun phrase — what exists when done) · Scope · Out of Scope (min two) · Success Signal · Dependencies on siblings

**For a Story:** User outcome (single testable outcome — if it has "and" it's two Stories) · Acceptance Criteria (observable, demonstrable) · Out of Scope

**For a Task:** Goal (what system state changes) · Acceptance Criteria (verifiable without user interaction) · Dependencies

### 2f — Draft and confirm each unit

After drilling: present the full ticket draft. "Confirm this one? [yes / edit / skip / cancel all]"

On confirm: create the ticket in the tracker with the parent link and inherited labels.

If the PM gets impatient: "Want me to draft the remaining N units as a batch for review?" Shift to batch-confirm but create sequentially after confirmation.

### 2g — Link dependencies

After all units are created, present identified dependency edges and offer to create Blocks links.

---

## Phase 3 — Refine (enrich an existing ticket)

### 3a — Identify the ticket

Parse the user input for a ticket key. Fetch it. Walk up the parent chain to find the governing Direction doc. Check the parent status — if Done/Closed/Cancelled, warn before proceeding. Check if the parent theme is still active in PRODUCT.md Current Strategic Themes.

### 3b — Assess gaps

Compare the ticket body against the standard format (Context · Requirements · Acceptance Criteria · Out of Scope · Technical Notes · Dependencies). Classify each section as Missing, Weak, or Complete. Present as a table. Ask to proceed.

### 3c — Fill gaps

Use the drilling technique for each weak or missing section. Acceptance Criteria must be observable. Out of Scope needs minimum two exclusions for Initiatives/Epics. Technical Notes: if unknown, write "Needs engineering input before implementation" — never leave empty or invented.

### 3d — Draft and apply

Show Added, Changed, Unchanged, then the full updated body. Confirm before updating the ticket.

---

## Rules

- Read PRODUCT.md before authoring anything. No exceptions.
- Hard-stop if a new Direction conflicts with a resolved product decision. Redirect to `reflect`.
- Direction doc first, tracker ticket second. Never create a tracker artifact without a written Direction doc (or an explicit PM override for Epics/Stories under an existing Direction).
- Do not auto-chain between phases. Each phase is a deliberate invocation.
- Confirm before every write — Direction doc, tracker ticket, PRODUCT.md glossary entry, tracker link.
