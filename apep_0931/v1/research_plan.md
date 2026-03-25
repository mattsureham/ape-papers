# Research Plan: apep_0931

## Research Question
Did India's Integrated Action Plan (IAP) — a combined security-and-development block grant targeting 60 Naxal-affected tribal districts from 2010 — causally improve economic development, measured by nighttime luminosity?

## Identification Strategy
**District-level Difference-in-Differences.** Compare nightlights trajectories in 60 IAP-designated districts against non-IAP districts, exploiting the sharp November 2010 designation as treatment onset. District and year fixed effects absorb time-invariant district characteristics and common shocks. With 18 years of pre-treatment DMSP nightlights (1992-2009), parallel trends is testable with high power.

**Event-study specification** for dynamic effects and pre-trend validation:
Y_{dt} = alpha_d + gamma_t + sum_k beta_k * 1[t - 2010 = k] * IAP_d + epsilon_{dt}

**Robustness:** (1) Restrict to states with both IAP and non-IAP districts (within-state comparison), (2) Leave-one-state-out, (3) Boundary sample — districts adjacent to IAP districts as controls, (4) Callaway-Sant'Anna with expanded 82/88 districts as staggered treatment.

## Expected Effects and Mechanisms
- **Direct channel:** Rs 25-30 crore/year block grants fund infrastructure (roads, schools, health facilities), electrification, and livelihood programs → direct increase in nightlights via electrification and economic activity.
- **Security channel:** Combined security-development approach reduces Maoist violence → improved business environment → indirect economic growth.
- **Null hypothesis:** Funds captured by local elites or absorbed by security spending with no development impact. This is plausible given the challenging governance environment in tribal districts.

## Exposure Alignment
The IAP's block grant structure means all residents and economic agents within designated districts are exposed to the program's effects (improved roads, electrification, schools, health facilities, and security operations). The treatment is well-aligned with the district-level nightlights outcome, as luminosity reflects aggregate economic activity across the entire district. The unit of treatment assignment (district designation) matches the unit of observation (district-year nightlights panel).

## Primary Specification
log(nightlights + 1) regressed on IAP × Post(2011+), with district and year FEs, clustering at district level.

## Data Sources
1. **SHRUG DMSP nightlights** (`dmsp_pc11dist.csv`): District-level annual nightlights 1992-2013 (calibrated)
2. **SHRUG VIIRS nightlights** (`viirs_annual_pc11dist.csv`): District-level annual nightlights 2012-2021
3. **SHRUG Census 2001/2011 PCA** (`pc01_pca_clean_pc01dist.csv`, `pc11_pca_clean_pc11dist.csv`): Population, literacy, workers
4. **IAP district list**: Compiled from Government of India Planning Commission / MHA documents (60 districts)

## Fetch Strategy
- SHRUG data already on disk at `data/india_shrug/`
- IAP 60-district list: compile from published government documents and code directly in R
- No external API calls needed — all data is local
