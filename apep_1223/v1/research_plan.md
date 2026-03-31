# Research Plan: apep_1223

## Research Question
How do tiered cigarette tax structures affect product substitution in developing countries? Specifically, do differential tax increases across cigarette price tiers in Bangladesh induce downward switching to cheaper cigarettes — undermining the health objectives of tobacco taxation?

## Background
Bangladesh applies supplementary duty to cigarettes across four price tiers (low, medium, high, premium). Between FY2006–07 and FY2014–15, tax rate increases differed by tier: +11pp for low-price, +8pp for medium, +6pp for high, +4pp for premium. This regressive gradient created widening relative price gaps between tiers, potentially inducing downward substitution.

## Identification Strategy
**Repeated cross-section DiD** exploiting differential tax treatment across product categories:
1. **Between-tier variation:** Different cigarette tiers received different cumulative tax increases (4–11pp). Tiers with larger increases should lose market share to adjacent lower tiers.
2. **Between-product variation:** Cigarettes vs bidis/smokeless tobacco received different tax treatment — bidis had minimal tax changes, serving as a control product category.
3. **Synthetic cohort analysis:** Within education×age×division cells across the two GATS waves to track compositional changes net of demographics.

**Key estimand:** Change in tier-specific market share (and daily consumption) between 2009 and 2017, as a function of the cumulative tier-specific tax increase.

## Expected Effects and Mechanisms
- **Primary:** Downward substitution — smokers in higher-taxed tiers switch to lower-taxed tiers rather than quitting
- **Secondary:** Intensity reduction (fewer cigarettes per day) within tier
- **Tertiary:** Cross-product substitution to bidis (untaxed/low-taxed)
- **Null hypothesis:** Tax increases are proportional to prices, so no relative incentive to switch tiers

## Primary Specification
Multinomial logit / conditional logit for product choice, with tier-specific tax increase as key regressor. Linear probability models for binary tier indicators as robustness.

DiD specification:
Y_ij = α + β(TaxIncrease_j × Post_t) + γ_j + δ_t + X_i'θ + ε_ij

where j indexes product tier, t indexes survey wave, i indexes individuals, and TaxIncrease_j is the cumulative pp increase for tier j.

## Data Source and Fetch Strategy
1. **GATS Bangladesh 2009 and 2017:** WHO NCD Microdata Repository (catalog IDs 259 and 870). Individual-level tobacco use, product type, consumption quantity, demographics. ~10,000 respondents per wave.
2. **Tax rate schedules:** Published in NBR budget documents; key rates tabulated in Nargis et al. (2019, 2024) and Shang et al. (2024). Will code directly from published schedules.
3. **Aggregate validation:** WHO GHO API for country-level smoking prevalence trends.

**Fallback if GATS microdata requires approval:** Use published cross-tabulations from GATS fact sheets (2009, 2017) + GHO aggregate data + tier-specific production volumes from published papers. This would reduce the individual-level advantage but still allow tier-level DiD.

## Key Risks
- GATS microdata may require WHO registration/approval (cannot be automated)
- Only 2 time periods — no event study diagnostics possible
- Tiered tax changes occurred gradually (2006–2015); timing is diffuse
- Potential confounding: income growth, urbanization between waves
