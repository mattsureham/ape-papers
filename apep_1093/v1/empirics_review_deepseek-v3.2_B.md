# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-27T18:15:10.414325

---

**Referee Report: “Show Me the Raise: Pay Transparency Laws and the Racial New-Hire Earnings Gap”**

Thank you for the opportunity to review this paper. It addresses a timely and important question—whether pay transparency laws reduce racial earnings disparities—using novel administrative data and a credible quasi-experimental design. The paper is generally well-structured and makes a clear case for its contribution. My assessment is structured as follows.

### 1. Idea Fidelity
The paper closely follows the original idea manifest. It uses the stipulated data source (Census QWI race-by-industry at the 3-digit NAICS level), exploits the staggered adoption of state salary-range posting mandates, and examines the Black-White new-hire earnings gap as the primary outcome. The proposed identification strategy—a staggered difference-in-differences (DiD) design, supplemented by a triple-difference (DDD) using high-pay-dispersion industries—is implemented, though the presentation of the DDD could be clearer (see Essential Points). The paper also pursues the suggested mechanism tests (industry heterogeneity) and placebo checks (separation gaps). No key elements from the manifest are missing.

### 2. Summary
This paper provides the first causal evidence that state laws mandating salary ranges in job postings reduce the Black-White earnings gap among new hires. Using county-industry-quarter data from the QWI (2018–2024) and a staggered DiD design, the author finds that these laws narrow the gap by approximately 0.9 log points on average, with stronger effects (1.4 log points) in Colorado, the earliest adopter. The effects are concentrated in industries with high pre-treatment wage dispersion, consistent with a mechanism of constraining employer discretion.

### 3. Essential Points
The following three issues are critical and must be addressed for the paper to be credible.

1.  **Identification: Clarify and Validate the Empirical Strategy**
    *   The paper must clearly define its DiD and DDD specifications. Equation (1) presents a two-way fixed effects (TWFE) DiD, but the discussion of DDD in the results (Table 1, columns 3–4 and 6) is confusing. The text states “the DDD interaction is absorbed by the county-industry fixed effects,” which is incorrect if `HighDisp` varies at the industry level. The author should specify a proper triple-interaction model (e.g., `Treated × Post × HighDisp`) and report its coefficient. The current presentation, showing `Post × HighDisp` separately, does not constitute a DDD.
    *   More importantly, **parallel trends must be demonstrated visually and tested formally**. The identifying assumption is that, absent treatment, the evolution of the Black-White earnings gap in treated states would have mirrored that in control states. The paper should present an event-study graph plotting leads and lags relative to treatment adoption. This is essential to rule out pre-existing differential trends and to assess the dynamics of the effect (e.g., whether it emerges immediately or builds over time).

2.  **Robustness to Staggered DiD Pitfalls and Sample Composition**
    *   The TWFE estimator with staggered timing can be biased in the presence of effect heterogeneity (e.g., Baker, Larcker, and Wang, 2022; Sun and Abraham, 2021). The author should at a minimum discuss this potential issue and justify the use of TWFE. Ideally, the results should be shown to be robust to alternative estimators like the Callaway and Sant’Anna (2021) approach or an interaction-weighted estimator.
    *   The sample drops 41% of observations due to data suppression (cells with zero or missing earnings for either race). This is a substantial selection. The author must more thoroughly discuss the potential for bias. For example, are suppressed cells systematically different (e.g., smaller counties, industries with fewer Black workers)? A robustness check using a balanced sample of counties or industries that consistently report data could be informative.

3.  **Interpretation of Mechanisms and Magnitude**
    *   The interpretation that effects operate through “constraining wage-setting discretion” relies on the industry heterogeneity results. However, the classification of industries into “high-dispersion” and “low-dispersion” is ad hoc (based on three example industries each). The paper should provide a systematic measure of pre-treatment wage dispersion (e.g., the interquartile range or standard deviation of new-hire earnings within each industry-state cell) and show that the treatment effect is monotonically related to this measure. The current binary split is insufficient.
    *   The economic magnitude of the effect requires clearer contextualization. A 0.9 log point reduction is equivalent to about a 0.9% reduction in the gap. The standardized effect size is reported as -0.022 SD. The author should translate this into a percentage of the mean pre-treatment gap (e.g., “this closes roughly X% of the average gap”). Comparing this magnitude to the effects of other anti-discrimination policies (e.g., ban-the-box, affirmative action) would help readers assess its importance.

### 4. Suggestions
The following recommendations are intended to strengthen the paper but are not essential for its core contribution.

*   **Literature and Context:**
    *   Engage more deeply with the literature on statistical discrimination and referral networks (e.g., Bayer, Ross, and Topa, 2008). The paper’s proposed mechanism—that posted ranges benefit groups with less access to informal salary information—directly connects to this work.
    *   Briefly discuss the potential for spillover or avoidance behaviors, such as employers in border counties adjusting practices due to neighboring states’ laws or firms listing jobs as “remote” but excluding certain states. Does the analysis implicitly capture these spillovers?
    *   The policy timeline in the Institutional Background section could be enhanced with a simple table or figure summarizing adoption dates, key provisions (e.g., employer size thresholds), and penalties.

*   **Empirical Analysis:**
    *   **Dynamic Effects:** Beyond the event-study graph, discuss whether the effect appears immediately upon implementation or grows over time (as the Colorado-only result might suggest). This has implications for policy evaluation.
    *   **Compositional Changes:** The finding of a decline in White hiring volumes warrants further exploration. Is this driven by a reduction in job postings, a change in applicant pools, or both? Could it reflect a reduction in “overqualified” applicants who previously negotiated high offers? While the within-cell design mitigates some concerns, a discussion of potential equilibrium effects on hiring composition would be valuable.
    *   **Alternative Outcomes:** Consider examining the effect on the *variance* of new-hire earnings within race groups. If transparency compresses the offer distribution, we might see a reduction in within-group inequality as well.
    *   **Placebo Tests:** In addition to the separation gap placebo, consider conducting a placebo test on the Hispanic-White gap (if data permits) as another untreated racial group. A null effect there would bolster the case that the policy specifically addresses Black-White disparities tied to historical discrimination and information gaps.

*   **Presentation and Clarity:**
    *   **Tables:** Ensure all tables are fully self-contained. Table 1’s notes should define “HighDisp.” In Table 2 (industry heterogeneity), consider adding a column for the pre-treatment mean gap or dispersion measure for each industry to help readers interpret the coefficients.
    *   **Figures:** The paper would benefit greatly from at least two figures: (1) an event-study plot as mentioned, and (2) a map showing treated and control states, which would immediately convey the geographic variation used for identification.
    *   **Writing:** Tighten the prose in the results section. For example, the sentence “Columns (1) and (2) decompose this by race, though these estimates—drawn from different samples due to differential suppression—should be interpreted cautiously” belongs in a footnote or data section.

*   **Limitations and Future Research:**
    *   Expand the discussion of limitations. The lack of individual-level controls (education, experience, occupation) is a significant constraint. Acknowledge that the estimated effect could combine a reduction in within-occupation discrimination with changes in occupational sorting. If possible, cite related work that finds pay transparency affects occupational sorting (e.g., by gender) to frame this limitation.
    *   Suggest concrete avenues for future research: e.g., using job-level data from online postings to see how stated ranges change, or linking to individual-level data to examine heterogeneous effects by worker age, education, or prior earnings.

**Overall Assessment:** This paper tackles a novel and policy-relevant question with an appropriate empirical approach. The core finding—that pay transparency laws reduce racial earnings gaps at hire—is intriguing and plausible. Addressing the three **Essential Points** is necessary to establish causal credibility and clarify the mechanisms at work. With these revisions, the paper will make a valuable contribution to the literatures on pay transparency, discrimination, and labor market policy.
