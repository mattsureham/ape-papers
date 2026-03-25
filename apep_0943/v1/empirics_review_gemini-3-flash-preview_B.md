# V1 Empirics Check — google/gemini-3-flash-preview (Variant B)

**Model:** google/gemini-3-flash-preview
**Variant:** B
**Date:** 2026-03-25T15:57:21.419315

---

**Referee Report: The Boomerang Ballot: Federal Climate Referendum Failure and Subnational Policy Innovation in Switzerland**

### 1. Idea Fidelity
The paper follows the core logic of the original idea manifest: using the June 2021 CO2 Act rejection as a shock to identify "compensatory federalism" in pro-climate cantons. However, it deviates significantly from the proposed outcome variables. The manifest explicitly prioritized **Stage 1 (policy adoption)** and **Stage 2 (heat pump adoption/fossil replacement)**. While the paper executes Stage 1 convincingly, it replaces the Stage 2 "real" outcome of heat pump adoption with "new residential building construction." This is a weaker proxy for climate innovation, as new construction is driven by broader macroeconomic factors (interest rates, migration, zoning) more than marginal changes in climate policy, which primarily target heating systems rather than the decision to build an entire structure. The proposed "Triple-difference" using the 2023 federal reversal is also absent.

### 2. Summary
The paper investigates whether the rejection of a national climate policy triggers subnational legislative action and subsequent shifts in the building sector. Using a continuous difference-in-differences design based on Swiss cantonal referendum results, the author finds that cantons with high support for the failed federal CO2 Act were significantly more likely to pass independent climate laws and saw a relative increase in new residential construction.

### 3. Essential Points
**1. Validity of the Outcome Variable:** The paper uses "new residential buildings per 1,000 population" as the primary real-world outcome. This is theoretically problematic. Most Swiss cantonal climate innovations (e.g., Zurich’s fossil heating ban) affect the *type* of heating system installed or renovated, not the total volume of new construction. Using construction volume as a proxy for "building stock modernization" conflates climate policy with the health of the real estate market. The author must explain why they abandoned the proposed heat pump/fossil replacement data (from BFS GWS), which is far more directly linked to the policy change.

**2. Omitted Variable Bias and the 2018 "Blip":** The event study shows a significant, large pre-period coefficient in 2018 ($t=-3$, $\beta=1.887$, $p<0.01$). This "blip" is larger than the post-treatment effect size. In a sample of only 26 units, an unexplained pre-trend of this magnitude suggests that the parallel trends assumption is violated or that a major unobserved variable (e.g., changes in cantonal zoning laws or mortgage lending rates) is driving construction in pro-climate (mostly urban/wealthy) cantons independently of the 2021 referendum.

**3. Small Sample Inference:** With only 26 clusters and a highly skewed treatment (Basel-Stadt at 66% vs. others), standard cluster-robust standard errors are likely to under-reject. While the author provides a leave-one-out analysis, a study of this size requires more rigorous permutation tests or wild cluster bootstrap p-values to confirm that the results are not driven by 1–2 influential cantons (e.g., Zurich and Basel).

### 4. Suggestions

**Refining the Outcome and Mechanism:**
*   Move back to the original plan of using heating system data. If the BFS GWS data is not available as a panel in the public API, it is often available via the "Stat-Tab" interactive tables or by request for researchers. If the author must stay with construction data, they should at least distinguish between *new* buildings and *renovations* (Umbauten), as the latter are more sensitive to climate mandates.
*   The "Construction Volume" result implies that passing a climate law *increases* total construction. This is a bold claim. Usually, stricter regulation is argued to increase costs and potentially slow construction. The author should clarify the mechanism: is it that developer certainty increased, or that these laws included subsidies that spurred new projects?

**Empirical Strategy Improvements:**
*   **The 2023 Reversal:** The manifest suggested using the 2023 Climate and Innovation Act (KlG) passage as a "reversal" shock. Adding this to the panel would allow for a much stronger "switch-on / switch-off" test of the compensatory federalism theory. If the theory holds, the divergence between cantons should flatten or narrow after June 2023.
*   **Control for House Prices/Interest Rates:** The post-2021 period coincides with significant shifts in global interest rates and Swiss real estate prices. Since pro-climate cantons are often the highest-demand real estate markets (Zurich, Geneva, Basel), the results might be picking up the "COVID-era" urban flight recovery or specific local bubble dynamics. Adding a control for cantonal-level house price indices or mortgage volumes would strengthen the paper.
*   **Spatial Autocorrelation:** Climate preferences and construction trends are likely spatially correlated. A Moran’s I test or inclusion of neighbor-weighted controls would address whether "innovation" is just spilling over from Zurich to its neighbors.

**Formatting and Presentation:**
*   **Visualizing the "Boomerang":** A simple scatter plot showing the % Yes for the CO2 Act (x-axis) vs. the date of cantonal law adoption (y-axis) would be a highly effective "smoking gun" visual for the political mechanism.
*   **Standardized Effect Sizes:** In Table 5 (Appendix), the SDE is 0.169. For an AER:Insights style paper, emphasizing the "economic significance" (i.e., how many actual buildings this represents in a typical canton like Bern) would be more impactful than normalized coefficients.

**Conclusion:**
The paper identifies a fascinating political economy phenomenon. However, the link between "voting for a carbon tax" and "building more apartment blocks" is currently the weakest part of the chain. Strengthening the outcome variables (heating systems) and addressing the 2018 pre-trend are the primary hurdles for publication.
