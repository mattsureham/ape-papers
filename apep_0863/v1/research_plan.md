# Research Plan: The Forecaster Lottery

## Research Question

Does the quality of tornado warnings issued by National Weather Service (NWS) Weather Forecast Offices (WFOs) causally affect storm casualties? Specifically, do counties assigned to higher-performing WFOs experience fewer tornado fatalities and injuries, conditional on tornado occurrence?

## Identification Strategy: Spatial RDD at WFO Boundaries

The 122 NWS WFOs were assigned County Warning Areas (CWAs) during the 1990s modernization, following historical administrative practice rather than tornado risk or county characteristics. Counties on opposite sides of a WFO boundary share identical tornado climatology but receive warnings from different offices with persistently different performance (average lead times 5-25+ minutes, POD 50-95%, FAR 40-85%).

**Design:** Boundary-pair fixed effects approach. For each pair of adjacent counties served by different WFOs, compare tornado outcomes conditional on tornado occurrence. The key identifying assumption is that CWA boundaries are arbitrary (administrative artifacts) and tornado paths are determined by meteorology, not administrative lines.

**Running variable:** Distance to WFO boundary (for spatial RDD interpretation) or simply boundary-pair FE with WFO performance as treatment.

**Falsification tests:**
1. EF-scale intensity should not differ at boundaries (tornado physics don't change)
2. Property damage (immediate structural damage, not preventable by warnings)
3. Population density and demographics smooth at boundaries

## Expected Effects

- Higher warning lead time → fewer casualties (behavioral response: sheltering)
- Effect should be stronger for injuries than fatalities (marginal warning helps most with moderate-severity events)
- Effect should be larger for mobile home populations (more vulnerable to tornadoes, more responsive to warnings)
- Null on property damage (structural damage is instantaneous)

## Primary Specification

```
casualties_{ept} = α + β * WFO_performance_{w(c),t} + γ * tornado_controls_{ept} + δ_{bp} + ε_{ept}
```

Where:
- e = tornado event, p = boundary-pair, t = year
- WFO_performance = average lead time (minutes) from IEM verification data
- tornado_controls = EF-scale, path length, path width, time of day
- δ_{bp} = boundary-pair fixed effects

Clustering: Two-way by WFO and year.

## Data Sources

1. **NOAA Storm Events Database** (NCEI): All US tornado events 2008-2025. Fields: CZ_FIPS, WFO, injuries, deaths, damage, EF-scale, begin/end lat/lon.
   - Source: https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvs/
   - ~1,500 events/year × 18 years = ~27,000 events

2. **Iowa Environmental Mesonet (IEM) Cow API**: WFO-year verification statistics (lead time, POD, FAR, CSI).
   - Source: https://mesonet.agron.iastate.edu/cow/
   - 122 WFOs × 18 years = ~2,196 WFO-year observations

3. **NWS CWA Shapefiles**: County-to-WFO assignment boundaries.
   - Source: https://www.weather.gov/gis/CWABounds

4. **Census API**: County population, demographics, housing stock (mobile homes).

## Execution Plan

1. Download NOAA Storm Events CSVs for 2008-2025 (tornado events)
2. Download CWA boundary shapefiles and construct county-to-WFO mapping
3. Identify boundary county pairs (adjacent counties in different CWAs)
4. Fetch WFO performance data from IEM Cow API
5. Merge datasets and construct analysis sample
6. Run primary boundary-pair FE regressions
7. Run robustness: bandwidth sensitivity, placebo outcomes, McCrary-style tests
8. Construct SDE table

## Key Risk

Power for fatalities — tornado death rate is ~0.005 per event. May need to focus on injuries (0.15 per event) as primary outcome. Will check power after data construction.
