# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T11:36:34.442819

---

**Idea Fidelity**

The paper adheres closely to the manifest. It exploits the five EEG capacity thresholds and the MaStR dataset, implements multi-cutoff bunching across all thresholds, and uses the 2021 expansion of the surcharge exemption in a difference-in-bunching setup, just as the manifest envisaged. The welfare back-of-the-envelope on capacity “left on the roof,” the comparison of thresholds with varying regulatory burdens, and the event study across EEG regimes were all in line with the original identification strategy and research question.

**Summary**

The paper documents massive strategic undersizing of German solar PV installations at every EEG regulatory threshold (10, 30, 40, 100, 750 kWp) using the full MaStR universe of 4.85 million units. A multi-threshold bunching design shows statistically significant excess mass below each cutoff, while a difference-in-bunching exercise around the 2021 reform and a 2010–2024 event study at 10 kWp trace how responses track regulatory incentives. Aggregate “capacity left on the roof” is estimated at 0.54 GWp, highlighting a measurable welfare cost of threshold-based regulations.

**Essential Points**

1. **Causal Interpretation of Multi-Threshold Bunching:** The large $\hat{b}$ estimates are consistent with strategic optimization, but the paper stops short of convincingly ruling out other mechanisms—especially mechanical clustering due to technological constraints or industry-standard panel sizes. For instance, 10 kWp installations may reflect the most common rooftop configuration, and 100 kWp installations may reflect commercial roofs. More must be done to demonstrate that the observed bunching is driven by regulatory incentives rather than pre-existing preference or feasibility distributions. Consider incorporating placebo thresholds without regulatory significance (e.g., 25 kWp or 60 kWp), exploiting spatial variation in ridge lengths, or directly testing whether bunching intensity correlates with contemporaneous changes in regulatory rents (surcharge levels, feed-in tariffs).

2. **Difference-in-Bunching Interpretation:** The 2021 reform is stated as a “natural experiment,” but the observed increase in bunching at 10 kWp post-reform undermines the assumed clean treatment variation. The narrative attributes this jump to compositional shifts (boom in small residential installations), yet that compositional change itself may be a response to the reform. Without isolating which part of the reform effect is causal, the difference-in-bunching estimates risk confounding. The placebo thresholds (100 and 750 kWp) also change post-2021, suggesting broader market dynamics. The authors need to clarify the identifying assumptions (e.g., parallel trends in bunching absent the reform) and provide evidence (e.g., pre-trends, control groups, synthetic counterfactuals) that the 2021 reform is the primary driver of bunching changes at the treated thresholds.

3. **Bootstrap Standard Errors and Sensitivity:** The wild variation in $\hat{b}$ across polynomial orders (e.g., 30 kWp flipping sign when using order 5) raises concerns about the robustness of the baseline estimates, especially for higher thresholds with sparse data. The paper should more carefully justify the chosen polynomial order, bin width, and exclusion interval, perhaps by reporting fit diagnostics or cross-validation results. The robustness checks (order 5 vs 7 vs 9) are insufficiently discussed; for instance, why does order 5 yield negative bunching at 30 kWp? Without this discussion, readers cannot gauge the reliability of the reported magnitudes.

**Suggestions**

1. **Strengthen Identification of Strategic Optimization**

   - **Placebo thresholds and tails:** The paper mentions round-number placebos at 5 kWp but does not present them. Displaying placebo plots or statistics for multiple non-regulatory thresholds (e.g., 20, 50, 60 kWp) would demonstrate that bunching is concentrated at the regulatory cutoffs. Additionally, examine whether the density just below the thresholds is materially higher than just above, to confirm the classic bunching signature.

   - **Covariate balance and technological constraints:** The paper should exploit the rich MaStR data to rule out non-regulatory explanations. For example, compare bunching patterns by installation type (rooftop vs ground-mount) and roof size proxies (e.g., module count or federal-state-level averages). If rooftop systems exhibit lot-level capacity constraints, one could regress density on the length of the roof (if available) or use module count as a proxy to ensure that thresholds, not geometric limitations, drive the bunching.

   - **Incentive variation:** The manuscript already links bunching intensity to the surcharge level in the event study. Make this more formal by directly regressing normalized bunching on the contemporaneous regulatory rent (e.g., surcharge per kWh or tariff differential) across years and thresholds. Showing that $\hat{b}$ scales with the monetary incentive reinforces the causal story.

2. **Clarify the 2021 Reform Strategy**

   - **Parallel trends:** Provide pre-2021 bunching trends for treated and placebo thresholds to assess whether the difference-in-bunching assumption is plausible. A figure showing $\hat{b}$ over time for the four thresholds would allow readers to judge whether post-2021 divergences are attributable to the reform.

   - **Mechanisms for compositional change:** The manuscript argues that the 2021 reform coincided with a residential boom that could explain the rise in 10 kWp bunching. This should be substantiated by showing installation counts and capacities by year—did the share of installations clustered around 10 kWp actually increase post-reform independently of the rate of bunching? If so, the reform may have had unintended scaling effects that deserve more explicit modeling (e.g., synthetic control or triple differences using installation type or federal-state rollout of complementary subsidies).

   - **Alternative counterfactuals:** Consider reconstructing counterfactual capacity distributions for the post-reform period using pre-2021 trends (analogous to synthetic control or distributional forecasting). This would help separate the reform-induced bunching change from secular growth in solar adoption.

3. **Polish the Methodological Transparency**

   - **Polynomial order and exclusion region:** Provide justification for the chosen bounds (12% below to 6% above) and polynomial degree. The robustness table shows that estimates at higher thresholds are very sensitive to these choices. Including figures of the raw histogram, fitted polynomial, and counterfactual for each threshold (as in Kleven 2016) would allow readers to visually assess the fit and the stability of $\hat{b}$.

   - **Bootstrap details:** The text says 500 Poisson bootstraps in the main section but 300 or 100 in tables, which should be harmonized. Also specify whether the bootstrap resamples bins or installations (the latter is more appropriate but computationally heavier). Reporting the distribution of $\hat{b}$ from the bootstrap could help evaluate skewness or non-normality.

   - **Confidence intervals around “capacity left”:** The welfare calculation (0.54 GWp) is compelling, but the uncertainty is not quantified. Include a confidence interval or sensitivity range based on the variation in assumed undersizing percentages (e.g., 2–10% of threshold). If possible, relate the welfare loss to monetary terms (e.g., cost per kWp, value of electricity), which would make the finding more policy-relevant.

4. **Expand Robustness and Heterogeneity**

   - **Time variation at other thresholds:** The event study focuses on 10 kWp. Extending this analysis to the other thresholds—particularly 100 kWp, where bunching is extreme—would show whether bunching intensity responds to regulatory changes (e.g., the introduction of mandatory direct marketing or tender reforms) over time. If data allows, plot $\hat{b}$ by year for each threshold to test whether bunching moves with changes in compliance costs.

   - **Spatial heterogeneity:** Germany's federal states differ in solar irradiation, electricity prices, and grid constraints. Testing whether bunching varies systematically across states (e.g., more intense in high-surcharge states or those with more supportive policies) would strengthen the external validity of the findings.

   - **Ground-mount interpretation:** The robustness table shows even stronger relative bunching for ground-mount installations at 10 and 30 kWp. Provide explanation—are these small utility projects that prefer to operate multiple sub-10 kWp arrays? If so, the policy implications differ, and further exploration (e.g., do ground-mount projects intentionally segment capacity to stay below tender thresholds?) would be valuable.

5. **Clarify the Narrative on Threshold Migration**

   - The manifesto emphasized “bunching migration” from 10 to 30 kWp after the 2021 reform. The current results show a decline at 30 kWp, which contradicts that expectation. Reconcile this by discussing whether the 30 kWp threshold was already “binding” before the reform (as the event study briefly notes) and what policy or technological changes caused its pre-2021 importance to fade. Without this discussion, readers may misinterpret the negative $\Delta \hat{b}$ at 30 kWp.

6. **Contextualize within Policy Debate**

   - The conclusion mentions smoothing thresholds into continuous schedules. To make the policy implications sharper, quantify the likely gain from elimination of specific thresholds (e.g., what fraction of the 0.54 GWp loss is driven by the 10 kWp surcharge exemption?). This would allow regulators to prioritize reforms.

   - Discuss whether the results imply that the existing tariffs/feed-in schemes could be redesigned using “soft” thresholds (e.g., phasing in direct marketing requirements gradually). Provide examples of jurisdictions with graduated systems to show that mitigation is feasible.

Implementing these suggestions would substantially increase the persuasiveness of the causal claims, contextualize the reform analysis, and clarify the robustness of the empirical approach.
