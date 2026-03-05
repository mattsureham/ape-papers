# Initial Research Plan — apep_0531

## Research Question

Do Police Community Support Officers (PCSOs) reduce crime? England's austerity-driven PCSO cuts (2010-2024) varied enormously across police force areas — from near-total elimination to relative preservation. This paper exploits that cross-force variation to estimate the first national-scale causal effect of community-oriented civilian policing on crime.

## Identification Strategy

**Design:** Dose-response difference-in-differences across 43 English and Welsh police force areas, 2007-2024.

**Treatment:** Change in PCSO FTE per 100,000 population (continuous, force × year).

**Key identifying assumption:** Conditional on force FE, year FE, region×year FE, sworn officer FTE changes, and local covariates (population, deprivation), the timing and magnitude of PCSO cuts are uncorrelated with latent crime trends.

**Instrument (Bartik/shift-share):** Pre-2010 share of force funding from central government grants × annual national grant cut magnitude. Forces more dependent on Home Office grants had less fiscal capacity to protect PCSOs via council tax precepts.

**Primary specification:**
```
CrimeRate_{ft} = β₁ × PCSO_FTE_per100k_{ft} + β₂ × OfficerFTE_per100k_{ft} + γ_f + δ_t + ρ_{r(f),t} + X'_{ft}θ + ε_{ft}
```
Where f=force, t=year, r=region. β₁ is the parameter of interest. Including sworn officer FTE (β₂) isolates the PCSO-specific effect from total police workforce changes.

## Expected Effects and Mechanisms

**Hypothesis:** PCSO cuts increase crime, particularly for crime types where visible community presence and local intelligence are important (ASB, burglary, low-level violence). Effects on "hidden" crimes (domestic abuse, fraud) should be null or smaller.

**Mechanism channels:**
1. **Visible deterrence:** PCSOs patrol neighbourhoods in uniform; their removal reduces perceived detection risk for opportunistic offenders.
2. **Community intelligence:** PCSOs gather local intelligence through community engagement; their removal degrades police awareness of emerging criminal activity.
3. **Procedural justice:** PCSO presence builds community trust in policing; their removal may reduce crime reporting and cooperation.

## Exposure Alignment (DiD)

- **Who is treated?** Residents and potential offenders in police force areas that lost PCSOs.
- **Primary estimand population:** All force areas, weighted by PCSO cut intensity.
- **Placebo populations:** (a) Crime types unaffected by visible patrol (online fraud, cybercrime); (b) Force areas with stable PCSO numbers (limited treatment).
- **Design:** Dose-response DiD (continuous treatment × force × year FEs). NOT binary treatment.

## Power Assessment

- **Pre-treatment periods:** 3 years (2007-2009, pre-austerity)
- **Treated clusters:** 43 force areas with varying treatment dose (most forces cut PCSOs substantially; a few maintained numbers)
- **Post-treatment periods:** 15 years (2010-2024)
- **Total observations:** ~43 × 18 = 774 force-years
- **Expected MDE:** With 43 clusters and force-year panel, expect to detect effects ≥5-8% of baseline crime rates. The Ariel et al. (2016) RCT found ~39% crime reduction from PCSO hot-spot patrols, so even 10-20% of that micro-level effect is detectable at force level.

## Planned Robustness Checks

1. **Pre-trend validation:** Event-study with leads showing flat crime trends before PCSO cuts (2007-2009).
2. **Bartik IV:** Instrument PCSO cuts with pre-2010 grant dependence × national cut.
3. **Leave-one-out jackknife:** Drop each force; coefficient stability.
4. **Drop Metropolitan Police:** Largest force by far (~25% of PCSOs).
5. **Wild cluster bootstrap:** 43 clusters → `fwildclusterboot` for finite-sample correction.
6. **Randomization inference:** Permute treatment across forces (1,000 iterations).
7. **HonestDiD:** Rambachan & Roth sensitivity to parallel trends violations.
8. **Spillovers:** Include spatially-weighted neighbor-force PCSO changes.
9. **Crime type decomposition:** Separate regressions by crime type → mechanism test.
10. **Detection rates:** Effect on clearance/sanction rates.

## Data Sources

| Data | Source | Years | Granularity |
|------|--------|-------|-------------|
| PCSO + Officer FTE | Home Office workforce ODS | 2007-2025 | Force × year |
| Recorded crime by type | ONS PFA tables + Home Office open data | 2007-2024 | Force × year × crime type |
| Population | ONS mid-year estimates | 2007-2024 | Force area |
| Deprivation | MHCLG IMD | 2010, 2015, 2019 | LSOA→Force |
| Council tax precepts | Home Office | 2012-2024 | PCC area |
