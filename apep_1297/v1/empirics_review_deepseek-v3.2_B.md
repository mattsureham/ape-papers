# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-04-02T03:54:55.944575

---

**Referee Report**

**Paper:** “The Developer's Ceiling: Price Bunching at Ireland's Help to Buy Cap”

**Date:** April 2, 2026

This paper applies the bunching methodology to Ireland’s Help to Buy (HTB) scheme, which provides a tax credit for first-time buyers of new-build homes priced at or below €500,000. Using the universe of property transaction data, the authors document sharp bunching of new-build prices just below the €500,000 cap, a pattern absent in the pre-period and in the ineligible second-hand market. The paper is clearly written, the empirical strategy is appropriate, and the multiple placebo tests are convincing. The findings offer a clear illustration of how sharp eligibility thresholds can distort market prices, with implications for subsidy design.

---

### 1. Idea Fidelity

The paper closely follows the original idea manifest. The manifest specified using the Property Price Register (PPR) to test for bunching at €500,000, employing a second-hand market placebo, and examining an intensity shock in July 2020. The paper delivers on all these core elements. The data scope is expanded (2010–2025 vs. 2017–2023 in the manifest), which strengthens the pre-period analysis. The reported bunching ratio for new builds (2.33) is very close to the manifest’s 2.30. The second-hand placebo result differs in sign (the paper finds -0.20, the manifest suggested 0.55), but the key qualitative conclusion—no evidence of bunching in the placebo group—is the same and is convincingly supported. The analysis of the July 2020 enhancement is presented in the heterogeneity table. Therefore, the paper is highly faithful to the original research design.

---

### 2. Summary

This paper provides clean, credible evidence that Ireland’s Help to Buy scheme creates a significant price ceiling (“developer’s ceiling”) at its €500,000 eligibility cap. The primary contribution is a well-identified estimate of the policy-induced distortion: approximately 1,800 new-build transactions were compressed below the threshold, at an average price reduction of €11,700 per transaction. The design leverages multiple placebo tests (second-hand market, pre-period, non-policy thresholds) to rule out alternative explanations, making a strong case for a causal effect of the policy notch on transaction prices.

---

### 3. Essential Points

The following three issues must be addressed for the paper to be suitable for publication. They concern the estimation of the counterfactual density, the interpretation of the welfare effect, and the validation of the primary placebo group.

1.  **Counterfactual Specification and Sensitivity:** The paper relies on a global 7th-order polynomial fit over a wide price range (€200k–€800k) to estimate the counterfactual density. This is standard but can be sensitive to the chosen polynomial order and the width of the fitting region, as the robustness checks in Table 4 confirm. More importantly, a global polynomial may not provide the best local fit around the threshold, especially if the underlying price distribution has regional idiosyncrasies or structural breaks. The authors should augment their robustness analysis by presenting estimates from a local linear or quadratic regression using a narrower fitting window on either side of the exclusion zone (e.g., €300k–€475k and €525k–€700k). This would demonstrate that the estimated excess mass is not an artifact of the specific parametric form chosen for the global counterfactual.

2.  **Interpreting the Price Distortion and Incidence:** The paper interprets the €11,700 average price compression as the “developer’s sacrifice” and concludes that the subsidy is split between buyer and developer. This interpretation, while intuitive, requires more nuance and supporting discussion. The estimated price distortion (Δz*) is a reduced-form measure of how far agents adjust the *observed* price to avoid the notch. It does not reveal the incidence—who bears the economic burden of this adjustment. The €11,700 could reflect a pure price cut by the developer (a transfer to the buyer), a reduction in housing quality or size (a hidden cost to the buyer), or a combination. The paper should explicitly discuss these distinct margins of adjustment and acknowledge that the welfare implications differ for each. A short discussion on whether the data could be used to probe quality adjustments (e.g., using hedonic characteristics if available) would be valuable, even if a full analysis is beyond scope.

3.  **Validation of the Second-Hand Placebo Group:** The second-hand market is an excellent placebo, but its credibility rests on the assumption that, absent the HTB notch, new and second-hand properties would have similar smoothness in their price distributions around €500,000. The paper strengthens this by showing no new-build bunching at €400k or €450k. To further validate the placebo, the authors should perform the same non-policy threshold tests (€400k, €450k) for the second-hand market. Demonstrating that second-hand properties *do* exhibit similar (or different) round-number heaping patterns at these other thresholds would help readers assess whether the absence of bunching at €500k in this group is truly due to policy ineligibility or a general lack of clustering at that specific number. This is a straightforward and highly informative robustness check.

---

### 4. Suggestions

The following suggestions are aimed at improving clarity, robustness, and depth.

**A. Empirical Analysis & Presentation**
*   **Bunching Figures:** The paper is currently without graphical evidence. A key figure plotting the binned price distribution for new builds (HTB period) with the polynomial counterfactual overlaid is essential. A second figure comparing this to the second-hand distribution would powerfully illustrate the main result. These should be included in the main text.
*   **Standard Error Computation:** The method for computing bootstrap standard errors should be specified. It is crucial to state that resampling is done at the transaction level (not the bin level) to account for all sampling uncertainty. A brief mention in the text or a footnote suffices.
*   **Missing Mass and Integration Constraint:** The discussion focuses on excess mass below the threshold. The bunching estimator typically uses the “missing mass” above the threshold to help pin down the counterfactual. The paper should briefly note whether an integration constraint (equating total observed and counterfactual mass in the excluded region) was imposed, as is common practice, and if so, how it affected estimates.
*   **Temporal Heterogeneity Interpretation:** The finding of weaker bunching during the “enhanced” (July 2020–2022) period is intriguing but not deeply explored. The authors suggest it may reflect the “compressed COVID-era housing market.” This could be elaborated. Was transaction volume unusually low or volatile? Did the composition of buyers or properties shift? A few sentences of speculation, grounded in the summary statistics (e.g., lower N, different Dublin share), would be helpful.

**B. Context & Interpretation**
*   **Policy Evolution:** The paper notes the €500,000 cap has been fixed since 2017 despite ~40% price inflation. This is a critical point for policy implications. A short paragraph could more explicitly frame the analysis as a case study of the problems of *nominal* price caps in an inflationary housing market, contrasting it with schemes that index thresholds.
*   **General Equilibrium Considerations:** The analysis expertly captures the *local* distortion at the threshold. Acknowledging potential *general equilibrium* effects in a limitation paragraph would strengthen the paper. For instance, could the ceiling affect the overall supply of new homes or the price level of homes far from the threshold? While likely second-order and hard to estimate, noting this possibility shows scholarly caution.
*   **Comparison to Literature:** The literature review effectively places the paper within housing subsidy and bunching literatures. To sharpen the contribution, consider more directly contrasting the HTB’s sharp notch with the phase-outs or kinks studied in some of the cited papers (e.g., mortgage interest deductions). The clean ineligibility of second-hand homes is a particular strength worth highlighting again in the conclusion.

**C. Data & Mechanics**
*   **VAT Adjustment:** The 13.5% VAT adjustment for new builds is correct. A footnote confirming that this rate was constant throughout the sample period (2010–2025) would preempt a potential reader question.
*   **Sample Restrictions:** The rationale for the €100k–€1m price truncation is clear. For transparency, the appendix could report the number of transactions dropped by this and other filters (e.g., non-full-market-price).
*   **McCrary Test:** While the bunching framework is superior, noting that the result is consistent with a McCrary-style density discontinuity test can connect the findings to a wider methodological audience.

**D. Writing & Presentation**
*   **Abstract and Introduction:** The abstract and introduction are clear. Ensure the abstract explicitly mentions the key identification strategy (the second-hand placebo) and the main quantitative result (€11,700 price distortion).
*   **Terminology:** The term “difference-in-bunching (DiB)” is used in Table 2. While intuitive, it is non-standard. Consider using a more conventional description like “difference in bunching ratios” or simply presenting the difference as a separate estimate.
*   **Table Notes:** Table notes are comprehensive. In Table 2, specify that the standard errors for the DiB column are also bootstrapped (presumably by taking the difference in each bootstrap replication).

**Overall,** this is a well-executed study that makes a valuable contribution. The requested revisions are manageable and will enhance the paper’s rigor, clarity, and impact. I look forward to seeing a revised version.
