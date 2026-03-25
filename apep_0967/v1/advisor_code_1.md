# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T22:17:21.202393

---

**Idea Fidelity**

The submitted manuscript largely implements the research design outlined in the manifest. It studies the political consequences of the 2017 Ordonnances Macron CSE reform, constructs commune-level exposure from the INSEE Sirene registry, and applies a treatment-intensity difference-in-differences comparing 2012/2017 versus 2022 Le Pen vote shares. The paper likewise discusses the reduction in worker voice at firms with 50+ employees and frames the research question within “voice displacement” theories of populism. Two minor deviations from the manifest are worth noting: (1) the treatment measure is constructed from the current INSEE stock file rather than a pre-2017 snapshot (see Data Appendix), which alters the timing justification of the empirical strategy; and (2) while the manifest mentioned testing dose-response (11–49 vs. 50–99 vs. 100+), the paper focuses primarily on the 50+ cutoff with limited treatment heterogeneity. These differences do not undermine the core idea but should be clarified (see Suggestions).

---

**Summary**

The paper investigates whether the 2017 Ordonnances Macron reform, which merged CE/DP/CHSCT into a single CSE and substantially reduced worker representatives in firms with 50+ employees, increased support for the far-right Rassemblement National. Using commune-level share of large establishments as treatment intensity and exploiting 2012/2017 (pre-reform) versus 2022 (post-reform) presidential election results, it finds a precisely estimated null: no meaningful rise in Le Pen’s vote share associated with greater reform exposure. The null holds under multiple specifications, including binary treatment indicators, alternate exposure definitions, population weighting, and small-commune subsets, challenging “voice displacement” narratives that link institutional weakening to populist gains.

---

**Essential Points**

1. **Treatment Measurement Timing and Classical Measurement Error Claim**

   The treatment intensity is derived from the Sirene establishment stock as of 2026, yet the identification is premised on the pre-2017 distribution of large establishments. Post-reform firm dynamics (growth, closures, consolidation) can change the share of 50+ establishments differently across communes, potentially invalidating the assumption that exposure is predetermined. The data appendix acknowledges this and contends that any shifts induce classical attenuation. However, if large firms located in more urban/commercial communes are precisely those that grew faster post-2017 (or if the CSE reform itself affected firm size), the “measurement error” may be correlated with the outcome, biasing estimates unpredictably. The authors need to demonstrate that the 2026 shares are a valid proxy for the 2017 distribution (e.g., by showing stability in firm size composition over time using alternative data, or by instrumenting the 2026 share with a pre-2017 measure). Without such evidence, the key identifying variable may not be exogenous.

2. **Parallel Trends and Time-Varying Confounders**

   The event-study regressions show no significant pre-trend for Le Pen, but the paper relies on only two pre-treatment elections and a single treated post-election (2022), which limits the ability to detect subtle differential time trends. Moreover, communes with more large firms are systematically urban, and these areas experienced secular political realignment toward the left between 2012 and 2022 (as indicated, for example, by the significant pre-trend for Mélenchon). If urbanization or other parallel processes continued into the 2022 post-period in ways correlated with treatment intensity (e.g., faster income growth, demographic turnover, or non-CSE policy shocks), the DiD estimate could absorb these factors. The authors should provide stronger evidence that the only systematic change between 2017 and 2022 differing across high- and low-exposure communes was the CSE reform—for instance, by controlling for time-varying local covariates, allowing commune-specific linear trends, or exploiting within-commune changes in firm size (rather than levels) to pin down the reform’s causal effect.

3. **Ecological Treatment Definition and Worker Exposure**

   The treatment is defined as the share of establishments with 50+ employees, yet the hypothesized channel operates through workers employed in such firms losing representation. This share may poorly approximate the number of affected workers: a commune with a few very large firms (say 500 employees) could have low share of establishments but high employment exposure, while a commune dominated by many small 50+ establishments may have the opposite profile. Weighting by employment or by number of elected seats eliminated would capture the policy’s bite more precisely. The data appendix hints at this limitation but does not quantify how it might affect the estimates. Without aligning treatment with the actual worker population impacted, the study risks conflating “structural presence of large firms” with the intended “loss of worker voice,” weakening identification and interpretability.

---

**Suggestions**

1. **Strengthen the Treatment Measure**

   - Explore alternative sources (e.g., DADS/URSSAF, INSEE structural surveys) to reconstruct the pre-2017 distribution of firm sizes at the commune level. Even if only available at a coarser geography (e.g., canton/département), such a measure could validate that the 2026 share is a stable proxy.
   - If that is infeasible, consider constructing an instrument for the 2026 share using lagged measures or predetermined covariates (e.g., historical industrial composition, proximity to transport hubs) that predict the prevalence of large firms but should not respond to recent political shifts.
   - Alternatively, reframe the treatment as exposure in 2022 while explicitly discussing why post-reform firm size still captures treatment (e.g., because firm size tends to persist and post-reform growth is endogenous but not differential) to avoid the appearance of “using future information.”

2. **Bolster the Parallel Trends Argument**

   - Include commune-specific linear trends or interact treatment with time polynomials to test whether the null result is robust to allowing for diverging pre-trends. Since only two pre-periods exist, the trends could be identified by constructing an event-study that exploits the timing of reform implementation at the firm level (2018 vs 2019 vs 2020) if such data exist, rather than relying solely on election years.
   - Consider adding time-varying controls that might proxy for urbanization/labor market dynamics (population change, unemployment, construction permits, income) and examine whether results shift when these covariates are included. This would help rule out confounding due to differential trends in areas with large firms.
   - As an alternative falsification, use another political outcome that should not be affected by the reform (e.g., support for non-populist left candidates) to ensure that the 2022 difference is not driven by broader ideological shifts correlated with treatment intensity.

3. **Align Treatment with Worker Exposure and Mechanism**

   - Reconstruct exposure using employment counts (e.g., total employment in firms with 50+ employees) rather than establishment counts. If employee-level data are unavailable, approximate exposure via the number of establishments weighted by the average firm size in the relevant bracket (data on average employment per size class is often published by INSEE).
   - Link the treatment to the actual reduction in representative seats by estimating, for each commune, the pre-reform number of CE/DP/CHSCT seats based on the size distribution and null assumption of minimum representation, then compare it to the post-reform seat allocation. This would quantify how much “voice” was lost, which is more directly related to the theory.
   - Provide evidence that workers in the affected communes were indeed employed in firms subject to the reform (e.g., via sectoral employment shares). This would help assess whether the commune-level average exposure masks within-commune heterogeneity (urban communes could have both large exports and small non-treated firms).

4. **Address the Timing of Exposure and Political Response**

   - Discuss the fact that the 2017 presidential election occurred shortly after the reform announcement but before implementation, and the 2022 election happened well after. If the hypothesized causal chain requires time for workers to react politically, including 2017 as a post-treatment observation (as in a dynamic DiD) might capture an anticipatory effect. Testing robustness by treating 2017 as post or focusing on 2017–2022 only (while still controlling for pre-trends via placebo outcomes) would clarify the timing.
   - Conversely, consider whether the reform’s effects might dissipate or be absorbed differently across the years (e.g., if the largest firms complied with the CSE early but smaller ones delayed). Incorporating information on the timing of CSE establishment (if available) would allow for finer-grained variation.

5. **Explore Heterogeneity and Mechanism**

   - The suggestive positive effect in small communes (Table 4, column 5) deserves deeper exploration. Are these communes characterized by rurality, single-firm towns, or particular sectors? Disentangling this could reveal whether the reform had localized political consequences even if the national average is null.
   - Investigate whether turnout declines or Mélenchon gains are correlated with treatment intensity in a way that could mask Le Pen effects. The significant post-2017 coefficients for Mélenchon and turnout signal broader shifts that should be interpreted carefully; for example, if treated communes experienced lower turnout, this could mechanically dampen far-right vote shares. A decomposition of vote-share changes into turnout and support conditional on voting could clarify the mechanism.

6. **Clarify External Validity and Policy Implications**

   - Given that the result is a precise null, it would be helpful to articulate more explicitly what magnitude of effect the study is powered to detect and how that compares to theory (e.g., translating the treatment coefficient into a “lost representative per 1,000 workers” effect).
   - Discuss whether the null generalizes beyond the French case—might the institutional context (strong unions, capacity for social dialogue) mute the hypothesized response elsewhere?

Overall, the paper tackles an important and novel question with a large administrative panel, and the empirical framework is sensible. Addressing the points above would strengthen the credibility of the null finding and clarify the mechanisms at play.
