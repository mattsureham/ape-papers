# Research Plan: The Enforcement Federalism Production Function

## Research Question

Does federal environmental inspector withdrawal cause facility-level pollution increases, and do state agencies substitute for lost federal enforcement?

## Identification Strategy

**Shift-share (Bartik) design.** Treatment intensity = pre-period (2012–2016) share of inspections in state $s$ conducted by EPA (from ICIS) × national EPA OECA staffing trajectory (from OPM FedScope). States historically reliant on federal inspectors experienced larger effective enforcement declines when EPA lost ~700 staff (22%) between 2016–2020.

**Estimating equation:**
$$Y_{f,t} = \alpha_f + \lambda_t + \beta \cdot \text{FedShare}_s \times \text{Post}_t + X_{f,t}\gamma + \varepsilon_{f,t}$$

where $Y_{f,t}$ is log total on-site releases at facility $f$ in year $t$, $\text{FedShare}_s$ is the pre-period federal inspection share for state $s$, and $\text{Post}_t$ is an indicator for the decline period (2017+). Facility and year fixed effects absorb time-invariant facility characteristics and national trends.

**Event study extension:** Replace $\text{Post}_t$ with year dummies to trace out dynamics and check pre-trends.

## Expected Effects and Mechanisms

- **Primary:** Federal withdrawal → fewer inspections → reduced deterrence → higher toxic releases
- **Mechanism test:** Direct test of state substitution — did state inspection counts increase in high-federal-share states?
- **Heterogeneity:** By industry (chemicals vs. manufacturing), facility size, state regulatory capacity (budget per facility)
- **If null:** States fully substitute for federal withdrawal — cooperative federalism works at the margin

## Primary Specification

- **Unit:** Facility-year (TRI reporting facilities)
- **Outcome:** Log total on-site releases (pounds), log air emissions
- **Treatment:** Continuous — pre-period federal inspection share × post indicator
- **Fixed effects:** Facility + year
- **Clustering:** State level (50 clusters)
- **Period:** 2010–2023 (7 pre-treatment years, 7 post-treatment years)

## Robustness

1. Rotemberg weights decomposition (which states/years drive the result)
2. Pre-trend test: event study coefficients for 2010–2016
3. Placebo: Non-regulated chemicals at same facilities
4. Placebo: States with near-zero federal share (always state-enforced)
5. Leave-one-state-out sensitivity
6. Alternative outcomes: compliance violations, ambient air quality

## Data Sources

1. **TRI (Toxics Release Inventory):** EPA Envirofacts API. Facility-level annual toxic releases, ~21,000 facilities, 1987–present.
2. **ICIS (Integrated Compliance Information System):** EPA ECHO API. Inspection records with `state_epa_flag` distinguishing EPA (E) vs. state (S) vs. local (L) inspections.
3. **OPM FedScope:** EPA OECA staffing levels by year. Public employment data.
4. **EPA ECHO facility data:** Facility characteristics (industry, location, size).

## Fetch Strategy

1. TRI: Envirofacts REST API, query by year (2010–2023), download facility releases
2. ICIS: ECHO API, query ICIS_ACTIVITY for inspections by state_epa_flag
3. FedScope: Download EPA employment data from OPM website
4. Merge at facility level using EPA Registry ID
