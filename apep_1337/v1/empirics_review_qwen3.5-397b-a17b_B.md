# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-04-03T00:58:13.599903

---

# Referee Report

## 1. Idea Fidelity

The paper deviates significantly from the Original Idea Manifest in terms of data resolution and identification power. The Manifest explicitly proposed using **county-level** data with **4-digit NAICS** industry codes (claiming 143.9 million rows), which would allow for rich within-state variation across specific manufacturing subsectors (e.g., distinguishing electronics from textiles). The submitted paper, however, relies on **state-level** data aggregated to **2-digit NAICS** sectors (75,150 cells). The authors state in the "Threats to Validity" section that the QWI Race-Hispanic panel is "available only at the 2-digit NAICS level," which contradicts standard LEHD documentation and the Manifest's own feasibility check. This aggregation drastically reduces the variation in tariff exposure, effectively collapsing the treatment into a broad Manufacturing vs. Services comparison rather than the proposed high-exposure vs. low-exposure industry design. Additionally, while the Manifest hypothesized that protection might *compress* the wage gap (by lifting lower-wage workers in protected sectors), the paper finds the gap *widened*. While empirical results need not match hypotheses, this reversal requires a more robust mechanistic explanation than currently provided.

## 2. Summary

This paper investigates the distributional consequences of the 2018 Section 301 tariffs on Chinese imports, specifically focusing on the understudied Asian-White wage gap in U.S. manufacturing. Using a triple-difference design on Quarterly Workforce Indicators (QWI) data, the authors find that tariffs widened the earnings gap by approximately 0.15 to 0.30 log points, driven by the overrepresentation of Asian workers in heavily protected electronics and machinery sectors. The study contributes to trade and labor economics by highlighting a "composition windfall" mechanism, where sector-specific trade policy inadvertently redistributes income across racial groups based on pre-existing industrial sorting.

## 3. Essential Points

The authors must address the following three critical issues to support their causal claims:

1.  **Data Granularity and Identification Power:** The downgrade from 4-digit to 2-digit NAICS sectors severely compromises the identification strategy. With only ~19 sectors, the "continuous tariff exposure" variable lacks sufficient variation within manufacturing. If most manufacturing sectors (NAICS 31-33) receive similar exposure scores (as implied by the 0.18 average), the design effectively compares Manufacturing vs. Non-Manufacturing. This conflates tariff effects with any other shock differentially affecting manufacturing during this period (e.g., automation, supply chain trends). The authors must either recover the 4-digit data as originally proposed or explicitly acknowledge that the coefficient captures a broad manufacturing premium rather than tariff-specific variation.
2.  **Failed Parallel Trends:** The event study reveals significant pre-trends, with a rejected Wald test ($p < 0.001$) and significant coefficients at $t=-8$ and $t=-2$. While the authors attribute the $t=-2$ spike to anticipation, the $t=-8$ deviation suggests underlying divergent trends between high-exposure and low-exposure sectors unrelated to the tariffs. This undermines the causal interpretation of the post-2018 coefficients. The authors need to demonstrate that controlling for sector-specific linear trends or using a synthetic control approach resolves these pre-existing divergences.
3.  **COVID-19 Confounding:** The results indicate that the effect size doubles when COVID-era data (2020-2022) is included. Given that the pandemic disproportionately affected Asian communities (due to discrimination, immigration restrictions, and specific supply chain disruptions in electronics), this period introduces severe confounding. The pre-COVID estimate (0.149) is half the size of the full sample estimate. The authors should prioritize the pre-COVID specification as their primary result and treat the full-sample estimate as highly contaminated, rather than presenting them as equally valid robustness checks.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's empirical rigor and clarity. While not strictly essential for publication, addressing them would significantly elevate the contribution from a suggestive correlation to a more credible causal insight.

**Recover 4-Digit Industry Variation**
The most critical improvement would be to revert to the data structure outlined in the Manifest. The LEHD QWI infrastructure typically supports 4-digit NAICS codes at the state level (and often county level). The claim that data is limited to 2-digit sectors appears to be a processing constraint rather than a data availability constraint.
*   **Action:** Re-extract the QWI data using 4-digit NAICS codes. This would increase the number of industry cells from ~19 to ~400+, providing the necessary variation to distinguish between high-tariff industries (e.g., NAICS 334 Computer/Electronic Products) and low-tariff manufacturing (e.g., NAICS 311 Food Manufacturing).
*   **Benefit:** This would allow for a cleaner "within-manufacturing" comparison, isolating the tariff effect from broader manufacturing shocks. It would also increase the sample size and statistical power, potentially tightening the standard errors around the event study estimates.
*   **Implementation:** If county-level data is too sparse for some race-industry cells, state-level 4-digit data is a viable middle ground that still honors the original identification strategy.

**Refine the Event Study and Pre-Trend Controls**
The current event study shows non-parallel pre-trends, which is a major threat to validity. Simply noting this limitation is insufficient for a causal paper.
*   **Action:** Include industry-specific linear time trends in the main specification. This allows each industry to have its own trajectory, isolating the *change* in trajectory post-tariff.
*   **Action:** Consider a "donut" event study that excludes the $t=-8$ outlier to see if the pre-trend significance holds. If the trend is flat from $t=-5$ to $t=-1$, emphasize this window as the relevant pre-period.
*   **Action:** Implement a synthetic control method at the industry level. Construct a weighted combination of low-exposure industries that matches the pre-trend trajectory of high-exposure industries. This provides a visual and statistical counterfactual that is often more convincing than fixed effects alone when parallel trends are shaky.

**Disentangle Tariff Effects from Pandemic Shocks**
The amplification of the effect during the COVID period is intriguing but dangerous. The paper currently attributes this to "amplification of pre-existing racial disparities," but it could equally be driven by pandemic-specific factors.
*   **Action:** Make the 2014-2019 (pre-COVID) specification the **primary** result in the main text. Move the full-sample (2014-2022) results to an appendix or clearly label them as "contaminated."
*   **Action:** Add a control for industry-level teleworkability or supply chain disruption indices during the 2020-2022 period. This would help isolate whether the widening gap was due to tariffs or due to the fact that electronics (high Asian employment) remained operational while other sectors shut down.
*   **Action:** Discuss the "China Virus" stigma effect. Literature suggests Asian workers faced heightened discrimination during the pandemic. If high-exposure industries are also high-visibility industries,
