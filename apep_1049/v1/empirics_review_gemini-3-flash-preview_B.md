# V1 Empirics Check — google/gemini-3-flash-preview (Variant B)

**Model:** google/gemini-3-flash-preview
**Variant:** B
**Date:** 2026-03-27T10:21:47.591510

---

**Referee Report**

**Title:** The Substitution Illusion: Product Bans and Packaging Waste Under the EU Single-Use Plastics Directive
**Author:** APEP Autonomous Research

---

### 1. Idea Fidelity
The paper follows the original idea manifest with high fidelity. It correctly identifies the core research question (causal impact of the SUP Directive on plastic vs. paper waste), utilizes the proposed data sources (Eurostat `env_waspac` and CELLAR SPARQL), and applies the recommended staggered Difference-in-Differences (Callaway-Sant’Anna) methodology. The author successfully operationalized the "treatment intensity" and "substitution ratio" concepts mentioned in the manifest through categorical analysis and material-specific regressions.

### 2. Summary
The paper estimates the causal effect of the EU Single-Use Plastics Directive (2019/904) on packaging waste using a staggered adoption design across 27 member states. It finds a precisely estimated null effect on plastic packaging waste per capita but a marginally significant increase in paper and cardboard packaging. The study concludes that product-specific bans fail to reduce aggregate material-level plastic waste, likely due to a "targeting mismatch" where banned items represent a negligible fraction of total plastic packaging tonnage.

### 3. Essential Points
1.  **The Targeting Mismatch vs. Data Granularity:** The "null" result is the paper's headline, but there is a tension between the policy's scope and the outcome data. The SUP Directive bans items like straws and stirrers, which are arguably a rounding error in Eurostat’s `W150102` (Total Plastic Packaging) category. The paper acknowledges this as a "targeting mismatch," but it must more rigorously address whether the null result is a **policy failure** (the ban didn't work) or a **measurement limitation** (the data is too aggregate to see the success). I strongly recommend the author supplement the Eurostat data with the suggested Comtrade data (HS 3924 vs. HS 4819) mentioned in the manifest. Showing a reduction in *tableware* imports/exports specifically would prove the ban was enforced, making the aggregate null on *total* plastic packaging much more powerful.
2.  **The 2021/2022 Confounder (Post-Pandemic Recovery):** The transposition window (2021–2022) coincides exactly with the post-COVID economic rebound and the shift back to "on-the-go" consumption. While the author notes that year fixed effects absorb common shocks, the *slope* of the recovery in packaging waste might be correlated with the legislative capacity (and thus transposition timing) of member states. The author should include a specification checking if the results are robust to including "Pre-COVID (2019) Plastic Intensity × Year" fixed effects to control for differential recovery paths.
3.  **Definition of "Packaging":** There is a legal-technical issue regarding whether the items banned (straws, cutlery, plates) are even classified as "packaging" in Eurostat `env_waspac`. Under the Packaging and Packaging Waste Directive (94/62/EC), cutlery and plates are often classified as "consumer goods," not "packaging," unless they are sold filled at the point of sale. If the Eurostat data excludes the very items the directive bans, the null is mechanical. The author must clarify the Eurostat reporting boundary for these specific items.

### 4. Suggestions
*   **The Identification of "Effective Year":** The author uses a July cut-off to assign the treatment year. While standard, the paper would benefit from a sensitivity analysis using a quarterly or continuous treatment variable if available, or at least showing that the results are not sensitive to shifting the cut-off to May or September.
*   **Mechanism: The "Substitution" Evidence:** The increase in paper/cardboard (1.46 kg/person) is interesting. To strengthen this, the author could create a "Substitution Index" (Plastic/Paper ratio) as suggested in the original manifest and use it as a dependent variable. A significant drop in this ratio would be cleaner evidence of the policy working as intended at the margin.
*   **Weight vs. Count:** Plastic straws are light; paper straws are heavy. A shift from plastic to paper could show a "null" or even an "increase" in waste weight while significantly reducing the *count* of plastic items in the environment. The paper should explicitly discuss the limitations of using mass (tonnes) as the only metric for environmental success.
*   **Discussion of PPWR:** The link to the new Packaging and Packaging Waste Regulation (PPWR) is a strong suit of the paper. I suggest expanding the discussion on how the "material-level targets" in the PPWR (e.g., specific % reductions in total plastic) contrast with the "item-based bans" analyzed here. This elevates the paper from a simple evaluation to a forward-looking policy piece.
*   **Visuals:** While the tables are clear, a traditional event-study plot showing the Callaway-Sant’Anna dynamic effects for Plastic vs. Paper side-by-side would be highly effective for an *AER: Insights* style paper. The current description of the event study (Section 5.2) suggests the data is there, but the visualization is missing from the manuscript.
*   **Anticipation Effects:** The significant coefficient at $t-1$ is concerning. The author attributes this to "anticipation," but it could also suggest a violation of parallel trends. Adding a lead-in analysis for the 2018–2019 period (post-announcement but pre-Slovakia's transposition) would help distinguish between the "announcement effect" and pre-existing trends.
*   **Clustering:** Ensure that standard errors in all tables are consistently clustered at the country level, as the number of clusters (27) is right at the threshold where wild cluster bootstrap might be preferred over the multiplier bootstrap for robustness.
