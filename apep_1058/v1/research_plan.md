# Research Plan: The Networked Bank Run

## Research Question
Did counties with stronger social ties to Silicon Valley experience larger deposit outflows from local banks during the March 2023 banking panic, beyond what geographic proximity, media exposure, and bank fundamentals can explain?

## Identification Strategy
**SCI shift-share design (cross-sectional IV).**

For each county *c*, construct:

NetworkExposure_c = Σ_j SCI(c,j) × SVBshare_j

where SCI(c,j) is the Facebook Social Connectedness Index between county *c* and county *j*, and SVBshare_j is SVB's deposit market share in county *j* (concentrated in ~17 Bay Area branches).

**Main specification:**
ΔDeposits_c = β × NetworkExposure_c + X_c'γ + State_FE + ε_c

where ΔDeposits_c is the log change in deposits (June 2022 → June 2023).

**Controls (X_c):**
- Log geographic distance to Santa Clara County
- Same-state indicator (California)
- Media market overlap (same DMA as Bay Area)
- Pre-crisis deposit trends (2019-2022)
- Tech employment share (QCEW or QWI)
- Local bank fundamentals: uninsured deposit ratio, CRE concentration, held-to-maturity losses
- Population and income

## Expected Effects and Mechanisms
- **Primary:** Negative β — higher SCI exposure → larger deposit outflows
- **Mechanism 1 (Social panic):** Real social ties transmit fear/urgency beyond public information channels
- **Mechanism 2 (Coordinated withdrawal):** Network connections facilitate coordinated runs on local banks
- **Heterogeneity:** Effect should be stronger for banks with higher uninsured deposit ratios (more susceptible to runs) and weaker for well-capitalized banks

## Primary Specification
OLS cross-sectional regression with state fixed effects. Continuous treatment (NetworkExposure). Cluster SEs at state level (~50 clusters). Robustness: commuting zone clustering, Conley spatial SEs.

## Data Sources and Fetch Strategy

### 1. Social Connectedness Index (SCI)
- **Source:** Azure blob `raw/sci/v2026/us_counties.zip`
- **Format:** County-pair level SCI scores
- **Use:** Construct NetworkExposure weights

### 2. FDIC Summary of Deposits (SOD)
- **Source:** FDIC BankFind API (banks.data.fdic.gov)
- **Years:** 2019-2023 (annual, June 30)
- **Level:** Branch-level with FIPS codes (~77,000 branches)
- **Variables:** Total deposits, institution identifiers
- **Use:** County-level deposit aggregation, SVB branch identification

### 3. FFIEC Call Reports
- **Source:** FFIEC CDR bulk downloads
- **Quarters:** Q4 2022, Q1 2023, Q2 2023
- **Level:** Bank-level
- **Variables:** Total deposits, uninsured deposits (RC-E), securities (RC-B), CRE loans
- **Use:** Bank fundamentals controls

### 4. County Controls
- **BLS QCEW:** Tech employment share by county
- **Census ACS/BEA:** Population, median income
- **Nielsen DMA:** Media market overlap

## Key Risks
1. **Confounding from tech sector:** Counties connected to SV may have tech workers who withdraw deposits independently. Control for tech employment share; placebo with non-tech-epicenter bank failures.
2. **Reflection problem:** SCI is symmetric — does the effect run both ways? SVB's geographic concentration provides directional asymmetry.
3. **Measurement:** SOD is annual (June 30) — may miss within-quarter dynamics. Supplement with quarterly Call Reports.

## Placebo Tests
1. Pre-trend test: SCI exposure should not predict deposit changes 2019-2020, 2020-2021, 2021-2022
2. Non-failing bank placebo: Construct NetworkExposure using JPMorgan or BofA branch footprints — should show no effect
3. Mechanism-matched placebo: Effect should be null for insured deposits (under $250K) if mechanism is panic about uninsured losses
