# Research Plan: Empty Chairs at New Tables

## Research Question

Did the January 2023 X-waiver elimination cause new buprenorphine prescribers to enter treatment-desert counties, or did new entrants cluster in already-served markets? The answer determines whether deregulation expanded geographic access or merely expanded credentials.

## Policy Background

The Consolidated Appropriations Act of 2023 (signed Dec 29, 2022; DEA letter Jan 12, 2023) eliminated the DATA 2000 X-waiver requirement. Any DEA Schedule III registrant can now prescribe buprenorphine without prior 8-hour training or patient caps. The April 2021 partial exemption (≤30 patients, no training) serves as a pre-treatment event for validation.

## Identification Strategy

**Provider-level event study with county-type heterogeneity.**

1. **Primary analysis:** Month-level counts of new buprenorphine-billing NPIs entering desert vs. non-desert counties, with January 2023 as the treatment break. This is essentially a difference-in-differences comparing the rate of new NPI entry across county types before vs. after the X-waiver elimination.

2. **Desert definition:** Counties with zero buprenorphine-billing NPIs in the 12 months prior to January 2023 (from T-MSIS). Cross-validated with HRSA HPSA mental health shortage designations.

3. **Pre-trend validation:** April 2021 partial X-waiver relaxation as a sub-event; expect smaller, proportional effect.

4. **Unit of analysis:** County × month panel (2020–2024), with new-entrant NPI counts as the outcome.

## Expected Effects

**Benchmark prediction:** X-waiver was a geographic barrier → new entrants should disproportionately enter deserts.

**Alternative (our hypothesis):** X-waiver was a credentialing-taste filter → new entrants cluster in already-served urban markets. If true, the *credential gap* was not the binding constraint — rather, it was willingness to treat OUD patients in underserved areas.

## Primary Specification

$$\text{NewEntrants}_{ct} = \alpha_c + \gamma_t + \beta_1(\text{Post}_t \times \text{Desert}_c) + \beta_2 \text{Post}_t + \varepsilon_{ct}$$

where $c$ indexes counties, $t$ indexes months. $\beta_1$ captures whether deserts saw differentially more or fewer new entrants post-elimination relative to non-desert counties. Standard errors clustered at county level.

## Data Sources

1. **T-MSIS** (`az://raw/medicaid/tmsis.parquet`, 227M rows): Buprenorphine J-codes (J0571–J0575) identify billing NPIs and timing of entry.
2. **NPPES** (download.cms.gov, free): NPI → practice ZIP → county FIPS, specialty taxonomy.
3. **HRSA HPSA** (data.hrsa.gov, free): Mental health professional shortage area designations by county.
4. **Census/ACS:** County population, poverty rate, urbanicity for controls.

## Exposure Alignment

The X-waiver elimination is a single national shock affecting all DEA-registered providers simultaneously. Treatment exposure is uniform across all counties — the reform applied nationally on January 12, 2023. The desert/non-desert classification captures differential baseline conditions, not differential treatment intensity. All counties were equally "treated" by the deregulation; the question is where new entrants chose to locate. The DiD interaction identifies whether entry rates evolved differently in desert versus non-desert counties after the reform, conditional on county and time fixed effects.

## Robustness

- Alternative desert thresholds (0 vs. ≤1 vs. ≤2 prior NPIs)
- Restrict post-period to Jan–Mar 2023 (pre-Medicaid unwinding)
- Placebo: non-buprenorphine controlled substance new entrants
- HRSA HPSA designation as alternative desert measure
- Permutation inference (randomize desert/non-desert labels)
