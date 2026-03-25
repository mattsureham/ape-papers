# Research Plan: apep_0963

## Research Question

Did the October 2021 Thrifty Food Plan (TFP) revision — which permanently increased SNAP benefits by 21% ($36.24/person/month) — reduce household food insecurity? The TFP revision was the first substantive update to the SNAP benefit formula since the program's inception, injecting $36 billion per year into the food safety net. This paper provides the first causal evaluation of this policy change.

## Economic Object: The Adequacy Gap

The TFP revision tests whether SNAP was previously calibrated below the food security threshold. If the revision reduced food insecurity, it implies the old benefit level was systematically inadequate — what we call the "adequacy gap." A null result would imply SNAP benefits were already above the threshold and the marginal dollar went to non-food consumption.

## Identification Strategy

**Continuous difference-in-differences** with dosage variation.

- **Treatment intensity:** State pre-TFP SNAP participation rate (ACS 2019). States with higher SNAP participation receive a larger per-capita benefit injection from the 21% increase.
- **Pre-period:** December 2018, 2019 (pre-COVID, pre-TFP — clean baseline)
- **Post-period:** December 2022, 2023 (post-TFP; post-EA in most/all states)
- **Transition years dropped:** December 2020, 2021 (contaminated by COVID, Emergency Allotments, and only 2 months TFP exposure in 2021)

**Primary specification:**

FoodInsecure_{ist} = β₁(SNAP_rate_s × Post_t) + X_{ist}γ + δ_s + θ_t + ε_{ist}

- β₁ captures the differential change in food insecurity in higher-SNAP-participation states after the TFP revision
- State FE (δ_s) absorb time-invariant state differences
- Year FE (θ_t) absorb national trends
- Household controls (X_{ist}): income, education, race, household size, children present
- Standard errors clustered at state level

**Key identifying assumption:** Parallel trends in food insecurity across states with different SNAP participation rates, conditional on controls. Testable with pre-treatment data (2018 vs 2019).

**Triple-difference (robustness):** Interact treatment intensity × post × early-EA-end indicator. ~18 states ended Emergency Allotments before October 2021. In these states, the TFP revision is the only post-period benefit change, providing a cleaner identification.

## Expected Effects

- **Primary:** Negative β₁ — higher-SNAP states experience greater food security improvement post-TFP
- **Magnitude:** If the adequacy gap was real, expect economically meaningful reduction (SDE > 0.05)
- **Heterogeneity:** Larger effects for households with children, low-income, single-parent
- **Mechanism:** Reduced meal-skipping, fewer days without food, increased food spending

## Data Sources

1. **CPS Food Security Supplement** (December supplement, 2018-2023): Household-level food security status (HRFS12M1), SNAP receipt, state FIPS, demographics. ~42,000 households/year. Access via Census Bureau API or IPUMS CPS.

2. **ACS 2019 state SNAP participation rates:** Via tidycensus (Table B22003 or S2201). Pre-determined treatment intensity measure.

3. **Emergency Allotment end dates:** Hard-coded from USDA FNS/CBPP documentation. Binary indicator for EA active in state-year.

4. **State controls:** Unemployment rate (BLS LAUS), poverty rate (ACS), median household income (ACS).

## Outcomes

| Variable | Source | Type |
|----------|--------|------|
| Food insecure (binary) | CPS FSS HRFS12M1 ∈ {3,4} | Primary |
| Very low food security | CPS FSS HRFS12M1 = 4 | Primary |
| SNAP receipt | CPS FSS HESP1 | Mechanism |
| Meal skipping | CPS FSS FSSKIP | Mechanism |

## Robustness Checks

1. Wild cluster bootstrap (50 state clusters)
2. Include transition years (2020-2021) with EA controls
3. Placebo treatment year (2019)
4. Leave-one-out state analysis
5. Event-study specification (year-by-year × SNAP_rate interactions)
6. Alternative treatment measures (SNAP benefit levels instead of participation rates)
7. Permutation inference on treatment assignment

## Potential Threats

1. **COVID recovery heterogeneity:** States recovered from COVID at different rates, potentially correlated with SNAP participation. Mitigated by: (a) state FE absorb levels, (b) dropping 2020-2021, (c) controlling for state unemployment.
2. **EA phase-out confound:** Emergency Allotments ended at different times. Mitigated by: (a) triple-diff on EA timing, (b) using Dec 2023 as cleanest post-period (all EAs ended by March 2023).
3. **50 state clusters:** Borderline for clustered inference. Mitigated by wild cluster bootstrap.
