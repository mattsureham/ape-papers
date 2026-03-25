# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-25T22:09:39.558691

---

**Review of "Tit-for-Tat in the Heartland: EU Retaliatory Tariffs and Local Labor Markets"**

**1. Idea Fidelity**

The paper is largely faithful to the core elements of the original Idea Manifest. It successfully pursues the primary research question—assessing the local labor market impact of the EU's politically targeted retaliatory tariffs—using the proposed identification strategy (continuous DiD with pre-tariff exposure shares) and data source (Quarterly Workforce Indicators). The analysis correctly focuses on the three targeted NAICS sectors (312, 331, 336) and implements an event study around the June 2018 policy change.

However, the paper misses or under-specifies several key elements outlined in the manifest, which weakens its execution:
*   **Outcome Variables:** The manifest specified outcomes like `FrmJbC` (firm job creation) and `EarnHirAS` (earnings of new hires). The paper uses total employment, hires, and separations but does not analyze earnings, missing a dimension of worker welfare.
*   **Sample Definition:** The manifest clearly defined the sample as "2,492 manufacturing counties" and provided exposure breakdowns. The paper's sample description is vaguer ("2,800 US counties") and Table 1 shows a large "None" exposure group (1,531 counties) that appears to include non-manufacturing counties, potentially diluting the treatment contrast and deviating from the intended design focused on manufacturing counties.
*   **Second Tranche:** The manifest notes the "Second tranche June 2020" as part of the policy context. The paper's treatment window extends to 2022Q4 but does not separately identify or discuss the effects of this second wave, a missed opportunity to study escalating retaliation.
*   **"Smoke Test" Evidence:** The manifest included compelling pre-trend evidence ("parallel pre-2018"). The paper's event study table (Table 3) is a positive step, but the supporting narrative is brief and the table's estimates for *total manufacturing employment* do not convincingly show "clean parallel pre-trends" as claimed; several pre-period coefficients are non-negligible relative to the post-effects.

**2. Summary**

This paper provides timely evidence that the EU's 2018 retaliatory tariffs, while sharply reducing employment in the directly targeted industries (e.g., bourbon, motorcycles), did not lower overall manufacturing employment in exposed US counties. Instead, the shock increased worker separations but not hires, suggesting costly within-county, within-manufacturing reallocation rather than net job destruction. The key contribution is leveraging the political logic of product targeting for identification and using high-frequency administrative data to observe dynamic adjustment.

**3. Essential Points**

The following critical issues must be addressed for the paper to be credible.

**A. The Validity of "Political Targeting" as an Exogeneity Assumption is Not Established.**
The entire identification strategy rests on the claim that product selection was based on political symbolism, making county exposure orthogonal to underlying economic trends. The paper provides only anecdotal citations (e.g., Kentucky bourbon, Wisconsin motorcycles) and a reference to media reports. This is insufficient. To credibly argue that exposure is quasi-exogenous, you must:
1.  **Formally Test the Link:** Regress county exposure on pre-trend political variables (e.g., Republican vote share, presence of senior GOP legislators, margin of victory in 2016) and economic variables (e.g., pre-2015 employment growth, industry diversification). A strong correlation with political variables and a weak correlation with economic trends would support your claim.
2.  **Address Reverse Causality:** Could economically declining counties have elected the politicians the EU wanted to target? This would violate exogeneity. Use political variables from a pre-period (e.g., 2014 or 2016 elections) to construct the instrument and discuss this potential.

**B. Failure to Account for Simultaneous, Industry-Specific US Protectionist Policies.**
This is a potentially fatal confounder. As noted in Section 4, the US imposed **Section 232 tariffs on steel (25%) and aluminum (10%) imports in March 2018**. This policy directly *benefited* the domestic primary metals industry (NAICS 331), which is a major component of your treatment. Your estimated "net effect" for steel counties conflates the negative EU retaliatory shock with a positive US protective shock. Your leave-one-out robustness check does not solve this; it merely shows the results change when you drop the confounded industry.
*   **Required Action:** You must directly disentangle these effects. Two approaches are: (1) Interact exposure with separate indicators for the EU retaliation period and the US Section 232 period, though they overlap. (2) A more convincing strategy: Exploit cross-industry variation *within* the treatment. Compare the effect in NAICS 331 (steel, subject to both shocks) to the effect in NAICS 312 (bourbon) and 336 (motorcycles), which were only hit by EU retaliation. If the negative effect is significantly attenuated or positive in 331 relative to the others, it indicates confounding. This analysis should be central, not a footnote.

**C. The Event Study Specification and Presentation Are Flawed.**
Table 3 and its interpretation undermine confidence in the parallel trends assumption.
1.  **Incorrect Outcome:** Table 3 presents event study coefficients for **Total Manufacturing Employment**, for which you find a null/slightly positive effect. The relevant test for parallel trends in your main story is for **Targeted Industry Employment**, where you find a strong negative effect. You must show the event study for the *targeted industry* outcome. The pre-trends for total manufacturing are irrelevant if workers are reallocating across industries.
2.  **Statistical Power:** Presenting a table with only a handful of selected quarters (t-12, t-8, t-4, t-2) is non-standard and raises concerns about cherry-picking. Provide a full event study plot or table with all pre-period coefficients and confidence intervals. The coefficients for t-4 (-0.031) and t-2 (-0.016) are not trivial relative to your long-run post-effect of ~0.06.
3.  **Standard Error Concerns:** With only 51 state-level clusters, your event study estimates, which involve many interaction terms, may have poorly estimated standard errors. You mention the wild cluster bootstrap; these p-values should be reported for the key event study coefficients.

**4. Suggestions**

**A. Refine Empirical Specification and Analysis:**
*   **Sample Construction:** Align with the manifest. Clearly define the analysis sample as counties with positive manufacturing employment throughout the period. Consider focusing the "control" group on low-exposure manufacturing counties rather than including counties with zero manufacturing employment ("None" group), which are structurally different.
*   **Dynamic Effects:** The event study for targeted industry employment is crucial. Plot it. Does the effect appear immediately in 2018Q3, or with a lag? Discuss the dynamics of adjustment.
*   **Heterogeneity:** The manifest categorized counties as High/Medium exposure. Explore heterogeneous effects along this dimension. Does the reallocation mechanism hold for both highly specialized and moderately exposed counties?
*   **Placebo Test:** The 2017Q1 placebo is good. Supplement with a spatial placebo test, assigning fake exposure shares based on randomized political districts.

**B. Deepen the Interpretation and Mechanism:**
*   **Reallocation Channel:** You find stable total employment but rising separations. Push further. Use the NAICS 3-digit detail of QWI to trace where separating workers from NAICS 312/331/336 go. Do they appear in other manufacturing sectors in the same county? In non-manufacturing? This would powerfully substantiate the reallocation story.
*   **Political Economy Implications:** Your conclusion that retaliation is a "signaling device" is interesting. Engage more deeply with the political economy literature. Did the localized pain you document (separations in targeted industries) generate the intended political response? A brief discussion linking to evidence on congressional statements, trade policy votes, or electoral outcomes in these districts would strengthen the paper's broader contribution.
*   **Earnings Effects:** Analyze `EarnHirAS` or similar earnings measures. Did reallocated workers experience earnings gains or losses? This speaks to the welfare cost of the shock.

**C. Improve Presentation and Robustness:**
*   **Tables and Figures:** Label all variables clearly. In Table 1, specify the time period for the means. In Table 2, the title references "Manufacturing Employment" but column (2) is "Targeted Emp"—clarify. A graphical abstract or map showing high-exposure counties would be impactful.
*   **Robustness Checks:** Beyond leave-one-out, consider:
    *   **Controlling for China Shock Exposure:** Use the Autor-Dorn-Hanson measures to ensure your exposure measure isn't correlated with prior trade shock trends.
    *   **Alternative Exposure Weighting:** Weight exposure by the national share of each industry's exports to the EU, not just employment shares.
    *   **Continuous Treatment Falsification:** Use exposure to *non*-targeted manufacturing industries as a placebo treatment.
*   **Discussion of Limitations:** Add a dedicated subsection discussing limitations, including: the potential for general equilibrium effects across counties, the inability to observe non-employment outcomes (labor force exit), and the short-to-medium-run timeframe of the analysis.

**Overall:** The paper tackles a clever and policy-relevant question with appropriate data. The core finding of reallocation versus net job loss is important. However, the current draft is not yet credible due to the **Essential Points** raised above, particularly the failure to credibly establish the exogeneity of the treatment and to address the confounding US steel tariffs. Addressing these issues rigorously is mandatory for publication. The **Suggestions** provide a pathway to strengthening the analysis and its contribution.
