# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T11:37:25.996176

---

**Idea Fidelity**

The submitted paper generally adheres to the original idea outlined in the manifest. It exploits geological variation in coal seam depth—proxied by the historical share of surface mines—to instrument for the current production-weighted share of surface mining, and uses this instrument to estimate the effect of surface mining on stream specific conductance in Appalachian coal counties. All key components are present: the endogenous variable (surface mining share), a geology-based instrument grounded in Carboniferous-era stratigraphy, controls for coal production intensity and demographics, and the primary outcome of water quality (specific conductance). One area where fidelity could be improved is in explicitly leveraging the USGS seam depth measurements described in the manifest; the current paper uses the historic mine-type composition (“geological surface share”) as the instrument. If the intent was to directly use measured seam depth, that connection should be clarified. Otherwise, the paper stays true to the core idea of nature-as-randomizer based on coal seam accessibility.

**Summary**

The paper introduces a geology-based instrumental variables strategy to isolate the causal effect of surface versus underground coal mining on stream water contamination in Appalachian counties. The instrument—historical prevalence of surface mines—is argued to reflect ancient geological constraints, which in turn shift the feasible mining method. Two-stage least squares estimates reveal that a county moving from all-underground to all-surface mining would experience an increase in specific conductance on the order of one standard deviation, with robustness checks and weak-instrument-robust inference supporting the result.

**Essential Points**

1. **Instrument Validity – Geological vs. Economic Channels:** The paper uses the historical share of surface mines as a proxy for geological seam depth. However, this variable may still reflect long-run economic and policy choices (e.g., infrastructure investment, local regulatory regimes, or historical demand) rather than pure geology. While the author mentions balance tests and placebo exercises, more evidence is needed to demonstrate that the instrument’s variation is orthogonal to unobserved determinants of water quality beyond mining method. For example, can the instrument be shown to predict contemporary water quality only in counties with active coal mining, but not in counties where mining ceased decades ago, as the manifest suggested? Or can the instrument be swapped for direct seam depth measures (from USGS drillhole data) to reinforce the geological story? Without stronger support, the exclusion restriction remains doubtful.

2. **Confounding by Mining Intensity and Spatial Spillovers:** Controlling for total coal production is helpful, but the 2SLS setup still risks conflating method with broader intensity or spatial heterogeneity. Surface mining is concentrated in particular watersheds, and its contamination can spill over into neighboring counties. The instrument (county-level geological surface share) may correlate with watershed-level exposure or with proximity to major valley fills that influence downstream water quality. The paper should address whether the instrument predicts conductance even when using watershed-level outcomes, or whether controlling for adjacent-county production changes the estimate. Absent these checks, the IV estimate could be picking up spatially correlated contamination rather than a pure method effect.

3. **Measurement of Outcomes and Treatment:** Specific conductance is averaged at the county level using all available monitoring stations, but monitoring density likely varies with mining activity; counties with more surface mines may also have more monitoring, introducing measurement heterogeneity. Similarly, averaging over stations may obscure within-county heterogeneity; surface mining tends to impact headwater streams disproportionately. The paper should clarify how measurement error in both treatment and outcome might bias the results, and whether re-weighting by watershed area or using median rather than mean conductance alters conclusions. Without addressing these measurement issues, the interpretation of the estimated effect (“one standard deviation”) could be misleading.

If these essential issues cannot be satisfactorily addressed, the paper should be rejected.

**Suggestions**

1. **Strengthen the Geological Instrument:**  
   - *Leverage direct seam-depth data*: The manifest emphasizes USGS NCRDS USTRAT drillhole data, which contains precise depth information. Incorporating these measurements—perhaps as county-level averages or quantiles of the depth to the top of economically exploitable seams—would anchor the instrument more directly in exogenous geology. If the historical surface-mining share is retained, supplement it with seam-depth controls to demonstrate robustness.  
   - *Instrument plausibility tests*: Implement the placebo suggested in the manifest: use counties where mining ceased before surface mining technology was prevalent (pre-1970s) and show that the instrument does not predict current water quality in these places. This would bolster the claim that the effect operates through current mining method rather than enduring geological baseline differences.  

2. **Refine the Treatment and Outcome Definitions:**  
   - *Disaggregate the treatment*: Instead of (or in addition to) the fraction of production from surface mines, consider using the share of surface mines by count or the count of surface mines per unit area. Some counties may have a few large surface mines producing most coal, while others have many smaller ones—this heterogeneity could affect local water quality.  
   - *Address monitoring bias*: Provide descriptive statistics on the number of monitoring stations per county and assess whether monitoring density correlates with the instrument. If monitoring is more intensive in surface-mining counties, average conductance could be upward-biased. One solution is to construct watershed-level outcomes (e.g., for HUC-8 or HUC-12 units) and assign mines to watersheds; alternatively, use panel data on station-year observations with station fixed effects to minimize measurement error.  

3. **Clarify Interpretation of 2SLS Estimates:**  
   - *Local average treatment effect*: Explicitly state the complier population—counties where geological constraints (as measured) shift the mining method. Discuss how these counties compare to the broader Appalachian coal economy.  
   - *Magnitude context*: The paper cites macroinvertebrate declines above 500 μS/cm, but the 2SLS change is relative to county means. Consider presenting the effect alongside policy-relevant thresholds (e.g., EPA chronic or acute criteria) or computing the implied increase in days exceeding a given contamination level.  

4. **Deepen Robustness and Sensitivity Analyses:**  
   - *Spatial controls*: Add controls for neighboring counties’ geology or mining activity to mitigate spillover concerns. This can be done via spatial lags or by including averages of the instrument and treatment in adjacent counties.  
   - *Alternative outcomes*: While the paper mentions selenium and sulfate in the manifest, the main text focuses on conductance. If data permit, estimate effects on selenium concentrations, total dissolved solids, or biological indicators to reinforce the mechanistic link.  
   - *Weak identification diagnostics*: The reported first-stage F-statistics seem mixed (e.g., 6.17 in one specification). Report the exact Kleibergen-Paap statistic, and consider showing the full Anderson-Rubin confidence interval values or a figure to convey the precision visually.  

5. **Address Potential Economic Confounders:**  
   - *Historical economic data*: Include indicators of historical coal investment (e.g., number of mines opened pre-1980, or historical employment) to test whether the instrument captures persistent economic sorting. If such variables are available, control for them or show that they are orthogonal to the instrument after accounting for observed covariates.  
   - *Regulatory differences*: Since states differ in enforcement and counties in permitting stringency, augment the control set with measures of state-level environmental budgets or pre-1970 surface mining intensity to ensure that differences in regulation do not confound the instrument-outcome link.  

6. **Make the Exclusion Story More Transparent:**  
   - Expand the discussion of why the instrument affects water quality solely through mining method. For example, argue explicitly that seam depth is uncorrelated with natural salinity sources because the Carboniferous strata are internally homogeneous over the relevant spatial scale, or that erosion/tectonic processes that affect depth do not simultaneously affect watershed geochemistry when conditioning on controls.  
   - Provide a directed acyclic graph (DAG) or schematic to illustrate the assumed causal pathways, which would help readers assess the plausibility of the exclusion restriction at a glance.  

7. **Engage with Related Literature:**  
   - The paper cites several relevant studies but could position itself more clearly relative to Hendryx et al. and others who document correlations between surface mining and health. Explicitly state how your IV estimates compare to their OLS estimates and what this implies about the magnitude of bias in previous work.  
   - Discuss how the findings relate to policy debates over surface mining bans or reclamation funding, perhaps by translating the conductance increase into downstream economic costs or health risks.

By addressing these suggestions, the paper can strengthen its credibility and policy relevance while clearly articulating the causal pathway from ancient geology to contemporary water quality.
