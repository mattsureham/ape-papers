# Research Plan: Frozen Out — The Local Housing Allowance Freeze and Rising Homelessness in England

## Research Question

Did the 2016–2020 freeze on Local Housing Allowance (LHA) rates causally increase statutory homelessness in England? The freeze created differential gaps between frozen LHA rates and actual 30th-percentile rents across 152 Broad Rental Market Areas, ranging from 0% to 39%. We exploit this exogenous, continuous variation in benefit adequacy to estimate the causal effect on homelessness.

## Identification Strategy

**Continuous Difference-in-Differences.** Treatment intensity = the percentage gap between the frozen LHA rate and the counterfactual 30th-percentile rent by BRMA, revealed when rates were re-linked in April 2020 (mean 14.2%, SD 7.9pp). The gap is driven entirely by differential rent growth during the freeze — the policy itself was uniform (all rates frozen simultaneously).

**Main specification:**
Y_{it} = α_i + γ_t + β(Gap_i × Post_t) + X_{it}'δ + ε_{it}

Where:
- Y_{it} = homelessness rate per 1,000 households in LA i, quarter t
- Gap_i = BRMA-level LHA-rent gap (assigned to LAs via postcode mapping)
- Post_t = 1 if t ≥ 2016Q2
- Controls: claimant count rate, ASHE median earnings, UC rollout timing
- Clustering: LA level

**Event study variant:** Replace Post_t with quarter dummies interacted with Gap_i to trace out pre-trends and dynamic effects.

## Expected Effects and Mechanisms

The LHA freeze should increase homelessness through:
1. **Affordability channel:** Rising rents with frozen benefits → private renters can't cover rent → Section 21 evictions → homelessness duty owed
2. **Prevention failure:** LAs in high-gap areas face larger caseloads, stretching prevention budgets
3. **Temporary accommodation:** More households in TA as throughput slows

Expected direction: **positive** (higher gap → more homelessness). Magnitude: moderate-to-large given the freeze affected millions of private renters.

## Placebo Tests

1. **Homeowner homelessness** — LHA only affects private renters; homeowner homelessness should show no relationship with the LHA-rent gap
2. **Pre-trend test** — event study coefficients for 2014Q2-2016Q1 should be zero

## Primary Data Sources

1. **LHA rates by BRMA** — VOA/DWP published rates (2014–2022), Cambridgeshire Insight or gov.uk direct
2. **Statutory homelessness** — MHCLG H-CLIC (2018Q2+) and P1E legacy tables (pre-2018), at LA level
3. **Claimant count** — NOMIS NM_162_1 (monthly, all LAs)
4. **ASHE median earnings** — NOMIS NM_99_1 (annual, by LA)
5. **BRMA-to-LA crosswalk** — Constructed via DWP/VOA published mapping or postcodes.io

## Fetch Strategy

All data sources are publicly available without API keys. NOMIS works at guest-level (25K rows/call). MHCLG tables are direct downloads from gov.uk. LHA rates are published CSV/Excel on gov.uk or Cambridgeshire Insight.
