---
name: facilitated-waterfall-bottom-up
description: Works a concrete task or fix from the code up to the waterline — locates the code, climbs the abstraction ladder to check it sits in the right place against the governing docs, resolves at the line, implements below it, and reconciles what it learned back into the durable record. Records working memory in docs/probes/. Use when handed a bug, change request, or task rooted in existing code.
---

Take a concrete trigger — a bug, a change request, a task — and carry it up to the waterline from the code side. Find the quick fix, then **look up**: is it in the right spot, the right class, the right module, the right architecture? Settle where it belongs, honor the commitments above the line, implement below it, and feed what you learned back up. Read `conventions` for the drilling technique, the waterline, append-only, formats, and numbering — not repeated here.

The working document is a **Probe** (`docs/probes/<id>-slug.md`) — the one mutable artifact, your working memory across sessions and context windows. Create it at Anchor; it carries the investigation so a fresh agent resumes from its header, not from zero.

## Ascent guard

You may change anything **below** the waterline freely — placement, class, module, pattern are reversible mechanism. You may **not** overturn a commitment **above** the line (an ADR decision, a Direction constraint or scope) without surfacing the trade-off and recording **accepted** supersession. If the trade-off isn't accepted, the fix is wrong — go back down and find a mechanism that honors the decision.

---

## Phase 1 — Anchor

State the trigger and the candidate quick-fix in one or two lines. Create the Probe with a collision-free id (`probe-YYYY-MM-DD-slug`), `status: open`, and the **Trigger** section filled. No authoring above the line yet.

## Phase 2 — Situate

Locate the code (`grep`/`find`/`git log`). Walk `relates` **upward** from whatever artifact governs this area to collect every constraint — ADRs, the Task/Epic scope, the Direction. Record them in **Governing docs**. If none exist, write "code ahead of docs" — that is itself a finding to reconcile later.

## Phase 3 — Climb & deliberate

This is the heart, and it is the step most easily skipped — the pull toward a quick fix is to find a clean home for the code and start writing. Resist it. From the fix's natural home, climb the ladder one rung at a time, asking each rung's question. **Do not stop at the first rung where the change fits** — a clean below-the-line home is necessary but not sufficient. Always carry the climb all the way to the waterline and read the governing ADR(s) and Direction. The point of reaching the top is not to ask permission; it is to *test the recorded decision against what the code just told you*.

```
placement (right spot?) → class (right abstraction?) → module (right owner?)
→ architecture/pattern (consistent?) → ══ WATERLINE ══ → ADR / Direction (still true?)
```

**Explore the code before you conclude anything.** Read the code the fix touches *and* the code the governing ADR describes — reason from the source, not from the doc's summary of it. Record what you find in **Findings** (dated, append-only — what investigation revealed about reality). Record the climb in **Deliberation**: which rung each candidate settled or failed at, and whether the line was hit. Keep **Open questions** (each with "what would resolve it") and **Risk** (blast radius · rollback · cost-of-wrong) current as you go.

**Test each governing decision — don't just obey it.** For every ADR that governs this area, hold its Decision against your Findings and ask: are its Context and assumptions still true in the code as it stands today? Does the clean fix you found quietly contradict, erode, or route *around* the decision? A decision you can only satisfy by working around it is a signal the ADR may be stale — not that your fix is clever. Write an explicit verdict for each governing ADR in Deliberation — `still holds — <why>` or `amendment candidate — <what reality changed>` — **before** you resolve. Skipping straight from a below-the-line home to implementation without recording these verdicts is the drift this phase exists to prevent.

**Resolve at the line:**
- **Fits below the line *and* every governing decision still holds** (verdicts recorded) → mechanism change. Proceed to implement. No ceremony.
- **Requires an above-the-line change** → classify it:
  - *Correction* (the recorded decision is simply wrong on contact with code) → surface the trade-off, get explicit acceptance, then append a **superseding ADR** through the `design` discipline (load `top-down` Phase 3). Record the acceptance in Deliberation.
  - *Net-new intent* (a missing decision, Task, or Direction) → **load `top-down`** at the matching tier to author it properly, then resume:
    - Missing decision → `top-down` Phase 3 (ADR).
    - Missing work unit → `top-down` Phase 2 (Breakdown → Task).
    - Missing/mis-stated problem → `top-down` Phase 1 (Shape → Direction).

**Autonomy scales to tier** (per `conventions`): a **Direction**-level gap is intent — always interview the human. A **Task/ADR** gap whose answer is derivable from code + existing docs, you may drive autonomously, escalating only on genuine ambiguity.

## Phase 4 — Implement

Only below the line, only after Phase 3 resolves — meaning a per-ADR verdict is recorded and every `amendment candidate` has been carried through the Correction path, not deferred. Do not open a Plan while any governing ADR is still an unresolved amendment candidate. Derive the **Plan** from the Task + governing ADRs when the work needs step-decomposition; write `docs/plans/NNN-slug.md` (Context · Steps · Verification · Risk). A Plan may span several sibling Tasks. Skeleton first, then body. Append verification results to the Probe's Findings. Do not report done if any Verification item fails or any ADR decision is violated.

## Phase 5 — Reconcile (the return path)

Distill the probe into durable record, then freeze it. The Probe cannot move to `reconciled` until **all** gates pass:

- Every **Open question** is resolved or explicitly deferred.
- Every Deliberation **conflict** is either fixed-in-code or recorded as a superseding ADR with accepted trade-off — never silently dropped.
- Every **CONTEXT.md** term the work touched is verified against the current code and updated if stale.
- The artifacts produced/updated are listed in **Reconciliation** (new/superseded ADR, updated Task, new Direction, CONTEXT entries), and their `relates` link back to this probe.

Append a `LEDGER.md` line. Set `status: reconciled`. A probe abandoned (not worth pursuing) is set `status: abandoned` and kept as a "why we didn't" record.

## Rules

- Implementation lives below the waterline. Never overturn a commitment above it without recorded acceptance.
- Never jump from trigger to Plan. Phase 3 — explore the code, climb to the waterline, and record a verdict on every governing ADR — is mandatory, not optional, even when a clean below-the-line fix is obvious.
- A quick fix that only works by routing around an ADR is evidence the decision may be stale — investigate and record an amendment candidate, don't quietly implement past it.
- Don't hand-author above-the-line artifacts ad hoc — load `top-down` so they get the full drilling discipline.
- The probe is working memory: keep the header (Trigger · status · Governing docs · Open questions) accurate so any session resumes from it.
- Reconcile before closing. An `open` probe with unresolved questions is drift `conventions` audit will flag.
