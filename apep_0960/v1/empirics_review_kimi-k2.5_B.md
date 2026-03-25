# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant B)

**Model:** moonshotai/kimi-k2.5
**Variant:** B
**Date:** 2026-03-25T20:24:20.816285

---

 **Referee Report: "Fiscal Overkill? Confiscatory Mining Taxation and Local Economic Activity in Zambia"**

---

### 1. Idea Fidelity

The paper pursues the core empirical question identified in the manifest—estimating the local economic effects of Zambia's 2019 mining tax reform using satellite nighttime lights—but deviates substantively from the proposed research design. Most critically, it abandons the treatment-intensity specification (mining employment share) in favor of a binary classification that alternates inconsistently between 11 "core" mining districts and 21 province-level districts. The paper also fails to utilize the DHS and Labour Force Survey data specified in the original design, which were intended to validate nightlight proxies with employment and welfare outcomes. Furthermore, while the manifest emphasized exploiting the September 2019 partial reversal as a dose-response test, the paper treats this only as a limitation rather than as identifying variation. These deviations considerably reduce the statistical power and mechanistic depth of the analysis.

---

### 2. Summary

This paper evaluates Zambia's 2019 mining tax reform—which raised effective tax rates to 86–105%—using a difference-in-differences design comparing nighttime light intensity in mining versus non-mining districts from 2012–2023. Contrary to industry predictions of economic collapse, the author documents a precise null effect, suggesting either local economic resilience to confiscatory taxation or limitations in satellite-based measurement of informal economic activity.

---

### 3. Essential Points

**Violation of parallel trends.** The event-study estimates reveal significant pre-trends in the six years preceding the reform (coefficients at $t=-6$, $-5$, $-4$, and $-3$ are statistically significant with magnitudes comparable to post-treatment estimates). The paper acknowledges these as "oscillations" but provides no formal test or covariate adjustment to justify the parallel trends assumption. Without addressing these pre-existing differential trends—potentially driven by anticipatory investment cycles, mine lifespan depreciation, or spatially correlated copper price shocks—the causal interpretation of the DiD estimates is invalid.

**Specification sensitivity contradicts key claims.** While the abstract emphasizes a "precise null" with tight confidence intervals, Table 4 reveals significant negative effects when isolating the January–September 2019 period ($-0.035$, $p<0.05$) and when including district-specific linear trends ($-0.055$, $p<0.05$), alongside a significant positive effect using the 75th percentile of luminosity ($+0.
