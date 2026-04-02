# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-02T19:34:50.443034

---

**Idea Fidelity**

The paper closely follows the original idea manifest. It exploits the UK FIT’s tiered structure with three simultaneous capacity thresholds (4, 10, 50 kW), uses the Ofgem installation register with precise capacity data, and leans heavily on the January 2016 merger of the 0–4 and 4–10 kW bands as a threshold-off natural experiment. The manifest highlighted the role of each remaining kink as an in-system placebo, the temporal evolution of bunching, and the welfare interpretation of the “capacity trap,” all of which appear explicitly in the paper. The authors also deliver the promised computations of excess mass, ratio comparisons, and welfare back-of-envelope arithmetic. There are no notable departures from the identification strategy or data source described in the manifest.

**Summary**

The paper documents extreme bunching at three capacity thresholds created by the UK Feed-in Tariff using more than 850,000 solar PV installations and a polynomial bunching framework. It shows that the merging of the 4 kW and 4–10 kW bands in 2016 collapses bunching at 4 kW while the 10 kW and 50 kW kinks remain, supporting a tariff-induced mechanism. The author then translates the excess mass into a “capacity trap,” estimating substantial foregone generation due to intentionally undersized systems.

**Essential Points**

1. **Interpretation of Post-Merger Polynomial Estimates**  
   The normalized excess mass at 4 kW remains elevated (38.2) even after the kink is removed, yet the paper relies on the raw ratio (threshold vs. just above) to argue that bunching disappears post-2016. This raises a credibility concern: the counterfactual density changes when the kink is switched off, and a degree-7 polynomial may not capture that shift, especially in a much smaller post-merger sample. The paper should show that the post-merger polynomial fit itself is not unduly sensitive to the changed distribution (e.g., by reporting fit diagnostics, alternative specifications, or re-estimating using local-linear counterfactuals) to ensure that the remaining excess mass is not an artifact of misspecification.

2. **Mechanism and Installer Optimization**  
   The identification hinges on installers optimizing capacity to remain just below thresholds. While the paper cites industry guides and points to the rapid rise in bunching ratios, it lacks direct evidence on installer behavior. Without stronger micro-level corroboration, alternative explanations (e.g., administrative rounding, engineer conservatism, or supplier package sizes) cannot be ruled out. The authors should present more systematic evidence such as installer-level heterogeneity, correlations with installer market concentration, or qualitative references that distinguish tariff-driven decisions from mechanical rounding.

3. **Welfare Calculation Anchoring**  
   The “capacity trap” welfare interpretation depends on the assumption that each bunching installation sacrifices a fixed amount of potential capacity (e.g., 0.5 kW). This figure is stated as conservative but lacks empirical grounding. The paper should either measure roof potential directly (e.g., combining capacity with roof characteristics) or provide robustness bounds around the foregone capacity estimate. Without this, the magnitude of the welfare loss remains speculative and could overstate the policy implication.

**Suggestions**

- **Robustness of Polynomial Counterfactual**: Provide additional checks around the counterfactual used for the excess mass. For example, report estimates using different polynomial degrees, bandwidth choices, or local-linear regressions to ensure the results are not driven by the particular functional form. A figure showing the fitted polynomial and the true histogram both pre- and post-merger would help readers assess fit quality.

- **Dynamic Learning and Anticipation**: The temporal dynamics table is compelling, but it would be useful to test formally whether bunching accelerates after government announcements or tariff degressions. For example, examine monthly rather than annual ratios, or exploit the quarterly tariff cuts to see how quickly installers react. This would strengthen the narrative that installers are fast-learning economic agents rather than merely following administrative norms.

- **Installer-Level Variation**: If possible, leverage postcode-level or installer-type variation to demonstrate that jurisdictions with more active installers or higher competition exhibit stronger bunching. Alternatively, comparing domestic versus commercial installations more systematically (beyond ratios) could reveal heterogeneous responses that reinforce the behavioral mechanism.

- **Post-2016 Distributional Shifts**: The merger likely changed the overall distribution of capacities (note the higher mean and standard deviation post-merger). Explore whether new bunching appears at other round numbers after the kink is removed, or whether installers simply spread out across the 0–10 kW interval. This would confirm that removing the kink leads to smoother density rather than a shift to a new threshold.

- **Alternative Explanations for 30 kW Bunching**: The placebo table shows strong bunching at 30 kW despite it not being a tariff knot. The paper notes planning or grid-connection thresholds may explain this, but it would strengthen the argument to document those thresholds more explicitly or to exclude that region from the comparisons if it overlaps with other regulations.

- **Welfare Bounds and Sensitivity**: When discussing foregone generation, present upper and lower bounds using different assumptions about forgone capacity (e.g., 0.3–1.0 kW) and per-kW yields. Also consider monetizing the welfare loss in terms of forgone payments at generator tariffs to allow comparisons with the FIT budget.

- **Policy Implications Beyond Solar**: The conclusion alludes to other tiered subsidies but could be expanded by discussing the general conditions under which such thresholds become distortionary (e.g., when the margin is easily adjustable and information is high). A short paragraph discussing how modern schemes (e.g., Smart Export Guarantee) have responded would contextualize the findings.

- **Data Transparency**: Since the registry is administrative, clarify whether any capacity entries are missing, misreported, or revised, and how the author deals with duplicates or data cleaning. Providing a data appendix with descriptive histograms and cleaning steps would improve reproducibility.

- **Placebo Ratios for Kinks with No Policy Change**: The identification could be strengthened by showing that the ratio at 10 kW and 50 kW did not decline after 2016. Currently, only the 4 kW ratio is tracked over time. Including the same time-series ratios for the other thresholds would make the “kink-off” experiment more compelling.

- **Link to Extensive Margin**: The limitations section notes that the extensive margin is not modeled. A brief discussion of how bunching might interact with the decision to install at all (e.g., whether higher thresholds discouraged marginal adopters) could motivate future research and clarify the scope of the current analysis.

These suggestions aim to reinforce the empirical credibility and sharpen the policy implications without altering the paper’s core contribution.
