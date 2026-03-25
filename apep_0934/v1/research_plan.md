# Research Plan: apep_0934

## Research Question

Does community financial ownership of wind turbines reduce local opposition? Evidence from Denmark's køberetsordning (purchase-right scheme), 2009-2020.

## Motivation

The global energy transition requires massive buildout of onshore wind capacity, but NIMBYism is the binding constraint. Governments experiment with community benefit schemes—revenue sharing, local ownership mandates—but whether financial stakes causally reduce opposition has never been answered with credible identification. The existing literature (Jørgensen 2020; Suskevics et al. 2019; Liebe et al. 2017) is entirely survey-based.

## Policy Setting

Under Denmark's Renewable Energy Act (VE-loven), developers of onshore wind turbines (≥25m) were required to offer ≥20% of project shares at cost price to nearby residents. The scheme ran January 2009 to June 2020, covering ~90+ projects. Shares priced at 3,000-4,000 DKK with guaranteed feed-in tariff returns. When oversubscribed, Energistyrelsen conducted formal lotteries (lodtrækning). Priority: residents within 4.5 km (Group 1), then municipality residents (Groups 2-3).

## Identification Strategy

**Primary: Staggered DiD**
- Treatment: installation of community-owned wind turbines in a municipality
- Timing: ~90+ projects staggered across 2009-2020
- Unit: Danish municipality (98 municipalities post-2007 reform)
- Pre-periods: 5-10 years of property/election data before each project
- Estimator: Callaway-Sant'Anna (2021) to handle heterogeneous treatment timing

**Treatment intensity:** continuous treatment using installed community wind capacity (MW) per municipality, following de Chaisemartin and D'Haultfoeuille (2020).

**Key threats and responses:**
- Selection of turbine sites → event study pre-trends, covariate balance on pre-treatment municipality characteristics
- Concurrent policies → municipality × year FE absorb time-varying shocks; leave-one-out robustness
- Measurement: municipality-level outcomes are coarse → this is acknowledged as a limitation; property value effects should be detectable at this level given Danish municipality sizes

## Data Sources

1. **Energistyrelsen Stamdataregisteret** — All Danish wind turbine coordinates, capacity, installation dates (3.9MB Excel, confirmed available)
2. **DST StatBank EJDFOE1** — Real estate values by municipality, property type, year (104 municipalities × 21 years)
3. **DST StatBank KVRES** — Municipal election results by party, 2005-2021 (105 municipalities × 22 parties × 5 elections)
4. **DST StatBank BOL101** — Dwellings by municipality (for normalization)

## Expected Effects

- **Property values:** If community ownership reduces opposition and facilitates project completion, nearby property values should decline less (or increase) relative to turbine installations without community ownership. At municipality level: positive effect on aggregate property values from local dividend income + acceptance.
- **Green voting:** If financial stake increases acceptance of renewables, green/climate party vote share should increase in treated municipalities.
- **Mechanism:** Financial alignment turns potential opponents into stakeholders with income tied to turbine performance.

## Primary Specification

Y_{mt} = α_m + λ_t + β · CommunityWind_{mt} + X_{mt}γ + ε_{mt}

Where:
- Y_{mt}: outcome (log property values, green vote share) in municipality m, year t
- CommunityWind_{mt}: indicator/intensity of community wind capacity
- α_m, λ_t: municipality and year fixed effects
- X_{mt}: time-varying controls (population, income)

## Robustness Checks

1. Event study / dynamic treatment effects (Callaway-Sant'Anna)
2. HonestDiD/Rambachan-Roth sensitivity for parallel trends
3. Leave-one-out (by project, by municipality)
4. Placebo: non-community wind turbines (installed before 2009 or without køberetsordning)
5. Wild cluster bootstrap for small number of clusters
