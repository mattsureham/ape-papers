# Internal Review — Claude Code (Round 1)

**Reviewer:** Claude Code (internal self-review)
**Paper:** Does Coverage Create Capacity? Section 1115 SUD Waivers and the Supply of Behavioral Health Providers
**Date:** 2026-03-05

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

**Strengths:**
- The staggered DiD design using Callaway-Sant'Anna (2021) is appropriate for this setting with 19 treatment cohorts and 14 never-treated controls.
- The exclusion of 8 always-treated states with insufficient pre-treatment data is methodologically sound.
- The placebo test using personal care T-codes is well-conceived — these services have no clinical connection to SUD.
- Threats to validity (concurrent policies, COVID, T-MSIS data quality, endogenous adoption) are discussed explicitly.

**Concerns:**
- The earliest treatment cohort (NH, July 2018) has only 6 months of pre-treatment data. While CS-DiD can handle this, it limits the power of the pre-trends test for early cohorts. The paper should acknowledge this more explicitly.
- The parallel trends assumption is supported by visual inspection of event-study plots, but no formal pre-trend test statistic (e.g., joint F-test on pre-treatment coefficients) is reported.
- The "treatment" is CMS waiver approval month, but actual implementation may lag approval by months. This measurement error in treatment timing could attenuate effects.

### 2. Inference and Statistical Validity

**Strengths:**
- Standard errors are clustered at the state level (the treatment unit).
- Three inference methods (cluster-robust, randomization inference, wild cluster bootstrap) all agree on the null.
- Sample sizes are clearly reported in all tables with cluster counts.

**Concerns:**
- With 43 clusters and 19 treatment cohorts, the effective sample for each group-time ATT is small. The paper should discuss minimum detectable effects — what size supply response could it actually detect?
- The p-value precision discussion (normal vs. t-distribution for CS-DiD) should be noted in the text.

### 3. Robustness and Alternative Explanations

**Strengths:**
- Comprehensive robustness battery: TWFE, stacked DiD, COVID exclusion, state trends, always-treated inclusion, RI, WCB.
- The Bacon decomposition is informative — showing 53% weight on clean treatment-vs-control comparisons.
- The divergence between CS-DiD (positive) and TWFE/stacked (near zero) is honestly reported and discussed.

**Concerns:**
- The SUD provider decline deserves more investigation. Is it driven by coding changes? Could states have reclassified H-codes during waiver implementation? A decomposition by specific H-code subcategories would help.
- No heterogeneity by state Medicaid expansion status, which could moderate the supply response.

### 4. Contribution and Literature Positioning

**Strengths:**
- Clear differentiation from demand-side papers (Wen et al. 2022, Gertner et al. 2021).
- Novel use of T-MSIS Provider Spending file for supply-side analysis.
- The "Theory of Change" section effectively frames the ex ante expectations.

**Concerns:**
- The paper could cite Clemens and Gottlieb (2014, AER) on physician responses to Medicare fee changes — directly relevant to the supply elasticity literature.
- Missing discussion of how results compare to Medicaid expansion effects on provider supply (Simon et al. 2017).

### 5. Results Interpretation

**Strengths:**
- The paper honestly reports null/weak results without spinning them as positive.
- The "who pays vs. how much" interpretation is compelling and well-supported.
- Policy implications are appropriately calibrated to evidence strength.

**Concerns:**
- The 25% point estimate for BH providers is economically large even if statistically insignificant. The paper should discuss confidence intervals — can it rule out effects larger than X%?

### 6. Actionable Revision Requests

**Must-fix:**
1. Add a formal pre-trends test (joint F-test or Wald test on pre-treatment coefficients).
2. Report minimum detectable effects given sample size and variance.

**High-value:**
3. Decompose SUD provider decline by specific H-code subcategories.
4. Add heterogeneity by Medicaid expansion status.
5. Discuss confidence interval bounds — what effects can be ruled out?

**Optional:**
6. Add Clemens and Gottlieb (2014) citation for supply elasticity context.
7. Consider HonestDiD sensitivity analysis for parallel trends violations.

### 7. Overall Assessment

**Key strengths:** Novel question, novel data, honest reporting of null results, comprehensive robustness, strong institutional context.

**Critical weaknesses:** Imprecise estimates limit what can be learned; no formal pre-trends test; limited heterogeneity analysis.

**Publishability:** Strong working paper with a genuinely important null result. The T-MSIS data contribution alone makes this valuable. With the suggested additions (pre-trends test, MDE, heterogeneity), this is a solid candidate for AEJ: Economic Policy or Health Economics.

DECISION: MINOR REVISION
