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

When all five are resolved, number sequentially from the highest existing file in `docs/directions/`. Write `docs/directions/NNN-slug.md` with frontmatter (`id`, `title`, `status: draft`, `created`, `relates: []`) and the five sections as body.

Update `CONTEXT.md` when a domain term is resolved. Glossary only — no implementation detail.
