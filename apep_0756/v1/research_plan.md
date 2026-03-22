# Research Plan: Fair Workweek, Unfair Turnover?

## Research Question

Do predictive scheduling ("fair workweek") laws reduce worker turnover in service-sector industries, or do employers respond by cutting hiring and shifting to fewer, more stable workers — creating a "predictability premium" that incumbent workers capture at the expense of job seekers?

## Policy Background

Six U.S. cities and one state adopted predictive scheduling laws between 2015 and 2020:

| Jurisdiction | Effective Date | Treatment Quarter | County FIPS |
|---|---|---|---|
| San Francisco, CA | July 2015 | 2015Q3 | 06075 |
| Emeryville, CA | July 2017 | 2017Q3 | 06001 (diluted) |
| Seattle, WA | July 2017 | 2017Q3 | 53033 |
| New York City, NY | Nov 2017 | 2017Q4 | 36005, 36047, 36061, 36081, 36085 |
| Oregon (statewide) | July 2018 | 2018Q3 | 41001–41071 (36 counties) |
| Philadelphia, PA | Jan 2020 | 2020Q1 | 42101 |
| Chicago, IL | July 2020 | 2020Q3 | 17031 |

These laws require employers (typically 500+ employees in retail/food service) to:
- Provide 14-day advance notice of schedules
- Pay "predictability pay" for last-minute schedule changes
- Offer additional hours to existing workers before hiring new ones

## Identification Strategy

**Triple-difference (DDD):**
1. Treated vs. untreated counties
2. Treated industries (NAICS 72 Food Services, NAICS 44-45 Retail) vs. control industries (NAICS 31-33 Manufacturing, NAICS 54 Professional/Technical)
3. Pre vs. post treatment

The third difference (industry) embeds a within-county placebo: manufacturing and professional service workers in treated counties should NOT be affected by scheduling laws that apply only to retail and food service employers.

**Estimating equation:**
Y_{c,i,t} = β(Treated_c × TreatedInd_i × Post_t) + δ_{c,i} + γ_{i,t} + μ_{c,t} + ε_{c,i,t}

Where δ_{c,i} = county×industry FE, γ_{i,t} = industry×quarter FE, μ_{c,t} = county×quarter FE.

**Robustness:**
- Callaway-Sant'Anna on treated industries only (pure DD, dropping industry dimension)
- Exclude COVID-affected cohorts (Philadelphia 2020Q1, Chicago 2020Q3)
- Varying control industries
- Young workers (19-24) as high-exposure subgroup

## Expected Effects and Mechanisms

**Mechanism 1 — Turnover reduction (direct):** Laws stabilize schedules → workers quit less → separation rate falls.

**Mechanism 2 — Hiring freeze (employer response):** "Offer hours to existing" provisions → employers hire fewer new workers → new hire rate falls.

**Mechanism 3 — Earnings compression:** Fewer separations + fewer hires → more stable but potentially lower-wage workforce. Earnings effect ambiguous.

**Net prediction:** Separation rate falls (moderate negative SDE), new hire rate falls (small-to-moderate negative), earnings ambiguous or small positive.

## Data

**Primary:** Census QWI (Quarterly Workforce Indicators) from LEHD, available as Parquet files on Azure at `derived/qwi/sa/ns/*.parquet`. County × quarter × NAICS sector × sex × age, 2001–2025. ~150M+ rows.

**Key variables:**
- `Emp` — Beginning-of-quarter employment
- `HirA` — All hires
- `HirN` — New hires (not recalled)
- `Sep` — Separations
- `EarnS` — Average monthly earnings (stable jobs)
- `TurnOvrS` — Turnover rate (stable jobs)

**Unit of analysis:** County × NAICS sector × quarter

## Primary Specification

DDD regression with county×industry, industry×quarter, and county×quarter fixed effects. Standard errors clustered at the county level. Pre-treatment window: 2013Q1–treatment quarter. Post-treatment window: treatment quarter–2019Q4 (pre-COVID for most cohorts).
