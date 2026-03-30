# Research Plan: apep_1155

## Research Question

What is the net economic effect of El Salvador's 2022 state of exception — the largest peacetime mass incarceration event in modern Latin American history — on local economic activity? When organized crime is suddenly removed from communities, does the elimination of extortion boost economic activity enough to offset the loss of labor supply?

## Policy Background

On March 27, 2022, El Salvador declared a state of exception following a spike of 87 homicides over a single weekend. The regime suspended constitutional rights and enabled mass arrests of suspected gang members. By 2026, over 91,000 people had been detained — approximately 1.4% of the national population, predominantly young men from gang-heavy communities. The homicide rate collapsed from 17.3 per 100,000 in 2021 to approximately 1.9 per 100,000 in 2024.

Gangs (primarily MS-13 and Barrio 18) had imposed an estimated $756 million annually in extortion payments (~3% of GDP), affecting businesses, bus routes, and local commerce across the country. The state of exception created a dramatic, sudden removal of gang infrastructure from communities with heterogeneous pre-crackdown gang presence.

## Identification Strategy

**Continuous difference-in-differences** exploiting cross-municipality variation in pre-crackdown gang intensity.

**Treatment intensity:** Cumulative gang member detentions per capita (2011–2018) from Policía Nacional Civil records. Municipalities with more gang members before the crackdown experienced greater "treatment" (more people removed, more extortion eliminated) during the state of exception.

**Specification:**
```
Y_{mt} = α_m + γ_t + β(GangIntensity_m × Post_t) + ε_{mt}
```

Where:
- Y_{mt} = log(nightlight radiance + 0.01) in municipality m, month t
- GangIntensity_m = pre-crackdown gang detentions per 10,000 population (2011–2018)
- Post_t = 1{t ≥ April 2022}
- α_m = municipality fixed effects
- γ_t = year-month fixed effects
- Clustering: municipality level (262 clusters)

**Event study version:**
```
Y_{mt} = α_m + γ_t + Σ_k β_k(GangIntensity_m × 1{t = k}) + ε_{mt}
```
With k indexing months relative to March 2022 (omitting k = -1 as reference).

**Identifying assumption:** Absent the state of exception, nightlight trends would have been parallel across municipalities with different levels of pre-crackdown gang intensity. Testable via pre-period coefficients in event study.

## Expected Effects and Mechanisms

**Theoretically ambiguous net effect:**
1. **Extortion reduction channel (+):** Removing gangs eliminates extortion payments (est. $756M/yr nationally), reducing costs for local businesses and enabling new commercial activity.
2. **Labor supply removal channel (−):** Detaining ~85,000 predominantly young men reduces the working-age population and consumer demand in affected municipalities.
3. **Security premium (+):** Reduced violence may attract investment, enable later business hours, reduce security costs.
4. **Disruption channel (−):** Mass arrests and security operations may temporarily disrupt normal economic activity.

The net sign is an empirical question — this is why the paper is interesting.

## Data Sources

1. **VIIRS nighttime lights (primary outcome):** NASA Black Marble VNP46A3 monthly composites, extracted at municipality level using BlackMarbleR package. Period: January 2019 – December 2024 (72 months). 262 municipalities.

2. **Municipality-level homicide and gang detention data (treatment intensity):** PLOS ONE supplementary files from "A Bayesian spatio-temporal model of variation in homicide rates for El Salvador" (2024):
   - S1: Homicide rates per 10,000 by municipality (2002–2021)
   - S2: Gang member detentions by municipality (2011–2018)
   - S3: Population projections by municipality (2002–2022)

3. **World Bank Development Indicators:** Country-level GDP, population for context.

## Primary Specification

- Unit of observation: municipality × month
- Sample: 262 municipalities × 72 months ≈ 18,864 observations
- Outcome: log(mean nightlight radiance + 0.01)
- Treatment: continuous (gang detentions per 10,000 pop, standardized)
- Fixed effects: municipality + year-month
- Clustering: municipality
- Estimator: OLS via fixest::feols()

## Robustness Checks

1. Binary treatment (above/below median gang intensity)
2. Placebo treatment dates (2020, 2021)
3. Leave-one-department-out
4. Alternative treatment measures (homicide rate instead of detentions)
5. Excluding COVID period (2020–2021)
6. Wild cluster bootstrap (small number of departments = 14)
7. Different functional forms of nightlights (levels, inverse hyperbolic sine)

## Key Risk

Tournament lessons flag "nightlights for policy effects" as a proxy outcome weakness. Mitigation: (1) the shock is extraordinarily large (1.4% of population detained), so any real economic effect should register in nightlights; (2) no municipality-level administrative economic data exists for El Salvador; (3) validate nightlights against national GDP trends; (4) frame honestly as the best available measure for this unique setting.
