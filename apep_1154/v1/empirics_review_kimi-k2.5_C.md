# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-30T16:42:25.884321

---

**Review of "The Implementation Gap: How Late Transposition of EU Directives Suppresses Firm Entry"**

---

### 1. Idea Fidelity

The paper substantially deviates from the original research design outlined in the manifest. The manifest proposed a granular panel of **1,109 directives × 27 member states × 1,250 NUTS3 regions × 11 NACE sectors**, exploiting staggered transposition timing with sector-directive specificity. The executed paper uses **114 directives × 20 countries × 3 broad NACE sectors (G, H, K)** at the national level (517 observations). This represents a massive aggregation—from regional variation to national aggregates, and from 11 sectors to 3. 

Crucially, the manifest promised placebo tests using "unrelated sectors" and moderation analysis by "regulatory complexity (articles, discretion scope)." The paper includes neither. The robustness table references a placebo test with no reported values (Table 3, row "Placebo: non-targeted sectors"), and the heterogeneity analysis is reduced to a simple regulated/non-regulated split rather than the proposed complexity measures. The shift from NUTS3 to national data is particularly damaging because the identification strategy relies on "within-directive variation" that is supposed to absorb directive-level confounds; with only 3 sectors and 20 countries, the effective number of independent treatment clusters is perilously small, and the "within-directive" comparison becomes confounded by sector-specific directive bundles.

---

### 2. Summary

This paper estimates the effect of EU directive transposition delays ("regulatory limbo") on firm entry using a two-way fixed effects (TWFE) model on a panel of 20 EU countries, 3 sectors, and 13 years. The author finds that having at least one directive in limbo reduces firm births by 21.5% (wild cluster bootstrap $p=0.029$), with larger effects in regulated sectors (Finance, Energy, Health, Transport). The contribution is positioned at the intersection of regulatory uncertainty and EU governance literatures, arguing that transposition delay creates a "lose-lose" dynamic where states postpone political costs but impose economic costs through entry suppression.

---

### 3. Essential Points

**1. The Callaway-Sant'Anna reversal is a fatal threat to identification.**  
You report that the Callaway-Sant'Anna (C-S) heterogeneity-robust estimator yields $\hat{\beta} = +0.331$ (significant and positive), while your TWFE estimate is $-0.215$. You dismiss this as "measurement error" from coarse sector mapping, but this is untenable. When the heterogeneity-robust staggered DiD estimator flips the sign, it indicates that your TWFE estimate is likely contaminated by negative weighting on treatment effects, heterogeneous treatment timing, or violated parallel trends. You cannot simply prefer the TWFE because it gives the "expected" sign. If measurement error in treatment timing biases C-S upward, it likely biases TWFE toward a spurious negative. Before this paper can be credible, you must reconcile these estimates—either by demonstrating that the C-S positive estimate is a pure artifact of specific data errors, or by admitting that the TWFE results are unreliable.

**2. The sample size and aggregation level leave no degrees of freedom for credible inference.**  
With 517 observations, 20 country clusters, and treatment defined as "any limbo" in a country-sector-year cell, you have approximately 25 observations per cluster. However, the effective number of independent treatment assignments is far smaller because directives apply to bundles of sectors. Your identification claim rests on "within-directive" variation, but with only 3 sectors, you cannot credibly claim to be comparing the same directive across sectors—you are comparing different directive portfolios across Finance, Transport, and Trade. Show an event study plot immediately. If you cannot demonstrate parallel pre-trends visually, the DiD design fails.

**3. The magnitude (21.5% decline) lacks credibility without mechanism validation.**  
A 21.5% decline in firm entry from temporary regulatory limbo is implausibly large—comparable to the entry effects of major financial crises or drastic regulatory bans, not administrative delays. Your baseline mean is 10.5 births per 100 active enterprises; your estimate implies limbo eliminates 2 percentage points, or roughly 19% of entry activity. This would suggest that uncertainty about *which* regulation applies is more costly than the regulations themselves. You must validate the mechanism: show that text-based policy uncertainty indices (Baker-Bloom-Davis style) or stock market volatility actually spike for affected sectors during limbo periods. Without this, the result suggests omitted variable bias (e.g., countries delay transposition during economic downturns that independently suppress entry).

---

### 4. Suggestions

**Address the staggered DiD critique head-on.**  
The discrepancy between TWFE and C-S estimators is not a minor robustness check—it is the central econometric issue. Implement the Sun-Abraham (2021) interaction-weighted estimator or de Chaisemartin-D'Haultfoeuille (2020) estimator. If these also yield positive or null effects, the paper's core claim is invalid. If they confirm the negative effect, explain why C-S failed (e.g., show that C-S requires a minimum number of treated units per cohort that your sparse data violate). Do not bury this in a footnote; it determines whether the paper is publishable.

**Show event studies and pre-trends.**  
With staggered treatment timing, you must plot the coefficients for leads and lags of treatment. Given your sample size, you may need to bin leads/lags or use a "stacked" event study design (Cengiz et al. 2019). If you cannot show a flat pre-trend for 2-3 years prior to limbo onset, the parallel trends assumption is violated, and your country-sector fixed effects do not solve the problem (countries may delay transposition in anticipation of sector-specific downturns).

**Clarify the directive-sector mapping rigorously.**  
You state you use "keyword classification of EUR-Lex titles" to map 114 directives to 3 NACE sectors. This is opaque and potentially arbitrary. Provide an appendix listing all 114 directives with their assigned sectors. Show balance tables: do late and early transposing countries differ in observable economic characteristics (GDP growth, sectoral composition) in the years preceding limbo? If so, your "within-directive" identification is compromised by country-specific trends.

**Fix the placebo test or remove it.**  
Table 3 lists "Placebo: non-targeted sectors" with no values. Either conduct the test (define sectors not subject to the directive as controls within the same country-year) and report the coefficients, or remove the claim. An empty cell suggests incomplete analysis.

**Redefine the treatment variable.**  
The binary "any limbo" indicator is crude. You have a continuous "limbo share" variable (mean 0.029, SD 0.132). Use this as your primary treatment. The binary indicator conflates countries with one directive in limbo versus twenty-two directives in limbo (your Table 1 shows a max of 22). If the effect is truly driven by uncertainty, it should scale with the *number* of conflicting regulatory signals (limbo share), not simply switch on/off. Report dose-response functions.

**Address selection into the sample of 114 directives.**  
You drop directives where fewer than 10 countries have verifiable records or where there is no timing variation. This selects directives with high administrative salience or complexity, potentially biasing the treatment effect upward (you observe limbo precisely where transposition is difficult and economic disruption is likely). Discuss this selection bias explicitly and bound the results using Lee (2009) bounds or similar.

**Validate the uncertainty mechanism.**  
The paper asserts that limbo creates "regulatory uncertainty," but provides no direct evidence. Use the European Central Bank's Survey on the Access to Finance of Enterprises (SAFE) or text analysis of earnings calls to show that firms in limbo-affected sectors report higher uncertainty. Alternatively, use the "regulatory intensity" measure you promised in the manifest (article counts, discretion scope) to show that the effect is larger when the directive involves more complex implementation choices.

**Cluster standard errors appropriately.**  
With 20 country clusters, you are at the boundary of credibility for cluster-robust inference. The wild cluster bootstrap is appropriate, but report the number of treated clusters explicitly. If fewer than 10 clusters experience treatment variation (some countries may never be in limbo for specific sectors), even the wild bootstrap may over-reject. Consider a randomization inference approach, permuting transposition dates across countries for the same directive.

**Reconsider the level of aggregation.**  
The manifest's NUTS3 design was ambitious but correct in spirit. If NUTS3 data is unavailable, consider NUTS2 or at least disaggregating to 2-digit NACE within your 3 broad sectors. With only 3 sectors, you cannot rule out that "Finance" is driven by one major financial directive (e.g., MiFID II) that coincided with the post-2008 regulatory overhaul, confounding your transposure timing with secular trends in financial entry.

**Expand the heterogeneity analysis.**  
You split by "regulated" vs. "non-regulated" sectors, but this is post-hoc and mechanical. Implement the originally proposed moderator: regulatory complexity measured by directive word count, number of articles, or discretion (optional vs. mandatory provisions). This would test the mechanism directly: complex directives should show larger limbo effects because uncertainty about implementation is higher.
