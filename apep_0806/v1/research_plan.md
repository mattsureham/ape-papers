# Research Plan: Ireland's Rent Pressure Zones — Staggered DiD

## Research Question

Did Ireland's Rent Pressure Zone (RPZ) designations — which capped annual rent increases at 4% — actually constrain rent growth relative to what would have occurred absent the policy?

## Policy Background

The Residential Tenancies (Amendment) Act 2015 empowered the RTB to designate LEAs as RPZs where rents could not increase by more than 4% per annum. Designation was staggered:
- **December 2016**: Dublin City and commuter belt LEAs (first wave)
- **2017–2019**: Cork, Galway, and additional commuter areas
- **2020–2022**: Remaining LEAs — by end-2022, all of Ireland is RPZ

Criteria for designation: >7% rent inflation for 4 of past 6 quarters AND rent above national average.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD:**
- **Unit**: Local Electoral Area (LEA) or county
- **Treatment**: Quarter in which LEA was designated as RPZ
- **Outcome**: Quarterly log median rent, quarterly rent growth rate
- **Control**: Not-yet-treated LEAs (and never-treated through ~2020 for rural LEAs)
- **Pre-treatment**: 2014Q1–2016Q3 (10 quarters before first treatment)
- **Post-treatment**: Up to 2023Q4

**Key identifying assumption**: Parallel trends in rent growth across LEAs prior to RPZ designation. The staggered rollout based on observable criteria (rent inflation thresholds) provides variation, though I must address selection on the running variable.

## Expected Effects and Mechanisms

1. **Direct effect**: RPZ caps should slow nominal rent growth in treated LEAs (negative ATT on rent growth)
2. **Supply channel**: If caps make landlording less profitable, rental supply may contract (rising vacancies, shift to owner-occupied)
3. **Composition channel**: If only new-tenancy rents are measured, caps may appear ineffective because landlords reset rents at turnover
4. **Heterogeneity**: Early designees (Dublin, hot markets) vs. late designees (rural, moderate markets) may respond differently

## Primary Specification

```
ATT(g,t) via Callaway-Sant'Anna (did package in R)
Y = log(median_rent) or quarterly rent growth
G = quarter of RPZ designation
X = LEA-level covariates (population, initial rent level)
Clustering: LEA level
```

## Data Sources

1. **RTB Quarterly Rent Index**: Median standardized rents by property type and location (LEA or county), 2007–present. Source: rtb.ie/research/rent-index
2. **CSO Residential Property Price Index (HPA09)**: Property prices by county, monthly. Source: data.cso.ie
3. **RPZ Designation Dates**: Official list from RTB website with exact designation dates per LEA. Source: rtb.ie/registration-and-compliance/rents/rent-pressure-zones/
4. **CSO Census/Population**: LEA-level population for controls

## Fetch Strategy

1. Download RTB Rent Index CSV/Excel from RTB research page
2. Query CSO PxStat API for HPA09 (property prices) and population data
3. Scrape/download RPZ designation dates from RTB
4. Construct LEA-quarter panel merging rents with treatment timing

## Exposure Alignment

**Who is affected:** RPZ designation applies to all registered private rental tenancies within designated LEAs. The treatment constrains landlords from raising rents by more than 4% per annum on existing tenancies and caps new-tenancy rents relative to the previous registered rent.

**Alignment with outcome:** The outcome (RTB standardised average rent) directly measures rents subject to the RPZ cap. Since RTB registration is mandatory for all private tenancies, the outcome captures the treated population. The county-level aggregation may dilute the treatment signal where only some LEAs within a county are designated, but the standardised rent is a weighted average of all tenancies including those in designated LEAs.

**Timing:** Treatment is measured at the quarter of first LEA designation within each county. Rents respond with a lag (existing tenancies adjust at renewal, typically annually), so the full treatment effect may take 4-8 quarters to manifest.

## Robustness

- Event-study plots of pre-trends
- Alternative estimators: Sun-Abraham, Borusyak-Jaravel-Spiess
- Placebo: test effect on property sale prices (not directly regulated)
- Heterogeneity by early vs. late cohort
- Bacon decomposition to check TWFE bias
