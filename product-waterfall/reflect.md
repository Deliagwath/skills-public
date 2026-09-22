---
name: product-waterfall-reflect
description: Takes a real-world signal and carries it upward against PRODUCT.md — classifies it, deliberates at the waterline, and records the outcome. The only path to updating resolved decisions and product-level out of scope in PRODUCT.md. The PM equivalent of facilitated-waterfall bottom-up.
---

Take a concrete signal — an experiment result, customer feedback, sprint retro finding, usage data, a market shift, a thing that surprised the team — and carry it upward to the waterline from the product side. Find the quick interpretation, then **look up**: does it confirm what we've decided, challenge it, or reveal a gap? Settle what it means, honour the commitments above the line, and feed what you learned back up. Read `conventions` for the waterline, PRODUCT.md structure, signal classification, append-only rule, and confirm-before-write rule.

The working document is a **Probe** (`docs/product/probes/probe-YYYY-MM-DD-slug.md`) — the one mutable artifact, working memory for the session. Create it at Anchor; it carries the deliberation so a fresh session resumes from its header, not from zero.

## Ascent guard

You may update anything **below** the waterline freely — current themes, Direction docs, tracker tickets. You may **not** overturn a commitment **above** the line (a resolved decision, product-level out of scope) without surfacing the trade-off and recording explicit supersession in PRODUCT.md. If the trade-off is not accepted, the signal is noise — monitor it, do not act on it.

`reflect` is the **only** path to writing resolved decisions and product-level out of scope to PRODUCT.md. `direct` reads those sections but may not write to them.

---

## Phase 1 — Anchor

State the signal and the candidate interpretation in one or two sentences. Create the Probe with a collision-free id (`probe-YYYY-MM-DD-slug`), `status: open`, and the **Signal** section filled. No authoring above the line yet.

If PRODUCT.md does not exist: stop. "There is no PRODUCT.md to check this signal against. Run `reflect bootstrap` to build the product direction document first."

---

## Phase 2 — Situate

Read PRODUCT.md. Walk through resolved decisions and product-level out of scope. Identify which entries are governed by or relevant to the signal. Record them in the Probe under **Governing decisions**. If PRODUCT.md has no entry that covers the signal area, write "gap — no governing decision" — that is itself a finding.

Classify the signal using the Signal classification table in `conventions`. Present the classification to the PM and ask: "Does that feel right?"

---

## Phase 3 — Deliberate

This is the heart, and it is the step most easily skipped — the pull toward a quick update is to record the obvious interpretation and move on. Resist it. For every resolved decision the signal touches, climb to the waterline and test the recorded decision against what reality just told you.

**For a confirming signal:** the decision holds. Record as supporting evidence in the Probe. No PRODUCT.md change. Close.

**For a noise signal:** record why it does not generalise. No PRODUCT.md change. Close.

**For a scope creep signal:** read the relevant product-level out of scope entry aloud to the PM. Ask: "Does this challenge the boundary, or affirm it?" If it affirms: record and close. If it challenges: treat as contradicting.

**For a gap signal:** "PRODUCT.md has no resolved decision covering [area]. Does this signal warrant adding one?" If yes, proceed to Phase 4. If no: record and close.

**For a contradicting signal — work through it fully:**

Read the governing decision aloud: "Here is the decision this signal contradicts: [decision + rationale]." Ask: "Does this signal change your confidence in it?"

If the PM says the decision holds: record the signal as a monitored data point in the Probe. Note it explicitly — "decision holds; signal logged for future review." Close.

If the PM says the decision should be revisited: ask "Is this a full supersession — the old decision is wrong — or a scoped amendment — the decision holds generally but needs a carve-out?" Drill until the PM's position is precise using the drilling technique from `conventions`. Do not accept "let's revisit it" as an outcome — a decision must be made or explicitly deferred.

Record the deliberation in the Probe under **Deliberation**: which interpretation was tested, what the PM decided, and why. This is the durable record — a future session reading the Probe should understand the full reasoning without reading the chat history.

---

## Phase 4 — Write to PRODUCT.md

Only after Phase 3 resolves — meaning a per-decision deliberation verdict is recorded and no governing decision is left as an unresolved amendment candidate.

**New resolved decision:**
Draft the row:
`| [Decision statement] | [Rationale — what evidence drove this] | [Supersedes: old decision if applicable, or —] | [Date] |`

The old row stays. A new row with a Supersedes pointer is the only way to reverse a decision.

**New product-level out of scope entry:**
Draft the entry:
`- [Exclusion statement] — [Rationale]`

**New domain glossary term:**
Draft the entry:
`| [Term] | [Meaning — naming and boundaries only] |`

**Current strategic themes update (cycle shift):**
If the signal indicates a theme is no longer active or a new theme is emerging, propose the updated themes table. A full replacement of the Current Strategic Themes section is allowed at cycle boundaries.

Show the current state of the section and the proposed addition side by side. Follow the confirm-before-write rule from `conventions`. Execute only on explicit PM yes.

---

## Phase 5 — Reconcile

Distil the probe into a durable record, then freeze it. The Probe cannot move to `resolved` until:

- Every **Governing decision** has a recorded verdict in Deliberation — `holds: [reason]` or `superseded: [new entry]`
- Every **open question** in the Probe is resolved or explicitly deferred with a reason
- All **PRODUCT.md changes** made are listed in the Probe under a Changes section
- The Probe is self-contained — a fresh session reading only this file can understand what happened

Append a line to `docs/product/probes/LEDGER.md` if it exists: `[probe-id] — resolved [DATE] — outcome: [one-line summary]`.

Set `status: resolved`. A probe abandoned (signal not worth pursuing) is set `status: abandoned` and kept as a "why we didn't act" record.

---

## bootstrap — Build PRODUCT.md from scratch

Use this entry when PRODUCT.md does not exist or the PM explicitly wants to build it from scratch.

Interview the PM through five questions using the drilling technique from `conventions`. One question at a time; give your recommended answer; push back.

**Q1 — Product identity:** "In one paragraph: who is this product for, what job are they hiring it to do, and what makes it distinct from alternatives?" Drill until it names a specific user type, states a concrete job-to-be-done (not a feature list), and names at least one differentiator.

**Q2 — Resolved decisions (seed):** "What product decisions have already been made that should never be re-litigated?" Give examples: "Desktop-only, not web", "enterprise not SMB", "we don't do payments processing ourselves." For each: collect the rationale. A decision without rationale is just a rule. Collect 2–5.

**Q3 — Product-level out of scope:** "What does this product explicitly NOT do — things users ask for but that are permanently off the table?" Require at least two. Push back on anything that sounds like "not yet" rather than "never."

**Q4 — Current strategic themes:** "What are the 2–4 things the team is focused on this cycle?" Name each theme and the tracker Initiative key if one exists. Remind the PM: these are below the waterline and will be replaced next cycle.

**Q5 — Domain glossary (seed):** "Are there product terms the team uses that mean different things to different people?" Optional — fine to start empty. Probe: "Is there a term like 'Butler' or 'connector' or 'workspace' that means something specific in this product?"

Compose the full PRODUCT.md draft using the structure in `conventions`. Show it. Confirm before writing. On confirm: write to the workspace root.

Report: "PRODUCT.md created. `direct` will read it before shaping any new Initiative. `reflect signal` is the only path to updating resolved decisions."

---

## Rules

- Create the Probe at Anchor. Never skip straight from signal to PRODUCT.md update.
- Never overturn a commitment above the waterline without recorded deliberation and explicit PM acceptance.
- A quick interpretation that only works by ignoring a resolved decision is evidence the decision may be stale — investigate and record, don't quietly act past it.
- Deliberate before you conclude anything. Read the governing decisions and test the signal against them explicitly.
- Reconcile before closing. An `open` probe with unresolved governing decisions is drift that `conventions` audit will flag.
- The probe is working memory — keep the header (Signal · status · Governing decisions · open questions) accurate so any session resumes from it.
