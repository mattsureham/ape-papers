# Initial Research Plan: Pump Price Pass-Through and Household Welfare After Nigeria's 2023 Fuel Subsidy Removal

## Research Question

Does the removal of Nigeria's fuel subsidy on May 29, 2023, produce heterogeneous price pass-through across states, and does this geographic heterogeneity — driven by distance from petroleum import terminals — translate into differential household welfare losses?

## Background

Nigeria's Premium Motor Spirit (PMS) subsidy was one of the largest fiscal interventions in Sub-Saharan Africa, costing approximately $10 billion per year. The subsidy maintained a uniform national retail price by absorbing distribution costs. When removed, these distribution costs — primarily driven by trucking distances from the three major petroleum import terminals (Lagos/Apapa, Port Harcourt, Warri) — were suddenly passed through to consumers. The key insight: under the subsidy regime, a litre of fuel cost the same in coastal Lagos as in landlocked Borno, 1,500km from the nearest terminal. After removal, geographic distance from terminals became the primary determinant of local fuel prices.

## Identification Strategy

**Design:** Difference-in-differences with continuous treatment intensity.

**Treatment variable:** Straight-line distance (km) from each state capital to the nearest major petroleum import terminal (Lagos/Apapa, Port Harcourt, or Warri).

**Primary specification (state-month panel):**

```
log(fuel_price_st) = α_s + γ_t + β(Post_t × Distance_s) + ε_st
```

where:
- α_s: state fixed effects (absorb persistent cross-state differences)
- γ_t: month fixed effects (absorb common supply shocks, naira depreciation)
- Post_t: indicator for months ≥ June 2023
- Distance_s: distance from state capital to nearest terminal (km)
- β: the DiD coefficient — does price pass-through scale with distance?

**Identifying assumption:** Conditional on state and month fixed effects, distance from terminals does not predict differential fuel price trends in the pre-reform period. Testable with 18 months of pre-period data (Jan 2022 – May 2023).

**Key threats and mitigants:**
1. *Road quality correlates with distance:* State FE absorb time-invariant road infrastructure
2. *Dangote Refinery opening (late 2023):* Robustness check excluding post-Dangote months
3. *Parallel market dynamics:* Month FE absorb common naira depreciation

## Expected Effects and Mechanisms

**Primary:** β > 0 — farther states experience larger price increases per km of distance.

**Mechanism channel:**
1. **Transport cost pass-through:** Distribution costs from terminals to inland states scale with distance. Under the subsidy, these were absorbed; after removal, they appear in retail prices.
2. **Competition gradient:** Coastal states have more fuel depots and distributors → more competition → lower margins → smaller pass-through per km.
3. **Informal market penetration:** In remote states, informal fuel sales at higher prices may partially substitute for formal retail.

**Downstream welfare effects (GHS-Panel):**
- Transport fares increase more in distant states
- Food prices increase more in distant states (transport-cost-driven)
- Household food insecurity scores increase more in distant states
- Generator use and energy expenditure shift

## Primary Specification

**Panel A: Price Pass-Through (State × Month)**
- Y: log(PMS pump price)
- Treatment: Post × Distance
- FE: State + Month
- Clustering: State level (37 clusters)
- Sample: Jan 2022 – Dec 2024 (36 months × 37 states = 1,332 obs)

**Panel B: Transport Fare Pass-Through (State × Month)**
- Y: log(intercity bus fare), log(within-city bus fare), log(motorcycle fare)
- Treatment: Post × Distance
- FE: State + Month
- Clustering: State level

**Panel C: Household Welfare (GHS-Panel)**
- Y: Food insecurity score, energy expenditure share, transport expenditure share
- Treatment: State-level price increase (instrumented by distance)
- FE: Household + Wave
- Clustering: State level

## Planned Robustness Checks

1. **Pre-trends test:** Event study interacting Distance × month dummies; test joint significance of pre-period coefficients
2. **Leave-one-out:** Drop each state; check stability of β
3. **Alternative distance measures:** Road distance (vs. straight-line), distance to nearest depot (vs. terminal)
4. **Bandwidth sensitivity:** Varying pre/post window (12 months, 18 months, 24 months)
5. **Placebo outcomes:** Prices of goods without distribution cost component (mobile airtime, utility bills)
6. **Dangote Refinery control:** Exclude post-October 2023 (when Dangote began limited operations)
7. **Wild cluster bootstrap:** Given 37 clusters, report bootstrap p-values alongside asymptotic
8. **Randomization inference:** Permute distance assignments across states

## Built-in Placebo

**Mobile phone airtime prices** — nationally uniform pricing set by telecoms, no distribution cost component. If β is driven by genuine distribution costs, there should be zero distance × post interaction for airtime prices.

## Data Sources

1. **NBS PMS Price Watch** (monthly, state-level pump prices): nigerianstat.gov.ng
2. **NBS Transport Fare Watch** (monthly, state-level transport fares): nigerianstat.gov.ng
3. **Nigeria GHS-Panel** (5 waves, household panel): World Bank Microdata Library
4. **Petroleum terminal locations:** NNPC/PPMC infrastructure maps (known coordinates)
5. **State capital coordinates:** Standard geographic reference

## Power Assessment

- **Clusters:** 37 states (continuous treatment)
- **Pre-periods:** 18 months (monthly)
- **Post-periods:** 18 months (monthly)
- **MDE:** With 37 clusters and 18 pre/post periods, the design is well-powered for detecting moderate effects. The first-month cross-state spread of ₦83/litre suggests strong first-stage variation.

## Timeline

1. Fetch NBS price and fare data (monthly reports)
2. Construct distance measures from terminal coordinates
3. Build state × month panel
4. Run primary DiD specifications
5. Event study and pre-trends validation
6. Robustness battery
7. GHS-Panel welfare analysis
8. Write paper
