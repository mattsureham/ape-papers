# Research Plan: Flood, Flight, and Fortune

## Research Question

Did flood-induced displacement during the 1927 Great Mississippi Flood improve or worsen the long-run occupational trajectories of Black farm workers? Using individual-level linked census data (MLP 1920-1930-1940), this paper estimates the causal effect of forced migration on occupational upgrading — the first individual-level study of this landmark natural disaster.

## Identification Strategy

**Instrument:** County-level proportion of land inundated during the 1927 flood (from Hornbeck & Naidu, AER 2014, replication archive). Continuous measure varying across Delta counties in Mississippi, Arkansas, and Louisiana.

**First stage:** Flood intensity → probability of out-migration between 1920 and 1930 for Black farm workers, controlling for pre-flood individual characteristics (age, sei_1920, occscore_1920) and county fixed effects.

**Second stage (LATE):** Instrumented migration → change in occupational earnings score (occscore) and socioeconomic index (sei) by 1930 and 1940.

**Identifying assumption:** Within the Mississippi Delta, variation in flood inundation intensity across counties is uncorrelated with pre-1927 individual-level economic trajectories, conditional on county and age fixed effects. Testable via pre-flood balance.

**Estimand:** Local Average Treatment Effect (LATE) — the causal effect of migration for compliers, i.e., Black farm workers who moved because of flood severity but would not have moved absent the flood.

## Expected Effects and Mechanisms

**Primary hypothesis:** Flood-induced migration broke the sharecropping trap, producing positive long-run occupational upgrading for compliers. Mechanism: forced relocation to northern/urban labor markets with higher returns to labor.

**Alternative hypothesis:** Displacement was welfare-destroying — loss of land, social networks, and local knowledge without compensating gains.

**Heterogeneity:**
- Age at displacement (younger workers may adapt better)
- Pre-flood occupational status (higher-status workers may have more transferable skills)
- Destination (North vs. within-South movers)

## Primary Specification

**Reduced form (ITT):**
Y_i = α + β · FloodIntensity_c + X_i'γ + δ_age + ε_i

**First stage:**
Migrate_i = π₀ + π₁ · FloodIntensity_c + X_i'λ + δ_age + ν_i

**Second stage (2SLS):**
Y_i = α + β_IV · Migrate_i(hat) + X_i'γ + δ_age + ε_i

Where:
- Y_i = occscore or sei in 1930 or 1940
- FloodIntensity_c = proportion of county c inundated in 1927
- Migrate_i = indicator for moving county between 1920-1930
- X_i = pre-flood controls (occscore_1920, sei_1920, farm_1920, age_1920)
- δ_age = age fixed effects
- Standard errors clustered at county level

## Data Sources

1. **MLP 1920-1930-1940 linked panel** — Azure: `az://derived/mlp_panel/linked_1920_1930_1940.parquet` (4.9GB, 34.7M rows). Individual-level linked census records with occupational scores, migration indicators, demographics.

2. **Hornbeck & Naidu (AER 2014) flood inundation data** — AER replication archive. County-level proportion of land inundated during the 1927 flood for MS, AR, LA counties.

## Fetch Strategy

1. Query MLP panel from Azure via DuckDB (filter to Black farm workers in MS/AR/LA Delta counties, 1920 baseline)
2. Download Hornbeck & Naidu replication data from AER website or reconstruct county-level flood intensity from their published tables
3. Merge at county level (statefip × countyicp)

## Robustness Checks

1. **Balance test:** Pre-flood characteristics (occscore_1920, sei_1920, age) should be uncorrelated with flood intensity conditional on county FE
2. **Falsification:** Same IV applied to white farm workers (expect null or different pattern)
3. **Reduced form:** Direct effect of flood intensity on outcomes (ITT, no first-stage required)
4. **LIML/Fuller:** Weak-IV-robust estimator as alternative to 2SLS
5. **Leave-one-county-out:** Verify no single county drives results
