Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing.

If a question can be answered by exploring the codebase or existing docs, explore instead of asking.

<supporting-info>

## During the session

### Sharpen fuzzy language

When vague or overloaded terms appear, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

Stress-test relationships and boundaries with specific scenarios. Invent edge cases that force precision about where one concept ends and another begins.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Sharpen each decision before moving on

Don't advance to the next branch until the current one is resolved. Ambiguity left open becomes a load-bearing assumption downstream.

</supporting-info>
