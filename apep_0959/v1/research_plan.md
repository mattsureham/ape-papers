# Research Plan: Do Staffing Floors Raise the Ceiling? Nursing Home Staffing Mandates and Care Quality

## Research Question

Do state-level nursing home minimum staffing mandates improve resident care quality, and does the mechanism operate through the extensive margin (more total hours) or the intensive margin (replacing agency/contractor staff with permanent employees)?

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD.** Treatment groups defined by the year each state's quantitative HPRD floor took effect or was meaningfully updated during the PBJ data era (2017Q1–2025Q3). Control group: facilities in states with no quantitative HPRD mandates.

Key features:
- **Binary, absorbing treatment:** Once a state enacts/updates a staffing floor, it remains in effect
- **Staggered timing:** 11 states adopted or updated during 2017–2022
- **Unit of observation:** Facility-quarter (aggregated from daily PBJ data)
- **Clustering:** State level (treatment assigned at state)

## Expected Effects and Mechanisms

1. **First stage:** Mandates should increase total HPRD, especially for facilities below the floor pre-mandate
2. **Quality:** If staffing improves care, expect reduced pressure ulcers, falls, UTIs, antipsychotic use
3. **Bodies vs. continuity mechanism:** Decompose staffing gains into:
   - Employee hours (permanent staff → continuity of care)
   - Contractor hours (agency temps → warm bodies only)
   - If gains are contractor-driven, quality effects should be attenuated
4. **Substitution:** Check whether CNA mandates crowd out RN hours (budget reallocation)

## Primary Specification

```
Y_{i,s,t} = α_i + γ_t + β · ATT(g,t) + X'_{i,t}δ + ε_{i,s,t}
```

Where:
- i = facility, s = state, t = quarter
- ATT(g,t) = group-time average treatment effects from Callaway-Sant'Anna
- X = facility-level controls (bed count, ownership type, rural/urban)
- Standard errors clustered at state level
- Aggregated to overall ATT and dynamic event-study coefficients

## Data Sources

1. **CMS Payroll-Based Journal (PBJ):** Daily facility-level staffing, ~15,000 facilities, 2017Q1–2025Q3. Employee vs. contractor split by staff type (RN, LPN, CNA).
   - API: `https://data.cms.gov/data-api/v1/dataset/7e0d53ba-8f02-4c66-98a5-14a1c997c50d/data`

2. **MDS Quality Measures:** Facility-quarter quality outcomes (pressure ulcers, falls, UTIs, antipsychotic use).
   - API: `https://data.cms.gov/provider-data/api/1/datastore/query/djen-97ju/0`

3. **Health Deficiencies:** Survey deficiency tags and severity codes.
   - API: `https://data.cms.gov/provider-data/api/1/datastore/query/r5ix-sfxw/0`

4. **Penalties:** Fine amounts and payment denials.
   - API: `https://data.cms.gov/provider-data/api/1/datastore/query/g6vv-u9sr/0`

## Treatment Mapping

States with quantitative HPRD floors enacted/updated during PBJ era:
- California: 3.5 total HPRD (2018 update)
- New York: 3.5 HPRD with 2.2 CNA floor (Jan 2022)
- Washington: updated 2019
- Arizona: new mandate 2019
- Connecticut: updated 2017
- Rhode Island: updated 2017
- Oregon: updated 2015 (pre-PBJ, serves as always-treated)
- Pennsylvania: updated 2016 (pre-PBJ, serves as always-treated)
- Massachusetts: updated 2016 (pre-PBJ, serves as always-treated)
- Illinois: updated 2010 (pre-PBJ, always-treated)
- Florida: 3.6 total HPRD (2002, always-treated)
- Arkansas: updated 2014 (pre-PBJ, always-treated)

Focus cohorts for staggered DiD: CT/RI 2017, CA 2018, AZ/WA 2019, NY 2022.

## Exposure Alignment

Treatment is defined at the state-year level: a facility is "treated" when its state has an active quantitative HPRD staffing floor at the time of its health inspection survey. This aligns treatment exposure with the outcome measurement moment — the survey date.

**Who is actually affected:** All Medicare/Medicaid-certified nursing homes in the state are subject to the mandate. The mandate binds for facilities below the HPRD floor pre-mandate. Facilities already above the floor are formally treated but may not change behavior. The treatment effect is therefore a weighted average across facilities that must adjust staffing (intensive margin) and those already compliant (zero adjustment).

**Potential exposure heterogeneity:** Facilities further below the mandate floor experience stronger treatment intensity. The analysis treats this as binary (mandate yes/no) rather than continuous (distance to floor) because historical facility-level HPRD data are not available in panel form from the PBJ API.

## Robustness

1. Event-study plots with pre-trend assessment
2. HonestDiD/Rambachan-Roth sensitivity bounds
3. Exclude COVID period (2020Q2–2021Q1)
4. Bacon decomposition to assess TWFE contamination
5. Leave-one-state-out sensitivity
6. Placebo: states that discussed but did not enact mandates
