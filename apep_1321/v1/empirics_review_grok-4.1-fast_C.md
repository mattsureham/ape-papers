# V1 Empirics Check — x-ai/grok-4.1-fast (Variant C)

**Model:** x-ai/grok-4.1-fast
**Variant:** C
**Date:** 2026-04-02T15:44:18.386482

---

### 1. Idea Fidelity
The paper largely pursues the original idea manifest, exploiting Ghana's 2019 mass MFI license revocations (347 MFIs + 23 S&Ls) as a natural experiment for a dose-response DiD on local economic activity via VIIRS nighttime lights, with geographic variation (high-exposure south vs. low north). It delivers the core identification using district-level lights and regional revocation intensity normalized by population. Key misses: (i) treatment is regional (16 units), not district-level as specified; (ii) no analysis of secondary outcomes (DHS 2014/2022 welfare, Findex 2017/2021 borrowing); (iii) annual (not monthly) lights data; (iv) no explicit mechanism tests (e.g., MFI-type decomposition, mobile money substitution beyond aggregate Findex trends).

### 2. Summary
This paper estimates the causal effect of Ghana's unprecedented 2019 microfinance purge on district-level economic activity using a dose-response DiD with satellite nighttime lights, finding a precise null result ($\hat{\beta} = -0.076$, RI $p=0.537$). The null challenges expectations of credit contraction harming output and is attributed to mobile money substitution, as financial inclusion rose amid falling traditional credit. It contributes novel evidence on fintech resilience during financial disruptions in developing economies.

### 3. Essential Points
1. **Regional treatment aggregation severely limits identification and power.** Treatment intensity is identical for all districts within a region (16 clusters), inherited from BoG reports rather than district-level MFI locations. This yields only 16 treated units, attenuates variation (SD=0.471 across regions), and induces mechanical spatial correlation. With district FEs, the design effectively compares regions; aggregate to regions upfront (as in robustness col. 4) and re-estimate power directly. Current setup risks understating effects due to intra-region heterogeneity (e.g., Accra suburbs vs. rural Ashanti).

2. **Parallel trends violated, biasing interpretation.** Event study shows significant pre-trend at $t-5$ ($\hat{\beta}=0.215$, $p=0.009$) and placebo 2017 fake post yields $\hat{\beta}=-0.114$ ($p=0.033$). Authors note it "reinforces the null," but this assumes direction; if high-intensity districts were converging pre-2019 (urban slowdown), true effect could be more negative. Restrict to 2015--2023 (drop 2014), use synthetic controls, or triple-difference with national trends. Without fixes, causal claims are untenable.

3. **No secondary outcomes or mechanisms undermine economic meaningfulness.** Null is only on aggregate lights (urban-biased proxy); no DHS/Findex results test welfare/credit substitution directly. Aggregate Findex trends are descriptive, not causal (no district variation). Manifest promised these; omitting leaves "resilience" interpretive, not evidenced. Add at minimum Findex borrowing shares by region or DHS consumption by exposure.

### 4. Suggestions
**Data and Measurement:** Obtain granular MFI locations from BoG registries or scraping (e.g., pre-2019 license lists) for true district-level intensity; Ghana has ~260 districts, so feasible. Switch to monthly VIIRS (VNP46M4) for sharper timing (May 2019 shock), extending pre-period to 2012. Normalize lights by district area or top-code outliers (>95th percentile) to reduce skewness (pre mean log=-1.615, SD=2.252). Supplement with DMSP-OLS pre-2014 for longer panel if needed, or Google Floodlights for sub-annual activity.

**Empirical Design:** Always report region-level DiD alongside district (power comparable to col. 4 robustness). For dose-response, demean intensity by regional mean or use region FEs + district trends. Event study: stack pre/post symmetrically, test joint pre-trend F-stat (should be $p>0.10$). Address few clusters via wild cluster bootstrap (e.g., R `boottest`) alongside RI; report sharp RI p-values by horizon. Binary treatment sensible (col. 3), but interact with baseline lights/urbanization for heterogeneity (high-baseline SDE=-0.0345 hints larger effects where MFIs mattered).

**Magnitudes and Power:** Null is plausible (SDE=-0.016 small vs. literature e.g., Chodorow-Reich 2014 bank stress SDE~0.1--0.3), SEs appropriate (RI validates clustering), but compute minimum detectable effect (MDE): with SD(Y)=2.252, power=80%, $\alpha=0.05$, needs $|\beta|>0.13$ (IQR intensity~0.5 yields 6.5% $\Delta$ lights). CI rules out large effects ($-$24% to +9% per unit), economically meaningful for regulators. Levels spec (+6.0, $p=0.08$) odd—likely post growth bias; log better for proportionality.

**Mechanisms and Extensions:** Exploit manifest's ideas: decompose by MFI type (insolvent vs. ceased) if BoG data disaggregates. Test substitution via mobile money agents (GSMA/BoG data, district-level) or ATM/branch closures (World Bank). Findex/DHS: regress 2021-2017 $\Delta$ mobile borrowing on intensity (IPW if nationally representative). COVID confound minor (lights resilient per Aiken et al. 2021); interact post x intensity x COVID waiver.

**Robustness and Presentation:** Add col. excluding 2019 (true post=2020+). Region-time trends (16x10=160 params feasible). Balance table: pre/post means by tertiles of intensity. Appendix: maps of intensity/lights, raw trends plot (high-intensity lights grow faster post, visually). Discuss lights' limits explicitly (ag/informal miss: <20% radiance per Chen & Nordhaus 2019); proxy via DHS ag income if available.

**Writing and AER Fit:** Title misleading ("Digital Safety Net" presumes mechanism unproven). Abstract: lead with null size/RI p-value. Intro: quantify "millions" (e.g., ~2M depositors per BoG). Discussion: benchmark SDE vs. priors (e.g., null < Banerjee et al. 2015 MFI~0.05). Shorten background; expand policy relevance (e.g., Kenya/India parallels). Fits Insights: novel shock, clean quasi-expt, precise null—but fix essentials first.

Overall, strong potential: null challenges orthodoxy credibly if pre-trends addressed. Revise and resubmit.
