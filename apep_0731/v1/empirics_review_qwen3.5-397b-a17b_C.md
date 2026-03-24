# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-22T13:31:35.705012

---

# Review: The Audit Cliff That Wasn't

## 1. Idea Fidelity

The paper adheres closely to the core identification strategy outlined in the Original Idea Manifest. It successfully implements the multi-threshold bunching design using the IRS EO BMF data across 34 states, exploiting the variation in audit thresholds as proposed. The sample size (~555,000 organizations) matches the feasibility check. However, there is a notable deviation regarding data granularity. The manifest explicitly proposed supplementing the BMF with IRS Form 990 XML filings to distinguish *contributions* from *total revenue*, noting that some states threshold on contributions. The paper acknowledges this measurement mismatch in Section 4 but does not appear to incorporate the XML data to correct it, relying instead on `REVENUE_AMT` for all states. Additionally, the manifest proposed a "dose-response" tracing the bunching-threshold relationship; the paper implements this as categorical comparisons across four threshold levels rather than a continuous elasticity estimation. While these deviations do not invalidate the design, they represent a simplification of the proposed empirical strategy.

## 2. Summary

This paper exploits cross-state variation in charitable audit thresholds to test for strategic revenue reporting among US nonprofits. Using a multi-threshold bunching design on IRS data, the author finds no systematic evidence of revenue bunching at the modal $500,000 threshold, though significant heterogeneity exists across states and sectors. The results suggest that while compliance costs are substantial, they do not generate the behavioral distortions predicted by standard notch theory.

## 3. Essential Points

1.  **Measurement Error in the Running Variable:** The most critical threat to identification is the mismatch between the statutory threshold definition and the reported revenue variable. As noted in Section 4, several states (e.g., Pennsylvania) threshold on *contributions*, while the BMF provides *total revenue*. This introduces classical measurement error in the running variable relative to the policy notch. In bunching designs, measurement error in the running variable attenuates the bunching estimate toward zero. Given the paper's central claim is a null result, failing to align the revenue definition with the specific state statute (via the 990 XML data proposed in the manifest) risks conflating "no behavioral response" with "misaligned measurement." This must be addressed to credibly claim the cliff "wasn't."

2.  **Bootstrap Replications and Inference:** The standard errors are computed using only 200 bootstrap replications. In bunching estimation, where the counterfactual density is sensitive to sampling variation, 200 replications are insufficient to stabilize the standard error estimate itself. Standard practice in the literature (e.g., Kleven 2016) typically employs 1,000 or more replications. With only 200, the reported SE of 0.122 may be noisy, potentially affecting the confidence interval coverage. This should be increased to ensure inference is robust.

3.  **Counterfactual Stability:** Table 3 (Panel A) reveals that the bunching estimate $\hat{b}$ flips sign depending on the polynomial order (from $-0.098$ at order 6 to $0.066$ at order 8). While the author interprets this instability as evidence of a null result (i.e., no robust signal), it also indicates that the counterfactual density is not well-identified in the neighborhood of the threshold. If the counterfactual is this sensitive, the "null" may be an artifact of model specification rather than economic behavior. A more robust counterfactual approach (e.g., local polynomial regression or splines) should be considered to verify that the null is not driven by overfitting.

## 4. Suggestions

**Data Construction and Alignment**
The most impactful improvement would be to execute the data merge proposed in the manifest. You have access to the IRS Form 990 XML data; use it. For states that threshold on contributions (e.g., PA, OH), construct the running variable using `Contributions` rather than `Total Revenue`. For states that threshold on total revenue, use `Total Revenue`. This creates a "clean" sample where the notch is legally binding for every observation. Even if this reduces the sample size, the precision of the treatment definition will increase the power of the test. If the null result persists after aligning the revenue definition to the statute, the claim that "the audit cliff wasn't" becomes significantly stronger. Currently, a skeptic could argue that nonprofits are bunching on *contributions*, but you are measuring *total revenue*, masking the effect.

**Visualization of Density**
AER: Insights papers rely heavily on visual intuition. The text describes the density patterns (e.g., "172 vs 131" in the smoke test), but the main text lacks the canonical bunching histogram. You must include a figure showing the observed density of revenue around the $500,000 threshold overlaid with the polynomial counterfactual. Without this visual, readers cannot assess the fit of the counterfactual or the presence of "holes" vs. "spikes." Include separate panels for (a) the pooled $500K sample, (b) a high-bunching state (e.g., Connecticut), and (c) a placebo threshold in a no-mandate state. This visual triad would immediately communicate the heterogeneity and the validity of the placebo test.

**Refining the Difference-in-Bunching Design**
The DiD comparison between mandate and no-mandate states assumes that, absent the policy, the density around $500,000 would be identical in both groups. However, Table 1 shows meaningful differences: mean revenue is $6.3M in no-mandate states vs. $7.8M in mandate states, and the standard deviations differ by a factor of two. This suggests compositional differences in the nonprofit sectors of these states (e.g., Texas/Florida vs. California/New York). To strengthen the DiD, consider propensity score matching or entropy balancing to reweight the no-mandate states to match the observable characteristics (size, NTEE code, age) of the mandate states before comparing densities. This ensures the placebo group is a valid counterfactual for the treatment group's underlying distribution.

**Enforcement Intensity Proxies**
The heterogeneity analysis attributes variation to "enforcement intensity" but relies on anecdotal classification (e.g., "active charity registration units"). To make this empirical, construct a proxy for enforcement. You could use the state Attorney General's charity section budget, the number of staff dedicated to charity oversight, or the volume of enforcement actions filed (often available in state annual reports). Interact this continuous enforcement measure with the threshold indicator. If bunching is only present in high-enforcement states, it confirms that the null average is driven by lack of enforcement rather than lack of behavioral response. This adds significant policy nuance.

**Interpretation of the Null**
The discussion section offers three explanations (frictions, offsetting incentives, private ordering). I suggest prioritizing the "private ordering" hypothesis. Many large donors (foundations, government grants) require audited financials regardless of state law. If organizations near $500,000 are already seeking audits to secure funding, the state mandate is inframarginal. You can test this indirectly: examine bunching separately for organizations that receive government grants vs. those that do not (available in 990 Part VIII). If non-grant recipients bunch more than grant recipients, it supports the private ordering story. This moves the paper from "no effect" to "effect crowded out by private contracts."

**Standard Error Clustering**
You mention resampling within state, which is good. However, ensure that the bootstrap procedure respects the multi-threshold structure. When pooling across states with different thresholds, the variance structure may differ. Consider reporting state-clustered standard errors alongside the bootstrap SEs to show consistency. Additionally, given the sensitivity to polynomial order, consider using the "optimization frictions" bounds approach from Kleven (2016) to report a range of elasticities consistent with the data, rather than a single point estimate that flips sign with polynomial degree.

**AER: Insights Formatting**
Finally, ensure the paper meets the specific constraints of AER: Insights. This format typically limits text to 2,500 words and requires a specific layout for tables and figures. The current LaTeX setup is standard article class; you will need to adapt this to the specific AER template. Ensure the "Essential Points" of the contribution are highlighted in the introduction clearly, as Insights papers are meant to be policy-relevant summaries of broader work. The title is excellent ("The Audit Cliff That Wasn't"), but ensure the abstract explicitly states the policy implication in the first sentence to match the journal's style.

**Conclusion on Viability**
This is a promising design with a novel identification strategy. The cross-state variation is a significant improvement over single-state studies. However, the measurement error issue is a potential fatal flaw for a null result paper. If you can align the revenue variable to the state-specific statutory definitions using the XML data, this paper will be much harder to dismiss. The econometric execution is generally sound but needs tightening on inference (bootstrap reps) and counterfactual stability. With these improvements, the paper offers a valuable contribution to the literature on nonprofit regulation and compliance costs.
