# Research Plan: When Bugs Hatch Early

## Research Question

What fraction of the well-documented nonlinear temperature-yield relationship (Schlenker and Roberts 2009) operates through pest emergence rather than direct heat stress on plants? Using species-specific growing-degree-day (GDD) thresholds for insect development as a biological instrument, this paper decomposes the temperature-yield function into two channels: (1) pest-mediated damage, where warmer springs accelerate insect emergence, and (2) direct heat stress on plant physiology.

## Identification Strategy

Insect development is poikilothermic — body temperature equals ambient temperature, making emergence timing a deterministic function of accumulated heat. The western corn rootworm (Diabrotica virgifera) hatches at precisely 380 accumulated degree-days (ADD, base 52°F). This biological threshold creates exogenous within-county, across-year variation in pest emergence timing that is uncorrelated with summer heat stress conditional on county and year fixed effects.

**Primary specification:**

$$Y_{ct} = \alpha_c + \gamma_t + \beta_1 \cdot PestGDD_{ct} + \beta_2 \cdot HeatStress_{ct} + X_{ct}'\delta + \varepsilon_{ct}$$

where:
- $Y_{ct}$ = log corn yield in county $c$, year $t$
- $PestGDD_{ct}$ = accumulated degree-days above base 52°F by June 30 (pest emergence intensity)
- $HeatStress_{ct}$ = degree-days above 29°C during July-August (direct plant damage, following Schlenker-Roberts)
- $\alpha_c$ = county fixed effects (soil, long-run climate, farm practices)
- $\gamma_t$ = year fixed effects (national prices, technology trends, federal policy)

The key identification assumption: conditional on county and year FEs, spring warmth (driving pest emergence) is not systematically correlated with summer heat stress beyond what weather station data reveals. The correlation is approximately 0.40 — substantial but far from collinear, allowing separate identification.

## Expected Effects and Mechanisms

1. **Pest channel ($\beta_1 < 0$):** Earlier/more intense pest emergence reduces yields through root damage, feeding on silks, and larval boring. If pests explain 30-50% of temperature-yield damage, this transforms climate adaptation strategy.
2. **Heat stress channel ($\beta_2 < 0$):** Direct thermal damage to pollen viability, enzyme function, and photosynthesis above 29°C. This is the channel most seed biotechnology targets.
3. **Decomposition insight:** The ratio $|\beta_1| / (|\beta_1| + |\beta_2|)$ measures the pest share of total temperature damage — the key policy parameter.

## Data Sources and Fetch Strategy

All data available through Google BigQuery (confirmed accessible, project: scl-librechat):

1. **USDA NASS crop yields** (`bigquery-public-data.usda_nass.*`): County-level corn yields, 2000-2022, ~800 Corn Belt counties × 23 years ≈ 18,000 county-year observations.

2. **GHCN-D daily weather** (`bigquery-public-data.ghcn_d.ghcnd_*`): Daily max/min temperature from ~1,600 Corn Belt weather stations. Used to compute:
   - PestGDD: accumulated degree-days base 52°F (11.1°C), Jan 1 to Jun 30
   - HeatStress: degree-days above 29°C (84.2°F), Jul 1 to Aug 31

3. **USDA RMA Cause-of-Loss** (direct download from RMA website): County-level crop insurance indemnity payments coded by cause, including "Insects" category. Used as a mechanism test — if PestGDD captures real pest damage, it should predict insect-coded insurance claims.

**Fetch order:** BigQuery for NASS + GHCN-D (single session), then RMA Cause-of-Loss via direct HTTP download.

## Key Risks

1. **Collinearity:** Spring warmth and summer heat are correlated (~0.40). Mitigation: explicit VIF checks, partial R-squared decomposition, years where spring and summer diverge (e.g., warm spring + cool summer).

2. **Measurement:** County-level weather aggregated from station data introduces noise. Mitigation: inverse-distance weighting from multiple stations, county-centroid distances.

3. **Other pests:** Multiple pest species with different GDD thresholds. Mitigation: focus on western corn rootworm (dominant corn pest), robustness with composite pest index.
