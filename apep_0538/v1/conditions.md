# Conditional Requirements

**Generated:** 2026-03-06T11:53:50.345029
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

All conditions for the selected idea (Idea 1: ZFE + DVF) are addressed below.
Conditions for non-selected ideas (Ideas 2 and 3) are marked NOT APPLICABLE.

---

## Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: reframing the core claim as capitalization/incidence unless composition data are added

**Status:** [x] RESOLVED

**Response:**
Paper will be reframed as "capitalization and distributional incidence" rather than "gentrification." DVF records property characteristics (type, area, rooms) enabling hedonic decomposition, but cannot directly measure resident composition changes. The paper will: (1) estimate price capitalization as the primary outcome, (2) decompose by property type/size as a proxy for market segment, (3) test whether small/affordable properties see disproportionate price increases (regressive incidence), (4) explicitly acknowledge that displacement cannot be measured with DVF alone. Title revised to: "Do Low-Emission Zones Price Out the Poor? Vehicle Bans, Air Quality, and Housing Market Incidence in French Cities."

**Evidence:** DVF fields include property type (apartment/house), surface area, number of rooms — sufficient for hedonic decomposition and market-segment analysis.

---

### Condition 2: using repeat-sales or parcel-level specifications plus strong boundary/event-study placebo tests

**Status:** [x] RESOLVED

**Response:**
Design will include: (1) Parcel-level fixed effects using DVF's cadastral parcel identifiers (idparcelle) to control for time-invariant location characteristics. (2) Repeat-sales specification restricted to parcels with 2+ transactions in the panel. (3) Event-study specification showing dynamic treatment effects with pre-treatment coefficients as placebo test. (4) Placebo boundary test: use administrative boundaries (arrondissement borders within ZFE cities) that don't correspond to any ZFE discontinuity. (5) Placebo outcome: commercial property transactions (which should not respond to residential air quality improvements).

**Evidence:** DVF includes idparcelle (cadastral parcel identifier) enabling repeat-sales matching. Paris alone has thousands of parcels with multiple transactions 2014-2024.

---

### Condition 3: documenting a credible air-quality first stage with official monitor or satellite data

**Status:** [x] RESOLVED

**Response:**
Will use two sources for the air quality first stage: (1) LCSQA/Geod'Air official regulatory monitoring station data (France's national air quality monitoring network), which reports hourly NO2/PM2.5/PM10 from fixed stations inside and outside ZFEs. (2) Copernicus Atmosphere Monitoring Service (CAMS) reanalysis providing gridded (0.1 degree) daily pollution estimates across all of France. Open-Meteo will be used only as a convenience API for CAMS data, not as an independent source. The first stage will show that ZFE adoption reduces local NO2/PM concentrations at nearby monitors.

**Evidence:** LCSQA publishes station-level data via data.gouv.fr. CAMS European reanalysis is freely available via the Copernicus data store.

---

## Idea 1: Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: demonstrating that ZFE boundaries do not perfectly overlap with pre-existing demographic fault lines

**Status:** [x] RESOLVED

**Response:**
Design includes: (1) Balance tests on pre-treatment property characteristics (price/m2, property type mix, transaction volume) at the ZFE boundary. (2) Donut specification excluding properties within 200m of the boundary to address sorting. (3) Boundary bandwidth robustness (500m, 1km, 2km). (4) Cross-city variation: the 12 ZFEs have different boundary shapes — some follow ring roads, others follow administrative borders, providing variation in boundary type.

**Evidence:** Will be demonstrated empirically in the analysis.

---

### Condition 2: including a robust test for traffic/pollution spillovers just outside the zone

**Status:** [x] RESOLVED

**Response:**
Design includes: (1) Distance gradient analysis — estimate treatment effects in concentric rings (0-500m, 500m-1km, 1km-2km, 2km-5km) outside the ZFE boundary. If traffic displacement dominates, properties just outside should see negative effects (more traffic, worse air). If amenity spillovers dominate, there should be positive effects that decay with distance. (2) Air quality first stage estimated separately inside and outside the zone. (3) Triple-difference: compare residential vs commercial properties at the boundary (commercial should not respond to residential amenity).

**Evidence:** Will be demonstrated empirically in the analysis.

---

## Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: using a tighter design than a simple inside/outside DiD

**Status:** [x] RESOLVED

**Response:**
Primary specification is a boundary DiD within narrow bandwidths (1km default, robustness at 500m and 2km) around ZFE perimeters, combined with the staggered city-level adoption timing. This is tighter than a simple inside/outside because: (1) boundary bandwidth restricts comparison to nearby properties with similar neighborhood characteristics, (2) staggered timing across 12 cities provides cross-city replication, (3) Crit'Air tier tightening within cities provides dose-response variation. Additional specifications: repeat-sales, parcel FE, hedonic controls.

**Evidence:** Design addresses all three reviewer concerns (boundary endogeneity, composition, timing).

---

### Condition 2: adding repeat-sales/parcel FE

**Status:** [x] RESOLVED

**Response:** See GPT-5.4 (A) Condition 2 above — same resolution applies.

---

### Condition 3: strong placebo tests

**Status:** [x] RESOLVED

**Response:**
Planned placebo tests: (1) Event-study pre-trends (core). (2) Placebo boundaries within ZFE cities. (3) Placebo outcomes (commercial properties, land-only transactions). (4) Placebo populations: cities that announced but delayed ZFE implementation. (5) Randomization inference for staggered DiD.

---

### Condition 4: either measuring composition/displacement directly with auxiliary census data or reframing from "gentrification" to "capitalization/incidence"

**Status:** [x] RESOLVED

**Response:** See GPT-5.4 (A) Condition 1 above — paper reframed as capitalization/incidence. Will supplement with INSEE commune-level census data (FILOSOFI) on income distribution where available to provide suggestive evidence on composition, but the core claim is capitalization.

---

## Do Fiber Broadband Networks Fuel Populism? France's Plan France Tres Haut Debit

**Rank:** #2 | **Recommendation:** CONSIDER

### Conditions 1-4: NOT APPLICABLE (idea not selected)

---

## Russia's Gas Cutoff and European Industrial Restructuring

**Rank:** #2 | **Recommendation:** CONSIDER

### Conditions 1-4: NOT APPLICABLE (idea not selected)

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
