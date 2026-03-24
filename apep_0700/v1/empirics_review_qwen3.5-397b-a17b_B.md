# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-16T01:27:43.923273

---

# Referee Report

**Paper:** Frozen Out: The Local Housing Allowance Freeze and Temporary Accommodation in England
**Journal:** AER: Insights (Format)

## 1. Idea Fidelity

The paper largely pursues the core causal question outlined in the Original Idea Manifest: estimating the effect of the 2016–2020 LHA freeze on homelessness outcomes using geographic variation in LHA-rent gaps. The identification strategy (continuous DiD) and primary data sources (MHCLG, VOA) align with the proposal. However, there are notable deviations from the manifest that affect the robustness of the design. First, the sample size is significantly reduced from the proposed ~300 local authorities (LAs) to 122 LAs, with insufficient justification for the exclusion of nearly 60% of the sample. Second, the time horizon is truncated; the manifest proposed data through 2020/2022 to capture the full freeze and recovery, but the analysis ends in 2018Q1, capturing only the first half of the policy shock. Third, the proposed placebo test (homeowner homelessness) is absent, removing a key validation check for the identification strategy. Finally, while the manifest emphasized controls for Universal Credit rollout and earnings, the main specification relies primarily on fixed effects, with controls added only in robustness checks.

## 2. Summary

This paper estimates the causal impact of the 2016–2020 Local Housing Allowance (LHA) freeze on temporary accommodation (TA) placements and statutory homelessness acceptances in England. Exploiting cross-area variation in the gap between frozen benefit rates and market rents, the authors find that a 10 percentage point increase in the LHA-rent gap raised TA rates by 0.585 per 1,000 households, while formal homelessness acceptances remained unchanged. The authors transparently acknowledge significant pre-trends in TA growth, interpreting their estimates as upper bounds on the policy's causal effect.

## 3. Essential Points

The following issues must be addressed to support the causal claims made in the paper:

1.  **Pre-Trend Violation and Causal Interpretation:** The paper documents a statistically significant pre-trend ($p=0.003$) in the main outcome (TA rates), where areas with larger eventual LHA gaps already experienced faster TA growth before the freeze. This suggests that the same rental market pressures driving the gap (e.g., supply constraints, gentrification) were already driving homelessness. While the authors interpret the result as an "upper bound," this admission significantly weakens the causal claim required for *AER: Insights*. The authors must either (a) control for LA-specific linear trends to difference out these pre-existing divergences, (b) use a modern DiD estimator (e.g., Callaway & Sant'Anna, 2021) that adjusts for heterogeneous trends, or (c) provide a compelling argument for why the *acceleration* in trends post-2016 is distinct from the pre-2016 slope. Without this, the estimate may reflect omitted variable bias rather than policy impact.

2.  **Sample Selection and External Validity:** The reduction from the proposed ~300 LAs to 122 LAs is substantial. The paper states exclusions are due to "incomplete panels" or "BRMA mapping," but this risks selection bias if the excluded LAs (likely smaller, rural, or non-metropolitan authorities) differ systematically in their exposure to the freeze or homelessness trends. The authors must provide a table or map comparing included vs. excluded LAs on observable characteristics (e.g., baseline rent growth, TA rates, LHA gap). If the excluded areas have systematically lower gaps, the estimated effect may not generalize to the national population affected by the policy.

3.  **Treatment Variable Construction:** There is an inconsistency in how the treatment intensity is defined. The main text describes the gap as time-varying (growing with rent inflation post-2016), but Table 1 notes define the gap as the percentage increase from 2015–16 to *2020–21*. Since the data ends in 2018Q1, using the 2020 realized gap as the treatment intensity for the 2016–2018 period constitutes an "exposure design" using ex-post information. This is valid only if the *relative ranking* of areas by gap severity was stable over time. The authors must clarify whether the treatment variable is the *realized quarterly gap* or the *fixed ex-post maximum gap* interacted with time. If the latter, they must justify why early-period exposure is proportional to the final 2020 gap, especially given the pre-trend evidence that rent dynamics were divergent early on.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's contribution and clarity. Implementing these would significantly improve the quality of the analysis without necessarily altering the core findings.

**Strengthening Identification and Robustness**
*   **Implement Placebo Tests:** The original manifest correctly identified homeowner homelessness as an ideal placebo outcome, as homeowners are unaffected by LHA rates but exposed to the same local economic shocks. Including this test would help rule out the possibility that the results are driven by general local demand shocks correlated with rent growth. If data on homeowner homelessness is unavailable, consider using social renters *not* on LHA (if identifiable) or a demographic group ineligible for housing benefit as a falsification test.
*   **Visualize the Event Study:** The paper presents event study coefficients in a table (\Cref{tab:eventstudy}), but for *AER: Insights*, a coefficient plot with confidence intervals is standard and more informative. Plotting the dynamic effects for both TA and Acceptance rates on the same scale would allow readers to visually assess the parallel trends assumption and the divergence in post-treatment paths. Ensure the pre-period coefficients are clearly visible to assess the pre-trend violation.
*   **Control for Confounding Policies:** The 2016–2020 period coincided with the rollout of Universal Credit (UC) and the implementation of the Benefit Cap. While LA fixed effects absorb time-invariant exposure, the *pace* of UC rollout varied by LA and over time. The manifest proposed including UC rollout dates as controls. I recommend interacting the UC rollout intensity with time or including a control for the share of claimants on UC in each LA-quarter to ensure the LHA effect is not confounded by the broader welfare reform agenda.
*   **Weighting by Exposure:** The current design treats the LHA gap as the treatment intensity, but the *share* of households actually receiving LHA varies by LA. An area with a large gap but few LHA claimants should theoretically show a smaller aggregate effect. Consider weighting the regression by the baseline share of private renters on LHA in each LA, or interacting the Gap variable with this share. This would sharpen the identification by focusing variation on areas where the policy was economically relevant.

**Clarifying Data and Measurement**
*   **Resolve Treatment Definition:** As noted in the Essential Points, clarify the construction of the `Gap` variable. If using the 2020 ex-post gap to measure 2016 exposure, explicitly frame this as an "exposure design" (à la Bartik instruments) and discuss the assumption that relative market pressures were stable. If using time-varying quarterly gaps, ensure the pre-trend test is consistent with this (i.e., testing if *future* gap growth was predictable by *past* TA growth).
*   **Sample Selection Transparency:** Include a "Data Appendix" table listing the criteria for LA exclusion. Report summary statistics for the excluded LAs compared to the included sample. If possible, run a robustness check including the excluded LAs (imputing missing gaps with regional averages) to show that the results are not driven by the specific selection of 122 authorities.
*   **Outcome Measurement:** The paper uses TA *stock* (end of quarter) rather than *flows* (new placements). Stock measures accumulate over time and may reflect duration of stay rather than incidence of homelessness. If flow data is available in the P1E returns (e.g., "new households placed in TA this quarter"), prefer that as the primary outcome to better capture the immediate response to the policy shock. If stock is used, discuss how changes in TA *duration* (e.g., difficulty exiting TA due to affordability) might influence the results.

**Enhancing Policy Context and Discussion**
*   **Mechanism Discussion:** The divergence between rising TA and flat acceptances is intriguing. Expand the discussion on *why* this occurs. Is it due to the Homelessness Reduction Act (2018) shifting focus to prevention? Or is it that councils are housing people in TA *without* formal acceptance to bypass statutory duties? Qualitative evidence or references to council guidance changes during this period would enrich the economic narrative.
*   **Cost-Benefit Context:** The introduction mentions the fiscal savings of the freeze (£12 billion). The conclusion mentions the cost to local authorities (TA bills). A brief back-of-the-envelope calculation estimating the increased TA costs incurred by local authorities relative to the central government savings would powerfully illustrate the fiscal externality of the policy. This aligns well with the *AER: Insights* goal of informing policy design.
*   **Formatting for AER: Insights:** Ensure the paper adheres to the strict word count and formatting guidelines of *AER: Insights* (typically shorter than standard articles). The current draft includes extensive appendices; consider moving some robustness tables to an online appendix to keep the main text focused on the core identification and results. The abstract is well-written but should explicitly mention the pre-trend limitation to manage reader expectations immediately.

**Minor Technical Corrections**
*   **Equation Numbering:** Ensure all equations are numbered and referenced correctly in the text. Equation 2 is referenced, but the text sometimes refers to "Gap x Post" (interaction) and sometimes just "Gap" (continuous). Consistency here is vital for reproducibility.
*   **Standard Errors:** The paper clusters at the LA level. Given the treatment varies at the BRMA level (152 BRMAs vs. 122 LAs), and BRMAs cross LA boundaries, consider whether clustering at the BRMA level is more appropriate for the treatment variation, or if multi-way clustering (LA x Quarter) is needed to account for serial correlation and cross-sectional dependence.
*   **References:** Ensure all citations in the text (e.g., `\citep{callawaysantanna2021}`) are present in the `.bib` file. The draft shows placeholder citations that need to be finalized for submission.

By addressing the pre-trend concern more rigorously and clarifying the sample and treatment construction, this paper has the potential to make a significant contribution to the literature on housing policy and welfare retrenchment. The transparency regarding the limitations is commendable, but for a causal claim in a top field journal, the identification strategy must be as robust as possible.
