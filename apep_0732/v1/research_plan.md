# Research Plan: Does the Clock Kill? Time Zone Boundaries and Mortality Amplification from Extreme Heat

## Research Question

Do communities on the late-sunset (western) side of US time zone boundaries — which suffer chronic circadian misalignment and sleep deprivation — experience amplified mortality during extreme heat events?

## Identification Strategy

**Spatial RDD at time zone boundaries.** The three continental US time zone boundaries (Eastern/Central, Central/Mountain, Mountain/Pacific) create sharp 1-hour clock shifts between adjacent counties. Counties on the late-sunset (western) side have later social schedules relative to solar time, causing chronic sleep deprivation (Giuntella & Mazzonna, 2019).

**Key coefficient:** The interaction between time zone boundary position (late-sunset side) and extreme heat exposure. This captures whether chronic circadian misalignment amplifies the mortality cost of heat waves.

**Running variable:** Distance to time zone boundary (negative = early-sunset/eastern side, positive = late-sunset/western side).

**Treatment:** Being on the late-sunset (western) side of a time zone boundary, interacted with extreme heat days in a given month.

## Expected Effects and Mechanisms

**Primary hypothesis:** Late-sunset counties experience higher heat-related mortality per extreme heat day due to chronic sleep deprivation reducing physiological heat tolerance.

**Mechanisms:**
1. Sleep deprivation impairs thermoregulation
2. Circadian misalignment reduces cardiovascular reserve
3. Compounding: heat disrupts sleep further, creating a vicious cycle

**Expected magnitude:** Moderate positive SDE. Giuntella & Mazzonna (2019) find ~8% higher obesity and 11% more heart attacks on the late-sunset side. Heat amplification should be economically meaningful but not enormous.

## Primary Specification

```
mortality_rate_{ct} = α + β₁ × late_sunset_c + β₂ × heat_days_{ct} +
                      β₃ × (late_sunset_c × heat_days_{ct}) +
                      X_{ct}γ + θ_t + ε_{ct}
```

Where:
- `c` = county, `t` = month-year
- `late_sunset` = indicator for western side of TZ boundary
- `heat_days` = number of days with max temp ≥ 95°F in county-month
- `β₃` = coefficient of interest (interaction)
- `X_{ct}` = county controls (population, income, demographics)
- `θ_t` = month-year fixed effects

**Robustness:**
- Bandwidth sensitivity (50/100/150/200 miles from boundary)
- Placebo: winter months (same misalignment, no heat stress)
- Alternative heat thresholds (90°F, 100°F)
- Donut RDD (exclude counties immediately on boundary)
- Cause-specific mortality (cardiovascular, respiratory)

## Data Sources

1. **CDC WONDER** — County-level monthly mortality counts by cause (1999–2020)
2. **NOAA GHCN-Daily** — 13,000+ weather stations, daily TMAX/TMIN
3. **Census/ACS** — County demographics, population, income
4. **Time zone boundary GIS** — 49 CFR Part 71, available from Census TIGER

## Fetch Strategy

1. CDC WONDER: API query for county-month mortality (requires structured request)
2. NOAA GHCN-Daily: API via `rnoaa` R package or direct HTTPS
3. County demographics: `tidycensus` R package
4. Time zone boundaries: Census TIGER shapefiles + manual county classification
