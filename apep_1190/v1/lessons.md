## Discovery
- **Idea selected:** idea_1734 — "When the Grocery Store Leaves" — grocery chain bankruptcies as exogenous shocks to food access, testing effects on birth outcomes
- **Data source:** Census CBP (NAICS 4451) for grocery counts, County Health Rankings for LBW rates, ACS for controls
- **Key risk:** Treatment defined at state level limits statistical power under state-clustered SEs

## Execution
- **What worked:** Chain bankruptcy exposure as reduced-form instrument produced clear, robust results at county-clustered level. Division × year FE strengthened the coefficient. Placebo on teen births returned precise null.
- **What didn't:** NBER natality microdata lacks county FIPS (stripped for privacy). CDC Tracking API, data.cdc.gov SODA API, and CDC WONDER all failed for county-level birth data. Pivoted to County Health Rankings (worked but provides 3-year pooled averages, not annual birth-level data). State-clustered SEs render main result insignificant (p=0.29).
- **Review feedback adopted:** Strengthened caveats about state-level clustering, added discussion of treatment measurement error (coarse state-level assignment), lowered claim register in abstract/intro, acknowledged premature death result as evidence of potential broader economic confounding.

## Key lessons
- County Health Rankings is a reliable source for county-level birth outcomes when CDC natality microdata is inaccessible
- CHR files have TWO header rows (human-readable + variable codes) — must skip=2 in fread
- NBER natality CSV files intentionally strip county FIPS codes from public-use data
- Chain bankruptcy exposure is inherently state-level, limiting effective cluster count — future work needs store-level closure data
