# V1 Empirics Check — google/gemini-3-flash-preview (Variant C)

**Model:** google/gemini-3-flash-preview
**Variant:** C
**Date:** 2026-03-25T13:05:00.889404

---

This review evaluates the paper "Dissolving the Monopoly? Alkaline Hydrolysis Legalization and Market Expansion in U.S. Funeral Services" following the AER: Insights format.

### 1. Idea Fidelity
The paper closely follows the original idea manifest. It successfully operationalizes the staggered DiD approach using the BLS QCEW data (NAICS 812210 and 812220) as proposed. It centers the identification on the Callaway-Sant’Anna (2021) estimator to handle the staggered rollout across 23 states. One minor deviation is the panel window: while the manifest suggests data back to 1990 (bulk files), the paper restricts its primary analysis to 2014–2023. This is a reasonable trade-off for data consistency but limits the number of "treated" units in the estimation window, as 13 states are relegated to "always treated" status.

### 2. Summary
The paper investigates the impact of legalizing alkaline hydrolysis (AH) on the funeral services industry structure. Contrary to the expectation that a lower-cost technology would disrupt incumbents, the author finds that AH legalization leads to a 4.6% increase in industry employment and a rise in establishment counts, suggesting "market expansion" rather than "competitive displacement."

### 3. Essential Points

*   **Plausibility of Magnitudes and Entry Costs:** The paper finds an increase of ~9 establishments per state and a 4.6% jump in employment. However, AH machines (resomators) are capital-intensive (often costing \$150k–\$400k) and require specialized plumbing/permitting. The result that employment rises *immediately* (1.5% at $t=0$) is surprising. You must clarify if this is driven by incumbents hiring in anticipation/adoption or by new entrants. If the latter, the speed of entry seems high for such a regulated, capital-heavy industry.
*   **The Wage Pre-trend:** The event study (Table 3) shows a significant negative pre-trend for $\ln(Wage)$ at $t-5$ and $t-4$. This suggests that states legalizing AH were on a different wage trajectory (perhaps struggling economically) compared to controls. Since the post-treatment wage effect (2.6%) is only marginally significant and potentially a recovery from this dip, the wage results are currently the weakest link and should likely be de-emphasized or better instrumented.
*   **Treatment of "Always-Treated" States:** By starting the panel in 2014, the 13 states that legalized early (2003–2014) are excluded from the ATT. However, these "early adopters" might be fundamentally different from "late adopters" (e.g., more secular or environmentally conscious). The paper should at least include a robustness check using the full 2003–2023 period (via bulk files) to ensure the 2017–2023 cohorts are representative of the AH effect generally.

### 4. Suggestions

**Econometric Refinements:**
*   **Weighting:** In the county-level analysis, consider weighting by county population or total employment. Funeral homes are distributed roughly by "death density." An unweighted regression might over-represent small rural counties where an "increase of 0.19 establishments" is mostly noise.
*   **Standard Errors:** State-level clustering is appropriate. However, since you have only 39–40 "units" (states) in the state-level employment/wage regressions, you are near the borderline where cluster-robust standard errors can be downward biased. Consider reporting Wild Cluster Bootstrap p-values for the state-level outcomes to ensure the 4.6% employment effect is robust.
*   **The CS-DiD Control Choice:** You use "not-yet-treated" as the command. Ensure that the "always-treated" states are truly excluded from the donor pool, as their inclusion can sometimes contaminate the counterfactual if there are long-run dynamic effects from 2003.

**Mechanism and Interpretation:**
*   **Decomposing 812210:** The QCEW does not distinguish between an AH provider and a traditional funeral home. You argue for "market expansion." To strengthen this, check if the effect is larger in states where "direct disposal" (cremation without service) was already high. If AH is a "green" alternative to cremation, the lack of substitution in 812220 is fascinating and suggests AH is pulling from the "burial" segment or creating a new "premium green service" tier.
*   **The "Grief Premium" Language:** You use the term "grief premium" effectively, but the paper lacks price data. Since QCEW only gives wages/employment, I suggest looking at the **Census Bureau’s Service Annual Survey (SAS)** or the **Economic Census (every 5 years)** which provides "Revenue" for NAICS 812210. Linking legalization to a change in revenue-per-establishment would provide a more direct test of the competitive discipline hypothesis.
*   **Death Rates as a Control:** While aggregate year-FE handles national shocks, state-level death rates (available from CDC NVSS) vary due to aging populations and COVID-19. Including log(deaths) as a covariate (or using it to normalize employment) would account for the "exogenous demand" mentioned in your background.

**Minor Notes:**
*   Table 3 ($t-5$ and $t+5$ bins): State if these are "mutilated" (endpoints) or specific years. 
*   In the Discussion, the "Industry Adaptation" mechanism is the most plausible. Most AH units are sold to existing funeral directors. If an existing home adds an AH machine, it doesn't create a new establishment but might increase employment. The fact that *establishments* increased suggests de novo entry, which contradicts the adaptation story. Reconciling these two would be beneficial.
