# Research Plan: The 25 Percent Line — Did the EU's Youth Employment Initiative Reduce NEETs?

## Research Question

Did the EU Youth Employment Initiative (2014-2020), which allocated EUR 8.8 billion exclusively to NUTS2 regions with youth unemployment above 25% in 2012, causally reduce NEET rates and improve youth employment outcomes?

## Identification Strategy

**Design:** Sharp regression discontinuity at the 25% youth unemployment threshold.

**Running variable:** 2012 NUTS2 youth unemployment rate (15-24 age group), centered at 25%.

**Treatment:** Eligibility for YEI funding (Council Regulation 1304/2013, Article 16). Regions with 2012 youth unemployment ≥25% received YEI allocations; regions below did not.

**Key assumption:** Potential outcomes are continuous at the 25% threshold. No precise manipulation of the running variable — the 2012 rates were realized before the YEI regulation was adopted.

## Exposure Alignment

The YEI targets young people aged 15-29 who are NEET. The funding flows through national Youth Guarantee implementation plans to NUTS2 regions above the threshold. The treatment is at the regional level (NUTS2), and the outcomes (NEET rates, youth employment) are measured at the same regional level. The threshold was set by EU legislation based on pre-existing Eurostat statistics, not by regional authorities. Regions could not manipulate their classification.

## Expected Effects

- NEET rate (18-24): Negative (YEI should reduce NEETs through training and employment programs)
- Youth employment rate (15-24): Positive (more jobs through subsidized employment, apprenticeships)
- Early school leaving: Smaller effect (education outcomes are slower-moving)

## Data Sources

1. **Eurostat yth_empl_110**: Youth unemployment rate by NUTS2, 1999-2024 (running variable from 2012)
2. **Eurostat edat_lfse_22**: NEET rate by NUTS2, ages 18-24 (primary outcome)
3. **Eurostat lfst_r_lfe2emprt**: Employment rate by NUTS2, ages 15-24 (secondary outcome)

All accessed via the `eurostat` R package (keyless).

## Analysis Plan

1. Fetch Eurostat data via `eurostat` R package
2. Construct running variable (2012 youth unemployment - 25)
3. Compute outcome changes: post-YEI (2016-2019 avg) minus pre-YEI (2010-2012 avg)
4. Run rdrobust with MSE-optimal bandwidth
5. Robustness: bandwidth sensitivity, McCrary density, placebo cutoffs (20%, 30%), donut RDD
6. Heterogeneity: Southern vs non-Southern Europe
