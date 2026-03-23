# Research Plan: Coal Dust in the Dark

## Research Question
Did MSHA's 2014 respirable coal dust rule accelerate employment exit from coal mining? We exploit the sharp August 1, 2014 effective date and within-NAICS-21 variation (coal mining vs. oil/gas extraction) to estimate the causal effect of health regulation compliance costs on county-level employment dynamics.

## Identification Strategy
Continuous-treatment DiD: county 2013 coal share of mining employment × post-August 2014 indicator. County FE + quarter FE. Clustered by state.

## Data
- QWI from Azure: county × quarter × NAICS 3-digit (211, 212, 213), 2011-2019
- FRED: coal and oil prices (quarterly)
- 822 mining counties, 477 coal-dominant, 50 oil/gas-dominant

## Key Results
- Main DiD: null in full sample (β = 0.15, SE = 0.11)
- Appalachian (underground): negative (β = -0.23, SE = 0.21)
- Non-Appalachian (surface): positive (β = 0.24, SE = 0.12)
- DDD (coal vs oil/gas within county): positive (β = 0.15, p < 0.01) — oil crash dominates
- Pre-trends fail in full sample — commodity price confounding
