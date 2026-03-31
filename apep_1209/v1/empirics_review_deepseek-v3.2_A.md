# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-31T16:03:57.185047

---

**Review of "The Dispensary Next Door: Lottery-Assigned Cannabis Retail and Neighborhood Housing Values"**

**1. Idea Fidelity**
The paper only partially pursues the original idea outlined in the manifest. The core, innovative element of the original proposal was a **spatial Instrumental Variables (IV) design** using the lottery draw *within BLS regions* as an instrument for dispensary proximity. This IV strategy was explicitly proposed to solve the endogenous site selection problem plaguing the literature. The submitted paper, however, abandons this approach in favor of a standard difference-in-differences (DiD) design comparing properties near and far from dispensaries, relying on dispensary-cluster fixed effects. This is a significant departure. While the lottery is discussed as providing exogeneity *for the location of treatment*, the empirical strategy does not operationalize the lottery as an instrument. It treats all dispensaries—including 39 pre-lottery, medically converted ones—as part of the same identification strategy, diluting the lottery-based variation. The paper also mentions crime data but presents a simple, aggregated community-area level analysis, not the spatial, microdata-based crime analysis suggested in the manifest. While the research question (effects on property values and crime) and data sources are largely aligned, the failure to implement the promised IV design means the paper does not deliver the "cleanest identification ever brought to this question" as originally envisioned.

**2. Summary**
This paper investigates the impact of cannabis dispensary openings on local property values and crime in Cook County, Illinois. Its key contribution is leveraging the random assignment of dispensary licenses through state-run lotteries to address the endemic site-selection endogeneity in this literature. The main finding is a modest, approximately 6% decline in property values within half a mile of a dispensary after it opens, with effects concentrated in higher-income neighborhoods and accompanied by an increase in reported drug crimes but not violent or property crimes.

**3. Essential Points**
The following three issues are critical and must be convincingly addressed for the paper to be considered for publication.

1.  **The Identification Strategy is Fundamentally Flawed and Misaligned with the Proposed Innovation.** The paper employs a DiD design with distance rings and dispensary-cluster fixed effects. This does not leverage the lottery as a source of *random variation in location*. The design compares properties *within* a dispensary's catchment area (near vs. far), which does not solve the problem that the *placement* of the dispensary cluster itself may be endogenous. The lottery's power is in creating random assignment **across qualified applicant locations within a BLS region**. The paper must implement the IV strategy outlined in the manifest: using the lottery outcome (win/loss) within a BLS region as an instrument for the actual opening of a dispensary at a *specific, applicant-proposed location*. The first stage would predict dispensary opening at a given location (or within a given geography) using the lottery draw. The reduced form would assess the effect of lottery winning on outcomes in that area. This "intent-to-treat" / LATE framework is the credible, quasi-experimental design promised. The current DiD approach, while controlling for time-invariant cluster characteristics, does not justify its key assumption—that the *choice* of which cluster gets a dispensary is uncorrelated with neighborhood trends—nearly as well as the IV design would.

2.  **The "Distance Ring" Treatment Definition is Ad Hoc and Susceptible to Bias.** Defining treatment based on distance thresholds (0.25, 0.5 miles) from *any* dispensary is problematic. Properties are assigned to their nearest dispensary, but a property just beyond 0.5 miles from Dispensary A might be within 0.25 miles of Dispensary B. The current approach does not account for this spatial competition or contamination. More seriously, it creates a non-random comparison group: "far" properties (e.g., 0.5-1.0 miles away) are likely systematically different from "near" properties, and these differences may trend differently over time. The paper needs a more rigorous, spatially-aware design. Options include: (a) using a continuous treatment measure (e.g., inverse distance) in the IV framework, (b) implementing a spatial regression discontinuity design using the lottery winner's proposed location as a treatment boundary, or (c) carefully constructing matched control *areas* based on lottery losers' proposed locations, as suggested in the manifest. The current ring analysis is descriptive but not causally rigorous.

3.  **Severe Measurement Error in Key Variables Undermines the Estimates.** The paper geocodes dispensaries to **ZIP Code centroids**. The distance from a property to a ZIP centroid is a very poor proxy for distance to the actual dispensary, which is a specific street address. This introduces massive, non-classical measurement error. Properties coded as "near" a centroid could be miles from the actual dispensary, and vice-versa. This error biases treatment effect estimates toward zero, making the reported 6% decline likely a substantial underestimate of the true effect. This flaw alone could justify rejection. The authors must obtain exact street addresses for dispensaries (publicly available from IDFPR or commercial sources) and perform proper geocoding. Similarly, for crime, aggregation to community areas loses the micro-spatial variation crucial for detecting localized effects. The analysis should use the geocoded incident data to calculate crime densities within the same distance rings used for property values.

**4. Suggestions**
*   **Fully Implement the Lottery IV Design:** Re-orient the entire empirical section. Specify the model:
    *   **First Stage:** `DispensaryOpened_{j} = α + π LotteryWinner_{j} + Z_{j}γ + η_{j}` for location/area `j`. Cluster `j` could be a census tract, block group, or a buffer around an applicant's proposed address.
    *   **Reduced Form:** `Y_{ijt} = α + β LotteryWinner_{j} × Post_{t} + X_{ijt}δ + μ_{j} + λ_{t} + ε_{ijt}`.
    *   Use only the 185 lottery-allocated licenses. Exclude the 39 pre-lottery medical conversions, as their locations are endogenous. This clarifies the source of variation.
    *   Explain the exclusion restriction: lottery winning affects outcomes only through dispensary opening (plausible given state rules) and is random conditional on BLS region and qualifying score.
    *   Present first-stage F-statistics to demonstrate instrument strength.

*   **Refine the Treatment and Sample Construction:**
    *   Obtain exact dispensary addresses and geocode them precisely. Calculate accurate distances.
    *   Consider defining treatment at the **neighborhood level** (e.g., census block group). A block group is "treated" if a lottery-winning dispensary opens within its boundaries or a specified buffer. Control block groups are those containing or near lottery-loser proposed locations from the same BLS region drawing.
    *   Use the Callaway & Sant'Anna estimator for staggered adoption, as mentioned in the manifest, to address potential bias from heterogeneous treatment effects across opening cohorts.

*   **Deepen the Crime Analysis:** The community-area analysis is too coarse. Replicate the property value analysis at a micro-geography level (e.g., block group-quarter) for crime counts. Use the same IV framework. Examine not just levels but also spatial displacement (does crime move around the corner?). The reported 34% drug crime increase is striking; is this driven by arrests for cannabis possession (which should fall with legalization) or other drug offenses? Disaggregate further.

*   **Improve the Data and Transparency:**
    *   Clearly report the number of lottery-winner dispensaries in the final sample used for estimation. The manifest mentions ~36 in Chicago; the paper says 74 lottery-era dispensaries in Cook County. This discrepancy needs clarification. If the sample is small, acknowledge power limitations.
    *   The property sales sample (26,740) seems small for Cook County over 6-7 years. Discuss potential selection: why do only these parcels have geocodes? Is this a random subset?
    *   Provide balance tables demonstrating that, within BLS regions, neighborhoods where lottery winners proposed locations are similar on pre-determined characteristics (income, demographics, pre-trends in prices/crime) to neighborhoods where losers proposed locations. This is a critical validity check for the IV.

*   **Strengthen the Interpretation and Discussion:**
    *   The "stigma premium" interpretation is interesting. Could it be tested? Interact the treatment effect with pre-legalization measures of community conservatism (e.g., vote share for anti-legalization referenda, church density).
    *   Discuss the policy implications more sharply. A 6% price effect is economically significant for homeowners. Who bears this cost? Is it a pure transfer, or a social cost?
    *   Acknowledge limitations beyond measurement error: e.g., general equilibrium effects (if many dispensaries open, the effect on any one neighborhood may change), the fact that "lottery loser" locations may eventually see a dispensary open if the loser obtains a license later (requires a careful definition of the "control" group and perhaps a focus on early periods).

*   **Minor Clarifications:**
    *   The abstract claims "34 percent increase in reported drug crimes," but Table 3 coefficient is 0.2913. Clarify that this is a log-point increase.
    *   In Table 1, define "Post-opening sales" more clearly.
    *   The conclusion's comparison to a "gas station" is evocative but needs a citation for the gas station effect size.

In sum, the paper has a promising premise but currently falls short of its methodological potential. The authors have the data and the institutional setting to execute a landmark study. To reach that standard, they must fundamentally revise the empirical strategy to implement the lottery-based IV, correct the critical measurement error, and conduct a more spatially-disciplined analysis. The suggestions above provide a path to achieving this.
