# Research Plan: The Speculator's Delay — How Lottery-Allocated Federal Leases Shaped Western County Economies

## Research Question

Does the mechanism of federal oil and gas lease allocation — random lottery vs. competitive auction — affect long-run county economic outcomes in the Western United States? Specifically, did counties where a larger share of federal leases were allocated via BLM's simultaneous filing lottery (which disproportionately assigned leases to speculators rather than developers) experience systematically different economic trajectories?

## Identification Strategy

**County-level instrumental variable (IV) using lottery share.**

The BLM's simultaneous filing procedure (1960s–mid-1990s) resolved competing noncompetitive lease applications by random drawing. When multiple applications arrived within the 5-day simultaneous filing window, a lottery determined the winner. The GAO documented that many lottery winners were speculators who flipped leases rather than developing them (EMD-79-41), creating systematic delays in drilling.

**Instrument:** For each Western county, the share of total federal oil/gas lease acreage allocated via lottery (case type 3112xx) vs. competitive sale (case type 3111xx). This captures exogenous variation in initial leaseholder composition (speculator vs. developer).

**First stage:** Higher lottery share → delayed drilling development (speculators hold/flip rather than drill). Brehm (2021, RAND Journal of Economics) confirmed this at the parcel level in Wyoming.

**Exclusion restriction:** Conditional on total leasable federal acreage in a county, the allocation mechanism (lottery vs. competitive) is orthogonal to county economic fundamentals. The lottery was triggered by filing timing, not parcel quality.

**Reduced form:** Compare county economic trajectories as a function of lottery share, controlling for total federal mineral acreage.

## Expected Effects and Mechanisms

1. **Speculator delay mechanism:** Counties with high lottery share experienced delayed drilling onset, potentially missing boom-period prices and reducing peak resource rents.
2. **Timing-of-extraction channel:** If extraction timing relative to price cycles matters, lottery counties may show different boom-bust amplitude.
3. **Long-run divergence:** Resource economics predicts that timing of extraction affects human capital investment, infrastructure, and industry diversification (Dutch disease timing).

**Direction:** Ambiguous ex ante. Delayed extraction could be harmful (missed booms, delayed investment) or beneficial (avoided bust-related scarring, more orderly development). This is a genuine empirical question.

## Primary Specification

**Reduced-form county panel:**

$$Y_{ct} = \alpha + \beta \cdot \text{LotteryShare}_c \times \text{Post}_t + \gamma X_{ct} + \delta_c + \theta_t + \varepsilon_{ct}$$

Where:
- $Y_{ct}$: County employment, income per capita, population, or industry composition
- $\text{LotteryShare}_c$: Share of federal O&G acreage allocated by lottery (time-invariant)
- $\text{Post}_t$: Indicator for post-lottery-era periods (or continuous time trend interaction)
- $X_{ct}$: Controls (total federal mineral acreage, state trends)
- $\delta_c, \theta_t$: County and year fixed effects

**Event-study variant:** Interact lottery share with year dummies to trace out dynamics.

## Data Sources and Fetch Strategy

1. **BLM General Land Office (GLO) API** — Federal oil/gas lease records
   - Endpoint: BLM ArcGIS REST API (public, no auth)
   - Case type 3112xx = simultaneous filing (lottery)
   - Case type 3111xx = competitive leases
   - Fields: location (state, county, township/range), acreage, date, case type
   - Expected: ~118K lottery leases, ~244K competitive leases

2. **BEA Regional Economic Accounts (REIS)** — County economic outcomes
   - API: `apps.bea.gov/api/data` with BEA_API_KEY
   - Tables: CAINC1 (personal income), CAEMP25N (employment by industry)
   - Years: 1969–2023
   - Coverage: All US counties

3. **Census County Business Patterns (CBP)** — Establishment counts by industry
   - Source: Census Bureau API
   - Years: 1986–2022
   - Key sectors: Mining (NAICS 21), Construction, Manufacturing, Services

## Key Risks

1. **County-level aggregation:** Lottery share is computed from parcel-level data aggregated to county. Sufficient variation across ~200+ counties needed.
2. **Exclusion restriction:** Must argue that lottery share is uncorrelated with county-level confounders conditional on total federal acreage.
3. **First-stage strength:** The link between allocation mechanism and drilling timing at the county level (vs. Brehm's parcel-level result) needs verification.
4. **Data linkage:** BLM records use township/range locations that must be mapped to FIPS county codes.
