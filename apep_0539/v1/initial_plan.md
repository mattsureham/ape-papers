# Initial Research Plan: Less Cash, Less Crime?

## Research Question

Did the staggered adoption of Electronic Benefit Transfer (EBT) — replacing paper food stamps with PIN-protected debit cards — reduce property crime by eliminating food stamps as a black-market currency?

## Identification Strategy

**Design:** Callaway-Sant'Anna (2021) staggered DiD across all 51 US jurisdictions, with county-level crime outcomes. Treatment is state-level EBT adoption year (from USDA ERS SNAP Policy Database), with 10-year staggered rollout (1996-2005).

**Key insight:** Paper food stamps were liquid, anonymous, and routinely stolen or traded at ~$0.50 on the dollar. EBT cards require a PIN, are non-transferable, and are electronically tracked — destroying this underground currency overnight.

**Plausible exogeneity:** Adoption timing driven by federal compliance deadlines and state IT procurement capacity, not by crime trends. We test this formally.

## Expected Effects and Mechanisms

- **Primary:** Reduction in burglary and robbery rates (food stamps stolen from homes and persons)
- **Secondary:** Reduction in larceny-theft (fencing/trading of stolen stamps)
- **Null expected:** Motor vehicle theft, arson (no mechanism linking EBT to these crimes)
- **Dose-response:** Larger effects in high-SNAP-caseload counties (more "currency" destroyed)
- **Heterogeneity:** Larger effects in urban counties (thicker black markets)

## Exposure Alignment

- **Who is treated:** SNAP recipients whose paper stamps are replaced by EBT cards
- **Primary estimand population:** County-level crime rates (treatment captures removal of theft target)
- **Placebo/control population:** Crimes unrelated to food stamp theft (motor vehicle theft, arson)
- **Design:** Staggered DiD (all units eventually treated, 10-year adoption window)

## Primary Specification

Y_{c,t} = alpha + ATT(g,t) from CS-DiD + X_{c,t} * gamma + delta_c + tau_t + epsilon_{c,t}

Where:
- Y: county crime rate per 100,000 (burglary, robbery, larceny, total property)
- g: state-level EBT adoption cohort year
- X: time-varying controls (population, unemployment, poverty rate, police per capita)
- delta_c, tau_t: county and year fixed effects
- Clustering: state level (treatment varies at state level)

## Power Assessment

- Pre-treatment periods: 10+ years (1985-1995 for earliest adopters)
- Treated clusters: 51 states (all eventually treated)
- Counties: ~3,100 (within-state variation in crime levels and SNAP intensity)
- Post-treatment periods per cohort: varies by adoption year (5-15 years)
- Property crime rates in 1990s: ~4,000-5,000 per 100,000 — substantial variation

## Planned Robustness Checks

1. **Event-study dynamics** with CS-DiD group-time ATTs
2. **Bacon decomposition** of TWFE estimates
3. **Rambachan-Roth HonestDiD** sensitivity to parallel trends violations
4. **Randomization inference** for p-values
5. **Timing exogeneity test:** Regress adoption year on pre-period state characteristics
6. **State-specific linear trends** as additional control
7. **Leave-one-out sensitivity** (drop each state)
8. **Crime-type decomposition:** Mechanism-aligned vs. placebo outcomes
9. **Dose-response:** Interaction with pre-EBT SNAP caseload per capita
10. **Controlling for concurrent reforms:** TANF implementation, COPS hiring grants

## Data Sources

| Source | Variable | Granularity | Period |
|--------|----------|-------------|--------|
| USDA ERS SNAP Policy Database | EBT adoption dates | State-month | 1996-2020 |
| FBI UCR (via ICPSR/Crime Data Explorer) | Crime counts by type | County-year | 1985-2010 |
| Census ACS/Decennial | Population, demographics | County-year | 1990-2010 |
| BLS LAUS | Unemployment rate | County-year | 1990-2010 |
| USDA SNAP annual data | Caseload, participation | State-year | 1990-2010 |

## Analysis Scripts

- `00_packages.R` — Load libraries
- `01_fetch_data.R` — Download UCR, SNAP Policy DB, controls
- `02_clean_data.R` — Merge, construct treatment variables, panel
- `03_main_analysis.R` — CS-DiD, TWFE, event studies
- `04_robustness.R` — All robustness checks
- `05_figures.R` — Event studies, maps, mechanism plots
- `06_tables.R` — All regression tables
