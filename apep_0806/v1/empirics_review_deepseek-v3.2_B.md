# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-23T12:23:40.260426

---

**Referee Report: "Capped but Not Contained: Ireland's Rent Pressure Zones and the Limits of Growth Regulation"**

**1. Idea Fidelity**

The paper largely pursues the original research question of evaluating the causal effect of Ireland's Rent Pressure Zones (RPZs) using a staggered adoption design. However, it deviates from the original idea manifest in several consequential ways:
*   **Unit of Analysis:** The manifest explicitly called for a **Local Electoral Area (LEA)-level** analysis, which is the unit of actual policy designation. The paper instead conducts the analysis at the **county level**. This aggregation loses critical within-county variation (e.g., a hot LEA in a rural county designated early vs. other LEAs in the same county not yet designated). This likely biases the estimated treatment effects toward zero and reduces statistical power.
*   **Control Group:** The manifest planned to use "never-treated through 2020" rural LEAs as a clean control. The paper correctly notes that by August 2021, *all* counties are treated, creating a "no pure never-treated" scenario. However, the chosen solution—using not-yet-treated counties as controls—is more vulnerable to anticipation effects and policy spillovers as the national rollout date approached, a threat not sufficiently explored.
*   **Mechanisms & Additional Outcomes:** The manifest proposed testing mechanisms like landlord exit via vacancy rates or supply measures. The paper is silent on these channels, focusing solely on rent levels and growth. This omission limits the policy insights regarding potential unintended consequences.

In summary, while the core empirical strategy (staggered DiD) and data source (RTB/CSO) align with the manifest, the shift to county-level analysis and the lack of mechanism tests represent significant departures that weaken the intended identification strategy.

**2. Summary**

This paper provides credible evidence that Ireland's RPZ policy, which caps annual rent increases at 4%, successfully reduced the rate of rent growth by approximately 2.4 percentage points but had no detectable effect on the level of rents. A key secondary contribution is a methodological demonstration: a standard Two-Way Fixed Effects (TWFE) estimator yields a severely biased, positive estimate of the level effect, highlighting the perils of applying TWFE to staggered rollouts with heterogeneous treatment effects.

**3. Essential Points**

The authors must address these three critical issues for the paper to be publishable.

1.  **Justify the County-Level Analysis and Address Aggregation Bias.** The policy was applied at the LEA level. The move to county-level treatment, where treatment timing is assigned based on the *first* LEA designated within a county, is a major compromise. The authors must:
    *   **Explain and justify** this choice, presumably due to data availability. A clear statement of this limitation is required.
    *   **Quantify the potential for attenuation bias.** What proportion of a county's rental stock was in designated LEAs at the assigned treatment date? If treatment is mis-measured for large parts of a "treated" county for many quarters, effects will be biased toward zero. A simple robustness check could restrict the sample to counties that were entirely designated in a single wave (if any exist) or use a continuous treatment measure (e.g., share of county population/rental stock in an RPZ).
    *   **Discuss the implications** for interpreting the null level effect. Could a true LEA-level effect be masked by this aggregation?

2.  **Grapple Seriously with the Control Group Problem Post-2021.** The national extension of RPZs in August 2021 eliminates a clean control group. The Callaway and Sant'Anna estimator uses "not-yet-treated" controls, but as the terminal treatment date nears, this group becomes small and potentially non-representative. More importantly, the *anticipation* of national rollout could have altered landlord/tenant behavior in control counties well before Q3 2021, violating the "no anticipation" assumption.
    *   The authors should conduct a **sensitivity analysis** truncating the sample period well before the 2021 national designation (e.g., end in 2020Q4). Does the estimated growth effect persist? Is it larger, given a cleaner control group?
    *   They must **discuss the potential for bias** from this design feature. If landlords in control counties expected imminent caps, they might have front-loaded rent increases, which would make the treated counties *appear* to have lower growth relative to this artificially inflated control trend. This could exaggerate the estimated treatment effect.

3.  **Explore Mechanisms and Bound Potential Unintended Consequences.** The finding of reduced growth but unchanged levels is important but incomplete for policy. The original manifest correctly identified supply-side mechanisms as crucial.
    *   The authors should use **available proxies** to test for adverse supply effects. While ideal microdata on vacancies or landlord exits may be unavailable, they could explore secondary outcomes: has the growth rate of *new rental listings* (from sources like Daft.ie) changed post-designation? Are there trends in rental property sales (a proxy for landlord exit) using CSO/Property Price Register data at the county level?
    *   Even simple **theoretical discussion and bounding calculations** would add value. If the cap reduced rent growth by 2.4 pp, what is the implied upper-bound reduction in the return on investment? Could this plausibly deter marginal new supply? Acknowledging and quantitatively scoping these potential downsides, even indirectly, is essential for a balanced policy evaluation.

**4. Suggestions**

The following recommendations would strengthen the paper but are not essential for a minimum viable revision.

*   **Robustness and Heterogeneity:**
    *   **Formal Parallel Trends Test:** Present a statistical test (e.g., joint test on pre-period leads) for the parallel trends assumption in the event-study graphs, especially for the growth outcome.
    *   **Alternative Robust Estimators:** The paper uses Callaway & Sant'Anna and Sun & Abraham. For completeness, briefly show results from other estimators like the interaction-weighted estimator of Borusyak et al. (2024) or a simple stacked regression (as in Cengiz et al., 2019) to demonstrate the result is not an artifact of one specific method.
    *   **Heterogeneity by Market Tightness:** Beyond cohort timing, explore heterogeneity by pre-treatment rent *levels* or vacancy rates (if available). Theory suggests caps bite more in tighter markets.
*   **Policy Context and Interpretation:**
    *   **Benchmark the 2.4 pp Effect:** How does this compare to other rent stabilization studies (e.g., Diamond et al. in SF, Mense et al. in Germany)? A brief comparative discussion would help situate Ireland's experience within the broader literature.
    *   **Distinguish Between Sitting and New Tenants:** The RPZ cap applies to both. The effect on aggregate rents is a mix. Can the data or institutional details shed light on whether the effect is driven by limiting increases for sitting tenants, limiting resetting of rents for new tenancies, or both? This has implications for which tenants benefit.
    *   **Discuss "Success" in Context:** The paper's tone is appropriately cautious. Further emphasize that a growth reduction is a policy "success" only relative to its stated *mechanistic* goal (capping growth). It may be a failure relative to the broader *political* goal of improving affordability, as levels remain high.
*   **Presentation and Clarity:**
    *   **Event-Study Graphs:** The main results table is clear, but dynamic event-study graphs for both level and growth outcomes are crucial for visualizing pre-trends and effect dynamics. These should be included in the main text.
    *   **Data Description:** Clarify the RTB/ESRI "standardised average rent." What is the exact standardization procedure (e.g., hedonic adjustment, fixed composition)? Reassure the reader that changing property composition within a county is not driving the results.
    *   **TWFE Discussion:** The Bacon decomposition is excellent. Consider adding a simple graphical illustration (e.g., a schematic with two cohorts showing how using the earlier-treated as a control for the later-treated biases the estimate) to make the intuition even more accessible to a broad audience.

Overall, this paper identifies a compelling policy experiment and employs appropriate modern econometric tools to address it. The core finding is policy-relevant and the methodological lesson is valuable. Addressing the essential points regarding the unit of analysis, the control group challenge, and mechanisms will significantly strengthen its contribution and credibility.
