# Research Plan: The Bureaucratic Delay Tax — FEMA Declaration Lags and Household Disaster Recovery

## Research Question

Does the speed of federal disaster declaration affect household recovery outcomes? Specifically, how much does each additional day of lag between disaster onset and FEMA declaration cost affected households in terms of assistance received and displacement duration?

## Identification Strategy

**Primary approach:** IV / 2SLS

- **Endogenous variable:** Declaration lag (days between `incidentBeginDate` and `declarationDate`), continuous 1-247 days
- **Instrument:** Number of concurrent open FEMA disaster declarations at the time of the governor's request. When FEMA processes multiple simultaneous disasters, processing speed slows for any individual request, but concurrent load has no direct effect on household recovery conditional on own-disaster severity.
- **Exclusion restriction:** FEMA's concurrent disaster workload affects household recovery only through declaration timing, not directly. Conditional on own-disaster severity (damage, type, geography), the number of other disasters FEMA is processing is plausibly orthogonal to individual household outcomes.
- **Unit of analysis:** Disaster-level (N≈104) for first stage; zip-code × disaster for reduced form with larger N.

**Reduced form backup:** OLS with declaration lag as continuous treatment, controlling for disaster severity, type, state, and year FE.

## Expected Effects and Mechanisms

- **Direction:** Longer declaration lags → worse household outcomes (lower assistance, more displacement)
- **Mechanism:** Declaration is the legal prerequisite for Individual Assistance. Until declaration, households cannot register for FEMA assistance. Delays → delayed assistance → longer displacement, more uninsured losses, capacity constraints at registration
- **Magnitude prior:** With mean lag of 43 days and SD of 44, a 1-SD increase in lag (~44 days) could plausibly reduce per-household assistance by 5-15% through delayed registration and exhaustion of temporary coping strategies

## Primary Specification

**First stage:**
`declaration_lag_d = α + δ × concurrent_disasters_d + X_d'γ + ε_d`

**Second stage:**
`outcome_zd = β₀ + β₁ × declaration_lag_hat_d + X_d'β₂ + μ_s + τ_y + ε_zd`

Where:
- d = disaster, z = zip code, s = state, y = year
- X_d = disaster controls (type, damage severity, population affected)
- μ_s = state fixed effects, τ_y = year fixed effects

**Key outcomes:**
1. Per-registrant IHP assistance amount
2. Average FEMA-inspected damage (conditional on application)
3. Approval rate (share deemed eligible)
4. Rental assistance amount (displacement proxy)

## Data Sources

All from OpenFEMA (free, keyless APIs):
1. `DisasterDeclarationsSummaries` — 69,706 records; disaster dates, types, FIPS codes
2. `HousingAssistanceOwners` — city-level aggregates: registrations, damage, assistance amounts
3. `RegistrationIntakeIndividualsHouseholdPrograms` — city-level IHP aggregates
4. `IndividualAssistanceHousingRegistrantsLargeDisasters` — 6.4M individual registrant records (large disasters only)

## Robustness Checks

1. Exclude politically salient hurricanes (Katrina, Sandy, Harvey, Maria, Ian)
2. Placebo: non-IHP declarations (Fire Management Assistance)
3. Heterogeneity by disaster type (hurricane vs flood vs tornado vs wildfire)
4. Control for FEMA-inspected damage at zip level
5. Alternative IV: lagged FEMA workload (disasters declared in prior 30 days)
6. Wild cluster bootstrap for inference (clustering at disaster level with ~104 clusters)
