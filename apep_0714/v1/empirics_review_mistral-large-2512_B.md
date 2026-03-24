# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-17T17:32:52.072528

---

### 1. Idea Fidelity

The paper closely adheres to the original manifest, pursuing the core research question of whether automatic marijuana expungement improves Black labor market outcomes beyond the effects of legalization alone. Key elements of the identification strategy—including the use of the QWI race panel, the triple-difference framework (though simplified to a double-difference in the paper), and the comparison between expunge and legalize-only states—are faithfully implemented. The paper also correctly identifies the novel contribution relative to prior work (e.g., Anderson 2023) and leverages the staggered adoption of expungement laws as planned.

Two minor deviations are worth noting:
- The manifest proposed a **triple-difference (DDD)** design (Expunge × Black × Post), but the paper uses a **double-difference (DD)** approach (Expunge × Post) with race-specific outcomes. This simplification is reasonable given the QWI’s race-disaggregated data, but the paper should clarify why DDD was not implemented (e.g., potential power issues or collinearity with fixed effects).
- The manifest mentioned a "smoke test" showing parallel pre-trends in California and Colorado, but the paper does not include a formal pre-trends test for all states. The event study in Table 3 partially addresses this, but a more comprehensive pre-trends analysis (e.g., joint significance tests) would strengthen the case for parallel trends.

### 2. Summary

This paper provides the first causal evidence that automatic marijuana expungement—proactively clearing prior convictions without requiring individual petitions—raises Black workers’ earnings by 6.8% relative to states that legalized marijuana without expungement. Using the Census LEHD Quarterly Workforce Indicators (QWI) race panel, the authors compare five expunge states (CA, IL, NJ, VA, NY) to four legalize-only states (CO, WA, OR, AK) and find that expungement disproportionately benefits Black workers, narrowing the racial earnings gap. The results are robust to sample restrictions and suggest that legalization alone is insufficient to address the labor market barriers posed by prior convictions.

### 3. Essential Points

**1. Clarify the identification strategy and counterfactual.**
   - The paper uses a DD design comparing expunge states to legalize-only states, but the manifest proposed a DDD design. While the DD approach is valid, the paper should explicitly justify why DDD was not used (e.g., "We estimate race-specific models to avoid collinearity between the Black × Post interaction and race-quarter fixed effects").
   - The counterfactual (legalize-only states) is appropriate, but the paper should address whether these states are comparable in other dimensions (e.g., labor market conditions, racial composition, or pre-existing trends in earnings). For example, Colorado and Washington legalized earlier and may have had more mature cannabis markets, which could confound the comparison. The inclusion of state-year fixed effects helps, but the paper should discuss whether residual differences in market development could bias the estimates.

**2. Strengthen the pre-trends analysis.**
   - The event study in Table 3 shows flat pre-trends for Black employment in expunge states, but this does not test whether pre-trends were parallel *between* expunge and legalize-only states. The paper should include a formal test of pre-trends (e.g., a regression of outcomes on leads of the treatment variable) to rule out differential trends.
   - The manifest’s "smoke test" suggested parallel pre-trends in California and Colorado, but the paper does not replicate this for all states. A figure showing pre-trends for Black and White earnings in both groups of states would be helpful.

**3. Address potential mechanisms and alternative explanations.**
   - The paper interprets the combination of lower employment and higher earnings as evidence of a "job quality upgrade," but this is speculative. Alternative explanations include:
     - **Compositional effects:** Expungement may have led to a shift from informal to formal employment, reducing measured employment in QWI (which only covers formal private-sector jobs) while increasing earnings.
     - **Labor supply effects:** Workers with expunged records may have reduced their labor supply (e.g., by exiting low-wage jobs) while those remaining in the formal sector earned more.
     - **Concurrent policies:** Illinois and New York implemented other criminal justice reforms (e.g., bail reform) during the study period. The paper should discuss whether these could confound the results and test robustness to excluding these states.
   - The paper should also discuss whether the earnings effect is driven by specific industries (e.g., cannabis-related jobs) or is more general. A heterogeneity analysis by industry would be informative.

### 4. Suggestions

**Data and Measurement:**
- **Expand the sample:** The paper restricts the sample to counties with ≥50% non-missing data in the pre-period. This could introduce selection bias if missingness is correlated with expungement status or labor market conditions. The paper should test robustness to alternative missing-data thresholds (e.g., ≥30% or ≥70%) or use multiple imputation for missing values.
- **Address QWI limitations:** The QWI does not cover informal employment or public-sector jobs. The paper should discuss how this might bias the results (e.g., if expungement primarily affects transitions from informal to formal work) and consider supplementing the analysis with alternative data sources (e.g., CPS or ACS) if feasible.
- **Clarify outcome definitions:** The paper uses "average monthly earnings" (EarnS) and "employment" (Emp) from QWI but does not explain how these are constructed (e.g., whether they include part-time workers or are annualized). A brief description in the data section would be helpful.

**Empirical Strategy:**
- **Test for dynamic effects:** The event study in Table 3 suggests that the earnings effect grows over time. The paper should explore whether the effect is persistent or fades (e.g., by estimating effects 2+ years post-expunge).
- **Heterogeneity analysis:** The paper should test whether the effect varies by:
  - **County characteristics:** Urban vs. rural, racial composition, or pre-existing marijuana arrest rates.
  - **State-level factors:** The timing of retail legalization relative to expungement (e.g., California’s expungement preceded retail sales by a year, while New York’s expungement and retail sales were nearly simultaneous).
  - **Worker characteristics:** Age, sex, or education (if available in QWI).
- **Alternative specifications:** The paper should consider:
  - A **synthetic control** approach to construct a more comparable counterfactual for expunge states.
  - A **placebo test** using never-legalized states as a "fake" treatment group to assess whether the results are driven by spurious trends.

**Mechanisms:**
- **Background check data:** The paper could strengthen its mechanism discussion by citing evidence on how expungement affects background check outcomes (e.g., studies showing that expungement reduces the likelihood of a "hit" in employer background checks).
- **Job applications:** If possible, the paper could use data on job applications or callbacks (e.g., from audit studies) to test whether expungement improves hiring outcomes for Black workers.
- **Industry-specific effects:** The paper should test whether the earnings effect is concentrated in industries with high background-check requirements (e.g., healthcare, education, or finance) or in the cannabis industry itself.

**Robustness:**
- **Exclude early legalizers:** Colorado and Washington legalized in 2014, while expunge states legalized later (2018–2022). The paper should test robustness to excluding these early legalizers and using only Oregon and Alaska as the comparison group.
- **Alternative clustering:** The paper clusters standard errors at the state level, but expungement laws may have county-specific effects (e.g., due to variation in enforcement or court processing times). The paper should test robustness to clustering at the county level or using wild bootstrap methods.
- **Falsification tests:** The paper should conduct falsification tests using outcomes that should not be affected by expungement (e.g., White employment in never-legalized states or pre-treatment outcomes in expunge states).

**Interpretation and Policy Implications:**
- **Generalizability:** The paper should discuss whether the results are likely to generalize to other types of expungement (e.g., for non-drug offenses) or to states with different labor market conditions.
- **Policy trade-offs:** The paper could briefly discuss the costs of automatic expungement (e.g., administrative burden on courts) and whether these are justified by the labor market benefits.
- **Comparison to petition-based expungement:** The paper focuses on automatic expungement but could compare its effects to those of petition-based systems (e.g., by including states that later adopted petition-based expungement as an additional comparison group).

**Presentation:**
- **Figures:** The paper would benefit from figures showing:
  - Pre-trends in Black and White earnings for expunge vs. legalize-only states (to complement the event study).
  - A map of expunge and legalize-only states to visualize the geographic variation.
  - The event study coefficients with confidence intervals (currently only in Table 3).
- **Tables:** The paper should include a table summarizing the key policy dates and sample sizes for each state to help readers assess the staggered adoption design.
- **Clarify the "job quality upgrade" mechanism:** The paper’s interpretation of the employment-earnings pattern is plausible but could be strengthened by citing literature on labor market segmentation (e.g., formal vs. informal work) or employer screening practices.

**Minor Issues:**
- **Typo in Table 1:** The "Retail Legal" date for New York is listed as "Dec 2022," but the text and manifest state "March 2021." This should be corrected.
- **JEL codes:** The paper includes J15 (Economics of Minorities, Races, Indigenous Peoples, and Immigrants) and I28 (Education: Government Policy), but I28 seems less relevant. Consider replacing it with J71 (Labor Discrimination) or K14 (Criminal Law).
- **Abstract:** The abstract states that the earnings effect is "6.8 percent (p<0.001)" but does not mention the standard error or confidence interval. Including these would strengthen the abstract.

### Overall Assessment

This is a well-executed paper with a compelling research design and important policy implications. The core finding—that automatic expungement raises Black earnings beyond the effects of legalization alone—is novel and robust. With minor revisions to address the essential points above (particularly the pre-trends analysis and mechanism discussion), the paper would make a strong contribution to the literature on criminal records, racial labor market disparities, and policy evaluation. The suggestions provided are intended to further strengthen the paper’s credibility and impact.
