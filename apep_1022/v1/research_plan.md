# Research Plan: The Long Shadow of Colorblindness

## Research Question

Do state-level bans on affirmative action in public university admissions reduce minority enrollment, and do displaced students cascade to less-selective institutions? We exploit the staggered adoption of bans across 9 US states (1996–2020) using modern heterogeneity-robust DiD estimators.

## Contribution

Hinrichs (2012) — the only multi-state study — uses biased TWFE on 5 states through 2008 and finds small, mostly insignificant effects. We update and overturn this with: (1) Callaway-Sant'Anna (2021) estimator correcting for heterogeneous treatment effects, (2) 26 years of IPEDS data covering all 9 ban states, (3) a cascade analysis showing where displaced minority students enroll, and (4) post-SFFA implications for the national policy landscape.

## Identification Strategy

**Design:** Staggered difference-in-differences
**Estimator:** Callaway & Sant'Anna (2021)
**Treatment:** State-level ban on race-conscious admissions
**Treated states (9):** CA (1998), WA (1999), FL (2000), MI (2007), NE (2009), AZ (2011), NH (2012), OK (2013), ID (2020)
**Treatment timing note:** Prop 209 passed in 1996 but enrollment effects begin 1998 (first admitted class). Timing coded to first affected enrollment year.
**Control group:** Public 4-year institutions in never-ban states (pre-SFFA)
**Unit of observation:** Institution × year

**Exposure alignment:** Treatment is assigned at the state level but measured at the institution level. All public four-year institutions within a ban state are affected, as bans prohibit race-conscious admissions across the entire public university system. The treatment timing is the first fall enrollment year after the ban takes legal effect — this is when the first cohort admitted under colorblind policies enrolls. Selective institutions with holistic review processes are more directly affected, while open-enrollment campuses may see minimal operational change.

**Key assumptions:**
1. Parallel trends: minority enrollment share would have evolved similarly absent the ban
2. No anticipation: institutions don't change admissions before legal mandate
3. SUTVA: bans in one state don't affect enrollment in other states (test with cross-border enrollment)

## Expected Effects and Mechanisms

1. **Direct effect:** Bans reduce Black and Hispanic enrollment share at selective public institutions
2. **Cascade:** Displaced students enroll at less-selective public institutions (within-state reallocation)
3. **Heterogeneity by selectivity:** Effects concentrated at highly selective institutions
4. **Dynamic effects:** Possible intensification over time as institutional culture and recruitment change

## Primary Specification

```
ATT(g,t) estimated via Callaway-Sant'Anna
Y_it = minority_enrollment_share (Black, Hispanic)
Treatment: first year of ban-affected enrollment
Covariates: state-level unemployment rate, cohort size (18-24 population)
Clustering: state level
```

## Data Sources

### Primary: IPEDS Fall Enrollment Survey (2000–2022)
- Source: NCES bulk download (CSV)
- Variables: institution ID, year, enrollment by race/ethnicity, total enrollment
- Coverage: ~700+ public 4-year institutions, 23 years
- Access: Free, no API key needed

### Supplementary: IPEDS Institutional Characteristics
- Selectivity tier (admissions rate pre-ban)
- Carnegie classification
- Institution type (flagship, regional, HBCU)

### Supplementary: ACS (via Census API)
- State-level 18-24 population by race (denominator for enrollment rates)
- State-level educational attainment trends

## Fetch Strategy

1. Download IPEDS bulk CSV files for Fall Enrollment (EF tables) 2000–2022
2. Download IPEDS Institutional Characteristics (HD/IC tables) for selectivity
3. Query ACS API for state-level demographics
4. Merge and construct panel

## Tables (max 5 + SDE appendix)

1. **Table 1:** Summary statistics — institutions, enrollment, selectivity by ban/non-ban states
2. **Table 2:** Main CS ATT estimates — Black and Hispanic enrollment share
3. **Table 3:** Cascade analysis — effects by institution selectivity quintile
4. **Table 4:** Dynamic treatment effects (event-study coefficients)
5. **Table 5:** Robustness — TWFE comparison, placebo (White enrollment, private institutions)
6. **SDE Appendix:** Standardized effect sizes
