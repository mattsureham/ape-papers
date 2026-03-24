# V1 Empirics Check — google/gemini-3-flash-preview (Variant A)

**Model:** google/gemini-3-flash-preview
**Variant:** A
**Date:** 2026-03-18T00:36:35.308236

---

**Referee Review**

**Date:** March 20, 2024
**Journal:** AER: Insights
**Title:** The Replacement Problem: Tornado Destruction and the Permanent Loss of Manufactured Housing

---

### 1. Idea Fidelity
The paper follows the "Idea Manifest" with high fidelity regarding the core identification strategy and research question. It successfully operationalizes the NOAA tornado path width as a spatial RD running variable and focuses on the "replacement problem" of manufactured housing. However, it departs from the manifest in one critical area: the unit of analysis. While the manifest suggested a park-level analysis ("geocode all manufactured housing communities"), the paper defaults to census tract-level centroids. This shift significantly weakens the power of the RD, as tract centroids are much further from the "cutoff" (path edge) than individual park centroids would be. Consequently, the paper finds a null result for the primary outcome (mobile home share) while finding significance for a secondary outcome (vacancy).

### 2. Summary
The paper investigates whether the destruction of manufactured housing by tornadoes leads to a permanent reduction in affordable housing supply due to non-replacement (“the replacement problem”). Using a spatial regression discontinuity design based on the edges of EF2+ tornado paths, the authors find that tracts inside tornado paths experience a persistent 1.8 percentage point increase in housing vacancy rates 8–18 years post-event. While the authors suggest this reflects land being held for higher-value redevelopment, the effect on the actual stock of mobile homes is statistically insignificant at the census tract level.

### 3. Essential Points

1.  **Unit of Analysis and "Centroid" Measurement Error:** The use of tract centroids as the running variable is the paper's primary weakness. A census tract is often several miles wide, while an EF2 tornado path is measured in yards (median width $\approx$ 200–500 yards). Assigning "treatment" based on whether a tract centroid falls inside a narrow path creates massive measurement error and essentially "washes out" the RD logic. Many "control" tracts (centroid outside) likely had significant portions of their land area destroyed, and many "treated" tracts (centroid inside) likely had the destruction hit unpopulated areas. The authors **must** move to either (a) a parcel-level analysis or (b) the park-level analysis suggested in the manifest. Without a more granular unit of analysis, the null result on mobile home share is likely a type-II error due to spatial smoothing.
2.  **The "Vacant Mile" Interpretation:** The finding of increased vacancy (1.8 pp) is the only significant result, but its interpretation as "land held for redevelopment" is speculative without data on land use. High vacancy 15 years later could also indicate neighborhood decline, lack of insurance payout, or permanent out-migration. To claim this is a "replacement" mechanism, the authors must show that these specific vacant lots eventually transition to higher-value uses (e.g., using Zillow/CoreLogic transaction data or satellite-derived land cover changes).
3.  **Invalidity of the Density Test:** The paper reports a McCrary test $p$-value of 0.000 (Panel C, Table 3) and dismisses it as a "geometric artifact." In an RD, a failed density test is a red flag for the entire design. If the distribution of tract centroids is not continuous across the tornado path edge, the fundamental assumption of "as-good-as-random" assignment is violated. The authors need to investigate if tornado paths are systematically more likely to be recorded near certain geographic features (e.g., roads) that correlate with tract boundary densities.

---

### 4. Suggestions

**Identification & Specification:**
*   **Buffer Analysis over Centroids:** If the authors stick to tracts, they should use a "Continuous Intensity" or "Proportion of Area Treated" approach rather than a binary RD based on centroids. For an RD to work here, the unit must be smaller than the treatment swath.
*   **Path Geometry:** The paper buffers a straight line between start and end points. Real tornado paths are often curved or "jagged." Using the actual NOAA "damage polygons" (available for many recent storms) or more sophisticated meteorological path modeling would reduce treatment assignment error.
*   **The "Near-Miss" Control:** Instead of all tracts within 5 miles, consider matching "treated" tornadoes with "nearby" storms that didn't hit a park, or using the EF0-1 placebo more centrally as a "Difference-in-RD" to control for general storm-prone geography.

**Data & Outcomes:**
*   **The EPA/HUD MHC Dataset:** The original manifest mentioned the EPA/HUD Manufactured Housing Community dataset. Using this is essential. Mapping the ~43,000 MHCs and calculating their distance to path edges would allow for a much cleaner RD where the "park" is the unit. Did the park close? Is it still a park 10 years later? That is a binary outcome much better suited for RD.
*   **Zoning Data:** The paper mentions zoning as a mechanism. A powerful addition would be to check if the "vacancy" effect is stronger in jurisdictions with more restrictive "non-conforming use" laws (which prevent rebuilding of mobile homes after $>$50% destruction).
*   **Time-Trajectory:** Rather than just "Pre" and "Post," plot the RDD coefficient for each year relative to the tornado ($t-2, t-1, t+1...t+10$). This would confirm if the vacancy spike happens immediately and persists, or grows over time.

**Mechanism & Context:**
*   **Property Values:** You find a suggestive increase in property values. Does this correlate with the disappearance of mobile homes in those specific tracts? A mediation analysis or simple correlation of the two effects across tracts would strengthen the "gentrification" narrative.
*   **FEMA Buyouts:** Check the OpenFEMA dataset for buyout grants in these tracts. Is the "replacement" actually a government-funded retreat? This would change the policy implication from "market-driven gentrification" to "policy-driven hazard mitigation."

**Minor Points:**
*   **Table 1 Balance:** The "Mobile Home Share (pre)" is 12.65% for treated and 4.38% for control. This 8-point difference is huge and suggests the RD is not balanced, despite the $p$-value in Table 3. This mismatch likely stems from the "geometric artifact" mentioned in the density test.
*   **Visuals:** For a spatial RD, a "binned scatter plot" of the outcome vs. distance to the path edge is mandatory for an AER: Insights-style paper. Readers need to see the jump at zero.
