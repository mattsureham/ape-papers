# Research Plan: Cannabis Legalization and Agricultural Formalization in Morocco's Rif Mountains

## Research Question

Did Morocco's Law 13-21 (2021) — which legalized cannabis cultivation in three designated provinces (Al Hoceima, Chefchaouen, Taounate) while keeping adjacent provinces ineligible — cause measurable changes in agricultural land use and economic activity, as captured by satellite-derived vegetation indices and nighttime luminosity?

## Identification Strategy

### Primary Design: Province-Border Difference-in-Differences

- **Treatment:** Communes in the three eligible provinces (Al Hoceima, Chefchaouen, Taounate)
- **Control:** Communes in adjacent ineligible provinces (Taza, Tétouan, Ouazzane, Larache)
- **Timing:** Decree 2-22-159 effective March 2022; permit rollout staggered 2022–2024
- **Estimator:** Callaway-Sant'Anna (2021) for staggered treatment; standard TWFE as robustness
- **Clustering:** Province level (7 clusters → wild cluster bootstrap)

### Supplementary Design: Spatial RDD

- Communes within 20km of the eligible/ineligible provincial boundary
- Running variable: distance to nearest eligible boundary point
- Tests whether the treatment effect is concentrated at the boundary (ruling out smooth regional trends)

## Expected Effects and Mechanisms

1. **NDVI (vegetation):** Ambiguous sign. Cannabis has a distinct growing cycle (August–September harvest peak vs. May–June cereal peak). Legalization may shift land from cereals to cannabis → change in seasonal NDVI profile. Could increase peak-season NDVI if legal cultivation is more intensive.

2. **Nightlights (economic activity):** Expected positive. Formalization brings investment, processing facilities, infrastructure. The 2,837 farmer authorizations and industrial permits channel capital into eligible communes.

3. **The legalization discount paradox:** Legal cannabis prices are ~1/50th of illicit prices. If farmers formalize despite massive price penalties, the mechanism must be non-pecuniary: reduced imprisonment risk, access to formal credit, land tenure security. This is the portable insight.

## Primary Specification

```
Y_{ct} = α_c + γ_t + β(Eligible_c × Post_t) + X_{ct}δ + ε_{ct}
```

Where:
- Y_{ct}: commune-level NDVI (annual peak) or nightlight radiance (annual composite)
- α_c: commune fixed effects
- γ_t: year fixed effects
- Eligible_c: indicator for communes in Al Hoceima, Chefchaouen, or Taounate
- Post_t: indicator for years ≥ 2022
- X_{ct}: optional controls (elevation, distance to coast, population density)

## Data Sources

| Dataset | Source | Unit | Years | Access |
|---------|--------|------|-------|--------|
| Sentinel-2 NDVI | Copernicus Data Space | 10m → commune aggregate | 2017–2024 | Free API |
| VIIRS nightlights | NOAA/EOG | ~500m → commune aggregate | 2017–2024 | Free download |
| Commune boundaries | HDX (OCHA) | Admin3 polygons | Static | Free download |
| ACLED incidents | ACLED API | Event-level, geocoded | 2017–2024 | API key available |

## Exposure Alignment

Treatment is defined at the provincial level: grid cells in Al Hoceima, Chefchaouen, and Taounate are "eligible" after Decree 2-22-159 (March 2022). The treatment captures legal eligibility for cannabis cultivation, not actual cultivation itself. All residents, businesses, and land in eligible provinces are exposed to the legalization regime — including access to ANRAC permits, processing facility investments, and associated infrastructure. This intent-to-treat (ITT) design avoids selection bias from endogenous permit take-up. The outcome (nightlights) captures aggregate economic activity in each grid cell, including both agricultural and non-agricultural channels.

## Robustness Checks

1. Placebo treatment year (2019, 2020)
2. Placebo treatment provinces (non-adjacent provinces with similar geography)
3. Donut-hole RDD (excluding communes immediately on the boundary)
4. Event study with leads and lags (Callaway-Sant'Anna dynamic effects)
5. Alternative NDVI measures (mean vs. peak; growing season vs. off-season)
