# Research Plan: When the Bell Rings for Everyone

## Research Question

Do state universal free school meal mandates improve household food security? When eight US states made pandemic-era universal free school meals permanent (2022–2024), 42 states reverted to means-tested eligibility. This paper estimates the causal effect of retaining universal provision on food security for households with school-age children.

## Policy Background

COVID-19 triggered nationwide universal free school meals (USDA waivers, March 2020–June 2022). When waivers expired, eight states legislated permanent universal free meals for all public school students:

| Cohort | States | Effective Date |
|--------|--------|----------------|
| 1 | California, Maine | July 2022 |
| 2 | Colorado, Michigan, Minnesota, Vermont | July 2023 |
| 3 | New Mexico, Massachusetts | July 2024 |

This differs from the Community Eligibility Provision (CEP), which is school-level and poverty-targeted. These mandates cover ALL public schools statewide, regardless of school poverty rate.

## Identification Strategy

### Primary: Triple-Difference (DDD)

$$Y_{ist} = \alpha + \beta_1 (\text{Treat}_s \times \text{SchoolAge}_i \times \text{Post}_t) + \gamma X_{ist} + \delta_s + \lambda_t + \mu_{st} + \nu_{it} + \varepsilon_{ist}$$

Three margins of variation:
1. **State:** Treated (8 states that kept universal) vs. Control (42 states that reverted)
2. **Household type:** Households with school-age children (5–18) vs. without
3. **Time:** Post-waiver expiration (academic year 2022–23 onward) vs. pre-period

The triple-diff nets out state-level shocks (affecting all households) and nationwide trends for families with children. The identifying assumption is that the *differential* trend between households with and without school-age children would have been parallel across treated and control states absent the policy.

### Robustness
- Callaway-Sant'Anna (2021) staggered DiD exploiting the three cohorts
- Event-study plots for pre-trend validation
- Leave-one-state-out jackknife
- Placebo: households with children aged 0–4 only (not yet in school)
- Heterogeneity: near-poor (130–185% FPL) vs. poor (<130% FPL) vs. non-poor (>185%)

## Expected Effects and Mechanisms

**Primary mechanism:** Universal free meals eliminate both direct costs (meal prices for non-qualifying families) and stigma/paperwork barriers. Near-poor families (just above FRL eligibility thresholds) benefit most because they previously paid full or reduced prices.

**Expected signs:**
- Food security: positive (reduced food insecurity)
- SNAP participation: ambiguous (could substitute away from SNAP, or SNAP+meals are complements)
- Food spending: negative (freed-up household budget)

## Data Sources

### Primary: CPS Food Security Supplement (December annually)
- Source: IPUMS CPS or Census Bureau
- Years: 2019, 2021, 2022, 2023 (skip 2020 — COVID field disruptions)
- Key variables: FSSTATUS (food security status), SNAP receipt, children's food security, state FIPS, household demographics
- Sample: ~54,000 households/year; ~15,000 with school-age children

### Secondary: USDA NSLP Participation Data
- State-level monthly participation counts
- Used for first-stage verification: do treated states show participation jumps?

## Primary Specification

Outcome: Binary indicator for food insecurity (FSSTATUS = low or very low food security)

Unit: Household-year
Treatment: State enacted permanent universal free meals × household has school-age child × post-waiver period
Clustering: State level (50 states + DC)
Controls: Household size, income-to-poverty ratio, race/ethnicity, education, urban/rural, single-parent indicator

## Feasibility Assessment

- **Treated units:** 8 states (3 cohorts) — sufficient for state-level clustering
- **Pre-periods:** 2019 + 2021 = 2 clean pre-periods (2020 excluded due to COVID fieldwork issues; 2021 still had universal waivers but captures pre-state-mandate baseline)
- **Post-periods:** 2022 (Cohort 1 post), 2023 (Cohorts 1–2 post)
- **Sample size:** ~54,000 HH/year × 4 years ≈ 216,000 HH-year observations
- **Power:** Food insecurity rate ~11% nationally; school-age HH rate ~14%. With ~6,000 treated HH-years, MDE ≈ 2–3 pp
