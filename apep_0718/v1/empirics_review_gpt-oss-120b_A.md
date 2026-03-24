# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-18T00:36:53.787235

---

**1. Idea Fidelity**  
The submitted manuscript follows the core outline of the original manifest. It uses the NOAA SPC tornado database, constructs path‑width polygons, and exploits a spatial regression‑discontinuity (RDD) that compares census‑tract centroids just inside versus just outside EF‑2+ tornado swaths. The research question – whether destroyed manufactured‑housing (MH) stock is replaced by higher‑value, non‑affordable development – is retained, and the primary outcomes (MH share, poverty rate, housing values, vacancy rates) come from the ACS exactly as proposed.  

Where the paper departs from the manifest:  

* **Geographic scope** – the original idea listed a specific set of eight “tornado‑prone” states and suggested using HUD and ATTOM data to geocode individual mobile‑home parks. The final version works at the **census‑tract** level for all states with at least three EF‑2+ events, without ever identifying individual parks. This arguably weakens the link between “park destruction” and the observed outcomes, because a tract may contain many parcels, some of which are unrelated to the park that happened to be intersected by the tornado.  

* **Bandwidth and running‑variable definition** – the manifest called for a 0–500‑yard buffer and a signed distance measured in **yards**, whereas the paper measures distance in **miles** and allows a 5‑mile bandwidth. The larger bandwidth may admit tracts that are far enough from the actual damage zone to dilute the treatment effect.  

* **Supplementary DiD** – the manifest mentioned a supplemental differences‑in‑differences (DiD) design using county‑level panels for EF‑3+ tornadoes. The manuscript does **not** present such a DiD analysis; it relies solely on the spatial RDD.  

* **Policy heterogeneity** – the idea noted the possibility of exploiting state‑level tenant‑protection laws or FEMA HMGP take‑up. The paper only splits the sample by pre‑tornado MH concentration and does not interact the treatment with any policy variables.  

Overall, the paper captures the spirit of the project (spatial RDD on tornado paths) but drops several key extensions that would have strengthened identification and policy relevance.

---

**2. Summary**  
This paper estimates the long‑run impact of EF‑2+ tornadoes on the composition of neighborhoods by exploiting the near‑random boundary of tornado paths as a spatial regression‑discontinuity. Using NOAA tornado polygons and ACS tract‑level outcomes, the author finds that tracts whose centroids fall inside tornado swaths experience a persistent increase in vacancy rates (≈1.8 pp) and modest rises in housing values, while the effect on the share of manufactured‑housing units is statistically imprecise. The results are interpreted as evidence of a “replacement problem” whereby destroyed mobile‑home parks are not rebuilt as affordable housing but are redeveloped for higher‑value uses.

---

**3. Essential Points**  

1. **Identification at the appropriate geographic unit** –  
   *Problem:* The treatment is defined at the **tract‑centroid** level, but mobile‑home parks are much smaller than tracts and may straddle the boundary. This creates measurement error in treatment assignment and likely attenuates the estimated effect on MH share.  
   *Required remedy:* Either (a) construct a park‑level dataset (using HUD/MHC listings, ATTOM, or parcel data) and apply the spatial RDD to park centroids, or (b) demonstrate analytically that the proportion of a tract’s MH units that fall inside the path is tightly correlated with the centroid indicator (e.g., by overlaying park polygons on tracts for a subset). Without this, the causal claim about “manufactured‑housing replacement” is tenuous.

2. **Bandwidth choice and running‑variable scaling** –  
   *Problem:* The manuscript uses a 5‑mile bandwidth and a distance measured in miles, far larger than the 0–500‑yard buffer suggested in the idea. This admits observations that are unlikely to have experienced any physical damage, potentially contaminating the control group and violating the local‐smoothness assumption.  
   *Required remedy:* Re‑estimate the main RDD using the narrower bandwidths (≤ 0.5 mile ≈ 880 yd) and report how the treatment effect on vacancy and MH share changes. If sample size becomes a concern, justify the trade‑off with power calculations and discuss the bias‑variance trade‑off explicitly.

3. **Robustness to spillovers and broader regional effects** –  
   *Problem:* The paper acknowledges that EF‑2+ tornadoes may generate county‑wide insurance or migration shocks that could affect nearby tracts, yet it does not test for such spillovers (e.g., by excluding tracts within 0.5 mi of the path but on the “outside” side). Moreover, clustering only at the county level may be insufficient if tornadoes affect multiple adjacent counties.  
   *Required remedy:* Conduct a “donut RDD” that omits a thin band (e.g., 0–0.2 mi) on both sides of the cutoff to ensure that observed discontinuities are not driven by spillovers. Additionally, report results with alternative clustering (e.g., state‑level or two‑way clustering by county–state) and/or spatial HAC standard errors.

If these three issues cannot be adequately addressed, the paper should be **rejected** for insufficient causal credibility.

---

**4. Suggestions**  

1. **Data Enhancements**  
   * **Park‑level geocoding:** Utilize the HUD‑MHC dataset (or the ATTOM “mobile home park” layer) to obtain precise park boundaries. Merging park polygons with tornado path polygons will allow a binary “park destroyed” indicator and enable analysis of the *actual* MH stock loss, rather than an indirect tract‑level proxy.  
   * **Parcel‑level land‑use outcomes:** To substantiate the “replacement” claim, incorporate parcel‑level data on building permits, land‑use codes, or property sales (e.g., CoreLogic, Zillow, or county assessor records). This would let you trace whether vacated land is later rezoned or sold for higher‑value development.  

2. **Refine Outcome Measures**  
   * **Vacancy definition:** ACS vacancy rates blend seasonal, rental, and outright vacant units. Consider complementing with the “vacant housing units for seasonal use” variable or with remote‑sensing data (e.g., night‑lights, building footprints) to verify that the observed vacancy spike reflects true abandonment rather than seasonal fluctuations.  
   * **Affordable‑housing proxies:** In addition to the MH share, examine the count of “affordable‑housing units” (e.g., units with median rent below area median) or the share of subsidized units (HUD’s Section 8 data) to capture broader affordable‑housing loss.

3. **Alternative Identification Strategies**  
   * **Event‑study DiD:** Stack tornado events and construct a staggered‑adoption panel at the tract level, using leads and lags of the treatment. This would allow you to test for pre‑trends and to visualize dynamic effects beyond the binary RDD. The paper mentions a DiD on EF‑3+ tornadoes; implementing it would provide a useful robustness check and broaden the scope.  
   * **Instrumental variable (IV) using wind speed:** For parks that lie within tornado paths, variation in maximum wind speed (continuous EF rating) could serve as an IV for the intensity of destruction, helping to separate the “damage” channel from pure “proximity” effects.

4. **Balance and Manipulation Checks**  
   * **McCrary test:** The manuscript reports a significant density discontinuity and attributes it to tract geometry. It would be more convincing to present a visual of tract area or perimeter versus distance to the path, and to show that after normalising for tract size the density test disappears.  
   * **Covariate continuity:** Provide formal regression tables showing that all pre‑tornado covariates (including prior trends in vacancy, housing values, and demographic composition) are smooth across the cutoff. Including higher‑order polynomials of distance in these tests will reassures readers that the RDD is not picking up underlying gradients.

5. **Presentation and Interpretation**  
   * **Effect‑size framing:** The vacancy increase of 1.8 pp is statistically significant but modest in absolute terms. Translate this into a more intuitive metric (e.g., additional vacant houses per tract, or estimated number of households displaced) to help policymakers gauge relevance.  
   * **Placebo variations:** In addition to the EF‑0/1 placebo, consider a “random rotation” test where tornado paths are rotated by a fixed angle (e.g., 90°) while preserving their length and width. This creates a falsified treatment that should show no effect if the RD is truly driven by physical damage.  
   * **Policy heterogeneity:** Even if state‑level tenant‑protection laws are not directly interacted with, you can at least stratify the sample by whether the state has a “right‑to‑purchase” law and report separate RD estimates. This would directly address the policy relevance highlighted in the original idea.

6. **Statistical Power and Multiple Testing**  
   * **Power calculations:** Given the relatively small number of treated tracts (≈3,150) and the modest effect sizes, a brief power analysis would help readers understand whether the imprecise MH‑share estimate is a true null or a power limitation.  
   * **Adjustment for multiple outcomes:** You test six outcomes in Table 3. Consider applying a modest multiple‑testing correction (e.g., Benjamini–Hochberg) when discussing the significance of the vacancy result.

7. **Additional Robustness**  
   * **Alternative kernels/polynomials:** Report results using a rectangular kernel and a second‑order polynomial to demonstrate that the main findings are not driven by a particular smoothing choice.  
   * **Geographic heterogeneity:** Split the sample by urban vs. rural tracts (using the USDA Rural‑Urban Continuum Codes) because land‑use dynamics may differ dramatically across these contexts.  

8. **Discussion and Policy Implications**  
   * **Link to FEMA buyouts:** If data on HMGP buyouts are available, overlay them on the tornado‑affected tracts to show whether buyout participation correlates with the vacancy spike. This would strengthen the argument that policy design (e.g., lack of affordable‑housing replacement requirements) is driving the observed outcomes.  
   * **Broader external validity:** Briefly discuss whether the findings might generalize to other fast‑moving hazards (e.g., wildfire fronts, floodplains) where a physical boundary creates a quasi‑random exposure.

---

**Conclusion**  
The paper tackles a novel and policy‑relevant question using an inventive spatial RDD design. However, the current implementation at the tract level, the wide bandwidth, and the limited robustness checks undermine confidence that the estimated “vacancy” effect truly reflects the destruction of manufactured‑housing parks and their non‑replacement. Addressing the three essential points—refining the geographic unit of treatment, tightening the bandwidth/running‑variable, and ruling out spillovers—will substantially improve the credibility of the identification strategy. The additional suggestions above will further enhance the contribution and make the manuscript a strong candidate for *AER: Insights*.
