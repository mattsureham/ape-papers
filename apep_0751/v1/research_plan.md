# Research Plan: When the Corner Store Closes

## Research Question
Does tightening SNAP retailer stocking requirements reduce food access by driving out small-format retailers?

## Policy Context
The 2016 USDA Final Rule (published Dec 2016, effective Jan 2018) increased minimum stocking requirements for SNAP retailers from 3 to 7 varieties in each of 4 staple food categories. Approximately 71% of authorized SNAP retailers are small-format stores (convenience stores, dollar stores, small groceries) that face the highest compliance burden.

## Identification Strategy
**Continuous-treatment DiD.** Treatment intensity = pre-reform (2015) share of convenience stores (NAICS 445120) among all food retailers (NAICS 4451) in each county. Counties with a higher baseline share of small-format retailers face greater effective exposure to the stocking rule.

**Specification:**
Y_{ct} = β(ConvShare_c^{pre} × Post_t) + γ_c + δ_t + X_{ct}'δ + ε_{ct}

- Y_{ct}: food retailer count (Poisson QMLE)
- ConvShare_c^{pre}: 2015 convenience store share
- Post_t: indicator for t ≥ 2018
- γ_c, δ_t: county and year FE
- SE clustered at state level

**Parallel trends:** Testable with 8 pre-periods (2010-2017). Event study traces out dynamic effects.

**Key threats:**
1. Rural depopulation (differential trends) → control for ACS demographics
2. Dollar store expansion (confound) → separate NAICS code, placebo
3. NAICS code consistency → verify 445110/445120 stable across vintages

## Expected Effects
- Negative β on convenience store counts (compliance-driven exits)
- Null effect on supermarkets (already meet requirements → within-unit placebo)
- Stronger effects in rural/high-poverty counties (fewer substitutes)

## Data Sources
1. **Census CBP** (2010-2021): County-year establishment counts by NAICS
2. **ACS 5-year** (2015, 2021): County poverty, vehicle access, population
3. **USDA ERS** (optional): Food access atlas for descriptive context

## Primary Specification
Poisson QMLE with county + year FE, state-clustered SEs.
Robustness: OLS log(1+estab), negative binomial, state×year FE.
