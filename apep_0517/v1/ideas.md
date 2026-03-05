# Research Ideas

## Idea 1: The Thin Blue Line at the Border — Police Austerity and Crime at Force Boundaries

**Policy:** UK police austerity cuts (2010-2019). Central government grants to the 43 police forces in England and Wales were cut by ~19% in real terms, but the cuts were highly differential: Cleveland lost 31% of officers while Surrey lost 0.4%. This created growing discontinuities in policing intensity at Police Force Area (PFA) boundaries.

**Outcome:** LSOA-level monthly crime counts from the Police API bulk download (December 2010 - January 2026), covering all crime categories (violence, burglary, robbery, vehicle crime, ASB, drugs, etc.). Secondary outcome: HM Land Registry Price Paid Data for property price capitalization of safety at boundaries. ~33,000 LSOAs, 15+ years of monthly data.

**Identification:** Boundary Discontinuity Design (BDD). For each pair of adjacent police forces, compare LSOAs within a narrow bandwidth of the PFA boundary. The running variable is signed distance from LSOA population-weighted centroid to the nearest PFA boundary (positive = heavily-cut force side, negative = lightly-cut side). The identifying assumption is that unobserved determinants of crime are continuous through the boundary, while the policing regime changes discontinuously. Multiple boundaries (43 forces create many boundary pairs) enable multi-cutoff pooling with boundary-segment fixed effects.

**Why it's novel:**
- No existing study exploits PFA boundary discontinuities in England/Wales
- The austerity-driven variation (2010-2019) provides a natural experiment with enormous cross-force variation
- Uniquely positioned to test for crime DISPLACEMENT across boundaries (do criminals migrate to the understaffed side?)
- Multi-margin welfare analysis: crime types + property prices + firm entry/exit
- Internal replication across many boundary segments
- Built-in placebos: online fraud/cybercrime (unaffected by local policing), pre-2010 balance tests

**Feasibility check:**
- PFA boundary shapefiles: ONS Open Geography Portal (free, GeoJSON/Shapefile) -- CONFIRMED
- LSOA population-weighted centroids: ONS (free download, 2021 vintage) -- CONFIRMED
- Crime data: data.police.uk bulk download, LSOA-level, December 2010-present -- CONFIRMED (API tested)
- Police workforce by force: Home Office open data tables, 2010-present (ODS/Excel) -- CONFIRMED
- Land Registry PPD: Free CSV download, 24M+ transactions, postcode-level -- CONFIRMED
- 44 forces listed in API, 33,000 LSOAs -- more than sufficient power

---

## Idea 2: Does Licensing Restraint Reduce Alcohol-Related Crime? Boundary Evidence from Cumulative Impact Zones

**Policy:** Under the Licensing Act 2003, English local authorities can designate Cumulative Impact Assessment (CIA) zones where new alcohol license applications face a rebuttable presumption of refusal. Multiple cities have designated CIAs (London boroughs, Manchester, Bristol, Leeds, Newcastle, Brighton), each with sharp geographic boundaries.

**Outcome:** LSOA-level crime from Police API, focusing on alcohol-related categories (violence, ASB, public order). Land Registry PPD for property price effects at zone boundaries.

**Identification:** Spatial RDD at CIA zone boundaries. Running variable: distance from LSOA centroid to the CIA boundary. Inside the zone, new alcohol outlets are effectively restricted; outside, standard licensing applies. Multiple CIA zones across England enable multi-cutoff pooling.

**Why it's novel:**
- CIAs are a major policy tool but lack rigorous causal evaluation
- Sharp spatial boundaries create clean RDD running variable
- Multi-zone design provides internal replication
- Natural placebo: non-alcohol crime types (burglary, vehicle theft)
- Property price capitalization tests welfare effects

**Feasibility check:**
- CIA zone boundaries: Available from individual LA websites, but NOT centralized. Would require scraping or FOI for each council. This is the major feasibility risk.
- Crime data: Police API confirmed working
- Land Registry: Confirmed
- CONCERN: Endogenous zone designation (zones drawn around problem areas). The RDD requires that the BOUNDARY is not precisely manipulated, which is questionable since LAs draw the boundary.
- VERDICT: Feasible but moderate data access risk for boundaries; endogeneity concern at boundary.

---

## Idea 3: School Quality Shocks and Local Youth Crime — An Ofsted Rating RDD

**Policy:** Ofsted inspects all state schools in England, rating them on a 1-4 scale (Outstanding, Good, Requires Improvement, Inadequate). Schools rated "Requires Improvement" (RI) or "Inadequate" face mandatory interventions: increased monitoring, leadership changes, potential forced academisation. The threshold between "Good" (2) and "RI" (3) triggers a discrete jump in regulatory intensity.

**Outcome:** LSOA-level crime from Police API, focusing on youth-related categories (ASB, violence, criminal damage) within a radius of each school. School-level data from Ofsted/DfE.

**Identification:** Sharp RDD at the Good/RI boundary. The running variable is the Ofsted overall effectiveness judgment or an underlying continuous score. Schools just below the "Good" threshold face dramatically different intervention regimes from schools just above. Compare crime in LSOAs surrounding schools rated just-Good vs. just-RI.

**Why it's novel:**
- Links education quality shocks to crime outcomes (cross-domain)
- Clean institutional threshold with real consequences
- Policy-relevant: Ofsted reform is a major current debate in UK education

**Feasibility check:**
- Ofsted inspection data: Free on data.gov.uk, includes school URN and address
- School-to-LSOA mapping: Via postcodes.io or DfE school locations
- Crime data: Police API confirmed
- CONCERN: Ofsted score is ordinal (1-4), not truly continuous. Manipulation: schools/inspectors may game near the threshold. The "running variable" is not clean.
- CONCERN: Small sample — many schools cluster at Good; few observations near the threshold for inference.
- VERDICT: Interesting but ordinal running variable and potential manipulation weaken the RDD.

---

## Idea 4: Does Rainfall Deter Crime? A Precipitation Threshold Design Using High-Frequency Weather and Crime Data

**Policy:** Not a "policy" per se, but an exogenous environmental shock. Heavy rainfall reduces outdoor activity, creating a natural experiment for crime opportunity theory. The Environment Agency provides 15-minute rainfall data from ~1,000 gauges across England.

**Outcome:** LSOA-level daily/monthly crime counts from Police API, decomposed by indoor vs. outdoor crime types.

**Identification:** Sharp RDD or IV design. The running variable is daily rainfall (mm). Above certain thresholds (e.g., >10mm/day), outdoor activity drops sharply. Compare crime on days just above vs. just below extreme rainfall thresholds. Alternatively, use rainfall as an IV for "outdoor opportunity" (outdoor foot traffic) affecting street crime.

**Why it's novel:**
- High-frequency (15-min) rainfall data is unusually precise for weather-crime analysis
- Mechanism decomposition: outdoor crime (ASB, robbery, violence) should respond; indoor crime (domestic violence, burglary) may increase (displacement)
- Tests both opportunity theory (fewer victims on street → less crime) and routine activity theory

**Feasibility check:**
- EA rainfall data: Confirmed (15-min gauges, ~1,000 stations, API working)
- Crime data: Police API gives monthly data, NOT daily — major limitation
- CONCERN: Police API data is at MONTHLY granularity. Cannot match daily rainfall to daily crime. This makes the high-frequency design infeasible.
- CONCERN: Crime data is geolocated to approximate locations (snapped to street), adding measurement error.
- VERDICT: Monthly crime data kills the high-frequency design. Would need daily crime data (not publicly available).
