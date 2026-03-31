# Research Plan: apep_1212

## Research Question

Did anti-Asian sentiment during COVID-19 disproportionately push Asian American workers out of customer-facing sectors, and did this discrimination operate as a sorting mechanism that accelerated reallocation into knowledge-economy sectors?

## Identification Strategy

**Triple-difference (DDD):**
- D1: Asian (A4) vs White (A1) workers — absorbs sector-specific COVID shocks
- D2: Customer-facing (NAICS 72 Hospitality, 44-45 Retail) vs knowledge-economy (NAICS 54 Professional, 51 Information) — absorbs race-specific shocks
- D3: High vs low anti-Asian media intensity states (continuous) — absorbs state-level general COVID severity

**Key identifying assumption:** Absent differential anti-Asian sentiment, the relative employment gap between Asian and White workers in customer-facing vs knowledge sectors would have evolved similarly across high- and low-sentiment states.

**Threats and responses:**
- COVID lockdowns: Absorbed by DDD (White workers in same state-sector serve as control)
- Differential industry exposure by race pre-COVID: Event study with 12 pre-periods (2017Q1-2019Q4) tests parallel trends
- State-level COVID severity correlation with sentiment: Control for COVID death rates per capita × race × sector
- Selective migration: Test using state-level inflows/outflows

## Expected Effects and Mechanisms

1. **Primary:** Negative DDD coefficient — Asian workers in customer-facing sectors in high-sentiment states experienced disproportionately larger employment declines
2. **Reallocation mechanism:** Positive DDD for knowledge-economy sectors — displaced Asian workers reallocated to non-customer-facing roles
3. **Persistence:** Effects persist beyond pandemic (through 2022-2024), suggesting permanent reallocation rather than temporary displacement
4. **Atlanta spa shootings (March 2021):** Sharp event study provides within-design replication

## Primary Specification

$$Y_{s,r,j,t} = \alpha + \beta_1 (Asian_r \times CustomerFacing_j \times AntiAsianMedia_{s,t}) + \gamma_{s,t} + \delta_{r,j} + \mu_{s,j} + \nu_{r,t} + \varepsilon_{s,r,j,t}$$

Where:
- $Y$: employment (log), hires, separations, earnings
- $s$: state, $r$: race (Asian/White), $j$: sector (customer-facing/knowledge), $t$: quarter
- $AntiAsianMedia_{s,t}$: GDELT-based anti-Asian article rate per 10k articles by state-quarter
- Fixed effects absorb all two-way combinations

**Clustering:** State level (51 clusters)
**Inference:** Wild cluster bootstrap as robustness (moderate cluster count)

## Data Sources

1. **QWI (Azure):** `az://derived/qwi/rh/ns/*.parquet` — state × quarter × race × NAICS sector, 2016-2024. Variables: Emp, HirA, Sep, EarnS.
2. **GDELT GKG (BigQuery):** `gdelt-bq.gdeltv2.gkg_partitioned` — construct anti-Asian media intensity by state-quarter using theme co-occurrence (discrimination/hate + Asian/China themes).
3. **COVID controls:** Johns Hopkins CSSE or NYT COVID data — state-quarter death rates.

## Execution Plan

1. Fetch QWI race × industry data from Azure Parquet files
2. Construct GDELT anti-Asian media intensity from BigQuery
3. Merge panels, construct DDD variables
4. Run main DDD specification
5. Event study around Atlanta spa shootings (March 2021)
6. Robustness: wild cluster bootstrap, alternative sentiment measures, excluding outlier states
7. Mechanism: decompose into hires vs separations, test earnings changes
