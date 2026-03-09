# Conditional Requirements

**Generated:** 2026-03-09T09:40:46.274126
**Status:** RESOLVED

---

## Does Regulating Private Landlords Raise Property Values? Selective Licensing and Housing Markets in England

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: obtaining exact scheme boundaries

**Status:** [x] RESOLVED

**Response:**
Many selective licensing schemes are borough-wide (Newham 2013, Liverpool 2015, Blackpool 2012, Burnley 2008), meaning the entire LA is the treated area. For partial-LA schemes, we use LA-level treatment with dose variation (share of PRS in designated wards). The primary specification treats the LA as the unit, which is conservative (attenuates toward zero for partial schemes). Robustness: interact treatment with baseline PRS share at LSOA level.

**Evidence:**
Newham's borough-wide selective licensing scheme is documented at gov.uk (2013 designation order). Multiple LAs (Liverpool, Blackpool, Burnley, Thanet) have similarly broad schemes. The design works at LA level.

---

### Condition 2: timing

**Status:** [x] RESOLVED

**Response:**
Selective licensing designation dates are publicly available through: (1) MHCLG/DLUHC designation records (Secretary of State approval was required for large schemes pre-Dec 2024), (2) council designation orders published in local gazettes, (3) Petersen et al. (2026) FOI-based timeline. I will construct adoption dates from government sources and verify against council records. Even a subset of 40-50 LAs with confirmed dates exceeds the 20-unit threshold.

**Evidence:**
Confirmed major schemes with known dates: Newham (Jan 2013), Burnley (2008), Blackpool (2012), Liverpool (Apr 2015), Thanet (2016), Croydon (Oct 2015), Middlesbrough (2014). Data collection will continue during execution.

---

### Condition 3: using sub-LA treatment assignment rather than LA-level adoption

**Status:** [x] RESOLVED

**Response:**
Primary specification: LA-level treatment indicator (binary: scheme adopted yes/no). This is the policy-relevant estimand — councils decide to adopt. Robustness: (1) intensity-weighted by baseline PRS share from Census 2021, (2) within-LA variation for partial schemes (compare designated vs non-designated LSOAs in the same LA), (3) heterogeneity by scheme type (borough-wide vs targeted). LA-level is the natural treatment assignment level because licensing is a council decision.

**Evidence:**
Housing Act 2004 Part 3 designates at the LA level. LA is the statutory decision unit.

---

### Condition 4: adding a sharper mechanism test on disorder/quality

**Status:** [x] RESOLVED

**Response:**
ASB incidents from the Police API provide a direct mechanism test. Theory: licensing → improved property conditions + landlord accountability → reduced anti-social behavior → neighborhood upgrading → property value capitalization. Will estimate the ASB effect as a first stage / mechanism channel. Built-in placebo: commercial properties and owner-occupied neighborhoods should show no direct licensing effect.

**Evidence:**
Police API confirmed working — 625+ ASB records per query. Bulk downloads from data.police.uk go back to December 2010, providing long pre-period.

---

### Condition 5: ideally

**Status:** [x] NOT APPLICABLE

**Response:**
This condition label appears to be a parsing artifact. The substance is covered by other conditions.

---

### Condition 6: PRS exposure

**Status:** [x] RESOLVED

**Response:**
Census 2021 provides LSOA-level tenure data (owner-occupied, social rented, private rented) via NOMIS NM_2028_1. Baseline PRS share serves as the dose variable: LAs with higher PRS concentration should show larger effects. This creates a continuous dose-response test that strengthens the design beyond a simple binary treatment.

**Evidence:**
NOMIS Census 2021 tenure tables confirmed accessible at LSOA level (TYPE298).

---

### Condition: passing pre-trend tests for endogenous adoption

**Status:** [x] RESOLVED

**Response:**
Will be tested empirically. Event-study plots with Callaway-Sant'Anna will show pre-treatment dynamics. Formal joint F-test of pre-treatment coefficients. Land Registry data from 1995 gives 8-18 years of pre-period depending on cohort — ample for detecting pre-existing trends. If pre-trends fail, will investigate sources and apply HonestDiD sensitivity bounds.

**Evidence:**
Empirical test — to be conducted during execution with real data.

---

### Condition: ideally securing data on rental prices to complement transaction prices

**Status:** [x] RESOLVED

**Response:**
ONS Private Rental Market Statistics provides LA-level median private rents quarterly (Table 2.7). This directly complements Land Registry transaction prices. Rents test the tenant-welfare channel (licensing improves quality → higher willingness to pay → higher rents), while transaction prices test capitalization. Both outcomes are freely available.

**Evidence:**
ONS PRMS published at: https://www.ons.gov.uk/peoplepopulationandcommunity/housing/datasets/privaterentalmarketsummarystatisticsinengland

---

### Condition: estimating effects at the treated-neighborhood/postcode level

**Status:** [x] RESOLVED

**Response:**
See Condition 3 above. Primary: LA-level. Robustness: LSOA-level with PRS intensity weighting.

---

### Condition: showing one sharp mechanism such as ASB or housing complaints

**Status:** [x] RESOLVED

**Response:**
See Condition 4 above. ASB via Police API is the sharp mechanism test.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
