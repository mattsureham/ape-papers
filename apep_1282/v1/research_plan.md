# Research Plan: The Double Squeeze

## Research Question

Did Italy's sequential labor supply shocks — the Fornero pension reform (2012) and the Reddito di Cittadinanza (2019) — produce non-additive effects on youth employment and NEET rates? Specifically, did regions with high Fornero "bite" (extending older workers' careers) AND high RdC take-up (paying working-age adults not to work) experience worse youth outcomes than either shock alone would predict?

## Identification Strategy

**Generalized triple-difference** exploiting two independent continuous treatment dimensions with nearly orthogonal geographic distributions:

1. **Fornero bite** (high in Center-North, low in South): Change in 55-64 employment rate 2010-2014 by NUTS2 region. Ranges from +1.4pp (Sicilia) to +15.4pp (Umbria).

2. **RdC take-up** (high in South, low in Center-North): Provincial RdC recipient share of working-age population, 2019. Ranges from <1% (Trentino-Alto Adige) to ~22% (Campania).

**Phase 1 (2012-2018):** Continuous DiD on Fornero bite alone. `Y_rt = α_r + γ_t + β₁(FornBite_r × Post2012_t) + ε_rt`

**Phase 2 (2019-2023):** Interaction term. `Y_rt = α_r + γ_t + β₁(FornBite_r × Post2012_t) + β₂(RdC_r × Post2019_t) + β₃(FornBite_r × RdC_r × Post2019_t) + ε_rt`

The coefficient **β₃** captures the non-additive "double squeeze" — whether the combination of delayed retirement + income support compounds youth disengagement beyond what either policy predicts individually.

**Phase 3 (2023+):** RdC abolition as asymmetric reversal. If the double squeeze is real, regions with high Fornero bite should recover less from RdC abolition (because the retirement channel persists).

## Expected Effects and Mechanisms

- **Main effect (β₃ > 0 on NEET):** Regions with both high Fornero bite AND high RdC take-up see elevated youth NEET rates beyond additive prediction. Mechanism: older workers block entry-level positions (crowding) while income transfers reduce job search intensity (reservation wage).
- **Heterogeneity:** Stronger for males (more affected by construction/manufacturing crowding) and for 15-24 age group (closer to entry-level competition with older workers).
- **Null is informative:** If β₃ ≈ 0, the policies operate through independent channels — pension reform doesn't interact with income support. This would challenge the "policy interaction" narrative common in European welfare state reform discussions.

## Primary Specification

```
NEET_rt = α_r + γ_t + β₁(FornBite_r × Post2012_t) + β₂(RdC_r × Post2019_t) 
        + β₃(FornBite_r × RdC_r × Post2019_t) + X_rt'δ + ε_rt
```

- Unit: NUTS2 region r, year t
- Outcome: NEET rate 18-24, youth employment rate 15-24
- Clustering: NUTS2 region (21 clusters → wild cluster bootstrap)
- Controls: region and year FE; potentially GDP per capita growth, population age shares

## Data Sources

1. **Eurostat REST API** (confirmed 100% coverage):
   - `lfst_r_lfe2emprt`: Employment rate by age group, NUTS2, 2005-2023
   - `edat_lfse_22`: NEET rate 18-24, NUTS2, 2005-2023 (97.2% coverage)
   - Employment rate 55-64 for constructing Fornero bite

2. **INPS RdC data** (confirmed downloadable):
   - Monthly XLSX files from inps.it with regional/provincial recipient counts
   - 53 files, ~130KB each, 2019-2023

## Robustness

- Wild cluster bootstrap (21 clusters is borderline — WCB essential)
- Permutation inference on β₃
- Placebo: employment rate 45-54 (should not respond to either shock in the same way)
- Leave-one-region-out sensitivity
- Alternative Fornero bite measures (change in 55-64 employment 2010-2016 instead of 2010-2014)
