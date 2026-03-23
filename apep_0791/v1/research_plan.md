# Research Plan: The Credential Equity Trap

## Research Question
Does for-profit college regulation designed to protect students from poor outcomes reduce minority credential attainment by disproportionately threatening programs that serve Black and Hispanic students?

## Policy Setting
The Gainful Employment (GE) Rule (34 CFR §668, effective July 1, 2015) imposed debt-to-earnings ratio tests on virtually all for-profit programs. Programs failing two of three consecutive assessments lost Title IV federal aid eligibility. Programs disproportionately failing the GE tests served higher shares of Black and Hispanic students (TICAS 2023). The Trump administration repealed the rule effective July 1, 2019.

## Identification Strategy
**Design:** Difference-in-differences (DD) and triple-difference (DDD)

- **DD:** Compare for-profit institutions (control=3) vs. public 2-year institutions (sector=4) before/during/after the GE Rule, with minority completion share and total completions as outcomes.
- **DDD:** Stack institution × race-group × year observations. Compare how minority (Black/Hispanic) vs. white completions changed at for-profits relative to public 2-years during the GE period and after repeal.

Three regulatory periods:
- Pre-GE: 2007–2014
- GE-Active: 2015–2018
- Post-Repeal: 2019–2023

## Expected Effects
1. GE Rule reduces total completions at for-profits (program closures, enrollment declines)
2. Minority completion share declines at for-profits during GE (GE-failing programs disproportionately serve minorities)
3. Repeal partially reverses these effects

## Primary Specification
Y_it = α + β₁(ForProfit_i × GE_t) + β₂(ForProfit_i × PostRepeal_t) + γ_i + δ_t + ε_it

Clustered SEs at institution level. Outcomes: (1) log total completions, (2) minority share, (3) log minority completions.

DDD: institution × race FE, race × year FE, institution × year FE.

## Data Source
IPEDS completions by race/ethnicity (c_a table), 2000–2024. Institution characteristics from hd table. ~1,800 for-profit institutions, ~900 public 2-year controls. Downloaded from Azure as ipeds.duckdb.
