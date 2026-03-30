# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-30T20:38:28.255694

---

# Referee Report

## 1. Idea Fidelity

The paper closely follows the original idea manifest in its core research question, identification strategy, and data sources. It implements the proposed cross-country DiD (Belgium vs. Netherlands, Germany, Luxembourg), the cross-sector intensity variation, and the triple-difference design. The analysis uses the specified Eurostat datasets (`namq_10_a10_e`, `lc_lci_r2_q`, `nama_10_a10`) over the intended timeframe (2013–2019). The paper also incorporates the suggested robustness checks, including permutation inference and an expanded control group.

However, the paper **deviates in two notable ways** from the original manifest:
1.  **Sectoral Aggregation:** The manifest proposed analysis across "6 NACE sectors," but the paper uses 10 NACE A*10 sectors. This is a minor expansion, not a deviation in concept, but it slightly changes the intended cross-sector heterogeneity analysis.
2.  **Treatment Intensity Gradient:** The manifest emphasized a "natural intensity gradient: labor-intensive sectors face larger effective treatment." While the paper implements a triple-difference with labor share, it does not foreground this as a primary identification strategy. The results from this gradient are presented as null but could be leveraged more centrally to strengthen the design against confounding macroeconomic trends.

Overall, the paper is highly faithful to the original proposal, maintaining its core empirical approach and research question.

## 2. Summary

This paper provides the first quasi-experimental evaluation of Belgium's large (7.4 pp) 2016-2018 cut to employer social security contributions (SSCs). Exploiting Belgium's unique wage rigidities (automatic indexation, sectoral bargaining) that prevent pass-through to workers, the study uses a cross-country, cross-sector DiD design to test for employment effects. It finds a precise null result: despite a sharp first-stage reduction in non-wage labor costs, Belgian sectoral employment evolved indistinguishably from that in neighboring control countries. The paper concludes that in rigid-wage economies, such payroll tax cuts function as profit windfalls rather than job-creation tools.

## 3. Essential Points

The authors must address the following three critical issues for the paper to be publishable.

**1. The fragility of the parallel trends assumption with a small treated unit and aggregate data.** The identification rests on the assumption that Belgian sectoral employment would have trended in parallel with the (initially three) control countries absent the reform. While the event study shows no significant pre-trends, the visual "parallelism" is imperfect, and the short pre-period (13 quarters) limits power for pre-trend tests. With only one treated country and aggregate sector data, any unobserved Belgium-specific shock coinciding with the reform could bias the result. The authors must strengthen the case for parallel trends. *Suggestion:* Conduct a more rigorous assessment using (a) **synthetic control methods (SCM)** at the country level for total employment (as mentioned in the manifest but not implemented), and (b) **lead-specific placebo tests** in the triple-difference specification (interacting `Belgium × Lead_t × Labor Intensity`). If sectors with higher treatment intensity showed no differential pre-trends, this would greatly bolster the identification.

**2. Potential for aggregation bias masking heterogeneous effects.** The analysis uses 10 broad NACE A*10 sectors (e.g., "Industry," "Trade/Transport/Hospitality"). Employment responses may be heterogeneous *within* these sectors—for example, between low-margin, labor-intensive subsectors (e.g., textiles, hospitality) and high-margin, capital-intensive ones (e.g., chemicals, air transport). The null average effect could mask positive effects in the most affected firms that are diluted by no effects elsewhere. The authors must engage with this limitation directly. *Suggestion:* Acknowledge this as a key data constraint. Then, use the most disaggregated public data available (e.g., NACE 2-digit, if accessible from Eurostat) to probe for subsector heterogeneity. If microdata is inaccessible (as noted), this limitation should be prominently discussed in the interpretation, noting that the estimated *sector-level* null may not rule out firm-level responses.

**3. Incomplete evidence for the proposed mechanism (wage rigidity blocking pass-through).** The paper compellingly argues that Belgium's institutions *should* block wage pass-through, but it provides only indirect econometric evidence (Col. 3 of Table 2 shows a relative decline in Belgium's wage index, attributed to differential CPI growth). To convincingly argue that the null employment result stems from rigid wages (rather than, say, inelastic labor demand), more direct tests are needed. *Suggestion:* Perform two additional analyses: (a) Test for **differential effects on gross wages** using the national accounts compensation data (`D11`). A direct DiD on the log wage bill or average wage should show a zero effect. (b) Explore a **"second-order" prediction:** If the tax cut is a pure profit windfall, its effect might correlate with firm profitability or financial constraints. As a proxy, test for heterogeneous effects across sectors with high vs. low average profitability (using pre-reform EBITDA margins from ORBIS/AMADEUS or similar, if possible, or using sectoral gross operating surplus from Eurostat). A finding that more profitable/less constrained sectors showed even less employment response would support the windfall mechanism.

## 4. Suggestions

The following suggestions are aimed at improving the paper's clarity, robustness, and contribution. They are non-essential but would significantly strengthen the work.

**A. Empirical Strategy & Specification**
*   **Event Study Visualization:** The event study is mentioned but not shown. Include a figure plotting the `Belgium × Quarter` coefficients with confidence intervals. This is crucial for readers to assess pre-trends and the dynamic response.
*   **Standard Error Justification:** The paper clusters at the country level in the main DiD (4 clusters). This is appropriate but fragile. Explicitly justify this choice with reference to the recent DiD literature (e.g., Abadie et al., 2023). Report Conley-Taber (2007) or wild cluster bootstrap p-values as additional robustness.
*   **Triple-Difference Refinement:** The triple-difference uses a standardized continuous labor share. Consider showing results using a **binary high/low labor intensity split** (based on the median) for easier interpretation. Also, report the simple DiD for high- and low-intensity sectors separately (as in Panel B of Appendix Table SDE) in the main text to make the heterogeneity analysis more transparent.
*   **Placebo Reform Timing:** Add a placebo test where the "reform" is assumed to occur in, e.g., 2014. Estimate the model on the pre-period data (2013-Q1 to 2016-Q1) with a fake post-period. This tests whether spurious pre-existing dynamics could generate a significant coefficient.

**B. Data & Measurement**
*   **First-Stage Magnitude:** Translate the 1.75 pp reduction in the SSC share (Table 2, Col. 2) into a more intuitive metric. What was the approximate **percentage reduction in the total cost of an average worker** (including both wage and non-wage components)? This helps gauge the economic magnitude of the shock.
*   **Labor Intensity Measure:** The labor share (compensation/GVA) is a standard proxy. Acknowledge that it may correlate with other sector characteristics (e.g., tradability, exposure to foreign competition). Discuss whether this confounds the triple-difference interpretation.
*   **Control Group Composition:** The paper primarily uses NL, DE, LU. Provide a brief table comparing these countries to Belgium on key pre-reform dimensions (e.g., GDP per capita growth, unemployment trend, sectoral composition) to substantiate their suitability. The expanded control group in Column 5 is a good robustness check; discuss why the point estimate changes slightly.

**C. Interpretation & Context**
*   **The Null Result:** The paper convincingly shows a null. Dedicate a subsection to **interpreting the confidence interval**. What is the smallest positive effect the study can rule out? Compute the upper bound of a one-sided 95% CI for the main coefficient. If this upper bound is, for example, +0.02 log points, state that the study can rule out employment increases greater than ~2% relative to controls.
*   **Macroeconomic Context:** The period 2016-2019 was one of moderate growth. Discuss whether the null finding might be different in a deep recession (when labor demand may be more elastic) or a boom (when capacity constraints bind). This contextualizes the external validity of the result.
*   **Policy Counterfactual:** The reform was financed by indirect tax increases. Briefly discuss the potential general equilibrium effects. Could the demand-reducing effects of higher consumption taxes have offset the labor cost reduction? While likely secondary, acknowledging this channel shows thoroughness.
*   **Literature Dialogue:** The discussion rightly cites related studies. Sharpen the contrast: Create a small table summarizing key studies (Country, Reform Size, Wage Flexibility, Estimated Employment Elasticity) to visually position Belgium's "rigid wage, zero effect" finding within the literature.

**D. Presentation & Exposition**
*   **Title and Abstract:** The title "Cheaper Labor, Same Jobs" is clever but slightly misleading—the paper finds no *net* job creation relative to a counterfactual, not that job levels were static. Consider a more precise title like "The Employment Impact of a Large Payroll Tax Cut in a Rigid-Wage Economy: Evidence from Belgium."
*   **Flow of Results:** Reorganize Section 5 for better narrative. Suggest: 5.1 First Stage, 5.2 Main DiD Result (Table 3, Col. 1), 5.3 Event Study (Figure), 5.4 Heterogeneity by Reform Phase & Labor Intensity (Table 3, Cols. 2-4), 5.5 Robustness (Expanded Controls, Placebos, Leave-One-Out).
*   **Clarity on COVID Truncation:** The sample ends in 2019-Q4 to avoid COVID-19. State this explicitly in the main data section, not just the abstract.
*   **Appendix Utilization:** The appendices are well-structured. Consider moving the detailed permutation test description and the sector-specific results from the appendix into the main text's identification/results sections, as they are central to the inference story.

**Overall, this is a well-executed, timely, and important study.** The identification strategy is credible and well-matched to the research question. The null result is policy-relevant and contributes meaningfully to debates on tax policy and labor market institutions. Addressing the essential points will solidify the paper's causal claims, while the suggestions will enhance its rigor, clarity, and impact. I look forward to seeing a revised version.
