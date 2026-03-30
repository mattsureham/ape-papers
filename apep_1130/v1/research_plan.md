# Research Plan: The Crowding-Out Gradient — SBA Size Standard Increases and the Geographic Redistribution of Federal Procurement

## Research Question

When the SBA raises small business size standards for specific NAICS sectors, does federal procurement redistribute geographically from rural/small-metro counties (with genuinely small firms) toward larger metro counties (with newly eligible mid-sized firms)?

## Motivation

Small business set-asides represent $98.6B annually (~23% of federal procurement). The SBA periodically raises the employee or revenue thresholds that define "small" for specific NAICS codes. Denes, Duchin, and Hackney (Census WP CES-WP-24-28, 2024) find that the smallest firms lose 15.6% of procurement revenue after increases — but the geographic dimension is unstudied. If mid-sized firms that become newly eligible are disproportionately in metro areas, the policy may undermine its distributional objective.

## Identification Strategy

**Staggered DiD (Callaway-Sant'Anna 2021).** Treatment: NAICS sector s receives its first major size standard increase at time t*_s. Three treatment cohorts:

| Cohort | Treatment Year | Sectors (NAICS 2-digit) |
|--------|---------------|------------------------|
| Cohort 1 | FY2013 | Wholesale (42), Retail (44-45), Information (51) |
| Cohort 2 | FY2014 | Finance (52), Real Estate (53), Professional Services (54) |
| Cohort 3 | FY2016 | Manufacturing (31-33) |

Never-treated sectors (control): Agriculture (11), Mining (21), Utilities (22), Construction (23), Transportation (48-49), Administrative (56), Arts (71), Accommodation (72).

SBA reviews follow a fixed sector-rotation schedule mandated by Congress, NOT responsive to county-level procurement conditions. This gives plausibly exogenous sector-level timing.

## Data Sources

1. **USAspending API** (`/api/v2/search/spending_by_geography/`): County-level procurement by NAICS sector and fiscal year. Filter for contracts (award_type_codes A/B/C/D). Separate calls for SB set-asides vs full-and-open.
2. **SBA Federal Register final rules**: Exact treatment dates by sector.
3. **USDA Rural-Urban Continuum Codes**: County metropolitan/non-metropolitan classification.

## Panel Construction

- Unit: NAICS 2-digit sector (s) × fiscal year (t)
- Period: FY2008–FY2020 (13 years; pre-2022 to avoid universal inflation adjustment)
- Treatment: binary indicator for post-size-standard-increase
- N treated: ~13 NAICS sectors in 3 cohorts; ~7-8 never-treated controls

## Outcomes

1. **Total SB set-aside procurement** (log $): Does total SB-eligible spending increase?
2. **Number of unique SB vendors**: Does vendor count change?
3. **Geographic HHI**: Does procurement become more or less concentrated across counties?
4. **Metropolitan share**: Share of SB set-aside dollars going to metro vs non-metro counties.

## Expected Effects

- Total SB procurement: ambiguous (more eligible firms, but same budget)
- Geographic HHI: decrease if newly eligible firms are in new counties; increase if metro capture
- Metro share: increase (newly eligible mid-sized firms are disproportionately metro)
- This is the "crowding-out gradient" — small firms in thin markets lose share to mid-sized firms in thick markets

## Primary Specification

ATT(g,t) via Callaway-Sant'Anna, aggregated to event-time estimates. Sector-level panel with concentration measures computed from county-level procurement data.

## Exposure Alignment

The treatment (SBA size standard increase) directly affects firm eligibility for small-business set-aside contracts within specific NAICS sectors. The treated population is the set of firms that become newly eligible — those with employees or revenue between the old and new thresholds. These firms are disproportionately located in metropolitan counties with larger average establishment sizes. The outcome (geographic concentration of procurement) is measured at the sector-year level, aggregated from county-level contract data. The exposure pathway is: size standard increase → newly eligible mid-sized firms → these firms compete for and win set-aside contracts → procurement shifts toward counties where newly eligible firms are located → geographic concentration increases. Counties without newly eligible firms (typically rural/thin-market counties with only genuinely small firms) experience relative loss of procurement share.

## Robustness

1. Event study with pre-trend test
2. TWFE comparison (expected to show heterogeneity issues)
3. Placebo: never-treated sectors
4. Dropping one cohort at a time (leave-one-out)
5. Alternative concentration measures (top-10 county share, Gini, rural share)
