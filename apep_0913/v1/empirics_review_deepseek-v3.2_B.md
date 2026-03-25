# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-25T12:44:11.836396

---

**Referee Report: “The Legal Fortress: Wilderness Designation and Forest Harvesting at the Boundary”**

**1. Idea Fidelity**

The paper departs from the original, ambitious idea in several significant ways, resulting in a substantially narrower and less compelling contribution.

*   **Sample and Scope:** The original idea proposed a spatial RDD leveraging **all 806 federally designated wilderness areas** across all 50 states. This paper restricts analysis to **359 areas in the Pacific Northwest and Northern Rockies**. This geographical restriction severely undermines the paper’s ability to speak to the “bigger” question posed in the manifest: “Is [the wilderness system] effective in a developed country with strong rule of law? The contrast with tropical-country results tests whether institutional quality moderates protected area effectiveness.” The chosen region represents the area of *highest* timber value and conflict; the estimated “legal fortress” effect may not generalize to the broader system, and the institutional quality contrast with tropical studies is lost.
*   **Outcome Measures:** The manifest specified two primary outcomes: (a) Hansen tree cover loss **and** (b) Landsat NDVI for vegetation health. The paper uses only the binary tree cover loss indicator from Hansen. The omission of the continuous NDVI measure, which could capture more nuanced changes in forest health and growth (e.g., regrowth after fire, stress), leaves the analysis one-dimensional and fails to exploit the full temporal depth (1984-2024) mentioned in the manifest.
*   **Identification Nuance:** The original idea correctly noted the need to separate fire-driven from harvest-driven loss using MTBS data and proposed a placebo test using national park boundaries. The paper acknowledges the fire confound but does not adequately address it empirically (calling it a “lower bound”). The placebo test uses arbitrary “false boundaries” instead of the more compelling institutional placebo (national park boundaries) where both sides restrict harvest.

In summary, the paper executes a technically sound but limited version of the core RDD, while leaving the broader, more novel contributions of the original idea unexplored.

**2. Summary**

This paper provides the first spatial regression discontinuity evidence on the conservation effectiveness of U.S. federal wilderness areas. Using satellite data on tree cover loss from 2001-2023 and focusing on wilderness boundaries in the Pacific Northwest, it finds a modest, marginally significant reduction in the probability of tree cover loss (1.1 percentage points, or 5.5%) on the protected side of the legal boundary. The paper interprets this as a “legal fortress” effect, demonstrating that formal legal prohibitions can causally reduce forest disturbance even in a high-income country with active timber markets.

**3. Essential Points**

The authors must convincingly address the following three critical issues:

1.  **Generalizability and Scope Creep:** The restriction to the Pacific Northwest/Northern Rockies is a major limitation that must be front-and-center in the abstract and introduction. The paper currently reads as an evaluation of the “U.S. wilderness system,” but it is not. The authors must either (a) justify this regional focus as the only relevant sample for testing the theory (e.g., arguing harvest pressure is negligible elsewhere, which is likely false) and adjust all general claims accordingly, or (b) expand the analysis to include wilderness areas in other timber-relevant regions (e.g., the Southeast, Lake States) to support a national claim. The policy relevance of a study limited to one region is far smaller.
2.  **Outcome Validity and Mechanism:** The binary “any tree cover loss” outcome is a serious weak point for causal inference. It aggregates legal harvest, illegal harvest, fire, insects, and windthrow. The key identification assumption—that *non-harvest* disturbances are continuous at the boundary—is questionable for fire. Fire regimes (suppression vs. managed wildland fire use) may differ systematically across the wilderness boundary. The authors use MTBS data in their manifest but not in the paper. They **must** conduct a robustness check using an outcome that excludes fire-related loss (e.g., masking pixels within MTBS fire perimeters) or, at minimum, show that fire perimeter data are balanced at the boundary. Without this, the estimated discontinuity could reflect differential fire management, not the prohibition on harvesting.
3.  **Statistical Significance and Design Validity:** The main result has a bias-corrected p-value of 0.063. While not a strict cutoff, it necessitates extraordinary caution. This concern is compounded by the significant discontinuity in baseline tree cover (-1.5 pp, p<0.01) and the rejected density test (p=0.002). The authors dismiss the density test as a “geometry of the sampling buffer” issue, but this is insufficient. They must demonstrate robustness by (i) using the *donut hole* approach (e.g., dropping a small interval like 0-100m on either side) to ensure the result isn’t driven by edge effects, and (ii) conducting the density test on the underlying universe of pixels, not their random sample, to rule out sampling artifacts. A fragile, marginally significant result atop these validity concerns is not a solid foundation for a causal claim.

**4. Suggestions**

*   **Expand the Data and Analysis Towards the Original Vision:**
    *   **Broaden the Sample:** Include wilderness areas in other major USFS regions (Region 8 - Southern, Region 9 - Eastern). This would greatly enhance external validity and better match the promise of evaluating the “U.S. wilderness system.”
    *   **Incorporate Landsat NDVI:** Implement the planned NDVI analysis. A complementary plot of NDVI trends (2000-2024) on either side of the boundary could reveal effects on forest health and recovery not captured by a simple loss indicator.
    *   **Execute the Institutional Placebo Test:** Test for a discontinuity at National Park boundaries (where harvest is prohibited on both sides). A null result there would powerfully reinforce that the identified effect is specific to the *change* in legal timber regime, not just any administrative boundary.
    *   **Analyze Heterogeneity as Planned:** The manifest planned heterogeneity by “USFS vs BLM” and “pre-2000 vs post-2000 designations.” These are excellent tests. Do effects differ for newer wilderness areas? Are effects on BLM land (often with different management histories) similar to USFS land?

*   **Strengthen the Empirical Execution and Presentation:**
    *   **Address Fire Confusion Directly:** Use the MTBS data to create a secondary outcome variable: “tree cover loss in non-burned pixels.” Present this alongside the main result. Discuss fire management policies (wilderness often allows natural fire regimes) as a potential moderator or confounder.
    *   **Improve Covariate Balance:** The discontinuity in baseline tree cover is troubling. While included as a control, investigate its source. Is it driven by specific wilderness areas or forest types? Consider adding other relevant, high-resolution spatial covariates from the LANDFIRE program (e.g., vegetation type, biophysical setting) to improve conditional continuity claims.
    *   **Clarify the Bandwidth and Sample:** The paper states a 5km buffer was used to sample 500,000 points, but the main analysis uses an MSE-optimal bandwidth of ~1.14km. This is fine, but the description should be precise. How was the random sample drawn? Ensure it is representative of the full buffer. A transparency table showing the number of wilderness areas and mean perimeter length contributing to the analysis would be helpful.
    *   **Refine the “Legal Fortress” Mechanism:** The heterogeneity by canopy cover is interesting. Dig deeper. Merge with data on timber suitability or accessibility (e.g., distance to roads, slope). The “fortress” should be most salient where commercial harvest is otherwise most feasible. Can you show the effect is stronger closer to existing roads?
    *   **Temper the Language:** The abstract’s “suggestive evidence” is appropriate, but the conclusion’s “the evidence is clear: the legal fortress works” is an overstatement given the marginal significance, validity concerns, and limited scope. The title “The Legal Fortress” is catchy but may over-claim; consider something more descriptive like “At the Boundary: Wilderness Designation and Reduced Tree Cover Loss in the Pacific Northwest.”

*   **Presentation and Scholarly Context:**
    *   **Discussion Section:** Expand the discussion to explicitly contrast the 5.5% effect with the tropical literature’s larger estimates. Frame this not just as “lower baseline pressure,” but theorize about the role of other overlapping regulations (e.g., ESA, forest planning) on the non-wilderness side that might already restrict harvest, thereby attenuating the *marginal* effect of wilderness designation in a high-governance setting.
    *   **Policy Implications:** The policy implications are currently vague. Be more specific. Given the modest, localized effect, what does this imply for (a) the debate over new wilderness designations (are they worth the opportunity cost?), and (b) the management of boundary-adjacent lands (e.g., should there be stronger buffers?).
    *   **Visualization:** The paper lacks a key graphical element: a clear map illustrating a few example wilderness boundaries and the sampling buffer. Additionally, a compelling RD plot (binned means with the fitted local linear function) for the main result should be in the main text, not just in an appendix.

In conclusion, the paper demonstrates a promising application of spatial RDD to an important U.S. conservation policy. However, in its current form, it falls short of the broader contribution envisioned in the original idea. By addressing the essential points—particularly on scope, outcome validity, and statistical robustness—and implementing the suggested extensions, the authors could significantly strengthen the paper into a more definitive and generalizable contribution to the literature.
