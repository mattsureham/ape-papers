# Research Plan: First Blood Test for Cars: UK MOT Age-3 Threshold and the Road Safety Dividend

**Paper:** apep_1414/v1  
**Idea:** idea_2452  
**Country:** United Kingdom  
**Method:** Sharp Regression Discontinuity Design (RDD)  
**Date:** 2026-04-08

---

## Research Question

Does mandatory vehicle safety inspection at age 3 years causally improve subsequent vehicle roadworthiness? Specifically, does crossing the 36-month MOT threshold — at which inspection (and forced repair if failed) becomes legally required — reduce defect rates at subsequent annual tests?

## Background

The UK Ministry of Transport (MOT) test requires all vehicles to undergo mandatory safety inspection at exactly 36 months of age, then annually thereafter. In 2023, the UK Department for Transport consulted on moving the first test from age 3 to age 4, with 4,400+ respondents opposing the change on safety grounds (retained January 2024). The consultation's implicit claim is that the age-3 inspection causally improves vehicle safety — a claim no academic study has ever tested.

## Identification Strategy

**Design:** Sharp RDD at the 36-month vehicle age threshold.  

**Running variable:** Vehicle age in months at the time of the first recorded MOT test. Centered at 36 months (running variable = age_months - 36).

**Cutoff:** 0 (i.e., 36 months of vehicle age)

**Treatment:** Vehicles receiving their mandatory first inspection at ≥36 months. Vehicles tested voluntarily before 36 months are the counterfactual.

**Mechanism:** Mandatory inspection at 36 months identifies defects that must be repaired before re-test. If this inspection-and-repair cycle improves vehicle safety, we should observe discontinuously lower failure rates at the second annual test (age ~48 months) for vehicles that crossed the 36-month threshold.

**Key assumption:** Vehicle characteristics (quality, make, owner type) vary continuously through the 36-month threshold. Owners who voluntarily test before 36 months and those who test at the mandatory boundary are similar in all respects except timing of inspection.

**Validity tests:**
1. McCrary density test: test for bunching/sorting at 36-month threshold
2. Continuity of vehicle characteristics at threshold (make, fuel type, region, first-use year)
3. Placebo cutoffs at 30 and 42 months (false cutoffs where no mandate exists)
4. Bandwidth sensitivity (IK optimal vs. ±3, ±6 month windows)
5. Donut RDD (excluding ±1 month of threshold to test bunching robustness)

## Primary Specification

```
y_v = α + τ·D_v + f(age_months_v - 36) + ε_v
```

Where:
- y_v = failure indicator at second annual test (age ~48 months)
- D_v = 1 if first test at age ≥36 months (mandatory), 0 if voluntary before
- f(·) = flexible polynomial in running variable, estimated separately on each side
- Estimator: `rdrobust` with bias-corrected confidence intervals (Calonico-Cattaneo-Titiunik)

## Expected Effects

Prior literature on vehicle inspection programs uses US state-level variation (comparing states with/without programs) and finds reductions in fatalities of 5-15%. The mechanism is inspection-triggered repair. If the UK's mandatory age-3 threshold functions similarly, we expect a negative discontinuity in failure rates at the second annual test. A null result would challenge the mandatory inspection rationale.

## Data

**Primary:** DVSA MOT Test Results (data.gov.uk / S3)
- URL: `https://edh-dvsa-data-gov-uk-files-prod.s3.eu-west-1.amazonaws.com/dft_test_result_YEAR.zip`
- Fetch years: 2021, 2022, 2023
- Size: ~1.19GB compressed per year
- Key fields: `test_id`, `vehicle_id`, `test_date`, `test_result`, `first_use_date`, `make`, `model`, `fuel_type`, `test_mileage`, `postcode_region`
- **Processing strategy:** DuckDB out-of-core, filter to bandwidth cohort (age 30-42 months at first test), sample 10% for speed

**Cohort design:**
- From 2022 file: vehicles registered ~Jan-Jun 2019 with first test at age 30-42 months → this is their mandatory first test
- From 2021 file: verify no prior test record for these vehicle_ids (confirms "first test")
- From 2023 file: extract second test result for same vehicle_ids (age ~42-54 months)

## Tables (V1 — max 5, no figures)

| Table | Content |
|-------|---------|
| 1 | Summary statistics: vehicle characteristics by side of threshold |
| 2 | McCrary density test + first-stage (fraction at each age-month bin) |
| 3 | Main RDD: failure rate at second test by age-at-first-test |
| 4 | Bandwidth robustness and placebo cutoffs |
| 5 | Heterogeneity: by make, fuel type, region |
| F1 | SDE appendix (mandatory) |

## Code Structure

- `00_packages.R` — duckdb, tidyverse, rdrobust, rddensity, jsonlite, arrow
- `01_fetch_data.R` — Download DVSA ZIPs, process with DuckDB, extract bandwidth cohort
- `02_clean_data.R` — Variable construction, cohort linking, first-test identification
- `03_main_analysis.R` — rdrobust main spec, density test, first-stage
- `04_robustness.R` — Bandwidth grid, placebo cutoffs, donut RDD, covariate balance
- `05_tables.R` — All tables including SDE

## Hardware Constraints

RAM: 8GB → Use DuckDB for all large-file processing. Only load bandwidth-filtered data into R.
CPU: 8 cores → Parallelization available but not required for this design.
