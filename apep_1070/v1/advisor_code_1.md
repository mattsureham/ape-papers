# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-27T13:31:14.974468

---

**Idea Fidelity**

The paper closely tracks the original idea manifest. It leverages county-level H-2A certification data merged with the Census Quarterly Workforce Indicators race/ethnicity panel for NAICS 11, implements the county-quarter-ethnicity triple-difference, and uses the Bartik-style shift-share instrument. The research question—whether the H-2A expansion displaced Hispanic domestic farm workers—is addressed as proposed. No key elements of the identification strategy or data sources appear missing relative to the manifest. The paper even augments the outline with outcome heterogeneities and placebo industries, which were anticipated in the manifest.

---

**Summary**

This study examines whether the rapid expansion of the H-2A agricultural guestworker program displaced Hispanic domestic farm workers. Using a county-quarter-ethnicity triple-difference design and QWI employment flows, the author documents a negative naïve OLS association but finds a null effect once county-level H-2A exposure is instrumented with a Bartik shift-share. Placebos in non-H-2A industries and event-study evidence support the interpretation that selection—not substitution—drives the OLS correlation.

---

**Essential Points**

1. **Instrument Credibility and Exclusion Restriction**  
   The Bartik shift-share instrument hinges on the assumption that national H-2A growth interacts exogenously with a county’s 2018 share of state-level certification to predict local growth. However, counties with higher 2018 shares may systematically differ in unobservables that also shape the response of domestic Hispanic employment to national H-2A trends (e.g., crop mix, mechanization capacity, or local policy). The paper should provide evidence that the instrument is not capturing such heterogeneous trends—e.g., balance tests of observable covariates or falsification regressions using pre-2018 outcomes (even if H-2A data are limited) to demonstrate that the shift-share is orthogonal to prior employment dynamics. Without this reassurance, the IV estimates risk inheriting similar selection bias to OLS.

2. **Triple-Difference Parallel Trends**  
   The critical DDD assumption is that, absent H-2A expansion, Hispanic versus non-Hispanic trends would have been similar across high- and low-H-2A counties. Yet the event-study only decomposes effects by expansion period and lacks a clear pre-period trend analysis, especially given that H-2A data start in 2018. The absence of a robust pre-trend test leaves open the possibility that counties with rising H-2A were already on distinct Hispanic/non-Hispanic trajectories. The authors should exploit the QWI panel prior to 2018 more explicitly—for example, interact county H-2A intensity forecasts (e.g., based on 2012–2017 crop patterns) with ethnicity in the pre-period to test for differential trends—or, alternatively, control for flexible Hispanic-specific county trends.

3. **Timing of Outcome Measurement versus Treatment**  
   Treatment is aggregated at the annual level whereas outcomes are quarterly, yet the empirical strategy does not fully address the timing mismatch or potential within-year substitution patterns. Furthermore, H-2A certifications are tied to employment demand, but actual arrivals and work spells may lag certification and vary seasonally. The manuscript should clarify how the annual H-2A measure aligns with quarterly QWI outcomes (e.g., do quarterly outcomes reflect the same fiscal year’s certifications or lagged values?), and ideally perform robustness checks with lagged H-2A exposure or seasonal averaging to ensure the results are not driven by timing misalignment.

If these issues cannot be satisfactorily addressed, the paper’s causal claims may not be credible. Otherwise, the work is promising.

---

**Suggestions**

1. **Strengthen Instrument Validation**  
   - Report first-stage relationships separately for Hispanic and non-Hispanic counties to demonstrate that the Bartik induces variation that is not driven by differential trends or other local shocks.  
   - Include a “leave-one-state-out” IV (Bartik) estimate or use alternative instrument constructions (e.g., interact national growth with county pre-trends in crop mix) to show the results are not sensitive to the specific weighting.  
   - Conduct a falsification test using outcomes that should not respond to H-2A even if the instrument were invalid (e.g., non-agricultural Hispanic employment in counties where H-2A is absent) to reassure that the instrument is not simply capturing unobserved Hispanic demand shocks.

2. **Enhance the Pre-Trend Analysis**  
   - Although H-2A data are unavailable before 2018, the paper could exploit the fact that counties’ baseline (2010–2017) Hispanic vs. non-Hispanic employment ratios are observable. Interact those pre-period employment levels with post-period national H-2A growth to test whether counties destined to receive more H-2A exhibited divergent ethnic employment dynamics before the program ramped up.  
   - If possible, construct a proxy for pre-treatment H-2A intensity (e.g., from NAWS data, FLC filings, or administrative anecdotal reports) to check whether the parallel trends assumption holds conditional on that proxy.  
   - Consider including county-specific linear (or quadratic) time trends interacted with ethnicity to soak up remaining preparatory dynamics, and report how this affects the key coefficients.

3. **Clarify and Robustify Timing**  
   - Explain in the text whether the annual H-2A counts correspond to fiscal years and how they map onto the calendar quarters in QWI. If the treatment moves annually, consider varying the aggregation level of the outcome (e.g., annual averages) to match the treatment frequency or use lagged treatments to allow for implementation delays.  
   - Re-estimate the models with quarterly (or seasonal) H-2A intensity constructed from monthly/quarterly FLC filings if available; if not, use smoothing to create a quarterly treatment proxy.  
   - Test whether the results differ when restricting attention to harvest-intensive quarters (typically Q2–Q4) versus off-season quarters to see if the implied substitution is temporally consistent with actual H-2A work periods.

4. **Address Potential Spillovers and General Equilibrium Effects**  
   - Discuss whether H-2A expansion in one county could affect neighboring counties’ labor markets (through commuting or regional crop cycles) and whether the county-level clustering adequately captures these spillovers. A spatial lag or controls for neighboring counties’ H-2A growth would help ensure the estimates capture within-county effects.  
   - Provide more discussion (or empirical evidence) on whether the non-Hispanic comparison group is appropriate: if non-Hispanics are themselves being displaced in ways correlated with H-2A, the DDD may understate displacement of Hispanics relative to a more neutral counterfactual. Consider alternative comparison groups (e.g., different industries or genders) or justify why non-Hispanics are a valid control.

5. **Augment Mechanism Evidence**  
   - The positive earnings effects are intriguing; explore whether this pattern is consistent across high- and low-H-2A counties or whether it reflects compositional shifts (e.g., losing low-wage workers).  
   - Examine whether separations declines are driven by layoffs or by workers exiting agriculture entirely, possibly using QWI flow data to distinguish between quits and layoffs if available.  
   - Investigate whether hiring declines are concentrated among young workers or new entrants, as hypothesized. This could be proxied with age-specific QWI cells or by focusing on counties with recent school closures.

6. **Data Transparency and Reproducibility**  
   - Provide more details (perhaps in the appendix) about the matching procedure between worksites and counties, including any manual corrections and the treatment of multi-county employers.  
   - Clarify how suppressed QWI cells (common in smaller counties) were handled—whether they were dropped and how this might bias the sample toward larger counties.  
   - Include code or algorithm descriptions for constructing the Bartik instrument and the QWI treatments to aid replicability, possibly linking to a data appendix.

7. **Broader Contextualization**  
   - The conclusion currently rests heavily on the null IV effect; consider acknowledging alternative interpretations more fully (e.g., the local average treatment effect identifying counties with high baseline H-2A shares, which may not generalize).  
   - Discuss policy implications cautiously, stressing that these results pertain to employment counts and may not generalize to wages or worker well-being.  
   - Situate the findings within the ongoing debate about whether H-2A programs crowd out domestic labor in certain regions (e.g., high-mechanization counties) by exploring heterogeneity across crop types, mechanization intensity, or county demographics.

By addressing these points, the paper would substantively strengthen its causal claims and contribution.
