# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-23T10:45:29.949417

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It exploits the EGRRCPA Section 104 exemption as a natural experiment to study how reduced HMDA reporting affects racial disparities in mortgage lending. The core identification strategy—a lender-level difference-in-differences (DiD) comparing exempt vs. non-exempt institutions within the same county—is faithfully implemented. The data source (CFPB HMDA API) and key outcomes (denial rate gaps by race) align with the manifest.

However, the paper misses two elements from the original plan:
1. **Census-tract-level analysis**: The manifest proposed comparing denial gaps in high vs. low exempt-lender market share tracts, but this is absent in the paper.
2. **Donut RDD around the 500-loan threshold**: The manifest mentioned a regression discontinuity design to check for strategic bunching, but this is not pursued.

The paper also narrows the scope by focusing exclusively on denial rates (not pricing disparities, which were mentioned in the manifest) and omitting pre-2018 data (the manifest suggested extending to 2014–2017).

### 2. Summary

This paper exploits the EGRRCPA’s partial HMDA reporting exemption to test whether reduced public scrutiny widens racial disparities in mortgage lending. Using a lender-county-year DiD design, it finds that exempt lenders exhibit a 2.3 percentage point wider Black-White denial rate gap than non-exempt lenders in the same market, driven by disproportionately larger reductions in White denial rates. The effect is specific to Black-White disparities (no comparable widening for Asian-White gaps) and robust to controls, clustering, and placebo tests. The results suggest that mandatory disclosure deters discriminatory behavior, and its removal creates a "detection gap" with distributional consequences.

### 3. Essential Points

**1. Sample construction and representativeness**
- The analysis excludes counties without both exempt and non-exempt lenders, which may introduce selection bias. Exempt lenders are disproportionately rural/small-town institutions, and the paper’s focus on counties with both lender types may overrepresent urban/suburban markets. The authors should:
  - Report the share of total HMDA loans excluded by this restriction.
  - Test whether results hold in a broader sample (e.g., including counties with only exempt lenders, using a synthetic control approach).
  - Discuss external validity: Are the findings generalizable to rural markets where exempt lenders dominate?

**2. Unobserved applicant quality**
- The paper acknowledges that unobserved credit scores/wealth could confound the denial gap, but dismisses this as affecting *levels* rather than *differences*. This is insufficient. Exempt lenders may attract lower-quality applicants (e.g., due to relationship lending), and if Black applicants at exempt lenders are systematically worse on unobservables, the gap could reflect compositional differences rather than discrimination. The authors must:
  - Use a bounding exercise (e.g., Oster 2019) to assess how robust the results are to unobserved confounders.
  - Exploit the fact that exempt lenders still report *some* HMDA fields (e.g., loan amount, income) to test for differential sorting on observables (e.g., do Black applicants at exempt lenders have lower loan-to-income ratios?).

**3. Mechanism and economic significance**
- The paper argues that the wider gap at exempt lenders reflects "in-group favoritism" (relationship lending benefits flowing more to White borrowers), but this is speculative. Alternative explanations include:
  - **Regulatory arbitrage**: Exempt lenders may relax underwriting standards for all applicants, but Black applicants are more likely to be near the margin of approval (e.g., due to lower wealth), so the effect appears racially disparate.
  - **Enforcement substitution**: Exempt lenders may face less scrutiny from *other* regulators (e.g., CRA), leading to looser standards for all applicants.
- The authors should:
  - Test whether the effect is larger in markets with stronger fair-lending enforcement (e.g., high CFPB activity).
  - Examine whether exempt lenders’ denial rates for *other* minority groups (e.g., Hispanic borrowers) also widen, which would suggest a broader relaxation of standards.

### 4. Suggestions

**A. Data and Identification**
1. **Pre-trends and parallel trends**:
   - The paper lacks a formal test of parallel trends. While the event study (Table 4) is a start, it only covers 2018–2022. The authors should:
     - Extend the sample to 2014–2017 (pre-Dodd-Frank expansion) to test whether exempt and non-exempt lenders had similar trends in denial gaps before the EGRRCPA.
     - Plot pre-trends graphically (e.g., Figure 1 in Roth et al. 2023).
   - The 2018 "reference year" in the event study is problematic because the exemption was implemented mid-year. The authors should:
     - Split 2018 into pre- and post-exemption periods (e.g., before/after May 2018).
     - Test whether the effect grows over time (e.g., 2019–2022 vs. 2018).

2. **Alternative identification strategies**:
   - **Census-tract-level DiD**: As promised in the manifest, the authors should estimate:
     \[
     \text{DenyGap}_{jt} = \beta \cdot \text{ExemptShare}_{j} + \alpha_j + \gamma_t + \varepsilon_{jt},
     \]
     where \(\text{ExemptShare}_j\) is the pre-2018 share of loans in tract \(j\) from exempt lenders. This would address concerns about lender-level selection.
   - **Donut RDD**: Test for strategic bunching around the 500-loan threshold (e.g., do lenders just below the threshold have wider denial gaps than those just above?).

3. **Pricing disparities**:
   - The manifest highlighted pricing data (interest rates, loan costs), but the paper focuses solely on denial rates. The authors should:
     - Exploit the fact that exempt lenders still report *some* pricing data (e.g., loan amount) to test for disparities in approved loans (e.g., do Black borrowers at exempt lenders receive smaller loans relative to income?).
     - Use a Heckman selection model to jointly estimate denial and pricing disparities.

**B. Robustness and Heterogeneity**
1. **Lender characteristics**:
   - The paper splits lenders by size (Panel B of Table 5), but exempt lenders may differ along other dimensions (e.g., CRA rating, ownership structure). The authors should:
     - Test whether the effect is larger for lenders with "satisfactory" vs. "outstanding" CRA ratings (since the exemption requires a satisfactory rating).
     - Examine heterogeneity by lender type (banks vs. credit unions) or ownership (minority-owned vs. non-minority-owned).

2. **Borrower sorting**:
   - The paper finds that exempt lenders attract fewer Black applicants (Table 5, Panel C), but does not explore whether this reflects:
     - **Supply-side steering**: Exempt lenders discouraging Black applicants (e.g., via marketing or branch locations).
     - **Demand-side sorting**: Black applicants avoiding exempt lenders due to perceived discrimination.
   - The authors should:
     - Test whether the share of Black applicants at exempt lenders falls *after* 2018 (consistent with supply-side steering).
     - Use a two-stage model to estimate the intensive-margin effect (denial gaps) conditional on the extensive-margin effect (application sorting).

3. **Placebo tests**:
   - The Asian-White placebo test is a strength, but the authors should also:
     - Test for effects on *Hispanic*-White denial gaps (another group targeted by fair-lending enforcement).
     - Use a "fake exemption" test (e.g., assign exempt status randomly to non-exempt lenders and check for spurious effects).

**C. Interpretation and Policy Implications**
1. **Magnitude and welfare**:
   - The 2.3pp effect is economically meaningful (25% of the mean gap), but the authors should:
     - Translate this into dollar terms (e.g., how many additional Black applicants are denied per year due to the exemption?).
     - Compare the effect to other policy interventions (e.g., the impact of the CFPB’s 2013 HMDA expansion).
   - The paper argues that the exemption harms minority borrowers, but it may also benefit some (e.g., White borrowers who face lower denial rates at exempt lenders). The authors should:
     - Estimate the net welfare effect (e.g., using a structural model of lending discrimination).

2. **Policy trade-offs**:
   - The paper frames the exemption as a trade-off between compliance costs and fair-lending oversight, but the authors should:
     - Quantify the compliance cost savings (e.g., using survey data on HMDA reporting costs).
     - Compare the cost savings to the social cost of wider racial disparities (e.g., using estimates of the welfare loss from mortgage discrimination).
   - Discuss whether alternative policies could achieve the same cost savings without widening disparities (e.g., targeted exemptions for lenders with strong fair-lending records).

**D. Presentation and Clarity**
1. **Tables and figures**:
   - The event study (Table 4) is hard to interpret. The authors should:
     - Plot the coefficients graphically (e.g., Figure 2) with confidence intervals.
     - Clarify why 2018 is the reference year (it is a partial treatment year).
   - The mechanism decomposition (Table 3) is compelling but could be improved by:
     - Adding a column for the *difference* between Black and White denial rate effects (to directly test the asymmetry).
     - Reporting the implied gap (e.g., \(\hat{\beta}_{\text{White}} - \hat{\beta}_{\text{Black}} = 0.0181\)).

2. **Discussion of alternative explanations**:
   - The paper dismisses unobserved applicant quality too quickly. The authors should:
     - Add a paragraph in the discussion explicitly addressing this concern (e.g., "While we cannot rule out unobserved quality differences, the asymmetry in denial rate effects and the null Asian-White placebo suggest that discrimination is the more likely explanation.").
   - Discuss whether the results could reflect differential access to *other* data (e.g., exempt lenders may lack the technology to verify applicant information, leading to higher denial rates for Black applicants).

3. **Literature review**:
   - The paper cites the HMDA and disclosure regulation literatures, but misses key references on:
     - **Relationship lending**: Petersen and Rajan (1994), Berger and Udell (1995).
     - **Regulatory arbitrage**: Agarwal et al. (2014), Buchak et al. (2018).
     - **Fair-lending enforcement**: Ross and Yinger (2002), Bhutta and Hizmo (2021).

**E. Minor Suggestions**
- The abstract should clarify that the 2.3pp effect is the *within-county* estimate (not the raw gap).
- The introduction could better motivate why the exemption is a "natural experiment" (e.g., "The exemption was not targeted at lenders with worse fair-lending records, and its timing was exogenous to local market conditions.").
- The data appendix should include a table showing the number of lenders/counties/loans excluded by each sample restriction.
- The standardized effect sizes (Table A1) are a nice addition but could be more prominently featured (e.g., in the abstract or introduction).

### Final Assessment
This is a strong paper with a compelling identification strategy and clear policy implications. The core result—that exempt lenders exhibit wider racial denial gaps—is robust and economically meaningful. However, the authors must address concerns about sample selection, unobserved applicant quality, and alternative mechanisms before the paper is ready for publication. The suggestions above would strengthen the paper’s credibility and impact. With these revisions, it could make a valuable contribution to the literatures on disclosure regulation, lending discrimination, and financial deregulation.
