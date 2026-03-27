# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-27T13:32:08.971056

---

### 1. Idea Fidelity

The paper adheres closely to the original idea manifest. It successfully implements the proposed **county × quarter × ethnicity triple-difference design** using:
- **H-2A certification data** from DOL Foreign Labor Certification files (2018–2023) as the treatment variable.
- **Census QWI race/ethnicity panel** for outcomes (employment, earnings, separations, hires) in NAICS 11 (agriculture), with Hispanic (A2) vs. non-Hispanic (A1) comparisons.
- **Bartik shift-share IV** to address selection bias, as promised in the manifest.
- **Placebo tests** in NAICS 23 (construction) and 72 (food service), and robustness checks (e.g., COVID exclusion, state-level clustering).

The paper even exceeds the manifest’s scope by:
- Extending the analysis to earnings and labor market flows (separations/hires).
- Including an event study to probe dynamic effects.
- Providing standardized effect sizes (Appendix Table A1).

**Minor deviations**:
- The manifest proposed using 2012–2022 H-2A data, but the paper uses 2018–2023. This is justified by the focus on the steepest expansion phase, but the shorter panel weakens pre-trend tests.
- The manifest mentioned "county × quarter × ethnicity" fixed effects, but the paper uses **county × ethnicity**, **quarter × ethnicity**, and **state × quarter** fixed effects. This is a more flexible specification and is appropriate.

### 2. Summary

This paper examines whether the expansion of the H-2A guestworker program (2018–2023) displaced Hispanic domestic farm workers. Using a **triple-difference design** (county × quarter × ethnicity) and **Bartik IV** to address selection bias, the authors find:
- **Naïve OLS** suggests a 1% decline in Hispanic agricultural employment per log-unit of H-2A expansion.
- **IV estimates** reveal a precisely estimated null effect, implying that H-2A growth is driven by employer demand in counties where domestic labor is already scarce (reverse causality).
- **Placebo tests** in non-H-2A industries (construction, food service) and robustness checks support the null.

The paper’s key contribution is demonstrating that **cross-county correlations between H-2A growth and domestic employment declines reflect selection, not causation**, with implications for immigration policy debates.

---

### 3. Essential Points

The paper is well-executed and makes a credible contribution, but **three critical issues** must be addressed before publication:

#### **1. Pre-Trend Analysis is Insufficient**
- The manifest promised pre-treatment data (2012–2017), but the paper uses 2018–2023 H-2A data, leaving only 2010–2017 as a pre-period. This is problematic because:
  - The **event study** (Table 4) shows no pre-trends, but the pre-period lacks H-2A variation (treatment = 0 for all counties). This cannot test parallel trends.
  - The **Bartik IV** relies on 2018 shares, but if counties with high 2018 H-2A shares were already on divergent trends, the IV may not isolate exogenous variation.
- **Fix**: Extend the H-2A data to 2012–2023 (as in the manifest) and show:
  - A **formal parallel trends test** (e.g., event study with leads/lags) for 2012–2017.
  - **Balance tests** for pre-2018 county characteristics (e.g., Hispanic employment growth, crop acreage, mechanization) between high- and low-H-2A counties.

#### **2. Bartik IV Validity Needs Further Justification**
- The Bartik instrument assumes that **national H-2A growth** is exogenous to local labor market conditions. This is plausible but requires more defense:
  - **Potential violations**: If national H-2A growth is driven by supply-side factors (e.g., changes in sending-country conditions, visa processing backlogs), the IV may not isolate demand-pull variation.
  - **First-stage heterogeneity**: The first-stage F-statistic is implausibly high (21,000), suggesting near-perfect collinearity. This may indicate a weak instrument problem in disguise (e.g., the Bartik is mechanically linked to the treatment).
- **Fix**:
  - Show the **first-stage regression** (not just the F-statistic) to assess instrument strength.
  - Test for **heterogeneity in the first stage** (e.g., does the Bartik predict H-2A growth equally well in all counties?).
  - Discuss **alternative instruments** (e.g., crop-specific national demand shocks, interacted with county crop mix).

#### **3. Mechanism Interpretation is Overstated**
- The paper argues that **reverse causality** (H-2A growth in counties with declining domestic labor supply) explains the OLS-IV divergence. This is plausible but not the only explanation:
  - **Complementarity**: H-2A workers may complement domestic workers (e.g., by enabling farm expansion), offsetting displacement. The null could reflect a balance of substitution and complementarity.
  - **Wage effects**: The paper finds positive earnings effects (Table 2), suggesting labor market tightening. If H-2A workers raise productivity (e.g., by reducing crop spoilage), they may not displace domestic workers.
- **Fix**:
  - **Test for complementarity**: Interact H-2A growth with crop-specific mechanization indices (from USDA NASS) to see if displacement is concentrated in labor-intensive crops.
  - **Examine wage effects**: The earnings results (Table 2) are intriguing but underdeveloped. Show IV estimates for earnings and discuss whether H-2A growth raises wages (consistent with complementarity) or lowers them (consistent with substitution).
  - **Heterogeneity by skill**: If H-2A workers are lower-skilled, they may displace low-wage domestic workers but complement high-wage ones. Test this by stratifying by earnings quartiles.

---

### 4. Suggestions

#### **A. Data and Measurement**
1. **Extend H-2A data to 2012–2023**:
   - The manifest promised this, and it is feasible (DOL files are public). This would strengthen pre-trend tests and allow a longer event study.
2. **Address QWI suppression**:
   - The paper notes that 30% of Hispanic employment cells are suppressed (Table 1). This could bias results if suppression is non-random (e.g., concentrated in small counties with high H-2A growth).
   - **Suggestion**: Use **multiple imputation** or **inverse probability weighting** to account for suppression.
3. **Crop-level heterogeneity**:
   - The manifest mentioned testing heterogeneity by USDA NASS crop acreage. This is missing from the paper.
   - **Suggestion**: Interact H-2A growth with county-level shares of labor-intensive crops (e.g., fruits, vegetables) vs. mechanized crops (e.g., grains). If displacement occurs, it should be concentrated in labor-intensive crops.

#### **B. Identification**
4. **Alternative instruments**:
   - The Bartik IV is clever but may not fully isolate demand-pull variation. Consider:
     - **Crop-specific national demand shocks** (e.g., changes in global fruit prices) interacted with county crop mix.
     - **State-level H-2A policy changes** (e.g., streamlined certification in some states) as an instrument.
5. **Dynamic effects**:
   - The event study (Table 4) shows effects emerging in 2020–2021. This could reflect:
     - **COVID-19 disruptions** (e.g., domestic workers leaving agriculture for other sectors).
     - **Delayed displacement** (e.g., farms take time to adjust labor inputs).
   - **Suggestion**: Interact H-2A growth with COVID-era indicators to test whether effects are pandemic-specific.

#### **C. Mechanisms**
6. **Labor market flows**:
   - The paper finds declines in **separations and hires** (Table 2), suggesting reduced labor market churn. This could reflect:
     - **Reduced turnover**: H-2A workers may be more stable, reducing separations.
     - **Lower entry**: Domestic workers may avoid agriculture if H-2A workers dominate.
   - **Suggestion**: Decompose separations into **quits vs. layoffs** (if QWI data allow) to distinguish voluntary from involuntary displacement.
7. **Wage effects**:
   - The positive earnings effects (Table 2) are intriguing but not discussed. Possible explanations:
     - **Selection**: Remaining domestic workers may be higher-skilled.
     - **Complementarity**: H-2A workers may raise productivity, increasing wages.
   - **Suggestion**: Show IV estimates for earnings and discuss whether they align with displacement or complementarity.

#### **D. Robustness**
8. **Alternative clustering**:
   - The paper clusters at the county level, but H-2A growth may be correlated within **commuting zones** or **crop regions**.
   - **Suggestion**: Cluster at the **commuting zone level** (available in QWI) or use **Conley standard errors** for spatial correlation.
9. **Non-linear effects**:
   - The paper uses log(H-2A + 1) as the treatment. This assumes a constant elasticity, but displacement may be non-linear (e.g., only at high H-2A intensities).
   - **Suggestion**: Test for non-linearities using **binned treatment effects** or **spline regressions**.
10. **Placebo tests**:
    - The placebo tests in construction and food service (Table 5) are useful but could be strengthened:
      - **Suggestion**: Show **event studies** for the placebo industries to rule out pre-trends.
      - **Suggestion**: Test for effects in **other Hispanic-concentrated industries** (e.g., landscaping, which uses H-2B visas).

#### **E. Interpretation and Policy Implications**
11. **Generalizability**:
    - The paper focuses on 2018–2023, a period of rapid H-2A growth and COVID disruptions. The null result may not hold in other contexts (e.g., slower growth, different crops).
    - **Suggestion**: Discuss **external validity** (e.g., would the results hold in Mexico or Spain, where guestworker programs are also expanding?).
12. **Policy implications**:
    - The paper argues that **capping H-2A would not restore domestic employment**, but this assumes the null effect holds at all margins. If H-2A growth were even larger, displacement might emerge.
    - **Suggestion**: Simulate **counterfactuals** (e.g., what if H-2A growth were 50% higher?) to assess the policy relevance of the null.
13. **Comparison to prior literature**:
    - The paper cites **Rutledge et al. (2024)** for wage effects but does not engage with their findings. Rutledge et al. find that H-2A raises wages for domestic workers, which aligns with the paper’s earnings results.
    - **Suggestion**: Discuss how the **employment null** and **positive wage effects** can coexist (e.g., complementarity, selection).

#### **F. Presentation**
14. **Figures**:
    - The paper lacks **visualizations**, which would help convey key results. Suggested figures:
      - **Map of H-2A growth** by county (to show geographic variation).
      - **Event study plot** (to visualize pre-trends and dynamic effects).
      - **Binned scatterplot** of H-2A growth vs. Hispanic employment (to show non-linearities).
15. **Tables**:
    - **Table 2 (main results)**: Add a column for the **reduced-form Bartik effect** (i.e., the coefficient on the Bartik instrument in the first stage).
    - **Table 4 (event study)**: Show **leads and lags** (e.g., 2014–2017, 2018–2019, 2020–2021, 2022–2023) to better assess pre-trends.
16. **Appendix**:
    - Include **balance tests** for pre-2018 county characteristics (e.g., Hispanic employment growth, crop mix, mechanization).
    - Show **first-stage regression** for the Bartik IV.
    - Provide **replication code** (the paper is autonomously generated, so this should be feasible).

---

### Final Assessment

This is a **strong paper** with a **novel identification strategy**, **clean data**, and **compelling results**. The null finding is **policy-relevant** and challenges conventional wisdom about guestworker programs. With the **three essential fixes** (pre-trend analysis, Bartik IV validation, mechanism interpretation) and the **suggested improvements**, this paper would make an excellent contribution to *AER: Insights*.

**Recommendation**: Revise and resubmit. The core results are credible, but the pre-trend analysis and IV validity require strengthening. The suggested robustness checks and mechanism tests would further elevate the paper.
