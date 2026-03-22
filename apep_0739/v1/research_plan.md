# Research Plan: The Emergency Room Tax

## Research Question
Do GP practice closures in England increase emergency department (A&E) utilization? When primary care gatekeepers disappear, do patients substitute toward costly emergency care?

## Identification Strategy
**Staggered Difference-in-Differences** using the Callaway and Sant'Anna (2021) estimator.

- **Treatment unit**: Clinical Commissioning Group (CCG) area × quarter
- **Treatment event**: First GP practice closure in a CCG-quarter (or intensity = number of closures)
- **Outcome**: Total Type 1 A&E attendances at trusts serving each CCG area
- **Comparison group**: Not-yet-treated CCGs (those with no closures until later periods)
- **Time period**: 2015Q2–2024Q4 (monthly data aggregated to quarters for cleaner identification)

The staggered timing of 1,400+ closures across ~200 CCG areas provides clean variation. Selection concerns are mitigated by: (1) pre-trends testing, (2) HonestDiD sensitivity analysis, and (3) theory-matched placebos (elective referrals should not increase if the mechanism is access loss rather than general area decline).

## Expected Effects and Mechanisms
1. **Direct effect**: A&E attendances increase in areas experiencing GP closures
2. **Mechanism**: Surviving practices absorb displaced patients → longer wait times → patients bypass GP → attend A&E for conditions treatable in primary care
3. **Fiscal externality**: Average A&E attendance costs ~£171 vs GP consultation ~£42 (PSSRU 2023). Even modest substitution implies large fiscal costs.

**Prediction**: Positive effect on A&E attendances, concentrated in deprived areas (fewer alternative GP options) and for minor conditions (those most substitutable between primary and emergency care).

## Primary Specification
```
A&E_ct = α_c + γ_t + β × Closures_ct + ε_ct
```
Where c indexes CCG areas, t indexes quarters, α_c is CCG fixed effects, γ_t is time fixed effects. CS estimator handles staggered treatment timing with heterogeneous effects.

## Data Sources
1. **GP Practice Closures**: NHS ODS API — inactive GP practices with RO177 role (Primary Care), including postcodes and deactivation dates
2. **A&E Monthly Statistics**: NHS England — monthly A&E attendances by provider trust (Type 1, 2, 3), publicly downloadable
3. **Geographic Mapping**: Postcodes.io API — map practice postcodes to CCG/ICB areas; map trusts to serving CCGs
4. **Deprivation**: IMD 2019 scores by LSOA (from data.gov.uk), aggregated to CCG level

## Exposure Alignment
Treatment is defined as GP practice deactivation within 15 km of an A&E trust. The treated population comprises patients formerly registered at the deactivated practice who lose their primary care gatekeeper. However, the ODS "inactive" status conflates genuine closures (physical site closure, patient list dissolution) with administrative events (mergers, code retirements during ICB transition). The treatment variable thus measures *administrative deactivation exposure*, not *primary care access loss*. This distinction is critical for interpretation: a null effect on A&E attendances could reflect either (a) genuine access losses that are absorbed without A&E substitution, or (b) administrative events that do not reduce access at all. The 2023 spike in deactivations (75% of total) is strongly consistent with interpretation (b).

## Robustness Checks
- Distance bandwidth sensitivity (5km, 10km, 20km trust-CCG mapping)
- Placebo: elective (planned) admissions should not increase
- Pre-trends visualization and HonestDiD bounds
- Wild cluster bootstrap at CCG level
- Excluding London (different primary care market structure)
- Alternative estimator: Sun and Abraham (2021) via fixest::sunab()
