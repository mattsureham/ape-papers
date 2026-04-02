# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-04-03T00:16:23.526430

---

**Review of "The Substitution Failure: Federal Enforcement Withdrawal and Ambient Air Quality Under Cooperative Federalism"**

---

### 1. Idea Fidelity

The executed paper deviates from the original manifest in three critical dimensions. First, and most consequentially, the manifest proposed a facility-level analysis using the Toxics Release Inventory (TRI) to directly estimate the "marginal product of a federal inspector" on facility emissions. The current paper instead employs county-level ambient PM2.5 concentrations from the Air Quality System. This aggregation introduces severe measurement error: PM2.5 is a diffuse pollutant with substantial contributions from wildfire, transportation, residential combustion, and secondary formation—sources largely orthogonal to EPA facility enforcement. The shift from point-source emissions (the direct target of inspections) to ambient concentrations breaks the mechanism chain necessary to interpret the result as the "production function of enforcement."

Second, the manifest specified key validation exercises that are absent from the current draft: (a) Rotemberg weights to identify which regions drive the result and assess the validity of the shift-share shock exposure; (b) direct tests of state substitution using state-level inspection volumes as an intermediate outcome; and (c) falsification using non-regulated chemicals and 100% state-enforcement states as pure controls. These omissions weaken the internal validity and policy relevance of the analysis.

Third, the manifest identified the 2017-2020 period as featuring "partial recovery then collapse" in staffing, suggesting a post-2020 analysis. The paper truncates at 2019, missing the opportunity to test for asymmetric effects during the subsequent staffing collapse and potentially confounding the interpretation of the 2019 attenuation.

---

### 2. Summary

Using a shift-share design that interacts historical EPA-region-level federal enforcement shares with the 2017-2019 decline in national OECA staffing, the paper finds that counties in high-federal-dependence regions experienced differential PM2.5 increases of approximately 18 percent (comparing top to bottom terciles) relative to low-dependence regions. While the point estimate is stable across trimming and leave-one-state-out exercises, the event study reveals significant pre-trends (joint F-test $p<0.001$), undermining the causal interpretation and suggesting that regions with higher historical federal enforcement dependence were already on divergent pollution trajectories prior to the staffing decline.

---

### 3. Essential Points

**1. The aggregation level invalidates the mechanism.** The shift from facility-level TRI emissions (proposed in the manifest) to county-level ambient PM2.5 severs the link between the treatment (federal facility inspections) and the outcome. EPA enforcement targets specific Clean Air Act violations at industrial point sources; it does not regulate wildfire smoke, mobile sources, or residential wood burning, all major PM2.5 contributors. If federal withdrawal affects PM2.5 at all, the effect should operate through measurable changes in facility emissions (TRI or NEI data). Without facility-level emission changes, the paper cannot distinguish enforcement effects from regional trends in economic activity, energy mix, or wildfire incidence. For a paper claiming to estimate the "marginal product of a federal inspector," facility-level emissions data are not merely preferred—they are necessary.

**2. Pre-trends invalidate the causal claim.** The event study shows large, significant pre-treatment coefficients (e.g., 2010: $-0.885$, $p<0.001$; 2013: $0.535$, $p<0.01$) with a joint F-test strongly rejecting parallel trends. This is not a minor "caution"; it is evidence that the identifying assumption fails. The shift-share design requires that, absent the staffing shock, high- and low-fed-share regions would have followed parallel trends. The data reject this. The current framing as "suggestive evidence" is insufficient for *AER: Insights*, which requires credible identification strategies. Either the authors must resolve the pre-trends through design (e.g., restricted pre-periods, synthetic controls) or reframe the paper as a descriptive correlation.

**3. Inference with 10 effective clusters is unreliable.** The treatment varies at the EPA region level (n=10) because FedShare is allocated proportionally within regions—all states in Region 9 receive the same share. Clustering standard errors at the state level (n=51) with region-level treatment induces severe downward bias in standard errors (Cameron & Miller 2015). The reported t-statistics (>3.8 for the main coefficient) are likely inflated. With only 10 effective clusters, conventional asymptotic inference fails. The paper requires wild cluster bootstrap (Cameron, Gelbach & Miller 2008), randomization inference, or at minimum region-clustered standard errors with the Carter-Schnepel-Steigerwald (2017) degrees-of-freedom correction.

---

### 4. Suggestions

**Return to facility-level TRI data.** The manifest correctly identified TRI as the appropriate outcome. I recommend estimating:
$$ \log(\text{Releases}_{f,t}) = \alpha_f + \lambda_t + \beta \cdot (\text{FedShare}_s \times \text{Post}_t) + \gamma \cdot (\text{StateShare}_s \times \text{Post}_t) + \varepsilon_{f,t} $$
where $f$ indexes facilities. This allows you to test whether federal withdrawal increases toxic releases specifically at facilities subject to federal oversight, rather than aggregating to ambient air which conflates enforcement effects with confounding regional trends. If data linking specific facilities to specific federal inspections exist (ICIS-Facility matches), an even sharper design would compare facilities within the same state that historically received federal versus state inspections.

**Address pre-trends through design, not caveat.** If TRI data confirm the pre-trend failure, consider:
- **Restricted pre-periods:** The 2010-2011 coefficients are particularly problematic. Estimating with a 2012-2019 window (as in Column 3 of Table 2) still shows pre-trends; try 2014-2019 if feasible.
- **Synthetic control:** Construct synthetic versions of high-fed-share regions using low-fed-share donors to explicitly model the counterfactual trend.
- **Interactive fixed effects:** Use Bai (2009) or factor models to account for differential trends correlated with FedShare.

**Fix the inference.** Report wild bootstrap p-values (999 replications) clustering at the EPA region level. Given the small number of clusters, also report randomization inference p-values based on permuting the shift (national staffing trajectory) across placebo years, or permuting the shares across regions. If the result survives these corrections, it is credible; if not, the significance is artifactual.

**Test state substitution directly.** The "substitution failure" mechanism requires evidence that state agencies did *not* increase inspections in response to federal withdrawal. Estimate:
$$ \text{StateInspections}_{s,t} = \alpha_s + \lambda_t + \beta \cdot (\text{FedShare}_s \times \text{Post}_t) + \varepsilon_{s,t} $$
If $\beta \approx 0$ or positive, states held constant or increased effort; if $\beta < 0$, states free-rode on federal presence. Without this intermediate outcome test, the "substitution failure" title is speculative.

**Include Rotemberg weights.** The shift-share literature now requires reporting Rotemberg (2019) weights to identify which regions drive the result and whether those regions have characteristics (e.g., mining intensity, Republican vote share) that correlate with other determinants of PM2.5. This is especially important given the pre-trend evidence.

**Explore heterogeneous effects by enforcement regime.** Test whether effects are concentrated in "delegated" states (where EPA retains oversight) versus "authorized" states (with primary enforcement authority). The substitution failure should be larger in delegated states where state capacity to backfill is weaker by design. This would sharpen the policy implication and align with the cooperative federalism literature.

**Clarify the 2019 attenuation.** The event study shows a null result in 2019 despite continued staffing decline. This could reflect (a) state substitution finally kicking in, (b) 2019 wildfire anomalies, or (c) recovery in specific programs. Investigate whether specific media (air, water, land) or specific industries drove the 2017-2018 spike but not 2019. If the effect is driven by a few large facilities in specific regions, this should be noted as a limitation on external validity.

**Reconcile magnitudes.** An 18% increase in PM2.5 from a 25% reduction in federal staff (which affects roughly 10-25% of inspections in treated regions) implies an implausibly large elasticity. A back-of-the-envelope calculation: if federal inspections decline by 25% in a region with 20% federal share, total inspections fall by 5%. An 18% PM2.5 increase from a 5% total inspection decline implies a compliance elasticity orders of magnitude larger than Shimshack & Ward (2005) estimates. This suggests either (a) the pre-trend bias is substantial, or (b) the ambient PM2.5 measure is capturing confounding trends (e.g., Western wildfire intensity correlates with Region 8-9's high fed share). Facility-level TRI data would resolve whether this magnitude is real or artifactual.
