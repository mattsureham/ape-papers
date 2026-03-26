# Research Plan: apep_0990

## Research Question

Do mandatory groundwater pumping allocations cause farmers to restructure their crop portfolios, and does this adaptation preserve or reduce agricultural productivity? Nebraska's 23 Natural Resources Districts (NRDs) adopted binding groundwater allocations in a staggered pattern from 1979 to 2025, creating the world's longest-running experiment in quantitative groundwater regulation.

## Identification Strategy

**Staggered DiD** (Callaway & Sant'Anna 2021) exploiting the NRD-by-NRD adoption of mandatory groundwater allocations. Treatment is binary: NRD adopts binding pumping limits. The staggered rollout spans 45+ years across 23 NRDs (mapped to ~93 counties), with never-treated NRDs as controls. Key threats: (1) differential aquifer depletion trends across NRDs — controlled via pre-treatment aquifer thickness; (2) correlated agricultural policy changes — addressed via within-state design (all counties face same federal/state policies); (3) few-cluster inference with 23 NRDs — will use wild cluster bootstrap.

## Expected Effects and Mechanisms

**Primary hypothesis:** Allocations reduce irrigated corn acreage and increase dryland crop acreage (sorghum, wheat, soybeans) — the "crop substitution margin." Whether total farm income falls depends on adaptation efficiency.

**Mechanism:** Binding water limits force farmers to reallocate acres from water-intensive corn (25-30 inches/season) to drought-tolerant crops (sorghum: 15-18 inches, winter wheat: 10-12 inches). Long-run effects may differ from short-run as farmers invest in center-pivot efficiency and drought-resistant varieties.

## Primary Specification

ATT estimated via Callaway-Sant'Anna (2021) with:
- Unit: county-year
- Treatment: year NRD adopted mandatory allocations
- Outcomes: (1) irrigated corn share of cropland, (2) sorghum + wheat share, (3) net cash farm income per acre
- Clustering: NRD level (23 clusters)
- Control group: not-yet-treated + never-treated counties
- Event study: pre/post dynamics to validate parallel trends

## Data Sources

1. **USDA NASS Quick Stats API** — County-level crop area harvested by commodity (corn, sorghum, wheat, soybeans), irrigated vs non-irrigated, 1990-2023 (annual Survey); Census of Agriculture (1997, 2002, 2007, 2012, 2017, 2022) for irrigated breakdowns.
2. **NRD treatment timing** — Manually compiled from Nebraska Department of Natural Resources reports and NRD management plans. Key source: "NRD Water Management Activities Summary" (DNR).
3. **USGS National Water Information System** — Groundwater levels for Ogallala Aquifer monitoring wells.
4. **US Drought Monitor API** — Weekly county-level drought severity for drought controls.

## Robustness

1. Callaway-Sant'Anna event study (pre-trend validation)
2. HonestDiD sensitivity (Rambachan-Roth bounds)
3. Wild cluster bootstrap (few-cluster inference, 23 NRDs)
4. Placebo: non-irrigated crop acreage (should not respond to irrigation limits)
5. Dose-response: allocation stringency (inches per year) vs binary adoption
6. Leave-one-out: drop Upper Republican (earliest adopter, 1979)
