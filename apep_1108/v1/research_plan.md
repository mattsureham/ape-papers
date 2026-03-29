# Research Plan: The Housing Cost of Reshoring

## Research Question

Does federally subsidized semiconductor manufacturing investment under the CHIPS and Science Act increase local housing costs, and how large are the distributional consequences for incumbent residents?

## Identification Strategy

**Staggered difference-in-differences** exploiting the timing of CHIPS Act funding announcements across counties.

- **Treatment:** First public announcement of CHIPS Act funding award to a semiconductor facility in a given county. Treatment dates are staggered from February 2023 through March 2025.
- **Treated units:** ~26 counties receiving major CHIPS Act fab investments (TSMC in Maricopa AZ, Intel in Franklin OH, Micron in Onondaga NY, Samsung in Williamson TX, etc.)
- **Control units:** All other US counties with Zillow ZHVI coverage (~2,500+ counties)
- **Estimator:** Callaway and Sant'Anna (2021) group-time ATT, aggregated to event-time. Robust to staggered treatment timing and heterogeneous effects.
- **Pre-trends:** 24+ months of pre-treatment data (announcements start Feb 2023, Zillow data monthly from 2000).

**Triple-difference (robustness):** Treatment × Post × High-construction-exposure (counties with large fab investment relative to existing housing stock).

## Expected Effects and Mechanisms

1. **Housing price appreciation:** Fab construction employs thousands of workers (often 5,000-10,000 during peak construction). Combined with permanent workforce (1,000-3,000 per fab), this creates sudden housing demand. Expected: positive effect on ZHVI, larger for counties with tighter pre-existing housing supply.

2. **Rental price increases:** Construction workers and early fab employees need rental housing. Expected: positive effect on ZORI, possibly larger and faster than ownership prices.

3. **Distributional channel:** Low-income incumbent renters face higher costs without receiving the high-wage fab jobs (which require specialized skills). The "reshoring rent" falls disproportionately on service-sector workers.

## Primary Specification

```
Y_{c,t} = α_c + α_t + Σ_g β_g × 1[G_c = g] × 1[t ≥ g] + X_{c,t}γ + ε_{c,t}
```

Where:
- Y_{c,t} = log(ZHVI) or log(ZORI) for county c in month t
- G_c = announcement month for treated county c (∞ for never-treated)
- Callaway-Sant'Anna group-time ATTs, aggregated to dynamic event-study
- X_{c,t} = time-varying controls (optional: state economic conditions)
- Standard errors clustered at county level

## Data Sources

1. **Zillow Home Value Index (ZHVI):** County-level, monthly, Jan 2000 – Feb 2026. Free CSV download from Zillow Research. ~3,100 counties.
2. **Zillow Observed Rent Index (ZORI):** County-level, monthly, Jan 2015+. Free CSV download.
3. **CHIPS Act announcements:** Commerce Department press releases, compiled manually. Key fields: county FIPS, announcement date, award amount, company, fab type.
4. **Census ACS (controls):** Median household income (B19013), population (B01001), housing units (B25001) via Census API.
5. **Building Permits Survey (mechanism):** County-level monthly permits from Census.

## Robustness Checks

1. Synthetic DiD (Arkhangelsky et al. 2021) as alternative estimator
2. Placebo: random announcement dates assigned to treated counties
3. DDD: single-family vs. multifamily housing (fabs affect SFH more)
4. Heterogeneity by investment size (award amount per existing housing unit)
5. Donut: exclude 2-month window around announcement (anticipation)
6. Leave-one-out: drop each treated county in turn (no single county drives result)
