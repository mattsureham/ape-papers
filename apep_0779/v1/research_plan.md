# Research Plan: Pumping the Pipeline

**Paper ID:** apep_0779
**Idea:** idea_1635
**Version:** v1

## Research Question

Do state lactation accommodation laws increase maternal employment retention? We exploit the staggered adoption of workplace breastfeeding protection laws across 34 US states (1995--2022) to estimate the causal effect on female employment flows using Census QWI administrative data.

## Identification Strategy

**Triple-Difference (DDD):** Female vs Male x Age 25-34 (childbearing) vs Age 45-54 (non-childbearing) x Treated vs Untreated states.

The DDD removes:
1. State-specific shocks common to all sex-age groups
2. National sex-age trends (e.g., secular female labor force changes)
3. State-by-sex trends unrelated to lactation accommodation

**Callaway-Sant'Anna (2021)** for heterogeneity-robust ATT on female 25-34 subsample (DD).

## Treatment Assignment

34 states adopted lactation accommodation laws between 1995-2022. Treatment year = year law enacted. States without a law by 2022 are never-treated controls.

Key early adopters: TX, UT (1995), MN (1998), GA, HI (1999), CA, CT, IL, LA (2001).
Late adopters: MI (2018), NV, NJ (2019), WV (2021).

Federal PUMP Act (Dec 2022) provides a natural endpoint.

## Data

- **Source:** Census QWI (Quarterly Workforce Indicators) from Azure blob storage
- **Path:** `az://derived/qwi/sa/ns/*.parquet` (51 state files)
- **Unit:** State x Quarter x Sex x Age Group
- **Period:** 2000Q1 -- 2022Q4
- **Filters:** geo_level = 'S', industry = '00' (total), sex in {1,2}, agegrp in {A04, A06}
- **Outcomes:** Separation rate (Sep/Emp), hire rate (HirA/Emp), log employment, log earnings

## Outcomes

| Outcome | Variable | Definition | Hypothesis |
|---------|----------|------------|------------|
| Separation rate | Sep/Emp | Quarterly separations / beginning-of-quarter employment | Decrease (retention) |
| Hire rate | HirA/Emp | Quarterly hires / beginning-of-quarter employment | Ambiguous |
| Log employment | log(Emp) | Log of beginning-of-quarter employment | Increase |
| Log earnings | log(EarnS) | Log of average monthly earnings for stable workers | Increase (selection) |

## Empirical Specifications

### Main: DDD
```
Y_{s,q,g,a} = β (Female × Young × Post) + FE(state^sex^agegrp) + FE(sex^agegrp^quarter) + FE(state^quarter) + ε
```
Cluster standard errors at state level.

### Robustness
1. Callaway-Sant'Anna on Female 25-34 subsample (DD)
2. Placebo: Male 25-34 (should be null)
3. Placebo: Female 45-54 (should be null)
4. Exclude early adopters (pre-2001)
5. Event study dynamics (leads/lags)

## Expected Sample Size

~50 states x 92 quarters (2000-2022) x 2 sexes x 2 age groups ≈ 18,400 observations.

## Timeline

1. Fetch QWI data from Azure
2. Clean and construct treatment variables
3. Run main DDD regression
4. Run robustness checks
5. Generate tables
6. Write paper (AER: Insights format)
7. Validate and review
