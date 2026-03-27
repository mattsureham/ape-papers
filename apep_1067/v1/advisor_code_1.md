# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-27T13:36:43.102911

---

**Idea Fidelity**

The paper substantially adheres to the original idea manifest. It uses the National Bridge Inventory (2000–2018) to estimate bunching at the SR=50 federal replacement-funding threshold, implements a pre/post MAP-21 natural experiment for identification, and documents heterogeneity (owner types) and placebo tests, as envisioned. The bunching estimator and McCrary test are employed exactly as described, and the reform is treated as weakening the SR<50 incentive. No key element of the manifest—data source, threshold, or empirical strategy—is missing.

---

**Summary**

This paper documents sharp bunching of bridge sufficiency ratings just below the SR=50 federal replacement-funding threshold and shows that the excess mass attenuated significantly after MAP-21 eliminated sufficiency-based apportionments. Using the full National Bridge Inventory, it links this discontinuity to strategic manipulation by state DOTs (through owner heterogeneity) while placebo thresholds and formal density tests support the causal interpretation. The findings suggest that condition-based funding formulas can distort the very metrics they rely upon, echoing Goodhart’s Law.

---

**Essential Points**

1. **Causal interpretation of the pre/post MAP-21 comparison requires stronger support.** The paper treats the 2013–2018 period as “post-treatment” and attributes the drop in bunching solely to the elimination of the SR<50 incentive. However, several other secular changes (e.g., updates to inspection guidelines, changes in bridge stock age/composition, the 2008–2009 recession, or shifts in federal funding levels) could affect the SR distribution. Without showing that the post-period would have continued the pre-trend in the absence of MAP-21, the diff-in-bunching estimate may capture contemporaneous confounders. Please formalize a parallel-trends-style argument, either by showing that bunching at other thresholds or in placebo years did not move in 2013, or by controlling for changes in bridge composition, inspector guidance, or aggregate funding outside of MAP-21.

2. **State-level variation in the MAP-21 effect is not addressed.** The identification rests on the assumption that MAP-21 uniformly eliminated the incentive across all states, yet state DOTs may have differed in their dependence on HBP funds, inspection practices, or the timing of implementation. Without exploiting this cross-sectional variation, it is difficult to rule out alternative stories (e.g., some states voluntarily reformed rating procedures). Please incorporate heterogeneity across states (e.g., by pre-MAP-21 HBP_share or funding dependency) and show that those states with the strongest incentive pre-2013 exhibit the largest post-2013 decline in bunching. This would bolster the causal link to the funding formula rather than other concurrent national trends.

3. **Robustness of the bunching estimate to the counterfactual specification and aggregation level needs clarification.** The polynomial estimator is sensitive in many tax-bunching applications to bandwidth, order, and binning. While Table 5 shows sensitivity to polynomial order, there is no discussion of how the integer binning and exclusion window ([46,53]) affect the results, nor of alternative nonparametric specifications (e.g., local linear regression, spline). Moreover, the normalized excess mass is reported at the national level despite the potential for state-level heterogeneity in inspection precision. Please report robustness checks that either (a) use alternative bandwidths/orders/bins or (b) estimate the bunching at the state-year level and then aggregate (with state fixed effects and year trends) to ensure the national figure is not driven by a few large states with idiosyncratic distributions.

If these critical issues cannot be resolved, I would be reluctant to recommend publication.

---

**Suggestions**

1. **Strengthen the MAP-21 counterfactual narrative.** Consider implementing an event-study-style graph showing bunching intensity year by year (or every two years), with vertical line at 2012, to demonstrate that the decline in excess mass is concentrated after the policy change and not part of a longer downward trend. Complement this with a placebo reform year (e.g., pretend MAP-21 occurred in 2005) to show no spurious pre-trend. This visual would also help readers calibrate the magnitude of the attenuation relative to pre-trends.

2. **Leverage state-level funding dependency to augment identification.** Use the pre-2013 share of state bridge funding coming from the HBP (or HBP apportionments per bridge) to create a continuous “treatment intensity” variable. Estimate whether states with higher dependence saw larger bunching declines post-MAP-21. This could be implemented in a triple-difference framework: compare state-years above/below a funding dependency cutoff before and after 2012. Doing so would convert the analysis from a national pre/post comparison to a gradient-based effect, making the inference more credible.

3. **Address the possibility of reporting digit preference or institutional inertia.** Even absent strategic gaming, bridge inspectors may exhibit digit rounding (e.g., favoring values ending in 0 or 5), which could generate apparent bunching at certain points and might interact with SR=50. Please present the full SR histogram to show that the spike is specific to 49/50 rather than a broader tendency to report round numbers. Similarly, inspect whether the distribution of ordinal component scores (such as structural adequacy) changes discontinuously at SR=50, which would help isolate whether the manipulation occurs in specific inputs rather than the composite index.

4. **Provide more detail on standard errors and multiple testing.** The bootstrap procedure resamples bridge IDs but it is not clear whether the bootstraps are clustered by state or inspection crew, which could matter if the manipulation is state-driven. Consider clustering at the state level (or state-year) when estimating the difference-in-bunching and heterogeneity results, and report those standard errors alongside the current ones. Additionally, while you conduct multiple placebo thresholds, adjust for multiple hypothesis testing or at least discuss the implications for statistical inference (the p-value at SR=60 might not be informative absent such an adjustment).

5. **Clarify the residual bunching post-MAP-21.** The paper notes that some bunching persists after 2012 despite the elimination of the sufficiency-based formula. Is this residual mass explained by legacy procedures, or might states still find it worthwhile to keep bridges just below 50 even under the new structurally-deficient deck-area rule? Provide evidence from the structural condition data (e.g., inspect the frequency of bridges with low deck-area and SR around 50 post-2012) to argue whether the remaining bunching reflects inertia or a new incentive.

6. **Discuss policy implications with nuance.** The conclusion emphasizes that MAP-21 “reduced but did not eliminate the incentive.” If the residual bunching is due to institutional inertia rather than financial incentives, policies aimed purely at reforming formulas may not suffice. Consider discussing whether auditing, data verification, or inspector training could complement formula redesign to improve data integrity.

In sum, the paper addresses an important and novel question with a large dataset and an intuitive design. Strengthening the causal narrative around MAP-21, exploiting state-level heterogeneity, and bolstering robustness would elevate the contribution and increase confidence in the policy implications.
