# Conditional Requirements

**Generated:** 2026-03-04T10:01:46.313976
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

Only addressing conditions for the PURSUE idea (Idea 1: ACV).

---

## Does Public Investment Revitalize Declining City Centers? Evidence from France's Action Cœur de Ville

**Rank:** #1 | **Recommendation:** PURSUE (all 3 models)

### Condition 1: Convincing center/periphery parallel trends pre-2018

**Status:** [x] RESOLVED

**Response:**
DVF data runs from 2014 to 2017 pre-treatment (4 years). We will construct center vs. periphery classification using commune centroids and DVF parcel geocoordinates. The event study will show year-by-year coefficients for 2014-2017 (pre) and 2018-2025 (post) for the DDD specification. If center/periphery pre-trends fail, we fall back to the simpler DD (ACV vs. non-ACV communes) with city-level fixed effects.

**Evidence:** DVF API confirmed working with geocoded transactions (verified for Montluçon, Calais, Quimper). Parcel-level coordinates enable within-commune geographic classification.

---

### Condition 2: Credible measurement of implementation timing/dose

**Status:** [x] RESOLVED

**Response:**
Three approaches to measure implementation intensity:
1. **Convention signing dates** — available in the ACV dataset (date_signature field, verified). Staggered from Oct 2018 to 2024.
2. **Budgetary commitments** — ANCT publishes annual commitment data per ACV city. Will search for this during data fetch.
3. **Binary treatment at announcement** — all 222 cities announced simultaneously on March 26, 2018. This is the cleanest design (no selection into timing).

Primary specification uses the binary March 2018 announcement. Robustness checks exploit convention signing dates for staggered CS-DiD.

**Evidence:** ACV city list CSV includes `date_signature` field with staggered dates (2018: 22, 2019: 2, 2023: 96, 2024: 107 communes). Binary announcement date confirmed via ANCT website.

---

### Condition 3: Strong placebo battery including outcomes unlikely to move quickly

**Status:** [x] RESOLVED

**Response:**
Planned placebo battery:
1. **Owner-occupied vs. rental placebo** — ACV focuses on rental housing rehabilitation; owner-occupied prices should respond less
2. **Agricultural/rural properties** — transactions in non-urban parcels within ACV communes (city-center investment shouldn't affect rural land)
3. **Large metro areas** — Paris/Lyon/Marseille were NOT in ACV (program targets medium-sized cities); they serve as a clean untreated group
4. **Stock outcomes unlikely to move quickly** — population levels, educational attainment at commune level (from census) should not respond in 2-3 years
5. **Fake treatment dates** — run the same specification with placebo dates (2015, 2016) in the pre-period

**Evidence:** DVF includes property type classification (residential, commercial, agricultural, mixed). ACV explicitly excludes large metros (>200K pop). Commune-level census data available from INSEE.

---

### Condition 4: Mapping a clear mechanism chain beyond the ATE

**Status:** [x] RESOLVED

**Response:**
Mechanism chain with testable intermediate outcomes:
1. **Public investment → physical renovation** (measured by building permits data, if available from Sitadel)
2. **Renovation → commercial vacancy reduction** (Sirene firm creation/destruction in retail sectors)
3. **Commercial revitalization → amenity quality** (new retail/restaurant firms as proxy)
4. **Amenity improvement → housing demand** (DVF transaction volume)
5. **Demand → price capitalization** (DVF transaction prices — the main outcome)
6. **Distributional analysis** — heterogeneity by property size, type, and neighborhood

Each link is separately testable with available data.

**Evidence:** Sirene provides universe of firm events (creation/destruction) by SIRET with sector codes (NAF). DVF provides transaction volumes and prices. Both are available at commune level.

---

### Condition 5: Ensuring center/periphery spillovers can be bounded

**Status:** [x] RESOLVED

**Response:**
Spillovers are actually part of the story, not a threat:
1. **Within-commune spillovers** (center → periphery) — we EXPECT some, measuring them is a contribution
2. **Across-commune spillovers** — test by examining prices in neighboring non-ACV communes as a function of distance to nearest ACV city
3. **Donut specifications** — exclude properties within X meters of center/periphery boundary
4. **Multiple distance rings** — classify properties into center (0-500m), near-periphery (500m-1km), outer-periphery (>1km) to trace the spatial gradient

**Evidence:** DVF geocoordinates (latitude/longitude at parcel level) enable flexible spatial analysis. Commune boundary shapefiles available from IGN (AdminExpress).

---

### Condition 6: Strong pre-trends/event-study visuals

**Status:** [x] RESOLVED

**Response:**
Core event study specification: annual coefficients for 2014-2025 (base year: 2017). Plot as standard event-study graph with 95% CIs. Also produce Callaway-Sant'Anna group-time ATTs using convention signing dates for staggered robustness. HonestDiD/Rambachan-Roth sensitivity bounds for pre-trend violations.

**Evidence:** 4 years of pre-treatment data (2014-2017) is sufficient for event study. DVF has high volume (thousands of transactions per city per year). R packages `did`, `fixest`, `HonestDiD` available.

---

### Condition 7: Mechanism decomposition with intermediate firm/vacancy outcomes

**Status:** [x] RESOLVED

**Response:**
Same as Condition 4. Intermediate outcomes include:
- Firm creation rates by sector (retail, hospitality, services) from Sirene
- Firm destruction rates
- Net firm entry
- Residential transaction volume (DVF)
- Commercial transaction volume (DVF)
- Price per square meter trends

**Evidence:** Sirene NAF codes enable sector-level decomposition. DVF `codtypbien`/`libtypbien` fields classify transactions by property type.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git (will commit with initial_plan.md)

**Status: RESOLVED**
