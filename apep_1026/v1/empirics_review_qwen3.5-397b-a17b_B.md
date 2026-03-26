# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-26T23:58:33.202869

---

1. **Idea Fidelity**

The paper largely adheres to the original research design outlined in the manifest, successfully executing the core empirical strategy: exploiting staggered state-level marijuana legalization to identify effects on FHA mortgage shares using HMDA data and Callaway-Sant'Anna (CS) difference-in-differences. However, there are two notable deviations. First, while the manifest proposed using data from 2007–2023, the paper restricts the sample to 2018–2023. This is justified by the HMDA rule changes and the requirements of the CS estimator, but it reduces the number of pre-treatment periods for early adopters. Second, and more critically, the manifest proposed mechanism tests using county-level variation in cannabis employment (QCEW data). The paper primarily relies on state-year aggregates, only mentioning county-level heterogeneity in the discussion. This shift from a proposed triple-difference (state × county employment × time) to a standard staggered DiD reduces the power to detect the specific mechanism described in the manifest. Despite these deviations, the core question and identification strategy remain faithful to the original proposal.

2. **Summary**

This paper investigates whether state-level recreational marijuana legalization reduces the share of FHA-insured mortgages due to federal income exclusion rules. Using HMDA data from 2018–2023, the author finds no detectable aggregate effect on FHA market share when employing modern staggered DiD estimators, despite a significant bias in traditional two-way fixed effects models. The contribution is twofold: it bounds the economic magnitude of regulatory friction in credit markets, and it provides a stark empirical illustration of the biases inherent in TWFE estimators under treatment effect heterogeneity.

3. **Essential Points**

1.  **Aggregation Bias and Statistical Power:** The null result may reflect aggregation bias rather than a true absence of effect. Cannabis employment is highly localized (e.g., specific counties near dispensaries), yet the primary analysis is at the state-year level. Diluting treated units (cannabis workers) across entire states where legalization occurred likely attenuates the estimate toward zero. The paper acknowledges this in the discussion but treats it as a post-hoc explanation rather than addressing it empirically.
2.  **Indirect Mechanism Identification:** A fundamental limitation is that HMDA data does not contain borrower employment industry codes. The identification relies on the assumption that legalization increases the share of cannabis workers in the mortgage pool. Without direct measures of borrower industry or interactions with local cannabis employment density, the link between the policy (legalization) and the mechanism (income exclusion) remains inferential. This weakens the causal claim that the *exclusion* is what drives any observed changes.
3.  **Balance of Contributions:** The paper oscillates between being an substantive study of housing credit markets and a methodological cautionary tale about TWFE vs. CS estimators. While the methodological lesson is valid, emphasizing it too heavily risks overshadowing the economic null result. For an *AER: Insights* audience, the economic implication (that federal-state conflict has not yet scaled to distort credit markets) should remain the primary contribution, with the econometrics serving as support rather than the headline.

4. **Suggestions**

**1. Exploit Geographic Heterogeneity (County-Level Analysis)**
The most significant improvement would be to move the unit of analysis from the state to the county level, as originally envisioned in the manifest. Cannabis employment is not evenly distributed within legalized states; it concentrates in urban centers or specific agricultural zones.
*   **Action:** Re-estimate the CS model using county-year panels. HMDA data supports this granularity.
*   **Action:** Interact the legalization treatment with a measure of local cannabis industry presence. Since QCEW data often suppresses cannabis-specific codes due to confidentiality, consider using private datasets (e.g., Leafly or BDSA employment estimates by county) or proxy variables like the density of licensed dispensary locations per capita. A triple-difference specification (Legalized State × High Cannabis Density County × Post) would significantly sharpen identification and power. If the effect is real, it should be concentrated in high-density counties within treated states.

**2. Analyze Welfare Margins (Interest Rate Spreads)**
Even if the *share* of FHA loans does not change (perhaps because cannabis workers simply do not buy homes, or are denied for other reasons), the *cost* of borrowing for those who do qualify via conventional loans may be higher. The manifest proposed analyzing interest rate spreads, but the paper largely drops this after finding the share null.
*   **Action:** Test whether average interest rate spreads (`rate_spread` in HMDA) increased in legalized states relative to controls, conditional on borrower credit scores and LTV. If cannabis workers are forced into conventional loans, and if conventional loans carry higher rates for marginal borrowers compared to FHA, there should be a slight upward pressure on average rates in treated areas.
*   **Action:** Alternatively, examine denial rates. If cannabis workers apply for FHA and are rejected due to income source verification (even if not explicitly coded), denial rates might rise in treated areas among lower-income brackets.

**3. Strengthen the Methodological Demonstration**
The claim that TWFE is "lying" relies on the presence of negative weights and heterogeneous effects. While the cohort table supports this, a visual decomposition would make the case irrefutable for a general audience.
*   **Action:** Include a Goodman-Bacon (2021) decomposition plot. This will visually demonstrate which cohort comparisons are driving the TWFE result and explicitly show the negative weights assigned to later-treated states. This transforms the methodological claim from an assertion into a visual fact.
*   **Action:** Clarify the pre-trend discussion. The paper mentions a $p$-value of 0.86 for the CS pre-test. Include an event-study figure showing the dynamic coefficients leads up to treatment. This is standard practice in modern DiD and would reinforce the validity of the null result.

**4. Deepen the Discussion of Data Limitations**
The paper briefly mentions lender enforcement inconsistency but should more rigorously address the "invisible borrower" problem.
*   **Action:** Expand the data section to explicitly discuss the lack of industry coding in HMDA. Acknowledge that this is a "intent-to-treat" style analysis where the treatment (legalization) is observed, but the actual exposure (cannabis income) is not.
*   **Action:** Discuss potential misclassification. If lenders do not actively screen for cannabis income (as suggested in the discussion), the theoretical mechanism is broken at the implementation stage. This is a policy insight in itself: federal rules may be unenforceable at scale without specific reporting requirements.

**5. Refine the Narrative Balance**
To ensure the paper fits the *AER: Insights* format, the narrative should prioritize the economic finding.
*   **Action:** Consider renaming the paper to emphasize the economic null rather than the methodological divergence (e.g., "Federal Dissonance in Mortgage Markets: Evidence from Marijuana Legalization"). The TWFE vs. CS issue is a robustness section that became the main story; rebalancing this will make the paper more relevant to housing economists rather than just econometricians.
*   **Action:** In the conclusion, speculate on the threshold required for detection. Based on your power calculations, how large does the cannabis workforce need to be before this penalty becomes visible? This provides forward-looking guidance for policymakers.

**6. Minor Technical Corrections**
*   **Table 1:** The mean income is listed as "0" for both groups. This appears to be a data processing error or a suppression issue in HMDA (where income is often top-coded or blanked for privacy in public files). This needs clarification or removal to avoid confusion.
*   **Standard Errors:** Ensure that when moving to county-level data, multi-way clustering (state × year) is considered to account for serial correlation within states.
*   **Citation Format:** Ensure all citations in the text match the `.bib` file style required by *AER*. Some citations (e.g., `leafly2024`) appear to be industry reports; ensure these are distinguished from peer-reviewed literature in the references.

By implementing these suggestions, particularly the geographic disaggregation and the welfare margin analysis, the paper can transform from a methodological case study with a null result into a substantive contribution regarding the limits of regulatory friction in consumer credit markets.
