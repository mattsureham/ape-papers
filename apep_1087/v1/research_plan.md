# Research Plan: Codes of Safety — Do Healthcare Workplace Violence Prevention Mandates Reduce Worker Injuries?

## Research Question

Do state-mandated workplace violence prevention (WVP) programs for healthcare employers reduce workplace injuries among healthcare workers? Twenty-seven US states have adopted these mandates with staggered timing (2011–2024), creating a natural experiment. The key mechanism: mandates require employers to assess violence risks, train staff, and implement protective protocols — but do these requirements translate into measurably safer workplaces, or are they primarily compliance exercises?

## Identification Strategy

**Callaway–Sant'Anna (2021) staggered DiD** exploiting variation in the timing of state WVP law adoption across 27+ states.

- **Treatment:** Binary indicator for whether a state has enacted a healthcare WVP mandate, coded by effective date.
- **Treated cohorts:** States grouped by year of mandate adoption (CT 2011, CA 2017, WA ~2019, IL/MN/MD ~2020, NJ ~2021, MA/TX 2024, etc.)
- **Control group:** Not-yet-treated states (states that adopt later or never adopt)
- **Unit of observation:** State × year
- **Primary outcome:** Days-away-from-work (DAFW) injury rate per healthcare establishment

**Placebo tests:**
1. Non-healthcare establishments (NAICS ≠ 62) in treated states — WVP mandates are healthcare-specific
2. Within-healthcare: if case detail available, compare violence-coded vs. non-violence injuries

## Expected Effects and Mechanisms

**Primary hypothesis:** WVP mandates reduce workplace injuries in healthcare, particularly violence-related injuries. Mechanisms:
- Risk assessment → identification of high-risk units (psych, ED)
- Staff training → de-escalation skills reduce violent incidents
- Engineering controls → panic buttons, security staffing, physical barriers

**Alternative hypothesis (null/perverse):** Mandates may have no effect if:
- Requirements are vague and enforcement weak
- Healthcare violence is driven by patient acuity, not prevention gaps
- Compliance is formal (policy on paper) but not substantive

A credible null here is informative: it would suggest that mandate-style regulation is insufficient for a fundamentally clinical problem.

## Primary Specification

$$Y_{st} = \alpha + \text{ATT}(g,t) + \gamma_s + \delta_t + \varepsilon_{st}$$

Where $Y_{st}$ is the injury rate (DAFW cases per establishment) in state $s$, year $t$. Using `did::att_gt()` with:
- `gname`: year of WVP mandate adoption
- `tname`: year
- `yname`: DAFW rate per establishment
- `idname`: state FIPS
- `control_group`: "notyettreated"

Aggregate to overall ATT and event-study plot. Cluster SEs at state level.

## Exposure Alignment

The treatment (state WVP mandate) operates at the state level and applies to all healthcare employers (NAICS 62) within the state. The outcome (DAFW injury rate) is measured at the establishment level and aggregated to the state-year. Treatment and outcome are aligned at the state-year level: when a state adopts a WVP mandate, all healthcare establishments in that state are exposed. Non-healthcare establishments in the same state serve as a placebo (they are exposed to the same state-level economic conditions but not to the healthcare-specific mandate). The key concern is that the OSHA 300A data captures all DAFW injuries, not just violence-related ones — so the outcome is broader than the mechanism targeted by the policy. This dilution is acknowledged as a limitation.

## Data Source and Fetch Strategy

**Primary data:** OSHA Injury Tracking Application (ITA) 300A Summary data (2016–2023)
- URL: `https://www.osha.gov/Establishment-Specific-Injury-and-Illness-Data`
- Annual ZIP files containing establishment-level injury records
- Fields: state, NAICS code, total injuries, DAFW cases, establishment size
- Filter to NAICS 62 (healthcare and social assistance)
- Aggregate to state × year: total DAFW cases, total establishments, DAFW rate

**Treatment data:** State WVP law adoption dates
- Compiled from Health Affairs Scholar (2024), OSHA state plan documentation, and state legislature records
- Key dates verified: CT (2011), CA (2017), WA (2019), IL (2020), MN (2020), MD (2020), NJ (2021), MA (2024), TX (2024), NY (2025/2027), OR (2026)

**Fetch strategy:**
1. Download OSHA ITA ZIP files for years 2016–2023
2. Extract, filter to NAICS 62, aggregate to state × year
3. Construct treatment timing variable from legislative research
4. Merge and construct analysis panel
