# Research Plan: OSHA's 2022 Heat National Emphasis Program and Workplace Injury Rates

## Research Question

Does OSHA's April 2022 Heat National Emphasis Program (NEP) — the agency's most aggressive heat enforcement action — reduce workplace injuries in targeted industries? And does the program's effectiveness depend on local heat exposure, creating an "enforcement-climate gradient" where regulatory bite scales with environmental risk?

## Identification Strategy

**Triple Difference-in-Differences:**

1. **Industry dimension**: High-heat industries targeted by the NEP (agriculture, construction, manufacturing, landscaping/outdoor services) vs. low-heat industries (finance, information, professional services)
2. **Time dimension**: Pre-NEP (2016–2021) vs. post-NEP (2022–2023)
3. **Geographic dimension**: States with high heat exposure (above-median summer temperatures) vs. low heat exposure

The triple interaction isolates the effect of the NEP where it should bind most: in targeted industries, after the policy, in hot states. The within-industry-type, within-state variation addresses confounds from general injury trends or state-level economic shocks.

**Key identifying assumption**: Absent the NEP, injury trends in high-heat industries in hot states would have evolved parallel to (a) high-heat industries in cool states, (b) low-heat industries in hot states, and (c) low-heat industries in cool states.

## Expected Effects and Mechanisms

- **Primary**: Reduction in total injury rates in targeted industries, concentrated in hot states
- **Mechanism 1 (Deterrence)**: Employers reduce hazards because inspection probability increased
- **Mechanism 2 (Information)**: NEP publicity raises awareness of heat risks
- **Mechanism 3 (Reporting shift)**: Employers may reclassify injuries to avoid scrutiny (negative for heat-specific, but positive for other categories)

## Primary Specification

$$Y_{ist} = \alpha + \beta_1 (\text{HighHeat}_i \times \text{Post}_t) + \beta_2 (\text{HighHeat}_i \times \text{Post}_t \times \text{HotState}_s) + \gamma_{is} + \delta_{st} + \epsilon_{ist}$$

Where:
- $Y_{ist}$: injury rate per 200,000 hours at establishment $i$ in state $s$ in year $t$
- $\text{HighHeat}_i$: indicator for NEP-targeted NAICS industry
- $\text{Post}_t$: indicator for 2022+
- $\text{HotState}_s$: indicator for above-median summer temperature
- $\gamma_{is}$: establishment × state FE (or industry × state FE)
- $\delta_{st}$: state × year FE

Standard errors clustered at the state level (~50 clusters).

## Data Sources

1. **OSHA ITA (Injury Tracking Application)**: Establishment-level Form 300A annual data. ~346,000 establishments/year. Variables: NAICS, state, total hours worked, total injuries, DART cases, DAFW cases. URL: https://www.osha.gov/Establishment-Specific-Injury-and-Illness-Data
2. **NOAA Climate Normals**: State-level average summer (June-August) temperature from 1991-2020 climate normals. Used as pre-determined cross-sectional heat exposure measure.

## Robustness Checks

1. Event study with pre-trend coefficients (2017-2021 leads, 2022-2023 lags)
2. Placebo test: non-targeted industries in hot states (should show no effect)
3. State-plan vs. federal OSHA states (NEP adoption varies)
4. Alternative heat thresholds (terciles instead of median split)
5. Excluding COVID-affected years (2020-2021)

## Idea Source
- idea_0566 from APEP idea database
- Feasibility grade: READY
