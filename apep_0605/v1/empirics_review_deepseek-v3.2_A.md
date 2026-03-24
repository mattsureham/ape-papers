# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-12T18:18:34.156352

---

**Referee Report: "No Resource Curse: Persistent Employment Gains from the US Fracking Revolution"**

**1. Idea Fidelity**
*Manifest not provided. Section skipped.*

**2. Summary**
This paper challenges the canonical "resource curse" hypothesis by examining the local economic effects of the US fracking boom. Using a staggered difference-in-differences design based on the geological lottery of shale play locations, the authors find that counties exposed to fracking experienced large, persistent gains in total employment (≈21%) and earnings (≈12%) from 2001-2023. Their central contribution is a formal test showing that employment gains during the boom period (pre-2015) were statistically indistinguishable from effects during the subsequent "bust" period, contradicting the prediction of boom-bust asymmetry.

**3. Essential Points**
The paper addresses an important question with a clear empirical strategy, but several critical issues must be resolved before it can be considered for publication.

1.  **Treatment Timing is Arbitrary and Potentially Mis-specified.** The analysis assigns a single, uniform treatment year to all counties within a given shale play (e.g., 2008 for all Marcellus counties). This ignores substantial within-play heterogeneity in the *intensity* and *timing* of drilling activity. A county where the first well was drilled in 2008 is treated identically to a county where activity only ramped up in 2012. This measurement error biases the dynamic treatment effects and undermines the clean "event time" interpretation. The authors must justify these specific year choices with references to production data and, ideally, move towards a continuous treatment measure (e.g., wells drilled per capita, total production) or a more granular, county-specific adoption year based on observable activity thresholds.

2.  **Definition and Test of "Boom-Bust Asymmetry" is Flawed.** The paper's core test defines the "bust" period uniformly as post-2014 for all treated units. This is problematic. Different plays experienced their production peaks and downturns at different times due to local geology, infrastructure, and oil vs. gas price dynamics (e.g., the gas-focused Marcellus bust preceded the oil-focused Bakken bust). Pooling all post-2014 periods imposes a homogeneous bust dynamic that does not exist. The asymmetry test must be re-specified to use play-specific (or better, county-specific) bust definitions based on local commodity prices or drilling activity declines. The current test risks missing true asymmetry that is masked by aggregation.

3.  **Parallel Trends Assumption is Not Convincingly Demonstrated.** The event study table (Table 2) shows several statistically significant negative coefficients in the pre-period (e.g., -0.1152*** at t-9, -0.1122*** at t-8, -0.0551** at t-6). While the coefficients closer to treatment are small and insignificant, these early, significant deviations are a serious concern. They suggest shale counties were on a different trajectory long before fracking began, potentially related to underlying economic or geographic factors correlated with shale deposits. The authors must: (a) discuss the economic meaning of these early gaps, (b) show that their main results hold when controlling for these pre-trends (e.g., by including county-specific linear trends or using the "imputation" estimator of Borusyak et al. (2024), which is more robust to such issues), and (c) provide a more honest assessment of the parallel trends limitation in the text.

**4. Suggestions**
The following suggestions are offered to strengthen the paper. Addressing the essential points is paramount; these recommendations can further enhance clarity, credibility, and contribution.

*   **Empirical Strategy & Identification:**
    *   **Continuous Treatment & Dynamics:** Beyond the binary treatment fix, consider presenting results from a distributed lag model using a continuous treatment measure (e.g., cumulative wells). This would more credibly capture the dose-response relationship and dynamic adjustment paths, showing how effects evolve with *intensity* of exposure, not just its onset.
    *   **Alternative Control Groups:** The robustness check using "not-yet-treated" controls is good. Extend this by implementing the `did_multiplegt` estimator (de Chaisemartin & D'Haultfœuille, 2020) or similar, which uses only clean comparisons between newly treated and not-yet-treated units, avoiding contamination from earlier-treated cohorts. This is a stricter test.
    *   **Spatial Spillovers:** A major threat to identification is that fracking's effects spill over into neighboring "control" counties (e.g., workers commuting, supply chain links). This would attenuate your estimated ATT towards zero. You should (1) discuss this as a caveat, and (2) conduct a sensitivity analysis where you redefine the control group to exclude counties within, say, 100 miles of a treated county, or use a spatial estimator.

*   **Analysis & Interpretation:**
    *   **Heterogeneity Analysis:** The paper would be much richer with a principled exploration of heterogeneity. Do effects differ by: the type of play (oil vs. gas)? Pre-existing county economic structure (rural vs. semi-urban, manufacturing base)? Region (Texas vs. Pennsylvania vs. North Dakota)? Such analysis can speak to *why* the curse didn't manifest—was it due to labor mobility, prior diversification, or state-level institutions?
    *   **Mechanisms Beyond Employment Levels:** The discussion of mechanisms is currently speculative. Strengthen it by analyzing intermediate outcomes: population (via migration data), housing prices, firm entry/exit by sector, and local government revenues/expenditures. Does the data show evidence of the hypothesized durable investments in infrastructure and housing?
    *   **Refine the "Asymmetry Test":** As noted in Essential Point 2, rebuild the asymmetry test. Define the "bust" start date for each county/play based on a local activity or price indicator (e.g., year after rig count peak). Then, estimate separate `ATT(g, t)` for `t` in the local boom and bust windows and test their equality. This is more conceptually valid.
    *   **Long-Run vs. Medium-Run:** The conclusion claims "permanent" gains, but the sample only covers ~10-15 years post-treatment for most cohorts. Temper this language to "persistent through two major busts" or "medium-run permanent." Acknowledge that institutional decay or other curse channels could operate over longer horizons.

*   **Presentation & Context:**
    *   **Clarify the "Resource Curse" Benchmark:** The introduction sets up a strong null hypothesis from cross-country literature. More explicitly bridge this to your subnational test. Which specific curse mechanisms (Dutch disease, volatility, institutional) are *testable* with your county-level, within-US design? Clearly state that your test is primarily about the *dynamic boom-bust asymmetry* and *local persistence* channels, not about national-level institutional decay.
    *   **Engage with Conflicting Evidence:** The discussion mentions Allcott (2018) finding Dutch disease (manufacturing decline) but net gains. This is crucial. Your finding of a 18% non-mining employment gain seems to contradict the Dutch disease mechanism. Analyze this directly: disaggregate non-mining employment into tradables (manufacturing) and non-tradables (services, construction). Does manufacturing shrink as services grow, resulting in net positivity? This would reconcile your findings with prior work and provide nuance.
    *   **Address Environmental & Social Costs:** The paper briefly mentions this as a limitation but then concludes with a strong policy-friendly message. This imbalance is problematic. Given the literature on negative externalities (Bartik et al., 2019), you must integrate a more substantial discussion. Could these persistent employment gains be offset by health costs, water contamination, or increased inequality? Acknowledge that a full welfare analysis is beyond your scope, but your results speak only to one dimension (labor market aggregates).
    *   **Tables and Figures:**
        *   **Table 1 (Main Results):** Panel B uses a TWFE specification interacting `Post` with `Boom/Bust`. This is inconsistent with the Callaway-Sant'Anna estimator used elsewhere and is vulnerable to the same heterogeneity biases the paper seeks to avoid. Recalculate this panel using the CS estimator to decompose the overall ATT into boom/bust averages.
        *   **Table 2 (Event Study):** The table is too dense. Move it to an appendix and replace it in the main text with a clear event-study *plot* (coefficients with confidence intervals). This makes the pre-trends and dynamics immediately visible.
        *   **Standardized Effects (Appendix Table SDE):** This is a useful addition. Consider moving a simplified version to the main text to help readers gauge magnitude.

*   **Minor Points:**
    *   The abstract states mining employment "more than doubled," which is correct for the ATT of 0.779 log points (exp(0.779) ≈ 2.18). However, in the summary statistics (Table 1), the *mean* mining employment in shale counties is 947, versus 165 in non-shale. The raw difference is large, but not a "doubling" relative to their own pre-period mean. Clarify this language.
    *   The description of the Callaway-Sant'Anna estimator is technically correct but very brief. Given the centrality of this method, include a footnote or a brief appendix section detailing how the weights are constructed and what the "overall ATT" represents (e.g., a weighted average of group-time ATTs).

**Overall Assessment:**
This paper tackles a significant question with a plausible design and an interesting, policy-relevant finding. However, the issues related to treatment timing, the definition of the bust period, and pre-trend violations are substantial and must be convincingly addressed. The suggestions provided, if implemented, would significantly improve the paper's credibility and contribution. I recommend a **major revision**. The authors have the core of a compelling paper, but it requires substantial work on identification and analysis to meet the high bar of a leading journal.
