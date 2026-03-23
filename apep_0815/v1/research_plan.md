# Research Plan: apep_0815/v1

## Title
The Compliance Gap: Do SNAP Work Requirements for Older Adults Create Jobs or Just Cut Benefits?

## Research Question
The Fiscal Responsibility Act of 2023 extended SNAP ABAWD (Able-Bodied Adults Without Dependents) time limits from ages 18–49 to ages 18–54, in three legislatively specified steps (age 50 in Sep 2023, 52 in Oct 2023, 54 in Oct 2024). Did this expansion increase formal employment among newly affected older adults, or did it primarily reduce food assistance without improving labor market outcomes? The gap between SNAP exits and employment gains — the "compliance gap" — determines whether work requirements function as employment policy or de facto benefit cuts.

## Identification Strategy
**Triple-difference (DDD):**
1. **Age:** QWI age group 45–54 (half newly treated: 50–54) vs 55–64 (never subject to ABAWD)
2. **Time:** Pre-FRA (2018Q1–2023Q2) vs post-FRA (2023Q3–2024Q4)
3. **State enforcement:** Full ABAWD reinstatement (~17 states with no waivers) vs statewide waiver (12 states where the age expansion has no bite)

The DDD absorbs: (a) age-specific employment trends (older workers aging out anyway), (b) state-level economic shocks (common to both age groups), (c) national time effects (post-COVID recovery affecting all groups).

**Key assumption:** Parallel trends between 45–54 and 55–64 age groups in enforcing vs waivered states before FRA. Testable with 22 pre-treatment quarters.

**Dilution note:** QWI reports ages 45–54 as one bin. Since 45–49 was already subject to ABAWD, only ~half the treated bin is newly affected. The ITT estimate on the 45–54 bin understates the effect on newly-affected 50–54 year olds by ~50%. Report both the ITT and a rescaled LATE.

## Expected Effects and Mechanisms
**If work requirements bind as employment policy:**
- Employment rises for 45–54 in enforcing states (positive DDD coefficient)
- New hires increase (people entering formal labor market)
- Earnings may increase (though from a low base)

**If work requirements function as benefit cuts:**
- Little or no employment effect (DDD ≈ 0)
- SNAP participation declines (first-stage evidence from USDA data)
- Compliance gap is large: people leave SNAP but don't enter employment

**Most likely:** Small positive employment effect that is far smaller than the SNAP participation decline — i.e., a substantial compliance gap.

## Primary Specification
```
log(Emp_{s,a,t}) = α + β₁(Post_t × Young_a × Enforce_s) +
                   β₂(Post_t × Young_a) + β₃(Post_t × Enforce_s) +
                   β₄(Young_a × Enforce_s) + γ_{s,a} + δ_{a,t} + θ_{s,t} + ε_{s,a,t}
```
Where:
- s = state, a = age group (45–54 vs 55–64), t = quarter
- Post = 1 if t ≥ 2023Q3
- Young = 1 if age group is 45–54
- Enforce = 1 if state has full ABAWD enforcement
- γ_{s,a} = state × age FE, δ_{a,t} = age × quarter FE, θ_{s,t} = state × quarter FE
- Cluster SEs at the state level

## Data Sources

### Primary: Census QWI (Quarterly Workforce Indicators)
- **API:** Census QWI REST API (`https://api.census.gov/data/timeseries/qwi/sa`)
- **Variables:** Emp (employment), HirA (all hires), Sep (separations), EarnS (avg monthly earnings)
- **Dimensions:** State × age group (agegrp=A06 [45-54], A07 [55-64]) × quarter
- **Coverage:** 2018Q1–2024Q4 (28 quarters)
- **Note:** Must loop per-industry for multi-industry requests (HTTP 204 bug); use CENSUS_API_KEY

### Treatment Assignment: ABAWD Enforcement Classification
- **Source:** FNS ABAWD waiver status tables (FY2024)
- **Classification:**
  - Full enforcement (~17 states): No waivers, all ABAWDs subject to time limits
  - Statewide waiver (12 states): Time limits not enforced (e.g., CA, NY)
  - Partial waiver (22 states): Some areas waived — sensitivity analysis

### Descriptive: USDA FNS SNAP Data
- **Source:** USDA Food and Nutrition Service, SNAP data tables
- **Use:** State-level monthly SNAP participation for aggregate first-stage context

## Robustness Checks
1. **Event-study DDD:** Quarter-by-quarter β₁ coefficients (pre-trend test)
2. **Alternative control group:** Ages 35–44 instead of 55–64
3. **Partial-waiver states:** Include or exclude
4. **Industry heterogeneity:** DDD by industry sector (food service, retail — where SNAP-eligible adults cluster)
5. **Phase-specific effects:** Separate estimates for Phase 1 (Sep 2023) vs Phase 2 (Oct 2023) vs Phase 3 (Oct 2024)
6. **Placebo age group:** DDD on 25–34 vs 35–44 (both always-subject; should show no differential effect)
