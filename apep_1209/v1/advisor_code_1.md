# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-31T16:00:36.826804

---

**Idea Fidelity**  
The paper adheres quite closely to the original manifest. It exploits the Illinois dispensary license lotteries, uses Cook County property sales and Chicago crime data, and focuses on neighborhood-level externalities of lottery-assigned cannabis retail. However, the empirical strategy diverges from the manifest’s promised spatial IV design: instead of instrumenting with actual lottery draws, the analysis relies on a within-cluster difference-in-differences comparison of properties near versus far from opened dispensaries. The paper therefore misses the opportunity to fully operationalize the lottery-based identification strategy outlined in the manifest.

---

**Summary**  
The paper estimates the effect of proximity to lottery-assigned cannabis dispensaries on Cook County property values, finding a modest ~6% decline within a half-mile and suggesting that the impact is concentrated in higher-income neighborhoods. It also documents a sizeable increase in reported drug crimes near dispensaries, with no corresponding increase in property or violent crime. The contribution is pitched as methodological, leveraging the randomized license allocation to address the endogeneity of dispensary siting.

---

**Essential Points**

1. **Credibility of Identification:** The paper claims the lottery provides quasi-random variation but never uses the actual lottery draw as an instrument. Instead, the empirical strategy compares properties near versus far from opened dispensaries in a DiD framework. This leaves the very concern motivating the study—endogenous site selection—largely unaddressed. The key identifying assumption becomes that, conditional on being the nearest dispensary, the timing of opening is exogenous across distance rings, but that is not justified by the lottery. The authors need to incorporate the lottery mechanism explicitly: e.g., use winner/loser assignment (or draw order) to instrument for building a dispensary in a given location, or otherwise show that the lottery induces random variation in distance to the nearest dispensary that is orthogonal to pre-existing neighborhood trends.

2. **Pre-trends and local counterfactual:** The DiD specification assumes that properties near a dispensary would have followed the same trend as those farther away absent the opening. But properties within 0.5 miles are inherently different from those 1 mile away, and there is no evidence presented to justify parallel trends. In particular, the design does not compare neighborhoods that were potential dispensary sites but lost the lottery. Without that, we cannot rule out that the observed price decline simply reflects that winners (and their chosen locations) systematically differed from losers in ways that also affect property values. An event-study and placebo tests, exploiting the randomness of the draw, are essential.

3. **Measurement and treatment definition:** Dispensaries are geocoded to ZIP code centroids, and the matching of properties to dispensary clusters depends on ZIP-level proximity. This injects classical measurement error that may attenuate estimates, but it also leads to ambiguous treatment definitions across distance rings. The paper should clarify how ZIP centroid geocoding affects distance calculations and, if possible, validate the geocoding with a subsample of precise addresses. Additionally, the property dataset includes only transactions that appear in both historical and current datasets, potentially biasing the sample toward investor-owned homes; the authors should demonstrate that the results are not driven by this selection.

If these concerns cannot be credibly addressed, the paper’s central claim—that the lottery provides a clean identification—does not hold, and rejection should be considered.

---

**Suggestions**

- **Exploit the lottery directly.** The manifest promised a spatial IV design; implement it. Use the actual winner/loser status (or draw rank) within each BLS region to instrument for the presence of an open dispensary in a candidate location. If precise applicant-proposed locations are unavailable, use the geographic information tied to winners’ proposed addresses (the IDFPR applications may record this) or, at minimum, exploit variation in the distance from properties to the nearest lottery-winning dispensary versus the nearest lottery loser location, as in a fuzzy RD/IV design. This would ground the exogeneity claim and allow a first-stage test.

- **Include event-study and placebo analyses.** To build confidence in the DiD estimates, plot pre-treatment trends for near and far properties. Estimate leads and lags of the treatment indicator and show that there are no anticipatory effects. Placebo treatments—e.g., assigning fake opening dates—can further demonstrate that the observed drop in prices is not a mechanical artifact of the matching procedure.

- **Strengthen the comparison group.** Rather than defining the control group as properties beyond 0.5 miles, consider an approach that compares properties near lottery-winner dispensaries to properties near lottery-loser locations that never opened (or opened much later). If data on losers’ proposed sites are unavailable, consider comparing within the same ZIP code but different census blocks, as long as one block had a winner and another did not—this would more closely mimic the random assignment.

- **Address spatial spillovers and treatment timing more precisely.** Treatment timing is based on license issue dates, but dispensaries do not open immediately. Incorporate actual opening dates (if obtainable) or instrument license dates with opening dates to avoid misclassifying pre-treatment periods. Additionally, because the treatment affects not only properties within 0.5 miles but potentially nearby neighborhoods (and even property markets adjusted by expectations), exploring more flexible spatial weights or continuous distance functions would help understand the spatial decay.

- **Clarify the role of zip-code centroid geocoding.** Provide evidence on how much error centroid-based distances introduce. For a subset of dispensaries where exact addresses are available, compare the centroid-based distance to the true distance to evaluate attenuation bias. If the centroids are substantially off, consider imputation techniques or sensitivity analyses (e.g., randomly jittering locations within the ZIP) to assess robustness.

- **Improve sample representativeness.** Since the sample covers only “matched” transactions present in both historical and current assessor datasets, discuss whether this selection skews the results toward certain property types (e.g., investor flips) or neighborhoods. As recommended, re-estimate the main results on the full sample of current transactions using imputed coordinates (e.g., from parcel shapes) or by focusing on properties in more stable neighborhoods.

- **Crime specification details.** The crime analysis aggregates to community-area by quarter and simply includes a “dispensary present” dummy. This misses the randomized spatial variation. Consider a spatial DiD analogous to the property-price model, assigning treatment based on proximity to newly opened dispensaries and using the cluster fixed effects to control for local time-invariant differences. Include more granular crime categories (e.g., distinguishing between dispensary-related drug incidents and generic drug crimes) and control for time-varying patrol intensity if such data are available.

- **Interpretation of heterogeneity.** The paper interprets stronger effects in high-income neighborhoods as evidence of stigma, but this could also reflect differential baseline trends or market liquidity. Provide additional evidence—e.g., survey data on attitudes or a triple-difference comparing high- versus low-income neighborhoods before/after openings—that supports the stigma mechanism. Alternatively, test whether the income heterogeneity persists when controlling for a neighborhood’s pre-trend in price appreciation or crime.

- **Discuss potential general equilibrium effects.** The model assumes dispensary openings affect only nearby property values. If some consumers relocate or crime shifts across areas, the measured effect may partly reflect displacement rather than true amenity changes. A brief discussion (or some checks using adjacent neighborhoods) would help position the estimates.

- **Clarify the counterfactual.** In the conclusion, the paper notes that the counterfactual is “near vs. far properties within a dispensary cluster,” but the identification narrative centers on lotteries providing random treatment. Explicitly reconcile these two views: either (a) the randomness justifies treating the winner’s location as exogenous, so near/far comparisons are valid, or (b) the analysis should instead compare winners’ neighborhoods to losers’ neighborhoods. Making this clearer will reduce confusion about what exactly is being identified.

- **Data transparency.** Provide summary statistics for lottery losers and for dispensary counts by BLS region/time to demonstrate the scope of the randomization. Consider including the rotation of applicants across regions to show that zoning differences are not confounding the identification.

Implementing these suggestions would align the empirical strategy with the paper’s stated contribution and increase confidence in the conclusions.
