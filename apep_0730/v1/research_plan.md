# Research Plan: Living on the Wrong Side of the Clock

## Research Question
Do US time zone boundaries — which create sharp 1-hour discontinuities in the gap between solar time and clock time — cause elevated teen morning-commute traffic fatalities on the late-sunset (western) side?

## Identification Strategy
**Spatial RDD** at the three continental US time zone boundaries (Eastern/Central ~84-86°W, Central/Mountain ~104°W, Mountain/Pacific ~115°W).

- **Running variable:** Longitude of each fatal crash relative to nearest TZ boundary (degrees).
- **Treatment:** Being on the late-sunset (western) side of a TZ boundary, where clock time diverges most from solar time, producing chronic sleep deprivation ("social jetlag").
- **Key specification:** Crash-level RDD on fatality counts within bandwidths of the boundary. Primary bandwidth: 100km (~0.9° longitude). CCT optimal bandwidth for robustness.

## Expected Effects and Mechanisms
Communities on the late-sunset side experience:
1. Later effective sunrise → shorter sleep on work/school mornings
2. Chronic circadian misalignment → impaired cognitive function
3. Teen drivers are especially vulnerable (biological sleep need ~9h, early school start times)

**Prediction:** Teen (15-19) morning fatality rates are discontinuously higher on the late-sunset side. Adult morning fatalities may show a smaller or null discontinuity (adults have more driving experience, less sleep-sensitive). Evening fatalities should show NO discontinuity (falsification).

## Primary Specification
```
Y_i = α + β·Late_i + f(longitude_i) + γ·X_i + ε_i
```
Where Y_i = indicator for fatal crash at location i, Late_i = 1 if west of TZ boundary, f() is local polynomial in longitude, X_i = year FE, boundary FE, weather controls.

Main analysis pools crash-level data. Robustness: county-year panel with fatality rates.

## Data Sources
1. **FARS (Fatality Analysis Reporting System):** NHTSA, 2010-2023. All US traffic fatalities. Geocoded (lat/lon). Person-level age, time-of-day. ~600,000 fatal crashes over period. Free API at crashviewer.nhtsa.dot.gov.
2. **Census ACS:** County population by age for rate denominators.
3. **Time zone boundaries:** US DOT/NOAA shapefiles. 49 CFR Part 71.
4. **NOAA weather:** Daily temperature/precipitation for weather controls.

## Key Risks
- **Sample size near boundaries:** ~1,260 teen morning fatalities over 14 years within reasonable bandwidth. Mitigated by also testing all-age morning fatalities (~24,700).
- **Sorting:** People don't choose residence based on TZ assignment → minimal concern.
- **COVID:** 2020-2021 driving patterns disrupted. Test with/without COVID years.
- **School start time confound:** If school start times differ systematically across TZ boundaries. Addressable via NCES data.
