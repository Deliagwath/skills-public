---
name: facilitated-waterfall-shape
description: Interviews the user to define a Direction artifact with Problem, Appetite, Out of scope, Success signal, and Constraints sections. Use when starting a new initiative, defining project direction, or capturing a new goal as a structured Direction file.
---

Interview the user about a problem or goal until all five sections of a Direction are resolved, then write the Direction file.

If an argument is provided, treat it as the opening problem statement and proceed to the first question. If not, ask the user to describe the problem first.

## Drilling technique

Ask one question at a time. Give your recommended answer before waiting for a response. Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases ("What happens when X?").
- **Push back** — test each answer; a decision is resolved when it holds under challenge.
- **Resolve inline** — capture decisions as they happen.
- **Frame the fork to fit the options** — ask either/or when the options exclude each other. When the candidates each own a different leg of the problem, present them as complements and ask which, or both; a "both" answer changes the budget (surfaces, amendments, boundaries).

## Resolve the premise first

When the solution space rests on an unresolved premise — a choice of external project, repo or service the Direction would depend on — settle it before drilling the sections it determines: survey the candidates (liveness, license, what they already provide, grounded in source) and let the user choose.

When the application the Direction rides on ships its own integration for a candidate — a plugin, an adapter, a config section — survey what that integration already does from the pinned source: its adapter docstring, its error paths, and the host's config defaults (approval modes, unattended-classification, deny-by-default boundaries, echo-loop prevention, protected-file lists). That text names the trust boundary and feeds two sections: the Appetite fork (config-of-the-host vs code-of-ours) and the Constraints the host enforces. Recommend the host-native path, and let the survey show whether it can express the need.

## Cover in order

1. **Problem** — what is broken or missing, stated plainly?
2. **Appetite** — how much complexity and effort is this worth? (a budget, not an estimate)
3. **Out of scope** — what would a naive engineer build that you don't want?
4. **Success signal** — how will you know it worked? Observable. Include the end-to-end outcome only the operator observes alongside the machine checks, worded so a later failure points to the leg that failed.
5. **Constraints** — what holds regardless of how this is solved?

When a section produces a vague answer, drill until it is precise before moving on.

## Output

When all five are resolved, run `sp new direction "<title>" --intent "<one sentence>"` (`~/.agent-skills/facilitated-waterfall/scripts/sp`): it takes the next number, writes `docs/directions/NNN-slug.md` with its frontmatter (`id: direction-NNN`, `title`, `created`, `relates: []`) and the section headings, and prints the path. Fill the five sections, then run `sp check <direction-id>`. `sp check` covers links and numbering; measure every `file:line` citation in the current tree before it lands and re-grep it after. Without `sp`, number from the highest file in `docs/directions/` and write the same by hand. The `intent:` line is one sentence saying what the Direction is for, drawn from the settled Problem; leave it out when the interview didn't settle it.

Update `docs/CONTEXT.md` when a domain term is resolved. Glossary only — no implementation detail.
