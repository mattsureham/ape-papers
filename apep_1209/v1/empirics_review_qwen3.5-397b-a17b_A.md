# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-31T16:01:58.976807

---

1. **Idea Fidelity**

The paper largely adheres to the original idea manifest regarding the policy context (Illinois cannabis lotteries), data sources (Cook County property records, Chicago crime data), and the core research question (neighborhood externalities of dispensaries). However, there is a significant deviation in the identification strategy. The manifest proposed a "Spatial IV design" that explicitly compared neighborhoods near lottery winners to neighborhoods near **lottery losers' proposed locations**. The submitted paper abandons the loser-location comparison, opting instead for a difference-in-differences (DiD) design comparing "Near" vs. "Far" properties relative to opened dispensaries. While the paper argues the lottery ensures exogeneity, it does not implement the instrumental variable approach outlined in the manifest. Additionally, the manifest suggested a Callaway & Sant'Anna event study design, whereas the paper employs a standard fixed-effects DiD. These changes simplify the execution but weaken the causal claim regarding *location* specific effects, as the paper now relies on the assumption that lottery winners do not select locations endogenous to neighborhood characteristics post-draw.

2. **Summary**

This paper exploits Illinois's 2021–2023 cannabis license lotteries to estimate the causal effect of dispensary proximity on neighborhood property values and crime in Cook County. The author finds a modest 6 percent decline in property prices within half a mile of a dispensary, concentrated in higher-income neighborhoods, alongside a 34 percent increase in reported drug crimes but no change in violent or property crime. The results suggest that dispensary externalities are driven primarily by stigma rather than crime spillovers, offering a calibrated perspective for policymakers weighing local legalization costs.

3. **Essential Points**

1.  **Geocoding Precision and Spatial Validity:** The paper states that dispensaries are geocoded to **zip-code centroids** (Section 3.1 and Introduction). In Cook County, zip codes (ZCTAs) can span several square miles. Using centroids to define 0.25-mile and 0.5-mile rings introduces massive measurement error that renders the spatial variation meaningless. A property might be 0.1 miles from a dispensary but assigned a distance of 3 miles based on the zip centroid. This invalidates the core spatial mechanism. You must obtain exact street addresses from the IDFPR database (which are public) and compute precise haversine distances. Without this, the distance bands are noise.

2.  **Post-Lottery Site Selection Endogeneity:** The identification argument claims location is random due to the lottery (Section 2). However, Section 2 also states winners "required finding a suitable location... This process typically took 12–18 months." If winners choose their location *after* winning the lottery based on zoning, rent, or foot traffic, the *location* is endogenous, even if the *license winner* was random. The lottery randomizes who gets to open, not necessarily *where* they open. You must clarify whether applicants locked in a specific address during the lottery application. If not, the "random location" claim is false, and you should revert to the manifest's proposed strategy: using lottery losers' proposed locations as the counterfactual control group.

3.  **Parallel Trends and Control Group Definition:** The DiD design compares properties "Near" vs. "Beyond 0.5mi." Table 1 shows that properties within 0.5mi are already more expensive ($460k vs $366k) before treatment. This suggests systematic differences between near and far neighborhoods. The dispensary-cluster fixed effects absorb time-invariant differences, but the DiD relies on the *trend* in prices being parallel. You must present pre-trend graphs (event study coefficients) to show that near and far properties were trending similarly before the dispensary opened. If high-value areas were already appreciating faster, the -6% effect could be a convergence rather than a dispensary shock.

4. **Suggestions**

The following recommendations are intended to strengthen the empirical rigor and clarity of the paper. While the above essential points must be addressed to validate the core claims, these suggestions will enhance the contribution and robustness of the analysis.

**1. Refine the Identification Strategy (IV vs. DiD)**
The manifest's proposal to use lottery losers' proposed locations was superior for identifying *location* effects. If applicants submitted specific addresses during the lottery process (common in social equity lotteries to prevent speculation), you should construct an instrument where $Z_i = 1$ if the location won the lottery, and use this to predict dispensary presence. This isolates variation in location that is purely random. If addresses were not locked, you must temper the claims: the lottery randomizes *entry*, not *site selection*. In this case, consider using the lottery win as an instrument for *dispensary density* in the BLS region, rather than precise proximity, or acknowledge that post-win site selection introduces bias. If you retain the DiD approach, explicitly test for parallel trends using pre-period coefficients (e.g., $t-2, t-1$) rather than just asserting exogeneity.

**2. Implement Staggered Adoption Event Studies**
The manifest recommended Callaway & Sant'Anna (2021), but the paper uses a standard two-way fixed effects (TWFE) model. Given that dispensaries opened between 2022 and 2025 (staggered timing), TWFE can be biased under heterogeneous treatment effects. Implement a generalized event study design (e.g., `did` package in R or `csdid`) to plot dynamic effects over time. This will allow you to show whether the -6% effect appears immediately upon opening or evolves over time, and crucially, whether there are significant pre-trends (coefficients significantly different from zero in pre-periods). This visual evidence is standard in modern AER-style papers and would greatly bolster confidence in the parallel trends assumption.

**3. Improve Crime Data Alignment**
Currently, property data is parcel-level, but crime data is aggregated to community-area-by-quarter (Section 3.1). This mismatch reduces power and precision. Chicago Police Department data is geocoded at the incident level (as noted in the manifest smoke test). You should aggregate crime to the same spatial rings used for property (0.25, 0.5, 1 mile) around each dispensary. This allows for a consistent spatial test: does crime increase *inside* the ring where property values drop? Currently, the community-area aggregation might miss hyper-local crime spikes that drive the stigma effect. Using incident-level data to construct crime counts within the specific distance bands would align the crime and property analyses perfectly.

**4. Mechanism Tests for "Stigma"**
The paper argues the effect is driven by "stigma" in high-income areas. This is plausible but speculative. To strengthen this claim, consider auxiliary data sources. For example, scrape local news archives or Nextdoor/Reddit discussions near dispensary openings to quantify sentiment changes. Alternatively, use Google Trends data for search terms like "cannabis dispensary" or "crime" in the specific zip codes. If the property value drop is due to stigma, you should see increased search intensity for negative terms in high-income areas relative to low-income areas upon opening. This would move the mechanism from an assertion to an empirically tested channel.

**5. Address Zoning and Land Use Controls**
Dispensaries cannot open everywhere; they require specific zoning (often commercial or mixed-use). Neighborhoods zoned for dispensaries might differ systematically from those that are not. Include controls for local zoning changes or land-use composition (e.g., percentage of commercial zoning in the census tract) to ensure the effect is not confounded by broader commercial development trends that coincide with dispensary openings. If possible, restrict the sample to properties in zones where dispensaries
