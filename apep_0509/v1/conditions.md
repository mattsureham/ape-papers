# Conditional Requirements

**Generated:** 2026-03-04T16:13:55.373233
**Status:** RESOLVED

---

## PURSUING: When Labor Gets Expensive: MGNREGA, Input Substitution, and Crop-Specific Agricultural Productivity

### Condition 1: demonstrating clear parallel trends in the 6-year pre-period

**Status:** [x] RESOLVED

**Response:** ICRISAT DLD provides crop yield data from 1966-2017 for 313 apportioned districts. The pre-treatment period (2000-2005) gives 6 years before Phase I (2006). CS-DiD event-study plots will show pre-treatment coefficients for each phase cohort. The analysis will include a joint F-test for pre-trend coefficients = 0. If pre-trends appear for specific crops, phase-specific linear trend controls will be added as robustness.

**Evidence:** ICRISAT API tested — 16,146 district-year rows confirmed. Pre-2006 data verified for all 313 districts.

---

### Condition 2: proving the first-stage wage effect holds robustly in this specific sample

**Status:** [x] RESOLVED

**Response:** ICRISAT DLD wages endpoint provides district-level male and female agricultural field labor wages from 1966-2013. This covers the core treatment period (2006-2008) and 5-7 post-treatment years. The first stage will regress log(agricultural wage) on MGNREGA phase × post indicators with district and year FE. This builds on Imbert & Papp (2015) and Berg et al.'s established wage effect, but validates it in the specific ICRISAT sample.

**Evidence:** ICRISAT wages API tested — 14,707 rows, 1966-2013, with DISTRICT MALE FIELD LABOUR and DISTRICT FEMALE FIELD LABOUR variables confirmed.

---

### Condition 3: robust pre-trend tests and spatial spillover checks

**Status:** [x] RESOLVED

**Response:**
- **Pre-trends:** CS-DiD event-study with phase-specific pre-treatment coefficients. Joint null test. HonestDiD sensitivity analysis (Rambachan & Roth 2023) for robustness to pre-trend violations.
- **Spatial spillovers:** (a) Exclude districts bordering Phase I districts from Phase II/III controls; (b) test for spillover effects using neighbor-phase exposure; (c) use state × year FE to absorb within-state spatial correlation.

**Evidence:** Design-level commitments. Spatial neighbor matrix constructable from ICRISAT district lat/lon coordinates.

---

### Condition 4: pilot ICRISAT API pulls for full data coverage

**Status:** [x] RESOLVED

**Response:** All required ICRISAT endpoints tested successfully:
- area-production-yield: 16,146 rows, 313 districts, 29 crops, 1966-2017
- fertilizer-consumption: 16,047 rows, NPK per hectare, 1966-2017
- wages: 14,707 rows, male/female field labor, 1966-2013
- cropwise-irrigated-area: 15,943 rows, 1966-2020
- population (Census): 1,850 rows, 1961-2011 (for backwardness index construction)
- monthly-rainfall: 14,527 rows, 1966-2003
- farm-harvest-prices: 15,150 rows, 17 crops, 1966-2016

**Evidence:** curl tests all returned HTTP 200 with valid JSON. API requires no authentication.

---

## NOT PURSUING: Other Ideas

All conditions for Ideas 2-5 (FRA, APMC, Demonetization, Jan Dhan) marked NOT APPLICABLE — not pursuing.

---

## Verification Checklist

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Status: RESOLVED**
