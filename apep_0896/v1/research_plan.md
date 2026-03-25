# Research Plan: Does the Right to Repair Create Repairers?

## Research Question

Do electronics right-to-repair (RTR) laws expand the independent repair market? Specifically, do states that mandate manufacturers provide diagnostic tools, parts, and schematics to independent repair shops experience growth in repair-sector establishments, employment, and wages?

## Policy Background

Between 2022 and 2025, several US states enacted electronics right-to-repair legislation:
- **New York:** Digital Fair Repair Act, effective July 1, 2023
- **California:** SB 244, effective July 1, 2024
- **Minnesota:** SF 2744, effective July 1, 2024
- **Oregon:** SB 1596, effective January 1, 2025
- **Colorado:** HB 24-1121, effective January 1, 2025

These laws require original equipment manufacturers (OEMs) to make diagnostic tools, parts, and repair documentation available to independent repair providers and consumers. ~45 states have not enacted such legislation, providing a large never-treated control group.

## Identification Strategy

**Design:** Staggered difference-in-differences using Callaway and Sant'Anna (2021).

**Treatment:** Binary indicator for whether a state has an effective RTR law. Three treatment cohorts: 2023Q3 (NY), 2024Q3 (CA, MN), 2025Q1 (OR, CO).

**Control group:** ~45 never-treated states + DC.

**Key assumption:** Parallel trends in repair-sector outcomes between treated and never-treated states, conditional on state and time fixed effects.

**Placebo:** NAICS 8111 (Automotive Repair & Maintenance) — a repair sector unaffected by electronics RTR laws. If the treatment effect appears in automotive repair, the identification is suspect.

## Expected Effects and Mechanisms

**Theory is ambiguous:**
1. **Entry channel:** RTR reduces barriers for independent repair shops by mandating access to parts/schematics → more establishments, more employment
2. **Absorption channel:** OEMs may integrate repair services in response → independent entry suppressed, OEM employment rises
3. **Null hypothesis:** RTR laws may be too new or weakly enforced to have measurable effects in the short run

## Primary Specification

ATT estimated via Callaway-Sant'Anna with never-treated controls:
- Y: log(establishments), log(employment), log(average weekly wage) in NAICS 8112
- Unit: state × quarter
- Treatment cohorts: 2023Q3, 2024Q3, 2025Q1
- Inference: state-clustered SEs, wild cluster bootstrap, randomization inference

## Robustness
1. Placebo outcome: NAICS 8111 (Automotive Repair)
2. Rambachan-Roth sensitivity for parallel trends violations
3. Leave-one-out (drop NY, which dominates the treated group)
4. Alternative estimator: Sun-Abraham via fixest::sunab()
5. Pre-trend event study (unconditional)

## Heterogeneity
- States with large vs. small pre-existing repair sectors (above/below median NAICS 8112 employment share)

## Data Sources
1. **BLS QCEW API:** NAICS 8112 (Electronic & Precision Equipment Repair) and NAICS 8111 (Automotive Repair), quarterly, all states, 2019Q1–2025Q2 (latest available)
2. **Census CBP:** Annual establishment counts for pre-period validation
3. **BLS CPI:** Appliance repair price series (consumer price channel)

## Outcome Variables
- `estabs`: Number of establishments (NAICS 8112)
- `emp`: Average monthly employment (NAICS 8112)
- `avg_wkly_wage`: Average weekly wage (NAICS 8112)

## Design Parameters
- Treated units: 5 states (staggered across 3 cohorts)
- Never-treated controls: ~46 states + DC
- Pre-periods: 18 quarters for NY cohort, 22 for CA/MN, 24 for OR/CO
- Post-periods: ~8 quarters for NY, ~4 for CA/MN, ~2 for OR/CO
