# Research Plan: Banned at the Border — ZFE Low-Emission Zones and Populist Voting in France

## Research Question

Do vehicle bans in France's Low-Emission Zones (Zones à Faibles Émissions, ZFE) cause electoral backlash, measured by increased voting for the Rassemblement National (RN)?

## Why It Matters

France's 2021 Climate and Resilience Law mandated ZFEs in all agglomerations above 150,000 inhabitants. By 2024, 12 metropolitan areas had implemented ZFEs banning progressively older vehicles (Crit'Air 5 → 4 → 3). In 2025, France voted to abolish ZFEs — the most dramatic reversal of environmental regulation in a major economy. Yet no causal evidence exists on whether ZFEs actually fueled populist backlash. This paper provides the first such estimate.

## Identification Strategy

**Spatial difference-in-discontinuities** (Butts 2021; Grembi, Nannicini & Troiano 2016). The ZFE perimeter in each metropolitan area creates a sharp geographic boundary: vehicles above the Crit'Air threshold are banned inside but not outside. I exploit the discontinuous change in RN vote share at the ZFE boundary, comparing pre-ZFE elections (when the boundary had no regulatory meaning) to post-ZFE elections.

**Running variable:** Signed geodesic distance from commune centroid to nearest ZFE boundary (positive = inside, negative = outside).

**Key equation:**
$$\Delta Y_{ct} = \alpha + \tau \cdot \mathbb{1}[\text{Inside}_c] + f(\text{Distance}_c) + \mathbb{1}[\text{Inside}_c] \times f(\text{Distance}_c) + X_c'\gamma + \delta_m + \varepsilon_{ct}$$

where $\Delta Y_{ct}$ is the change in RN vote share from the last pre-ZFE election to the first post-ZFE election, $\mathbb{1}[\text{Inside}_c]$ indicates whether the commune centroid is inside the ZFE perimeter, $f(\cdot)$ is a local polynomial in distance, $X_c$ are pre-determined covariates, and $\delta_m$ are metro fixed effects.

**Why this works:**
1. ZFE boundaries follow administrative/road network lines, not socioeconomic sorting
2. Communes just inside vs. just outside are comparable in pre-treatment characteristics
3. Stacking across 12 metros with different implementation dates provides variation
4. Pre-ZFE elections serve as placebo: no discontinuity should exist before the ban

## Expected Effects and Mechanisms

**Primary hypothesis:** ZFEs increase RN vote share in communes just inside the boundary relative to communes just outside. Mechanism: vehicle owners with older (cheaper) cars face mobility costs and perceive the regulation as regressive.

**Alternative mechanisms to test:**
1. Turnout (mobilization vs. persuasion): Does the effect operate through differential turnout or vote switching?
2. Income gradient: Is the backlash concentrated in lower-income communes where Crit'Air 4-5 vehicles are more prevalent?
3. Sorting: Do DVF transactions show price divergence at the boundary post-ZFE? (Rules out composition changes driving vote results)

## Primary Specification

- **Bandwidth:** 5 km baseline, with robustness at 3, 7, 10 km
- **Kernel:** Triangular (baseline), uniform (robustness)
- **Polynomial:** Local linear (baseline), local quadratic (robustness)
- **Clustering:** Metro-level (12 clusters) with wild cluster bootstrap; commune-level as alternative
- **Fixed effects:** Metro fixed effects in stacked specification

## Data Sources and Fetch Strategy

### 1. ZFE Boundaries (GeoJSON)
- Source: transport.data.gouv.fr — Base Nationale des ZFE (BNZFE)
- Content: Polygons with date_debut, date_fin, Crit'Air thresholds
- Format: GeoJSON, direct download

### 2. Commune-Level Election Results
- Source: data.gouv.fr — Résultats électoraux
- Elections: Presidential 2012, 2017, 2022; Legislative 2017, 2022, 2024
- Variables: RN (FN pre-2018) vote share, turnout, registered voters
- Format: CSV/Parquet, direct download

### 3. Commune Centroids and Boundaries
- Source: IGN Admin-Express or communes GeoJSON from data.gouv.fr
- Variables: Commune code, latitude/longitude, population
- Format: GeoJSON/Shapefile

### 4. DVF Property Transactions (sorting test)
- Source: data.gouv.fr — Demandes de Valeurs Foncières
- Variables: Transaction price, location, date, property type
- Format: CSV, direct download (by département)

### 5. Socioeconomic Controls
- Source: INSEE BDM/SDMX or Filosofi
- Variables: Median income, unemployment rate, population density, share of renters
- Level: Commune

## Execution Order

1. Fetch ZFE boundary GeoJSON and commune geometries
2. Compute signed distance from each commune centroid to nearest ZFE boundary
3. Fetch election results for all 6 elections
4. Match elections to commune-ZFE proximity panel
5. Run diff-in-disc: estimate discontinuity in ΔRN at boundary, pre vs. post
6. Robustness: bandwidth sensitivity, placebo (pre-ZFE elections), donut RDD
7. Mechanism: turnout decomposition, income heterogeneity
8. Sorting test: DVF prices at boundary

## Diagnostics to Report

- McCrary/rddensity test for commune density at ZFE boundary
- Covariate balance at boundary (income, population, pre-treatment vote share)
- Placebo: discontinuity in 2012→2017 vote change (before any ZFE existed)
- Bandwidth sensitivity plots
- Leave-one-metro-out jackknife
