# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-22T14:14:25.646830

---

**Idea Fidelity**  
The paper closely adheres to the original idea manifest. It uses the DVF transaction dataset, the Monuments Historiques registry, and the 500‑meter Architectes des Bâtiments de France (ABF) boundary as stated. The authors implement the spatial regression discontinuity design around the administrative perimeter, conduct donut-hole and placebo checks, and emphasize the heterogeneity between classé and inscrit monuments. The additional institutional description of the two protection tiers and the purported arbitrariness of the 500‑meter radius are also consistent with the manifest. Nothing essential from the proposed identification strategy or research question seems to have been dropped; the main econometric setup is maintained.

---

**Summary**  
This paper studies how France’s 500‑meter ABF boundary around historic monuments affects residential property prices by exploiting it as a spatial regression discontinuity. Using nearly 2.7 million geolocated transactions matched to over 44,000 monuments, the author finds a 2.6 % premium for properties inside the boundary. Crucially, this average masks heterogeneity: prices fall near the most stringently protected “classé” monuments and rise near the lighter “inscrit” monuments, suggesting a trade‑off between amenity and restriction effects.

---

**Essential Points**

1. **Density manipulation and discontinuities in nearby characteristics** – The McCrary test rejects the null of smooth density at the 500 m boundary, and there are measurable jumps in covariates such as floor area and apartment share. These discontinuities could reflect differences in urban form (e.g., apartment-heavy cores) rather than strategic sorting, but the paper currently downplays the implication for the RDD setup. The author should better document why these differences do not bias the estimate—e.g., by demonstrating that the functional form is flexible enough to absorb them, by showing covariate-adjusted estimates, or by more clearly arguing that they originate purely from geography rather than treatment.

2. **Placebo and gradient interpretation** – The placebo tests at several other distances (300, 600, 700, 800 m) produce statistically significant effects, which the paper interprets as evidence of a continuous price gradient around monuments. However, the RDD relies on the absence of other structural breaks near 500 m. The existence of other discontinuities raises concern that the observed 500 m jump might not isolate the regulatory effect but rather capture non‑regulatory changes in neighborhood quality at various scales. The author should provide a clearer explanation (and ideally empirical support) that these placebo “effects” reflect misspecified local trends rather than other thresholds, or restrict the analysis to finer bandwidths where only the 500 m jump remains.

3. **Interpreting heterogeneity and policy inference** – The key contribution is the different signs across classé and inscrit monuments, yet the analysis assumes that these statuses are exogenous conditioning on distance. However, classé monuments are disproportionately located in large urban cores, while inscrit monuments cover more provincial contexts; these correlated location characteristics could drive price differences rather than regulatory intensity per se. The paper needs to better argue why the protection tier itself, and not the surrounding urban context, explains the reversal—perhaps by controlling for coarse location fixed effects (e.g., commune × monument-type interactions), by showcasing within‑monument RDD comparisons (where classé and inscrit are randomly assigned across adjacent municipalities), or by exploiting the reform that allows adapted perimeters to show that relaxing regulation (holding location fixed) changes prices in the predicted direction.

If addressing these points requires major changes, the paper may not yet be suitable for publication. At minimum, each of the above issues must be convincingly accounted for to preserve the credibility of the RDD and of the heterogeneity interpretation.

---

**Suggestions**

1. **Strengthen covariate-adjusted RDDs and balance diagnostics.**  
   - Provide covariate balance tables limited to the chosen bandwidth (e.g., ±150 m), not the entire 1 km sample, to show that observable characteristics are similar around the cutoff.  
   - Report “bias-adjusted” RDD estimates that include controls such as property type, floor area, and number of rooms as a robustness check. If including these covariates meaningfully alters the estimate, discuss why and whether it is desirable.  
   - Consider using a local randomization approach (Cattaneo et al. 2015) where you show that within a narrow window the treated and control units do not differ on observables, reinforcing the continuity assumption.

2. **Interpret placebos and density more carefully.**  
   - The significant McCrary test suggests structural differences in built environment density. If you can show that the observed density jump is entirely due to the underlying morphology (e.g., by plotting counts of apartments vs. distance), explain that to reassure readers the treatment is still as good as randomly assigned near the boundary.  
   - For the placebo cutoffs, show the full pattern of price as a continuous function of distance to illustrate whether the discontinuities are spurious or part of a smooth trend. Adding a visualization (e.g., binned scatterplot with fitted lines) could make the “true” jump at 500 m more persuasive.  
   - Another option is to re-estimate the RDD using higher-order polynomials on each side (as in local quadratic) or different bandwidth selectors; if the 500 m coefficient remains stable while the placebo coefficients shrink, that would bolster the argument that the 500 m boundary is unique.

3. **Refine the heterogeneity analysis.**  
   - The classé vs. inscrit comparison is compelling, but to attribute the reversal to regulatory intensity you could exploit municipal heterogeneity: e.g., contrast locations where municipal governments applied adapted perimeters (post‑2016 reform) with those that kept the 500 m uniform boundary. While adoption is low, even a small treated sample could provide quasi-experimental variation in regulatory stringency controlling for monument type.  
   - Alternatively, examine monuments whose status changed over time (if any exist within the sample period). A monument that transitioned (e.g., from inscrit to classé) provides more direct evidence about how intensity affects prices.  
   - Expand the property-type heterogeneity with interaction plots showing how the premium evolves across distance for apartments vs. houses. If regulatory costs primarily affect renovation-heavy buyers (house owners), that would support the restriction channel.

4. **Address the spatial clustering of monuments.**  
   - The running variable is distance to the nearest monument, but many properties are simultaneously within 500 m of multiple monuments, especially in dense urban cores. Describe how you handle cases where adjacent monuments produce overlapping treated regions (e.g., using the closest monument, dropping duplicates, or clustering standard errors).  
   - If multi-monument exposure matters (e.g., a property is near two classé monuments), consider weighting observations by the intensity of regulatory exposure (e.g., number of monuments within 500 m) or at least checking whether the treatment effect varies with the count.  
   - Clarify whether these overlaps could contaminate the RDD (since the “running variable” might jump at distances other than 500 m when switching from one monument to another). You might test robustness by restricting the sample to properties whose nearest monument is unique (no other monuments within ±100 m) to ensure a clean discontinuity.

5. **Enhance discussion of policy implications.**  
   - The conclusion touches on the wider trade-off between amenity and restriction. You could sharpen this by translating the estimated premium into a welfare metric or by discussing how many properties fall inside each type of zone, to assess aggregate supply effects.  
   - Consider briefly connecting to the housing affordability debate—if the restriction penalty near classé sites is sizable, how might this influence urban renewal or housing supply in protected versus non-protected neighborhoods?  
   - Since the RDD captures local treatment effects, explicitly state the limits of extrapolation (i.e., the findings apply only to properties near the boundary, not those deep inside the ABF zone). This clarification helps policymakers understand where the evidence is strongest.

6. **Improve transparency on data preprocessing.**  
   - The summary stats mention trimming based on price-per-m2 and floor area; specify how many observations were dropped and whether the trimming affected the RDD sample near 500 m.  
   - Provide a map or table showing the geographic distribution of monuments and transactions to illustrate the representativeness of the sample.  
   - If the DVF data are aggregated by transaction year, mention whether the RDD estimate changes over time—this is touched on in robustness but could be made more systematic by plotting the estimated discontinuity annually.

By addressing these suggestions, the paper would reinforce the credibility of the spatial RDD and clarify the mechanisms underlying the heterogeneous effects.
