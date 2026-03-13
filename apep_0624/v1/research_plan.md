# Research Plan: apep_0624

## Research Question

Does mandatory carbon pricing reduce industrial greenhouse gas emissions at the facility level? We estimate the causal effect of Canada's federal carbon pricing backstop — imposed on four provinces (Ontario, Saskatchewan, Manitoba, New Brunswick) in April 2019 — on facility-level GHG emissions using Environment and Climate Change Canada's Greenhouse Gas Reporting Program (GHGRP).

## Identification Strategy

**Difference-in-differences** comparing facilities in backstop provinces (ON, SK, MB, NB) to facilities in provinces with pre-existing own carbon pricing systems (BC since 2008, QC since 2013, AB since 2007).

The federal backstop was imposed by the Greenhouse Gas Pollution Pricing Act (2018) on provinces that refused to implement carbon pricing meeting the federal benchmark. The key identifying assumption is that, absent the backstop, emissions trajectories of backstop-province facilities would have evolved parallel to those in own-pricing provinces. We have 15 pre-treatment years (2004–2018) to validate this assumption.

**Treatment:** Binary indicator = 1 for facilities in ON/SK/MB/NB in years ≥ 2019.

**Specification:**
```
log(emissions_it) = α_i + γ_t + β × Backstop_i × Post_t + ε_it
```

Where α_i are facility FE and γ_t are year FE. Clustering at the province level with wild cluster bootstrap (fwildclusterboot) given only 13 provinces.

## Expected Effects and Mechanisms

**Primary hypothesis:** The backstop reduced facility-level emissions by 3–8% within 4 years (2019–2023), driven primarily by fuel-switching (CO2 reductions) and process improvements (CH4/N2O reductions).

**Mechanism tests:**
1. Gas-type decomposition: CO2 (fuel combustion) vs CH4 (process/fugitive) vs N2O
2. Sector heterogeneity: Energy-intensive sectors (mining, manufacturing) vs others
3. Ontario's deregulation gap: July 2018 – March 2019 (cap-and-trade cancelled, backstop not yet in effect)

**Welfare calculation:** Implied marginal abatement cost = (β × mean_emissions × carbon_price) / (β × mean_emissions) = carbon price at which marginal reductions occur. Compare to social cost of carbon (ECCC CA$294/tonne, US EPA US$51/tonne).

## Data Source and Fetch Strategy

**Primary:** ECCC GHGRP facility-level CSV (18,772 facility-year observations, 2004–2023). Direct download from ECCC Open Data portal. No API key required. Fields: GHGRP ID, reference year, facility name, province, NAICS code, lat/lon, CO2, CH4, N2O, HFCs, PFCs, SF6, total CO2e, quantification methodology.

**Download URL:** `https://data-donnees.az.ec.gc.ca/api/file?path=/substances/factsheets/ghgrp-annual-reporting/PDGES-GHGRP-GHGEmissionsGES-2004-Present.csv`

## Exposure Alignment

The treatment — the federal carbon pricing backstop — applies directly to facilities in the four backstop provinces (ON, SK, MB, NB) beginning April 2019. All GHGRP-reporting facilities (emitting ≥10,000 tonnes CO₂e/year) in these provinces face the Output-Based Pricing System (OBPS), which applies a marginal carbon price on emissions exceeding output-based benchmark intensities. The treatment is therefore well-aligned with the unit of observation (facility) and the outcome (facility-level emissions). The comparison group consists of facilities in provinces with pre-existing own pricing systems (BC carbon tax, QC cap-and-trade, AB SGER/CCIR/TIER), which were already exposed to carbon pricing before 2019 and are not affected by the backstop. A key confound is Ontario's pre-2019 coal-fired electricity phase-out, which produced large utility-sector emissions reductions unrelated to the carbon price; we address this through a triple-difference decomposition separating utilities from non-utility sectors.

## Primary Specification

TWFE DiD with facility and year fixed effects. Event study with year-by-year interactions relative to 2018 (last pre-treatment year). Wild cluster bootstrap for inference with 13 province-level clusters. Robustness: HonestDiD/Rambachan-Roth bounds for parallel trends sensitivity.

## Tables (≤5 + SDE appendix)

1. Summary statistics: Facility-level emissions by province group (backstop vs own-pricing)
2. Main DiD results: Effect of backstop on log(emissions)
3. Event study coefficients (pre/post relative to 2018)
4. Mechanism: Gas-type decomposition and sector heterogeneity
5. Robustness: Alternative controls, HonestDiD bounds, placebo tests
F1. Standardized effect size appendix (SDE)
