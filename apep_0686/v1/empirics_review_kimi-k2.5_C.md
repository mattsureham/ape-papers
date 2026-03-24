# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-14T19:24:32.906856

---

**Review of "The Presumption Paradox: Does Overriding Local Planning Discretion Increase Housing Supply in England?"**

### 1. Idea Fidelity

The paper pursues the core identification strategy outlined in the manifest—exploiting the 75% Housing Delivery Test (HDT) threshold via sharp regression discontinuity—but deviates in two consequential ways. First, it uses only four HDT rounds (2020–2023) rather than the six rounds (2018–2023) specified in the manifest, omitting the 2018 and 2019 rounds where the presumption threshold was lower (25% and 45%, respectively). This is justifiable given the phased policy rollout, but the reduction in sample size (1,184 vs. projected 1,866 observations) materially affects power. Second, the manifest promised a "substitution test" using PS1 data on speculative applications; this is absent from the paper, removing an important mechanism check that would strengthen causal interpretation. The panel structure and use of PS2 householder applications as a placebo are retained as proposed.

### 2. Summary

This paper provides the first causal estimate of the "presumption in favour of sustainable development" in English planning law, using a sharp regression discontinuity design at the 75% Housing Delivery Test threshold. The authors find that falling below the threshold increases major dwelling approval rates by approximately 8–10 percentage points, though the effect is imprecisely estimated in the preferred nonparametric specification ($p = 0.16$). The result is specific to major residential applications (unaffected for householder permits) and robust to bandwidth choice, suggesting that shifting the burden of proof modestly increases development approvals.

### 3. Essential Points

**Critical Issue 1: Sign Confusion and Interpretation of Treatment Effects.**  
Table 2 reports negative point estimates (e.g., $-7.59$ for major dwellings) while the text and abstract interpret the effect as an *increase* of approximately 8 percentage points. This contradiction—whether arising from non-standard treatment coding ($D=1$ if $X > 75$), reversed subtraction order, or a coding error—must be resolved. The paper cannot report negative coefficients and describe positive effects without explicit clarification of the estimand (e.g., "estimate represents $E[Y|X=75^+] - E[Y|X=75^-]$"). Readers will misinterpret the direction of the causal effect.

**Critical Issue 2: Statistical Power and Specification Searching.**  
The nonparametric local linear estimate is statistically indistinguishable from zero ($p = 0.16$) with a 95% confidence interval spanning $-18.1$ to $+2.9$ percentage points. The paper's emphasis on the "real but modest effect" rests heavily on a parametric specification (significant at $p = 0.03$) whose functional form (polynomial order, bandwidth, controls) is not pre-registered or theoretically justified. With only $\approx$270 effective observations clustered at the LA level across just four periods, the study is underpowered. The authors must acknowledge that the evidence is consistent with a null effect or use methods to improve precision (covariate adjustment) rather than highlighting a noisy, marginally significant result from a selected specification.

**Critical Issue 3: Absence of Graphical Evidence and Manipulation Concerns.**  
An RDD paper is incomplete without a graphical depiction of the discontinuity (binned scatterplot with local linear fits). The absence of this figure prevents assessment of linearity, curvature, outliers, or heaping at the threshold. While the McCrary test reports $p = 0.46$, this test has low power given the small sample (only $\sim$20–30 LAs per year within the bandwidth). The running variable (delivery/requirement ratio) is highly manipulable through strategic timing of completions or local plan adjustments; the institutional argument against manipulation is insufficient. The paper must include the RD plot and seriously discuss the possibility of endogenous sorting.

### 4. Suggestions

**Graphical Presentation:**  
Add Figure 1 showing binned means (evenly spaced or RDplot with IMS-optimal bins) and local linear fits on either side of the 75% threshold for the main outcome. This is standard practice (e.g., Cattaneo, Idrobo & Titiunik, 2020) and essential for visual validation of the design.

**Improve Precision via Covariate Adjustment:**  
The paper mentions pre-period (2017–2019) approval rates as balance checks but does not use them for efficiency. Include pre-treatment outcomes as covariates in the local linear regression (Calonico et al., 2019, "Regression Discontinuity Designs Using Covariates"). This can reduce standard errors substantially given the panel structure.

**Donut Hole as Main Specification:**  
Given the manipulability of the HDT score and the low power of the McCrary test, estimate the main treatment effect excluding observations within $\pm$1 or $\pm$2 percentage points of the threshold (donut-hole RDD). Report this as the preferred specification rather than a robustness check to alleviate concerns about heaping or strategic behavior directly at the cutoff.

**Handle the 2020 COVID Outlier Appropriately:**  
The 2020 HDT round coincided with COVID-19 planning suspensions and shows a wrong-signed, implausibly large positive effect (Table 5). Rather than pooling this with other years and attributing it to "familiarity," exclude 2020 from the main sample and use it as a falsification test (placebo period), or include year-specific treatment effects to allow the 2020 effect to differ.

**Intensive Margin and Economic Significance:**  
Approval rates are a weak proxy for housing supply. Link approvals to dwelling counts (PS2 provides units for major applications) to estimate the effect on *units* approved, not just applications. The claim of "2–3 additional schemes per year per authority" may represent <50 units annually—economically trivial. Calculate confidence intervals around these unit projections to assess policy relevance.

**Placebo Using Early Rounds:**  
Use the 2018 and 2019 rounds (25% and 45% thresholds) as placebo tests. Although the thresholds differ, you can test for "effects" at the 75% cutoff in these pre-periods where the presumption did not yet apply at that threshold. This strengthens the validity argument by showing no discontinuity at 75% before the policy was active at that level.

**Clarify Standardized Effects:**  
Appendix Table 6 classifies a 0.20 SD effect as "Large positive." This contradicts standard Cohen's conventions (0.2 = small, 0.5 = medium). Correct the classification or remove it to avoid misleading readers about effect magnitudes.

**Clustering and Inference:**  
With only $T=4$ periods, clustering at the LA level yields few clusters for inference (potentially <50 effective clusters if many LAs are always above/below). Report wild cluster bootstrap p-values (Cameron, Gelbach & Miller, 2008) to ensure valid inference with a small number of clusters.
