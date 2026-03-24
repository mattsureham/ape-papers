# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-14T20:49:27.987480

---

**Referee Report**

**Paper:** “Deterrence Beyond Borders: Violence Reduction Units and Knife Crime Spillovers in England and Wales”

---

### 1. Idea Fidelity

The paper largely pursues the core research question outlined in the original idea manifest: it exploits the 2019 allocation of Violence Reduction Unit (VRU) funding to estimate direct effects and spatial spillovers on knife crime. It uses a staggered difference-in-differences (DiD) framework (including Callaway–Sant’Anna) and decomposes untreated forces into “boundary” and “interior” categories to test for displacement vs. deterrence.

However, the paper deviates from the original plan in several consequential ways:

*   **Data:** The manifest specified **monthly** crime counts (May 2013–Jan 2026) from `data.police.uk` for multiple categories (violent crime, possession-of-weapons, robbery, public-order). The paper instead uses **annual** ONS knife crime data (financial years 2011–2025). This change loses temporal granularity, precludes high-frequency event studies, and narrows the outcome to a single (albeit salient) category. The planned analysis of stop-and-search data is absent.
*   **Sample:** The manifest envisioned 43 forces; the paper analyzes 42 (excluding British Transport Police). More critically, the “interior” control group is reduced to a single force (Dyfed-Powys), which was foreseeable but critically undermines the spillover analysis.
*   **Identification:** The spillover strategy (boundary vs. interior) is implemented, but the extreme imbalance (21 vs. 1) makes the comparison highly fragile, a challenge not fully anticipated in the manifest.

Overall, the paper adheres to the spirit of the idea but misses key elements of the proposed data strategy, which weakens its capacity to deliver compelling causal evidence.

### 2. Summary

This paper evaluates the UK’s Violence Reduction Units, finding that the direct effect on knife crime in treated forces is not credibly identified due to selection on pre-treatment violence levels and trends. Its more novel contribution is a test for spatial spillovers, which yields a suggestive but statistically fragile negative estimate, implying possible deterrence effects rather than displacement to neighboring police force areas.

### 3. Essential Points

The following issues must be addressed for the paper to constitute a credible contribution:

1.  **The Spillover Analysis Lacks a Credible Control Group.** The classification of untreated forces yields 21 “boundary” forces and only 1 “interior” force (Dyfed-Powys). Comparing 21 units to 1 is not a viable control strategy. The estimated spillover effect is essentially the time trend in 21 forces relative to one idiosyncratic force, which could be driven by any factor differentially affecting that single comparator. The paper acknowledges this fragility via randomization inference, but this does not solve the fundamental identification problem. The spillover analysis, in its current form, cannot support a causal claim.

2.  **The Data Choice Undermines the Empirical Strategy.** The shift from the planned monthly, multi-category crime data to annual, knife-only data has serious consequences:
    *   It prevents a dynamic event-study analysis that could visually and formally assess pre-trends and effect evolution, especially in the short pre-COVID window.
    *   It reduces statistical power and limits the ability to control for seasonality or other high-frequency confounders.
    *   It abandons the opportunity to test for effects on related crime types (e.g., weapon possession, public order) that might be more immediately responsive to policing interventions, or to use them in a multiple outcomes framework.
    The authors must justify this choice and, ideally, implement the analysis with the richer, originally specified data.

3.  **The Discussion of Null Direct Effects is Incomplete.** The paper correctly concludes that the direct effect is not identified due to selection. However, it does not sufficiently engage with potential alternative strategies to address this. For example, could a regression discontinuity design be applied using the selection threshold (serious violence rates 2016–2018)? Could synthetic control methods for each treated force provide more credible case studies? At a minimum, the authors should present a formal analysis of pre-treatment trends (beyond the Callaway–Sant’Anna test) to document the divergence. A simple event-study graph (even with annual data) and a test for differences in pre-treatment slopes between treated and control groups are necessary.

### 4. Suggestions

**A. Reframe the Spillover Analysis**
The current boundary/interior decomposition is not salvageable with a single interior unit. Consider these alternatives:
*   **Distance-Based Gradient:** Model spillovers as a continuous function of distance from the nearest treated force boundary (e.g., using centroid distances or shared border length). Estimate a dose-response model for untreated forces.
*   **Concentric Rings:** For each treated force, define “buffer zones” (e.g., 0-10km, 10-20km beyond the border) using GIS shapefiles. Aggregate crime data for these rings (which may cross force boundaries) and compare trends to rings farther away. This is methodologically demanding but more robust.
*   **Alternative Control Group:** If the single interior force is untenable, consider using **second-order neighbors** (untreated forces that do not border a VRU force but border a “boundary” force) as a control for the boundary forces. This at least increases the control group size.
*   **Mechanism Test:** If stop-and-search data can be obtained (as planned), test whether changes in enforcement intensity in treated forces correlate with crime changes in neighboring untreated forces. This could provide indirect evidence of a spillover channel.

**B. Maximize Use of Available Data**
*   **Secure Monthly Data:** The manifest confirmed access to monthly crime counts. This data is essential. Use it to estimate monthly event studies, which would provide a clearer picture of pre-trends and the timing of any effects relative to the COVID disruption.
*   **Analyze Multiple Outcomes:** Report results for the other serious violence categories (robbery, weapon possession). A consistent pattern of null effects or a specific effect on knife crime only would be informative about VRU mechanisms.
*   **Incorporate Stop-and-Search:** The original plan included this. Analyze it as a secondary outcome or a mechanism. Did VRU funding change enforcement patterns?

**C. Strengthen Causal Inference for Direct Effects**
*   **Event-Study Graphs:** Present event-study coefficients (relative to year before treatment) for both the direct and spillover analyses. This is a standard requirement for DiD papers.
*   **Formal Pre-trends Tests:** Conduct placebo tests on pre-treatment periods (e.g., estimating “effects” for years before 2019) and report the results.
*   **Synthetic Control:** As a supplementary analysis, build synthetic controls for one or two major treated forces (e.g., Metropolitan Police) to provide illustrative case studies. This can complement the panel DiD.
*   **Discuss RD Feasibility:** Explore in the text whether the selection rule was based on a clear, observable cutoff. If so, an RD design might be feasible and should be noted as a direction for future research.

**D. Improve Presentation and Interpretation**
*   **Table Clarity:** In Table 1 (main results), label what “CS-DiD” and “TWFE” refer to in each column. The current notes are insufficient. Also, report the pre-treatment mean for the dependent variable in columns 2-5 for comparison.
*   **Abstract Refinement:** The abstract’s final sentence (“The results illustrate how…”) is too vague. State the concrete methodological takeaway (e.g., “The study highlights how selection on pre-treatment outcomes and limited geographic variation can thwart the evaluation of nationally rolled-out place-based programs.”).
*   **Policy Implications:** Expand the discussion on how future large-scale crime prevention programs could be designed to facilitate evaluation (e.g., phased rollout with randomization, explicit cutoffs for funding). This turns a methodological limitation into a constructive recommendation.
*   **Acknowledge Data Limitations:** Add a short subsection or paragraph explicitly justifying the use of annual ONS data over the planned monthly data, if the latter is truly unavailable. Discuss the potential implications of this choice (e.g., attenuation bias, inability to detect short-run dynamics).

**E. Minor Points**
*   The term “force-year observations” is used interchangeably with “force-year” in the text. Standardize.
*   In Table 2 (spillover), clarify what “All Forces” and “Untreated Only” specifications are testing. The note is unclear.
*   The conclusion is well-written but could be tightened by summarizing the two key findings (unidentified direct effect, insufficient evidence for spillovers) before the broader lesson.

---

**Overall Assessment:** The paper addresses an important policy question and correctly identifies a major inferential challenge (selection on pre-treatment violence). However, in its current form, its empirical contribution is limited. The spillover analysis is critically flawed, and the data choices are suboptimal. The authors have the foundation of a compelling research design but must significantly revise the empirical approach to produce credible causal estimates. The suggestions above provide a pathway for doing so.
