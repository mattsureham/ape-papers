# Research Plan: The Economic Integration Lottery

## Research Question

Does granting legal immigration status to asylum seekers improve local labor markets? Specifically: when immigration judges grant more asylum cases in a court's jurisdiction, do local employment, wages, and business formation respond?

## Identification Strategy

**Instrument: Immigration judge leniency (UJIVE)**

Within each EOIR immigration court, cases are quasi-randomly assigned to judges (confirmed by GAO 2008, 2017). Judges vary dramatically in leniency — the median within-court grant rate disparity is 56 percentage points (TRAC 2024). We exploit this variation using a leave-one-out judge leniency instrument.

**Construction:**
1. For each judge j in court c, year t: compute leave-one-out grant rate (excluding case i)
2. Aggregate to court × year: weighted average leniency of judges hearing cases at court c in year t
3. This instruments for the actual asylum grant rate at court c in year t
4. Link court × year to county × year outcomes via court-county crosswalk

**First stage:** 56-pp within-court variation → expect F-stat >> 10 (far stronger than bail judges ~5 pp or SSDI ALJs ~15 pp).

**Exclusion restriction:** Conditional on court × year FE, judge identity affects county outcomes only through the grant decision. Random assignment ensures no selection on unobservables.

**Estimand:** LATE — the effect of granting asylum to marginal applicants (those whose outcome depends on judge assignment).

## Expected Effects and Mechanisms

1. **Direct channel:** Asylum grant → work authorization → labor force entry → employment in low-wage services
2. **Indirect channel:** Legal workers → business formation (entrepreneurs) and labor supply in accommodation/food services
3. **Null expectation for high-wage sectors:** Finance (NAICS 52) and Professional Services (NAICS 54) should not respond to low-skill asylum labor supply → built-in placebo
4. **Noncitizen population:** ACS data should confirm that higher grant rates increase local noncitizen/foreign-born population

**Direction:** Expect positive effects on total employment and establishment counts; ambiguous on wages (depends on whether new labor supply or new demand dominates).

## Primary Specification

$$Y_{c,t} = \alpha + \beta \cdot \widehat{GrantRate}_{court(c),t} + \gamma_{court} + \delta_t + X'_{c,t}\theta + \varepsilon_{c,t}$$

Where:
- $Y_{c,t}$: county-level outcome (employment, wages, establishments)
- $\widehat{GrantRate}$: instrumented by leave-one-out judge leniency
- $\gamma_{court}$: court fixed effects
- $\delta_t$: year fixed effects
- $X'_{c,t}$: time-varying county controls (baseline demographics interacted with trends)

**Clustering:** Two-way clustering at court and year levels.

## Method Notes (IV — no pre-built guide)

### Identification assumption
Judge assignment within courts is as-good-as-random. The instrument (judge leniency) affects outcomes only through the asylum grant decision.

### Required validity checks
1. **First-stage F-statistic** (effective F for many instruments): Must exceed 10; expect >> 10 given 56-pp variation
2. **Balance test:** Judge leniency should not predict pre-determined county characteristics (demographics, pre-period employment levels)
3. **Monotonicity:** More lenient judges should weakly increase grant rates for all case types (testable by examining judge effects across nationalities)
4. **Exclusion restriction support:** Placebo outcomes (high-wage sectors) should show no response
5. **Leave-one-out stability:** Results stable to dropping individual courts/judges
6. **Overidentification test:** If using multiple instruments (judge leniency by nationality group), Hansen J test

### Common pitfalls
- Many-instrument bias: Standard 2SLS biased toward OLS with many judges. Use UJIVE or LIML.
- Weak instrument bias: Less likely here given 56-pp variation, but report effective F
- Measurement error in aggregation: Court-to-county mapping introduces noise → use robust crosswalk
- Reflection problem: Court caseload may respond to local conditions → instrument addresses this

### R packages and code patterns
- `fixest::feols()` with `| court + year` FE syntax and `~judge_leniency` IV
- Manual UJIVE implementation via leave-one-out residualization
- `ivreg` package as backup
- `sandwich` / `clubSandwich` for two-way clustered SEs

### Key papers to cite
- Kling (2006): Incarceration judge IV → recidivism
- Dobbie, Goldin, Yang (2018): Bail judge IV → pretrial detention effects
- Maestas, Mullen, Strand (2013): SSDI ALJ IV → disability benefits effects
- Kolesár (2013): UJIVE estimator for many-instrument settings
- Dahl, Kostol, Mogstad (2014): Family welfare culture via SSDI judge IV
- Borjas (2003): Immigration and labor markets
- Card (2001, 2009): Immigration impact on native wages
- Peri and Sparber (2009): Immigration and task specialization

## Planned Robustness Checks

1. **Placebo outcomes:** High-wage sector employment (Finance, Professional Services)
2. **Leave-one-court-out:** Drop each court and re-estimate
3. **Leave-one-judge-out:** Drop highest/lowest leniency judges
4. **Alternative time windows:** 2005-2019 (pre-COVID), 2010-2023
5. **Alternative clustering:** State-level, court × year
6. **LIML vs UJIVE vs 2SLS:** Compare IV estimators
7. **Reduced form:** Direct effect of judge leniency on outcomes (no first stage needed)
8. **Nationality composition controls:** Add controls for case nationality mix
9. **Court-level trends:** Add court-specific linear trends
10. **Bartik-style alternative:** Use national asylum policy shocks × court baseline caseload

## Data Sources

| Source | Variables | Access | Unit |
|--------|-----------|--------|------|
| EOIR Case Data | Judge, court, decision, date, nationality | DOJ FOIA (free) | Case |
| BLS QCEW | Employment, wages, establishments by industry | API (free) | County × quarter |
| Census ACS | Noncitizen pop, foreign-born, poverty | API (free) | County × year |
| TRAC Reports | Judge grant/denial rates | Web (free) | Judge |

## Sample

- ~2.7M asylum cases across 68+ courts, 2000-2024
- ~735 immigration judges
- ~68 courts linked to ~100 counties (primary court-county)
- QCEW: ~3,200 counties × 20+ years × 4 quarters
- ACS: ~3,200 counties × 15+ years (2005-2023)
