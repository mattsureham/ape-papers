# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-24T16:30:22.037218

---

# Referee Report

**Manuscript:** The Stability Paradox: Tipped Minimum Wages Close the Racial Earnings Gap but Not the Turnover Gap in U.S. Restaurants
**Journal:** AER: Insights

## 1. Idea Fidelity

The paper largely pursues the core empirical strategy outlined in the Original Idea Manifest, utilizing the QWI administrative panel to examine the differential effects of tipped minimum wages on racial earnings versus employment stability. The shift from a state-level panel (manifest) to a county-level panel (paper) represents a rigorous improvement in statistical power. However, there is a notable divergence in the descriptive findings. The Manifest claimed that OFW states exhibit a near-zero cross-sectional earnings gap ($10), whereas Table 1 in the paper shows an 8.2% gap ($164) in OFW states. The paper correctly pivots to rely on causal identification (DDD and event study) rather than cross-sectional comparison to establish the policy effect, but the Introduction should explicitly acknowledge this deviation from the initial descriptive hypothesis to avoid confusion. The use of Insurance (NAICS 524) as a placebo industry aligns with the Manifest's suggestion of "Finance and professional services," maintaining fidelity to the identification strategy.

## 2. Summary

This paper documents a "stability paradox" in the U.S. restaurant industry: while increases in the tipped minimum wage significantly narrow the racial earnings gap between Black and White workers, they leave the racial turnover gap unaffected. Using a difference-in-difference-in-differences design on administrative employment data, the author argues that tipped wage policy successfully addresses customer-driven tipping discrimination (the price channel) but fails to mitigate employer-driven discrimination in hiring and retention (the quantity channel). The findings suggest that "One Fair Wage" policies are necessary but insufficient for achieving full racial equity in restaurant employment.

## 3. Essential Points

1.  **Event Study Pre-Trends:** The event study results in Table 3 (Panel A) display significant pre-trends in the earnings gap. The Black-White earnings interaction is statistically significant and growing in magnitude from $t-5$ to $t-2$ (widening from -$167 to -$241) before the policy implementation. This suggests that the racial earnings gap was already evolving differently in New York compared to control states prior to the reform. While the post-treatment narrowing is evident, the non-parallel pre-trends weaken the causal claim that the policy *caused* the convergence rather than a mean reversion or coincident trend. The authors must address whether control states are appropriate or if a synthetic control approach would better match pre-trends.
2.  **Interpretation of Turnover Mechanisms:** The paper attributes the persistent turnover gap entirely to employer-side discrimination (statistical discrimination in hiring/retention). However, standard labor supply theory suggests that higher wages could increase turnover if workers use the wage boost as a bridge to better outside options (the "stepping stone" effect). If Black workers face different outside options than White workers, a wage increase could heterogeneously affect quit rates without invoking employer discrimination. The discussion needs to engage with this alternative explanation to strengthen the claim that the stability gap is purely demand-side discrimination.
3.  **Descriptive Narrative vs. Causal Estimates:** There is a tension between the "Paradox" narrative and Table 1. The Introduction states OFW is "framed as a racial equity intervention," yet Table 1 shows OFW states still have an 8.2% earnings gap (similar to tip-credit states). If OFW states haven't eliminated the gap cross-sectionally, the welfare claim that OFW is "half a remedy" relies entirely on the DDD coefficient. The authors should clarify whether the cross-sectional similarity in Table 1 is due to offsetting factors (e.g., higher cost of living in OFW states) to prevent readers from dismissing the policy's efficacy based on the descriptive table alone.

## 4. Suggestions

**Clarify the "Paradox" Definition and Narrative**
The current draft risks confusing readers by presenting Table 1 (showing similar gaps in OFW and tip-credit states) alongside a narrative that implies OFW states solve the earnings problem. The Manifest originally claimed OFW states had a $10 gap; the paper corrects this to $164. This correction is scientifically
