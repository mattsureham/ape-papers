# Research Plan: The Devolution Dividend

## Research Question
Does formula-driven fiscal decentralization translate into measurable local economic activity? India's 14th Finance Commission (April 2015) raised states' share of central tax revenue from 32% to 42%, with cross-state variation in windfall magnitude driven by predetermined formula weights (50% income distance, 17.5% population, 15% area, 7.5% forest cover, 10% demographic performance). We test whether states receiving larger per-capita windfalls experienced faster growth in district-level nighttime luminosity.

## Identification Strategy
**Continuous treatment DiD.** Treatment intensity = predicted per-capita fiscal windfall by state, constructed from the 14th FC formula weights. The formula uses predetermined characteristics (1971 population, area, forest cover, historical GSDP distance from richest state), providing plausibly exogenous cross-state variation.

**Primary specification:**
```
log(Light_{d,t}) = α_d + γ_t + β × (Windfall_s × Post_t) + ε_{d,t}
```
Where:
- d = district, t = year, s = state containing district d
- α_d = district FE (absorbs time-invariant district characteristics)
- γ_t = year FE (absorbs aggregate shocks: demonetization, GST, etc.)
- Windfall_s = per-capita formula-predicted transfer increase for state s
- Post_t = 1{t ≥ 2015}
- Cluster SEs at state level (28 clusters → wild cluster bootstrap)

**Event study for pre-trends:**
```
log(Light_{d,t}) = α_d + γ_t + Σ_k β_k × (Windfall_s × 1{t=k}) + ε_{d,t}
```
Omitting 2014 as reference year. Clean pre-trends in β_{2012}, β_{2013} support parallel trends.

## Expected Effects and Mechanisms
- **Primary:** Positive β — larger formula-driven windfalls increase local economic activity (the "devolution dividend")
- **Mechanism 1:** Untied transfers → state capital expenditure → infrastructure → growth
- **Mechanism 2:** Untied transfers → social spending (health/education) → human capital → growth (longer run)
- **Null result interpretation:** If β ≈ 0, suggests fiscal leakage, crowding out, or that untied transfers substitute for own revenue effort

## Data Sources
1. **VIIRS nightlights** (2012–2023): Annual district-level luminosity from SHRUG, aggregated from village level
2. **Census 2011 PCA**: District-level baseline characteristics (population, literacy, urbanization)
3. **14th FC formula weights**: Official state-wise devolution shares from Finance Commission report (public)
4. **13th FC formula weights**: For computing the CHANGE in allocation (difference instrument)
5. **RBI DBIE**: State-level fiscal data for first-stage verification (actual transfers pre/post)

## Key Design Parameters
- 28 states, ~640 districts
- Pre-period: 2012–2014 (3 years VIIRS)
- Post-period: 2015–2023 (9 years)
- Treatment: Continuous (per-capita windfall, varies by state)
- Inference: Wild cluster bootstrap (28 state-level clusters)

## Exposure Alignment
The treatment — per-capita formula-driven fiscal windfall — varies at the STATE level (28 states). All districts within a state receive the same windfall intensity. The outcome — nighttime luminosity — is measured at the DISTRICT level (588 districts). The fiscal transfers flow from the central government to state treasuries; state governments then allocate spending across districts. The identifying assumption is that higher state-level windfalls translate into greater district-level economic activity through state spending. The within-state distribution of spending is unobservable in our data, so the coefficient captures the average district-level response to the state-level windfall.

## Robustness
1. **13th FC transition placebo**: Test for effects during 13th→14th FC transition using DMSP 2008–2013
2. **Bartik decomposition**: Separate formula components to check which dimension drives results
3. **Balanced panel**: Restrict to districts observed in all years
4. **Heterogeneity**: By baseline urbanization, income level, state capacity
5. **Leave-one-out**: Drop each state to check sensitivity to outliers
