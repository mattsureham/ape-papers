# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-22T13:30:59.327724

---

**Idea Fidelity**

The paper adheres closely to the manifest’s stated objective of exploiting cross-state variation in charitable audit thresholds using a multi-threshold bunching design. It draws on the EO BMF data, focuses on revenue bunching below threshold values that range from \$300,000 to \$2,000,000, and implements the polynomial counterfactual approach described in the idea. The difference-in-bunching comparison with no-mandate states, the emphasis on pooled and threshold-specific estimates, and the null result with heterogeneous state estimates all mirror the original research plan. The paper therefore honors the core identification strategy, data source, and research question outlined in the manifest.

---

**Summary**

The paper tests whether mandatory state-level charitable audit thresholds induce nonprofit organizations to “bunch” their reported revenues just below the compliance cliff, applying a multi-threshold bunching framework to 555,714 IRS EO BMF observations. The pooled bunching estimate at the modal \$500,000 threshold is indistinguishable from zero, and a placebo comparison with no-mandate states confirms that any excess mass near the threshold mirrors round-number reporting behavior. Heterogeneity analysis reveals state- and sector-level variation, but on average the audit mandates exert little detectable distortion on reported revenue.

---

**Essential Points**

1. **Measurement of the Running Variable** – The core identification rests on reported total revenue, but many states’ statutory thresholds are tied to \emph{contributions received}, not total revenue. This measurement mismatch can attenuate bunching estimates toward zero because the reported running variable does not reflect the cost discontinuity that organizations actually face. The paper acknowledges this issue but does not quantify its severity. Without showing that revenue and contributions are tightly correlated near the threshold, or otherwise adjusting the running variable, the null result could simply reflect measurement noise rather than a true absence of behavioral response.

2. **Validity of the Difference-in-Bunching Placebo** – The paper leverages no-mandate states as a placebo, implicitly assuming that these states provide a credible counterfactual for round-number reporting absent audit mandates. Yet states with and without mandates may differ systematically in enforcement, nonprofit composition, and accounting sophistication, all of which influence the baseline density. The DiB estimator would be biased if those differences persist within the \$25,000 window. The current analysis does not demonstrate that the density shape is similar across the two groups aside from round-number bunching, nor does it explore alternative control windows or matching on observable characteristics to ensure comparability.

3. **Sensitivity of the Main Estimate** – The pooled estimate at \$500,000 fluctuates in sign and magnitude with polynomial order and excluded-region width, raising concerns about estimator stability. While the paper interprets this instability as evidence of a null effect, it could also reflect the fragility of the counterfactual specification when the true response is modest. Without clearer motivation for the chosen baseline specifications (e.g., formal model selection or pre-testing), it is difficult to know whether the null result is substantive or an artifact of post-hoc specification choices. The authors should better justify their baseline and document how sensitive the inferences are to reasonable alternatives beyond reporting different polynomial orders.

If the authors cannot address or mitigate these issues convincingly, rejection may be appropriate.

---

**Suggestions**

1. **Improve Measurement of the Threshold-Relevant Running Variable**

   - Assemble data on reported contributions where possible, either from the EO BMF (if available) or by merging in subset extracts of Form 990 XML filings that explicitly report contributions. Even if contributions are missing for some organizations, showing a high correlation between total revenue and contributions near each threshold would strengthen the claim that the discontinuity is being measured. If the contribution-based threshold cannot be recovered, consider constructing a noise-adjusted running variable (e.g., revenue × average contribution share by state) or focus the main analysis on states whose statutes explicitly reference total revenue.

   - Alternatively, exploit states with thresholds on \emph{total revenue} exclusively in the pooled estimate to ensure the cost discontinuity aligns with the measured running variable. This could also serve as a robustness check: do states with revenue-based thresholds show different bunching patterns than those tied to contributions?

2. **Strengthen the Difference-in-Bunching Design**

   - Provide evidence that the revenue density in the ±\$25,000 window is otherwise similar in mandate and no-mandate states (e.g., compare moments or fit the same polynomial in the control windows) to justify the parallel-density assumption behind the DiB estimator. If systematic differences exist, consider augmenting the DiB design with observable controls (e.g., nonprofit size distribution, sector composition) or matching on pre-threshold densities.

   - Expand the DiB analysis to other thresholds and to placebo thresholds (e.g., compare \$300K mandate states to no-mandate states at \$300K) to demonstrate that the DiB estimator behaves as expected when no cost discontinuity exists. Showing that DiB is near zero at placebo thresholds would bolster confidence in the approach.

   - Alternatively, consider a synthetic control or binder-based approach where each mandate state is compared to a weighted combination of no-mandate states with similar density shapes. This would alleviate concerns about structural differences between the groups.

3. **Clarify and Justify Specification Choices**

   - Provide a systematic strategy for choosing the polynomial order and excluded region, possibly based on minimizing the mean squared error of the residuals outside the excluded window or using cross-validation. A diagram showing the fitted density for different orders would help readers assess whether higher-order polynomials overfit or whether lower orders unduly smooth out structure.

   - Report pre-specified robustness checks rather than ad-hoc ones. For instance, fix polynomial order and vary the width of the excluded window from both sides symmetrically, or use alternative bin widths in addition to the \$5,000 base. If the null result persists across a pre-registered grid, it is much more convincing than a post-hoc narrative that “the estimate bounces around.”

   - Present the polynomial fits graphically, overlaying the estimated counterfactual and actual density to show visually that the counterfactual is well-behaved and not influenced by the threshold region.

4. **Address State-Level Heterogeneity More Transparently**

   - Rather than reporting min/max values (which may be driven by sampling noise), decompose heterogeneity using observable state-level characteristics such as enforcement funding, nonprofit density, or audit fee levels. A regression of state-level bunching coefficients on these characteristics (with appropriate weighting) would show whether the heterogeneity is systematic or random.

   - Provide confidence intervals for the state-level estimates. The ranges reported (e.g., –1.15 to 1.32) are difficult to interpret without uncertainty; a state with a large point estimate but also a wide interval may not be informative. If standard errors are large, explain whether heterogeneity is statistically distinguishable from zero.

5. **Supplement with Alternative Evidence on Behavioral Responses**

   - Consider complementary tests such as analyzing the share of organizations that suddenly drop revenue just below the threshold after a few years (akin to bunching over time), or examining whether audit filings increase discontinuously right after each threshold (even if revenue bunching is absent, organizations may change audit behavior). 

   - Use the EO BMF or Form 990 data to track organizational size changes over time. If organizations are manipulating revenue, one might expect bunching to appear in growth rates or in the timing of large grants — even if the annual total revenue distribution looks smooth.

   - If possible, exploit recent reforms (e.g., in Arkansas 2023, Wisconsin 2024) as quasi-experiments. A difference-in-differences around a reform could reveal whether organizations alter their reporting or audit compliance when the threshold changes, providing a dynamic complement to the static bunching analysis.

6. **Interpretation of the Null**

   - The paper rightly emphasizes the null result, but it should be careful not to overstate policy implications. The absence of detectable bunching does not conclusively prove that the compliance cliff “does not distort organizational growth,” especially if detection is hindered by noisy revenue data. Framing the result as “we cannot reject the null within the precision bounds of our estimator” is more appropriate.

   - Discuss potential power limitations more formally. For example, simulate the detectable effect size given the sample size and variance in the vicinity of the thresholds. This would help readers assess whether the null is due to a true absence of behavior or insufficient power to detect a modest bunching response.

7. **Miscellaneous Enhancements**

   - Provide a table summarizing the statutory thresholds, which states fall into each category, and whether the threshold is based on revenue or contributions. This would make it easier to interpret the pooled estimates.

   - Clarify the bootstrap procedure—does it account for clustering at the state or state-threshold level? If the same states appear multiple times in the pooled estimate (because the threshold is shared), resampling at the state level is critical to avoid overstating precision.

   - Explain how time variation is handled. The paper mentions multiple years are available, but the analysis seems cross-sectional. If data span multiple years, it may be feasible to exploit within-organization variation to further validate the smoothness assumption (e.g., check if a given organization ever crosses the threshold and whether reported revenue jumps around it).

Implementing these suggestions would greatly strengthen the case for the null result, make the identification strategy more transparent, and provide policymakers with a firmer understanding of when audit thresholds do—or do not—induce behavioral distortion.
