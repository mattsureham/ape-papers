# Research Plan: Pakistan 2022 Floods and Non-Monotonic Agricultural Recovery

## Research Question
Do severely flooded areas experience paradoxical agricultural recovery in the winter (rabi) crop season due to soil moisture replenishment, even as summer (kharif) crops suffer monotonically increasing losses from flood intensity?

## Identification Strategy
**Continuous Treatment DiD with dose-response:**
- **Treatment:** % of tehsil area flooded (0–100%), from UNOSAT satellite flood mapping
- **Outcome:** MODIS NDVI (vegetation index) at tehsil × crop-season level
- **Control:** Tehsils with <5% flooded area (~200 tehsils, effectively unflooded)
- **Panel:** 751 tehsils × 10 seasons (4 years pre × 2 seasons + 2 post-seasons)

**Estimating equation:**
```
NDVI_{it} = α_i + γ_t + β₁(Flood_i × Post_t) + β₂(Flood_i² × Post_t) + ε_{it}
```

Separate regressions for kharif (summer: Jul–Oct) and rabi (winter: Nov–Mar) seasons.

**Non-monotonic hypothesis:**
- Kharif: β₁ < 0 (destruction), β₂ ≈ 0 (monotonic loss)
- Rabi: β₁ > 0 (soil moisture benefit), β₂ < 0 (inverted-U — extreme flooding destroys soil)

## Expected Effects and Mechanisms
1. **Kharif destruction channel:** Standing crops destroyed proportionally to flood extent → monotonic negative dose-response
2. **Rabi moisture channel:** Moderate flooding replenishes groundwater and deposits nutrient-rich silt → positive NDVI in next season
3. **Rabi salinization channel:** Extreme flooding deposits salts and destroys soil structure → negative NDVI at high intensities
4. Net effect: Non-monotonic rabi response (positive at moderate, negative at extreme flood intensities)

## Primary Specification
- Unit FE + season-year FE
- Continuous treatment (% flooded) × post indicator
- Quadratic and binned specifications for non-linearity
- Clustering: district level (since flood intensity spatially correlated within districts)
- Pre-trends: event study with 8 pre-periods (4 years × 2 seasons)

## Data Sources
1. **UNOSAT Flood Extent:** Pakistan 2022 flood footprint — tehsil-level % area flooded (HDX/UNOSAT)
2. **Pakistan Admin Boundaries:** GADM Level 3 (tehsil) boundaries for spatial overlay
3. **MODIS NDVI:** MOD13Q1 product (250m, 16-day composites, 2018–2023) via ORNL DAAC API or AppEEARS
4. **Supplementary:** CHIRPS rainfall data for mechanism (soil moisture proxy)

## Fetch Strategy
1. Download UNOSAT flood extent shapefile from HDX API
2. Download GADM Pakistan Level 3 boundaries
3. Use MODISTools R package to extract NDVI time series at tehsil centroids (2018–2023)
4. Compute tehsil-level flood intensity via spatial overlay in R (sf package)

## Exposure Alignment
The treatment variable (% tehsil area flooded) measures the spatial extent of satellite-detected inundation during July–October 2022. This is a geographic exposure variable, not an individual-level treatment. All agricultural producers within a tehsil are assigned the same treatment intensity. The identifying variation is cross-sectional: tehsils that experienced different flood intensities are compared before and after the 2022 flood event, holding fixed tehsil-level unobservables and common time shocks. The key concern is that flood intensity may correlate with time-varying confounders (e.g., provincial agricultural programs, irrigation investments, or relief aid). Province-specific trends and the placebo test address this. NDVI measures vegetation at the tehsil centroid, not agricultural outcomes specifically — this is a measurement limitation that may attenuate true crop effects.

## Robustness Checks
- Alternative NDVI thresholds (raw NDVI vs. enhanced EVI)
- Province-specific trends
- Dropping extreme outlier tehsils (>95% flooded)
- Placebo test: 2019 monsoon season (no major flood)
- Permutation inference (randomly reassign flood intensities)
- Leave-one-province-out
