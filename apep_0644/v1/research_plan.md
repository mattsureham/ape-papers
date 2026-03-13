# Research Plan: apep_0644

## Research Question

How do employers adjust hiring, workforce composition, and labor flows when required to post salary ranges in job listings? Specifically, do state pay transparency mandates reduce new hiring or firm job creation, shift the composition between new hires and recalls, or alter turnover patterns — and do these effects concentrate in industries where wage opacity was greatest?

## Identification Strategy

**Design:** Callaway-Sant'Anna (2021) staggered difference-in-differences.

**Treatment cohorts:**
- Colorado: 2021Q1 (Equal Pay for Equal Work Act)
- California: 2023Q1 (SB 1162)
- Washington: 2023Q1 (SB 5761)
- New York: 2023Q4 (S9427A)

**Units:** County-quarter-industry cells (2-digit NAICS).

**Control group:** 2,936 never-treated counties across 46+ states without salary-range-in-posting mandates.

**Identifying assumption:** Parallel trends in labor flow outcomes between treated and never-treated counties in the pre-mandate period, conditional on county and industry fixed effects.

## Expected Effects and Mechanisms

1. **Hiring composition channel:** Transparency may shift hiring from new hires (external recruitment where posted ranges matter) toward recalls (returning workers with known wages), reducing search friction for new hires but raising adjustment costs.

2. **Job creation/destruction:** If transparency compresses wage-setting power, employers in high-dispersion industries may reduce job creation or increase job destruction to maintain profit margins.

3. **Turnover:** Transparency reduces information asymmetry, potentially lowering voluntary separations (workers know market wages at hiring) but increasing involuntary separations (firms restructure around posted ranges).

4. **Industry heterogeneity:** Effects should concentrate in high-wage-dispersion industries (Finance, Professional Services, Information Technology) where salary opacity was greatest. Low-dispersion industries (Retail, Hospitality) serve as a built-in placebo.

## Primary Specification

```
Y_{c,i,t} = α + τ_{g,t} + μ_c + γ_i + δ_t + ε_{c,i,t}
```

Where:
- Y: labor flow outcome (new hire rate, recall rate, job creation, job destruction, turnover, earnings)
- c: county, i: industry, t: quarter
- τ_{g,t}: group-time ATT (Callaway-Sant'Anna)
- μ_c, γ_i, δ_t: county, industry, and time fixed effects

Clustering at the state level (51 clusters).

## Robustness

1. **Event study:** Dynamic ATT estimates for k = -12 to +8 quarters
2. **HonestDiD / Rambachan-Roth bounds:** Sensitivity to parallel trends violations
3. **Border county design:** Colorado border counties vs. adjacent UT/KS/NE/WY counties
4. **Industry triple-DiD:** High- vs. low-wage-dispersion industries as intensity margin
5. **Placebo outcomes:** Government employment (exempt from mandates in most states)
6. **Leave-one-state-out:** Verify no single treated state drives results
7. **Alternative control group:** Not-yet-treated (adding 2025 cohort states) vs. never-treated

## Data Source and Fetch Strategy

**Primary:** Quarterly Workforce Indicators (QWI) via Azure Blob Storage.
- Industry-level (2-digit NAICS): `az://derived/qwi/sa/ns/*.parquet`
- Industry-level (3-digit NAICS): `az://derived/qwi/sa/n3/*.parquet` (for heterogeneity)
- Education cuts: `az://derived/qwi/se/ns/*.parquet`
- Race cuts: `az://derived/qwi/rh/ns/*.parquet`

**Key variables:** Emp, HirN, HirA, Sep, FrmJbGn, FrmJbLs, EarnS, EarnHirNS, TurnOvrS

**Sample:** 2015Q1-2024Q4 (40 quarters), all US counties, all private-sector 2-digit NAICS industries.

**Treatment assignment:** State FIPS codes mapped to mandate effective dates.
