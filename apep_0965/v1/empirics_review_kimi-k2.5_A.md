# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-25T22:09:25.048761

---

 **Referee Report for "Tit-for-Tat in the Heartland: EU Retaliatory Tariffs and Local Labor Markets"**

---

### 1. Idea Fidelity

The paper pursues the original idea faithfully. It employs the Quarterly Workforce Indicators (QWI) to construct a county-level continuous difference-in-differences design exploiting EU Regulation 2018/886, using pre-tariff (2017Q4) employment shares in NAICS 312, 331, and 336 as the treatment intensity measure. The identification strategy relies on the political targeting of products (bourbon, motorcycles, steel) to argue that exposure variation is quasi-exogenous. The empirical approach—county and time fixed effects with state-clustered standard errors—matches the proposed research design. The paper appropriately focuses on the extraterritorial labor market channel and quarterly employment dynamics.

---

### 2. Summary

This paper estimates the local labor market effects of the European Union’s 2018 retaliatory tariffs on politically targeted U.S. exports. Using quarterly administrative employment data (QWI) for approximately 2,800 counties, the author finds that while employment in targeted industries (beverages, primary metals, transportation equipment) declined significantly in high-exposure counties, total manufacturing employment was unaffected. The results suggest that retaliatory tariffs generated costly worker reallocation—higher separations with stable hiring—within counties rather than net job destruction, implying that trade retaliation may function primarily as a political signaling device rather than an instrument of sustained economic damage.

---

### 3. Essential Points

**1. Fundamental Confounding with U.S. Section 232 Tariffs.** The identification strategy is critically compromised for one-third of the treatment variation. NAICS 331 (Primary Metals/Steel) counties simultaneously experienced the *positive* employment shock of U.S. Section 232 import protection (enacted March 2018) and the *negative* shock of EU retaliation (June 2018). The paper acknowledges this as a “net effect” but does not adequately address the severe bias this introduces. If import protection boosted steel employment while retaliation reduced export demand, the null finding for total manufacturing employment could reflect offsetting biases rather than genuine resilience. This is not a minor robustness concern—it is a fundamental threat to the causal interpretation of the primary specification.

**2. Sample Selection on Manufacturing Survival.** The paper restricts the sample to counties with “positive manufacturing employment in every quarter” (2015Q1–2022Q4). This creates potentially severe selection bias: counties where manufacturing employment collapsed to zero due to the tariffs (or contemporaneous shocks) are mechanically excluded. Given that the paper finds null effects on total manufacturing employment, it is crucial to verify that this result is not an artifact of dropping the most distressed, “extreme-margin” counties. The current sample selection risks imposing “survivor bias” that attenuates negative employment effects toward zero.

**3. Fragility of the Null Result and Industry Heterogeneity.** The leave-one-industry-out robustness checks (Table 3) reveal that the null effect on total manufacturing employment is entirely driven by NAICS 336 (Transportation Equipment). Excluding NAICS 336 triples the coefficient (from 0.064 to 0.202) and makes it highly significant. Conversely, dropping NAICS 312 or 331 leaves the coefficient unchanged. This pattern is inconsistent with the narrative of uniform politically-motivated targeting and suggests that the aggregate result masks starkly heterogeneous effects. The paper must explain why the “motorcycle” channel (Harley-Davidson) drives the null, and why bourbon/steel counties apparently experienced *positive* manufacturing employment growth (or less negative than implied by the aggregate). Without reconciling this heterogeneity, the causal interpretation of the political targeting strategy remains suspect.

---

### 4. Suggestions

**Addressing the Section 232 Confounding.** The authors must take concrete steps to separate the effects of U.S. import protection from EU retaliation. I recommend the following: First, restrict the main analysis to NAICS 312 (Beverages/Tobacco) and NAICS 336 (Transportation Equipment), excluding steel entirely, and demonstrate that results hold for these “pure” retaliation-exposed industries. Second, for specifications including NAICS 331, control for U.S. tariff exposure using the county-level tariff shock measures from Bown et al. (2019) or Fajgelbaum et al. (2020). If data limitations preclude this, the paper should clearly bound the bias or acknowledge that NAICS 331 results are uninterpretable as causal effects of EU retaliation alone.

**Handling Sample Selection.** To address the zero-employment exclusion, I suggest two approaches: First, estimate the specifications using inverse probability weighting (IPW) where weights are derived from a model predicting the probability of remaining in the sample (positive manufacturing employment) based on pre-treatment characteristics. Second, show results for an alternative sample that includes counties with zero employment in *targeted* industries but drops only those with zero *total* manufacturing employment in 2017Q4 (the baseline), allowing post-treatment zeros. If results are sensitive to this choice, the “null effect” conclusion must be heavily qualified.

**Clarifying Industry Heterogeneity.** The paper should systematically explore why dropping NAICS 336 eliminates the null. I recommend: (1) Report separate event-study figures for each targeted NAICS code (312, 331, 336) to visualize heterogeneity. (2) Test for differential pre-trends by industry. (3) Interrogate the NAICS 336 result: Was there a concurrent shock to the motorcycle industry (e.g., shifting consumer preferences, supply chain issues) independent of tariffs? Was Harley-Davidson’s corporate restructuring around the same time spatially correlated with EU exposure? A placebo test using pre-2018 corporate announcements or consumer sentiment indices for motorcycles could help.

**Improving Treatment Measurement.** The current treatment intensity measures production employment, not export exposure. A county with a steel plant serving only domestic markets is coded as “treated” but unaffected by EU tariffs. To reduce measurement error, I suggest merging with the Census Bureau’s Exporter Database or using LFTTD (Longitudinal Foreign Trade Transaction Database) to construct export-weighted exposure: $\text{Exposure}_c = \sum_{j \in J} (Exports_{c,j,2017}^{EU} / Emp_{c,j,2017}^{Total})$. If export data are unavailable at the county level, use state-level export shares as weights. This would sharpen the first stage and reduce attenuation bias.

**Event Study Presentation.** The paper reports event study coefficients for total manufacturing employment (Table 2) but not for targeted industries or separations/hires. Given that the main claim rests on the asymmetry between targeted-industry declines and total-employment stability, the event study for targeted industries is essential for validating the identification strategy. Please include this figure and discuss any anticipation effects (e.g., did separations spike in 2018Q2 immediately after the March 2018 announcement of Section 232 but before June 2018 EU retaliation?).

**Interpretation and Magnitudes.** The abstract states that EU targeting was “surgical precision,” yet the results suggest the signal may have been weak—total employment was unaffected. Reconcile this by comparing the standardized effect sizes (reported in Appendix Table B.1) to the China shock literature (Autor et al. 2013). The SDE of -0.029 for targeted employment is an order of magnitude smaller than typical China shock estimates. Discuss whether this reflects (a) successful reallocation, (b) measurement error in exposure, (c) the small scale of EU retaliation ($2.8B vs. hundreds of billions in China imports), or (d) offsetting Section 232 protection.

**Additional Robustness Checks.** Consider: (1) Spatial spillovers using Conley standard errors or a spatial lag model to account for cross-border commuting zones; (2) Wild cluster bootstrap inference given only 51 state clusters; (3) A falsification test using non-manufacturing employment as the outcome (should be unaffected); and (4) Analysis of the second
