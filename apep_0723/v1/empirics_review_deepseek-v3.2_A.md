# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-18T03:33:28.460359

---

**Referee Report**

**Paper:** “The 25 Percent Line: Did the EU’s Youth Employment Initiative Reduce NEETs?”
**Authors:** APEP Autonomous Research et al.
**Journal:** AER: Insights Format

---

### 1. Idea Fidelity

The paper faithfully executes the research plan outlined in the original Idea Manifest. The core identification strategy—a sharp geographic Regression Discontinuity Design (RDD) using the 2012 youth unemployment rate at the NUTS2 level and the legislated 25% threshold—is implemented as proposed. The paper utilizes the specified primary data sources (Eurostat tables `edat_lfse_22`, `lfst_r_lfe2emprt`, `yth_empl_110`) and examines the intended primary and secondary outcomes (NEET rates, youth employment). It incorporates the key robustness checks mentioned in the manifest, including donut-hole RDD, placebo cutoffs, covariate balance tests, and the McCrary density test. The sample size (~212 regions) aligns with the initial feasibility check. The paper’s central contribution—providing the first RDD estimate of the YEI’s impact—is clearly delivered as promised.

---

### 2. Summary

This paper provides the first quasi-experimental, regression discontinuity evaluation of the EU’s Youth Employment Initiative (YEI). Exploiting the program’s sharp eligibility cutoff at a 25% youth unemployment rate in 2012, the authors find precise null effects on regional NEET rates and youth employment. The null results are robust to a comprehensive set of sensitivity checks. The paper’s key contribution is demonstrating that this major, threshold-based allocation of EU cohesion funds did not generate a detectable labor market discontinuity at its legislative boundary, raising important questions about program design and implementation.

---

### 3. Essential Points

The authors must address the following three critical issues to strengthen the paper’s contribution and credibility:

1.  **Statistical Power and Precision of the Null:** The effective sample for the main NEET rate specification is 76 regions (43 below, 33 above the cutoff). While the confidence intervals are presented, the paper needs a formal discussion of statistical power. What is the Minimum Detectable Effect (MDE) for the primary specification? Given the context of a multi-billion euro program and the observed pre-post changes in NEET rates (e.g., a ~3.3 pp drop in treated regions), is the study powered to detect effects of a *policy-relevant* magnitude? A power calculation would help readers interpret whether the “precise null” is truly informative about policy ineffectiveness or is a function of limited identifying variation.

2.  **Dosage and the Interpretation of the RDD Estimate:** The paper correctly notes that the RDD estimates the Intent-to-Treat (ITT) effect of *eligibility* at the threshold. However, the discussion of “insufficient dosage variation” (Explanation 1) is critical and underdeveloped. The authors must more rigorously examine the “first stage” of the policy. Is there a significant discontinuity in *per-capita YEI spending* at the 25% cutoff? A fuzzy RDD using actual spending (as mentioned in the Idea Manifest but not fully executed in the paper) is essential. If the spending discontinuity is minimal, the ITT estimate will be attenuated, and the null finding speaks more to allocation design than program effectiveness. This distinction is central to the policy conclusion.

3.  **Timing of Treatment and Outcome Measurement:** The YEI ran from 2014-2023 with noted implementation lags. The primary outcome is the change from a 2010-2012 pre-period to a 2016-2019 post-period. This captures a medium-run effect but may miss later impacts, especially given slow absorption. The authors should justify this window more thoroughly. A dynamic event-study RDD framework, plotting annual effects for regions near the cutoff, would be more convincing than a single pre-post difference. It would visually establish parallel pre-trends and show if any effects emerged, faded, or were delayed. The current single-difference approach is susceptible to bias if recovery paths post-2012 were non-linear in ways correlated with the running variable.

---

### 4. Suggestions

The following suggestions are offered to improve the paper’s analysis, interpretation, and presentation.

#### A. Empirical Analysis & Robustness

*   **Implement the Fuzzy RDD:** Follow through on the original plan to use per-capita YEI spending. Estimate the first-stage discontinuity in funding and present the Local Average Treatment Effect (LATE). This directly addresses “Explanation 1” and is the most important empirical extension. Does a euro of YEI funding have a different effect than a euro of general ESF funding?
*   **Adopt an Event-Study RDD Framework:** Replace the simple pre-post difference outcome with an event-study specification. For each year (e.g., 2008-2022), estimate the RDD coefficient using the running variable, showing the discontinuity in outcomes for each year. This would provide powerful visual evidence on pre-trend stability and the evolution of any post-2014 effect. It also mitigates concerns about the arbitrary choice of the 2016-2019 post window.
*   **Deepen Heterogeneity Analysis:** The split between Southern and non-Southern Europe is a good start. Consider more policy-relevant dimensions:
    *   Split by an index of *administrative capacity* or rule of law at the country level (e.g., World Governance Indicators). The “implementation heterogeneity” explanation suggests effects might be positive in high-capacity states.
    *   Split by the *intensity of the crisis*: Compare regions just above 25% (e.g., 25-30%) to those far above (e.g., >35%). The RDD estimate is local to the threshold; discussing how it might differ for more distressed regions is important.
    *   Test for heterogeneity by the *type of YEI intervention* predominant in a region, if coarse data exists (e.g., apprenticeship-heavy vs. subsidy-heavy programs).
*   **Address Spillovers More Formally:** The spatial robustness check (excluding border regions) is good. Consider a more formal test, such as estimating a spatial RDD model that incorporates a spatial lag of the outcome or treatment variable, to quantify potential bias from spillovers.
*   **Report Bias-Corrected Estimates Prominently:** The Calonico-Cattaneo-Titiunik (CCT) robust confidence intervals are mentioned but not featured in the main results table. These should be the default inference method reported alongside the conventional estimates in Table 2.

#### B. Interpretation and Mechanisms

*   **Contextualize the Null within the ALMP Literature:** The discussion cites meta-analyses finding “mixed but on-balance positive effects.” The paper should engage more deeply with the conditions under which ALMPs, particularly for youth, fail to show effects (e.g., during deep recessions, when programs are poorly targeted, or when public employment services are weak). This would transform the null from a simple finding into a contribution to the theory of ALMP effectiveness.
*   **Clarify the Policy Counterfactual:** Emphasize that the control regions below 25% still had access to mainstream European Social Fund (ESF) support. The estimated effect is therefore of the *marginal, targeted YEI funding* over and above baseline ESF activities. This nuance is crucial for EU policymakers considering the value of dedicated, threshold-triggered budget lines versus boosting general ESF envelopes.
*   **Expand the Discussion of “Threshold Design”:** The concept of the “threshold dividend” is insightful. Elaborate on what an ideal threshold-based policy design would look like to generate a detectable RDD effect. Should future programs pair eligibility with a minimum absolute spending floor for regions crossing the cutoff? This would make the paper forward-looking for policy design.

#### C. Presentation and Clarity

*   **Visualize the Main Result:** The paper lacks a canonical RDD plot. Include a binned scatterplot of the outcome (e.g., ΔNEET rate) against the running variable, with local polynomial fits on either side of the cutoff. This is an essential piece of evidence for readers to assess the validity of the continuity assumption and the null result visually.
*   **Streamline the Robustness Section:** Table 3 is comprehensive but overwhelming. Consider moving many of these checks (e.g., all placebo cutoffs, kernel variations) to an online appendix. The main text should highlight 2-3 of the most important robustness tests (e.g., donut RDD, CCT intervals, event-study graph).
*   **Improve Table Readability:** In Table 1 (Summary Statistics), the “Difference” column should include not just the point estimate but also its standard error and/or significance stars in a separate column, maintaining a clean format.
*   **Precision in Abstract and Introduction:** The abstract states the NEET estimate is “0.03 percentage points (SE = 1.56).” Given the large standard error, it is more informative to report this as “0.03 pp (s.e. 1.56)” or “0.03 pp (95% CI: -3.0, 3.1 pp).” The latter is more intuitive for a general audience.

---
**Overall Assessment:** This is a well-executed, methodologically sound paper that addresses an important policy question with a credible identification strategy. The core finding of a null effect is convincing based on the presented evidence. Addressing the **Essential Points**—particularly regarding power, dosage, and timing—will solidify the paper’s contribution. Implementing the **Suggestions** will enhance its depth, readability, and policy relevance. In its revised form, this paper will make a valuable contribution to the literatures on EU cohesion policy, youth labor markets, and the evaluation of large-scale active labor market programs.
