# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-27T00:01:02.477130

---

### 1. Idea Fidelity

The paper adheres closely to the original idea manifest. It correctly identifies the EGRRCPA’s Section 210 as the policy lever, uses the FDIC Call Report data as specified, and implements the proposed DiD design comparing banks in the $1B–$3B range (treatment) to those in the $3B–$10B range (control). The outcome variables (noncurrent loan ratio, capital adequacy, loan composition) and robustness checks (placebo tests, donut-hole exclusions, COVID restrictions) align with the manifest’s promises. The paper even cites the Kandrac & Schlusche (2021) comparison as intended. No key elements of the identification strategy or research question are missed.

---

### 2. Summary

This paper exploits the 2018 EGRRCPA’s extension of bank examination cycles from 12 to 18 months for well-capitalized community banks ($1B–$3B in assets) to test whether reduced regulatory scrutiny increases risk-taking. Using a DiD design with quarterly FDIC Call Report data (2016–2023), the authors find no economically or statistically significant effects on noncurrent loan ratios, capital erosion, or loan composition. The null result is robust to placebo tests, donut-hole exclusions, and COVID-era restrictions, suggesting that market discipline and internal governance may substitute for examination frequency in well-capitalized banks.

---

### 3. Essential Points

**1. Standard errors and clustering:**
The paper clusters standard errors at the bank level, which is appropriate given the DiD design. However, the number of clusters in the control group (189 banks) is small, and the treatment group (460 banks) is only modestly larger. With few clusters, inference can be fragile, especially for secondary outcomes. The authors should:
   - Report wild bootstrap p-values (e.g., Cameron et al., 2008) for the main results, particularly for the noncurrent loan ratio and Tier 1 capital ratio.
   - Justify why state-level clustering (which yields significant results) is less appropriate than bank-level clustering. If examination scheduling is bank-specific, bank-level clustering is correct, but the small number of clusters warrants caution.

**2. Magnitude and economic significance:**
The point estimate for the noncurrent loan ratio (-0.090 pp) is small relative to the pre-treatment mean (0.91%), but the standard error (0.059) implies a 95% confidence interval of roughly [-0.20, +0.02]. This interval includes economically meaningful effects (e.g., a 20% increase in noncurrent loans). The authors should:
   - Explicitly discuss the upper bound of the confidence interval and whether it rules out policy-relevant effects. For example, a 0.20 pp increase in noncurrent loans might be meaningful for regulators, even if not statistically significant.
   - Avoid overinterpreting the null as evidence of "no effect" without addressing the confidence interval’s width.

**3. Parallel trends and dynamic effects:**
The event study (Table 4) shows no pre-trends, but the post-treatment coefficients exhibit non-trivial variation (e.g., -0.14 pp at t+9). The authors should:
   - Test for joint significance of post-treatment coefficients to assess whether there is *any* dynamic effect, even if not concentrated at the treatment date.
   - Plot the full event study (including all quarters) to better visualize potential delayed effects or noise.

---

### 4. Suggestions

**A. Data and sample construction:**
1. **Treatment timing:**
   - The paper assigns treatment status based on 2018Q2 assets, but the interim final rule was issued in August 2018 (2018Q3). Banks may have anticipated the rule or adjusted behavior in 2018Q3. The authors should:
     - Test for pre-trends in 2018Q3 (the "implementation quarter") to check for anticipation effects.
     - Consider excluding 2018Q3 from the post period if banks could not have adjusted behavior immediately.

2. **Control group selection:**
   - The control group ($3B–$10B) is smaller and mechanically different from the treatment group. The authors should:
     - Show that results are robust to alternative control groups (e.g., $3B–$5B or $5B–$10B) to ensure the null is not driven by the choice of control.
     - Report balance tests for pre-treatment trends in *levels* (not just differences) of outcomes to confirm comparability.

3. **Outcome variables:**
   - The noncurrent loan ratio is a noisy measure of risk-taking, as it reflects both ex-ante risk-taking and ex-post realizations. The authors should:
     - Include additional forward-looking risk measures, such as loan loss provisions or interest income on loans (a proxy for riskier lending).
     - Test for effects on loan growth rates (not just log assets), as banks may respond to reduced scrutiny by expanding lending.

**B. Robustness and heterogeneity:**
1. **Heterogeneous effects:**
   - The paper hints at heterogeneity by splitting the treatment group into $1B–$2B and $2B–$3B (Table A1), but this is not discussed in the main text. The authors should:
     - Formally test for heterogeneity by size, capitalization, or pre-treatment CAMELS ratings. For example, do banks closer to the $3B threshold (which may have been "bunching" to avoid stricter scrutiny) respond differently?
     - Explore whether banks with higher pre-treatment noncurrent loan ratios (i.e., riskier banks) exhibit larger effects.

2. **Alternative specifications:**
   - The placebo test (Table 5) shows a significant effect for banks $500M–$1B, which the authors interpret as a size-driven trend. However, this could also reflect differences in market discipline or governance. The authors should:
     - Test whether the placebo effect is robust to including bank fixed effects (to absorb time-invariant size differences) or to using a triple-difference design (e.g., comparing $500M–$1B to $3B–$10B, with $1B–$3B as an additional control).
     - Report results for the placebo test using the same donut-hole exclusions as the main specification to ensure comparability.

3. **COVID-19 and forbearance:**
   - The authors address COVID-19 by restricting the sample to pre-2020 or excluding 2020–2021, but forbearance policies may have masked risk-taking in other ways. The authors should:
     - Test for effects on loan modifications or delinquencies specifically tied to COVID-19 relief programs (e.g., CARES Act modifications).
     - Examine whether the null result holds for outcomes less affected by forbearance, such as net charge-offs or loan growth.

**C. Interpretation and mechanisms:**
1. **Market discipline vs. internal governance:**
   - The paper suggests that market discipline or internal governance may substitute for examination frequency, but it does not test these mechanisms directly. The authors should:
     - Use the CRA Performance Evaluation data (mentioned in the manifest) to test whether banks with stronger pre-treatment CRA ratings (a proxy for community reputation) exhibit smaller effects.
     - Examine whether banks with higher deposit concentrations (more exposed to depositor discipline) respond differently.

2. **Comparison to Kandrac & Schlusche (2021):**
   - The authors contrast their null result with Kandrac & Schlusche’s (2021) finding that reduced examination intensity increased failures during the S&L crisis. However, the settings differ in multiple dimensions (crisis vs. stability, moral hazard vs. market discipline). The authors should:
     - Test whether the effect of EGRRCPA varies with local economic conditions (e.g., unemployment rates or house price growth) to assess whether the deterrence gap emerges during stress.
     - Discuss whether the null result is consistent with Kandrac & Schlusche’s findings if one assumes that the marginal effect of examination frequency is smaller for well-capitalized banks.

3. **External validity:**
   - The paper’s focus on well-capitalized community banks limits its generalizability. The authors should:
     - Discuss whether the results might differ for less-capitalized banks (e.g., those with CAMELS 3 ratings) or for larger banks (e.g., $10B+).
     - Speculate on how the deterrence gap might operate in other regulatory domains (e.g., food safety) where market discipline is weaker.

**D. Presentation and transparency:**
1. **Tables and figures:**
   - The event study (Table 4) omits many quarters, making it hard to assess dynamic effects. The authors should:
     - Include a figure plotting all event-study coefficients with 95% confidence intervals.
     - Report the full event-study table in the appendix.
   - The robustness table (Table 5) lacks a clear narrative. The authors should:
     - Add a column describing the intuition behind each robustness check (e.g., "Placebo: tests for size-driven trends").
     - Highlight which checks are most critical for addressing key threats to validity.

2. **Replication materials:**
   - The paper mentions a GitHub repository but does not provide a link to the replication code or data. The authors should:
     - Include a replication package with clean code, data dictionaries, and instructions for reproducing all results.
     - Ensure the FDIC API data is fully documented, as it is not publicly available in raw form.

3. **Clarity of writing:**
   - The abstract and introduction overstate the null result as evidence of "no effect" without acknowledging the confidence interval’s width. The authors should:
     - Revise the abstract to emphasize the *precision* of the null (e.g., "find no economically meaningful increase in risk-taking, with effects bounded below [X] pp").
     - Clarify in the discussion that the null does not imply examinations are unnecessary, but rather that frequency may not be the binding constraint for well-capitalized banks.

---

### Final Assessment

This is a well-executed paper that delivers on its promise to test the "deterrence gap" hypothesis using a clean policy experiment. The DiD design is appropriate, the robustness checks are thorough, and the null result is plausible given the setting (well-capitalized banks during stable times). However, the paper’s interpretation of the null as evidence of "no effect" is premature without addressing the confidence interval’s width and potential heterogeneity. The authors should focus on refining the economic interpretation, testing mechanisms, and ensuring the standard errors are robust to the small number of clusters. With these improvements, the paper would make a strong contribution to the literature on regulatory inspection frequency.
