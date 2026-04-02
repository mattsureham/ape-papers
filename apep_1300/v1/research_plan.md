# Research Plan: The Racial Dividend of the Warehouse Boom

## Research Question

Did Amazon fulfillment center (FC) entry disproportionately increase Black employment and earnings in US county labor markets? The warehouse boom of 2010–2022 created hundreds of thousands of logistics jobs in counties where Black workers were already over-represented in transportation/warehousing. This paper estimates whether staggered FC openings generated a *racial employment dividend* — larger gains for Black workers than for other racial groups — or whether displacement of incumbent logistics firms offset potential gains.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered difference-in-differences.**

- **Treatment:** County receives its first Amazon FC in year *t* (staggered 2010–2022)
- **Control:** Counties that never received an FC, plus not-yet-treated counties
- **Unit of observation:** County × quarter × race
- **Key advantage:** ~350 treated counties with staggered timing across 12+ years; ~2,790 never-treated counties as controls

The identifying assumption is parallel trends: absent Amazon FC entry, Black (and White/Hispanic) warehousing employment in treated counties would have evolved in parallel with control counties. We test this with:
1. Event study plots showing pre-trend dynamics (≥8 pre-periods for most cohorts)
2. Placebo tests on non-warehousing industries (NAICS sectors where Amazon FCs should not operate)
3. Leave-one-out robustness dropping each treatment cohort

## Expected Effects and Mechanisms

**Primary hypothesis:** Amazon FC entry increases warehousing employment in treated counties, with *disproportionately larger* gains for Black workers (a racial dividend) because:
1. Logistics jobs require no college degree — lower barriers to entry
2. Black workers are already over-represented in NAICS 48-49 (16% in 2010, rising to 22% by 2022)
3. Amazon's $15 minimum wage (announced 2018) may have compressed racial wage gaps

**Competing hypothesis (displacement):** Amazon FCs may crowd out incumbent warehousing/logistics employers, destroying existing jobs while creating new ones. If displaced workers face worse re-employment prospects, net effects could be negative.

**Expected magnitudes:**
- Total warehousing employment: positive, moderate (0.05–0.15 SD)
- Black warehousing employment: positive, larger than overall (0.08–0.20 SD)
- Earnings: positive but smaller (Amazon's $15/hr may compress wages upward for entry-level)
- Hire rates: positive (high turnover at FCs creates continuous labor demand)

## Primary Specification

$$Y_{c,t,r} = \alpha_{c,r} + \gamma_t + \text{ATT}(g,t) + \varepsilon_{c,t,r}$$

where:
- $Y_{c,t,r}$ is log employment (or earnings) in county $c$, quarter $t$, race $r$
- $\alpha_{c,r}$ are county-by-race fixed effects
- $\gamma_t$ are time fixed effects
- ATT(g,t) is the group-time average treatment effect (Callaway-Sant'Anna)
- Standard errors clustered at the county level

**Heterogeneity:** We estimate separate ATTs for:
1. Black vs. White vs. Hispanic workers (triple difference flavor)
2. High vs. low pre-existing Black workforce share counties
3. Pre-2018 vs. post-2018 FC openings (before/after $15 minimum wage)

## Data Sources

1. **QWI Race Panel (Azure):** `az://apepdata/derived/qwi/rh/ns/*.parquet` — 143.9M rows, county×quarter×industry×race. NAICS 48-49 (Transportation and Warehousing). Confirmed: 3,140 counties, employment + earnings + hire/separation rates by race.

2. **Amazon FC Openings:** MWPVL International public FC tracker (https://www.mwpvl.com/html/amazon_com.html). Scrape county-level opening dates for all US FCs 2010–2022. Cross-reference with press reports for validation.

3. **County Controls (ACS):** Population, demographics, education, income from Census ACS for pre-treatment county characteristics. Available via `tidycensus`.

## Exposure Alignment

The treatment is Amazon FC entry at the county level. The outcome (QWI warehousing employment by race) measures workers employed in NAICS 48-49 establishments located in the same county. This aligns treatment and outcome at the same geographic level: Amazon opens a facility in county $c$, and we measure employment changes in county $c$'s transportation/warehousing sector. Workers who commute across county lines to work at the FC are captured in the workplace county's QWI data (QWI reports by establishment location, not worker residence). This means the estimated effect reflects labor demand at the point of production, not residential labor supply effects, which is the appropriate estimand for measuring Amazon's direct and indirect employment impact.

## Fetch Strategy

1. Query Azure QWI parquet files via DuckDB for NAICS 48-49, all races, 2005–2023
2. Scrape MWPVL Amazon FC tracker for facility locations and opening dates
3. Geocode FC addresses to county FIPS codes
4. Merge treatment timing with QWI panel
5. Fetch county-level ACS controls via tidycensus for baseline characteristics
