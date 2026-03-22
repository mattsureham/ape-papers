# Research Plan: Into the Dark — The Capitalization of Light Pollution Reduction from Dark Sky Ordinances

## Research Question
Do International Dark Sky Community designations — which require legally enforceable outdoor lighting ordinances — increase residential property values? This paper provides the first causal estimate of the amenity value of darkness.

## Identification Strategy
**Staggered DiD (Callaway–Sant'Anna 2021)** exploiting the staggered timing of DarkSky International community certifications across 29 US communities (2001–2023). Each treated community receives certification at different times, providing variation in treatment timing necessary for modern staggered DiD estimation.

**Key assumption:** Parallel trends — in the absence of Dark Sky designation, treated communities would have experienced the same property value trajectory as matched control communities.

**Control group:** For each treated zip code, 3–5 matched control zip codes selected on:
- Pre-treatment ZHVI level and trend
- Population size (ACS)
- Rural/suburban classification
- Geographic proximity (same state or census region)

**Pre-treatment validation:**
- Event-study plots showing flat pre-trends in property values
- Balance tests on covariates

## Expected Effects and Mechanisms
1. **Direct amenity value:** Reduced light pollution improves nighttime aesthetics, stargazing, sleep quality → positive capitalization into home values
2. **Tourism/branding:** Dark Sky designation attracts astro-tourism, raising local economic activity → positive housing demand
3. **Signal of community quality:** Certification requires coordinated governance → property value signal
4. **Expected sign:** Positive effect on ZHVI, magnitude 3–8% based on analogy to other environmental amenity capitalizations

## Primary Specification
$$ATT(g,t) \text{ via Callaway–Sant'Anna (2021)}$$

Where groups $g$ are defined by the year of Dark Sky Community certification, and outcomes are log(ZHVI) at the zip-code–month level. Standard errors clustered at the community level (29 clusters — will supplement with wild cluster bootstrap).

## Secondary Outcomes
- VIIRS nighttime radiance (mechanism/first stage)
- CDC PLACES sleep data (health mechanism)

## Data Sources and Fetch Strategy

### 1. DarkSky International Community Designations
- Source: DarkSky International website / manual coding from public records
- Variables: Community name, state, designation year, zip codes
- 29 US communities, 2001–2023

### 2. Zillow Home Value Index (ZHVI)
- Source: Zillow Research Data (public CSV download)
- URL: https://www.zillow.com/research/data/
- Variables: ZHVI (median home value), zip-code level, monthly, 2000–2024
- Unit: Zip code × month panel

### 3. American Community Survey (ACS)
- Source: Census API
- Variables: Population, median household income, education, rural/urban classification
- For matching and balance tests

### 4. VIIRS Nighttime Radiance (if accessible)
- Source: NOAA Earth Observation Group
- Annual composites, 2012–2024
- For first-stage: verifying ordinances reduce radiance

## Robustness Checks
1. Alternative control groups (nearest-neighbor matching, synthetic control)
2. Placebo treatment dates (random assignment of treatment years)
3. Different pre-treatment matching windows
4. Wild cluster bootstrap for inference with 29 clusters
5. Excluding tourism-heavy communities (Sedona, Flagstaff)
6. Donut analysis excluding designation year
