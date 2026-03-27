# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-27T18:03:54.846084

---

**Idea Fidelity**

The paper is faithful to the manifest’s ambition of using the picture bride episode as a quasi-natural experiment to study the causal effect of family reunification on Japanese immigrant economic mobility. It uses the advertised IPUMS full-count data, focuses on male Japanese outcomes, contrasts them with Chinese men, exploits the 1920 Ladies’ Agreement cut-off, and connects the analysis to property-right constraints through Alien Land Laws. The key identification strategies described in the manifest—variation in spouse presence over time, the rationale for an exogenous supply shock to marriage opportunities, and the use of linked panels for within-person checks—are all present. The paper diverges modestly by framing the comparison as Japanese versus Chinese rather than married versus unmarried Japanese men, but that is still consistent with the manifest’s intent to isolate the effect of the picture bride system via a non-Japanese control group.

---

**Summary**

This paper studies the 1908–1920 picture bride system as an exogenous shock to Japanese immigrant family formation, using difference-in-differences with Chinese immigrants as a control group in IPUMS full-count decennial censuses. Despite a large increase in co-resident wives among Japanese men, the paper finds little change in occupational income scores but a substantial increase in farm ownership, especially where property rights were available. The story highlights property acquisition rather than wage mobility as the channel through which household formation delivered economic returns.

---

**Essential Points**

1. **Parallel trends assumption for the Japanese–Chinese DiD is weak.** Japanese and Chinese immigrants followed quite different economic trajectories before 1920 (differences in age composition, immigration timing, and responses to discrimination), and the paper’s reported pre-trends are limited to 1900–1910 for OCCSCORE. A DiD that spans three decades should show a richer event study for each outcome (especially the main ones: OCCSCORE and farm ownership) to demonstrate parallelism; otherwise the identification claim is fragile. In particular, the observed negative pre-trend in OCCSCORE from 1900 to 1910 suggests compositional changes due to the expansion of Japanese migration, which could bias post-1920 estimates. Please present event studies (or other diagnostics) for the outcomes to document that the Japanese–Chinese gap was stable absent the picture bride shock.

2. **Treatment variation conflates picture-bride-induced household formation with other contemporaneous shocks.** The Japanese × Post indicator captures every differential development after 1920, including the 1924 Immigration Act, heightened racial exclusion, and even the downstream effects of World War I demand shocks. There is no direct link between the differential change in farm ownership and spouse presence. Consider leveraging within-Japanese variation—marriage cohorts, timing of picture bride arrivals, or the timing of Ladies’ Agreement enforcement—to isolate the marriage effect from broader secular shifts. Alternately, exploit cross-state enforcement or differences in local adoption of immigrant-friendly institutions, using the sharp “closing” in mid-1920 to implement a regression-discontinuity or event-study that looks for a kink in spouse presence and outcomes around July 1920.

3. **The causal role of family formation in boosting farm ownership remains tenuous.** While the aggregate farm-ownership increase coincides with more spouses, the analysis never directly links spouse presence to property acquisition within a credible identification framework. The within-person panel regression is descriptive and subject to selection. To establish causality, the paper needs to show that the increase in farm ownership is driven by men who newly gained spouses due to picture bride access (e.g., instrument spouse presence by the post-1920 policy within the Japanese sample, or use marriage timing induced by the Ladies’ Agreement). Without such a strategy, the result risks conflating marriage supply with parallel trends in agricultural investment or land-price shifts unrelated to the picture bride system.

---

**Suggestions**

1. **Strengthen the credibility of the DiD.**  
   - Provide fully populated event-study plots for each main outcome (OCCSCORE, farm ownership, spouse presence) showing estimates for every census year relative to a base (e.g., 1910). This will clarify whether the parallel-trend assumption is tenable.  
   - Since the comparison spans 1900–1930, consider including 1900 explicitly in the DiD and showing leads and lags (the appendix could include tests for anticipation or dynamic effects).  
   - Alternatively, re-estimate the model using 1900–1920 only (pre- and post-picture bride shock) or incorporate 1930 as a robustness check rather than the main post period to mitigate confounding from the 1924 Immigration Act.

2. **Isolate the picture bride shock more cleanly.**  
   - Use the 1920 Ladies’ Agreement (and the sudden cutoff in March 1920) to implement a sharp regression-discontinuity design on the timing of picture bride arrivals: does spouse presence drop abruptly after the cutoff, and do outcomes for marriage-eligible cohorts also change?  
   - Explore differences between cohorts who arrived before vs. after 1920: newly arrived Japanese men should have had less time to form households even with picture brides, so comparing these groups may sharpen inference.  
   - If feasible, instrument Japanese men’s spouse presence in 1920 with the intensity of the picture bride influx in their pre-existing community (e.g., use state-level counts of picture bride entries or Japanese women per male) to trace how local marriage supply affects outcomes.

3. **Clarify the mechanism linking marriage to property.**  
   - Use the individual panel to track men who transition from spouse-absent to spouse-present status between 1910 and 1920 (or 1920–1930) and compare their farm ownership changes. Even if marriage is endogenous, comparing within-person changes before and after spouse arrival (i.e., an individual event study) would help.  
   - Explain how Farmer status is measured—does “farm owner” mean owning land outright, or merely residing on owned farmland (even if rented)? Decompose the outcome into different tenure types if possible (owner-occupied vs. renter), which would better capture “land acquisition.”  
   - Provide descriptive evidence that picture bride marriages coincided with moves to rural areas or the formation of farm households (e.g., by showing that spouse presence is associated with higher likelihood of living on a farm in 1910 versus 1920 among Japanese men, but not Chinese men).

4. **Address alternative explanations for the farm-ownership increase.**  
   - Document whether farm-ownership growth also occurred among Chinese men or other groups (e.g., Korean immigrants) during the same period; if yes, it may reflect broader agricultural opportunities rather than marriage.  
   - Discuss whether other policies (e.g., the 1913 Alien Land Law itself) affected farm ownership differentially across states or races in a way that could confound the DiD estimate. Incorporating interactions with state-level policy year indicators (beyond the ALI heterogeneity table) could clarify this.

5. **Augment robustness checks and heterogeneity analysis.**  
   - The heterogeneity table shows a striking sign reversal between ALI and non-ALI states, but the sample for non-ALI states is much smaller. Provide confidence intervals or a formal interaction test to show whether the difference is statistically meaningful.  
   - Include robustness exercises that vary the control group: for instance, compare Japanese men to white or other immigrant groups to see if the picture bride effect is unique to the Japanese–Chinese contrast.  
   - Report placebo tests using outcomes that should not be affected by marriage (e.g., height, if available, or urban/rural residence) to reinforce the interpretation.

6. **Clarify measurement and interpretation of OCCSCORE.**  
   - The discussion argues that OCCSCORE misses within-occupation mobility, but the paper never documents that picture brides actually moved Japanese men from tenant to owner while keeping the same occupation code. Consider linking farm ownership to occupation codes to show that Japanese men remained “farm laborers” even as they owned land.  
   - If available, compute alternative outcome measures (e.g., property value, rent) or use published data on farm acreage to triangulate the property channel.

7. **Discuss general equilibrium and external validity.**  
   - The increase in Japanese farm ownership may have resulted from Japanese immigration pushing into agricultural niches displacing other workers. Briefly discuss whether the property channel would apply outside the immigrant-dense West Coast or under different property regimes.  
   - Reflect on how relevant the picture bride episode is for modern family-based immigration debates; the paper’s implications would be more persuasive if you articulate the institutional differences (e.g., the presence of property rights, urban labor markets today).

Implementing these suggestions will strengthen the paper’s identification and deepen the interpretation of the land-ownership channel.
