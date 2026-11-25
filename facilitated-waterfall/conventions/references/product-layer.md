# Product layer (when present)

The reference half of `facilitated-waterfall/conventions`; cites to `conventions → Product layer` resolve here.

When the project also runs `product-waterfall` (`docs/PRODUCT.md`, `docs/product/`), a second waterline stacks **above** this one, and the product **Story** is the seam: mechanism to the PM, commitment to engineering. See `product-waterfall` `conventions` for the full picture.

```
docs/PRODUCT.md (D-/X-ids) ═══ PRODUCT WATERLINE ═══ product Direction → Epic? → Story
   ┄┄ seam: Story ┄┄  FW Direction · ADR ═══ ENGINEERING WATERLINE ═══ architecture → code
```

- **Entry from above.** `top-down` accepts a Story (or product Epic) as input; the FW Direction or Tasks it writes carry the Story's id in `relates`.
- **Product commitments bind engineering.** A Story's Outcome, Acceptance criteria, and Out of scope, its parents' Out of scope, and every `docs/PRODUCT.md` resolved decision (D-NNN) and product-level exclusion (X-NNN) are above-the-line constraints for any FW artifact beneath them.
- **Product commitments move through the PM.** A Story → `direct` Refine; a D-/X-entry → `reflect`. ADRs operate below them.
- **Two glossaries.** `docs/PRODUCT.md` holds product terms; `docs/CONTEXT.md` holds engineering terms. A term lives in exactly one: check the other before appending. A CONTEXT.md entry that realises a product term names it.

Without a product layer, FW works standalone.
