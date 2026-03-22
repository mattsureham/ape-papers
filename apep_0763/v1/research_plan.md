# Research Plan: SNAP Emergency Allotment Expiration and Labor Supply

## Research Question
Does the expiration of SNAP Emergency Allotments — a sudden $95–$250/month benefit cut — increase labor supply, and does the effect differ by race?

## Policy Context
The Families First Coronavirus Response Act (March 2020) authorized SNAP Emergency Allotments (EA), increasing monthly benefits to the household maximum. By mid-2021, 18 states voluntarily terminated EA early (Idaho first, April 2021), while 32 states + DC continued through February 2023. This staggered termination creates a clean natural experiment: when you suddenly cut food assistance, do people work more?

## Identification Strategy
**Callaway-Sant'Anna staggered DiD.** Treatment = state-quarter of EA termination. 18 early-exit states are treated at different dates (2021Q2–2022Q4). 32 late-exit states serve as never-treated controls through the end of the panel. Pre-period: 2019Q1–2021Q1.

**Parallel trends:** Testable with 8+ pre-quarters. Both early and late states experienced COVID labor market shock simultaneously.

**Threats:** Early opt-out states are predominantly Republican-governed, which may correlate with other pro-work policies. Mitigated by: (a) state fixed effects absorb time-invariant differences; (b) pre-trend tests; (c) within-industry analysis (food service/retail where SNAP recipients concentrate).

## Exposure Alignment
EA termination directly reduces monthly income for SNAP households ($95–$250/month). SNAP recipients who need to replace this income have an incentive to increase work hours or seek employment. QWI captures formal employment and hiring at state-quarter level. Black workers (34% of SNAP households but 13% of population) face disproportionate exposure, creating a natural heterogeneity test.

## Data Sources
1. **QWI from Azure** (az://derived/qwi/rh/n3/*.parquet): State-quarter employment, new hires, earnings by race. 374.9M observations, all 50 states, 2019-2023.
2. **EA termination dates:** Constructed from USDA FNS and CBPP tracking (18 states, quarterly).
3. **FRED:** State unemployment rates as controls.

## Primary Specification
Callaway-Sant'Anna att_gt():
- yname = log(HirN) or HirN rate
- tname = quarter (numeric)
- idname = state FIPS
- gname = first quarter of EA termination (0 for never-treated)
- control_group = "nevertreated"

Standard errors clustered at state level.

## Expected Effects
- **New hires (HirN):** Positive — income loss creates work incentive
- **Employment (Emp):** Positive but smaller — new hires affect stock with a lag
- **Racial heterogeneity:** Larger effect for Black workers (higher SNAP dependence)
- **Industry heterogeneity:** Concentrated in food service (NAICS 72) and retail (NAICS 44-45)
