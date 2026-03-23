# Research Plan: The Quota Windfall — Business Formation Effects of Florida's Liquor License Lottery

## Research Question

Does expanding the supply of liquor licenses through lottery allocation increase employment and business activity in the drinking-place sector? Florida's annual Quota Alcoholic Beverage License Drawing randomly distributes 50–90 new licenses (each worth $50K–$1M+ on the secondary market) across 20–30 counties. This paper asks whether these supply-side shocks to regulatory access translate into real economic activity or merely redistribute existing rents.

## Identification Strategy

**Design:** Staggered difference-in-differences at the county-quarter level.

**Treatment:** County c receives N_ct new quota licenses in year t's annual drawing (typically June–August). The number of licenses allocated is determined by Florida Statutes §561.19: one quota license per 7,500 county residents. As counties grow past population thresholds, new licenses become available.

**Variation:** Not all counties receive new licenses each year. Among those that do, the number varies (1–10+). This creates an intensive-margin "dose" variable: new licenses per 10,000 population.

**Within-system placebo:** NAICS 7225 (Restaurants and Other Eating Places) do not require quota liquor licenses and serve as a within-county control sector. If employment gains in NAICS 7224 (Drinking Places) are driven by county-level demand shocks rather than license supply, we should see parallel effects in NAICS 7225. A null placebo result strengthens the supply interpretation.

**Pre-trends:** Event-study specification centered on the lottery quarter, showing quarters -8 to +8 relative to license allocation. Flat pre-trends validate the parallel-trends assumption.

## Expected Effects and Mechanisms

**Primary hypothesis:** New quota licenses increase county-level employment in drinking places (NAICS 7224). The mechanism is regulatory supply expansion: binding license quotas constrain entry, and new allocations relax this constraint.

**Alternative:** If secondary market transfers dominate (winners flip licenses to existing operators), new allocations may have zero net effect on employment — they merely transfer regulatory rents.

**Magnitude prior:** Each new license could create 5–15 direct jobs (typical bar employment). With 50–90 licenses statewide per year across ~67 counties, effects may be modest at the county level but detectable in the quarterly data.

## Primary Specification

Y_{c,t} = α_c + γ_t + β × NewLicenses_{c,t} + X'_{c,t}δ + ε_{c,t}

Where:
- Y_{c,t}: QWI employment or earnings in NAICS 7224 for county c, quarter t
- α_c: county fixed effects
- γ_t: quarter fixed effects
- NewLicenses_{c,t}: count of new quota licenses allocated to county c in the drawing associated with quarter t (annual, mapped to Q3)
- X_{c,t}: county population (time-varying control)
- Clustering: county level

Event-study variant: interact treatment leads/lags with indicators for quarters relative to the lottery drawing.

## Data Sources and Fetch Strategy

1. **Census QWI (Quarterly Workforce Indicators):** County-quarter employment and earnings for Florida, NAICS 7224 (Drinking Places) and 7225 (Restaurants/Eating Places). API endpoint: `api.census.gov/data/timeseries/qwi/sa`. Years: 2012–2024.

2. **DBPR Lottery Allocation Data:** Florida Division of Alcoholic Beverages and Tobacco publishes annual winner PDFs at `www2.myfloridalicense.com/abt/licensing/quota_winners/`. Parse PDFs to extract county-level winner counts by year (2015–2024). Also fetch Entrants Summary PDFs for applicant counts.

3. **Population Data:** Census Population Estimates Program (PEP) for annual county populations, used to normalize license allocations (licenses per 10,000 pop) and as a time-varying control.

## Key Risks

1. **PDF parsing failure:** DBPR PDFs may be inconsistently formatted across years. Mitigation: validate parsed counts against known totals from entrants summaries.
2. **Small dosage:** Each county receives 0–5 new licenses per year. County-level effects may be small relative to baseline employment. Mitigation: focus on intensive-margin specification and rate outcomes (employment per 10,000 pop).
3. **Population endogeneity:** Counties receiving licenses are growing — growth drives both license allocation and employment. Mitigation: county FE absorb levels; population control captures trends; placebo sector (7225) nets out county-level demand shocks.
