# V1 Empirics Check — google/gemini-3-flash-preview (Variant B)

**Model:** google/gemini-3-flash-preview
**Variant:** B
**Date:** 2026-03-25T12:43:15.437761

---

**Referee Report**

**Title:** The Legal Fortress: Wilderness Designation and Forest Harvesting at the Boundary  
**Paper ID:** idea_0581

---

### 1. Idea Fidelity
The paper maintains high fidelity to the original research manifest. It correctly identifies the policy (Wilderness Act of 1964) and the primary identification strategy (Spatial RDD at the boundary). It utilizes the suggested data sources (Hansen GFC, SRTM elevation, WDPA/Wilderness.net). 

However, there are two notable departures from the manifest:
1.  **Geographic Scope:** The manifest proposed an analysis of 806 wilderness areas nationwide (~555M pixels). The paper narrows this to 359 areas in the Pacific Northwest and Northern Rockies, sampling only 500,000 pixels. While this makes the analysis more tractable, it trades off the "unprecedented scale" promised in the manifest.
2.  **Secondary Outcomes:** The manifest suggested using USFS FACTS (actual timber harvest spatial data) and MTBS (fire perimeters) to separate fire-driven from harvest-driven loss. The paper acknowledges fire as a potential confounder but does not actually incorporate the MTBS data to filter the outcome, nor does it use the FACTS data to validate the mechanism.

---

### 2. Summary
This paper uses a spatial regression discontinuity design to estimate the effect of federal wilderness designation on tree cover loss in the Western United States. Exploiting the "arbitrary" political nature of congressional boundaries, the author finds that wilderness protection reduces the probability of tree cover loss by 1.1 percentage points (a 5.5% reduction). The effect is most pronounced in moderate-canopy forests, suggesting that legal protection binds most effectively on commercially marginal lands.

---

### 3. Essential Points
1.  **Identification and Covariate Balance:** The validity of the RDD is threatened by the significant discontinuity in baseline (pre-treatment) tree cover (Table 3). If the "inside" of the boundary already had lower tree cover in 2000, those pixels may inherently have different harvesting or disturbance trajectories regardless of the legal status. While the author controls for this, a 1.5 percentage point discontinuity on an outcome effect of 1.1 percentage points is concerning. The author must present a "RD plot" for baseline tree cover to show if this is a sharp jump or a local trend.
2.  **Density and Sampling Bias:** The density test (Table 3, Panel B) strongly rejects the null of continuous density ($p=0.002$). In a spatial RDD, a density jump often signals that the boundary follows a physical feature (like a road or ridge) that affects the probability of a pixel being "available" or sampled. Given that wilderness boundaries often follow Forest Service roads (which are outside the wilderness), the "outside" sample may be systematically closer to roads than the "inside" sample. This would confound "legal protection" with "physical accessibility."
3.  **Treatment of Fire:** The author admits that the Hansen GFC data conflates timber harvest with wildfire. In the Western US, wildfire is a dominant driver of tree cover loss. Since wilderness areas often have different fire management policies (e.g., "let-burn" policies), the outcome variable is extremely noisy. Without using the MTBS fire perimeters (suggested in the manifest) to mask out fires, it is impossible to know if the 1.1% effect represents a reduction in logging or just a difference in fire patterns.

---

### 4. Suggestions
1.  **Mechanism Validation:** The strongest version of this paper would use the USFS FACTS data (Spatial Data of timber sales) as a secondary outcome. If the "Fortress Effect" is real, we should see a massive discontinuity in *planned timber sales* at the boundary, which would validate the tree-loss results.
2.  **Distance to Roads:** To address Essential Point #2, the author should include "distance to nearest road" as a covariate or a running variable. If the discontinuity disappears after controlling for road proximity, the effect is driven by transport costs, not the Wilderness Act.
3.  **Visual Evidence:** The paper lacks the standard RDD visualization (binned scatter plots of tree loss vs. distance to boundary). These plots are essential for the reader to assess the "sharpness" of the discontinuity and the fit of the functional form.
4.  **Hansen Data Versioning:** The paper references Hansen v1.11 and v1.12 interchangeably. The author should stick to the most recent version and clarify if the "lossyear" includes 2024 (as the manifest suggested) or ends in 2023.
5.  **Placebo Tests:** The placebo tests at false boundaries are excellent. I suggest adding a "National Park boundary" placebo test (as suggested in the manifest). Since National Parks prohibit timber on *both* sides of their internal administrative boundaries (in most cases), there should be no jump there.
6.  **Economic Magnitude:** The author notes a 5.5% reduction. It would be helpful to translate this into "acres of forest saved" or "tons of carbon sequestered" to make the Insights-style contribution more impactful for a general economics audience.
7.  **Heterogeneity by Designation Date:** The NWPS has grown over time. A powerful test would be to look at pixels around boundaries of wilderness areas designated *after* 2001 (using a Difference-in-Discontinuities design). This would allow the author to observe the same pixel before and after the "fortress" was built.
