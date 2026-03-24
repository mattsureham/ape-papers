# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-23T17:12:28.658563

---

**1. Idea Fidelity**

The paper deviates significantly from the Original Idea Manifest regarding the measurement of the key mechanism. The manifest explicitly proposed using **GDELT GKG (BigQuery)** to construct a "competing-news instrument" based on "daily article counts with Swiss locations, topic themes, article tone." This was central to the identification strategy: proving that foreign disasters *actually* crowded out Swiss referendum coverage in the media record.

The submitted paper, however, states in the Discussion section that "access limitations prevented [GDELT] use in this study." Instead, the authors construct a **proxy** for news salience based on USGS earthquake data and geographic distance to predefined media-market centroids. While the research question (does competing news affect turnout?) and the data source for outcomes (Swiss referendum data) remain faithful to the manifest, the substitution of actual media coverage data with a geographic proxy fundamentally alters the empirical claim. The paper asserts a "media crowding mechanism" but provides no direct evidence that media coverage actually shifted. This weakens the link to the Eisensee-Stromberg (2006) framework, which relies on observed media allocation, not inferred geographic salience.

**2. Summary**

This paper investigates whether exogenous foreign earthquakes reduce voter turnout in Swiss federal referendums by crowding out media coverage in language-specific markets. Exploiting variation across 175,000 municipality-ballot observations from 2015–2024, the authors find that a one-standard-deviation increase in earthquake salience reduces turnout by 3.3 percentage points, with stronger effects for low-salience ballot items. The study contributes to the literature on direct democracy and media economics by suggesting that geophysically random global events can influence democratic participation through language-segmented information environments.

**3. Essential Points**

The paper addresses a novel and important question, but three critical issues must be addressed before the causal claims can be supported:

1.  **Missing First-Stage Evidence (Media Coverage):** The core identification assumption is that earthquakes crowd out referendum news. However, the paper admits it lacks direct media data (GDELT). Without showing that high "earthquake salience" dates actually correspond to lower Swiss referendum coverage in German vs. French media, the mechanism remains hypothetical. It is possible that Swiss media coverage of referendums is invariant to foreign earthquakes, and the turnout effect operates through a different channel (e.g., voter mood or diaspora concerns). The authors must validate their salience proxy against actual media content for at least a subset of the sample.
2.  **Inference with Few Clusters:** The treatment varies at the vote-date-by-language-region level, yielding only 60 effective clusters (30 dates × 2 regions). The main result is significant only at the 10% level ($p \approx 0.08$). With few clusters, standard cluster-robust standard errors can be severely biased downward. The current inference is fragile. The authors need to employ wild cluster bootstrap procedures or randomization inference (permutation tests) to confirm that the result is not a statistical artifact of the limited variation.
3.  **Exclusion Restriction and Diaspora Confounds:** The paper acknowledges in the Introduction that German-language media has "deep ties to Turkey through decades of migration," yet dismisses direct effects too quickly. If an earthquake strikes Turkey, German-speaking Swiss voters (who have a larger Turkish diaspora population than French speakers) may be emotionally affected directly, independent of media coverage. This violates the exclusion restriction. The authors must control for municipality-level diaspora shares or show that the effect persists in municipalities with negligible diaspora populations.

**4. Suggestions**

The following recommendations are intended to strengthen the identification strategy and robustness of the paper. Addressing these would significantly elevate the contribution from a suggestive correlation to a credible causal estimate.

**Validate the Media Proxy with Auxiliary Data**
Since full GDELT access was unavailable, the authors should attempt to validate the "earthquake salience score" using alternative media data sources that are publicly accessible.
*   **Swiss Press Online:** Consider purchasing or accessing a subset of articles from *Swiss Press Online* (mediaresearch.ch) for the top 5 highest-salience and top 5 lowest-salience vote dates. Manually coding or keyword-searching these articles for "Referendum" vs. "Earthquake/Disaster" coverage by language (German vs. French) would provide a crucial first-stage test. Even a small sample (e.g., 100 articles per date) could confirm whether the geographic proxy correlates with actual editorial choices.
*   **Google Trends:** As a lower-cost alternative, use Google Trends data for search terms like "Abstimmung" (vote) vs. "Erdbeben" (earthquake) in Switzerland, filtered by language region. If the mechanism holds, search interest for voting should decline relative to earthquakes in the German region during high-salience seismic periods, but not in the French region. This would provide independent evidence of attention shifting.

**Strengthen Econometric Inference**
Given the small number of clusters (60), reliance on asymptotic cluster-robust standard errors is risky, especially for a result hovering near $p=0.10$.
*   **Wild Cluster Bootstrap:** Implement the wild cluster bootstrap percentile-t method (Cameron, Gelbach, and Miller 2008) specifically designed for few clusters. This often yields more conservative confidence intervals.
*   **Randomization Inference:** Conduct a permutation test where the earthquake salience scores are randomly reassigned across the 30 vote dates within each language region. Plot the distribution of coefficients from 1,000 permutations and show where the actual estimate falls. This non-parametric approach does not rely on asymptotic assumptions and is well-suited for this design.
*   **Conley Bounds:** Consider reporting Conley et al. (2012) bounds to show how much violation of the exclusion restriction (e.g., direct diaspora effects) would be needed to nullify the result.

**Address the Diaspora Channel Directly**
The distinction between "media crowding" and "direct emotional impact" is vital for the Eisensee-Stromberg interpretation.
*   **Diaspora Controls:** Interact the earthquake salience score with municipality-level shares of Turkish or foreign-born residents (available from Swiss Federal Statistical Office structural data). If the effect is driven by media crowding, it should be *uncorrelated* with diaspora share. If it is driven by direct emotional impact, it should be *stronger* in high-diaspora municipalities.
*   **Placebo Events:** Use earthquakes in regions with *no* diaspora ties to Switzerland (e.g., South Pacific) as a placebo test. If the effect disappears for these events, it suggests the main result might be driven by cultural ties rather than general news crowding.

**Refine the Salience Construction**
The current salience score uses fixed centroids (e.g., "Turkey" for German media). This is somewhat rigid.
*   **Dynamic Media Markets:** Instead of fixed centroids, consider using language-specific keyword weights. For example, weight earthquakes higher if they occur in countries where the primary language matches the Swiss region (German vs. French), rather than just geographic proximity. This might better capture the editorial logic of newsrooms.
*   **Time Decay:** The current 7-day window is reasonable, but news cycles are fast. Test a 3-day window (immediate pre-vote) vs. a 14-day window. If the mechanism is about crowding out *campaign* coverage, the effect should be strongest immediately before the vote.

**Clarify the Contribution Relative to the Manifest**
Given the absence of GDELT data, the authors should temper the claims regarding the "Eisensee-Stromberg mechanism."
*   **Reframing:** Instead of claiming to test the media crowding mechanism directly, frame the paper as testing the effect of *exogenous information shocks* on turnout. Acknowledge that while media crowding is the hypothesized channel, the paper identifies the reduced-form effect of global seismic activity.
*   **Policy Implications:** Expand on the "seismic distraction" concept. If turnout is vulnerable to random global events, discuss whether this implies a need for institutional buffers (e.g., mandatory minimum campaign silence periods or extended voting windows) to stabilize participation rates.

**Minor Data and Presentation Improvements**
*   **Table 1 (Summary Stats):** Include the variation in the salience score by language region. Currently, it aggregates both. Showing the mean/sd of salience for German vs. French regions separately would help the reader understand the identifying variation.
*   **Figure 1:** Add a binned scatter plot of turnout vs. salience for both language regions. Visualizing the negative slope for German regions and the flat/noisy slope for French regions (if applicable) would make the identification strategy immediately intuitive.
*   **Standardized Effects:** The appendix table on standardized effect sizes is excellent. Move this to the main text or ensure it is prominently referenced when discussing economic significance.

By addressing the missing first-stage evidence, tightening the inference for few clusters, and ruling out the diaspora confound, this paper could become a definitive study on how exogenous information environments shape direct democracy. Currently, it is a promising reduced-form analysis that requires additional validation to support its structural claims.
