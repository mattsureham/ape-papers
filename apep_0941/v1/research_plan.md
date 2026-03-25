# Research Plan: ACICS Collapse and Community College Racial Absorption

## Research Question
Did the September 2016 revocation of ACICS accreditation — the largest accreditor collapse in US history, displacing ~600,000 students from ~247 for-profit institutions — lead to enrollment increases at nearby community colleges? Did absorption differ by race/ethnicity, given that ACICS institutions disproportionately served Black and Hispanic students?

## Identification Strategy
**Geographic continuous-treatment DiD.** Treatment intensity = pre-collapse ACICS enrollment per capita in each county. Post = academic years 2017–2022 (the ACICS revocation was September 22, 2016; most closures occurred 2016–2018). Control = counties with zero ACICS exposure. Within-county over-time variation in community college enrollment by race identifies the absorption effect.

**Primary specification:**
```
ΔEnroll_{c,t,r} = α_c + δ_t + γ_r + β₁(ACICSExposure_c × Post_t)
                  + β₂(ACICSExposure_c × Post_t × Minority_r) + X'_{c,t}θ + ε_{c,t,r}
```

where c = county, t = academic year, r = race/ethnicity group.

**Threats:**
1. Secular for-profit enrollment decline (Obama-era regulations): controlled by county FE and national time trends; only geographic differential matters.
2. Local economic shocks: include county-level unemployment controls.
3. ACICS institution location endogeneity: use pre-period balance tests; parallel trends in community college enrollment should hold if location selection is time-invariant.

**Placebo tests:**
- 4-year public university enrollment in treatment counties (should not respond — different student population)
- Pre-trend test: 2010–2015 parallel trends in community college enrollment

## Expected Effects
- **Partial absorption:** Community colleges in ACICS-proximate counties should show modest enrollment increases, especially for Black and Hispanic students. But many displaced students likely dropped out entirely, so absorption rate < 100%.
- **Racial differential:** Black and Hispanic students may show larger community college absorption if they have fewer alternative options; or smaller absorption if displacement barriers are higher.
- **Lag structure:** Absorption should peak 1–2 years after ACICS revocation (2017–2018) as institutions close and Title IV eligibility lapses.

## Primary Specification
Standard TWFE DiD with continuous treatment intensity (single treatment timing — Callaway-Sant'Anna not needed). Cluster SEs at state level. Robustness: wild cluster bootstrap.

## Data Source and Fetch Strategy
All data from IPEDS DuckDB on Azure (`raw/ipeds/ipeds.duckdb`):
1. **HD tables (2010–2022):** Institution characteristics, FIPS codes, sector classification, accreditor
2. **EF_A tables (2010–2022):** Enrollment by race/ethnicity at institution-year level
3. **Construct treatment:** Identify ACICS institutions from HD2015/HD2016, aggregate their enrollment by county
4. **Construct outcomes:** Community college (sector = public 2-year) enrollment by race, aggregated to county-year

No external API calls needed — all data is local DuckDB.
