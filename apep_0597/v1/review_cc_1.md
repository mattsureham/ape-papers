# Internal Review — Round 1

**Paper:** From Pumps to Plates: Geographic Pass-Through of Nigeria's 2023 Fuel Subsidy Removal
**Reviewer:** Claude Code (self-review as Reviewer 2 + Editor)
**Date:** 2026-03-11
**Verdict:** MAJOR REVISION

---

## Summary

This paper studies the geographic price pass-through of Nigeria's May 2023 fuel subsidy removal, using distance from petroleum import terminals as continuous treatment intensity. The paper's structure is sound: a DiD framework with built-in placebos (protein, processed goods, pre-reform timing). The cereal price result (β = 0.0704, p < 0.001) is the headline finding and is both economically large and statistically sharp.

## Strengths

1. **Clever identification.** The subsidy maintained uniform prices, so removal creates a natural experiment with clean variation in treatment intensity. The continuous treatment (distance) is plausibly exogenous.

2. **Built-in placebos.** The commodity heterogeneity (cereals positive, protein negative, processed goods null) is a powerful internal validity test. This pattern is hard to explain by confounders.

3. **Strong prose.** The introduction is vivid and well-structured. The Tinubu inaugural scene is an effective hook. The "pumps to plates" framing is memorable.

4. **Bandwidth sensitivity is well-handled.** Rather than hiding the insignificant full-sample fuel result, the paper presents it honestly and uses the bandwidth analysis to characterize the temporal dynamics.

## Critical Issues

### 1. Text-Data Inconsistency: Number of RI Permutations
The paper text states "500 permutations" (Section 6, Robustness; Appendix E.1), but the code (`04_robustness.R`, line 160) sets `n_perms <- 1000`. This must be reconciled — either update the code or the text.

### 2. Pre-Trend Concern for RTEP Data
The paper claims "no evidence of differential pre-trends" with F = 1.24, p = 0.26 (Appendix B.1). However, the RTEP data are described as "modeled" prices that include crowd-sourced and interpolated values. If the pre-reform prices were genuinely uniform under the subsidy (as the institutional background claims), then a pre-trend test is nearly tautological — of course there are no pre-trends, because the government set the same price everywhere. The test is uninformative about the parallel trends assumption, which concerns what would have happened *without* the reform. The paper should acknowledge this limitation more directly.

### 3. Abstract Mentions "significant distance gradient" for Petrol — Misleading
The preferred full-sample specification (Table 2, Column 2) shows β = 0.0035 with p > 0.10. The abstract leads with "a significant distance gradient in shorter windows" — but the reader's first impression should not be that the main petrol result is significant. The abstract correctly qualifies this, but consider reframing to lead with the cereal result as the headline.

### 4. SDE Table Classification
The SDE table should use the preferred specification for each outcome. Verify that the SDE computation uses the correct β, SD(X), and SD(Y) values. The continuous treatment formula SDE = β × SD(X) / SD(Y) requires the unconditional SD of distance (in 100km units) — confirm this matches the summary statistics.

## Major Suggestions

1. **Reframe the paper's contribution.** The real contribution is the food price pass-through (cereals), not the petrol price gradient. Consider restructuring to make cereals the primary result and petrol the supporting evidence. The petrol result is suggestive; the cereal result is definitive.

2. **Discuss RTEP data quality.** The RTEP "modeled" prices may introduce measurement error that attenuates the petrol coefficient. If prices are model-based (e.g., interpolated from nearby observations), this could explain both the weak full-sample result and the pre-trend test behavior. The WFP food prices, being directly observed, may be more reliable — which is consistent with the sharper food price results.

3. **Add a back-of-envelope welfare calculation.** The paper discusses geographic equity qualitatively but could include a simple calculation: for a household consuming X kg of cereals per month, how much more does a northern household pay than a southern one? This would make the magnitude legible.

## Minor Issues

- Table 4 caption says "Robustness: Bandwidth Sensitivity" — consider a more descriptive title.
- The scatter plot (Figure 4) could include confidence bands to show statistical uncertainty.
- The paper mentions "1,400 kilometers" for Maiduguri in the introduction but "1,160 km" in the data section. The 1,400 is road distance, 1,160 is Haversine — clarify.
- Consider adding a table of the top-10 and bottom-10 markets by distance, showing pre and post prices, to make the variation tangible.

## Decision

**MAJOR REVISION.** The paper has a strong core result (cereals) but the framing overweights the weaker petrol result. Fix the RI permutation count inconsistency, reframe to lead with cereals, and improve the discussion of RTEP data limitations.
