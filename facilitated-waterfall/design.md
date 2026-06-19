---
name: design
description: Interviews the user about design decisions for an Epic or Direction, walking down each branch of the design tree and resolving dependencies one-by-one. Use when making architectural or design decisions for a feature, or when exploring trade-offs and dependencies for a planned initiative.
---

<what-to-do>

Read the input artifact and its related documents, then interview the user about the design decisions it raises until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies one-by-one. For each question, provide your recommended answer.

Find the input: interpret the argument naturally to locate the file in `docs/epics/` or `docs/directions/`. If no argument, scan and ask.

Ask one question at a time. If a question can be answered by exploring the codebase, explore instead of asking.

</what-to-do>

<supporting-info>

## Before the first question

Read the input artifact in full. Follow its `relates` to read each parent document. Use these as the frame for the interview — challenge decisions that contradict them.

## Drilling technique

Ask one question at a time. Give your recommended answer before waiting for a response. Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen, don't batch.

### Challenge against the glossary
When the user uses a term that conflicts with `CONTEXT.md`, call it out immediately. "Your glossary defines X as Y, but you seem to mean Z — which is it?"

### Cross-reference with code
When the user states how something works, check whether the code agrees. Surface contradictions.

### Update CONTEXT.md inline
When a term is resolved, update `CONTEXT.md` immediately. Glossary only — no implementation details.

### Offer ADRs sparingly
Only when all three are true:
1. Hard to reverse — the cost of changing your mind later is meaningful
2. Surprising without context — a future reader will wonder "why did they do it this way?"
3. The result of a real trade-off — there were genuine alternatives

Write ADRs to `docs/adr/NNNN-slug.md`. Set `relates` to include the input artifact's id.

</supporting-info>
