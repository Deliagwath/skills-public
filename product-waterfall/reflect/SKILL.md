---
name: product-waterfall-reflect
description: Takes a real-world signal — or an engineering finding handed up by facilitated-waterfall bottom-up or top-down — and carries it upward against docs/PRODUCT.md. Classifies it, deliberates at the product waterline, records the outcome, and lists every product and engineering artifact the outcome affects. The only path to updating resolved decisions and product-level out of scope. The PM equivalent of facilitated-waterfall bottom-up.
---

Take a concrete signal and carry it upward to the product waterline. The signal might be an experiment result, customer feedback, a retro finding, usage data, a market shift, something that surprised the team, or an engineering finding that a product commitment can't hold. Find the quick interpretation, then **look up**: does it confirm what we've decided, challenge it, or reveal a gap? Settle what it means, honour the commitments above the line, and feed what you learned back down to everything that depends on it. Read `conventions` for the waterlines, the hooks, docs/PRODUCT.md structure, signal classification, append-only rule, and confirm-before-write rule.

The working document is a **Probe** (`docs/product/probes/probe-YYYY-MM-DD-slug.md`), the one mutable artifact and the session's working memory. Create it at Anchor. It carries the deliberation, so a fresh session can resume from its header instead of starting over.

**Find the entry.**

- A signal from the world → **Anchor**.
- Loaded by `bottom-up` or `top-down` → **Anchor** in subroutine mode. The signal is the engineering finding the caller hands over, along with its probe or artifact id. Don't re-gather what the caller already found.
- No docs/PRODUCT.md, or the PM asks to build it → **bootstrap**.

## Ascent guard

You may recommend changes to anything **below** the product line: themes, Directions, Epics, Stories. You may **not** overturn a commitment **above** it (a resolved decision, a product-level exclusion) without surfacing the trade-off and recording explicit supersession in docs/PRODUCT.md. If the PM doesn't accept the trade-off, treat the signal as noise: monitor it and don't act on it.

`reflect` is the **only** path to writing resolved decisions and product-level out of scope. `direct`, `top-down`, and `bottom-up` read those sections but never write them.

---

## Phase 1 — Anchor

State the signal and the candidate interpretation in one or two sentences. Create the Probe with a collision-free id, `status: open`, and the **Signal** section filled. In subroutine mode, set `relates:` to the caller's probe or artifact so the two probes point at each other.

If docs/PRODUCT.md doesn't exist, stop: "There is no docs/PRODUCT.md to check this signal against. Run `reflect bootstrap` to build it first."

---

## Phase 2 — Situate

Read docs/PRODUCT.md. Walk through resolved decisions and product-level out of scope. Identify which D-/X-ids govern or relate to the signal, and record them in the Probe under **Governing decisions**. If no entry covers the signal area, write "gap — no governing decision". That is itself a finding.

Classify the signal using the table in `conventions`. Present the classification to the PM and ask: "Does that feel right?"

---

## Phase 3 — Deliberate

This is the most important step, and the one most often skipped. The temptation is to record the obvious interpretation and move on. Don't. For every resolved decision the signal touches, climb to the product waterline and test the recorded decision against what reality just told you.

**For a confirming signal:** the decision holds. Record it as supporting evidence in the Probe. No PRODUCT.md change. Close.

**For a noise signal:** record why it doesn't generalise. No PRODUCT.md change. Close.

**For a scope creep signal:** read the relevant X-id entry aloud to the PM and ask: "Does this challenge the boundary, or affirm it?" If it affirms the boundary, record and close. If it challenges it, treat the signal as contradicting.

**For a gap signal:** "docs/PRODUCT.md has no resolved decision covering [area]. Does this signal warrant adding one?" If yes, go to Phase 4. If no, record and close.

**For a contradicting signal, work through it fully:**

Read the governing decision aloud: "Here is the decision this signal contradicts: [D-NNN + rationale]." Ask: "Does this signal change your confidence in it?"

If the PM says the decision holds, record the signal as a monitored data point: "decision holds; signal logged for future review." In subroutine mode, the caller must now find a mechanism that honours the decision. Say so explicitly. Close.

If the PM says the decision should be revisited, ask: "Is this a full supersession (the old decision is wrong) or a scoped amendment (the decision holds generally but needs a carve-out)?" Drill until the PM's position is precise. Don't accept "let's revisit it" as an outcome: a decision must be made or explicitly deferred.

Record the deliberation in the Probe under **Deliberation**: which interpretation was tested, what the PM decided, and why. This is the durable record. A future session reading only the Probe should understand the reasoning without the chat history.

---

## Phase 4 — Write to docs/PRODUCT.md

Only after Phase 3 resolves, meaning every governing decision has a recorded verdict and none is left as an unresolved amendment candidate.

**New resolved decision** (next D-id):
`| D-NNN | [Decision statement] | [Rationale — what evidence drove this; cite the probe] | [D-id superseded, or —] | [Date] |`

The old row stays. A new row with a Supersedes pointer is the only way to reverse a decision.

**New product-level out of scope entry** (next X-id):
`- X-NNN — [Exclusion statement] — [Rationale]`

**New domain glossary term:**
`| [Term] | [Meaning — naming and boundaries only] |`
First check that docs/CONTEXT.md doesn't already define it.

**Current strategic themes update (cycle shift):**
If the signal shows a theme is no longer active or a new one is emerging, propose the updated table. A full replacement is allowed at cycle boundaries.

Show the current section and the proposed addition side by side. Follow confirm-before-write, and execute only on an explicit yes from the PM.

---

## Phase 5 — Propagate

A changed decision is only half done until its dependents are known. For every D-/X-id superseded or amended in Phase 4, find what cites it, directly or through its parents:

```sh
grep -rlH "PRODUCT.md#D-NNN" docs/ 2>/dev/null        # direct citations
grep -rlH "<each hit's id>" docs/ 2>/dev/null          # children of each hit, repeated downward
```

Walk down: Direction → Epics → Stories → FW Directions/Tasks → ADRs and Plans. Record every hit under **Affected** in the Probe with a one-line recommendation:

- Product Direction that conflicts with the new decision → new Direction through `direct` (Directions are append-only).
- Epic or Story → `direct` Refine.
- FW Direction, Task, ADR, or Plan → `bottom-up` on it, with this probe as the trigger.

Present the Affected list. **Recommend; don't edit.** Each fix is its own deliberate invocation. In subroutine mode, return the outcome and the Affected list to the caller.

---

## Phase 6 — Reconcile

Distil the probe into a durable record, then freeze it. The Probe can't move to `resolved` until:

- Every **Governing decision** has a recorded verdict in Deliberation: `holds: [reason]` or `superseded: [new id]`.
- Every **open question** is resolved or explicitly deferred with a reason.
- Every docs/PRODUCT.md change is listed under **Changes**.
- **Affected** is filled in: either every hit or "none".
- The Probe is self-contained: a fresh session reading only this file can understand what happened.

Append to `docs/product/probes/LEDGER.md` (create it if missing): `[probe-id] — resolved [DATE] — outcome: [one-line summary]`.

Set `status: resolved`. If the signal turns out not to be worth pursuing, set `status: abandoned` and keep the probe as a record of why nothing was done.

---

## bootstrap — Build docs/PRODUCT.md from scratch

Use when docs/PRODUCT.md doesn't exist or the PM explicitly wants to rebuild it.

Interview the PM through five questions using the drilling technique. One question at a time; give your recommended answer; push back.

**Q1 — Product identity:** "In one paragraph: who is this product for, what job are they hiring it to do, and what makes it distinct from alternatives?" Drill until it names a specific user type, states a concrete job-to-be-done (not a feature list), and names at least one differentiator.

**Q2 — Resolved decisions (seed):** "What product decisions have already been made that should never be re-litigated?" For example: "desktop-only, not web", "enterprise, not SMB", "we don't process payments ourselves". Collect the rationale for each; a decision without a rationale is just a rule. Collect 2–5 and number them D-001….

**Q3 — Product-level out of scope:** "What does this product explicitly NOT do: things users ask for but that are permanently off the table?" Require at least two. Push back on anything that sounds like "not yet" rather than "never". Number them X-001….

**Q4 — Current strategic themes:** "What are the 2–4 things the team is focused on this cycle?" Link each to a Direction in docs/product/directions/ if one exists. Remind the PM that themes are below the waterline and get replaced next cycle.

**Q5 — Domain glossary (seed):** "Are there product terms the team uses that mean different things to different people?" Optional; it's fine to start empty. Skip any term docs/CONTEXT.md already defines.

Compose the full draft using the structure in `conventions`. Show it and confirm before writing. On yes, write `docs/PRODUCT.md`.

Report: "docs/PRODUCT.md created. `direct` and FW `top-down` will read it before shaping anything. `reflect` is the only path to changing resolved decisions."

---

## Rules

- Create the Probe at Anchor. Never skip straight from signal to a PRODUCT.md update.
- Never overturn a commitment above the product line without recorded deliberation and explicit PM acceptance, even when an engineer or `bottom-up` is the one asking.
- A quick interpretation that only works by ignoring a resolved decision is evidence the decision may be stale. Investigate and record; don't quietly act past it.
- Deliberate before concluding anything. Test the signal against each governing decision explicitly.
- Propagate, then reconcile. A supersession with no Affected list leaves stale work downstream that audit will flag.
- The probe is working memory. Keep the header (Signal · status · Governing decisions · open questions) accurate so any session can resume from it.
