# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-15T17:08:04.080927

---

 **Review of "When Bans Replace Taxes: The Domestic Substitution Response to New Zealand's Foreign Buyer Prohibition"**

### 1. Idea Fidelity

The paper deviates substantially from the original research design. The manifest proposed a three-pronged identification strategy: (1) synthetic control at the national level against 15+ OECD countries with 54 pre-treatment quarters; (2) cross-regional DiD across 67 territorial authorities (TAs); and (3) internal replication using the 2025 partial reversal. 

The delivered paper abandons the first strategy almost entirely, relegating the synthetic control to a brief "supplementary" mention with no formal inference, placebo tests, or confidence intervals—despite the manifest's promise of permutation-based inference. It also reduces the regional analysis from 67 TAs to 37 aggregated geographic areas (combining regions, Auckland local boards, and selected TAs), discarding nearly half the promised spatial variation. Most critically, the quarterly DiD ends in 2020Q1 (11 quarters), truncating just as the 2025 reversal data should become available for the promised "built-in replication." The manifest explicitly committed to the 2025 reversal as Strategy 3; the paper dismisses it due to "insufficient data" despite being dated 2026. These omissions severely weaken the paper's credibility and represent a failure to deliver the pre-registered research design.

---

### 2. Summary

This paper examines New Zealand's 2018 ban on foreign residential property purchases using a continuous-treatment difference-in-differences design across 37 geographic areas. The author finds that the ban reduced foreign buyer shares by approximately 0.5 percentage points per unit of pre-ban exposure (a 79% national decline), but finds no evidence of price declines using a synthetic control comparison dominated entirely by Australia. The central claim is that domestic buyers substituted for exiting foreign demand, rendering quantity restrictions ineffective for housing affordability.

---

### 3. Essential Points

**Pre-trend violation and selective sample truncation.** The event study (Table 4) reports significantly positive coefficients at $t=-2$ and $t=-1$ (0.636 and 0.656), indicating that high-exposure areas were experiencing *increasing* foreign buyer shares immediately prior to the ban—a direct violation of the parallel trends assumption. The paper incorrectly interprets these positive pre-period coefficients as "mechanical" level differences rather than trend violations. Compounding this, the decision to truncate the quarterly panel at 2020Q1 discards four years of post-treatment data explicitly promised in the manifest (including data through 2024), leaving the analysis vulnerable to COVID-19 contamination and eliminating the ability to study medium-run price effects.

**Unreliable inference with few clusters.** The main DiD coefficient (-0.500) carries a clustered standard error of 0.016 (t-stat $\approx$ 31) with only 37 area clusters. With such few clusters and a continuous treatment, conventional cluster-robust SEs are severely downward-biased (Cameron & Miller, 2015). The paper reports p-values $<$ 0.001 throughout, but these likely overstate precision by an order of magnitude. Without wild cluster bootstrap, randomization inference, or at minimum heteroskedasticity-robust wild bootstrap, the strong claims of significance are unsubstantiated.

**Degenerate synthetic control and absent price analysis.** The national-level price analysis—promised as Strategy 1—relies on a synthetic control where Australia receives 99.9% weight, effectively reducing to a simple two-country comparison. The paper reports a 12 index point "rise" relative to this counterfactual but provides no inference (RMSPE ratios, placebo tests, or confidence intervals), rendering the price null result uninterpretable. Given the manifest's emphasis on the synthetic control as the primary national-level identification, this perfunctory treatment undermines the paper's central conclusion that the ban had no price effects.

---

### 4. Suggestions

**Address the pre-trend violation directly.** The significantly positive leads in the event study (Table 4, $t=-2$ and $t=-1$) are not "mechanical"—they indicate divergent trends. If high-foreign-share areas were experiencing rising foreign purchase intensity just before Q3 2018 (perhaps due to anticipation effects or differential seasonality), the DiD estimator is biased. You should: (1) test for linear pre-trends explicitly by regressing the outcome on exposure interacted with a time trend for the pre-period; (2) consider an "interaction-weighted" estimator (Sun & Abraham, 2021) or imputation-based estimators (Borusyak et al., 2024) that are robust to heterogeneous treatment effects and pre-trends; and (3) if anticipation is suspected (buyers rushing to close before October 2018), model the treatment as beginning in Q2 2018 or use a dynamic event study that allows for anticipation effects at $t=-1$.

**Fix the inference or admit imprecision.** With 37 clusters, you must move beyond conventional cluster-robust SEs. Implement wild cluster bootstrap-t (Cameron & Miller, 2015) or randomization inference ( permutation tests) for the DiD coefficient. Given the continuous treatment, consider collapsing to a binary comparison (above/below median exposure) for the primary specification, which is more credible with few clusters, while reporting the continuous specification as a
