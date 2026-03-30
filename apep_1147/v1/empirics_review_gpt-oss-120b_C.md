# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-30T15:49:04.771236

---

**1. Idea Fidelity**

The paper stays largely faithful to the original manifest. It uses the QWI county‑race panel, the four staggered Right‑to‑Work (RTW) adopters (IN, MI, WI, WV), and never‑treated neighboring states as controls. The identification strategy matches the proposed Callaway‑Sant’Anna staggered DiD, although the author ultimately reports a conventional triple‑difference (DDD) with state‑quarter fixed effects rather than the explicit CS‑ATT estimates. The manuscript therefore drops the CS‑ATT “group‑time” aggregation that the manifest highlighted, but the Sun‑Abraham event‑study is reported as a robustness check, which partially recovers the intended heterogeneity‑robustness. Overall, the core research question and data source are intact; the only noticeable deviation is the omission of the primary CS‑ATT table and a limited discussion of dynamic treatment effects across cohorts.

**2. Summary**

The paper asks whether weakening union power via recent RTW laws altered the Black‑White earnings gap. Exploiting staggered adoption across four Midwestern/Appalachian states and a triple‑difference design with county‑race, quarter‑race, and state‑quarter fixed effects, the author finds a null effect: the differential impact on log earnings is –0.012 (SE 0.026). Sun‑Abraham ATT estimates for Black and White workers are both close to zero, and a battery of placebo and leave‑one‑out tests support the finding. The result suggests that RTW‑induced de‑unionization does not drive racial wage disparity.

**3. Essential Points**

1. **Inference with Very Few Treated Clusters**  
   - The standard errors are clustered at the *state* level, but there are only **four** treated states. Cluster‑robust inference with ≤5 clusters is known to be unreliable and can severely under‑state the true variance. The paper should either (a) use wild bootstrap (e.g., Cameron, Gelbach, and Miller 2008) or the “cluster‑by‑county” approach together with a randomization inference, or (b) report results with alternative clustering (e.g., county) and robust confidence intervals (CRV2, Bell–Mammen). Without this, the reported SE = 0.026 may be far too optimistic.

2. **Parallel‑Trends Assumption Not Fully Tested**  
   - The manuscript shows a “placebo” test with a fake treatment 12 quarters earlier, but this does not substitute for a visual/event‑study inspection of pre‑trends **separately for Black and White** workers. Because the DDD relies on *within‑state* racial gap trends, one should plot the Black‑White earnings gap for treated vs. control states over the full pre‑period (2005‑2011) and formally test for differential pre‑trends (e.g., regress leads of the DDD term). The current evidence is insufficient to rule out that the gap was already diverging before RTW.

3. **Treatment Timing and Cohort Heterogeneity Not Fully Explored**  
   - The main specification collapses across cohorts, yet the manifest emphasized a Callaway‑Sant’Anna approach to allow for cohort‑specific ATT. The Sun‑Abraham estimates are presented, but only as overall ATT for each race, not as *dynamic* ATT by cohort and event time. If effects differ (e.g., a stronger response in the 2012 cohort vs. 2016), the DDD estimate may average to zero and mask important heterogeneity. The paper should present the cohort‑specific event‑study graphs and discuss any variation.

**4. Suggestions**

1. **Improve Inference with Few Clusters**  
   - Implement a wild cluster bootstrap (R‑bootstrap) at the state level (e.g., 5,000 replications) and report the bootstrap p‑values and confidence intervals.  
   - As a complement, conduct a permutation (randomization) test by randomly assigning “pseudo‑RTW” dates to the four treated states many times and recomputing the DDD coefficient; this will give a distribution under the null that respects the limited number of clusters.  
   - Report standard errors clustered at the county level as a robustness check, acknowledging potential serial correlation and adjusting with a multi-way clustering (county × state) if feasible.

2. **Strengthen Parallel‑Trends Evidence**  
   - Plot the Black‑White earnings gap (log ratio) for each treated state and the synthetic control group (average of never‑treated states) over the full pre‑period. Include separate lines for Black and White earnings to illustrate that the gap trends are parallel before RTW.  
   - Estimate a “lead” specification: add interactions for periods −4, −3, −2, −1 (relative to RTW) and test jointly that they are zero. Report the F‑statistic and p‑value.  
   - If any pre‑trend violation appears, consider adding state‑specific linear trends or controlling for pre‑treated gap levels.

3. **Present Full Callaway‑Sant’Anna / Sun‑Abraham Results**  
   - Compute cohort‑specific ATT (e.g., for IN/MI cohort 2012, WI cohort 2015, WV cohort 2016) for each race and for the gap. Plot the dynamic treatment effects (event‑time coefficients) with 95 % confidence bands.  
   - Discuss whether the gap responds differently for early vs. late adopters, which could be linked to differing union density or industry composition across states.  
   - If cohort heterogeneity is negligible, explicitly state this; if not, interpret the economic magnitude.

4. **Consider Alternative Outcome Measures**  
   - The paper focuses on average stable‑worker earnings (EarnS). Union bargaining may affect **distributional** aspects (e.g., 10th vs. 90th percentiles) more than the mean. If feasible, compute the Black‑White earnings *ratio* (or log ratio) directly rather than using log earnings with race fixed effects; this could provide a more transparent measure of the gap.  
   - Use the QWI “median earnings” or “10th percentile earnings” if available, to test whether the gap at the lower tail is affected.

5. **Address Potential Spillovers and Mobility**  
   - Discuss whether workers might relocate across county borders in response to RTW (e.g., moving from a treated to a neighboring untreated county). Although the QWI is county‑level, some mobility could attenuate the estimated effect. A simple robustness check could restrict the sample to “core” counties far from state borders (e.g., >50 km) and re‑estimate.  
   - Alternatively, include a control for county‑level unionization rates (pre‑RTW) to ensure that the treated counties do indeed have higher baseline union density, strengthening the relevance of the instrument.

6. **Clarify Sample Construction and Attrition**  
   - The manuscript notes a balanced panel requirement of ≥20 pre‑treatment quarters, but does not report how many county‑race observations are dropped after 2012 due to missing data. Provide a table showing the number of observations before/after trimming, and test whether attrition is correlated with treatment status.  
   - Consider a “unbalanced” panel with all available observations and include county‑race × quarter FE to soak up missingness; this can increase power without biasing the DiD.

7. **Economic Interpretation and Power Analysis**  
   - Translate the point estimate into a more intuitive metric: a –0.012 change in the log earnings gap corresponds to roughly a 1.2 % reduction in the Black‑White earnings ratio. Discuss whether, given the pre‑trend decline in the gap (≈3 % over the sample), this magnitude is substantively meaningful.  
   - Conduct a post‑hoc power calculation given the effective number of clusters (4) and the observed variance; this will help readers gauge whether the study is truly “well‑powered” or simply under‑identified.

8. **Minor Presentation Enhancements**  
   - Move the “RTW × Post” row out of the tables; it is redundant since the DDD variable already captures the triple interaction.  
   - Rename “Log Earnings” columns to “Log Quarterly Earnings (All Industries)” for clarity.  
   - Include a simple schematic diagram of the identification strategy (timeline of RTW adoption, treatment/control groups, and the DDD interaction) near the empirical strategy section.  
   - Ensure all references to “Callaway‑Sant’Anna” in the text are reflected in the bibliography; the current reference list appears missing.

By addressing the inference issue, bolstering the parallel‑trend validation, and delivering the full cohort‑specific DiD results envisioned in the original manifest, the paper will substantially improve its credibility and contribution. The core finding—a null differential effect of RTW on the Black‑White earnings gap—remains interesting, especially given the policy relevance of unions as a potential “racial shield.” Strengthening the methodological rigor will allow the result to be taken seriously by both labor‑economics and race‑inequality scholars.
