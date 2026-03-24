# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-24T23:04:41.671048

---

 **Review of "The Compliance Boundary: Radon Building Codes and the Absence of Behavioral Spillovers"**

---

### 1. Idea Fidelity

The paper deviates substantively from the original manifest in three ways that weaken the research design. First, the manifest proposed analyzing **100+ jurisdictions** with adoption dates ranging from **1999** (Brentwood, TN) through 2015, including local ordinances in Colorado, Iowa, and Tennessee. The paper instead restricts attention to **20 statewide adoptions** occurring only between **2007–2015**. This discards eight years of early treatment variation and potentially the most informative observations: local adoptions in high-awareness jurisdictions (e.g., Aspen 2003) may be precisely where spillovers would manifest.

Second, the manifest identified **CDC Environmental Health Tracking Network data** (county-level testing rates) as the primary outcome. The paper uses **Census County Business Patterns (CBP)** employment in NAICS 562910. This is a significant measurement downgrade: NAICS 562910 captures mold, asbestos, and lead remediation alongside radon, and employment is a noisy proxy for testing activity (the behavioral margin of interest). The CDC testing data would provide a direct measure of the spillover mechanism.

Third, the manifest proposed using **EPA Zone 3 counties as a placebo** (where RRNC should have minimal impact). The paper instead uses radon zones for **heterogeneity analysis** (Zone 1 vs. Zone 2/3), which is not a valid placebo test—if Zone 3 counties also adopt RRNC codes, the information channel might still operate through contractor training and media markets regardless of geological risk.

---

### 2. Summary

This paper tests whether radon-resistant new construction (RRNC) building codes generate behavioral spillovers to existing homes by analyzing county-level employment in environmental remediation services (NAICS 562910) across 20 U.S. states that adopted statewide codes between 2007 and 2015. Using a Callaway–Sant'Anna difference-in-differences estimator with never-treated states as controls, the author finds a precise null effect (ATT ≈ 0) that persists across radon risk zones, alternative outcomes, and leave-one-out specifications, concluding that building codes operate strictly at the compliance boundary without inducing voluntary remediation in the existing housing stock.

---

### 3. Essential Points

**1. Measurement Validity Crisis.** The shift from CDC testing data (manifest) to CBP industry data (paper) is fatal to the interpretation. NAICS 562 employment reflects general environmental remediation (mold, asbestos, lead) and general economic conditions, not radon-specific activity. The null result may reflect measurement error rather than a true absence of behavioral spillovers. If radon testing increased by 50% but remained a small share of total remediation employment, the CBP data would fail to detect it. You must either use the CDC testing data promised in the manifest or provide validation that NAICS 562910 employment correlates strongly with radon testing rates (e.g., via state-specific microdata).

**2. Omitted Treatment Variation.** By excluding pre-2007 local adoptions (Brentwood 1999, Iowa City 2002, Aspen 2003, Fort Collins 2005), the paper discards variation that could identify long-run spillovers and introduces selection bias. Early local adopters were likely high-demand jurisdictions with media markets primed for radon awareness—exactly where spillovers should appear. The switch from "local + state" to "statewide only" reduces the effective treatment variation to just 20 clusters, compromising the credibility of the Callaway–Sant'Anna estimator, which requires sufficient cohort sizes for balancing.

**3. Inference with Few Treated Clusters.** With only **20 treated states** (the level of treatment variation) and standard errors clustered at the state level, the effective degrees of freedom are dangerously low. The CS estimator's standard error (0.065) is roughly double the TWFE standard error (0.032), suggesting the heterogeneity-robust estimator is struggling with sparse cohorts (several adoption years have only 1–2 states). The claim that this "rules out effects larger than 0.065 standard deviations" is misleading; with 20 clusters, the critical values from the t-distribution are closer to ±2.09 (or higher with HC3 corrections), meaning the 95% CI is actually ±0.136 log points, ruling out effects larger than ~0.10 SD, not 0.065.

---

### 4. Suggestions

**Employ the CDC Testing Data.** Revert to the CDC Environmental Health Tracking Network data mentioned in the manifest (measure 843/865), which directly measures the behavior of interest—voluntary radon testing in existing homes. If access is restricted to certain years, limit the analysis to those years rather than using a proxy variable with unknown radon-specificity. If you must use CBP, report the radon-specific share of NAICS 562910 employment using Occupational Employment and Wage Statistics (OEWS) or industry surveys to bound the measurement error.

**Incorporate Local Adoptions.** Compile the local RRNC ordinances listed in the manifest (Brentwood, Iowa City, Aspen, Fort Collins) and include them as treated units using a mixed geographic level of analysis (counties/towns). This recovers the 1999–2006 variation and increases the number of treated units above 100, alleviating the small-cluster inference problem. Use a convex hull or propensity-score matching approach to align local adopters with comparable control counties if state-level parallel trends are implausible for local jurisdictions.

**Address General Equilibrium Confounding.** RRNC codes could reduce demand for remediation in existing homes through a **crowding-out mechanism**: fixed contractor capacity shifts to lucrative new-construction installation (guaranteed by code) and away from voluntary existing-home mitigation. This could mask a true positive spillover to testing by suppressing equilibrium quantity. Test for this by analyzing **new construction permits** (Census BPS data from the manifest) interacted with treatment—if new construction spikes in treated counties while remediation employment stays flat, this suggests capacity constraints rather than absent information.

**Refine the Mechanism Test.** The EPA zone heterogeneity analysis is underpowered and conceptually muddy. Instead, exploit **housing turnover rates**: spillovers to existing homes should be strongest in counties with high turnover (frequent sales force radon disclosures). Interact treatment with County Business Patterns data on real estate services (NAICS 531) or Census migration data. If the null persists in high-turnover markets, the information channel is truly inactive; if effects appear only there, the codes work but require transaction triggers.

**Validate with Alternative Outcomes.** Use the **Census BPS data** (cited in the manifest) to verify that RRNC codes actually increased radon system installations in new homes—a first-stage check. If BPS shows no increase in mechanical rough-ins or permit valuations, the treatment is weak and the null result uninformative. Also, test for placebo effects in unrelated service industries (e.g., NAICS 8111 automotive repair) to verify that the null is not driven by a general stagnation in service employment during the 2007–2015 period.

**Correct the Standard Error Presentation.** With 20 treated clusters, report wild cluster bootstrap p-values or use the CRV3 correction ( ochres/ML inference). The current SEs likely undercover. Additionally, clarify the MDE calculation: the 95% CI upper bound is approximately $1.96 \times 0.065 = 0.127$ log points, which divided by the outcome SD (1.359) yields an SDE of ~0.093, not 0.065.

**Discuss the "False Sense of Security" Channel.** The introduction mentions this as a possible explanation for the null, but the paper does not test it. If homeowners believe codes have "solved" radon, testing should decline in treated counties relative to controls (a negative effect). The point estimate is slightly negative (-0.0003) but the paper does not formally test $H_0: \beta \geq 0$ against $H_1: \beta < 0$. A one-sided test or Bayesian estimation would help distinguish "no effect" from "offsetting effects."

**Final Note on Scope.** The manifest's sample size projection was "100+ counties × 10+ years." The delivered paper uses 2,806 counties but only 20 independent treatment decisions. This is not merely a scaling issue—it fundamentally changes the identification strategy from a rich staggered DiD to a sparse one. If local adoption data are unavailable after 2006, acknowledge this constraint explicitly and frame the results as "statewide adoption only" rather than general evidence on RRNC codes.
