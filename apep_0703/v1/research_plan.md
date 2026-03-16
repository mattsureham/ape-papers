# Research Plan: Green Rush or Fools' Gold? Firm Dynamics and Labor Reallocation under Recreational Marijuana Legalization

## Research Question

Does recreational marijuana legalization create net new employment and firms, or does it merely reallocate workers and economic activity across sectors? We decompose the labor market effects into firm creation, firm destruction, hiring flows, and earnings — distinguishing the extensive margin (new firms born vs old firms dying) from the intensive margin (employment and wage changes at continuing firms).

## Identification Strategy

**Callaway-Sant'Anna (2021) DiD** exploiting staggered state-level legalization of recreational marijuana across 24 US states (2014-2023). Treatment date = first legal retail sale.

Treatment cohorts:
- 2014: CO, WA
- 2015: AK, OR, DC
- 2017: CA, ME, MA, NV
- 2019: MI
- 2020: IL
- 2021: AZ, MT, NJ
- 2022: NY, VA, NM, CT
- 2023: RI, MD, MO
- 2024: DE, MN, OH

Never-treated states (~26) serve as controls for all cohorts.

**Key identification assumptions:**
1. Parallel trends in pre-legalization outcomes (testable via event-study plots)
2. No anticipation before retail sales begin
3. Treatment timing uncorrelated with state-specific labor trends

**Built-in placebo tests:**
- Healthcare (NAICS 62) and education (NAICS 61): sectors with no theoretical connection to marijuana
- Pre-2014 placebo treatment dates
- Federal employees (unaffected by state law)

## Expected Effects and Mechanisms

**Direct channel:** New cannabis retail/cultivation firms → firm births in NAICS 44-45 (retail), 11 (agriculture)
**Indirect channel:** Tourism/hospitality spillovers → employment in NAICS 72 (accommodation/food)
**Displacement:** Alcohol/tobacco firms may lose market share → possible firm deaths in competing sectors

**Predicted decomposition:**
- Net positive firm job creation (FrmJbGn - FrmJbLs) in retail, accommodation, agriculture
- Possible negative or null in manufacturing, finance
- Younger workers (19-24) disproportionately affected
- Potential racial disparities due to differential access to cannabis licensing

## Primary Specification

```
Y_{s,t} = α_s + α_t + Σ_g ATT(g,t) × 1[G_s = g] + ε_{s,t}
```

Where:
- Y = {Emp, FrmJbGn, FrmJbLs, HirA, HirN, Sep, EarnS} at state-quarter-industry level
- G_s = treatment cohort (quarter of first legal retail sale)
- CS-DiD with never-treated as control, anticipation = 0

## Data Source and Fetch Strategy

**Primary:** Azure QWI Parquet files (pre-loaded, smoke-tested)
- `az://derived/qwi/sa/ns/*.parquet` — sex × age × NAICS sector (185M rows)
- `az://derived/qwi/se/ns/*.parquet` — sex × education (123M rows)
- `az://derived/qwi/rh/ns/*.parquet` — race × ethnicity (144M rows)

**Analysis level:** State × quarter × NAICS sector (primary); county-level for border design robustness.

**Variables:** Emp (employment), EmpEnd, HirA (all hires), HirN (new hires), Sep (separations), FrmJbGn (firm job gains), FrmJbLs (firm job losses), EarnS (average earnings), TurnOvrS (turnover).

**Treatment dates:** Hand-coded from NCSL tracking + DISA.com legalization timeline.
