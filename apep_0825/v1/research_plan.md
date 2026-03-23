# Research Plan: apep_0825

## Research Question

Does anti-immigration political backlash propagate through social networks? Using Sweden's 2016 mandatory Settlement Act (Bosättningslagen), which assigned refugee quotas to all 290 municipalities via a formula-driven allocation, we test whether the 2018 Sweden Democrats (SD) surge spread through social network ties measured by the Facebook Social Connectedness Index (SCI) at NUTS3 county level.

## Identification Strategy

**Two-step design:**

1. **Own exposure (OLS):** ΔSD_vote_i(2014→2018) = α + β₁ × RefugeeQuota_i + γX_i + ε_i
   - 290 municipality-level observations
   - RefugeeQuota_i = refugees allocated per 1,000 residents under Bosättningslagen
   - Controls: baseline SD share (2014), population, income, education, foreign-born share

2. **Network exposure (SCI Bartik IV):**
   NetworkExposure_i = Σ_k SCI(county(i), k) × RefugeeQuota_k
   - Each municipality i gets exposure through its parent county's SCI vector
   - Tests whether SD vote increased more in municipalities whose social-network neighbors received larger refugee quotas, conditional on own quota
   - Exogeneity: formula weights are labor market capacity and population share — neither directly causes SD vote changes

**Why credible:** The 2016 Bosättningslagen eliminated voluntary refugee placement (pre-2016, municipalities could opt out). The mandatory quota creates quasi-experimental variation. The formula components (labor market capacity, population) are plausibly exogenous to SD vote changes conditional on controls.

## Expected Effects and Mechanisms

- **Own exposure:** Positive β₁ — municipalities receiving larger refugee quotas see larger SD gains. This replicates standard dispersal effects found in Denmark, Italy.
- **Network exposure:** Positive β₂ — municipalities whose network neighbors received more refugees also see SD gains, conditional on own exposure. This is the "networked backlash" mechanism: anti-immigration sentiment spreads through social ties.
- **Magnitude:** Based on apep_0464 (Italy), expect network effects roughly 50-80% the size of own effects.

## Primary Specification

Cross-sectional long difference: ΔSD_share_i(2014→2018) on own_quota_i and network_exposure_i, clustering at county level (21 clusters → wild cluster bootstrap).

## Data Sources

1. **Election results:** SCB API (`ME0104T4`) — municipality-level party vote shares, 2010/2014/2018/2022
2. **SCI:** Facebook Social Connectedness Index from HUMDATA — NUTS3 pairwise connectedness for Sweden's 21 counties
3. **Refugee quotas:** Migrationsverket/SCB data on municipal refugee allocations under Bosättningslagen
4. **Municipality characteristics:** SCB API — population, income, education, foreign-born share
5. **Swedish municipality-to-NUTS3 crosswalk:** SCB regional codes

## Fetch Strategy

1. SCB API: POST requests with JSON query bodies to the PX-Web API
2. SCI: Download nuts_2024.zip from HUMDATA, filter to Swedish NUTS3 codes (SE1xx, SE2xx, SE3xx)
3. Refugee data: SCB integration statistics tables or Migrationsverket open data
