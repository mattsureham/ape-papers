# Research Plan: Paid Family Leave and Healthcare Workforce Retention

## Research Question
Do state-level paid family leave (PFL) mandates reduce female healthcare worker turnover and separations, leveraging the structural female-dominance of healthcare (NAICS 62, 77% female)?

## Identification Strategy
**Triple Difference-in-Differences (DDD):**
1. Pre/post PFL adoption within state
2. PFL-adopting vs. non-adopting states
3. Female vs. male workers within healthcare

The DDD removes: time-invariant gender gaps in healthcare turnover, state-level shocks common to both sexes, and national trends in female labor force participation.

**Identifying assumption:** Absent PFL, the male-female turnover gap in healthcare would have evolved similarly across adopting and non-adopting states.

**Treatment states & timing:**
| State | Year | FIPS |
|-------|------|------|
| California | 2004 | 6 |
| New Jersey | 2009 | 34 |
| Rhode Island | 2014 | 44 |
| New York | 2018 | 36 |
| Washington | 2020 | 53 |
| DC | 2020 | 11 |
| Massachusetts | 2021 | 25 |
| Connecticut | 2022 | 9 |
| Oregon | 2023 | 41 |
| Colorado | 2024 | 8 |

## Expected Effects
- **Primary:** PFL reduces female healthcare turnover (TurnOvrS) by 3-10% relative to male turnover
- **Mechanism:** PFL enables bonding/caregiving leave without job separation → reduces involuntary exits
- **Heterogeneity:** Stronger for younger women (childbearing age), possibly stronger in nursing/residential care (NAICS 623)

## Primary Specification
Y_{s,g,t} = α + β₁(PFL_st × Female_g) + β₂(PFL_st) + β₃(Female_g) + γ_s + δ_t + θ_g + ε_{s,g,t}

Where s=state, g=sex, t=quarter. β₁ is the DDD coefficient of interest.

Also estimate event study version with Callaway-Sant'Anna (2021) for heterogeneity-robust ATT.

## Data
- **Source:** QWI from Azure Blob (`az://apepdata/derived/qwi/sa/ns/*.parquet`)
- **Panel:** State × sex × quarter, NAICS 62, 2001-2024
- **Observations:** ~9,516 (51 states × 2 sexes × ~93 quarters)
- **Outcomes:** TurnOvrS (turnover rate), SepS (separations), EarnS (earnings)

## Robustness
1. Restrict to NAICS 623 (nursing/residential care)
2. Callaway-Sant'Anna event study
3. Placebo: male-only turnover should show null
4. Falsification industry: Finance (NAICS 52, similar female share, different mechanism)
5. Age group heterogeneity (childbearing age vs. older)
