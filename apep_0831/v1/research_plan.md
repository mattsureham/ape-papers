# Research Plan: Section 232 Steel Tariffs and the Racial Wage Gap in Manufacturing

## Research Question
Did the 2018 Section 232 steel and aluminum tariffs narrow or widen the Black-White wage gap in manufacturing communities? Import protection boosted demand for domestic steel/aluminum workers, but if Black workers are concentrated in less-protected sub-industries, lower-skill tiers, or face occupational segregation within manufacturing, the "protection premium" may accrue disproportionately to White workers.

## Identification Strategy
**Triple-difference:** county × tariff-exposure intensity × race (Black vs. White)

- **First difference (time):** Pre (2015Q1–2018Q1) vs. Post (2018Q2–2020Q1, stopping before COVID)
- **Second difference (exposure):** High vs. low county-level employment share in Section 232-protected industries (NAICS 3310 primary metals, 3320 fabricated metals)
- **Third difference (race):** Black (A2) vs. White (A1) workers within the same county-industry-quarter cells

This design nets out:
1. National time trends (first diff)
2. Permanent county-industry differences (second diff)
3. Nationwide race-specific shocks (third diff)

The identifying assumption is that absent the tariffs, the Black-White earnings gap would have evolved similarly in high- vs. low-exposure counties. We test this with 12 quarters of pre-trends.

## Expected Effects and Mechanisms
- **Baseline hypothesis:** Protection raises manufacturing wages overall but the racial gap persists or widens because Black workers are disproportionately in downstream using industries (which face higher input costs) rather than upstream producing industries (which benefit from protection).
- **Alternative:** Protection narrows the gap if it tightens labor markets in exposed counties, benefiting workers at the bottom of the wage distribution (where Black workers are overrepresented).
- **Mechanism test:** Decompose by upstream (NAICS 3310 producers) vs. downstream (other manufacturing using steel/aluminum as inputs).

## Primary Specification
```
Y_{c,i,r,t} = α + β₁(Post_t × Exposure_c) + β₂(Post_t × Black_r)
              + β₃(Post_t × Exposure_c × Black_r)
              + γ_{c,r} + δ_{i,t} + ε_{c,i,r,t}
```

Where:
- Y = log average monthly earnings
- c = county, i = industry (2-digit NAICS), r = race (Black/White), t = quarter
- Exposure_c = county-level share of 2015 employment in NAICS 3310+3320
- Post_t = indicator for 2018Q2+
- γ_{c,r} = county × race fixed effects
- δ_{i,t} = industry × quarter fixed effects
- Clustering: state level

**β₃ is the coefficient of interest:** the differential effect of tariff exposure on Black vs. White earnings.

## Data Sources and Fetch Strategy

### 1. QWI Race-Hispanic Panel (outcome data)
- Source: Azure blob `az://apepdata/derived/qwi/rh/ns/*.parquet`
- 143.9M rows, county × quarter × race × ethnicity × industry
- Key variables: avg_monthly_earnings (EarnS), employment (Emp), hires (HirA), separations (Sep)
- Filter: manufacturing industries (NAICS 31-33), 2015-2020, race codes A1 (White) and A2 (Black)

### 2. County Business Patterns 2015 (treatment intensity)
- Source: Census API `https://api.census.gov/data/2016/cbp`
- 2015 or 2016 vintage for pre-treatment employment by county × NAICS
- Construct: county-level share of total employment in NAICS 3310 (primary metals) + 3320 (fabricated metals)

### 3. Retaliation Exposure (robustness)
- China/EU/Canada retaliatory tariffs targeted agriculture and specific manufactured goods
- County-level agricultural export share as a control for retaliation effects

## Robustness Checks
1. Event-study plot of β₃ by quarter (pre-trend test)
2. Continuous vs. quartile treatment intensity
3. Drop counties with <100 manufacturing workers
4. Hispanic (H) vs. non-Hispanic White comparison
5. Employment counts as outcome (extensive margin)
6. Placebo: non-manufacturing industries in same counties
7. Stop sample at 2019Q4 (tighter pre-COVID window)
