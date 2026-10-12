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

## Cover in order

1. **Problem** — what is broken or missing, stated plainly?
2. **Appetite** — how much complexity and effort is this worth? (a budget, not an estimate)
3. **Out of scope** — what would a naive engineer build that you don't want?
4. **Success signal** — how will you know it worked? Observable, not aspirational.
5. **Constraints** — what cannot change regardless of how this is solved?

When a section produces a vague answer, drill until it is precise before moving on.

## Output

When all five are resolved, run `sp new direction "<title>" --intent "<one sentence>"` (`~/.agent-skills/facilitated-waterfall/scripts/sp`): it takes the next number, writes `docs/directions/NNN-slug.md` with its frontmatter (`id: direction-NNN`, `title`, `created`, `relates: []`) and the section headings, and prints the path. Fill the five sections, then run `sp check <direction-id>`. Without `sp`, number from the highest file in `docs/directions/` and write the same by hand. Add an optional `intent:` line to the frontmatter: one sentence saying what the Direction is for, drawn from the settled Problem. Omit it rather than invent one if the interview didn't settle it.

Update `docs/CONTEXT.md` when a domain term is resolved. Glossary only — no implementation detail.
