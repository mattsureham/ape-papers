# Internal Review Round 1

**Date:** 2026-03-04
**Reviewer:** Claude Code (self-review)
**Verdict:** Minor Revision

## Summary

The paper studies whether candidate wealth predicts electoral success in Indian state assembly elections using an RDD at the vote margin threshold. The core finding — that the 60% wealth premium vanishes to 50% in close elections — is striking and well-documented. The identification strategy is clean, with strong McCrary density tests and covariate balance. Robustness is extensive.

## Strengths

1. **Clean identification:** Sharp RDD with convincing manipulation tests and balance checks
2. **Novel finding:** The disappearing wealth premium is genuinely informative about mechanisms
3. **Comprehensive robustness:** Polynomial orders, donut RDD, kernels, bandwidths, placebo cutoffs — all consistent
4. **Good institutional detail:** The Supreme Court disclosure regime is well-explained
5. **State heterogeneity:** Positive effects in all 22 states with sufficient data

## Weaknesses and Suggestions

1. **"First stage" framing is imprecise:** The 1.38 log-point discontinuity in winner's assets is labeled a "first stage" but there's no second stage (no downstream outcome). It's really a mechanical effect: electing the richer candidate produces a richer winner. Clarify this is a selection effect, not an IV first stage.

2. **Wealth ratio balance test:** The marginally significant wealth ratio balance (p=0.018) deserves more discussion. While it's partially mechanical (related to running variable construction), it could also indicate that wealthier candidates strategically enter races where wealth gaps are largest.

3. **Match rate could bias:** 49.4% match rate means we lose half the sample. More discussion of how matched vs unmatched constituencies differ would strengthen external validity claims.

4. **Period coverage limited:** 2004-2013 is a specific era in Indian politics. Since 2014, BJP dominance has changed the landscape dramatically. Acknowledge this more prominently.

5. **No downstream outcomes:** The paper identifies who wins but not what winning buys. Without nightlights, spending, or development outcomes, the paper remains a study of political selection rather than policy consequences. This limits its contribution relative to Asher & Novosad (2017).

## Decision

The paper is methodologically sound with a clear and interesting finding. The weaknesses are primarily about framing and scope rather than identification. Recommend minor revision focusing on precise language about the "first stage" finding and expanded discussion of match rate selection.
