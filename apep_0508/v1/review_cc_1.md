# Internal Review — Round 1

**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-04
**Verdict:** Minor Revision

## Summary

The paper studies the UAE's 2022 kafala reform using a cross-sectional event study on 45 DFM-listed firms. The main finding is a precisely estimated null: high-exposure firms (construction, real estate, services) did not experience differentially negative abnormal returns relative to low-exposure firms (banking, insurance, telecom) around three reform events. The 95% CI bounds kafala-derived monopsony rents at less than 4.5% of listed firm value.

## Strengths

1. **Novel question with clear policy relevance.** This is the first paper to estimate the capitalized value of kafala-derived monopsony rents using financial market data. The question is important and understudied.

2. **Comprehensive robustness battery.** The paper includes five placebo dates, four event windows, GCC benchmark placebo, market model CARs, continuous treatment, randomization inference (1,000 permutations), and stacked DiD. This exceeds the standard for event studies on small exchanges.

3. **Honest engagement with the null.** The discussion section (Section 7) presents four interpretations of the null result with genuine intellectual depth. The bounding exercise in Section 7.5 is particularly effective.

4. **Clean identification.** The cross-sectional event study design exploits within-exchange variation in kafala exposure, with three events providing independent tests of the same hypothesis.

## Weaknesses

1. **Small sample (N=45 firms).** The design has limited power to detect small effects. The MDE is approximately 3-5 percentage points, meaning rents smaller than 3% of firm value would be undetectable.

2. **Exposure classification is sector-level, not firm-level.** The binary classification relies on approximate migrant shares. Within-sector heterogeneity in actual kafala dependence is not captured.

3. **Confounding with Emiratisation quotas.** Section 7.3 acknowledges this honestly, but it remains a fundamental limitation. The simultaneous tightening of nationalization quotas creates opposing effects that could mask the kafala signal.

4. **Data quality concerns.** Yahoo Finance data for DFM stocks may have gaps, survivorship bias, or thin trading artifacts. The 39.10% outlier in the GCC placebo table (now excluded) suggests data quality issues.

## Required Revisions

1. Clarify in the text that the stacked DiD coefficient (-0.0004) is in levels (daily returns), not percentage points.
2. Ensure Table 4 variable labels are clean and readable (fixed in this round).
3. Address the UAE_DFM outlier in the GCC placebo table (excluded with note in this round).

## Verdict

The paper is well-executed and makes a genuine contribution. The null result is informative and the robustness battery is thorough. I recommend **Minor Revision** with the fixes above (now implemented).
