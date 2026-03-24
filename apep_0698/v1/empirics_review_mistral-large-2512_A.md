# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-16T00:26:08.698640

---

### 1. Idea Fidelity

The paper adheres closely to the original idea manifest. It successfully links SBA PPP microdata to IRS Form 990 filings via name-address-ZIP matching, exploits the 25% revenue decline threshold for Second Draw PPP eligibility as an RDD, and examines nonprofit employment outcomes using the specified data sources. The paper also incorporates the supplementary IV strategy (bank-processing-time instrument) mentioned in the manifest, though it is not a central focus of the results.

Key elements from the manifest are preserved:
- **Research question**: Whether PPP preserved nonprofit sector capacity.
- **Identification strategy**: RDD at the 25% revenue decline threshold for Second Draw eligibility.
- **Data sources**: IRS SOI Form 990 extracts and SBA PPP microdata.
- **Outcomes**: Employment (W-3 count), revenue, and expenses.
- **Novelty**: First study to use IRS 990 data for PPP analysis and to test the 25% threshold in the nonprofit sector.

The paper does not miss any critical components of the original idea. The manifest’s feasibility checks (e.g., data access, sample size) are validated in the paper’s execution.

---

### 2. Summary

This paper examines the effects of the Paycheck Protection Program (PPP) on nonprofit employment by linking SBA PPP microdata to IRS Form 990 filings. Using a regression discontinuity design (RDD) at the 25% quarterly revenue decline threshold for Second Draw PPP eligibility, the authors find no discontinuity in loan receipt or employment outcomes. The threshold, designed for quarterly revenue reporting, was orthogonal to the annual reporting cycle of nonprofits, rendering it non-binding. While conditional associations between PPP receipt and employment are positive, a pre-treatment placebo test reveals these are driven by selection rather than causal effects. The paper highlights a mismatch between program design and the administrative data infrastructure of nonprofits.

---

### 3. Essential Points

The paper is methodologically sound and makes a valuable contribution, but three critical issues must be addressed:

#### (1) **Measurement Error in the Running Variable**
The RDD relies on annual revenue decline as a proxy for quarterly revenue decline, which introduces classical measurement error. The authors acknowledge this but do not quantify its implications for the first-stage estimate. While the null result is convincing, the paper should:
   - **Clarify the attenuation bias**: The measurement error in the running variable would bias the first-stage estimate toward zero, but the paper’s point estimate is *precisely* zero. This suggests the threshold was truly non-binding, but the authors should explicitly rule out the possibility that the null result is an artifact of attenuation.
   - **Provide a bounding exercise**: Simulate the relationship between annual and quarterly revenue declines to estimate the expected attenuation. For example, what fraction of nonprofits with a 25% annual decline would be expected to have a 25% quarterly decline? If this fraction is small, the null result is more credible.

#### (2) **External Validity of the Matched Sample**
The 45% match rate between PPP and Form 990 data raises concerns about external validity. The authors note that the matched sample overrepresents larger organizations, but they do not:
   - **Test for differential effects by size**: Are the results driven by large nonprofits (e.g., hospitals, universities) that may have had alternative funding sources? The paper should stratify the analysis by organization size (e.g., terciles of 2019 employment or revenue) to assess heterogeneity.
   - **Compare matched vs. unmatched nonprofits**: Provide summary statistics for unmatched nonprofits (e.g., from the SBA PPP data) to assess how they differ from the matched sample. This would help readers evaluate whether the null results generalize to smaller or less formalized nonprofits.

#### (3) **Interpretation of the Selection Diagnostic**
The pre-treatment placebo test (Table 7) is a strength of the paper, but the interpretation could be sharpened:
   - **Clarify the selection mechanism**: The authors suggest that organizational capacity or banking relationships drive selection, but they do not test this directly. The paper should:
     - Include additional pre-treatment covariates (e.g., prior-year assets, contributions, or program service revenue) to see if the placebo coefficient attenuates.
     - Test whether the placebo coefficient varies by organization size or sector (e.g., NTEE codes), which could shed light on the dimensions of selection.
   - **Discuss alternative explanations**: Could the placebo result reflect mean reversion or other dynamic patterns in nonprofit employment? The authors should rule out these possibilities.

---

### 4. Suggestions

#### (1) **Strengthen the RDD Framework**
- **Quarterly revenue data**: While the authors note that nonprofits do not report quarterly revenue in Form 990, they could explore alternative data sources (e.g., state-level quarterly filings for some nonprofits, or bank statements for a subset of organizations) to validate the annual proxy. Even a small subsample with quarterly data would bolster the credibility of the null result.
- **Alternative running variables**: Test whether other annual measures (e.g., program service revenue decline, contributions decline) yield similar results. This would address concerns that the null result is specific to total revenue.
- **Graphical evidence**: Include a binned scatterplot of the running variable (annual revenue decline) against Second Draw receipt, with the RDD threshold marked. This would make the null first stage more intuitive for readers.

#### (2) **Improve the Matching Strategy**
- **Match quality**: The paper uses exact name + ZIP matching, which may exclude organizations with minor name discrepancies (e.g., "Inc." vs. "LLC"). The authors should:
  - Report the share of matches achieved at each step (e.g., name + ZIP vs. name + state) to assess the trade-off between match rate and accuracy.
  - Consider fuzzy matching techniques (e.g., Levenshtein distance) to improve the match rate, especially for smaller nonprofits.
- **Sensitivity to match rate**: Replicate the main results on a subsample with higher match confidence (e.g., only exact name + ZIP matches) to ensure the null result is not driven by noisy matches.

#### (3) **Explore Heterogeneity**
- **By sector**: Nonprofits vary widely in their revenue structures (e.g., hospitals vs. food banks). The paper should:
  - Stratify the RDD analysis by NTEE major category (e.g., health, education, human services) to test whether the threshold was binding for specific sectors.
  - Test whether the placebo coefficient varies by sector, which could reveal sector-specific selection mechanisms.
- **By size**: The authors note that Second Draw recipients are smaller on average, but they do not test whether the RDD results differ by size. A triple-difference design (threshold × size) could assess whether the threshold was binding for smaller nonprofits, which may have lacked the administrative capacity to navigate the quarterly reporting requirement.

#### (4) **Clarify the Policy Implications**
- **Program design**: The paper’s key insight is that the 25% threshold was non-binding for nonprofits due to the mismatch between quarterly eligibility rules and annual reporting. The authors should:
  - Propose concrete alternatives for future programs (e.g., using annual revenue declines or multi-year averages).
  - Discuss whether the threshold was binding for for-profit firms, which *do* report quarterly revenue. A brief comparison to for-profit RDD studies (e.g., using payroll data) would contextualize the nonprofit results.
- **Targeting**: The paper suggests that PPP allocation was driven by organizational capacity rather than need. The authors should:
  - Test whether nonprofits with prior SBA relationships (e.g., from other federal programs) were more likely to receive PPP, which would support the "banking relationships" hypothesis.
  - Discuss whether alternative targeting mechanisms (e.g., revenue decline thresholds based on annual data) would have improved equity.

#### (5) **Address Potential Confounding**
- **Other COVID-19 programs**: Nonprofits may have received funding from other sources (e.g., FEMA, state/local grants), which could confound the PPP effects. The authors should:
  - Control for other COVID-19 relief programs in the OLS specifications (if data are available).
  - Discuss whether these programs were targeted differently than PPP (e.g., based on annual revenue declines).
- **Dynamic effects**: The paper focuses on employment in 2021–2023, but PPP may have had short-term effects (e.g., preserving jobs in 2020) that dissipated later. The authors should:
  - Include 2020 employment as an outcome to test for immediate effects.
  - Discuss whether the null results reflect delayed effects or genuine ineffectiveness.

#### (6) **Improve Presentation**
- **Figures**: The paper would benefit from:
  - A map of nonprofit PPP recipients by state or county to visualize geographic variation.
  - A histogram of annual revenue declines with the 25% threshold marked, to show the distribution of the running variable.
- **Tables**: The OLS results (Table 6) could be streamlined by:
  - Combining columns (2)–(4) into a single specification with all controls.
  - Adding a column with 2023 employment to assess long-term persistence.
- **Clarity**: The discussion of the "invisible threshold" is compelling but could be sharpened by:
  - Explicitly contrasting the nonprofit results with for-profit studies (e.g., "For for-profits, the 25% threshold was binding because...").
  - Adding a flowchart or timeline to illustrate the mismatch between quarterly eligibility and annual reporting.

#### (7) **Extend the Literature Review**
- **Nonprofit finance**: The paper cites foundational work on nonprofit revenue streams (e.g., Hansmann, Weisbrod) but could engage more with recent literature on nonprofit financial resilience (e.g., Calabrese and Grizzle 2019 on nonprofit liquidity).
- **PPP studies**: The paper positions itself as the first to study nonprofits, but it should acknowledge studies using other data sources (e.g., surveys of nonprofits) to assess consistency with prior findings.
- **RDD in policy evaluation**: The paper could cite recent work on RDD in program evaluation (e.g., Cattaneo et al. 2020 on optimal bandwidth selection) to contextualize its methodological choices.

---

### Final Assessment

This is a well-executed and important paper that makes a novel contribution to the literature on PPP and nonprofit finance. The null RDD result is convincing, and the selection diagnostic is a model of transparency. With the revisions suggested above—particularly addressing measurement error, external validity, and heterogeneity—the paper could be published in a top field journal (e.g., *Journal of Public Economics* or *American Economic Journal: Economic Policy*). The current version is close to publishable but requires minor revisions to fully address the critical issues.
