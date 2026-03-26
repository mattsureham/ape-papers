# V1 Empirics Check — google/gemini-3-flash-preview (Variant A)

**Model:** google/gemini-3-flash-preview
**Variant:** A
**Date:** 2026-03-26T12:24:06.624210

---

This review evaluates the paper "Selective Revenge: Product-Heterogeneous Trade Hysteresis from South Korea's 2019 Anti-Japan Boycott."

### 1. Idea Fidelity
The paper maintains high fidelity to the original idea manifest. It successfully executes the triple-difference (DDD) strategy, utilizes the proposed UN Comtrade monthly data, and focuses on the core comparison between consumer and industrial goods. However, there are two notable deviations from the manifest's specific predictions:
*   **The Identification of "Substitution":** The manifest proposed using Rauch (1999) rankings to predict recovery speed (substitutability). While the paper tests Rauch classification in Table 5, it pivots its primary narrative toward "Social Visibility" (Signaling). This is a strong intellectual pivot, but it de-emphasizes the manifest’s specific "Beverages recovered/Vehicles persisted" prediction.
*   **The Cosmetics Effect:** The manifest claimed cosmetics showed "zero boycott effect." The empirical results in Table 4 actually show a significant decline for HS 33 ($\hat{\beta} = -0.522$), which contradicts the "zero effect" smoke test in the manifest. The paper reconciles this by arguing the effect is *smaller* than visible goods, but the "anomaly" is less stark than originally proposed.

### 2. Summary
The paper investigates the impact of the 2019 South Korean boycott of Japanese goods on bilateral trade using a triple-difference design at the HS 2-digit level. It finds a persistent 41% decline in Japanese consumer exports to Korea, driven primarily by "socially visible" products (e.g., beverages, vehicles) rather than private consumption (e.g., cosmetics). The study provides evidence that consumer-led trade shocks can create long-term hysteresis through the shifting of social norms and signaling motives.

### 3. Essential Points
**1. Identification of the Industrial Placebo:**
The paper uses "Industrial Goods" as a control group within Korea in the DDD. However, the catalyst for the boycott was Japan’s export controls on *industrial/semiconductor materials*. While the author correctly notes that these specific chemicals (HS 28, 29, 39) saw trade increases, the broader industrial category may be contaminated by supply-chain realignments or "Buy Korean" initiatives in the tech sector (as seen in the Samsung/SK Hynix diversification efforts). If industrial goods were also negatively affected by the trade dispute (even if not by the *boycott*), the DDD estimate for consumer goods would be an undercount. The author needs to provide a more granular event study for the industrial "control" group separately to prove it is a valid counterfactual.

**2. Product-Level Regression Validity (Table 4):**
Table 4 reports product-specific coefficients with standard errors listed as `(0.000)` and massive t-stats. This suggests a failure in the estimation code or an issue with the cluster-robust variance estimator when N is small (144 obs per product). It is highly unlikely that "Coffee/Tea" has a standard error of zero to three decimal places. Furthermore, these regressions appear to be simple DiD (Korea vs. China). Without the third difference (comparing to other products), these estimates are vulnerable to any shock affecting Japan-Korea trade generally during that window.

**3. Defining Visibility vs. Substitutability:**
The paper argues that visibility (signaling) is the dominant mechanism, yet many "visible" goods (beer, cars) also have the highest domestic substitutability in Korea. Conversely, "private" goods like cosmetics often have extremely high brand loyalty (low substitutability). To convincingly claim the mechanism is *signaling*, the author must control for domestic substitute availability (e.g., using Korean production data or import penetration ratios) to ensure "Visibility" isn't just a proxy for "Ease of Switching."

### 4. Suggestions
*   **The Cosmetics Paradox:** In the manifest, cosmetics grew. In the paper, they fell 31% (Table 5). This discrepancy needs a more honest treatment. Is it possible that the *type* of cosmetics matters? High-end (SK-II) vs. mass-market (DHC)? If the HS 2-digit data is too blunt, the author might look at HS 4-digit or 6-digit data for a few key chapters to strengthen the "Signaling" argument.
*   **Constructing the Visibility Index:** The classification of "Visible" vs. "Private" in Section 5.3 feels slightly arbitrary. I suggest using a pre-existing classification from the literature on conspicuous consumption (e.g., Heffetz, 2011) to avoid the appearance of "data mining" the categories to fit the hypothesis.
*   **The China Control Group:** China is a large and volatile trade partner. Could the results be driven by China increasing imports of Japanese consumer goods for reasons unrelated to Korea? The author should check if the results hold using a "Rest of World" or "Taiwan" control group to ensure Chinese domestic policy shifts in 2019 aren't inflating the DDD coefficient.
*   **Aggregation Bias:** HS 2-digit (97 categories) is quite coarse. HS 4-digit would significantly increase the power and allow for more precise BEC (Broad Economic Category) mapping. For an *AER: Insights* style paper, the current HS 2-digit focus is acceptable only if the results are remarkably robust.
*   **Hysteresis or Supply Exit?** The paper frames the persistence as a shift in "social norms." However, it could also be that Japanese firms (e.g., Nissan, which exited the Korean market in 2020) simply gave up on the market. Distinguishing between a "demand-side" norm shift and a "supply-side" exit would strengthen the Discussion section.
*   **Specific Table Fixes:** In Table 4, provide the actual Standard Errors. If the SEs are truly that small, investigate the source of the variation. Also, provide the Mean of the dependent variable for the treated group in the pre-period to help the reader gauge the economic significance of the log-point declines.
*   **The Rauch Classification:** In Table 5, the difference between Differentiated (-0.59) and Homogeneous (-0.45) is statistically small. This suggests the Rauch classification (developed for supply-side search costs) might not be the right tool for consumer boycotts. The author could instead look at "Brand Equity" or advertising intensity by product category.
