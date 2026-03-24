# Research Plan: Craigslist Entry and Local Journalism Employment

## Research Question
Did Craigslist's staggered metro-area entry (2000–2009) cause county-level declines in publishing industry employment, and did it primarily operate through reduced hiring or increased separations?

## Identification Strategy
**Staggered Difference-in-Differences (Callaway-Sant'Anna)**

Treatment: Craigslist entry into a county's primary MSA. Treatment dates from Kroft and Pope (2014, AER) appendix and Seamans and Zhu (2014, Management Science), covering 125+ US metros entering between 2000 and 2009.

Comparison group: Counties in MSAs where Craigslist had not yet entered (not-yet-treated). Never-treated counties (rural, non-MSA) available as secondary comparison.

Key exclusion restriction: Craigslist chose city entry order based on city-level demand for housing/job listings, not based on local newspaper industry health. Validated by Seamans & Zhu (2014) and Cage & Sraer (2022, ReStud).

## Expected Effects and Mechanisms
- **Primary mechanism:** Craigslist entry destroys classified advertising revenue (40% of newspaper revenue in 2000) → newspapers cut costs → employment declines
- **Expected sign:** Negative effect on publishing employment
- **Heterogeneity:** Larger effects in metros with higher pre-Craigslist classified ad reliance
- **Decomposition:** Separations (layoffs) should increase; new hires should decline; earnings may fall as remaining workers lose bargaining power

## Primary Specification
```
ln(Emp_{c,t}) = α_c + λ_t + β · D_{c,t} + ε_{c,t}
```
where D_{c,t} = 1 if Craigslist has entered county c's MSA by quarter t. Estimate via Callaway-Sant'Anna ATT_gt with not-yet-treated as control group.

Event study: Pre-trends from 4-14 quarters before entry (QWI starts 1990s). Post-treatment dynamics through 2015 (6-15 years post).

## Data Sources
1. **QWI NAICS 513** (Publishing Industries): Azure parquet files at `az://derived/qwi/rh/n3/*.parquet`. County×quarter employment, hires, separations, earnings. ~1,500 counties, 1991-2024.
2. **Craigslist entry dates:** Construct from Kroft and Pope (2014) published appendix + Wikipedia timeline. ~125 MSAs, entry years 2000-2009.
3. **MSA-county crosswalk:** Census Bureau CBSA-FIPS crosswalk.

## Robustness Checks
1. Sun-Abraham estimator as alternative to Callaway-Sant'Anna
2. Never-treated (non-MSA counties) as alternative control group
3. Leave-one-out by entry cohort
4. Placebo: NAICS sectors unaffected by classified ads (e.g., mining, utilities)
5. Pre-trend event study + HonestDiD sensitivity bounds
