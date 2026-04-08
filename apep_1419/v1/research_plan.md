# Research Plan: The Contribution Cliff: UK Auto-Enrollment Step-Ups and the Wage-Offset Puzzle

## Research Question

Did the April 2019 doubling of mandatory employer pension contributions (from 2% to 3% of qualifying earnings) reduce employee wage growth, confirming Summers' (1989) mandate-tax hypothesis? Or did the step-up raise total compensation without wage offsets, suggesting behavioral defaults dominate incidence?

## Identification Strategy

**Design:** Difference-in-differences exploiting employer size variation.

The April 2019 step-up applied uniformly, but bite varied by employer size:
- **Small employers (1-49 employees):** Staged later (2014-2017), less time to gradually adjust. Higher share at the exact minimum contribution. Treatment group.
- **Large employers (250+ employees):** Staged first (2012), had years to absorb. Many already contributed above the minimum. Control group.
- **Medium employers (50-249):** Intermediate treatment intensity.

**Event study specification:**
Y_{st} = α_s + γ_t + Σ_k β_k × (SmallEmployer_s × 1{t=k}) + X_{st}δ + ε_{st}

Where s indexes employer size band, t indexes year, and k indexes event-time relative to April 2019.

**Key identifying assumption:** Absent the step-up, wage growth trends would have been parallel across employer size bands. Testable with pre-trend coefficients 2015-2018.

## Expected Effects

1. **Opt-out rates:** Should spike at the step-up (from ~9% to potentially 12-15%) as employees face larger paycheck deductions. Effect should be larger for lower-paid workers.
2. **Wage growth:** If mandate-tax hypothesis holds, wage growth should slow for workers at firms near the minimum. If behavioral defaults dominate, wages should be unaffected (employers absorb the cost or pass through to prices).
3. **Total pension contribution rates:** Should increase mechanically, but by less than 1pp if some employers were already above minimum.

## Primary Specification

DiD with ASHE data: median weekly earnings by employer size band, pre/post April 2019. Clustered at employer-size-band level.

## Data Sources

1. **ASHE via NOMIS API:** Annual earnings, pension participation, contribution rates by employer size band (2015-2023). ~180,000 employee sample annually.
2. **DWP Auto-Enrolment Statistics:** Quarterly opt-out rates, average contributions by employer size. Published on gov.uk.
3. **ONS CPI:** For deflating earnings to real terms.

## Fetch Strategy

1. Query NOMIS API for ASHE Table 4.6a pension data by employer size, 2014-2023
2. Download DWP auto-enrollment statistics (Excel files from gov.uk)
3. Construct employer-size × year panel
