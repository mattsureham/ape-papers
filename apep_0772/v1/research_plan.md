# Research Plan: Fair Workweek Laws and the Black-White Employment Gap in Food Service

## Research Question

Do predictive scheduling mandates ("Fair Workweek" laws) differentially improve employment outcomes for Black workers in food service? If schedule uncertainty imposes disproportionate costs on workers with fewer outside options and more binding childcare/transportation constraints, mandating schedule stability should close racial employment gaps in the affected sector.

## Identification Strategy

**Triple-Difference (DDD):** county × quarter × race

- **First difference:** Treated vs. control counties (jurisdictions with Fair Workweek laws vs. those without)
- **Second difference:** Pre vs. post law adoption (staggered timing)
- **Third difference:** Black non-Hispanic (A2/A1) vs. All non-Hispanic (A0/A1) workers

The third difference absorbs county-level shocks that affect all races equally (e.g., local economic conditions, COVID), isolating race-differential effects of the scheduling mandate.

**Estimator:** Callaway-Sant'Anna (2021) for heterogeneous treatment timing, applied to the DDD specification.

**Treatment timing (pre-COVID focus):**
- San Francisco: Q3 2015
- Seattle: Q3 2017
- New York City (fast food): Q4 2017
- Oregon (statewide): Q3 2018

COVID-era adopters (Philadelphia Q2 2020, Chicago Q3 2020, NYC retail Q1 2021) used in robustness only.

**Fixed effects:** county × race, quarter × race, state × quarter

**Key identifying assumption:** The Black-to-total employment ratio in NAICS 72 (food service) would have evolved similarly in treated and control counties absent the law. Tested via event-study pre-trends.

## Expected Effects and Mechanisms

1. **Employment (EmpEnd):** Positive DDD — Black employment rises relative to all workers in treated counties. Mechanism: schedule predictability disproportionately benefits workers facing binding constraints (childcare, second jobs).
2. **Earnings (EarnS):** Positive DDD — predictability pay and more stable hours increase Black worker earnings.
3. **Separations (Sep):** Negative DDD — fewer Black worker quits when schedules are predictable.
4. **Hires (HirA):** Ambiguous — could rise (more applicants attracted) or fall (fewer openings if firms retain more).
5. **Turnover (TurnOvrS):** Negative DDD — mechanism test for retention channel.

## Primary Specification

Y_{cqr} = β × (Treat_cq × Black_r) + γ × Treat_cq + δ × Black_r + α_{cr} + θ_{qr} + λ_{sq} + ε_{cqr}

Where:
- Y = employment/earnings/separations outcome in county c, quarter q, race r
- Treat_cq = 1 if county c has Fair Workweek law in effect in quarter q
- Black_r = 1 if race = Black non-Hispanic (A2/A1)
- α_{cr} = county × race FE
- θ_{qr} = quarter × race FE
- λ_{sq} = state × quarter FE
- Clustering: state level (to account for within-state correlation of treatment)

## Data Source and Fetch Strategy

**Primary:** QWI race/ethnicity × industry panel from Azure:
- Path: `az://apepdata/derived/qwi/rh/ns/*.parquet`
- Variables: EmpEnd, EarnS, HirA, Sep, TurnOvrS
- Filters: NAICS 72 (food service), race ∈ {A0, A2}, ethnicity = A1 (non-Hispanic)
- Period: 2013 Q1 – 2022 Q4

**Placebo industry:** NAICS 23 (construction) — high Black worker concentration, NOT covered by Fair Workweek laws.

**Treatment crosswalk:** City → county FIPS mapping:
- San Francisco = FIPS 06075
- Seattle → King County = FIPS 53033
- NYC → 5 boroughs = FIPS 36005, 36047, 36061, 36081, 36085
- Oregon = all counties with state FIPS 41
- Philadelphia = FIPS 42101
- Chicago → Cook County = FIPS 17031

## Robustness Checks

1. Event-study pre-trends (8+ pre-quarters for 2017 adopters)
2. Pre-COVID-only sample (drop Philadelphia, Chicago, NYC retail)
3. NAICS 23 (construction) placebo — should show null DDD
4. Wild cluster bootstrap (state-level, few treated clusters)
5. Randomization inference (permute treatment assignment across states)
6. Bacon decomposition (TWFE diagnostic)
7. Leave-one-out by treatment group (e.g., drop Oregon)
