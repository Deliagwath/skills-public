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
  The successor points at the predecessor; the predecessor is not rewritten. Carried
  by the optional `supersedes` frontmatter key on the successor. Partial replacement is the same
  edge — the part absorbed is named in the body, not in a second key.
- **Forward-only edge** — an edge recorded solely in the frontmatter of the newer
  artifact. The older artifact is never edited to reflect it. Supersession and the
  closing of an open question are both forward-only.
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
