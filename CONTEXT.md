# CONTEXT

Glossary for this repo. Terms only — no implementation detail.

## Facilitated Waterfall

- **Artifact** — a document produced by a Facilitated Waterfall skill: a Direction,
  Epic, Task, Plan, or ADR. The artifact is the unit of the method; an individual
  exchange within an interview is not.
- **Direction** — the top artifact. States a Problem, an Appetite, what is Out of
  scope, a Success signal, and Constraints.
- **Epic** — a unit of work decomposed from a Direction. States a Goal, Scope, and
  Out of scope.
- **Task** — a unit of work decomposed from an Epic.
- **Plan** — the numbered, executable steps for a Task.
- **ADR** — a recorded architectural decision. States Context, Decision, and
  Consequences.
- **`relates`** — the frontmatter field linking an artifact to its parents and to
  the ADRs bearing on it. Fixed at creation, and therefore reliable.
- **Frontier** — the deepest stage that has artifacts but whose next stage is
  missing. What `what-next` computes.
- **Drift** — an implementation that has left the boundaries its governing
  artifacts set. What `audit-doc` reports.

## Rationale

- **Issue** — a question raised. In IBIS terms, the thing a decision resolves.
- **Position** — a candidate answer to an Issue. Several may compete.
- **Argument** — a consideration for or against a Position. Does not itself branch
  the discussion; it elaborates in place.
- **Closure** — the state of an Issue that has been decided: a Position was chosen,
  and the Argument that settled it is recorded. An Issue with no closure is open.
  Raising is carried by the `open` key, closing by `closes` on a later artifact.
- **Open question** — an Issue recorded in frontmatter because it *cannot* be settled
  in the session that raised it. A question answerable now is answered, not recorded.
  Since closure is forward-only and needs a later artifact, an entry that never
  warranted one would never close.
- **Rejected position** — a Position that was raised and ruled out, recorded
  together with the Argument that killed it. Distinct from Out of scope, which
  bounds the work rather than reporting a weighing.
- **Ruled-out record** — where a Rejected position and its Argument are written. In
  an ADR: the *Considered Options* and *Pros and Cons of the Options* sections. In
  every other artifact type: prose under `## Notes`. Only the ADR carries the MADR
  headings.
- **Supersession** — a later artifact replacing an earlier one, in whole or in part.
  Two edges, written together: `supersedes` on the successor and `superseded-by` (a
  list) on the predecessor, whose body and decision are never rewritten (ADR 0005,
  replacing the forward-only rule). Partial replacement is the same edge — the part
  absorbed is named in the successor's body, not in a second key.
- **Forward-only edge** — an edge recorded solely in the frontmatter of the newer
  artifact. The older artifact is never edited to reflect it. The closing of an open
  question (`closes`) is forward-only; supersession no longer is.
- **Artifact id** — an artifact's `id:`, `<kind>-<number>` (`direction-020`,
  `task-084`, `adr-0034`, `story-013`; a probe keeps `probe-YYYY-MM-DD-slug`).
  Unique in a workspace by construction, and the form every link and prose citation
  uses (ADR 0006). The file name keeps its `NNN-slug.md` form.
- **Provenance over completeness** — rationale is recorded only when it was
  genuinely raised. "No alternatives were weighed" is an acceptable and common
  outcome; an invented alternative is a defect, not a gap filled.

## Method

- **Skill independence** — no skill requires another to have run. Skills communicate
  through committed artifacts, never through implied sequence.
- **Fan-out** — the number of descendant artifacts a single Direction resolves to
  through `relates`. Large fan-out is what makes a Direction untrackable within one
  working session.
- **Fan-out rejection test** — the check that a unit of work does not increase the
  number of artifacts a Direction spawns. Applied to a Task rather than measured on
  the corpus.
- **Cause tag** — the likely cause of a review or audit finding. A *context gap* means
  the governing docs didn't say it; a *judgment gap* means they did and the work
  missed it. The tag calibrates where fixes should go, and is distinct from how a
  finding is routed now.
- **Author-blind risk** — the test for planning depth. Work gets a Plan or a design
  interview when its author is likely blind to how it can go wrong, not because it
  is important.

## Knowledge

- **Workspace** — the unit that accumulates knowledge: one repo and its `docs/`.
  The analogue of an OpenRig *seat*. A session is its *occupant*: it inherits what
  the workspace knows, and deposits what it learned.
- **Maturity stage** — how settled a knowledge entry is, from a fixed vocabulary.
  Distinct from freshness (`unverified` / `stale`), which says whether the entry is
  still true.
- **Portable entry** — a knowledge entry that would read correctly in a different
  workspace. Marked, never moved.
- **Cut test** — "has this changed a decision recently?" Applied in pruning to
  entries that are still true.
- **Effect observed** — evidence, at a later real opportunity, that a change had its
  intended effect. Distinct from mechanics verified. It is what separates `done`
  from `implemented`.
- **Read depth** — what a resuming session actually re-read (full, partial, not
  read), as opposed to what it inherited from a summary.
- **Intent line** — an artifact's one-sentence `intent:`. Walking `relates` upward
  composes the intent lines one per level; a missing line is a gap, never filled in.
- **Handbook** — a workspace's short, graded lessons for working in it: commands,
  conventions, gotchas, and the purpose of each area. It is inherited by the next
  session and pruned by the cut test. Distinct from *research*, which is long-form
  and only looked up.
- **Sealed artifact** — finished history: a reconciled or abandoned probe, a Plan
  with a ledger line, a superseded ADR. Not loaded when a session inherits;
  reachable by lookup.
- **Inherit point** — a moment a skill already passes through at which it reads
  what its workspace knows about the area at hand. Reading is tied to these
  moments, never to a separate step.
- **Deposit** — what a probe's close adds to the handbook, and promotes or demotes
  in it, from what the probe observed.
- **Fence** — the end of a body of work: the last Task of an Epic, or the last Epic
  of a Direction, implemented. A trigger for distilling.
- **Retirement** — removing an idle entry from the handbook by moving it, verbatim
  and with its reason, into the sealed probe that cut it. Nothing is deleted.
