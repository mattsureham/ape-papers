# Research Plan: Regulatory Whack-a-Mole

## Research Question

When EPA conducts a Clean Air Act inspection at a regulated facility, do air emissions decline while water discharges and land disposal of the same chemicals increase? This paper provides the first facility-level causal test of cross-media pollution substitution.

## Identification Strategy

**Triple-difference design:**

Y_{i,c,m,t} = α_{i,c} + γ_t + δ_m + β₁(Post_{i,t} × Air_m) + β₂(Post_{i,t} × NonAir_m) + ε_{i,c,m,t}

Where:
- i = facility, c = chemical, m = medium (air vs water vs land), t = year
- Post_{i,t} = indicator for years after facility i's CAA inspection
- α_{i,c} = facility × chemical fixed effects
- The key test: β₁ < 0 (air releases fall) AND β₂ > 0 (water/land releases rise)

The triple-difference absorbs:
1. Facility-chemical level differences (FE)
2. Year-specific aggregate shocks (year FE)
3. Medium-specific levels (medium FE)
4. The interaction Post × Air vs Post × NonAir identifies substitution

**Key assumption:** Timing of CAA inspection within the mandatory 2-year cycle is quasi-random — driven by inspector scheduling, geographic routing, and capacity constraints, not by expected pollution patterns.

## Expected Effects and Mechanisms

- **Primary hypothesis:** Air releases decline after inspection (deterrence/compliance), BUT water and land releases increase (substitution)
- **Net effect:** Total pollution may not decrease — just reshuffled across media
- **Mechanism:** Facilities face medium-specific regulatory scrutiny; shifting pollution to unmonitored media is cheaper than abatement
- **Heterogeneity:** Substitution should be larger for chemicals that are easier to redirect across media; larger for facilities in industries with multi-media production processes

## Primary Specification

1. **Event study:** Estimate year-by-year effects relative to inspection year (t-3 to t+3)
2. **Main DiD:** Pre/post inspection × air vs non-air medium interaction
3. **Decomposition:** Split non-air into water (5.3), landfill (5.5.1), POTW transfers (6.1), off-site transfers (6.2)
4. **Placebo:** Effect of CWA (water) inspections on air releases (should be null or reversed)

## Data Sources

1. **ICIS-Air** (EPA): Full Compliance Evaluations (FCE) on-site inspections. 636K records across 151K facilities. Download from EPA ECHO bulk data.
2. **TRI** (EPA): Toxics Release Inventory. Annual facility × chemical releases by medium (air/water/land). 1987-present. Download from EPA TRI.
3. **FRS** (EPA): Facility Registry Service. Links ICIS-Air facility IDs to TRI facility IDs via FRS_ID. 99.8% match rate confirmed.

## Fetch Strategy

1. Download ICIS-Air bulk CSV (66MB zip) from EPA ECHO
2. Download TRI basic data files for 2000-2022 from EPA TRI
3. Link via FRS_ID
4. Construct facility × chemical × medium × year panel
5. Identify treatment events: first FCE inspection per facility within each 2-year cycle

## Robustness Checks

- Control for simultaneous CWA inspections
- Restrict to chemicals flagged as CAA-regulated (column 42)
- Vary event window (±2, ±3, ±5 years)
- Cluster SEs at facility level and state level
- Randomization inference on inspection timing
