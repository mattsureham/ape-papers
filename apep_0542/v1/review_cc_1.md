# Internal Review - Round 1

**Reviewer:** Claude Code (Internal)
**Paper:** When the Train Doesn't Come: Property Values and the Cancellation of HS2 Phase 2
**Date:** 2026-03-06

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The paper exploits the surprise cancellation of HS2 Phase 2 on October 4, 2023, as a negative infrastructure shock. The identification strategy is well-motivated: comparing properties near cancelled Phase 2 stations to (a) the broader sample and (b) properties near continuing Phase 1 stations.

**Strengths:**
- The within-project control (Phase 1 vs Phase 2) is a compelling design that controls for project-level uncertainty and macroeconomic conditions.
- The event is arguably exogenous — Royal Assent had been granted, land acquisition was ongoing, and no formal review preceded the announcement.
- Multiple treatment definitions (2km, 5km, 10km, continuous distance) provide a thorough examination.

**Concerns:**
- The parallel trends assumption is violated. The paper acknowledges this honestly and interprets the result as a well-powered null. This is the right interpretation but limits the causal claim.
- The "degree of surprise" is debatable given the 2021 IRP curtailment and persistent cost escalation. The paper addresses this well in Section 2.2 but could more explicitly discuss what this means for the estimand.
- The Phase 1 control group is geographically concentrated around London/Birmingham, creating a North-South composition difference that confounds the within-project comparison.

### 2. Inference and Statistical Validity

- Standard errors are clustered at the local authority level, which is appropriate.
- Randomization inference (500 permutations) supplements clustered SEs — good practice with ~25 treated clusters.
- Sample sizes are large and reported consistently.
- R² values for Columns 1-3 of Table 2 are nearly identical (0.89175-0.89179), which is expected given the same sample with different treatment indicator definitions affecting a small fraction of observations.

### 3. Robustness and Alternative Explanations

The robustness battery is comprehensive:
- Phase 1 placebo (-5.7%) is informative — suggests construction disruption effects.
- Temporal placebo (+3.4%) effectively undermines the causal interpretation.
- Exclude London (+1.3%, p=0.06) shows dependence on London in the control group.
- Repeat sales (+3.1%) rules out composition effects.
- Eastern vs Western leg comparison is useful for testing partial anticipation.

**Missing checks:**
- No heterogeneity by property tenure (freehold vs leasehold).
- No examination of transaction volume changes (extensive margin).
- No discussion of whether the "Network North" announcement confounds interpretation.

### 4. Contribution and Literature Positioning

The paper positions itself well against the transit capitalization literature (Gibbons & Machin 2005, Heblich et al. 2024) and the infrastructure cancellation literature (Greenstone & Gallagher 2008). The contribution — studying cancellation rather than creation — is genuine and interesting.

The honest reporting of a null result is a strength in a literature prone to publication bias.

### 5. Results Interpretation and Claim Calibration

The paper's central interpretation — a well-powered null — is well-calibrated. The authors resist the temptation to claim a positive causal effect despite statistically significant coefficients. The discussion of mechanisms (skeptical markets, blight relief, Network North substitution) is appropriately speculative.

---

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. **Transaction volume analysis:** Examine whether the cancellation affected the number of transactions (extensive margin), not just prices.
2. **Rental market:** If rental data were available, comparing price vs rent responses could distinguish between user-cost and speculative channels.
3. **Longer post-period:** With only 5 post-quarters, the long-run effect is unknown. Flag this as a limitation and suggest future work.

---

## 6. Actionable Revision Requests

### Must-fix:
1. None — the paper's core issues have been addressed in the current version.

### High-value improvements:
1. Add a map figure showing HS2 Phase 1/Phase 2 routes and station locations with treatment rings.
2. Discuss Network North announcement as a potential confound more explicitly in the threats section.
3. Consider adding transaction volume analysis as supplementary evidence.

### Optional polish:
1. Promote Figure 6 (raw trends) to main text — it builds trust before the event study.
2. The summary statistics discussion could more directly emphasize the North-South divide driving composition differences.

---

## 7. Overall Assessment

**Key strengths:**
- Excellent institutional knowledge and honest treatment of a null result
- Clean identification design with powerful within-project control
- Comprehensive robustness battery that systematically builds the case for interpreting the DiD as trend, not treatment
- Strong prose quality

**Critical weaknesses:**
- Pre-trends violation limits causal claims (but paper handles this well)
- Short post-period (5 quarters) limits power for detecting delayed effects
- Geographic concentration of Phase 1 controls around London creates composition concerns

**Publishability:** Publishable at AEJ: Economic Policy after minor revisions. The honest null result and thorough investigation of why the null obtains make this a valuable contribution.

DECISION: MINOR REVISION
