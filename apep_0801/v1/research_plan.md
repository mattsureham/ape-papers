# Research Plan: apep_0801

## Research Question

Does California's mandatory later school start time (SB 328, effective July 2022) reduce adolescent traffic fatalities, particularly during morning commute hours?

## Policy Background

California SB 328 — the first statewide school start time mandate in US history — requires all public high schools to start no earlier than 8:30am (middle schools: 8:00am). Signed October 2019, effective July 1, 2022. Roughly 75-80% of California high schools changed schedules; ~20% already complied. Rural districts exempt. No other state has a comparable mandate in effect.

## Identification Strategy

**Primary:** Synthetic Difference-in-Differences (SDID, Arkhangelsky et al. 2021). California is the single treated state; all other states serve as donors. The outcome is the teen (age 15-19) morning-hour (6:00-8:59am) traffic fatality rate per 100,000 teens.

**Triple-difference:** (Teen vs. Adult 25-54) × (Morning 6-9am vs. Evening 6-9pm) × (California vs. Synthetic Control). This nets out:
- State-level shocks common to all ages/hours (state × time FE)
- National teen trends (age-group × time FE)
- National morning driving trends (hour-block × time FE)

**Placebos:**
1. Adult (25-54) morning fatalities in California — should show no effect
2. Teen evening (6-9pm) fatalities in California — should show no effect
3. Permutation inference: reassign treatment to each non-CA state

## Expected Effects

- **Primary:** Reduction in teen morning fatality rate (SDID coefficient < 0)
- **Mechanism:** Later starts → more sleep → less drowsy driving → fewer morning crashes
- **Heterogeneity:** Stronger effects for 16-17 year olds (more likely newly licensed + attend high school) vs. 18-19

## Primary Specification

State-month panel, 2015-2023 (108 months × 50 states + DC = 5,508 obs). Outcome: morning teen fatalities per 100k teen population. Treatment: California × Post(July 2022). SDID estimator with permutation-based inference.

## Data Sources

1. **FARS (NHTSA):** Person-level census of all US fatal motor vehicle crashes, 2015-2023. Bulk CSV download. Fields: STATE, HOUR, MONTH, AGE, PER_TYP, INJ_SEV.
2. **Census ACS:** Annual state-level population by single-year age (15-19, 25-54). Via Census API.
3. No school-level data needed for the state-level design.

## Fetch Strategy

1. Download FARS annual CSV files from NHTSA (2015-2023)
2. Extract person-level fatality records (INJ_SEV = 4, PER_TYP = 1 driver)
3. Construct state × month × age-group × hour-block panel
4. Merge Census ACS population denominators
5. Compute fatality rates per 100k population
