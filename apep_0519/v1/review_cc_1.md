# Internal Review — Round 1

**Verdict: Minor Revision**

## Strengths
1. Well-motivated research question with clear policy relevance
2. Credible identification strategy exploiting staggered cantonal adoption
3. Honest presentation of null result with multiple inference approaches
4. Strong robustness section (Bacon decomposition, wild bootstrap, RI)
5. Thoughtful discussion of the wood heating placebo failure

## Concerns
1. **Wood placebo failure** (significant at p=0.02) undermines parallel trends assumption. Paper discusses this honestly but should acknowledge more explicitly that this limits the causal interpretation of all estimates.
2. **Data gap (2016-2020)** is substantial. While acknowledged, the paper could better discuss what we might be missing during the early adoption years.
3. **Limited power**: With 26 cantons and a 0.69pp effect, the MDE at 80% power is likely larger than the estimate. Should discuss power limitations.
4. **Missing CS-DiD**: The Callaway & Sant'Anna estimator is cited but not implemented. Given the staggered design, this would strengthen the paper.

## Recommended Changes
- Add a brief power analysis discussion in Empirical Strategy
- Strengthen the wood placebo discussion
- These are minor — paper is ready for external review

## Decision
Proceed to advisor review.
