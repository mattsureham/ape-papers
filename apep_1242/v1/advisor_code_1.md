# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-01T13:11:45.601989

---

**Idea Fidelity**

The paper stays remarkably close to the original manifest. It deploys the PSC register data as promised, studies excess mass around the 25 % disclosure threshold, focuses on the “equal split” configuration, and explores heterogeneity by foreign ownership and sector. The “bunching” framing is admittedly more heuristic than in the manifest (there is no formal counterfactual from pre-2016 or ECCTA variation), but the core objective—documenting strategic ownership engineering at the 25 % notch—is honored. The identification strategy, however, has shifted from a difference-in-bunching approach anchored in policy dates to a cross-sectional configuration test; this limits the paper’s ability to speak to causal responses to the PSC launch or ECCTA tightening.

**Summary**

The paper documents that UK companies with exactly four individual shareholders exhibit an astonishingly high rate (34 %) of each owner sitting in the 25–50 % ownership band, a configuration that coincides with hitting the 25 % beneficial ownership disclosure threshold. This “equal-split puzzle” is hard to reconcile with random assignment of ownership bands and is concentrated among firms with foreign beneficial owners and in sectors typically flagged as AML risks. The finding implies meaningful regulatory leakage around the globally adopted 25 % disclosure rule.

**Essential Points**

1. **Identification of Strategic Behavior:** The paper interprets the configuration anomaly as evidence of strategic avoidance, but the argument is entirely cross-sectional. Without observing any temporal response to the 2016 PSC implementation or the 2023 ECCTA enforcement tightening, it is difficult to rule out alternative explanations—such as equilibria of joint ownership, inheritance patterns, or stale data—driving the equal-split pattern. The manifest promised difference-in-bunching leveraging policy dates; the current draft needs either to deliver that variation or carefully argue why the cross-sectional evidence can be interpreted causally (e.g., through structural assumptions validated by auxiliary evidence).

2. **Sample Representativeness and Selection:** The analysis relies on a systematic sample of 5 out of 31 snapshot chunks (~16 % of the register). The paper briefly acknowledges this in the discussion, but does not assess whether the sample is representative along key dimensions (e.g., company age, sector, dissolution status). If the missing chunks are correlated with the prevalence of equal splits (for instance, newer filings or specific registries), the reported excess mass may misstate the national picture. Provide diagnostics comparing sampled vs. unsampled chunks or, if feasible, analyze the full snapshot.

3. **Measurement and Inference Concerns:** The independence benchmark assumes that ownership bands are assigned independently across PSCs within a firm. That assumption is implausible if firms typically record all large shareholders in the 25–50 % band (since 25–50 % is the only band below full disclosure). Moreover, the equal-split indicator is very rare (0.69 %), making the nonlinear regression results fragile—R² is effectively zero, and the coefficient magnitudes are substantively tiny. Without a richer structural mapping from the data to firm incentives, the claimed “26:1 ratio” risks exaggerating strategic manipulation. Consider showing bounds or alternative benchmarks that do not rely on independence and ensuring inference accounts for the extreme rarity (e.g., rare-events logit or exact tests).

**Suggestions**

1. **Leverage Temporal Variation:** If possible, extend the analysis to include earlier snapshots (pre-2016) or at least the initial years after the PSC launch to implement the difference-in-bunching design from the manifest. For example, compare the prevalence of the equal-split configuration across cohorts of companies incorporated before versus after 2016. A sharp change in trends concurrent with the PSC rollout would strengthen the strategic-avoidance interpretation.

2. **Refine the Counterfactual:** Rather than the independence benchmark, consider constructing a more credible counterfactual distribution of ownership configurations. This could involve (i) conditioning on firm size/sector to compute expected joint band distributions under exogenous heterogeneity, or (ii) simulating ownership bands from firms with only domestic owners, under the assumption that foreign owners have the incentive to manipulate. Alternatively, reinterpret the configuration anomaly not as “excess mass” but as a descriptive pattern and focus on correlates and mechanisms.

3. **Characterize Dynamics Within Firms:** The paper hints at corporate entities as an avoidance mechanism and at higher rates among older firms. Deepen this by (i) examining whether firms with equal splits are more likely to have a corporate PSC, or to appear in multiple registries, (ii) studying whether company age or number of PSC filings predicts equal splitting, and (iii) checking whether equal-split firms are more likely to have addresses linked to company-service providers. These additional correlations (even in cross-section) build credibility for the strategic-behavior story.

4. **Broaden the Robustness Arsenal:** The current robustness checks focus on polynomial sensitivity and permutation inference, but several other diagnostics would strengthen the narrative: (i) replicate the configuration test on dissolved companies to see if the anomaly persists (addresses potential survivorship bias), (ii) explore sibling comparisons (e.g., firms with three PSCs vs. four) to isolate the effect of crossing the threshold, and (iii) test for data artifacts by checking whether the 25–50 % band is disproportionately used in filings due to reporting convenience. Including more robustness checks would increase confidence that the equal split is not a product of noise or reporting practices.

5. **Clarify Policy Implications and Limits:** The policy discussion is compelling but could be more precise. Acknowledge that the analysis cannot distinguish between manipulation aimed at regulatory avoidance versus normal ownership arrangements (e.g., equal partnerships) and that lowering the threshold may introduce its own compliance costs. Also, quantify the policy significance by estimating how many firms would flip to disclosure if the threshold fell to, say, 15 % (perhaps using simulation based on the current configuration distribution).

6. **Improve Interpretation of Regression Results:** The regression table (Table 3) could be simplified and made more informative. The R² values are nearly zero, and the substantive effect sizes are tiny relative to the baseline, so the text should emphasize percentage-point magnitudes (0.33 ppt rise) and relative changes rather than presenting the coefficients in isolation. Additionally, discuss the potential for omitted variables (e.g., company size, owner wealth) and how they might bias the estimates.

7. **Address Measurement Noise in PSC Bands:** The PSC register records only banded percentages, so the equal-split indicator is necessarily imprecise. Consider assessing the sensitivity of the result to alternative definitions (e.g., allowing one band to be 50–75 % or requiring “three out of four” to be in the 25–50 % band). This would demonstrate that the finding is not an artifact of the coding threshold.

By addressing these points, the paper would offer a more credible identification of strategic avoidance, better account for sampling and measurement issues, and provide more actionable policy guidance.
