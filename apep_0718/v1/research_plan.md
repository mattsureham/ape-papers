# Research Plan: The Replacement Problem — Tornado Destruction and the Permanent Loss of Affordable Housing

## Research Question

When a tornado destroys a manufactured housing community, is the affordable housing rebuilt — or is the land permanently converted to higher-value uses? This paper estimates the causal effect of tornado-driven destruction on long-run mobile home stock, poverty concentration, and housing values using the near-random geographic boundary of EF2+ tornado paths as a spatial regression discontinuity.

## Identification Strategy

**Design:** Spatial regression discontinuity at tornado path boundaries.

**Running variable:** Distance from census tract centroid to nearest EF2+ tornado path edge (in miles). Tracts whose centroids fall inside the path are "treated"; tracts just outside are controls.

**Key assumptions:**
1. Census tract location relative to a tornado path edge is as-good-as-random conditional on the path's general direction — mobile home parks predate tornadoes by decades
2. No manipulation of which side of the path edge a tract falls on — physically impossible
3. No differential selection of new development on path edge — verifiable with pre-tornado balance

**Placebo tests:**
- Pre-tornado outcomes should be balanced at the path boundary
- EF0-1 tornadoes (low damage) should show no discontinuity
- Non-mobile-home outcomes should show weaker effects

## Expected Effects and Mechanisms

**Primary mechanism:** Tornado destruction creates a land-use transition opportunity. Destroyed mobile home parks sit on land that is often undervalued relative to its location. Post-disaster, developers acquire the cleared land and build market-rate housing or commercial properties. The affordable housing stock is permanently reduced.

**Expected effects:**
- Mobile home units: Large negative effect (destruction + non-replacement)
- Poverty rate: Reduction (displacement of low-income residents, not poverty reduction)
- Median housing value: Increase (land-use transition to higher-value uses)
- Population: Possible decrease initially, then recovery or growth

## Primary Specification

Local polynomial RD: Y_i = α + τ * D_i + f(dist_i) + D_i * f(dist_i) + X_i'β + ε_i

Where:
- Y_i = change in tract-level outcome (post - pre tornado)
- D_i = 1 if tract centroid inside tornado path
- dist_i = signed distance from path edge (negative = inside)
- f() = local polynomial (1st or 2nd order)
- X_i = state FE, pre-tornado tract characteristics

Bandwidth selection: MSE-optimal (Calonico, Cattaneo, Titiunik 2014)

## Data Sources

1. **NOAA Storm Prediction Center**: 1950-2023 tornado database (70,022 records)
   - Fields: year, state, magnitude (EF scale), start/end lat/lon, path width, injuries, fatalities
   - URL: https://www.spc.noaa.gov/wcm/data/1950-2023_actual_tornadoes.csv
   - Filter: EF2+ events, 2000-2015 (to allow post-tornado ACS measurement)

2. **Census ACS 5-year**: Tract-level outcomes
   - B25024_010E: Mobile home units
   - B25024_001E: Total housing units
   - B17001_002E/B17001_001E: Poverty rate
   - B25077_001E: Median housing value
   - B01003_001E: Total population
   - Pre-tornado: 2006-2010 ACS; Post-tornado: 2018-2022 ACS

3. **Census TIGER/Line**: Tract boundary shapefiles (via R `tigris` package)
   - For spatial join with tornado paths

4. **FEMA OpenFEMA** (supplementary): Hazard Mitigation Grant Program buyout data

## Analysis Plan

### Step 1: Build tornado path polygons
- Download NOAA SPC data, filter to EF2+ events 2000-2015
- Create polygons from start/end coordinates + width using R `sf`
- Buffer to get "near-path" zones (0.5, 1, 2 miles from edge)

### Step 2: Spatial join with census tracts
- Download tract boundaries for tornado-prone states (TX, OK, KS, MO, AR, MS, AL, TN, IN, IL, OH, GA, NC, FL)
- Classify tracts: inside path, near-path (within bandwidth), far from path
- Compute signed distance from each tract centroid to nearest path edge

### Step 3: Merge ACS outcomes
- Download pre and post-tornado ACS data via Census API
- Compute outcome changes (post minus pre)

### Step 4: RDD estimation
- Local polynomial with MSE-optimal bandwidth
- Robust bias-corrected inference (rdrobust)
- Heterogeneity: by state mobile home tenant protection laws
- Placebo: EF0-1 events, pre-tornado balance tests
