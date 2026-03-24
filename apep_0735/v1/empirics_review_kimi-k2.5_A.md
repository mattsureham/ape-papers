# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-22T14:16:12.647403

---

**Report on Manuscript: "The Price of Beauty: How Heritage Protection Shapes Property Values at France's 500-Meter Monument Boundaries"**

**1. Idea Fidelity**

The paper hews closely to the original manifest in terms of data sources (DVF transactions, Monuments Historiques registry) and core methodology (spatial RDD at the 500-meter boundary). The heterogeneity analysis by monument type (*classé* vs. *inscrit*) is executed as proposed and represents the paper's strongest contribution. However, the manuscript omits two key elements promised in the manifest: (1) the DiD analysis exploiting the 2016 LCAP reform to test for adapted perimeter adoption, which was explicitly framed as a complementary identification strategy; and (2) the Sitadel construction permit data, which were to be used to demonstrate the mechanism (regulatory delay/burden) rather than simply asserted. More critically, the paper does not address a fundamental complication inherent in the research design: with 46,700 monuments distributed across France, the "control" group (properties >500m from the nearest monument) is likely contaminated by overlapping protection zones from nearby monuments, a threat to identification that the manifest acknowledged only obliquely.

**2. Summary**

This paper estimates the causal effect of France's Architectes des Bâtiments de France (ABF) heritage regulation on property values using a spatial regression discontinuity design at the 500-meter monument boundary. The central finding is a striking reversal in price effects: properties near high-protection (*classé*) monuments experience a 2.5% price discount at the boundary, while those near lower-protection (*inscrit*) monuments command a 5.0% premium, suggesting that aesthetic regulation generates competing amenity and restriction effects whose net impact depends on regulatory intensity.

**3. Essential Points**

*The Multiple Monuments Problem.* The identification strategy assumes that properties just outside the 500-meter radius of the *nearest* monument serve as valid counterfactuals for those just inside. However, with 46,700 monuments nationwide—often clustered in urban centers like Paris, where 1,885 monuments create dense overlapping circles—properties classified as "control" (510m from Monument A) are frequently "treated" by Monument B located 200m away. This contamination biases the estimated treatment effect toward zero and may create artificial discontinuities where none exist. The paper must demonstrate that the control group is truly untreated, either by restricting the sample to spatially isolated monuments (requiring >1000m separation from any other monument) or by constructing a treatment intensity measure that accounts for overlapping jurisdictions.

*Validity Test Failures.* The McCrary density test rejects continuity (p = 0.007), suggesting sorting or manipulation at the cutoff. More concerning, placebo tests at 300m, 600m, 700m, and 800m yield significant estimates (Table 4), and the donut-hole test at ±50m produces a large, significant negative estimate (-7.7%) that contradicts the baseline. While the authors acknowledge a "continuous price gradient," the presence of significant discontinuities at multiple arbitrary distances suggests that the 500m estimate may capture non-regulatory spatial variation (e.g., urban density gradients) rather than a causal effect of ABF jurisdiction. The paper must reconcile these conflicting validity signals or acknowledge that the design may not satisfy the local randomization assumption required for causal interpretation.

*Spatial Correlation and Standard Errors.* The paper reports "robust standard errors" but does not address spatial correlation in property prices, which is severe in this setting (transactions cluster near urban monuments). Spatial correlation can severely inflate Type I error rates in boundary-discontinuity designs (Conley 1999; Bester et al. 2011). With 2.7 million observations, conventional robust standard errors are likely downward biased. The authors must implement spatially clustered standard errors (e.g., Conley standard errors with appropriate cutoffs) or demonstrate that spatial correlation does not affect inference.

**4. Suggestions**

*Address Overlapping Zones.* The most critical revision is to handle the multiple-monuments problem. I suggest defining the treatment as the *maximum* regulatory stringency within 500m (to capture binding constraints) and restricting the sample to properties where the nearest monument is at least 1000m from any other monument. This ensures the control group is genuinely unregulated. Alternatively, use a donut-RDD excluding all properties within 500m of any second monument to create "clean" control variation.

*Leverage the 2016 LCAP Reform.* The manifest proposed using the 2016 LCAP reform as a DiD complement. This is essential for validating the RDD results. Municipalities that adopted "adapted perimeters" (replacing the 500m default with custom boundaries) provide a test of whether regulatory intensity causally affects prices. A triple-difference design (monument × post-2016 × adapted perimeter) would isolate the effect of regulatory stringency from static amenity values and would mitigate concerns about the continuous gradient problem in the cross-sectional RDD.

*Use Sitadel Data for Mechanism.* The manifest mentioned Sitadel construction permit data (398k records) but these are unused in the analysis. These data are crucial for establishing the mechanism: if ABF jurisdiction restricts supply, you should observe fewer permits, longer processing times, or smaller floor area ratios inside the 500m boundary. A first-stage analysis showing that construction probability drops discontinuously at 500m would validate the "restriction penalty" interpretation of the *classé* results. Without this, the claim that regulation drives the price discount remains speculative.

*Boundary Fixed Effects.* Following Keele & Titiunik (2015), consider estimating boundary-segment fixed effects rather than pooling all monuments. Each of the 46,700 monuments creates a separate discontinuity; pooling assumes homogeneous treatment effects across vastly different contexts (rural chapels vs. urban landmarks). Estimating effects by monument or including boundary fixed effects would reveal whether the aggregate results are driven by a subset of high-density monuments and would address concerns about spatial sorting across different monument types.

*Reconcile Parametric and Nonparametric Results.* The commune fixed-effects specification yields an insignificant -2.1% estimate (opposite sign to the RDD), which the authors attribute to cross-commune sorting. However, this discrepancy is troubling: if the RDD is valid, within-commune comparisons should recover a similar (though noisier) estimate. The paper should explore this divergence—perhaps by estimating the RDD separately for communes with high vs. low monument density—to determine whether the main result reflects local amenity gradients rather than regulatory effects.

*Clarify Donut-Hole Instability.* The ±50m donut estimate (-7.7%) is qualitatively different from the baseline (2.6%). This suggests the result is sensitive to observations extremely close to the boundary, where measurement error in geocoding (parcel centroid vs. building location) is most severe. Report geocoding accuracy (DVF coordinates are often parcel centroids, which may be 50m+ from the actual structure) and assess whether measurement error could attenuate or distort the main estimates. If parcels are large, the 500m boundary is measured with error, biasing estimates toward zero; the donut-hole sensitivity may reflect this.

*Heterogeneity by Construction Intensity.* Explore heterogeneity by the likelihood of renovation (older housing stock) vs. new development. The restriction penalty should be larger for properties with high redevelopment potential (e.g., older buildings, larger lots). This would sharpen the interpretation of the *classé* vs. *inscrit* split and connect the findings to the housing supply debate cited in the introduction.

*Standardize Reporting of Multiple Testing.* With numerous placebo cutoffs and heterogeneity tests, report adjusted p-values (e.g., Bonferroni or Romano-Wolf) to account for multiple hypothesis testing, particularly given the many significant placebo estimates reported in Table 4.

Overall, the paper addresses an important policy question with a creative research design, but the identification strategy requires substantial strengthening to credibly isolate the causal effect of ABF jurisdiction from confounding spatial gradients and overlapping regulatory zones.
