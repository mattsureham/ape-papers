# Research Plan: Beyond the Extensive Margin — State EITCs and Industry Reallocation

## Research Question
Do state Earned Income Tax Credits shift low-educated women's employment across industries? While the vast EITC literature studies whether the EITC moves women into or out of the labor force (extensive margin), nobody has asked: conditional on employment, does the EITC change WHERE women work?

## Identification Strategy
**Staggered DiD with Callaway-Sant'Anna (2021)**

- Treatment: state-level adoption of EITC supplement (28 states, 1984-2018)
- Control: 22 never-treated states (using "never treated" control group)
- QWI data window: 2001-2023 (13 post-2001 adopters provide event study variation)
- Unit: state × year
- Outcomes: industry employment shares for low-education women (E1+E2)
- SEs clustered at the state level

## Expected Effects and Mechanisms
- **Main hypothesis**: EITC phase-in incentivizes earnings increases; low-edu women may shift from low-wage sectors (food services, retail) to higher-wage sectors (healthcare, admin)
- **Alternative 1**: No industry reallocation — EITC only affects extensive margin
- **Alternative 2**: Perverse reallocation — phase-out creates high MTRs that discourage moving to higher-wage sectors
- **Triple-diff**: low-edu women (E1+E2) vs high-edu women (E4+E5) within the same state — high-edu women less affected by EITC

## Primary Specification
Y_{st} = α_s + γ_t + β × EITC_st + ε_st

Where Y_st = share of low-edu female employment in industry i in state s, year t.
Using CS group-time ATT: ATT(g,t) for each treatment cohort g and calendar time t.

## Data Sources
1. **QWI (Quarterly Workforce Indicators)** on Azure: `az://derived/qwi/se/ns/*.parquet`
   - 51 state files, 123M rows, 2001-2025
   - State × county × quarter × industry × sex × education breakdowns
   - Key variables: Emp (employment), EarnS (earnings)

2. **State EITC adoption dates**: from NBER TAXSIM, hardcoded
   - 28 treated states + DC, 22 never-treated
   - Adoption years: 1984-2018, 16+ cohorts

## Robustness Checks
1. Triple-diff with high-edu women as within-state placebo
2. Dose-response using EITC generosity (% of federal)
3. Placebo outcomes: manufacturing (non-service sector)
4. Men as placebo group (less EITC-affected)
5. Event study pre-trends (4+ years pre-treatment for post-2006 adopters)
6. Wild cluster bootstrap (51 state clusters)
