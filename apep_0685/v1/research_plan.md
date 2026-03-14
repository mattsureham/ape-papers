# Research Plan: apep_0685

## Research Question

Does mandatory carbon pricing reduce facility-level industrial greenhouse gas emissions? Canada's federal carbon pricing backstop — imposed on provinces that refused to implement their own systems — provides a quasi-experiment to estimate the causal effect.

## Setting

Canada's Greenhouse Gas Pollution Pricing Act (2018) required all provinces to price carbon at a federal benchmark or face the "backstop." British Columbia (carbon tax since 2008) and Quebec (cap-and-trade since 2013) already complied. Ontario canceled its cap-and-trade in July 2018, and the federal backstop was imposed on Ontario, Saskatchewan, Manitoba, and New Brunswick in April 2019. The backstop fuel charge started at CA$20/tonne in 2019, rising to CA$65 by 2023.

Ontario's unique trajectory — voluntary pricing → cancellation → forced re-pricing — provides especially rich variation.

## Identification Strategy

**Staggered DiD with Callaway-Sant'Anna (2021).**

- **Treatment:** Federal backstop imposed April 2019 on ON, SK, MB, NB
- **Control:** BC and QC (continuously carbon-priced since 2008/2013); AB (own system TIER/SGER)
- **Unit:** Facility × year
- **Pre-period:** 2004-2018 (15 years)
- **Post-period:** 2019-2023 (5 years)
- **Clustering:** Province-level with wild cluster bootstrap (N=13 provinces/territories)

### Threats and Mitigations

1. **Oil prices:** Control for WTI × sector interactions
2. **COVID:** 2020 is contaminated — report with and without 2020
3. **Small N clusters:** Wild cluster bootstrap (Cameron, Gelbach, Miller 2008)
4. **Anticipation:** Ontario's July 2018 cancellation creates a brief "carbon holiday" — test whether emissions jump in this window

## Expected Effects and Mechanisms

- **Primary:** Backstop reduces facility emissions (negative treatment effect)
- **Mechanism 1 — Fuel switching:** CO2 declines more than CH4/N2O (fuel substitution)
- **Mechanism 2 — Sector heterogeneity:** Energy-intensive sectors (mining, manufacturing) respond more
- **Mechanism 3 — Ontario's carbon holiday:** Emissions may spike July 2018-March 2019

## Primary Specification

```
log(emissions_it) = α_i + δ_t + β × Backstop_it + X_it'γ + ε_it
```

Where `Backstop_it = 1` for facilities in ON/SK/MB/NB post-April 2019. Fixed effects: facility (α_i), year (δ_t). Controls X_it: province GDP growth, oil prices × sector.

CS-DiD for heterogeneous treatment effects by cohort timing.

## Data Sources

1. **ECCC GHGRP:** Facility-level emissions CSV, 18,772 observations, 2004-2023. Direct download from data-donnees.ec.gc.ca. Fields: facility ID, year, province, NAICS, lat/lon, CO2, CH4, N2O, total CO2e.
2. **Statistics Canada:** Provincial GDP for controls (CANSIM/NDM tables)
3. **WTI oil prices:** FRED API (DCOILWTICO)

## Outcome Variables

- **Primary:** log(total CO2e emissions) per facility-year
- **Secondary:** log(CO2), log(CH4), log(N2O) separately
- **Heterogeneity:** By NAICS sector (mining, manufacturing, utilities, waste)

## Robustness

1. Event study plot (pre-trends test)
2. Drop 2020 (COVID)
3. Exclude Alberta (own carbon pricing system, ambiguous treatment)
4. Placebo: fake treatment in 2015 on backstop provinces
5. Wild cluster bootstrap p-values
6. Bacon decomposition

## SDE Appendix

Standardized effect sizes for meta-analysis comparability.
