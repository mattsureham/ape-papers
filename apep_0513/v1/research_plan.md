# Initial Research Plan: apep_0513

## Research Question

Does lowering the default urban speed limit from 30mph to 20mph reduce road casualties? What is the welfare trade-off between safety gains and time costs, as revealed by residential property price capitalization?

## Policy Background

On September 17, 2023, Wales became the first UK nation to lower the default speed limit on restricted roads (residential streets with streetlights) from 30mph to 20mph. England retained the 30mph default. The policy generated historic public opposition (469,571 petition signatures). Starting in 2024, partial reversals occurred as individual roads were reclassified back to 30mph.

## Identification Strategy

### Primary Design: Difference-in-Differences

- **Treatment group:** 22 Welsh Local Authorities, post-September 17, 2023
- **Control group:** English Local Authorities (all, or restricted to border LAs for robustness)
- **Unit of analysis:** Police Force Area × month (for casualties); LA × quarter (for property prices)
- **Pre-treatment period:** January 2019 – August 2023 (56 months)
- **Post-treatment period:** September 2023 – December 2024 (16 months)
- **Estimator:** Two-way fixed effects (standard 2×2 DiD — single treatment date)
- **Fixed effects:** LA + year-month; region-specific linear trends for robustness
- **Standard errors:** Clustered at police force area (4 Welsh forces, 39 English forces) — wild cluster bootstrap given small number of Welsh clusters

### Secondary Design: Spatial RDD at the Wales-England Border

- Restrict sample to LAs within 50km of the border
- Compare Welsh-side vs English-side casualty trends
- Running variable: distance from LA centroid to border (positive = Wales, negative = England)

### Built-in Placebo Tests

1. **Road-type placebo:** Casualties on A-roads and motorways (40-70mph, exempt from 20mph default) should show NO treatment effect. This rules out any Wales-wide confounders affecting all road types.
2. **Scottish placebo:** Scotland (no policy change) vs England — should show no differential change.
3. **Pre-2023 placebo:** Artificially assign treatment to September 2022 and test for effects — should be null.

### Mechanism Decomposition

1. **Severity composition:** Do fatal/serious casualties fall more than slight?
2. **Road user type:** Pedestrians and cyclists (most vulnerable to speed) vs car occupants
3. **Time of day:** School-run hours (8-9am, 3-4pm) vs nighttime
4. **Urban vs rural:** Restricted roads are primarily urban — check heterogeneity
5. **Property value channel:** Do properties on affected roads capitalize safety gains?

## Expected Effects

- **Casualties:** Negative (reduction). Physics: kinetic energy scales with v². Reducing from 30→20mph cuts kinetic energy by 56%. Pedestrian fatality risk at 20mph is ~5% vs ~45% at 30mph (Rosén & Sander 2009). Expect larger effects for fatal/serious than slight casualties.
- **Property values:** Ambiguous. Quieter, safer streets → positive. Longer travel times → negative. Net effect is empirical.

## Primary Specification

For casualty analysis (LA-month panel):

$$Y_{lt} = \alpha + \beta \cdot \text{Welsh}_l \times \text{Post}_t + \gamma_l + \delta_t + \epsilon_{lt}$$

Where:
- $Y_{lt}$ = log(casualties + 1) or casualties per 100,000 population in LA $l$, month $t$
- $\text{Welsh}_l$ = indicator for Welsh LA
- $\text{Post}_t$ = indicator for $t \geq$ September 2023
- $\gamma_l$ = LA fixed effects
- $\delta_t$ = year-month fixed effects

For property value analysis (transaction-level hedonic):

$$\ln(P_{ilt}) = \alpha + \beta \cdot \text{Welsh}_l \times \text{Post}_t + X_{i}'\gamma + \gamma_l + \delta_t + \epsilon_{ilt}$$

Where $X_i$ includes property type, new/old build, freehold/leasehold.

## Planned Robustness Checks

1. **Wild cluster bootstrap** — 4 Welsh police forces is few clusters; use Cameron-Gelbach-Miller (2008) bootstrap
2. **Randomization inference** — permute treatment assignment across LAs
3. **Event study plot** — coefficients for each month relative to September 2023
4. **Varying control groups:** All English LAs; border-only; English + Scottish LAs
5. **Excluding COVID period** (2020-2021) to avoid compositional effects
6. **Donut RDD** at the border (excluding LAs directly on the border)
7. **Alternative outcomes:** Collision count (not just casualties), vehicles involved
8. **Speed limit composition check:** Verify that the share of 20mph vs 30mph roads changed in Wales but not England

## Power Assessment

- Pre-treatment periods: 56 months (Jan 2019 – Aug 2023)
- Treated clusters: 4 Welsh police forces (22 Welsh LAs)
- Post-treatment periods: 16 months
- Welsh monthly collision count: ~275/month
- English monthly collision count: ~5,600/month
- Expected effect: ~20-30% reduction (based on descriptive monitoring)
- MDE: With 56 pre-periods and 16 post-periods, the panel is long enough to detect effects of ~10% or larger with conventional power

## Data Sources

| Source | Granularity | Coverage | Access |
|--------|------------|----------|--------|
| STATS19 (via `stats19` R package) | Individual collision, daily | GB, 1979-2024 | Free download |
| HM Land Registry PPD | Individual transaction, postcode | England & Wales, 1995-2024 | Free CSV |
| ONS Mid-Year Population Estimates | LA × year | UK | ONS API |
| ONS NSPL | Postcode → LSOA/LA lookup | UK | Free download |

## DiD Exposure Alignment

- **Who is actually treated?** All road users on restricted roads (residential streets) in Wales
- **Primary estimand population:** Road users in Welsh LAs on 20/30mph roads
- **Placebo/control population:** Road users in England; road users on 40+mph roads in Wales
- **Design:** Standard DiD (single treatment date, two groups)
