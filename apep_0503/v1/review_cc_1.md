# Internal Review — Round 1

**Paper:** Energy Labels with Teeth: Rental Bans and the Capitalization of France's DPE System
**Reviewer:** Claude Code (Internal)
**Date:** 2026-03-04

## Verdict: MINOR REVISION

## Summary

This paper uses a multi-cutoff RDD to study whether France's DPE energy labels affect housing prices through information or regulation. The key finding — a 5.6% price discontinuity only at the G/F boundary where the rental ban actively binds, with null effects at five information-only boundaries — is clean and compelling. The built-in placebo design (using information-only cutoffs as controls for the regulatory cutoff) is methodologically elegant.

## Strengths

1. **Identification strategy:** The multi-cutoff comparison is a genuine contribution. Using information-only boundaries as internal placebos eliminates many confounders that plague single-cutoff RDDs.
2. **Institutional setting:** France's phased rental ban creates exogenous variation in regulatory intensity across otherwise similar label boundaries.
3. **Comprehensive robustness:** McCrary tests, covariate balance, donut RDD, bandwidth sensitivity, placebo cutoffs, polynomial sensitivity, and transaction volume tests cover the major threats.
4. **Clean narrative:** The paper's story — "markets respond to teeth, not labels" — is memorable and policy-relevant.

## Concerns

### Major
1. **Aggregate merge attenuation:** The commune × year × building-type merge is a significant limitation. The paper acknowledges this but should quantify the potential attenuation (e.g., how much within-cell price variance exists relative to across-cell variance?).
2. **McCrary rejection at E cutoff:** The significant bunching at the F/E boundary (p=0.005) deserves more discussion in the main text. If assessors manipulate at F/E, could they also manipulate at G/F in ways the McCrary test doesn't detect (e.g., strategic selection of which properties to assess)?

### Minor
1. The pre-ban / post-ban comparison is underpowered (N=268 post-ban). Consider dropping the table or moving it to the appendix if post-ban results are uninformative.
2. The B/A cutoff shows marginal significance (p<0.10 at the "wrong" sign). Brief discussion of why the highest-rated boundary might show this pattern would be useful.
3. Some placebo cutoffs show marginal significance — the one at 90 kWh is significant at p<0.001. The explanation (new construction concentration) is plausible but warrants a sentence acknowledging this as a limitation.

## Recommendation

The paper is well-executed and the core finding is robust. Address the minor concerns and proceed to external review.
