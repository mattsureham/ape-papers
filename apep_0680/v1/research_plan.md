# Research Plan: Do Vehicle Bans Capitalize into Housing? A Spatial RDD at France's Low-Emission Zone Boundaries

## Idea Source
idea_0570 — France ZFE spatial RDD on property values

## Research Question
Do driving restrictions in Lyon's Zone à Faibles Émissions (ZFE) capitalize into residential property values? Specifically, does the introduction of private vehicle bans at the ZFE boundary create a discontinuity in housing prices between properties just inside and just outside the zone?

## Why This Matters
Low-emission zones are proliferating globally (London ULEZ, German Umweltzonen, Dutch milieuzones). France alone has 25 active ZFEs, and the government is now moving to abolish them (June 2025) due to equity concerns — the "hidden tax" critique. Yet we have no causal evidence on how French ZFEs affect property values. This paper provides the first spatial RDD at a French ZFE boundary, resolving a key gap: do driving bans create a property premium (through cleaner air) or a property penalty (through reduced accessibility)?

## Identification Strategy
**Spatial RDD** (Keele and Titiunik 2015). The running variable is signed geodesic distance from each property parcel centroid to the nearest point on the ZFE boundary polygon. Properties inside the ZFE are treated (driving restrictions apply); properties outside are control.

- **Boundary:** Lyon ZFE perimeter (~35 km polygon following Boulevard Laurent Bonnevay)
- **Treatment timing:** September 2022 (private vehicles, Crit'Air 5 and unclassified banned)
- **Primary bandwidth:** ±1 km (robustness: 500m, 750m, 1.5km, 2km)
- **Key assumption:** No precise manipulation — the ZFE boundary follows existing road infrastructure (Boulevard Laurent Bonnevay), not drawn to optimize property values
- **Falsification:** Pre-ZFE placebo test using 2018-2019 transactions; McCrary density test at boundary; balance tests on property characteristics

## Expected Effects and Mechanisms
- **Mechanism 1 (Air quality premium):** ZFE restricts polluting vehicles → lower NO2/PM → higher willingness-to-pay for properties inside → positive capitalization
- **Mechanism 2 (Accessibility penalty):** ZFE restricts access for older vehicles → reduced demand from lower-income households with non-compliant vehicles → negative capitalization
- **Net effect:** Ambiguous ex ante — this is the empirical question. The sign and magnitude reveal which channel dominates.
- **Heterogeneity:** By property type (apartment vs. house), by Crit'Air tightening phase (2022 vs. 2024)

## Primary Specification
```
log(price/m²) = α + τ · 1(inside ZFE) + f(distance) + X'β + γ_t + ε
```
Where:
- f(distance) is a local polynomial in signed distance to boundary
- X includes: surface area, number of rooms, property type, construction period
- γ_t are year-quarter fixed effects
- Estimation via `rdrobust` with MSE-optimal bandwidth selection

## Data Sources and Fetch Strategy

### 1. DVF (Demandes de Valeurs Foncières) — Primary outcome
- **Source:** Bulk geocoded CSV from data.gouv.fr
- **URL:** `https://files.data.gouv.fr/geo-dvf/latest/csv/{year}/departements/69.csv.gz`
- **Years:** 2018-2024 (pre/post ZFE implementation)
- **Variables:** date_mutation, valeur_fonciere, type_local, surface_reelle_bati, nombre_pieces_principales, longitude, latitude, id_parcelle, code_commune
- **Expected volume:** ~100,000 transactions/year for Rhône department

### 2. ZFE Boundary — Treatment assignment
- **Source:** Grand Lyon open data portal
- **URL:** `https://download.data.grandlyon.com/files/grandlyon/environnement/zfe/zfe_zone_metropole_de_lyon.geojson`
- **Format:** GeoJSON polygon with ~750 vertices

### 3. Air Quality (Secondary) — Mechanism
- **Source:** EEA Air Quality Download API
- **Variables:** Monthly NO2 concentrations from monitoring stations in Lyon area

## Analysis Pipeline
1. `01_fetch_data.R` — Download DVF CSVs (2018-2024) and ZFE GeoJSON
2. `02_clean_data.R` — Geocode, compute signed distance to ZFE boundary, construct panel
3. `03_main_analysis.R` — Spatial RDD estimation (rdrobust), event study, diagnostics
4. `04_robustness.R` — Bandwidth sensitivity, placebo tests, McCrary density, balance tests
5. `05_tables.R` — Generate all tables including SDE appendix
