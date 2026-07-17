---
name: general-usage-zoom-in
description: Interviews relentlessly about every aspect of a plan to reach shared understanding, walking down each branch of the design tree and resolving dependencies. Use when drilling into design details, clarifying a plan, or stress-testing decisions against code and existing documentation.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing.

If a question can be answered by exploring the codebase or existing docs, explore instead of asking.

<supporting-info>

## During the session

Apply throughout:

- **Sharpen fuzzy language** — when vague or overloaded terms appear, propose a precise canonical term immediately.
- **Probe with scenarios** — stress-test boundaries with concrete edge cases. "What happens when X?" forces precision that abstract discussion doesn't.
- **Push back** — do not accept the first answer without testing it. A decision is resolved when it holds under challenge, not when it's first stated.
- **Resolve inline** — capture decisions as they happen, don't batch. Don't advance to the next branch until the current one is resolved; ambiguity left open becomes a load-bearing assumption downstream.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

</supporting-info>
