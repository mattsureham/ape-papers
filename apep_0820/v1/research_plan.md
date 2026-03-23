# Research Plan: apep_0820

## Research Question

What is the causal effect of ambient industrial air pollution (SO2/NOx) on children's academic achievement in U.S. public schools?

## Identification Strategy

**Instrumental Variable:** Gaussian plume dispersion model predictions of ground-level pollution concentration at each school's geocoded location, computed from EPA stack engineering parameters (height, diameter, exit temperature, velocity), hourly CEMS emissions data, and hourly ASOS meteorology (wind speed, direction, atmospheric stability).

**Why the IV is credible:**
- Variation comes from pre-determined plant engineering and synoptic weather
- School + year fixed effects absorb time-invariant sorting and common shocks
- Within-school, year-to-year variation driven by meteorological shifts in how emissions disperse — not by changes in economic activity
- Plume model is EPA's regulatory standard (AERMOD simplified to Gaussian)

**Exclusion restriction:** Predicted concentration affects test scores only through actual pollution. Key threats: (1) economic activity from plants — controlled by wind-direction variation (employment doesn't depend on upwind/downwind); (2) sorting — school FE; (3) direct weather effects — control for temperature, precipitation; IV variation is from nonlinear function of meteorology specific to plant-school geometry.

## Expected Effects and Mechanisms

- **Direction:** Negative — higher pollution reduces test scores
- **Magnitude:** Small to moderate SDE (0.02-0.10 SD per SD of pollution)
- **Mechanisms:** Respiratory health → school absences; cognitive impairment from air toxics; attention/concentration effects
- **Literature benchmark:** Persico & Venator (2021) find significant effects using distance; Marcotte (2017) finds effects of ozone on test performance

## Primary Specification

```
TestScore_{i,t} = β × Pollution_{i,t} + X'_{i,t}γ + α_i + δ_t + ε_{i,t}
```

Instrumented by: `PredictedConc_{i,t} = Σ_j GaussianPlume(emissions_j, stack_j, meteo_t, distance_ij)`

Where i = school, j = plant, t = year. School FE (α_i) and year FE (δ_t). Clustered at county level.

## Data Sources and Fetch Strategy

1. **EPA CAMPD CEMS** — Hourly emissions (SO2, NOx mass) for all Title IV/ARP facilities. API access confirmed. Will fetch annual aggregates by facility, 2009-2018.

2. **EPA NEI SMOKE flat files** — Stack parameters (STKHGT, STKDIAM, STKTEMP, STKVEL) for point sources. 148MB download confirmed. Will extract parameters for CAMPD-matched facilities.

3. **Iowa Environmental Mesonet ASOS** — Hourly surface meteorology (wind direction, wind speed, temperature). Will fetch for stations nearest to each plant, aggregate to annual wind roses.

4. **Stanford SEDA v5.0** — School-level standardized test scores (math, ELA), grades 3-8, 2009-2018. CS (cohort-standardized) metric for cross-district comparability.

5. **NCES EDGE** — School geocodes (latitude, longitude) for computing plant-school distances and bearings.

6. **EPA AQS** — Monitor-level pollution measurements for first-stage validation and reduced-form checks.

## Analysis Pipeline

1. Fetch and clean all data sources
2. Geocode schools and plants; compute pairwise distances and bearings
3. Construct Gaussian plume predicted concentrations (annual, school-level)
4. Merge with SEDA test scores
5. Run first-stage regression (predicted conc → monitor-based pollution)
6. Run 2SLS: IV estimates of pollution on test scores
7. Robustness: placebo outcomes, distance heterogeneity, summer pollution placebo
8. Generate SDE table
