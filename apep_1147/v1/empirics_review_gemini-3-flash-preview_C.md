# V1 Empirics Check — google/gemini-3-flash-preview (Variant C)

**Model:** google/gemini-3-flash-preview
**Variant:** C
**Date:** 2026-03-30T15:48:46.323771

---

This review evaluates the paper "The Union Shield That Wasn't: Right-to-Work Laws and the Racial Earnings Gap" following the requested format.

### 1. Idea Fidelity
The paper maintains high fidelity to the original idea manifest. It successfully executes the suggested staggered difference-in-differences (DiD) using the QWI county-race panel and the specified four-state treatment group (IN, MI, WI, WV). It correctly identifies the "union shield" mechanism and utilizes the recommended comparison states (IL, OH, MN, PA, NY). The paper expands on the manifest by adding Sun-Abraham heterogeneity-robust estimators and a triple-difference (DDD) specification, which are appropriate econometric evolutions of the original pitch.

### 2. Summary
The paper uses staggered Right-to-Work (RTW) law adoptions in the 2010s to test whether weakening unions widens the Black-White earnings gap. Using a triple-difference design on county-level administrative data, the author finds a precise null effect: RTW laws reduced earnings for both groups slightly and nearly identically, leaving the racial earnings ratio unchanged. The results suggest that modern union bargaining floors are not the primary mechanism maintaining or narrowing the racial wage gap in these states.

### 3. Essential Points

*   **Inference with Four Treated Clusters:** The paper clusters standard errors at the state level. With only 9 states (4 treated, 5 control), the cluster-robust variance estimator is known to be severely biased downward, leading to over-rejection of the null. While the paper finds a null result, the confidence intervals (CIs) are likely artificially tight. The author **must** implement a wild cluster bootstrap or a permutation-based inference method to provide credible $p$-values and CIs with such a small number of clusters.
*   **The "Earnings vs. Wage" Distinction:** The QWI `EarnS` variable measures quarterly earnings of "stable" workers, not hourly wages. A null effect on quarterly earnings could mask a scenario where hourly wages fell but hours worked increased (or vice versa) differentially by race. Given that unions negotiate both wage scales and seniority/scheduling rules, the author needs to be more cautious in interpreting "earnings" as a pure proxy for "bargaining power over price" and should check if `Emp` (employment) or `EmpTotal` shows differential volatility.
*   **Treatment Timing for Michigan:** The paper and tables list Michigan's treatment year as 2013, whereas the manifest and historical record note the law was signed in Dec 2012 and became effective in March 2013. In a quarterly model, assigning 2013 as the "Post" year is acceptable, but the Sun-Abraham event studies should clarify if 2013Q1 or 2013Q2 is the first treated quarter to avoid contaminating the "Pre" period with anticipation effects or early-implementation noise.

### 4. Suggestions

*   **Manufacturing Sub-sample:** Table 2, Column 2 shows a coefficient for Manufacturing ($0.022$, $p=0.14$) that is nearly the opposite sign and larger in magnitude than the aggregate null. Since manufacturing is the "home" of the union shield hypothesis, this deserves a dedicated event-study plot. If the "shield" exists anywhere, it is there; a null in the aggregate might just be reflecting the low unionization rates of the service sector.
*   **Selection into "Stable" Earnings:** The `EarnS` variable only counts workers who held a job for a full quarter. If RTW led to a disproportionate increase in "last-hired, first-fired" Black workers entering or exiting the labor force, the "stable worker" composition changes. I suggest running the DDD on `EarnS` and `EarnFull` (full-quarter earnings) side-by-side to see if the null is robust to the definition of employment stability.
*   **Visual Evidence:** The paper lacks an event-study plot. For an AER: Insights format, a single, high-quality Sun-Abraham event-study figure showing the Black and White ATTs (and their difference) over time is more persuasive than Table 3. This would allow readers to assess local parallel trends visually.
*   **Magnitude Interpretation:** The paper classifies the -0.012 estimate as a "precise null." At the county-race level, a 1.2% change in the earnings gap is actually quite large in the context of policy interventions. The author should contextualize this against the *secular* trend in the racial gap. If the gap is narrowing by 0.5% a year naturally, a 1.2% shift is two years of progress.
*   **Urban vs. Rural Heterogeneity:** The Appendix Table 5 shows a "Large negative" effect for urban areas (-0.035, SE=0.010). This is a highly significant result ($p<0.01$) that contradicts the primary "null" conclusion of the abstract. This suggests that the union shield *does* exist in urban labor markets where union density is high, but is washed out by rural data. The paper would be much stronger if it focused on this urban/rural tension rather than a flat null.
*   **Comparison Sample:** New York and Minnesota are quite different from West Virginia and Indiana. A robustness check using a more constrained "Rust Belt" control group (e.g., just IL, OH, and PA) would strengthen the claim that the counterfactual is appropriate.
*   **Check for Anticipation:** Union members often rush to sign long-term contracts *immediately before* RTW takes effect (a common tactic in MI and WI). This can delay the "treatment" effect for several years until those contracts expire. The author should discuss this "contract expiration" lag and perhaps look at 5-year post-treatment windows more specifically.
