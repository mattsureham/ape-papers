# Research Plan: Ban the Box and the Black Employment Gap

## Research Question

Do private-employer Ban-the-Box (BTB) laws reduce Black employment and hiring through statistical discrimination? When employers cannot ask about criminal history on applications, do they substitute group-level screening (race) for individual screening (criminal record), widening the Black-White employment gap?

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD with triple-difference.**

- **Treatment:** Staggered adoption of private-employer BTB laws across 16 states (2010–2020)
- **Triple-difference:** State × Post-BTB × Black race indicator
- **Identifying assumption:** Parallel trends in the Black/White employment ratio between treated and not-yet-treated states, conditional on county and time fixed effects
- **Pre-trend test:** Event-study plot of the Black employment ratio in treated vs. control states

**Treatment timing (private-employer BTB):**
| State | Year | Quarter |
|-------|------|---------|
| MA | 2010 | Q3 |
| HI | 2010 | Q3 |
| MN | 2013 | Q1 |
| RI | 2014 | Q1 |
| IL | 2014 | Q3 |
| DC | 2014 | Q4 |
| NJ | 2015 | Q1 |
| OR | 2016 | Q1 |
| VT | 2016 | Q3 |
| CT | 2017 | Q1 |
| CA | 2018 | Q1 |
| NV | 2018 | Q1 |
| WA | 2018 | Q2 |
| CO | 2019 | Q3 |
| NY | 2020 | Q1 |
| MD | 2020 | Q1 |

**Control group:** States with no private-employer BTB law (or only public-employer BTB).

## Expected Effects and Mechanisms

**Primary hypothesis (Doleac-Hansen 2020):** BTB increases statistical discrimination against Black applicants. When employers cannot observe individual criminal history, they use race as a proxy → Black hiring falls relative to White hiring.

**Expected signs:**
- Black new hires (HirA, HirN): **negative** relative to White new hires post-BTB
- Black incumbent employment (EmpS): **null or small negative** (discrimination operates at hiring margin)
- Overall Black employment (Emp): **negative** (driven by hiring channel)

**Mechanism test:** If the hiring channel drives the result, HirA/HirN should show larger effects than EmpS (full-quarter employment). This decomposes extensive margin (new hires) from intensive margin (incumbents).

## Primary Specification

```
Y_{crt} = α_c + γ_t + δ(Treated_s × Post_st × Black_r) + β(Treated_s × Post_st) + μ(Post_st × Black_r) + ε_{crt}
```

Where:
- c = county, r = race (Black/White), t = quarter
- Y = ln(Emp), ln(HirA), ln(HirN), ln(EmpS)
- Clustered at state level (treatment varies at state level)
- CS-DiD for staggered treatment timing

## Data Source and Fetch Strategy

**Primary data:** QWI county×race×ethnicity panel from Azure Blob Storage
- Path: `az://apepdata/derived/qwi/rh/ns/*.parquet`
- Coverage: All US counties, 2000–2023, quarterly
- Race: A1 (White alone), A2 (Black alone)
- Ethnicity: A0 (All), filter to avoid double-counting
- Variables: Emp, HirA, HirN, EmpS, EarnS, geography (county FIPS)

**Fetch method:** DuckDB Azure extension reading Parquet files directly.

## Robustness Checks

1. **Pre-trends:** Event study showing parallel trends in Black/White ratio pre-BTB
2. **Leave-one-out:** Drop each treated state and re-estimate
3. **Placebo race:** Hispanic/White ratio (BTB should not differentially affect Hispanic workers if mechanism is criminal-record proxy)
4. **Public-only BTB states as placebo:** States that only adopted public-sector BTB — effect should be zero or much smaller since QWI covers all employers
5. **Wild cluster bootstrap:** Given 50 state-level clusters, supplement with WCB p-values
6. **Bacon decomposition:** Examine which 2×2 DiD comparisons drive the result
