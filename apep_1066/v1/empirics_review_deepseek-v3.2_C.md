# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant C)

**Model:** deepseek/deepseek-v3.2
**Variant:** C
**Date:** 2026-03-27T11:59:02.810266

---

### **Review of “The Texture Penalty That Wasn’t: CROWN Act Adoptions and Black Worker Earnings”**

**1. Idea Fidelity**

The paper closely follows the original research question and data source outlined in the manifest. It uses ACS state-level data (2017-2023, excluding 2020) and a staggered adoption design to estimate the effect of CROWN Acts on Black workers’ earnings and employment. However, it **deviates significantly from the promised identification strategy**. The manifest explicitly proposed a **triple-difference (DDD) design comparing Black women (double-treated) vs. Black men (partially treated) vs. white women (placebo)**. This is a sharp, theory-driven test focusing on the group most likely affected (Black women) against two logical control groups.

Instead, the paper implements a **DDD comparing “Black workers” (pooled across sexes) to “white workers.”** This blurs the treatment’s expected heterogeneity. While the paper includes a secondary specification with a triple interaction (`CROWN × Black × Female`), this is not the same as the pre-specified, cleanly identified design. This deviation weakens the paper’s ability to detect a precise effect where it is most theoretically plausible and represents a missed opportunity to fully leverage the policy’s gendered nature.

**2. Summary**

This paper provides the first causal evaluation of state-level CROWN Acts, which prohibit hair-texture discrimination. Using a staggered triple-difference design with ACS data, it finds precisely estimated null effects on Black workers’ median earnings and employment rates. The authors conclude that this specific legal remedy, despite its symbolic importance, has not yet produced detectable aggregate labor market improvements.

**3. Essential Points**

The authors must address these three critical issues before publication:

1.  **Clarify and Justify the Core Identification Strategy:** The paper must explicitly justify why it abandoned the manifest’s more targeted DDD (Black women vs. Black men vs. white women) in favor of a pooled Black vs. white comparison. This is not a minor robustness check; it is the central test. The current approach risks dilution bias. The authors should present the results from the manifest’s specification as a primary analysis. If the pooled result is preferred, a compelling methodological or statistical reason (e.g., insufficient power in the gendered breakdown) must be provided.

2.  **Defend Standard Error Inference with Few Treated Clusters:** The analysis relies on state-level clustering (N=52). With staggered adoption, the number of *newly treated* clusters in any given post-period is small (e.g., only 3 states in 2019). This can lead to biased cluster-robust standard errors, over-rejection of the null, and potentially misleading confidence intervals. The authors correctly use randomization inference (RI) as a supplement, but they must formally address this "few treated clusters" problem. They should:
    *   Report the effective number of treated clusters per period.
    *   Implement and discuss the sensitivity of their results to alternative inference methods suitable for a small number of treated units, such as the **Conley and Taber (2011)** permutation method or **wild cluster bootstrap** procedures.
    *   Clearly state that the primary inference rests on the RI p-value, not the asymptotic cluster-robust SEs.

3.  **Strengthen the Economic Interpretation of the Null Result:** A well-identified null is a valuable result, but the discussion must move beyond generic explanations ("lack of enforcement," "coarse data"). The paper needs a more structured, evidence-based exploration of *why* the effect is null. This requires:
    *   **Testing Mechanisms:** Is it weak enforcement? The authors could examine heterogeneity by state enforcement capacity (e.g., budget of state civil rights agency, historical discrimination lawsuit rates) or by whether the state law includes a private right of action.
    *   **Addressing Measurement Directly:** If the effect is concentrated among a small subset (e.g., young Black women in professional services), state-level medians may mask it. The authors must engage with this more concretely. They should use the ACS PUMS microdata (mentioned as available) to run individual-level regressions, test for heterogeneity, and compute a **calibrated plausibility check**: What share of Black women would need to see what size earnings bump for a detectable state-level effect? This quantifies the "coarse data" critique.

**4. Suggestions**

The following recommendations would substantially improve the paper’s depth, credibility, and contribution.

**A. Empirical Analysis & Robustness**

*   **Implement the Original Design:** Run the pre-specified DDD (Black Women / Black Men / White Women) as a primary specification. A secondary DDD comparing Black Men to White Men could serve as an additional placebo test, as Black men are less targeted by hair-texture norms.
*   **Deepen the Heterogeneity Analysis:** The test by Black employment rate is a start. More informative tests include:
    *   **Occupational Heterogeneity:** Use PUMS to test if effects are larger in **customer-facing occupations** (sales, services) or **high-grooming-pressure industries** (corporate, law, hospitality) compared to blue-collar or remote-work sectors.
    *   **Age Cohort Analysis:** Effects may be strongest for **younger cohorts** (18-35) who are more likely to wear natural styles and be new labor market entrants.
    *   **Geographic Heterogeneity:** Interact treatment with local measures of **racial animus** (e.g., racial resentment survey data, historical segregation indices).
*   **Conduct a Formal Power Analysis:** Given the null result, calculate the **Minimum Detectable Effect (MDE)**. Report the smallest true effect size (in % change of earnings) that the study had 80% power to detect. This quantifies the “well-powered” claim.
*   **Event Study Diagnostics:** The negative, significant coefficient at t+3 for earnings is puzzling. Probe this. Is it driven by a particular late-adopter cohort (e.g., Texas, Michigan in 2023)? Perform a **cohort-specific analysis** or a **leave-one-cohort-out** test to see if this result is robust.
*   **Address Anticipation Effects:** Could employers or employees have changed behavior in anticipation of the law (e.g., after legislative passage but before enactment)? Check for effects in the year *before* adoption in the event study.

**B. Data & Measurement**

*   **Leverage PUMS Microdata:** The state-grouped data is a major limitation. The authors have access to PUMS. They should:
    *   Replicate the main analysis at the **individual level** with appropriate person-weighting and state-year-race-sex cell controls. This increases power and allows for richer controls.
    *   Construct a **direct measure of “likely affected” individuals.** While we cannot observe hairstyle in ACS, proxies can be built: e.g., Black women aged 18-40 in professional occupations. Estimate effects for this "high-intensity" subgroup.
    *   Examine **margins beyond employment/earnings:** Analyze effects on **hours worked**, **occupational switching**, or **industry composition**.
*   **Refine the Treatment Variable:** The paper codes treatment in the year of enactment. Check robustness to coding treatment only in **full post-enactment years** (e.g., if enacted July 2019, treatment begins in 2020).

**C. Interpretation & Context**

*   **Benchmark Against Similar Policies:** Contextualize the null effect by comparing it to estimated effect sizes from other anti-discrimination policies (e.g., initial Title VII enforcement, Ban-the-Box, sexual orientation protections). Is a null effect common for new, specific protections?
*   **Distinguish Between Extensive and Intensive Margins:** The law may not increase hiring (extensive margin) but could reduce discrimination in promotions or pay raises (intensive margin) for already-employed Black workers with natural hair. The earnings analysis should attempt to speak to this, perhaps by looking at full-time workers separately.
*   **Discuss Dynamic Effects:** The authors note this is the “first generation” of CROWN Acts. Could effects materialize as awareness grows? The discussion should explicitly frame the findings as an **early-stage evaluation** and suggest a timeline for future re-assessment.
*   **Policy Implications:** Move past “lack of enforcement” being vague. Suggest specific, testable enhancements: Are public awareness campaigns needed? Would explicit damages provisions in the law help? Should the federal government act to create a uniform standard? Ground these suggestions in the patterns (or lack thereof) observed in the heterogeneity analysis.

**D. Presentation & Clarity**

*   **Table & Figure Improvement:**
    *   **Figure 1:** Create a map of CROWN Act adoption timing.
    *   **Figure 2:** Plot the event study coefficients from Table 3 with confidence intervals. This is far easier to interpret than a table of coefficients.
    *   **Table 1:** Report the number of observations (state-cells) for each group in the summary statistics. Clarify if `Emp. Rate` is the employment-to-population ratio (as described) or an odds ratio (the very low base rate for Black women in pre-period, 0.166, suggests possible miscalculation or a different metric).
*   **Abstract & Introduction:** The abstract’s final sentence is excellent. Ensure the introduction ends with a similarly clear roadmap that previews the paper’s dual contribution: a causal null result *and* a framework for understanding why narrowly-targeted anti-discrimination laws may fail to show aggregate effects.

---

**Overall Assessment:** This paper tackles a timely, important policy question with a clean identification strategy, albeit one that diverges from its original, sharper formulation. The empirical execution is competent, and a null finding can be informative. However, for the paper to make a compelling contribution to AER: Insights, the authors must rigorously address the **Essential Points**—particularly by defending their inference with few treated clusters and providing a more economically nuanced interpretation of the null. Implementing the **Suggestions**, especially the use of microdata and a more focused heterogeneity analysis, would transform this from a competent null-result paper into a definitive study on the limits of specific anti-discrimination statutes.
