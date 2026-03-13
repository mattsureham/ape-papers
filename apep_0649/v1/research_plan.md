# Research Plan: apep_0649/v1

## Title
The Clean Air Penalty: Property Values at UK Clean Air Zone Boundaries

## Research Question
Do urban environmental traffic charges capitalize into local property values? Specifically, does being inside a Clean Air Zone — where polluting vehicles face daily charges — raise or lower nearby property prices relative to properties just outside the boundary?

## Policy Setting
Seven English cities implemented Clean Air Zones (CAZs) between March 2021 and February 2023:
- **Bath** (March 2021, Class C — buses, taxis, HGVs, LGVs)
- **Birmingham** (June 2021, Class D — all vehicles including private cars, £8/day)
- **Portsmouth** (November 2021, Class B — buses, coaches, HGVs only)
- **Bradford** (September 2022, Class C)
- **Bristol** (November 2022, Class D — £9/day for cars)
- **Tyneside** (January 2023, Class C)
- **Sheffield** (February 2023, Class D — £2/day for cars)

Charge classes create natural dose-response: Class B (commercial vehicles only) < Class C (adds taxis/LGVs) < Class D (adds private cars).

## Identification Strategy
**Difference-in-Discontinuities** at CAZ boundaries.

Running variable: signed geodesic distance from each property's postcode centroid to the nearest CAZ boundary (positive = inside, negative = outside).

Main specification:
```
log(Price)_{i,c,t} = f(distance_i) + α × Post_{c,t} + β × Inside_i × Post_{c,t} + City_c + ε_{i,c,t}
```

where f(distance) is a local polynomial, Post is city-specific (after that city's CAZ launch), Inside is 1 if inside the boundary, and β is the treatment effect at the boundary.

The diff-in-disc design controls for any pre-existing level differences at the boundary (e.g., if ring roads create permanent price gaps). We identify β from the *change* in the gap.

Primary bandwidth: 500m. Sensitivity: 250m, 750m, 1000m, 1500m.

**Key threats and mitigation:**
1. Boundaries follow ring roads → control for distance-to-A-road; diff-in-disc absorbs permanent differences
2. Anticipation (prices adjust before launch) → test for effects in announcement-to-launch window
3. COVID confounding (Bath/Birmingham launched during pandemic) → post-COVID cities (2022-23) serve as within-design placebo

## Expected Effects and Mechanisms
**Ambiguous a priori:**
- **Clean air premium** (+): CAZs reduce NO₂/PM₂.₅ inside the zone, creating an amenity value. Literature on congestion charging (Green et al. 2020 JEEM on London) suggests capitalization of air quality improvements.
- **Transport cost penalty** (−): Class D zones impose daily charges on non-compliant cars; residents may face vehicle upgrade costs or daily fees. Reduced commercial vehicle access could hurt local businesses.
- **Net effect:** Likely heterogeneous by charge class. Class B (no car charges) should show pure amenity effect. Class D (car charges) could show net negative if compliance costs dominate.

## Primary Specification
Pooled difference-in-discontinuities across 7 cities using rdrobust with city FE. Triangular kernel, MSE-optimal bandwidth. Clustered SEs at postcode level.

## Heterogeneity Tests
1. By charge class: B (pure commercial) vs C (commercial + taxis) vs D (all vehicles)
2. By property type: flats vs houses (proximity sensitivity)
3. By new-build vs existing (market segment)

## Data Sources
1. **HM Land Registry Price Paid Data** — all residential transactions 2018-2024, with postcode, price, date, property type
2. **CAZ boundary polygons** — OpenStreetMap Overpass API (confirmed for Bristol, Sheffield; will query all 7)
3. **Postcode geocoding** — postcodes.io batch API (free, 100 per request)
4. **NO₂ monitoring** — EEA air quality stations near CAZ boundaries (mechanism verification)

## Robustness Checks
1. Bandwidth sensitivity (250m, 500m, 750m, 1000m, 1500m)
2. Placebo boundaries (shifted 500m outward/inward)
3. Pre-period only RDD (should show null — no boundary effect before CAZ)
4. Donut hole (exclude ±50m to address boundary measurement error)
5. City-by-city estimation (check no single city drives result)
6. Property type controls
7. Seasonal controls (quarter FE)

## Feasibility Assessment
- **N treated units:** 7 cities = 7 boundaries; ~3,500 property transactions/year within 500m across all cities
- **Pre-periods:** 3 years (2018-2020) before first CAZ (Bath March 2021)
- **Data confirmed accessible:** Land Registry (bulk CSV, free), OSM (free), postcodes.io (free API)
