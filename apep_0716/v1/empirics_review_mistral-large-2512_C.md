# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-17T22:52:14.962103

---

### 1. Idea Fidelity

The paper closely follows the original idea manifest. It successfully implements the core bunching estimation at the $200,000 IRS Form 990 threshold, leverages the 2010 reform as a natural experiment, and includes the placebo test at the $50,000 threshold. The cross-state variation in audit thresholds is mentioned but not fully exploited in the analysis (only a brief heterogeneity check is performed). The paper also extends the original idea by adding heterogeneity analysis by organization type and asset size, which strengthens the compliance cost mechanism. No key elements of the identification strategy or data source are missed.

---

### 2. Summary

This paper provides the first bunching-based estimate of the compliance costs associated with IRS Form 990 disclosure requirements for tax-exempt organizations. Using the universe of 1.9 million registered nonprofits, the authors document sharp bunching just below the $200,000 gross receipts threshold, where organizations can avoid the more burdensome Form 990 (12+ pages) by filing the simpler Form 990-EZ (4 pages). The estimated normalized excess mass of 1.52 implies ~941 organizations manipulate reported revenue to avoid the full disclosure requirement. Placebo tests, robustness checks, and heterogeneity analysis support the compliance cost mechanism.

---

### 3. Essential Points

**1. Magnitude and Plausibility of the Bunching Estimate**
The normalized excess mass of 1.52 is large but plausible. However, the paper does not provide sufficient context to assess whether this magnitude is economically meaningful. For example:
   - What fraction of organizations in the $100K–$300K range does 941 represent? (The paper states 0.7% in the discussion, which is reasonable but should be highlighted earlier.)
   - How does this compare to bunching estimates in other settings (e.g., tax notches, SEC thresholds)? A brief benchmarking would help readers assess the result.
   - The missing mass above the threshold (269 organizations) is smaller than the excess mass (941), which is unusual. The paper attributes this to organizations compressing revenue by more than the minimum needed, but this warrants further discussion. Is this pattern consistent with other bunching studies?

**2. Standard Errors and Inference**
The standard errors are computed via parametric bootstrap (1,000 replications), which is appropriate. However:
   - The paper does not discuss whether the bootstrap accounts for potential spatial correlation in the revenue distribution (e.g., organizations in the same state or sector may have correlated reporting behaviors). If not, standard errors may be underestimated.
   - The placebo test at $50,000 has a large standard error (SE = 0.26 for $\hat{b} = 0.21$), which is expected given the minimal compliance cost difference. However, the paper should clarify whether the test has sufficient power to detect bunching at this threshold. A power calculation or discussion of the minimal detectable effect would strengthen the placebo argument.

**3. Cross-Sectional vs. Panel Interpretation**
The paper uses a cross-sectional snapshot of the EO BMF and interprets the bunching as a steady-state behavioral response. However:
   - The EO BMF is not a true panel; it reflects the most recent filing data for each organization, which could span multiple years. This introduces potential bias if organizations with older filings are systematically different (e.g., less likely to bunch).
   - The paper should acknowledge this limitation and discuss whether the results might reflect a mix of pre- and post-2010 behavior. The legacy bunching at $100,000 suggests some organizations may not have updated their reporting practices after the threshold change.

---

### 4. Suggestions

**A. Strengthening the Main Result**
1. **Benchmarking the Magnitude**
   - Compare the bunching estimate to other studies (e.g., Yildirim 2018 for state audit thresholds, Ewens et al. 2024 for SEC thresholds). Is 1.52 large or small relative to these settings?
   - Report the implied compliance cost. The bunching literature often translates excess mass into an implied "tax rate" or cost. For example, if organizations are willing to forgo $X in revenue to avoid the Form 990, what is the implied cost per organization? This would make the result more economically interpretable.

2. **Addressing the Missing Mass Puzzle**
   - The missing mass above the threshold (269) is smaller than the excess mass (941), which is unusual. The paper should:
     - Discuss whether this pattern is consistent with other bunching studies (e.g., do organizations often compress revenue by more than the minimum needed?).
     - Test whether the missing mass is statistically significant (e.g., is the count above the threshold significantly lower than the counterfactual?).
     - Consider alternative explanations (e.g., measurement error in revenue reporting).

3. **Improving the Placebo Test**
   - The placebo at $50,000 is a strength, but the paper should:
     - Clarify whether the test has sufficient power to detect bunching. For example, what is the minimal detectable effect given the sample size and counterfactual density at $50,000?
     - Report the results of a formal equivalence test (e.g., two one-sided tests) to confirm that the placebo estimate is statistically indistinguishable from zero.

**B. Robustness Checks**
1. **Alternative Counterfactuals**
   - The paper uses a 7th-degree polynomial for the counterfactual, which is standard but may overfit. The robustness checks show that the estimate varies with polynomial order (e.g., $\hat{b} = 0.63$ for order 9 vs. 1.65 for order 8). The paper should:
     - Report results using a local linear regression (e.g., following Cattaneo et al. 2020) as an alternative to polynomials.
     - Discuss whether the variation in estimates across polynomial orders is concerning.

2. **Donut Robustness**
   - The donut robustness checks (excluding bins above the threshold) are a good addition. However:
     - The estimate drops to $\hat{b} = 0.74$ when excluding $10,000 above the threshold, which is a large change. The paper should discuss whether this suggests sensitivity to the exclusion window or whether the result is driven by a few bins.

3. **Alternative Bin Widths**
   - The paper uses $1,000 bins, which is reasonable, but it should test whether the results are sensitive to bin width (e.g., $500 or $2,000 bins). This is a common robustness check in bunching studies.

**C. Heterogeneity Analysis**
1. **State-Level Variation**
   - The paper briefly mentions state-level heterogeneity but does not fully exploit the cross-state variation in audit thresholds. To strengthen this:
     - Report a formal decomposition of federal vs. state compliance costs (e.g., regress bunching intensity on state audit thresholds).
     - Test whether bunching is weaker in states with stringent charitable solicitation requirements (e.g., NY, CA), where organizations may already face high disclosure burdens.

2. **Organization Type**
   - The heterogeneity by organization type is compelling, but the paper should:
     - Discuss why religious organizations bunch so intensely ($\hat{b} = 5.45$). Is this due to aversion to governance disclosures, or are there other mechanisms (e.g., less professionalized accounting)?
     - Test whether the results are robust to excluding religious organizations, which may have unique reporting behaviors.

3. **Asset Size**
   - The asset size heterogeneity is a key contribution. To strengthen it:
     - Report the distribution of assets for organizations near the threshold. Are small-asset organizations systematically different in other ways (e.g., sector, age)?
     - Test whether the asset size gradient holds within sectors (e.g., do small-asset religious organizations bunch more than large-asset religious organizations?).

**D. Policy Implications**
1. **Implied Compliance Cost**
   - The paper should quantify the implied compliance cost. For example:
     - If 941 organizations are willing to forgo $X in revenue to avoid Form 990, what is the average cost per organization?
     - How does this compare to estimates of nonprofit compliance costs from other sources (e.g., surveys, time-use studies)?

2. **2010 Reform**
   - The paper mentions the 2010 reform but does not fully exploit it. To strengthen the analysis:
     - Test whether bunching at $100,000 declined after 2010 (using a pre/post comparison).
     - Estimate the migration of bunching from $100,000 to $200,000 after the reform (e.g., did the excess mass at $100,000 shift to $200,000?).

3. **Welfare Implications**
   - The paper argues that the compliance cost falls disproportionately on small organizations, but it does not discuss the welfare implications. For example:
     - Does the bunching reflect a distortion (e.g., organizations forgoing revenue to avoid disclosure) or an efficient response (e.g., organizations avoiding unnecessary compliance costs)?
     - How should policymakers weigh the compliance cost against the accountability benefits of Form 990?

**E. Data and Measurement**
1. **Cross-Sectional Limitations**
   - The paper acknowledges that the EO BMF is a cross-sectional snapshot but does not discuss potential biases. For example:
     - Are organizations with older filings less likely to bunch (e.g., because they are less aware of the threshold)?
     - Does the EO BMF include inactive organizations, which might bias the results?

2. **Revenue Measurement**
   - The paper assumes that reported revenue is manipulated, but it does not discuss how organizations might do this. For example:
     - Could organizations delay revenue recognition or accelerate expenses to stay below the threshold?
     - Are there audits or enforcement actions that validate the manipulation?

3. **Sample Restrictions**
   - The paper restricts the sample to organizations with revenue between $100K and $300K. It should:
     - Justify this window (e.g., why not $50K–$400K?).
     - Test whether the results are sensitive to the sample restrictions.

**F. Presentation and Clarity**
1. **Figures**
   - The paper lacks a visual representation of the bunching (e.g., a histogram with the counterfactual density). This would make the results more intuitive and help readers assess the magnitude of the excess mass.

2. **Standardized Effect Sizes**
   - The appendix includes a table of standardized effect sizes, but this should be integrated into the main text. The SDE of 1.52 is large, but the paper should explain what this means in context (e.g., "This is comparable to the largest bunching estimates in the tax literature").

3. **Mechanism Discussion**
   - The paper argues that the bunching reflects compliance costs, but it does not rule out alternative mechanisms. For example:
     - Could organizations bunch to avoid public scrutiny (e.g., donors or journalists using Form 990 data)?
     - Could the threshold create a coordination problem (e.g., organizations bunch to signal legitimacy)?

---

### Final Assessment

This is a strong and novel paper that makes a valuable contribution to the literature on nonprofit disclosure and bunching estimation. The identification strategy is well-executed, and the results are robust to multiple checks. However, the paper would benefit from:
1. Better benchmarking of the bunching magnitude and implied compliance cost.
2. More rigorous discussion of the missing mass puzzle and standard error assumptions.
3. Deeper exploitation of the 2010 reform and cross-state variation.
4. Improved presentation (e.g., figures, standardized effect sizes).

With these improvements, the paper would be suitable for publication in a top field journal (e.g., *Journal of Public Economics* or *American Economic Journal: Economic Policy*). The current version is close but needs to address the essential points above.
