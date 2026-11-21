---
name: facilitated-waterfall-shape
description: Interviews the user to define a Direction artifact with Problem, Appetite, Out of scope, Success signal, and Constraints sections. Use when starting a new initiative, defining project direction, or capturing a new goal as a structured Direction file.
---

Interview the user about a problem or goal until all five sections of a Direction are resolved, then write the Direction file.

If an argument is provided, treat it as the opening problem statement and proceed to the first question. If not, ask the user to describe the problem first.

## Drilling technique

Ask one question at a time. Give your recommended answer before waiting for a response. Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen, don't batch.
- **Frame the fork honestly** — an either/or question is only right when the options are in tension (one excludes the other). When the candidates each own a different leg of the problem, present them as complements and ask which, or both — a "both" answer changes the budget (surfaces, amendments, boundaries) in ways a false binary hides.

## Cover in order

1. **Problem** — what is broken or missing, stated plainly?
2. **Appetite** — how much complexity and effort is this worth? (a budget, not an estimate)
3. **Out of scope** — what would a naive engineer build that you don't want?
4. **Success signal** — how will you know it worked? Observable, not aspirational. A machine-only list is
   not the section: include the end-to-end outcome only the operator observes — the machine cannot prove it,
   and the operator judges success by their own experience — worded so a later failure triages to the leg
   that actually failed.
5. **Constraints** — what cannot change regardless of how this is solved?

When a section produces a vague answer, drill until it is precise before moving on.

If the problem's solution space rests on an unresolved premise — a choice of external project, repo or service the direction would depend on — resolve the premise before drilling the sections it determines: survey the candidates (liveness, license, what they already provide, grounded in source) and let the user choose. Drilling detail that the premise decision would preempt wastes the interview, and the user rejects the order.

When the application the direction rides on ships its own integration for a candidate — a plugin, an adapter, a config section — the survey must cover what that shipped integration already does, grounded in the pinned source, not the vendor's marketing: its adapter docstring, its error paths, and the host's config defaults (approval modes, unattended-classification, deny-by-default boundaries, echo-loop prevention, protected-file lists). That text names the trust boundary, so it feeds two sections at once: the Appetite fork (config-of-the-host vs code-of-ours) and the Constraints the host enforces whether we like it or not. Present the host-native path as the recommended option — the operator prefers re-enabling the host's own machinery over building bespoke — and let the survey surface whether the host path can express the need at all.

## Output

When all five are resolved, run `sp new direction "<title>" --intent "<one sentence>"` (`~/.agent-skills/facilitated-waterfall/scripts/sp`): it takes the next number, writes `docs/directions/NNN-slug.md` with its frontmatter (`id: direction-NNN`, `title`, `created`, `relates: []`) and the section headings, and prints the path. Fill the five sections, then run `sp check <direction-id>`. `sp check` verifies links and numbering, not
prose: every `file:line` citation written from memory (the classic post-compaction error) is measured in
the current tree before it lands and re-grepped after — a quote its own file cannot support is the drift
`sp check` will not name. Without `sp`, number from the highest file in `docs/directions/` and write the same by hand. Add an optional `intent:` line to the frontmatter: one sentence saying what the Direction is for, drawn from the settled Problem. Omit it rather than invent one if the interview didn't settle it.

Update `docs/CONTEXT.md` when a domain term is resolved. Glossary only — no implementation detail.
