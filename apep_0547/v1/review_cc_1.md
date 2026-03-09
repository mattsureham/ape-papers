# Internal Review - Round 1

**Reviewer:** Claude Code (Internal)
**Date:** 2026-03-09

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

**Strengths:**
- The natural experiment is genuinely compelling: Wales abolished no-fault evictions 3+ years before England, creating clean temporal and geographic variation.
- The paper's honest engagement with identification failures is its greatest asset. Rather than claiming a causal effect, it methodically dismantles its own baseline result.
- The triple-difference design (DDD) with PRS intensity is a sophisticated test of the mechanism.

**Concerns:**
- The 22 Welsh clusters remain the fundamental limitation. The permutation test (p=0.299) is decisive, but the paper could do more to quantify the minimum detectable effect (MDE) given this cluster count.
- The unbalanced panel (48 English LAs with boundary changes) is well-documented but could introduce composition bias if the merged/new LAs have systematically different trajectories.

### 2. Inference and Statistical Validity

- Standard errors clustered at LA level throughout — appropriate.
- Wild cluster bootstrap with Webb weights provides valid finite-sample inference (p=0.003, which contradicts the permutation test at p=0.299). The paper discusses this tension but could be more explicit about why these two approaches disagree (the bootstrap imposes the null, while the permutation test doesn't).
- Sample sizes are consistent across specifications after the corrections made.

### 3. Robustness and Alternative Explanations

- Border-county subsample (β=-0.018, p=0.353) is the strongest piece of evidence against causal interpretation.
- Leave-one-out stability is reassuring for internal consistency.
- The anticipation exclusion (Jun-Nov 2022) changes the estimate minimally.
- The paper acknowledges that the sign reversal with LA-specific trends (β=+0.049) is a red flag.

### 4. Contribution and Literature

- Well-positioned in the eviction/rent control literature (Diamond 2019, Autor 2014, Desmond 2016).
- The methodological contribution on few-cluster inference is genuinely useful.
- Missing: Could cite Kaplan et al. (2014) on housing market thin trading, and Anenberg & Kung (2014) on housing market search frictions.

### 5. Results Interpretation

- The paper correctly calibrates its claims — the conclusion is appropriately cautious.
- The log-point to percentage conversion has been corrected throughout.
- The SDE table in Appendix F is a valuable addition.

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. **Power analysis:** Add a back-of-envelope MDE calculation. With 22 treated clusters, what's the smallest effect you could detect? This would contextualize the null finding.
2. **Synthetic control:** A single-unit synthetic control for Wales (matching on pre-treatment transaction trends) would provide an alternative estimator that doesn't rely on parallel trends.
3. **Heterogeneity by time:** Break the post-treatment period into early (2023) and late (2024-2025) to test whether effects emerge gradually.

## OVERALL ASSESSMENT

**Key strengths:** Honest scientific inquiry, methodologically sophisticated, beautifully written.
**Critical weaknesses:** Fundamental power limitations (22 clusters), inability to distinguish "no effect" from "effect too small to detect."
**Publishability:** Strong paper that makes a genuine contribution despite (and partly because of) the null result. The methodological lessons are broadly applicable.

DECISION: MINOR REVISION
