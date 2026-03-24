# Research Plan: The Upload Filter Tax — EU Copyright Directive Article 17 and Creative-Sector Employment

## Research Question

Does mandatory platform copyright compliance (upload filters) reduce information-sector employment? The EU Copyright Directive 2019/790 Article 17 required platforms to implement content recognition technology, transposed by 27 member states over 44 months (Dec 2020–Aug 2024). We exploit this staggered adoption as a natural experiment.

## Identification Strategy

**Callaway & Sant'Anna (2021) staggered DiD.** Treatment = national transposition of Article 17. Timing varies across 27 EU member states from 2020 to 2024, driven by national legislative procedures (plausibly exogenous to local labor market conditions). Never-treated controls: Norway, Switzerland, Iceland (EEA members not bound by EU Copyright Directive).

**Triple-difference extension:** Within each NUTS2 region, compare NACE J (Information & Communication, directly exposed to upload filter mandates) to NACE K (Financial & Insurance Activities, unexposed). This differences out region-specific shocks.

## Expected Effects and Mechanisms

- **Compliance cost channel:** Upload filter mandates raise platform operating costs → reduced investment in content creation → lower creative-sector employment. Expected: moderate negative effect on NACE J employment.
- **Revenue protection channel:** Stronger copyright enforcement → higher licensing revenues for creators → positive effect on creative employment. Expected: positive for traditional media subsectors.
- **Net effect is theoretically ambiguous** — this is what makes it interesting. The sign tells us which channel dominates.

## Primary Specification

```
Y_{r,t} = α_r + α_t + β · D_{c(r),t} + X_{r,t}'γ + ε_{r,t}
```

Where Y is log NACE J employment in NUTS2 region r, year t. D is a binary treatment indicator = 1 after country c transposed Article 17. X includes time-varying controls (population, GDP per capita). Standard errors clustered at the country level (27 clusters).

CS-DiD will estimate group-time ATTs, aggregated to overall ATT with event-study plots.

## Data Sources

1. **Eurostat LFS** (`lfst_r_lfe2en2`): Employment by NACE sector at NUTS2 level, 2008–2024
2. **CELLAR SPARQL** (via `eurlex` R package): Exact transposition dates for Directive 2019/790 across all member states
3. **Eurostat regional GDP** (`nama_10r_2gdp`): Control variable, NUTS2 level
4. **Eurostat population** (`demo_r_pjanaggr3`): Control variable, NUTS2 level
5. **Norway, Switzerland, Iceland**: Same Eurostat LFS data (EEA reporting)

## Robustness

1. Event study with CS-DiD (pre-trends test)
2. DDD: NACE J vs NACE K (difference out region-time shocks)
3. Leave-one-country-out
4. Alternative treatment timing (entry-into-force vs notification date)
5. HonestDiD/Rambachan-Roth sensitivity for parallel trends violations
