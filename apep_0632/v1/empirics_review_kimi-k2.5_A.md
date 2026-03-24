# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-13T16:20:29.699973

---

**Referee Report: "The Green Backlash That Wasn't"**

---

### 1. Idea Fidelity

The paper hews closely to the original manifest's core empirical strategy: exploiting staggered ZFE implementation across French metropolitan areas using a spatial difference-in-discontinuities (diff-in-disc) design to identify effects on RN voting. The authors correctly prioritize the boundary discontinuity over cross-metro comparisons, emphasizing the necessity of metropolitan area fixed effects—a key insight previewed in the original idea.

However, the paper deviates from the manifest in two notable ways. First, the scope is narrowed from the proposed 12 metropolitan areas to only five (Paris, Toulouse, Reims, Saint-Étienne, Grenoble), restricted to those with ZFEs active before the April 2022 presidential election. This substantially reduces external validity and statistical power compared to the original design. Second, and more importantly, the paper omits the proposed sorting test using DVF (housing transaction) data to assess residential mobility across boundaries. Given that the null result could reflect compositional changes (disaffected voters moving out or affluent green voters moving in), omitting this test weakens the causal interpretation of the voting estimates.

---

### 2. Summary

This paper employs a spatial difference-in-discontinuities design at the boundaries of French Low-Emission Zones (ZFE) to test whether vehicle emission restrictions causally increased support for the Rassemblement National (RN) between 2017 and 2022. Despite strong raw correlations between ZFE coverage and RN gains, the authors demonstrate that these disappear when comparing communes within the same metropolitan area, yielding small, statistically insignificant estimates. The paper's central contribution is methodological: it reveals that spatial RDDs at urban policy boundaries suffer from severe omitted variable bias unless metropolitan fixed effects are included, providing a cautionary tale for the evaluation of congestion pricing, rent control, and other urban regulations.

---

### 3. Essential Points

**1. Critical small-sample limitations threaten statistical inference.**  
With only 50 treated communes (and merely 45 within the 3km bandwidth) across five metropolitan areas, the effective sample size is vanishingly small. The asymptotic approximations underlying the reported heteroskedasticity-robust standard errors are unreliable with such few clusters. More critically, with only five metropolitan areas, clustering standard errors at the metro level (the appropriate level given the treatment is defined at the boundary level) yields inference based on four degrees of freedom. The paper's claim that it can "rule out large backlash effects (5–10pp)" is optimistic; with a standard error of 2.1pp at the 5km bandwidth, the 95% confidence interval includes substantively meaningful effects (e.g., a +1.9pp increase, which represents a 10% increase over baseline RN support). The paper cannot distinguish between a true zero effect and modest but politically consequential backlash effects.

**2. Measurement error in treatment assignment biases estimates toward zero.**  
The paper assigns treatment based on commune centroids, but ZFE boundaries often slice through large suburban communes. For sizable communes (e.g., those with areas exceeding 10 km²), the centroid location poorly approximates the fraction of residents actually exposed to vehicle bans. This creates classical measurement error that attenuates estimated treatment effects. If the true effect is localized to households directly affected by the regulation, the centroid-based approach will obscure it, particularly for the large-area communes common in French suburbs. The paper acknowledges this issue but does not mitigate it (e.g., by restricting the sample to small-area communes or employing a "fuzzy" RDD using the share of commune area inside the ZFE).

**3. Temporal heterogeneity in treatment exposure is ignored.**  
The design pools ZFEs implemented years apart: Grenoble's ZFE began in May 2019 (nearly three years of exposure), while Toulouse, Reims, and Saint-Étienne activated within two months of the April 2022 election. Paris implemented its restrictions in June 2021. This conflates potential long-run adaptation/resentment (Grenoble) with immediate short-run reactions (Toulouse). If backlash requires time to crystallize or if anticipation effects dominate, pooling these timings induces severe heterogeneity bias. The staggered adoption that the paper exploits as an identification asset thus becomes a threat to internal validity when collapsed into a single pre/post comparison.

---

### 4. Suggestions

**Address measurement error directly.** Restrict the primary sample to communes with geographic areas below the median (or some threshold where the centroid approximation is credible). Alternatively, calculate the exact share of each commune's population or land area falling within the ZFE perimeter and employ this as a continuous treatment measure in a "fuzzy" spatial RDD framework. This would recover the local average treatment effect for compliers (communes fully inside versus fully outside) and provide a robustness check on the centroid-based results.

**Exploit temporal variation more carefully.** Instead of a single 2017–2022 difference, estimate event-study specifications that allow effects to vary by exposure duration. Specifically, compare Grenoble (early adopter) separately from the 2021–2022 adopters. If the null result persists in Grenoble despite three years of exposure, this strengthens the claim that ZFEs do not generate localized backlash; conversely, finding effects only in recent adopters would suggest short-run mobilization. The current pooling obscures these distinct mechanisms.

**Include the missing sorting test.** The original manifest proposed using DVF (Demande de Valeurs Foncières) housing transaction data to test for sorting across boundaries. This is essential for interpreting the null voting result. If ZFE implementation induced differential residential sorting (e.g., high-income households with electric vehicles moving in, working-class households with older vehicles moving out), the voting estimates capture a compositionally changed electorate rather than stable preferences. Implement the boundary discontinuity test for housing prices and transaction volumes to assess whether the "control" group remains valid.

**Clarify the estimand and external validity.** The paper tests for *localized* boundary effects, but the political narrative about "populist backlash" (cited in the introduction) may operate through general equilibrium channels: media coverage, national political entrepreneurship, or anticipation of future restrictions. The estimand is the effect of being inside versus outside the zone *at the boundary*, not the aggregate effect of ZFEs on metropolitan voting patterns. The paper should explicitly acknowledge that the absence of a boundary discontinuity is consistent with a diffuse national backlash that affects voters on both sides of the perimeter equally (e.g., suburban voters resenting ZFEs even if they don't face immediate restrictions).

**Improve inference for few clusters.** Report p-values using wild cluster bootstrap-t procedures given the small number of metropolitan areas (Cameron, Gelbach & Miller, 2008). The current robust standard errors likely understate true uncertainty. Additionally, conduct a detailed power analysis showing the minimum detectable effect size given the sample constraints, and frame the conclusion as "no evidence of large effects" rather than "no backlash."

**Discuss enforcement heterogeneity.** The paper notes enforcement may have been weak, but does not measure it. If available, incorporate data on camera installations or fine issuance rates by metropolitan area to test whether null effects correlate with weak implementation. This would help distinguish between "ZFEs don't cause backlash" and "unenforced ZFEs don't cause backlash."

**Consider the 2024 legislative elections.** The appendix mentions 2024 legislative data but dismisses it due to constituency complications. Given the small sample in the main analysis, even descriptive evidence from 2024 (using proportional swing estimates) could bolster the claim that the 2022 null result persists. If inclusion is infeasible, explain clearly why single-member district战略性 voting makes commune-level analysis impossible (e.g., candidate withdrawal agreements between parties).

**Refine the interpretation of the "spurious correlation" result.** The decomposition showing that omitting metro fixed effects creates a +17.6pp effect is compelling, but the paper should note that this arises because Paris (large, left-leaning) dominates the sample. A simple plot of the raw data by metro would illustrate this confound visually and strengthen the pedagogical value of the point.

Overall, this is a promising paper addressing a timely policy question with a clever research design. However, the severe sample size constraints, measurement issues, and temporal heterogeneity require more careful addressing before the null result can be interpreted as evidence that France "misdiagnosed" voter behavior.
