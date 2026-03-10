# Internal Review — Round 1

**Paper:** Eat In or Take Out? Complete Tax Pass-Through at Japan's Dual-Rate Consumption Tax Boundary
**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-09

## Overall Assessment

**Verdict: Minor Revision**

This is a well-executed empirical paper with a clean natural experiment and a striking result (100.4% pass-through). The identification is credible, the writing is strong, and the paper tells a compelling story. The main weaknesses are (1) the limited data (aggregate CPI only, no micro-data), and (2) the narrow scope of the finding (price pass-through only, no quantity/substitution evidence).

## Strengths

1. **Excellent natural experiment.** The within-product tax differential is genuinely unique and provides unusually clean identification.
2. **Strong hook and prose quality.** The rice ball opening is memorable and the writing maintains reader interest throughout.
3. **Complete robustness.** Pre-trend tests (p=0.75), placebo timing, bandwidth sensitivity, COVID controls — all clean.
4. **Honest about limitations.** The paper acknowledges the aggregate data constraint and doesn't overclaim.
5. **Near-perfect magnitude match.** 1.86% observed vs 1.85% predicted is a remarkable result.

## Weaknesses and Suggestions

### Methodology
1. The SD(Y) for the SDE table uses the pre-treatment SD of the relative price (0.0032), which is the SD of a near-constant ratio. This makes the SDE = 6.38 enormous but somewhat misleading — the outcome has low variance precisely because it's a relative price of two closely-related series. Consider noting this more prominently.

### Content
2. The paper could benefit from a brief conceptual framework (even 1 page) formalizing the pass-through prediction. The 2/108 = 1.85% is derived informally but a simple model of competitive pricing with a tax wedge would strengthen the theoretical grounding.
3. The DDD estimate (0.0077) vs DD pre-COVID estimate (0.0204) discrepancy deserves more discussion. The paper notes this but doesn't fully explain why the panel estimate is lower.

### Presentation
4. Table 2 note says "Newey-West" but the code uses HC1. Should be consistent.
5. The event study figure (Fig 3) uses pre-period residual variance for CIs rather than regression-based SEs. This is unconventional and should be noted more prominently.

## Minor Issues
- Some references in the bib file have notes fields that shouldn't be there (e.g., the Ashenfelter entry)
- The "crawfordetal2010" citation was fixed but the Crossley et al. (2009) reference is a working paper

## Decision: MINOR REVISION — proceed to external review after addressing Table 2 SE note.
