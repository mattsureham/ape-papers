# Research Plan: Banning the Spread — PBM Spread Pricing Prohibitions and Community Pharmacy Survival

## Research Question

Do state-level bans on Pharmacy Benefit Manager (PBM) spread pricing in Medicaid preserve community pharmacies? PBMs historically charged Medicaid managed care organizations (MCOs) more for drugs than they reimbursed dispensing pharmacies, pocketing the "spread." Starting in 2017, states began prohibiting this practice in staggered fashion. We estimate the causal effect of these bans on pharmacy market structure — establishment counts, employment, and entry/exit dynamics — using a Callaway-Sant'Anna staggered difference-in-differences design.

## Identification Strategy

**Design:** Staggered DiD exploiting the timing of state-level spread pricing prohibitions across 16+ states (2017-2024), with ~15 never-treated states as controls.

**Treatment definition:** A state is treated in the year its spread pricing ban becomes effective. Treatment dates:
- 2018: West Virginia (pharmacy carve-out from MCOs)
- 2019: Arkansas, New Hampshire, Ohio
- 2020: Kentucky, Georgia, Louisiana, Virginia
- 2021: Maryland
- 2022: Pennsylvania
- 2023: New York, Florida
- 2024: Idaho, Vermont

**Estimator:** Callaway-Sant'Anna (2021) with not-yet-treated and never-treated as control groups. Robust to treatment effect heterogeneity across cohorts.

**Key assumption:** Conditional on state and year fixed effects, pharmacy market trends would have evolved similarly in reform and non-reform states absent the ban. We test this via:
1. Pre-trend analysis (event study coefficients 2012-2016)
2. Placebo test: non-pharmacy retail establishments (NAICS 44-45 ex 446110)
3. Leave-one-cohort-out sensitivity
4. Randomization inference (500 permutations)

## Expected Effects and Mechanisms

**Main hypothesis:** Banning spread pricing increases pharmacy reimbursement → improves margins → reduces closures → stabilizes or increases pharmacy counts, especially in rural areas and for independent pharmacies.

**Alternative:** PBMs respond to bans by reducing base reimbursement rates, offsetting the reform. Or bans work but increase Medicaid drug costs (spread subsidized MCO premiums).

**Mechanism decomposition:**
1. Reimbursement channel: SDUD per-Rx Medicaid reimbursement
2. Volume channel: SDUD prescription counts
3. Entry vs exit: NPI activation/deactivation dates
4. Independent vs chain: CBP establishment size codes
5. Rural vs urban: county-level analysis

## Primary Specification

Y_{st} = α_s + γ_t + ATT(g,t) + ε_{st}

where Y_{st} is pharmacy establishments per 100,000 population in state s, year t; ATT(g,t) is the group-time average treatment effect from Callaway-Sant'Anna.

Clustering: state level (treatment varies at state level).

## Data Sources

1. **Census County Business Patterns (CBP):** NAICS 446110 (Pharmacies and Drug Stores), annual state/county establishment counts and employment, 2012-2022. Census API confirmed.
2. **Medicaid SDUD:** State-quarter-NDC prescription counts and reimbursement, 2012-2024. 5.3M records/year. Measures the spending channel.
3. **Census Population Estimates:** State/county population for per-capita normalization.

## Fetch Strategy

1. CBP: Census API by state × year × NAICS 446110 (2012-2022)
2. SDUD: Medicaid.gov API, aggregate to state-quarter (2012-2024)
3. Population: Census PEP API
