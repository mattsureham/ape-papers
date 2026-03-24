# Research Plan: apep_0874

## Title
Feeding the Supply Side: Did Higher SNAP Benefits Attract Grocery Investment to Food Deserts?

## Research Question
Did the October 2021 Thrifty Food Plan (TFP) revision — which permanently increased maximum SNAP benefits by 21% ($36B/year) — attract new food retailers to counties with high SNAP participation?

## Identification Strategy
Continuous difference-in-differences at the county level. Treatment intensity is the county's pre-TFP SNAP participation rate (ACS 2019) interacted with the per-person monthly benefit increase ($36.24). Counties with higher SNAP participation received larger demand shocks. The identifying assumption is that, absent the TFP revision, new retailer authorization trends would have evolved similarly across counties with different SNAP participation rates (parallel trends in levels, conditional on county and time fixed effects).

### Separating TFP from Emergency Allotments (EA)
The TFP revision (permanent, Oct 2021) overlapped with Emergency Allotments (temporary, ended state-by-state 2021-2023). Key separation strategies:
1. EA end dates are state-level, not county-level — county SNAP rate variation within states isolates TFP
2. Include state-level EA controls (indicator for active EA period by state)
3. Robustness: restrict to post-EA period (2023Q2+) where only TFP persists
4. Robustness: exclude early EA opt-out states

## Data Sources
1. **USDA SNAP Retailer Historical Database** (703K records, 2005-2025): Authorization dates, store types, county, geocoded locations. Primary outcome: new SNAP retailer authorizations per county-quarter.
2. **ACS 2019 5-Year** (Census API): County-level SNAP participation rates, population, poverty rates, demographics. Treatment intensity construction.
3. **QWI county-quarter** (Azure, NAICS 4451): Food retail employment. Secondary outcome.

## Unit of Analysis
County-quarter panel, ~3,100 counties × 25 quarters (2016Q1-2022Q2 pre, 2021Q4-2024Q4 post).

## Estimation
$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot (\text{SNAPrate}_c \times \text{Post}_t) + \delta \cdot \text{EA}_{st} + \mathbf{X}'_{ct}\Gamma + \varepsilon_{ct}$$

Where:
- $Y_{ct}$: new SNAP retailer authorizations in county $c$, quarter $t$
- $\alpha_c$: county fixed effects
- $\gamma_t$: quarter fixed effects
- $\text{SNAPrate}_c$: ACS 2019 SNAP participation rate (continuous treatment intensity)
- $\text{Post}_t$: indicator for $t \geq$ 2021Q4
- $\text{EA}_{st}$: indicator for active Emergency Allotments in state $s$, quarter $t$
- Standard errors clustered at county level

## Outcomes
1. Primary: New SNAP retailer authorizations per county-quarter (count and rate per 1,000 existing stores)
2. By store type: Supermarkets vs. convenience stores vs. other
3. Secondary: QWI food retail employment (if available)

## Robustness Checks
1. Pre-trends: Event-study coefficients for pre-treatment quarters
2. State × quarter fixed effects (absorbs all state-level confounders including EA)
3. Placebo treatment date (2019Q4)
4. Exclude early EA opt-out states
5. Alternative treatment intensity measures (poverty rate, median income)

## Tables (max 5)
1. Summary statistics
2. Main results (continuous DiD)
3. Heterogeneity by store type
4. Robustness panel
5. SDE (appendix)

## Timeline
- Phase 1: Data fetch and cleaning
- Phase 2: Main analysis and robustness
- Phase 3: Paper writing and validation
- Phase 4: Review and publication
