# Research Plan: Working Sick, Getting Hurt

## Research Question

Do state paid sick leave (PSL) mandates reduce workplace injuries? When workers lack paid sick leave, they face a choice: lose income or work while sick or fatigued. "Presenteeism" — attending work while impaired — is a recognized occupational health risk, yet no causal evidence links PSL mandates to workplace injury rates.

## Identification Strategy

**Primary:** Callaway-Sant'Anna (2021) staggered difference-in-differences exploiting the staggered adoption of mandatory PSL laws across 12 US states between 2016 and 2024.

**Treatment cohorts:**
- 2016: Oregon
- 2017: Arizona, Vermont, Washington
- 2018: Maryland, New Jersey, Rhode Island
- 2019: Michigan (private sector mandate effective March 2019)
- 2020: New York (statewide, effective September 2020)
- 2021: Colorado (effective January 2021)
- 2023: New Mexico (effective July 2023), Minnesota (effective January 2024), Illinois (effective January 2024)

**Always-treated (excluded from ATT estimation):** Connecticut (2012), California (2015), Massachusetts (2015), DC (2014).

**Never-treated:** 33 states without statewide PSL mandates as of 2024.

**Triple-difference:** Compare high-presenteeism-risk industries (construction NAICS 23, manufacturing NAICS 31-33, transportation NAICS 48-49) vs. low-presenteeism-risk industries (finance NAICS 52, information NAICS 51, professional services NAICS 54) within treated states. The presenteeism mechanism predicts larger injury reductions in physically demanding sectors where working while impaired is more dangerous.

**Placebo outcomes:** Injury types unlikely to be affected by presenteeism — specifically, we examine whether PSL affects the composition of injuries or only the total rate. Equipment/machinery malfunctions (captured in SIC/NAICS detail) should be unaffected by whether a worker is sick.

## Expected Effects and Mechanisms

**Primary mechanism:** PSL allows sick/fatigued workers to stay home → fewer impaired workers on the job → fewer injuries, especially "days away from work" (DAFW) cases that indicate more serious injuries.

**Expected signs:**
- Total Case Rate (TCR): negative (fewer injuries per 100 FTE)
- DAFW Rate: negative (fewer serious injuries)
- DJTR Rate: negative or null (job transfer/restriction cases)
- High-hazard industries: larger negative effects than low-hazard

**Magnitude prior:** Asfaw et al. (2012) found 28% lower injury risk cross-sectionally. Causal effects from mandates will likely be smaller (extensive margin only, not intensive): expect 3-8% reduction in injury rates, or SDE of -0.03 to -0.10.

## Primary Specification

$$Y_{ist} = \alpha_i + \gamma_t + \beta \cdot PSL_{st} + X_{st}'\delta + \epsilon_{ist}$$

Where:
- $Y_{ist}$: injury rate (TCR, DAFW, DJTR per 100 FTE) for establishment $i$ in state $s$ at time $t$
- $PSL_{st}$: indicator = 1 after state $s$ enacts PSL mandate
- $\alpha_i$: establishment fixed effects (or state×industry FE if establishment IDs unstable)
- $\gamma_t$: year fixed effects
- $X_{st}$: state-level controls (unemployment rate, GDP growth)
- Standard errors clustered at the state level

Implemented via Callaway-Sant'Anna `did` package with never-treated as comparison group.

## Data Sources

### Primary: OSHA Injury Tracking Application (ITA) 300A
- **URL:** https://www.osha.gov/Establishment-Specific-Injury-and-Illness-Data
- **Coverage:** 2016-2023 (annual establishment-level submissions)
- **Variables:** Total injuries, DAFW cases, DJTR cases, total hours worked, establishment size, NAICS, state
- **Size:** ~300,000 establishments/year
- **Access:** Public ZIP files, no API key needed

### Supplementary: BLS QCEW
- State-industry employment/wage controls
- Via BLS API (no key needed for quarterly data)

## Fetch Strategy

1. Download OSHA ITA ZIP files for 2016-2023
2. Parse CSV files, standardize variable names across years
3. Construct injury rates per 100 FTE (using hours worked)
4. Merge with PSL treatment dates
5. Collapse to state×NAICS-2×year if establishment panel is unstable
