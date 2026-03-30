# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-30T11:26:00.560963

---

**Idea Fidelity**

The paper largely follows the original manifest. It leverages the staggered, NAICS-specific timing of SBA size standard increases, employs USAspending county-by-NAICS data, and focuses on geographic redistribution of set-aside procurement, mirroring the stated research question. That said, the implementation simplifies the treatment definition (2-digit NAICS sectors instead of the 200+ six-digit industries mentioned in the manifest) and relies on a relatively small panel of 19 sectors, which both reduce the granularity of the identification strategy and omit the richer variation promised in the idea. The identification assumption—sector-level timing exogenous due to legislative rotation—remains central, but the paper should explain more carefully how the reduction to two-digit sectors preserves the original staggered variation's credibility.

**Summary**

This paper investigates whether SBA size standard increases concentrate federal small-business procurement geographically. Exploiting staggered sector-level treatment waves (2013, 2014, 2016) and USAspending data, the author finds that treated sectors lose about 85 counties receiving set-asides and exhibit a measurable rise in the county-level Herfindahl-Hirschman Index, suggesting a crowding-out of smaller, geographically dispersed firms by newly eligible mid-sized firms. These findings suggest a trade-off between expanding small-business eligibility and preserving geographic breadth in procurement.

**Essential Points**

1. **Granularity of treatment and the implied causal mechanism:** The manifest highlights NAICS-specific increases affecting 200+ industries, but the analysis aggregates treatment to 2-digit sectors. This aggregation masks within-sector heterogeneity in both treatment timing and magnitude of threshold changes. It is crucial to clarify whether every six-digit NAICS within, say, Manufacturing experienced the size standard increase simultaneously, or whether there is meaningful variation that could be exploited or that contradicts the assumption of uniform treatment. Without such clarity, the reader cannot assess whether the comparison group (never-treated sectors) provides a valid counterfactual or whether treated and control units differ systematically.

2. **Parallel-trends and sector-specific confounders:** The identifying assumption is that the SBA rotation timing is exogenous after controlling for sector and year fixed effects. Yet the analysis presents limited evidence on pre-trends, and the treatment cohorts coincide with major macro shocks (e.g., the 2013 sequestration, the 2016 manufacturing slump). The placebo in Table 3 shows that total procurement also falls, which could indicate sector-level shocks rather than the treatment effect. The paper needs richer diagnostics—event-study graphs with confidence intervals, tests for differential trends, and possibly inclusion of sector-specific linear trends or covariates—to bolster the parallel-trends claim. Without such diagnostics, the causal interpretation of the concentration effects is tenuous.

3. **Limited power and interpretation of results:** With only 247 observations and three cohorts, the standard errors are large and some core outcomes remain imprecise (e.g., HHI and metro share). Moreover, the treatment effects vary across cohorts and the leave-one-out exercise produces wildly different point estimates (even sign changes). These patterns raise concerns about over-interpreting noisy estimates. The paper should either strengthen the empirical design (e.g., move to more granular data) or temper the claims to reflect the limited statistical power and potential sampling variability.

**Suggestions**

1. **Enhance treatment coding:** Return to the manifest’s promise of industry-level variation. If the data permit, code treatment at the six-digit NAICS level or another finer taxonomy so that the timing and magnitude of size standard changes are captured more precisely. Even if effect estimates remain at the sector level for reporting, running the DiD at finer granularity would increase the number of treated units, improve power, and allow for more credible balance between treated and never-treated industries.

2. **Document the treatment rule more fully:** Provide a table listing each sector’s size standard change—year, old vs. new threshold, and the exact NAICS range covered. This helps the reader assess the uniformity of treatment within sectors and clarifies the policy mechanism. It also allows for heterogeneous treatment-intensity analyses (e.g., larger increases in employee caps might yield stronger geographic effects) rather than a simple binary Post indicator.

3. **Expand the empirical strategy to account for trends:** Present event-study plots with confidence intervals for each outcome, ideally derived from the Callaway-Sant’Anna estimator, to show whether the parallel-trends assumption holds. Consider augmenting the specification with sector-specific linear trends or relevant covariates (e.g., sectoral employment growth, trade exposure, procurement appropriations) to soak up confounders. Alternatively, use synthetic control-type comparisons or match treated sectors to similar controls to reinforce identification.

4. **Explore heterogeneity across geography and set-aside types:** Since the theory emphasizes mid-sized firms located in metropolitan hubs, the paper could test whether the concentration effect is driven by a few “thick” counties (e.g., showing changes in the share of top decile counties) and whether metropolitan areas disproportionately gain. Additionally, examine whether the effects differ for major set-aside categories (e.g., HUBZone vs. generic small-business set-aside), which might respond differently to size standard changes.

5. **Address the placebo on total procurement:** The drop in total procurement in treated sectors undermines the claim that observed geographic shifts are driven solely by small-business set-asides. Investigate whether this reflects mechanical reclassification (some contracts now counted as set-asides) or broader sectoral shocks. One approach is to decompose total procurement into its components (set-aside vs. open competition) and track whether the reduction stems from the non-set-aside portion. Alternatively, use a triple-differences strategy comparing the treated sectors’ set-aside outcomes to their open-competition outcomes before and after treatment.

6. **Leverage employment data for mechanisms:** Since the manifest mentions county-NAICS employment and the narrative emphasizes firm size-location correlations, incorporate QCEW data to show that treated sectors’ procurement shifts toward counties with larger average firm size or higher employment concentration. This would help make the “crowding-out gradient” more than suggestive and tie the reduced county count to actual economic structure.

7. **Clarify the role of never-treated sectors:** Provide balance tables comparing treated and never-treated sectors over pre-treatment periods (procurement size, concentration levels, trends, employment, etc.). If the levels differ substantially, discuss how that might bias the ATT estimates and what corrections (e.g., weighting, matching) could mitigate these biases.

8. **Discuss external validity and policy implications cautiously:** Given the data and power constraints, avoid broad policy claims about undermining SBA objectives without acknowledging the limitations. Instead, frame the findings as suggestive evidence that deserves further investigation, perhaps by combining confidential Census data (as in Denes et al.) with public procurement records to unpack the geography of displacement.

Implementing these suggestions would strengthen the credibility of the identification strategy, provide richer evidence on the proposed mechanism, and make the empirical narrative more defensible for an AER: Insights readership.
