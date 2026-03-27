# Research Plan: Lights, Camera, Equity: Film Tax Credits and Racial Employment Gains

## Research Question

Do state film production tax credits create equitable employment opportunities, or do benefits accrue disproportionately to white workers? Using QWI race-ethnicity data at the county-quarter-industry level, this paper estimates the first distributional analysis of who captures film subsidy jobs by race.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD** exploiting state-level adoption of film production tax credits from 1997-2019.

- Treatment: State-quarter when a state adopts or significantly enhances (≥15% rate) film tax credits
- Control group: Never-treated states (13+ states without meaningful credits)
- Outcome: Employment, hires, separations, and earnings in NAICS 512 (Motion Picture) by race (White, Black, Hispanic)
- Event study: Dynamic treatment effects with group-time ATTs
- NC 2014 repeal as removal experiment (separate event study)

## Expected Effects and Mechanisms

- **Overall employment**: Positive effects on NAICS 512 employment, reversing Button (2019) null with extended sample
- **Racial decomposition**: If film subsidies simply scale existing industry composition, Black employment share should remain constant. If subsidies unlock new entry points (production assistant roles, location services, craft positions), Black employment share could rise.
- **Named mechanism**: "The Casting Gap" — whether film subsidies diversify the industry workforce or just multiply existing demographic patterns

## Primary Specification

Event-study with group-time ATTs:
- Y_{s,t,r} = employment/hires/earnings in NAICS 512 for state s, quarter t, race r
- Treatment timing from state film credit adoption dates
- Clustering: State level (51 clusters)
- Heterogeneity: by race (White A1, Black A2, Hispanic A5), by pre-treatment Black employment share

## Data Sources

1. **Census QWI API** (timeseries/qwi/rh): State × quarter × NAICS × race employment, hires, separations, earnings. All 50 states + DC, 2001Q1-2024Q4.
2. **Film tax credit adoption dates**: Compiled from NCSL, legislative records, prior literature (Button 2019).
3. **BLS QCEW**: Establishment counts for NAICS 512 by state (validation).

## Data Fetch Strategy

1. Query Census QWI API for all states, NAICS 512, races A1/A2/A5, quarterly 2001-2024
2. Also fetch NAICS 722 (Food Services) as placebo sector
3. Compile film tax credit treatment dates from NCSL database
4. Fetch QWI total (all races) for comparison
