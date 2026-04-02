# Research Plan: The Runway Dividend

## Research Question
Does historical air freight infrastructure — instrumented by WWII military airfield conversions — causally increase county-level manufacturing employment and export orientation?

## Identification Strategy
**Instrument:** Binary indicator (and count) of WWII military airfields in a county that were converted to civilian airports under the Surplus Property Act of 1944.

**Assignment story:** The Army Air Corps and Navy sited 700+ training airfields during 1941-1945 based on strategic military criteria: flat terrain, favorable weather, distance from coasts (for training safety), and available cheap land. These criteria are plausibly orthogonal to post-war manufacturing comparative advantage, conditional on geography and region controls.

**First stage:** WWII airfield presence → persistent civilian airport infrastructure → air freight capability (measured by BTS T-100 freight tonnage).

**Exclusion restriction:** Military siting criteria (terrain, weather, remoteness) should not directly affect manufacturing location conditional on controls for terrain ruggedness, climate, highway access, proximity to rail/ports, pre-war population, and census region fixed effects. Main threats: (1) military bases brought permanent population/infrastructure; (2) flat terrain independently attracts manufacturing. Both addressable with controls and falsification tests.

**Estimand:** Local average treatment effect of air freight access on manufacturing employment, identified off the margin of counties whose airport access was determined by WWII military decisions.

## Expected Effects and Mechanisms
- **Primary:** Air freight access increases manufacturing employment, particularly in weight-to-value-sensitive and time-sensitive industries (electronics, instruments, pharmaceuticals, aerospace parts).
- **Heterogeneity:** Stronger effects for high-value, low-weight NAICS codes; weaker for bulk manufacturing (food processing, lumber).
- **Mechanism test:** If air freight is the channel, effects should be concentrated in industries where air shipping is economically viable (high value-to-weight ratio).

## Primary Specification
**Cross-sectional IV (2SLS):**
```
Y_c = α + β * AirFreight_c + X_c'γ + δ_r + ε_c
```
where:
- Y_c = manufacturing employment share or log manufacturing employment in county c
- AirFreight_c = log(1 + freight tonnage) from nearest airport serving county c
- X_c = terrain ruggedness, mean temperature, precipitation, highway density, rail access, port proximity, pre-war (1940) population, land area
- δ_r = census division fixed effects
- Instrument: WWII_airfield_c (binary or count of converted airfields)

**First stage:**
```
AirFreight_c = π₀ + π₁ * WWII_airfield_c + X_c'π₂ + δ_r + ν_c
```

## Data Sources and Fetch Strategy
1. **WWII Airfields:** Wikipedia state-by-state lists of WWII airfields + FAA NASR database for current airport status. Match by name/coordinates.
2. **Airport Freight:** BTS T-100 Domestic/International Segment Data — airport-level annual freight tonnage (1990-present). Free download.
3. **Manufacturing Employment:** Census County Business Patterns (CBP) — county × NAICS employment. Free via Census API.
4. **Controls:** USGS terrain ruggedness, PRISM climate normals, HIFLD highway data, pre-war population from NHGIS/Census.
5. **Robustness:** BLS QCEW for alternative employment measures.

## Robustness Checks
1. Balance tests: pre-determined covariates (1940 population, terrain, climate)
2. Reduced form: WWII airfield → manufacturing (without 2SLS)
3. Placebo outcomes: non-tradeable services employment (shouldn't respond to air freight)
4. Placebo instrument: WWII army camps (non-airfield) that didn't create airports
5. Varying distance radius for airport assignment (25mi, 50mi, 75mi)
6. Controlling for military base presence (separate from airfield)
7. Anderson-Rubin confidence intervals for weak-IV robustness
