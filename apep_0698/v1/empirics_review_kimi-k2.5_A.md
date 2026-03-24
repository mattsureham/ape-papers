# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-16T00:27:17.246308

---

 **Referee Report**

**Manuscript:** "The Missing Threshold: PPP Eligibility Rules and Nonprofit Employment"  
**Authors:** APEP Autonomous Research et al.  
**Journal:** AER: Insights (targeted)  
**Recommendation:** Revise and Resubmit

---

### 1. Idea Fidelity

The paper pursues the core empirical agenda outlined in the manifest—linking SBA PPP microdata to IRS Form 990 filings and implementing an RDD at the 25% revenue decline threshold for Second Draw loans. However, the realized paper departs from the manifest in one critical respect: rather than estimating treatment effects leveraging a binding eligibility rule, the authors discover (correctly) that the threshold generated no discontinuity in the nonprofit sector because the statutory quarterly requirement mapped poorly onto annual Form 990 reporting. 

The manuscript omits the supplementary IV strategy mentioned in the manifest (the April 16, 2020 Round 1 funding exhaustion as an instrument). Given that the RDD yields a precisely estimated zero first stage, the absence of this alternative identification strategy is a material omission. The paper also shifts emphasis from estimating causal effects to documenting selection—a defensible pivot given the data, but one that requires reframing of the research design section.

---

### 2. Summary

This paper links SBA PPP loan records to IRS Form 990 filings for 158,000 nonprofit organizations and tests whether the 25% quarterly revenue decline threshold for Second Draw eligibility created a binding constraint. The authors find a precisely estimated null first stage: organizations just above and below the threshold (proxied by annual revenue changes) were equally likely to receive loans, rendering the threshold "invisible" in nonprofit administrative data. While conditional correlations suggest PPP recipients had higher post-pandemic employment, pre-treatment placebo tests reveal identical "effects" in 2018, indicating severe selection on unobservables. The paper concludes that program design failed to account for the annual reporting cycle of the nonprofit sector.

---

### 3. Essential Points

**1. The "Invisible Threshold" vs. Attenuation Bias.**  
The paper interprets the null first stage as evidence that the quarterly threshold was "invisible" to annual reporters. However, the empirical design cannot distinguish between (a) a structural break where the threshold truly didn't bind because nonprofits used alternative quarterly documentation, and (b) classical measurement error attenuating a true first stage toward zero. If annual revenue decline is merely a noisy proxy for quarterly decline, the RDD estimates are biased toward zero, but the threshold might still have been binding in the underlying quarterly data. The authors must clarify whether the issue is that (i) the threshold was mechanically irrelevant because nonprofits could qualify via other means, or (ii) the research design simply lacks power due to measurement error. If (i), the paper should provide direct evidence from loan applications or SBA guidance showing that annual revenue was never used for eligibility determinations. If (ii), the paper should bound the degree of attenuation or acknowledge that the null could reflect noise rather than a genuinely non-binding rule.

**2. What Do We Learn from a Failed RDD?**  
The pivot to describing selection patterns is valuable but under-theorized. The pre-treatment placebo (2018 employment) is a powerful specification check, but the paper treats it as the "main result" rather than a diagnostic. Since the RDD fails, the OLS associations cannot support causal claims, yet the abstract and introduction emphasize the conditional correlations. The authors must clarify the paper's contribution: is it (a) a program evaluation that found no effect because the program was poorly targeted, or (b) a measurement paper documenting administrative data mismatches? Currently, it tries to be both without fully committing to either. If (a), the authors need to quantify the economic importance of the null (e.g., "we can rule out employment declines larger than X%"). If (b), the paper should expand the discussion of program design implications and potentially compare nonprofit vs. for-profit targeting efficiency using parallel data structures.

**3. External Validity of the Matched Sample.**  
The 45% match rate between PPP records and Form 990 filings raises serious external validity concerns. The paper notes the match rate reflects size and filing requirements but does not demonstrate that the matched sample is representative of the $67 billion in nonprofit PPP disbursements. If the unmatched 55% consists of smaller, more vulnerable organizations (e.g., those filing 990-EZ or 990-N), the finding that the threshold was "invisible" may not generalize to the sector's extensive margin. The authors should either (i) reweight the analysis to match the distribution of loan amounts in the full PPP data, (ii) report summary statistics comparing matched vs. unmatched PPP recipients on observable loan characteristics, or (iii) bound the potential bias from selective matching.

---

### 4. Suggestions

**Empirical Strategy and Identification**

- **Validate the Quarterly-to-Annual Proxy:** The paper assumes annual revenue changes are a noisy but directionally correct proxy for quarterly changes. If any subset of the data (e.g., hospitals with quarterly financial statements or a subsample with monthly bank data) can validate this assumption, include it. Show the correlation between annual and maximum quarterly declines. If validation is impossible, use simulation to show how much measurement error would be required to explain the null first stage given reasonable assumptions about the quarterly distribution.
- **Pursue the Promised IV Strategy:** The manifest proposed using the April 16, 2020 funding exhaustion as an instrument for First Draw receipt. Since the Second Draw RDD fails, the paper would significantly benefit from implementing this IV for First Draw loans, even if as a robustness check or appendix. This would provide at least one credible estimate of PPP's effect on nonprofit employment, salvaging the paper's ability to speak to treatment effects rather than just selection.
- **Event-Study Specifications:** Instead of single-year placebo tests, present event-study graphs showing employment trajectories for PPP recipients vs. non-recipients from 2017-2023. This would visually demonstrate the parallel (or divergent) trends and make the selection argument more compelling than a single 2018 coefficient.

**Measurement and Heterogeneity**

- **Decompose by Nonprofit Type:** The nonprofit sector is heterogeneous—hospitals, universities, food banks, and arts organizations faced different demand shocks and had varying capacities to document quarterly losses. Analyze heterogeneity by NTEE code or revenue composition (donation-dependent vs. fee-for-service). The threshold might have bound for certain subsectors (e.g., those with regular quarterly grant reporting) even if not in the aggregate.
- **Examine the Intensive Margin:** The paper focuses on employment levels but ignores loan amounts. Even if the 25% threshold didn't bind for eligibility, it may have determined loan size (since loan amounts were tied to payroll). Analyze whether loan amounts varied at the threshold—if the first stage on loan size is also null, this strengthens the "invisible threshold" interpretation.
- **Banking Relationship Controls:** Bartik et al. (2020) emphasize the importance of SBA lender relationships. If the Form 990 data can be merged with FDIC data on bank branches (via ZIP code or county), include controls for local banking density to sharpen the selection analysis.

**Program Design and Policy Implications**

- **Quantify the Design Failure:** Calculate what percentage of Second Draw loans went to nonprofits that would have been ineligible under a binding 25% annual revenue rule. This counterfactual would illustrate the fiscal cost of the administrative data mismatch.
- **Compare to For-Profits:** The paper emphasizes that nonprofits differ from firms, but provides no empirical comparison. If feasible (and acknowledged as descriptive), compare the first-stage discontinuity for for-profit vs. nonprofit borrowers in the same ZIP codes or industries. This would isolate whether the null result is specific to the nonprofit reporting cycle or reflects broader implementation challenges.
- **Recommendations for Future Emergency Lending:** Expand Section 6 to offer concrete guidance. Given that Form 990 is annual, what specific alternative eligibility rules (e.g., any revenue decline + size cap, or Cummins-Weiss style financial vulnerability indices) would have targeted distressed nonprofits more effectively?

**Presentation and Transparency**

- **Clarify the Sample Construction:** Table 1 shows 158,232 organizations, but the text mentions 82,251 unique nonprofit PPP borrowers. Clarify how these sample sizes relate—is the 158K the universe of 990 filers, of which only 36K matched? Provide a flowchart of sample selection.
- **Standardized Effect Sizes:** While Appendix Table 6 reports standardized effect sizes, the main text should reference these to facilitate comparison with Autor et al. (2022) and other PPP studies. The small negative RD effects (SDE ≈ -0.01 to -0.02) are economically trivial compared to the OLS associations (SDE ≈ 0.03), reinforcing the selection story.
- **Robustness to Alternative Bandwidths:** The bandwidth sensitivity table shows significance at 2× bandwidth. Explain why wider bandwidths induce bias (incorporating infra-marginal units with different revenue shock profiles) and consider reporting "donut hole" RD specifications excluding observations near the threshold to address potential manipulation concerns despite the McCrary result.

**Minor Points**

- The paper notes that nonprofits "file annual Form 990 returns" and therefore lack quarterly data. However, some large nonprofits (particularly 501(c)(3) hospitals and universities) file Form 990-T for unrelated business income on a quarterly estimated tax basis. Acknowledge this exception and verify it doesn't affect the results.
- Citation granularity: When discussing the PPP literature, distinguish between studies using Census/ADP data (Autor et al., 2022), bank records (Bartik et al., 2020), and payroll processing data (Chetty et al., 2024) to clarify why Form 990 offers a distinct vantage point.

---

**Conclusion:**  
This paper identifies a genuine and important puzzle: a statutory eligibility threshold that failed to bind due to administrative data mismatches. The finding is novel and policy-relevant. However, the manuscript currently sits uneasily between a failed program evaluation and a measurement paper. A revised version should either (1) commit fully to the "invisible threshold" as a contribution to program design theory, bolstered by validation exercises and heterogeneity analyses, or (2) supplement the failed RDD with credible alternative identification (the promised IV or for-profit comparisons) to recover treatment effects. Addressing the external validity concerns regarding the 45% match rate is essential for publication.
