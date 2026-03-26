# Research Plan: Armed and Unoccupied? Permitless Carry Laws and Racial Disparities in Accommodation-Sector Employment

## Research Question

Do permitless (constitutional) carry laws — which remove concealed-carry permit requirements — differentially reduce Black employment in customer-facing industries? The hypothesis is that expanding visible gun carrying in public spaces interacts with racialized perceptions of threat, making customer-facing workplaces (accommodation, food services) feel less safe for Black workers and potentially altering employer or customer behavior in ways that reduce Black employment relative to White employment in those sectors.

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway-Sant'Anna (2021).

- **Treatment:** State-level adoption of permitless concealed carry. 29 states adopted between 2003 and 2024, with a major wave in 2021 (UT, MT, IA, TN, TX). 10 states never adopted (CA, NY, NJ, IL, MA, CT, MD, HI, DE, RI) serve as never-treated controls.
- **Unit of observation:** County × quarter × race (Black vs White) × industry (NAICS 72 Accommodation & Food Services).
- **Parallel trends assumption:** Pre-treatment trends in Black-White employment gaps within the accommodation sector should be similar across soon-to-adopt and not-yet-adopted states.

**Triple-difference (DDD):** State × post × customer-facing industry (NAICS 72) vs. non-customer-facing industry (NAICS 31-33 Manufacturing). If the mechanism operates through public-space interactions, effects should concentrate in customer-facing sectors.

**Falsification:**
1. Manufacturing (NAICS 31-33) as placebo sector — no customer-facing exposure.
2. Mining (NAICS 21) as additional placebo — non-urban, not customer-facing.
3. White employment in accommodation as placebo outcome — if the mechanism is racial, effects should be weaker for White workers.

## Expected Effects and Mechanisms

- **Primary:** Permitless carry → reduced Black employment in accommodation/food services (negative effect).
- **Mechanism:** Racialized safety perceptions. Expanded legal gun carrying in public spaces may (a) make Black workers in customer-facing roles feel less safe, increasing voluntary separations; (b) alter customer behavior in ways that reduce demand for establishments with diverse workforces; (c) increase employer discrimination if armed-customer incidents are racialized.
- **Heterogeneity:** Effects should be larger in (a) high-tourism counties (more customer exposure), (b) urban counties (more public-space interaction), (c) states with higher baseline gun ownership.

## Primary Specification

```
Y_{c,t,r} = α + τ_ATT(g,t) + γ_c + δ_t + ε_{c,t,r}
```

Where Y is log employment (or hiring rate) for race r in county c at quarter t. Using `did` package for Callaway-Sant'Anna ATT(g,t) estimates, aggregated to overall ATT and dynamic event-study coefficients. Clustering at the state level (29 treated + 10 never-treated = 39 clusters minimum).

## Data Source and Fetch Strategy

**Primary data:** Quarterly Workforce Indicators (QWI) from the Census Bureau's LED program.
- Available on Azure: `derived/qwi/rh/n3/*.parquet` — county × quarter × race/ethnicity × 3-digit NAICS.
- Variables: Emp (employment), HirA (all hires), Sep (separations), EarnHirAS (average new-hire earnings).
- Time period: 2003-2024 (varies by state; most states available from 2005+).
- Race categories: White alone (A1), Black alone (A2).

**Treatment timing:** Permitless carry adoption dates compiled from published legal databases (Rand Corporation, Giffords Law Center). Hard-coded from verified sources.

**Additional data:**
- County-level tourism intensity: BEA CAEMP25 (leisure & hospitality share of total employment, pre-treatment).
- County urban/rural classification: USDA Rural-Urban Continuum Codes.

## Key Risks

1. **Composition effects:** States adopting permitless carry tend to be rural, Southern/Western, Republican. Must verify parallel pre-trends carefully.
2. **Confounders:** COVID-19 overlaps with the 2021 wave. Will test robustness excluding 2020-2021 and using pre-2020 adopters only.
3. **Power:** Black employment in accommodation may have small cell sizes in rural counties. Will assess suppression rates in QWI and potentially aggregate to state-quarter.
4. **QWI suppression:** Census suppresses small cells for disclosure avoidance. May need to work at state × quarter level if county-level Black employment is too sparse.
