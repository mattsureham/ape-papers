# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-22T13:31:29.779558

---

 **Review of "The Audit Cliff That Wasn't"**

**1. Idea Fidelity**

The paper partially fulfills the original research design outlined in the manifest. It successfully implements the core multi-threshold bunching estimator and the difference-in-bunching comparison between mandate and no-mandate states. However, it critically omits two key elements promised in the manifest: (i) the use of IRS Form 990 XML data to distinguish contributions from total revenue for states thresholding on contributions (e.g., Pennsylvania, Connecticut), and (ii) the planned "dose-response" analysis tracing bunching across the full continuum of threshold levels ($100K–$2M). Instead, the paper collapses thresholds into four discrete bins and drops lower thresholds entirely, sacrificing the continuous variation that would have strengthened causal interpretation. The shift from 33 to 34 states is minor, but the failure to address the contributions-versus-revenue mismatch—despite explicitly flagging the data solution in the manifest—represents a significant departure from the promised identification strategy.

**2. Summary**

This paper provides the first multi-state analysis of nonprofit revenue reporting at charitable audit thresholds, finding a precisely estimated null effect at the modal $500,000 threshold despite compliance costs of $10,000–$100,000. Using a difference-in-bunching design to net out round-number effects, the authors show that audit mandates do not generate the systematic distortions predicted by standard notch theory, though they document substantial heterogeneity across states and NTEE categories.

**3. Essential Points**

*Measurement Error Threatens Identification.* The paper’s central threat is a fundamental mismatch between the running variable (total revenue from the EO BMF) and the statutory threshold variable (contributions in several states; e.g., Pennsylvania thresholds at $100,000 in contributions). The manifest explicitly promised to resolve this using Form 990 XML data, which disaggregates contributions from revenue. By failing to implement this—or to subset the analysis to states using total revenue thresholds—the paper risks attenuating true bunching toward zero or capturing spurious bunching where the wrong variable is measured. The "well-identified null" may simply reflect measurement noise.

*Functional Form Sensitivity Undermines the Null Result.* Table 4 reveals that the pooled $500K bunching estimate oscillates between $-0.098$ (degree 6) and $+0.066$ (degree 8), with the baseline $-0.046$ (degree 7) effectively arbitrary. When a genuine bunching response exists, it is typically robust to polynomial order; the instability here suggests the counterfactual density is poorly identified, likely due to the underlying revenue distribution being ill-suited to high-order polynomial fits. The claim of a "well-identified null" is therefore overstated—the result is indistinguishable from specification error.

*Inference on Difference-in-Bunching Is Incomplete.* Table 3 reports a difference-in-bunching estimate of $0.00057$ but provides no standard errors, precluding hypothesis testing. Given that the estimate is derived from four sample proportions across two groups, analytical standard errors are easily computable. Without them, the reader cannot assess whether the audit-specific component is statistically different from zero (or from the placebo round-number bunching documented in Table 5). The paper’s central claim—that the 7.8% density gap is "attributable to round-number effects"—lacks statistical foundation.

**4. Suggestions**

*Address the Contributions-Revenue Mismatch.* Either restrict the main analysis to the subset of states that explicitly threshold on total revenue (verifying this via state statutes) or implement the promised Form 990 XML merge to construct the correct running variable for each state. If the XML data cannot be obtained, report results separately by threshold type (revenue vs. contributions) and acknowledge the measurement error bias explicitly. The current "robustness section" addressing this concern is insufficient given that it constitutes a first-order threat to internal validity.

*Implement Donut-Hole Robustness as Primary Specification.* The sensitivity analysis in Table 4B varies the excluded region width, but the baseline ($25,000) is arbitrary. Given the sensitivity to polynomial order, adopt a "donut hole" specification excluding progressively wider regions around the threshold as the preferred estimation strategy. If the null result persists across donut widths (e.g., $10K to $50K), this would substantiate the claim of no behavioral response far more convincingly than the current polynomial sensitivity analysis, which shows the sign flips with specification.

*Clarify the Economic Meaning of Negative Bunching.* The paper reports state-level estimates ranging from $-1.15$ (New Jersey) to $+1.32$ (Connecticut). Negative bunching is theoretically problematic: it implies a "hole" in the distribution below the threshold or excess mass above, which contradicts the audit-avoidance mechanism. Discuss whether these negative estimates reflect: (a) small-sample noise in states with few organizations near the threshold, (b) misreporting *upward* to signal quality (audits as a reputational good), or (c) misspecification of the counterfactual. If (a), report precision-weighted averages or shrinkage estimators rather than raw means. If (c), the pooled null may mask offsetting misspecifications.

*Report Standard Errors for DiB and Placebo Comparisons.* Compute analytical or bootstrap standard errors for the difference-in-bunching estimator in Table 3. Additionally, Table 5 reports placebo bunching at round numbers *other than* $500K (e.g., $300K, $400K). For a clean placebo comparison, report the bunching ratio at $500K specifically for no-mandate states. If the placebo $b_{500K}$ is similar to the mandate-state estimate, this would powerfully support the "round-number effects" interpretation. Currently, the reader must infer this comparison from nearby round numbers.

*Exploit the Continuous Threshold Variation.* The manifest promised a "dose-response" analysis across 33 thresholds. The current paper bins thresholds into four categories ($300K, $500K, $750K, $2M$), losing identifying variation. Consider a meta-regression framework
