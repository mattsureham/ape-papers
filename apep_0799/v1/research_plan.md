# Research Plan: Darkness by Decree — The Economic Cost of Internet Shutdowns in India

## Research Question
Do government-imposed internet shutdowns reduce local economic activity? India's 900+ district-level shutdowns (2012–2024) provide the world's largest natural experiment on digital disruption.

## Identification Strategy
**Primary:** Two-way fixed effects (TWFE) event study with district and state×year-month FEs. Treatment = indicator for active shutdown in district-month (and continuous: cumulative shutdown-days).

**Endogeneity concern:** Shutdowns are triggered by conflict/protests that independently affect economic activity. Three strategies:
1. **Exam-triggered shutdowns** (~60+ events in Rajasthan, Bihar, UP) — driven by exam calendars, plausibly exogenous to contemporaneous economic conditions
2. **Duration heterogeneity** — conditional on trigger type, variation in duration is administrative, not economic
3. **Neighboring-district placebo** — adjacent districts face similar conflict exposure but no shutdown

**Estimator:** Callaway-Sant'Anna (2021) for staggered DiD with heterogeneous timing. TWFE as baseline.

## Expected Effects
- Negative effect on nighttime luminosity during shutdowns
- Larger effects for: full blackouts vs mobile-only; longer shutdowns; more digitally-dependent districts
- Partial recovery after shutdown ends; possible scarring from prolonged shutdowns (Kashmir)

## Primary Specification
```
log(NTL_{dt} + 1) = β × Shutdown_{dt} + α_d + γ_{s(d),t} + ε_{dt}
```
Where NTL = nighttime lights, d = district, t = year-month, s(d) = state containing district d.

## Data Sources
1. **Internet shutdowns:** DW Data GitHub (382 labeled events 2012–2020 with trigger types) + internetshutdowns.in (913 events through 2024)
2. **Nighttime lights:** VIIRS Black Marble monthly composites (VNP46A3/VNP46A4) via NASA LAADS DAAC or Google Earth Engine. April 2012–present. District-level zonal means.
3. **District boundaries:** GADM Level 2 (India) or Census 2011 district shapefiles
4. **Controls:** Census 2011 district characteristics (population, urbanization, literacy) from SHRUG or Census API

## Fetch Strategy
- Shutdown data: Direct download from GitHub (CSV/JSON)
- Nightlights: Python extraction via GEE (server-side aggregation) or `blackmarbler` R package with NASA token
- Shapefiles: GADM download via `geodata` or `rnaturalearth` R packages
