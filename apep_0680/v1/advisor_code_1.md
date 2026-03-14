# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-14T16:04:14.868531

---

**Idea Fidelity**

The paper adheres closely to the original idea laid out in the manifest. It retains the focus on Lyon’s ZFE and the question of whether vehicle bans are capitalized into housing values via a spatial regression discontinuity at the ZFE boundary. The data sources, including DVF transaction data and the official ZFE polygon, are the ones promised, and the core identification strategy—spatial RDD with a difference-in-discontinuities twist—is faithfully pursued. The paper also retains the emphasis on the policy implications of France’s prospective ZFE abolition and contributes the novelty of being the first spatial RDD on a French ZFE boundary, as promised.

**Summary**

This paper estimates the causal effect of Lyon’s Low-Emission Zone (ZFE) on nearby residential property values by exploiting the sharp spatial boundary of the ZFE as a regression discontinuity. Using DVF microdata and a difference-in-discontinuities design to net out pre-existing boundary gaps, the author finds that properties just inside the ZFE sold for roughly 10.5 percent less per square meter than those just outside, with the effect concentrated in apartments and materializing with the initial vehicle ban. The work thus documents a “mobility tax” that dominates any air-quality premium in housing capitalization.

**Essential Points**

1. **Threat from heterogeneous pre-trends and boundary selection:** The validity of the spatial RDD rests on the assumption that the boundary was not correlated with unobserved determinants of housing prices beyond the ZFE itself. The paper acknowledges that the Boulevard Laurent Bonnevay delineates a clear urban-suburban divide and documents a pre-existing 7 percent discontinuity. However, the difference-in-discontinuities design may not fully account for time-varying heterogeneity: if inner-city versus outer-ring property markets were evolving differently around the boundary in ways unrelated to the ZFE (e.g., differential urban redevelopment, transportation investments, or amenities improving faster inside), the post–pre discontinuity could still be confounded. More evidence is needed that there were no divergent pre-trends in prices, transaction volumes, or neighborhood amenities that coincide with the ZFE implementation period besides the policy itself.

2. **Interpretation of the “difference-in-discontinuities” estimator:** The preferred estimate (\( \tau^{DD} \)) is interpreted as the causal effect of the ZFE, but it is constructed as the change in the boundary discontinuity before versus after September 2022. If there were contemporaneous shocks that differentially affected inside versus outside areas starting in September 2022 (e.g., other urban policies, infrastructure projects, macro shocks hitting the central city harder than the periphery), \( \tau^{DD} \) would absorb those as well. The author should more explicitly discuss and, ideally, empirically rule out such confounding shocks (e.g., by showing that no other major policy change coincided with the ZFE timing or by controlling for observable shocks). In addition, the paper should clarify whether the diff-in-disc specification includes flexible time trends on each side, or whether it relies solely on the binary Post indicator, given that transaction volumes and price dynamics may differ smoothly over time.

3. **Mechanism evidence on air quality versus accessibility:** The interpretation that accessibility costs dominate air quality benefits hinges on the assumption that pollution improvements were small while accessibility losses were large. The paper mentions NO2 data as a secondary source but never presents system-wide evidence of pollution change or the Los effect. Without documenting that air quality either did not improve meaningfully or that the timing of air quality gains does not align with the price drop, it is hard to rule out alternative explanations (e.g., backlash against increased traffic congestion from diverted vehicles, concerns about enforcement uncertainty). Providing evidence on pollution trends, mobility patterns, or even survey-based perceptions would ground the mechanism discussion more firmly.

**Suggestions**

1. **Strengthen pre-trend validation:**  
   - Include event-study–style plots showing the evolution of the price discontinuity at the boundary over time, ideally quarterly, to demonstrate that the jump only emerged after the ZFE implementation and was stable beforehand.  
   - Extend the placebo tests in Table 4 to include “falsification boundaries” along other segments of the Boulevard Laurent Bonnevay or other similar ring roads to show that discontinuity changes are not generic to the road itself.  
   - Explore a triple-difference by comparing Lyon’s boundary to another similar boundary in a city without a ZFE (if feasible) or using other boundaries within Lyon that did not experience policy changes.

2. **Clarify the diff-in-disc specification:**  
   - Provide the full estimation equation in the text (e.g., does \( f(d_i,t) \) interact distance with Post? Are time trends allowed on each side?).  
   - Report estimates separately for Post and Pre periods (i.e., show the discontinuity coefficient in each period) so readers can see the two levels that generate \( \tau^{DD} \).  
   - Investigate whether including property-specific time-varying controls (e.g., local construction permits, amenities) alters the diff-in-disc estimate, to address concerns about coincident shocks.

3. **Leverage air quality and accessibility data more directly:**  
   - Use the NO\(_2\) station data mentioned in the abstract to report time series of pollution levels inside and outside the ZFE before and after implementation, ideally within the bandwidth used for the RDD. If pollution reductions were modest or delayed, that would bolster the claim that accessibility loss dominated.  
   - Conversely, if pollution did fall appreciably, the paper should discuss why that did not translate into price increases (e.g., heterogeneous valuation of health benefits, high discounting).  
   - Consider using proxies for accessibility (e.g., changes in traffic counts, delivery restrictions, enforcement fines, or survey data on commuting difficulties) to show the salience of mobility costs. Even if rich data are unavailable, a qualitative narrative grounded in municipal communication or enforcement data would strengthen the mechanism story.

4. **Address compositional change and covariate adjustment concerns:**  
   - The covariate balance table shows significant differences in surface, rooms, and apartment shares within 500 meters, yet the RDD assumes those are balanced conditional on the distance function. It would be helpful to show that including richer controls (e.g., age of building, floor number for apartments if available, or proxies for amenities) does not materially change the estimate, or to present a table where the coefficient is stable when excluding controls versus including them.  
   - For the diff-in-disc, demonstrate that the results are robust to limiting the sample to narrower windows (e.g., 500 m) where compositional differences are smaller, or to running the specification separately for apartments and houses to show consistent patterns.

5. **Interpretation in light of policy debate:**  
   - The finding of a large negative capitalization effect has strong policy implications, but its generalizability beyond Lyon (or beyond apartment-heavy zones) should be qualified. Discuss whether similar boundaries in smaller cities might produce different results because of different transportation options or housing stock.  
   - Since the paper is framed around the potential abolition of ZFEs, consider briefly modeling the wealth transfer implied by the price drop (e.g., total value lost among affected homeowners) to illustrate the scale of the “mobility tax.” This would make the policy relevance more tangible for the AER: Insights audience, which often benefits from simple back-of-the-envelope calculations.

6. **Improve presentation of results:**  
   - Figure(s) showing the scatter of log prices against distance with the fitted RDD line would help readers intuitively grasp the discontinuity.  
   - Provide a plot of the diff-in-disc by showing the estimated discontinuity in the pre-period and post-period, perhaps with confidence intervals, to visually justify the interpretation.  
   - In Table 2, clarify what “Effective N” refers to in columns (1) and (2) (e.g., number of observations within bandwidth? number of weighted observations?).  
   - In the robustness section, the RDD estimate becomes smaller in magnitude at 2 km, but the standard error also shrinks. Explicitly discuss whether this reflects inclusion of heterogeneous neighborhoods or mechanical attenuation due to smoothing, and whether the conclusions hinge on narrow bandwidths.

7. **Language and tone:**  
   - The abstract and introduction use charged terms such as “penalize” and “mobility tax.” While evocative, tempering them slightly (e.g., “map out” instead of “penalize”) would align better with AER’s preference for neutral language while still conveying the substantive finding.  
   - Ensure that references cited (e.g., \citet{sager2025environmental}, \citet{kariel2025ulez}) are real and properly formatted; otherwise, substitute with existing literature or note when citations are forthcoming.

Implementing these suggestions would clarify the causal interpretation, reinforce the mechanism narrative, and better situate the paper within both the spatial RDD literature and the policy debate around low-emission zones.
