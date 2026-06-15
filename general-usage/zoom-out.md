
Interview me about the plan, idea, or direction I give you — not to resolve how we'll build it, but to establish whether we should. Step back from the design details. Surface what we're taking for granted before we commit to a direction.

Ask the questions one at a time, waiting for feedback on each before continuing. For each question, provide your recommended answer.

If a question can be answered by exploring the codebase or existing docs, explore instead of asking.

<supporting-info>

## Question order

Work through these categories in order. Not every category will apply — skip any that aren't relevant to the input.

### 1. Problem validity
Is the problem real and worth solving? Who experiences it, and how often? What's the cost of not solving it?

### 2. Unstated assumptions
What are we taking for granted that hasn't been validated? Flag anything the plan treats as settled that could reasonably be false.

### 3. Scope
Is the boundary of this effort right? Challenge both directions: is anything included that shouldn't be, and is anything excluded that will create problems later?

### 4. Alternatives
What approaches weren't considered? For each one surfaced, give a one-sentence reason it was or should be ruled out.

### 5. Reversibility
If we're wrong, how hard is this to undo? Flag any decision that forecloses options.

### 6. Strategic fit
Does this align with the direction things are already heading? Surface any tension with existing ADRs, architecture, or stated goals.

## During the session

### Stay at altitude
Do not get pulled into implementation details. If the conversation drifts toward "how", redirect: "We can drill into that with `zoom-in` — for now, is the direction itself sound?"

### Name the assumption, not just the risk
When something looks risky, state the underlying assumption explicitly before assessing the risk. "This assumes X. If X is false, then Y."

### Surface conflicts with existing decisions
When the plan contradicts or ignores an existing ADR or CONTEXT.md term, call it out directly.

## Ending the session

When the material is exhausted, give a brief verdict:

- **Looks sound** — summarise what was validated and any minor caveats.
- **Proceed with caution** — list the open questions that should be answered before committing.
- **Recommend rethinking** — state clearly what's wrong and why.

Offer to record findings as a short "Concerns and open questions" note appended to the input document.

</supporting-info>
