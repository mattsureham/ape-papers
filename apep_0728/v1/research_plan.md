# Research Plan: apep_0728

## Title
The Racial Trade Deficit: How China's PNTR Widened the Black-White Manufacturing Earnings Gap

## Research Question
Did the elimination of trade policy uncertainty through PNTR (October 2000) disproportionately compress Black workers' earnings relative to White workers in exposed U.S. manufacturing industries?

## Identification Strategy
**Triple Difference (DDD):**
- **D1 (Industry):** Pierce-Schott NTR gap — difference between Smoot-Hawley (1930s) tariff rates and applied NTR rates. Higher-gap industries faced greater competitive exposure after PNTR. Predetermined by 1930s legislation.
- **D2 (Race):** County-level pre-PNTR Black manufacturing employment share from QWI (1998-2000 average). Captures historical racial occupational sorting into high-exposure industries.
- **D3 (Time):** Pre-PNTR (1995-2000) vs. post-PNTR (2001-2010).

**Estimating equation:**
```
ln(Earnings_cit) = α + β₁(NTRGap_i × Black_c × Post_t)
                     + β₂(NTRGap_i × Post_t)
                     + β₃(Black_c × Post_t)
                     + β₄(NTRGap_i × Black_c)
                     + γ_ci + δ_ct + θ_it + ε_cit
```
where c = county, i = manufacturing industry, t = quarter. Fixed effects: county×industry, county×quarter, industry×quarter.

**Key coefficient:** β₁ captures the differential earnings effect of trade exposure on Black vs. White workers, controlling for all lower-order interactions and two-way fixed effects.

## Expected Effects and Mechanisms
1. **Primary hypothesis:** β₁ < 0. Black workers in high-NTR-gap industries experienced larger earnings declines because:
   - Historical occupational segregation concentrated Black workers in lower-skill manufacturing roles (textiles, apparel, furniture, plastics) with higher NTR gaps
   - Lower occupational mobility limits reallocation to other sectors
   - Spatial concentration in manufacturing-dependent areas amplifies local labor market effects

2. **Mechanism tests:**
   - Decomposition into employment (extensive margin) vs. earnings conditional on employment (intensive margin)
   - Hires vs. separations to identify which labor market flow drives the gap
   - Heterogeneity by education (low-education counties vs. high-education)

3. **Rival hypothesis:** β₁ ≈ 0 if trade exposure affects all workers equally within industry×county, or if Black workers' pre-PNTR industry composition already sorted them into declining industries (absorbed by county×industry FE).

## Primary Specification
- **Unit:** County × 2-digit NAICS manufacturing subsector × quarter
- **Treatment intensity:** Continuous NTR gap (industry-level)
- **Outcome:** Log average monthly earnings by race, separately for Black and White workers, then Black-White gap
- **Sample:** 1,914 counties with both Black and White manufacturing employment, 1995-2010
- **Clustering:** State level (50 clusters)
- **Robustness:** (1) County-level clustering, (2) Bartik-style shift-share with leave-one-out, (3) Placebo race (Asian workers), (4) Placebo industries (services/non-manufacturing with low NTR gaps), (5) Pre-trend test using 1995-2000 quarterly event study

## Data Sources
1. **QWI Race×Industry Panel:** Azure `az://apepdata/derived/qwi/rh/ns/*.parquet` — 143.9M rows, county×quarter×industry×race. Variables: employment, average monthly earnings, hires, separations. Confirmed 1,914 counties with Black + White manufacturing.

2. **Pierce-Schott NTR Gap:** Published data from Pierce & Schott (2016, AER). NTR gap = column 2 (Smoot-Hawley) rate minus NTR rate at SIC 4-digit level. Will download from journal replication package or construct from USITC tariff schedule. Map SIC → NAICS via Census crosswalk.

3. **County characteristics (controls):** Census 2000 county-level demographics for heterogeneity analysis (Black population share, manufacturing employment share, education levels).

## Fetch Strategy
1. Read QWI parquet from Azure via DuckDB/Arrow in R
2. Download Pierce-Schott NTR gaps from published replication files
3. Construct SIC-to-NAICS crosswalk for industry matching
4. Merge at county × industry × quarter level
5. Validate: confirm sample sizes match smoke test (489K Black obs, 1.2M White obs in manufacturing 1995-2010)
