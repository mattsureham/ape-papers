# Research Plan: Immigration Judge Leniency and Local Crime

## Research Question
Does exogenous variation in asylum grant rates — driven by the quasi-random assignment of cases to judges with vastly different grant rates — predict local crime rates?

## Identification Strategy
**Judge Leniency Instrumental Variable (Cross-Sectional)**

Within each immigration court, cases are assigned to judges through a rotation system that is effectively random conditional on court and time period. Judge grant rates vary enormously within the same courthouse (New York: 1.5% to 49.4%; Los Angeles: 3.0% to 26.4%).

- **Instrument:** Caseload-weighted average career grant rate of judges assigned to courts in each state
- **Endogenous variable:** State-level asylum grant rate
- **Outcome:** State-level homicide rate (CDC Mapping Injury, 2019-2024)
- **Controls:** Log population, foreign-born population share, Census region FE
- **Key assumption:** Conditional on state-level controls, the composition of judges at courts (and hence average leniency) is uncorrelated with local crime determinants except through asylum decisions

**Placebos:**
1. Judge leniency should NOT predict pre-existing state demographics
2. Judge leniency should NOT predict suicide rate (non-immigration-related)
3. Balance test: judge leniency uncorrelated with poverty, unemployment

## Expected Effects
The sign is theoretically ambiguous:
- **Positive (crime increases):** If asylum recipients include some who commit crimes; if rapid population growth strains services
- **Negative (crime decreases):** If asylum recipients are positively selected; if stable legal status reduces criminality relative to undocumented status
- **Null:** If immigration has no meaningful effect on crime, consistent with most prior literature (Ousey & Kubrin 2018 meta-analysis)

A null result is a valid and important contribution — it would provide the first IV evidence consistent with the descriptive literature.

## Primary Specification
```
homicide_rate_s = α + β * grant_rate_s + γ * X_s + region_FE + ε_s
```
where `grant_rate_s` is instrumented by `judge_leniency_s` (caseload-weighted average judge grant rate).

## Data Sources
1. **OpenImmigration.us APIs** — 88 courts, 1,269 judges with career grant rates
2. **CDC Mapping Injury** (Socrata: `psx4-wq38`) — County-level All_Homicide rates, 2019-2024
3. **ACS via tidycensus** — State-level demographics (population, foreign-born, poverty)

## Design Parameters
- N: ~40 states with immigration courts
- Courts: 88 across ~40 states
- Judges: 1,269 (1,116 with 1,000+ decisions)
- First-stage F: expected >>10 (judge leniency strongly predicts grant rates by construction)
- Clustering: Robust (HC1) standard errors
