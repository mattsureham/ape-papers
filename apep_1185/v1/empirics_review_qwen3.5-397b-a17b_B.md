# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-31T10:44:58.548664

---

1. **Idea Fidelity**
The paper largely adheres to the core empirical strategy outlined in the Original Idea Manifest, utilizing CDC VSRR data, a staggered difference-in-differences design, and drug-type decomposition for mechanism testing. However, there is a significant deviation regarding the data construction promised in the manifest. The manifest explicitly stated an intention to extend the pre-period using NCHS age-adjusted rates (1999–2015) to capture pre-treatment trends for early adopters like Indiana and Wisconsin. The submitted paper does not appear to implement this merge; instead, it excludes Indiana and Wisconsin from the primary Callaway–Sant'Anna estimator due to lack of pre-period data in VSRR (which begins in 2015). This reduces the treated cluster count from five to three for the main causal specification, materially impacting statistical power compared to the proposed design. Additionally, while the manifest anticipated 36,000+ observations, the final sample is approximately 6,000 state-months due to exclusions for data suppression; this is acceptable but represents a contraction from the feasibility check.

2. **Summary**
This paper provides the first causal evidence on whether state-level kratom prohibitions increased opioid overdose mortality by removing a harm-reduction substitute. Using CDC provisional overdose data (2015–2025) and a staggered treatment design, the author finds no detectable effect of kratom bans on opioid mortality, despite a strong theoretical substitution hypothesis. The study leverages negative control outcomes (psychostimulants) to demonstrate that observed correlations in naive models are driven by differential trends rather than causal mechanisms, contributing a crucial null result to ongoing federal scheduling debates.

3. **Essential Points**
1.  **Statistical Power and "Precise Null" Claims:** The primary causal estimate relies on only three treated states (Arkansas, Alabama, Rhode Island) in the Callaway–Sant'Anna specification. While the result is statistically insignificant, the confidence interval (approximately -9% to +19%) does not rule out economically meaningful increases in mortality. Characterizing this as a "precise null" in the abstract and text is potentially misleading. The authors must explicitly calculate and report Minimum Detectable Effects (MDE) to clarify what magnitude of harm the study is powered to detect.
2.  **Data Construction Deviation (NCHS vs. VSRR):** The manifest proposed merging NCHS historical data to salvage pre-period observations for Indiana and Wisconsin. The paper drops these states from the main estimator instead. Given that Indiana and Wisconsin were the earliest bans (2014), excluding them loses valuable variation. The authors need to either implement the proposed NCHS merge to recover these observations or explicitly justify why the incompatibility between NCHS aggregate rates and VSRR provisional counts prevented this, as this decision drives the low cluster count.
3.  **Interpretation of Negative Controls:** The TWFE results show negative coefficients for negative controls (psychostimulants), which the author correctly identifies as evidence of confounding trends. However, the Callaway–Sant'Anna results should also display these negative controls. If the C-S estimator is valid, the negative control outcomes should show null effects there as well. Showing the C-S estimates for psychostimulants is essential to validate that the *causal* estimator also clears the specificity test, not just the descriptive TWFE model.

4. **Suggestions**
The following recommendations are intended to strengthen the paper's contribution to the *AER: Insights* audience, focusing on clarity, robustness, and policy relevance. These suggestions constitute the bulk of the review to assist in refining the manuscript for publication.

*   **Clarify Power and Minimum Detectable Effects (MDE):**
    For a null result paper, power analysis is not optional; it is the main contribution. Currently, the text states the confidence interval rules out increases larger than 21%. In the context of opioid overdoses, a 10% increase is policy-critical. I recommend adding a formal power analysis table (perhaps in the Appendix) that simulates the MDE given the specific variance and cluster structure of this data. If the study is only powered to detect a 25% increase in mortality, the abstract should temper the "precise null" language to "no detectable effect within the limits of state-level aggregation." This honesty strengthens the credibility of the finding.

*   **Revisit the NCHS Data Merge:**
    The decision to drop Indiana and Wisconsin from the C-S estimator is the weakest link in the identification strategy. The manifest suggested using NCHS age-adjusted rates to extend the pre-period. Even if the levels differ between NCHS and VSRR, the *trends* in pre-period NCHS data could validate the parallel trends assumption for WI and IN. I suggest attempting a hybrid approach: use NCHS data solely to test pre-trends for WI and IN graphically, even if the levels are not merged for the main regression. This would allow the authors to retain all five states in the TWFE visualizations and potentially justify including them in a modified C-S specification or at least bolster the parallel trends assumption for the full sample.

*   **Expand on Enforcement Heterogeneity:**
    The discussion mentions "enforcement leakage" as a key explanation for the null result. This is plausible but currently speculative. To strengthen this, the authors could incorporate a proxy for enforcement intensity. For example, some states might have had higher Google search interest for "kratom ban" or higher seizure counts (if available via DEA ARCOS data, as hinted in the discussion). Even a simple classification of "strict" vs. "lenient" ban states based on statutory penalties (mentioned in Section 2) could be used to split the sample. If the effect is null even in "strict" ban states, the argument against substitution is stronger.

*   **Visualizing the Event Study:**
    The text mentions dynamic event-study estimates (Sun-Abraham) but does not provide a figure. For an *Insights* paper, a clear event-study plot is vital. It should show the coefficients relative to the ban date for both opioids and the negative control (psychostimulants). Visually demonstrating that the opioid trend does not diverge from the psychostimulant trend post-ban would be a powerful addition to the mechanism argument. Ensure the confidence intervals are visible to reinforce the power discussion.

*   **Policy Context: Bans vs. Regulation (KCPA):**
    The introduction and conclusion mention Kratom Consumer Protection Acts (KCPAs) as an alternative to bans. Since the paper finds bans have no detectable mortality effect (neither harm nor benefit), the policy implication leans toward KCPAs being the superior marginal policy (regulating quality without criminalization). However, the paper could be strengthened by explicitly framing the null result as evidence that *criminalization* adds no public health value over the status quo. A brief paragraph comparing the cost of enforcement (arrests, prosecutions) against the zero mortality benefit would sharpen the policy insight for the *AER* audience.

*   **Title Adjustment:**
    The current title, "The Substitution That Wasn't," is catchy but perhaps too definitive given the power constraints. A title like "Substitution Effects of Kratom Prohibition: Evidence from State Overdose Mortality" might be more aligned with the nuance required when discussing null results with wide confidence intervals.

*   **Data Transparency:**
    Given the autonomous generation note, ensure the repository linked includes the exact code used to merge the CDC VSRR API data. The exclusion of 8 states due to suppression is standard, but providing the code that identifies these states allows for replication. Additionally, clarify if the "12-month ending" variable was handled correctly in the lagging/leading process for the event study, as rolling windows induce specific serial correlation structures that standard DiD might not fully capture even with clustering.

*   **Refining the "Negative Control" Argument:**
    The paper argues that because psychostimulant deaths also fell (in TWFE), the opioid fall is confounded. This is a strong argument. However, in the C-S specification (the causal one), the psychostimulant effect should be explicitly reported as near zero. If the C-S estimator corrects the confounding, it should correct it for the negative controls too. Reporting the C-S ATT for psychostimulants in Table 2 or the Appendix would close the loop on the identification strategy, proving that the C-S estimator successfully removes the differential trends that plagued the TWFE model.

*   **Addressing the "Rolling Window" Issue:**
    The data appendix notes the 12-month rolling window smooths treatment effects. This attenuation bias is mentioned but could be
