# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-30T12:06:58.124604

---

 **Referee Report: "The Waste Wall: China's National Sword and the Collapse of US Recycling Employment"**

---

### 1. Idea Fidelity

The paper pursues the core research question outlined in the original manifest—estimating US county-level employment effects of China’s National Sword policy using QWI data—but deviates from the proposed design in three ways that materially weaken the empirical strategy. First, the manifest proposed a **continuous treatment** design (county-level waste industry share interacted with a national waste export shock), yet the paper implements a **binary median-split** DiD (above/below median waste share). This discards valuable variation and reduces power. Second, the manifest emphasized leveraging the **staggered product bans** (plastics in 2018, paper/metals through 2020) as multiple treatment events to strengthen identification; the paper treats National Sword as a single 2018Q1 shock, ignoring this temporal heterogeneity. Third, the manifest highlighted the QWI’s **race/ethnicity breakdowns** as a key data asset, but the paper aggregates across demographics, missing an important dimension of distributional analysis promised in the original design. The paper does correctly utilize the county×NAICS×quarter structure of the QWI and maintains the focus on NAICS 562 (Waste Management), but the simplification of the treatment variable represents a step backward from the more credible Bartik-style approach originally envisioned.

---

### 2. Summary

This paper provides the first causal estimates of how China’s 2018 National Sword policy—a unilateral ban on recyclable waste imports—propagated through US local labor markets. Using a county-level difference-in-differences design comparing high- versus low-waste-exposure counties before and after January 2018, the author finds that high-exposure counties experienced a 14.2% relative decline in waste management employment (NAICS 562), driven by reduced hiring and firm entry. The results contribute to the literature on trade shocks by documenting a "reverse pollution haven" effect: a developing country’s import standards change can generate significant employment losses in the developed world’s export-dependent environmental sectors.

---

### 3. Essential Points

**I. Violation of Parallel Trends.** The event study (Table 4) reveals significant positive pre-trends: high-exposure counties exhibit 3–6% higher employment growth in the eight quarters preceding National Sword (coefficients 0.0285 to 0.0581, many significant at the 1% level). This indicates that treated counties were on a differential growth trajectory *before* the shock, violating the key DiD identifying assumption. The authors’ interpretation—that this represents a "recycling growth premium" destroyed by the shock—is insufficient; the pre-trend violation implies that absent the ban, high-exposure counties might have continued diverging from low-exposure counties for reasons unrelated to trade policy (e.g., differential trends in environmental regulation, municipal waste contracting, or land costs). **This threat requires immediate address via synthetic DiD, interactive fixed effects, or a re-weighted control group.**

**II. Spatial Spillovers and General Equilibrium.** The paper assumes counties are independent units, but waste is geographically mobile. If National Sword caused high-exposure counties to divert waste flows to landfills or processing facilities in low-exposure counties (or neighboring states), the control group is contaminated by general equilibrium effects. The manifest noted that waste was diverted to Malaysia, but domestic reallocation within the US is equally concerning. **The authors must test for spatial spillovers** using neighbor-pair fixed effects, distance-to-treatment controls, or a spatial DiD framework (e.g., Clarke 2017). Without this, the 14.2% estimate may overstate or understate the true effect depending on the direction of reallocation.

**III. Measurement and Temporal Heterogeneity.** The shift from the manifest’s continuous Bartik-style treatment (interacting county shares with national export volumes by waste type) to a binary post×high-exposure dummy discards information and precludes dose-response analysis. Furthermore, National Sword was staggered—plastics faced immediate bans while paper and metals faced tightening restrictions through 2020. **The paper should exploit this staggered timing** to test for heterogeneous effects by waste type and to implement a more credible event-study design that uses the variation in "treatment intensity" over time rather than a single post dummy.

---

### 4. Suggestions

**Treatment Definition and Empirical Strategy**

1. **Implement the Continuous Bartik Treatment.** Return to the manifest’s original design: define treatment intensity as $Exposure_c \times Shock_t$, where $Exposure_c$ is the pre-period waste employment share and $Shock_t$ is the national change in waste exports to China (disaggregated by HS codes 3915, 4707, 7204). This creates a continuous, dose-response measure that (a) uses all variation, (b) allows for staggered timing by commodity, and (c) provides a more credible identifying assumption than the binary split. You can then use the "shock" as an instrument for local employment or estimate a standard imputation estimator (e.g., Borusyak, Jaravel, Spiess 2024).

2. **Address Pre-Trends with Synthetic DiD.** Given the clear pre-trend violation in Table 4, estimate Synthetic DiD (Arkhangelsky et al., 2021) or Matrix Completion with Nuclear Norm Regularization (Athey et al., 2021). These methods are designed precisely for settings with diverging pre-trends and will provide a more credible counterfactual than the standard two-way fixed effects model. If the results survive this robustness check, the paper’s credibility is substantially strengthened; if they do not, the current design is untenable.

3. **Exploit Staggered Bans by Commodity.** National Sword did not hit all materials simultaneously. Use Comtrade data to construct separate shock measures for plastics (banned effectively 2018Q1), paper (tightened through 2018–2020), and metals. This allows for a staggered DiD design that tests whether employment effects track the timing of specific commodity bans—a powerful falsification test that the current "big bang" 2018Q1 dummy cannot provide.

**Data and Measurement**

4. **Leverage Race/Ethnicity Heterogeneity.** The QWI data contain race/ethnicity breakdowns (the manifest emphasized this). Estimate heterogeneous effects by demographic group to determine whether minority workers bore disproportionate adjustment costs. This is a high-value addition for *AER: Insights* given the policy relevance of environmental justice in waste siting and recycling labor markets.

5. **Disaggregate NAICS 562.**
