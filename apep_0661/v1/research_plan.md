# Research Plan: Assigned Neighbors — No-Choice Asylum Dispersal and Local Crime in England

## Research Question

Does the exogenous placement of asylum seekers through the UK's no-choice National Asylum Support Service (NASS) dispersal policy causally affect local crime rates? If so, which crime types are affected, and does the effect operate through compositional changes or neighborhood-level mechanisms?

## Policy Context

The Immigration and Asylum Act 1999 created NASS, which from April 2000 dispersed asylum seekers to local authorities (LAs) with available social housing on a **no-choice basis** — refusal meant losing all support. Allocation was driven by housing vacancy and contract logistics with private providers (Clearsprings, Mears, Serco), not by local economic conditions. This removes the standard self-selection problem in immigration research: asylum seekers did not choose their placement location.

## Identification Strategy

### Shift-Share Instrumental Variable (Goldsmith-Pinkham et al. 2020; Borusyak-Hull-Jaravel 2022)

- **Share (s_i):** LA-level share of vacant social housing from the 2011 Census (pre-determined by post-war public housing construction, not by contemporaneous conditions)
- **Shift (g_t):** National quarterly asylum application volume (driven by geopolitical events: Syrian civil war 2014-15, Afghan fall 2021, Channel crossings 2018+)
- **Instrument:** Z_{i,t} = s_i × g_t → predicted asylum seeker inflow per LA per quarter
- **First stage:** Z_{i,t} predicts actual Home Office dispersal numbers (Asy_D11 data)
- **Second stage:** Instrumented dispersal → LA-quarter crime rates

### Key Identifying Assumptions

1. **Shares exogeneity (GPSS):** 2011 housing vacancy rates are pre-determined and reflect 1960s-80s public housing construction, not contemporaneous crime trends
2. **Shifts exogeneity (BHJ):** National asylum volumes driven by foreign conflicts are exogenous to local UK LA conditions
3. **Exclusion:** National asylum shocks affect local crime only through actual dispersal placement
4. **Parallel trends:** Pre-2014 crime trends uncorrelated with housing vacancy shares

### Robustness

- Rotemberg weights decomposition (identifying which shares drive results)
- Leave-one-out: drop top 5 dispersal LAs (Glasgow, Birmingham, Liverpool, Leeds, Sheffield)
- Placebo: test against pre-period crime changes
- Crime type decomposition as mechanism test

## Expected Effects and Mechanisms

**Theory is ambiguous:**
- **Null hypothesis:** Asylum seekers have no systematic effect on crime (consistent with most credible immigration-crime studies)
- **Compositional effect:** Asylum seekers are disproportionately young males → mechanical crime increase from demographics
- **Deprivation channel:** Placement in deprived areas with limited integration support → social friction
- **Reporting bias:** Increased policing attention in dispersal areas → more recorded crime without more actual crime

## Primary Specification

crime_rate_{i,t} = α_i + γ_t + β × (asylum_per_1000_{i,t}) + X'_{i,t}δ + ε_{i,t}

Instrumented by: Z_{i,t} = vacancy_share_i × national_asylum_t

Where:
- i = LA, t = quarter
- α_i = LA fixed effects
- γ_t = quarter fixed effects
- X = time-varying controls (LA population, unemployment rate)

## Data Sources

1. **Home Office Asy_D11:** Quarterly asylum seeker numbers by LA (2014Q2-2023Q1)
2. **UK Police API / data.police.uk:** Monthly crime counts by category, by LA
3. **2011 Census (NOMIS):** Housing tenure/vacancy by LA (instrument share)
4. **ONS Mid-Year Population Estimates:** LA population denominators
5. **NOMIS Labour Market:** LA-level unemployment/economic activity (controls)

## Outcome Variables

**Primary:** Total recorded crime per 1,000 population (LA-quarter level)

**Decomposition (mechanism tests):**
- Violence against the person
- Property crime (burglary, robbery, theft)
- Anti-social behaviour
- Drug offences
- Public order offences

## Sample

~350 LAs × 36 quarters (2014Q2-2023Q1) = ~12,600 LA-quarter observations
~150-200 LAs received some dispersal; top receivers: Glasgow (4,152), Birmingham (2,504), Liverpool (2,385)
