# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-25T12:25:16.832551

---

 **Referee Report: "Pushed Out, Moved Up: Cotton Displacement, the Second Great Migration, and Long-Run Black Occupational Convergence"**

---

### 1. Fidelity to Core Argument and Identification Strategy

The manuscript pursues the empirical ambition outlined in the manifest: tracing individual-level occupational trajectories of Black farm workers across the 1930–1950 period using linked census data, and testing whether Agricultural Adjustment Act (AAA)-induced displacement caused "scarring" or, alternatively, forced mobility that improved long-run outcomes. The triple-difference (DDD) design—interacting county-level farm share with an individual Black indicator and post-1930 waves—is appropriate in principle for distinguishing race-specific exposure to cotton dependence from general Southern agricultural decline.  

However, the execution falls short of the manifest’s promise on three critical identification dimensions. First, the "treatment" (county farm share) is a proxy for AAA exposure rather than a direct measure of acreage reduction contracts or eviction intensity; the paper acknowledges enforcement was weak, yet treats farm share as exogenous conditional on fixed effects. Second, the promised pre-trend validation using 1920–1930 linked data is referenced but not reported in the results tables, leaving the parallel trends assumption untested. Third, the mechanism attribution—to migration as liberation—relies on atiming that is blurry: the 1940 wave captures outcomes only 4–7 years after peak AAA activity, conflating immediate displacement with the lagged migration decisions that characteristically defined the Second Great Migration (1940–1970). While the paper delivers a clear result (positive DDD coefficient), the claim that this identifies "displacement as liberation" rather than differential selection into migration or pre-existing convergence trends requires stronger evidentiary support.

---

### 2. Summary

Using the MLPanel linked census (1930–1950), the paper estimates a triple-difference design comparing 20-year occupational score changes for Black versus white male farm workers across counties with varying agricultural intensity. The key finding is that Black workers in cotton-dependent counties experienced a 0.57-point (p = 0.008) relative occupational gain by 1950 compared to their trajectories in less agricultural counties, a result interpreted as evidence that AAA displacement accelerated convergence through Northern migration rather than scarring workers in place.

---

### 3. Essential Points (Must Address for Publication)

**Endogeneity of the County-Level Treatment.** The identifying variation relies on Black workers in high-farm-share counties experiencing different trends than those in low-farm-share counties after 1930, conditional on state-by-year fixed effects. This is fragile. County farm share correlates with soil quality, historical slavery intensity, boll weevil infestation timing, and pre-existing racial wage gaps—all potential determinants of occupational mobility that may trend differentially for Black workers regardless of AAA exposure. The DDD requires parallel trends between Black and white workers *within* farm-share quartiles pre-1930, yet the paper does not report placebo estimates from the 1920–1930 period (despite noting the data exist). Without evidence that Black-white occupational gaps evolved similarly across high and low cotton counties prior to treatment, the 0.57-point coefficient may reflect pre-existing convergence dynamics or spatial sorting rather than AAA-induced displacement. The authors must either (a) present 1920–1930 event-study plots showing no differential pre-trends, or (b) demonstrate that farm share is uncorrelated with 1920–1930 occupational changes conditional on controls. Absent this, the paper’s causal claim is unsubstantiated.

**Interpretation of Occupational Scores as “Mobility.”** The dependent variable (`occscore`) is the median 1950 income for each occupation code. The paper interprets gains in this variable as “occupational mobility,” but this conflates individual upward movement with structural economic transformation. When a displaced sharecropper (occscore ≈ 6) appears in 1950 as a Chicago factory operative (occscore ≈ 18), the 12-point gain reflects the destination occupation’s wage structure, not necessarily the individual’s skill acquisition or “liberation” from scarring. Moreover, the fixed effects absorb time-invariant individual heterogeneity, but not time-varying selection: the most able or networked workers may have migrated first, generating positive selection into the “mover” category that is correlated with farm share. The paper must clarify whether the DDD estimates reflect (a) within-individual occupational upgrading, (b) compositional shifts as low-scorers exit the sample (die or migrate untracked), or (c) general equilibrium effects of Black out-migration on stayers’ labor market opportunities. A test distinguishing between movers who switched occupations versus those who exited farming but remained in the South would clarify whether the mechanism is truly Northern industrial upgrading or merely exit from the bottom rung of Southern agriculture.

**Temporal Ambiguity and Mechanism Attribution.** The AAA program operated 1933–1936, yet the first post-treatment wave is 1940. By 1940, many displaced workers may still have been in transition (living as tenant farmers elsewhere in the South, or in temporary urban Southern work), while the full “Second Great Migration” acceleration occurred 1940–1950. The DDD coefficient for 1940 (0.86 points) is larger than for 1950 (0.28 points, insignificant), suggesting the effect fades rather than compounds, which is inconsistent with a permanent migration-driven convergence mechanism. The paper claims migration attenuates scarring, but the cross-sectional migration indicator (`mover_40_50`) conflates 1940–1950 moves with 1930–1940 displacement timing. The authors need to demonstrate that the 1940 occupational gains are not merely noise from immediate displacement (which would show up as *lower* scores if scarring dominated), and that the 1940–1950 migration flows are causally linked to 1933–1936 AAA exposure rather than to wartime labor demand (1941–1945) that differentially affected cotton counties through non-AAA channels.

---

### 4. Detailed Suggestions for Revision

**Strengthen Instrumental Validity or Narrow Claims.** If county farm share is the only available treatment proxy, the authors should instrument it using pre-AAA soil productivity interacted with the national cotton price collapse (1929–1933), or using variation in AAA payment uptake from Fishback-Kantor-Wallis (ICPSR #2603) rather than the general farm share. Alternatively, frame the paper as estimating the effect of *cotton dependence* (not AAA specifically) on Black occupational trajectories, acknowledging that the mechanism includes broader mechanization and the boll weevil. This would be honest about the reduced-form nature of the estimate while retaining the contribution of individual-level tracking.

**Decompose the Mechanism.** The migration result (Table 3) is the paper’s most compelling evidence, but it is under-identified. Suggestions:  
- Split `mover_40_50` into (i) intrastate movers to Southern cities, (ii) interstate movers to border states, and
