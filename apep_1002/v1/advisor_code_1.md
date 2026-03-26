# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-26T16:23:39.334778

---

**Idea Fidelity**

The paper largely tracks the original idea manifest. It exploits the Czech abolition of the EET system as a natural experiment, uses the Eurostat STS_RB_Q data, and frames the question around whether formalization gains are persistent (the “compliance ratchet”). The cross-country DiD with Hungary, Croatia, Italy, Poland, and Sweden as controls is implemented, and the sectoral heterogeneity (cash-intensive versus others) mirrors the manifest’s emphasis on detection-intensive sectors. One notable divergence: the manifest emphasized within-Czech staggered DiD across the original four EET phases, but the paper only implements a cross-country design and reports phase-based heterogeneity (without a formal staggered treatment specification). If the authors intended to exploit the phased introduction more structurally, that element is missing.

**Summary**

The paper examines what happens when a functioning digital tax enforcement system is dismantled, using Czech Republic’s January 2023 abolition of the EET system as a quasi-experiment. A country-sector-quarter DiD shows a large aggregate increase in business registrations in the Czech Republic relative to five controls, but the effect is concentrated entirely outside the cash-intensive sectors that were the primary targets of enforcement. The authors interpret this as evidence that formalization persists (“compliance ratchet”) while administrative burdens keep business entry suppressed in non-cash sectors.

**Essential Points**

1. **Credibility of the Comparison Group & Inference.** The treated unit is a single country, and the six-cluster wild bootstrap yields a high p-value (0.32). While sector variation helps, the paper should more rigorously justify that the control countries’ post-COVID trajectories are valid counterfactuals. The presented event study has erratic pre-trends (large negative coefficients at t-7 and t-5) that suggest non-parallel dynamics even before the treatment; the paper needs to grapple with whether the aggregate effect could be driven by these baseline divergences rather than the abolition. The authors should consider synthetic control approaches or matching on pre-trends, and report placebo regressions that mimic the timing/location of the main treatment. Without bolstering the counterfactual argument, the causal claim is fragile.

2. **Interpretation of Sectoral Heterogeneity.** The core claim is that cash-intensive sectors show no reversal while other sectors do, supporting a ratchet effect in the shadow economy. However, the heterogeneity regressions simply split the sample and re-estimate the same DiD, which mixes within-country sector and between-country variation. Given that cash-intensive sectors also differ systematically in volatility, seasonality, and exposure to other policies (e.g., tourism shocks, COVID rebound), the current exercise cannot disentangle the compliance ratchet from persistent sector-specific confounders. The authors must strengthen this channel by either (a) leveraging the within-Czech phase variation more directly (e.g., compare Phase 1 vs Phase 4 sectors over time) or (b) showing that pre-trends for these groups are parallel and that control countries’ sector distributions behave similarly.

3. **Mechanism and Outcome Link.** The outcome is business registrations, yet the narrative focuses on formalization persistence (i.e., businesses remaining formal rather than reverting to informality). Registrations capture entry, not the retention of previously formalized firms, so it is unclear whether the null effect in cash-intensive sectors reflects persistent compliance or simply no change in entry. Furthermore, the positive effect in non-cash sectors might reflect administrative burden removal, but it could also be a rebound from macroeconomic shocks or measurement artefacts (e.g., the index denominator changes). The authors should either triangulate with another outcome—such as VAT filings, employment, or firm survival—or carefully reframe the claims to align with what registrations actually measure.

If the authors cannot convincingly address these three points, the paper should be rejected.

**Suggestions**

1. **Strengthen the counterfactual through robustness and alternative specifications.**  
   - Expand the event study to the entire pre-period instead of binning the earliest quarters. The large negative coefficients at t-7 and t-5 raise concern; plot the raw trends by country-sector or report descriptive graphs showing that Czech registrations track the control average pre-2020.
   - Implement a synthetic control (or generalized synthetic control) for the aggregate treated unit to see whether the observed post-2023 divergence persists when the counterfactual is constructed from a weighted combination of the controls. This method is particularly useful when there is one treated cluster.
   - Explore alternative control groups (e.g., other EU countries without EET-like systems) or allow the weights on controls to vary by sector, thereby reducing reliance on a handful of countries.
   - While presenting both cluster types is good practice, consider adopting inference methods tailored for few treated clusters, such as randomization inference with permutations of the treatment assignment over possible countries/quarters (if plausible) or reporting the treatment effect distribution under placebo country assignments.

2. **Make better use of the phase-staggered introduction within the Czech Republic.**  
   - Since EET phases differ by sector, the paper can implement an intra-country DiD: compare sectors that had differing lengths of enforcement exposure and examine whether sectors with longer exposure exhibit more persistent effects post-abolition. This design would rely less on cross-country assumptions and more on within-Czech counterfactuals.
   - A difference-in-differences-in-differences (DiDiD) specification could interact the Czech post indicator with sector phase or cash intensity, controlling flexibly for country-sector and quarter fixed effects. This would formalize the sector heterogeneity findings and better isolate whether the lack of reversal is specific to long-exposure or cash sectors.
   - Present graphs of sectoral registrations for the Czech Republic alone to visually assess whether the abolition response differs systematically by exposure.

3. **Clarify the policy mechanism and align the narrative with the data.**  
   - Acknowledge explicitly that “formalization persistence” is being proxied by new registrations and discuss alternative interpretations (e.g., administrative burden removal). If possible, supplement with other indicators such as VAT revenue shares (GOV_10A_TAXAG) or firm-level data on compliance costs to bolster the mechanism.
   - If reliance on registrations is unavoidable, make the causal chain more precise: EET abolition may affect entry (through reduced compliance costs) and the magnitude/direction of this effect could vary by sector for reasons unrelated to informality. Recast the compliance ratchet discussion in terms of entry dynamics post-abolition, emphasizing that the absence of a dropout spike in cash-intensive sectors suggests that these sectors did not shrink, which is consistent with persistence but not a direct proof.
   - Consider interviewing or citing qualitative evidence (e.g., tax administration reports or business surveys) showing that compliance behaviors changed during EET and remained in place after abolition. Even anecdotal support would strengthen the persistence argument.

4. **Address potential confounders and placebos in greater depth.**  
   - The pre-COVID period includes heterogeneous dynamics, and 2023 itself may coincide with other tax or macro policy shifts in the Czech Republic (e.g., VAT rates, subsidies, EU recovery funds). Add controls for major policy changes or macro variables (GDP growth, tourism arrivals) that could drive registrations and may differ between Czechia and controls.
   - Use sector-specific seasonal dummies or quarterly interactions to rule out that the observed aggregate effect is driven by cyclical recovery post-COVID or sector-specific shocks.
   - Expand the placebo battery by randomly assigning the treatment to control countries or to different years for the Czech Republic, and show the distribution of placebo estimates relative to the actual one.

5. **Enhance transparency and replicability.**  
   - Provide the code/data pipeline (especially if using public Eurostat APIs) to confirm the indexing and construction of the dependent variable.
   - Report the raw levels of registrations (not just indices) and discuss how the index is constructed, because interpretation depends on the base year and sector composition.
   - In the robustness appendix, include a table comparing Czech registrations to each control country before and after 2023 to assess whether any single country drives the result.

6. **Reconsider the narrative tone.**  
   - The conclusion is strong (“compliance ratchet appears real”), but given the inference challenges, temper the language to emphasize suggestive evidence rather than definitive proof.
   - The administrative cost story (positive effects in non-cash sectors) is intriguing, but the paper should avoid overgeneralizing from the sectoral split without deeper mechanistic evidence.

By addressing these issues and expanding the robustness checks, the paper would make a stronger, more credible contribution to the formalization and tax enforcement literatures.
