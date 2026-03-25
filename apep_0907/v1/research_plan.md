# Research Plan: The Digital Door to Food Stamps

## Research Question
Does reducing application friction through online SNAP applications increase program takeup? Prior work (Jones et al. 2021, NBER WP 29037) found null effects using CPS survey data and static TWFE. We revisit this using administrative caseload data and the Callaway and Sant'Anna (2021) estimator, which avoids forbidden comparisons between early- and late-adopting states.

## Identification Strategy
**Staggered Difference-in-Differences (Callaway & Sant'Anna 2021)**
- Treatment: State adoption of online SNAP application systems
- 46 treated states (2002–2019), 5 never-treated (AK, DC, HI, ID, WY)
- Unit: state-month
- Outcome: SNAP participation rate (households per population), caseload levels
- Key advantage: CS estimator uses only clean 2x2 comparisons against not-yet-treated or never-treated, avoiding negative weighting from staggered TWFE

## Expected Effects and Mechanisms
- **Primary**: Positive effect on SNAP participation (reduced transaction costs)
- **Mechanisms**:
  1. Digital access channel: larger effects in states with higher broadband penetration
  2. Distance channel: larger effects in rural areas (higher physical travel costs to offices)
  3. Composition: working families (high opportunity cost of in-person visits) vs. elderly
- **Null hypothesis**: Online applications merely shift filing mode without increasing total applications (Jones et al.'s finding)

## Primary Specification
```
ATT(g,t) = E[Y_t - Y_{g-1} | G=g] - E[Y_t - Y_{g-1} | C=1]
```
where g is the cohort (adoption month/year), t is the calendar period, G is the treatment group indicator, and C indicates the never-treated comparison group. Aggregate via Callaway-Sant'Anna group-time ATTs into an overall ATT and dynamic event-study coefficients.

## Data Sources
1. **USDA ERS SNAP Policy Database**: Treatment timing (oapp variable — 46 states adopted 2002-2019), plus 49 concurrent policy controls (BBCE, face-to-face interview waivers, fingerprinting requirements, etc.)
2. **USDA FNS SNAP Caseload Data**: State-monthly administrative counts of participating households, persons, and benefit amounts (39 fiscal year files)
3. **Census/ACS population data**: State annual population for constructing participation rates
4. **FCC broadband data or FRED**: For heterogeneity analysis by internet access

## Fetch Strategy
- SNAP Policy Database: Direct download from USDA ERS (CSV)
- FNS Caseload: Direct download from USDA FNS (fiscal year ZIP files)
- Population: Census Bureau API or FRED
- Broadband: FCC Form 477 or NTIA data

## Exposure Alignment
Treatment is state-level adoption of online SNAP applications. The treated population is SNAP-eligible households in adopting states. The key exposure alignment consideration: online applications only affect new applicants and recertifying households, not current enrollees who applied under the old system. The effect on the participation *rate* (the stock of recipients) therefore accumulates gradually as new cohorts of applicants enter through the digital channel and as existing recipients recertify online. This implies effects should build over time rather than appearing as an immediate jump. The event study allows us to assess this dynamic pattern.

## Robustness
1. TWFE comparison (to show forbidden-comparison bias)
2. Sun and Abraham (2021) interaction-weighted estimator
3. Leave-one-out by adoption cohort
4. Placebo: Medicare-eligible elderly population (less affected by application friction)
5. HonestDiD/Rambachan-Roth sensitivity analysis
