# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-25T14:17:40.264996

---

**Review of "Guns and Roads: The Integrated Action Plan and Economic Development in India's Naxal-Affected Districts"**

**1. Idea Fidelity**

The executed paper deviates substantially from the original research manifest. The manifest proposed two complementary identification strategies: (i) a **boundary difference-in-differences** comparing villages within 25km of IAP/non-IAP district borders, and (ii) a **district-level regression discontinuity** based on the selection threshold. It also promised analysis of multiple outcomes: village-level nightlights, Census Village Directory public goods (schools, roads, medical facilities), and Economic Census enterprise dynamics.

The actual paper abandons both the boundary design and the RDD, opting instead for a conventional **district-level DiD** with district-specific linear time trends. It also omits the auxiliary outcomes (public goods, enterprise dynamics), relying solely on aggregated DMSP nightlights. This pivot is consequential: the boundary design was the manifest's primary defense against selection bias, allowing comparison of geographically contiguous areas across an arbitrary administrative boundary. By shifting to district-level analysis with 640 units (only 60 treated), the paper sacrifices the local identification strategy for a more fragile design that relies heavily on functional form assumptions to address pronounced pre-trends.

**2. Summary**

The paper estimates the effect of India's 2010 Integrated Action Plan—a combined security and development block grant for 60 Naxal-affected tribal districts—on nighttime luminosity. Using a two-way fixed effects model with district-specific linear trends to address pre-existing convergence, the preferred specification indicates a 17% increase in nightlights (0.16 log points) post-2010, with effects concentrated in high-tribal-share districts. However, significant pre-trends and a failed placebo test (fake treatment in 2005 yields significant "effects") suggest the identifying assumptions may not hold.

**3. Essential Points**

**i. Identification Strategy Abandonment and Pre-Trend Fragility.** The paper's central credibility problem is the shift from the manifest's boundary design to a district-level DiD with linear detrending. The event study (Table 2) reveals strong pre-treatment convergence: IAP districts were systematically closing the nightlights gap with non-IAP districts throughout the 1990s and 2000s. The admission that a placebo treatment assigned to 2005 yields a coefficient of 0.20 (half the actual treatment effect) is damning—it indicates that the linear trend model does not adequately capture the selection dynamics. When treatment is assigned based on backwardness (low nightlights), and treated units are mean-reverting, linear detrending requires the heroic assumption that convergence would have continued at exactly the same rate post-2010 absent the program. The paper's "acceleration" interpretation rests on this untested extrapolation.

**ii. Standard Errors and Inference with Few Treated Clusters.** With only 60 treated districts and district-level clustering, the standard errors rely on asymptotic approximations that may be unreliable with few treated clusters (Carter, Schnepel, and Steigerwald 2017). The paper reports state-level clustering as a robustness check, but with only 9 states containing IAP districts, this is arguably more problematic. Given the spatial correlation of insurgency and development, and the potential for spillovers across district boundaries (which the boundary design would have mitigated), the reported precision ($p < 0.001$) may be overstated. Randomization inference or the wild cluster bootstrap should be used to verify significance.

**iii. Aggregation Bias and Mechanistic Ambiguity.** The shift to district-level nightlights obscures the mechanism. IAP funds were allocated to districts but spent in specific blocks/villages. District-level luminosity averages over vast heterogeneity—potentially capturing electrification of district headquarters rather than household economic activity in tribal hamlets. Without the promised village-level boundary analysis or the auxiliary outcomes (road connectivity, school construction, enterprise counts), the paper cannot distinguish between: (a) genuine economic growth; (b) rural electrification infrastructure (which mechanically increases nightlights without economic activity); or (c) security lighting (floodlights for police camps). The heterogeneity by tribal share is suggestive but remains agnostic about whether the marginal dollar reached households or merely fortified state presence.

**4. Suggestions**

**Implement the Boundary Design.** The manifest's boundary DiD should be executed as originally planned. Restrict the sample to villages within 25km of IAP/non-IAP district borders, comparing nightlights and public goods across the boundary. This addresses selection bias by comparing geographically contiguous areas with similar insurgency exposure and topography, isolating the arbitrary administrative designation. If data constraints prevent village-level nightlights (though SHRUG provides these), at least implement the RDD using the selection threshold based on tribal population shares and LWE incident counts described in the manifest.

**Address the Pre-Trend Problem Directly.** Rather than assuming linear trends, consider:
- **Non-parametric pre-trend adjustment:** Estimate the pre-treatment convergence rate and project it forward non-linearly (e.g., using the method of Ben-Michael, Feller, and Rothstein 2021).
- **Synthetic control:** Construct synthetic counterparts for IAP districts using pre-treatment nightlights and covariates, which may better capture the non-linear convergence dynamics suggested by the 2005 placebo failure.
- **Donut RDD:** Exclude districts near the selection threshold to reduce manipulation concerns, then compare above/below threshold units.

**Improve Inference.** Report wild cluster bootstrap p-values (Cameron, Gelbach, and Miller 2008) given the small number of treated clusters (60). Additionally, test for spatial correlation using Conley standard errors with a cutoff distance appropriate for district contiguity (e.g., 100km) to account for spillovers and spatial dependence in insurgency patterns.

**Unpack the Mechanism.** The manifest promised analysis of Census Village Directory public goods and Economic Census enterprises. These should be included to test whether the nightlights effect reflects:
- **Infrastructure:** Did road connectivity or electrification rates improve (extensive margin)?
- **Economic activity:** Did enterprise counts or employment rise?
- **Security vs. Development:** Use variation in spending composition (if available) or security incident data to test whether effects correlate with security operations versus development spending.

**Deal with Measurement.** Nightlights in rural insurgency zones are problematic. DMSP saturation and blooming mean that new electrification (a likely IAP expenditure) appears as increased luminosity even without GDP growth. Use the VIIRS data (mentioned in the manifest) to test for intensive vs. extensive margin effects—VIIRS's higher resolution can distinguish between brightening of existing lit pixels (economic growth) versus new lit pixels (electrification).

**Heterogeneity by Baseline Conditions.** The finding that high-tribal-share districts show larger effects is confounded by baseline nightlights levels (floor effects). Test whether effects vary by *baseline* nightlights intensity rather than just tribal share, as the marginal effect of lighting is largest where initial luminosity is zero.

**Policy Relevance.** The conclusion appropriately notes uncertainty about whether security or development drove results, but the paper should engage more deeply with the counterinsurgency literature cited in the manifest. If the effect operates primarily through security (enabling night activity, reducing violence), the welfare implications differ fundamentally from genuine economic transformation. The boundary design would help here too—if effects stop sharply at the district border, they likely reflect administrative targeting; if they spill over, they may reflect security externalities.

**Minor points:** The standardized effect size (0.10 SD) is modest but meaningful for poor districts; however, the cost-effectiveness calculation (Rs 25-30 crore/district/year) should be compared to other Indian rural programs (e.g., PMGSY, MGNREGA) to contextualize the return on investment. Finally, acknowledge the limitation that DMSP data ends in 2013, capturing only the initial two years of the program, not the medium-run effects promised in the manifest (which mentioned data through 2021).
