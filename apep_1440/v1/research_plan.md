# Research Plan: Limestone's Filter — Karst Geology, PFAS Contamination, and Infant Health

## Research Question
Does geological formation type (karst vs. non-karst) causally determine PFAS contamination in drinking water near military AFFF sites, and do communities on karst aquifers experience worse birth outcomes?

## Identification Strategy
**Spatial RDD at karst/non-karst geological boundaries.** The running variable is distance to the nearest karst boundary. Public water systems (PWSs) on karst geology near DoD AFFF sites face rapid PFAS transport through conduit flow (meters/day), while PWSs on non-karst geology face slow diffuse transport with soil filtration (cm/year). Geology is millions of years old — completely exogenous to modern settlement, military base placement, and demographic composition.

**Two-stage approach:**
1. **First stage:** Show PFAS detection rates jump discontinuously at karst boundaries (UCMR5 data)
2. **Reduced form:** Show birth outcomes deteriorate discontinuously at karst boundaries near DoD PFAS sites

## Expected Effects
- PFAS detection rates: large positive jump on karst side (rapid groundwater transport)
- Birth weight: moderate negative effect on karst side
- Low birth weight incidence: moderate positive effect on karst side
- Preterm birth: small-to-moderate positive effect on karst side

## Primary Specification
Local polynomial RD: Y_i = α + τ·Karst_i + f(distance_i) + X_i'β + ε_i
- Bandwidth: MSE-optimal (rdrobust)
- Kernel: triangular
- Controls: maternal age, race, education, prenatal care, county-level income

## Data Sources
1. **UCMR5** — EPA PFAS monitoring data (13MB, 1.15M rows, 4,500+ PWSs)
2. **USGS Karst Map** — National karst geology boundaries (ScienceBase geodatabase)
3. **DoD PFAS Sites** — Military installations with known AFFF contamination
4. **NBER Vital Statistics** — Birth outcomes (1995-2024, county FIPS)
5. **ECHO/SDWA** — PWS locations and service area info

## Fetch Strategy
1. Download UCMR5 CSV from EPA
2. Download USGS karst geology shapefile
3. Get DoD PFAS installation list
4. Download NBER natality county-level aggregates (or use CDC WONDER)
5. Spatial join: classify each PWS as karst/non-karst, compute distance to boundary
