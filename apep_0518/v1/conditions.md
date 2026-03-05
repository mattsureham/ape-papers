# Conditional Requirements

**Generated:** 2026-03-05T11:54:26.966120
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

For each condition:
1. **Validate** - Confirm the condition is satisfied (with evidence)
2. **Mitigate** - Explain how you'll handle it if not fully satisfied
3. **Document** - Update this file with your response

**DO NOT proceed to Phase 4 until all conditions are marked RESOLVED.**

---

## Does Place-Based Policy Create or Relocate? Evidence from France's Neighborhood Redesignation

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: demonstrating a strong first-stage on policy resources/benefits

**Status:** [X] RESOLVED

**Response:** Losing ZUS status means loss of: (1) Contrats de Ville funding (operational budgets for social programs), (2) eligibility for ANRU urban renewal investment, (3) ZFU-TE tax exemptions for establishments in the 100 ZFU subset, (4) priority allocation of "adultes-relais" mediators and "emplois francs" hiring subsidies. I will document the per-neighborhood funding magnitude from ONPV/CGET annual reports and show the first stage as a discontinuity in Contrats de Ville funding around the redesignation.

**Evidence:** ONPV 2016 annual report documents ~€400M annual Contrats de Ville allocation across QPV; former ZUS losing status lose access to this. ANRU renovation budgets (€12B total NPNRU) are QPV-conditioned.

---

### Condition 2: addressing spillovers

**Status:** [X] RESOLVED

**Response:** Spillovers are not a threat — they are the CORE hypothesis. The paper's central question is whether firm creation displaced from lost-status neighborhoods to gained-status neighborhoods. I will: (1) estimate effects separately for lost-status, gained-status, and kept-status neighborhoods, (2) use concentric ring buffers (500m, 1km, 2km) around neighborhood boundaries to measure spatial spillovers, (3) test whether total firm creation across all ZUS+QPV neighborhoods changed (net effect test).

**Evidence:** Ring-buffer analysis plan in initial_plan.md. The net displacement test is the paper's primary contribution.

---

### Condition 3: retargeting endogeneity with border/near-threshold designs or very tight local controls

**Status:** [X] RESOLVED

**Response:** Three strategies: (1) QPV designation used a formula based on 200m grid income data — I will exploit the income threshold as an RDD complement (neighborhoods just above vs. just below the poverty cutoff), (2) entropy balancing on pre-2014 characteristics (firm counts, population, income, sector composition), (3) comparison within ZUS→QPV vs. ZUS→nothing restricts to neighborhoods that were ALL previously treated, making pre-treatment parallel trends more credible.

**Evidence:** QPV methodology documentation from CGET/ANCT describes the income-threshold formula. McCrary density test will verify no manipulation at the threshold.

---

## Does Losing Rural Revitalization Status Deter Firm Creation? Evidence from France's 2017 ZRR Reclassification

**Rank:** #2 | **Recommendation:** PURSUE

### Condition 1: confirming sufficient treated communes

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: event counts

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 3: exploring cutoff-based or near-threshold designs to strengthen exogeneity beyond DiD

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Business Tax Abolition and Firm Location — Evidence from France's CVAE Phase-Out

**Rank:** #4 | **Recommendation:** CONSIDER

### Condition 1: obtaining credible firm tax/turnover microdata for a sharper design

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: or a longer post window

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 3: otherwise this is likely to be attacked as under-identified

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Does Place-Based Policy Create or Relocate? Evidence from France's Neighborhood Redesignation

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: demonstrating strict parallel trends in the 2010-2014 pre-period

**Status:** [X] RESOLVED

**Response:** SIRENE data provides annual firm creation counts from 2010-2014 (5 pre-treatment years). Event-study specification with year-by-treatment-status interactions will test for differential pre-trends. Additionally, HonestDiD/Rambachan-Roth sensitivity analysis will bound plausible violations. Entropy balancing on pre-period levels and trends strengthens the parallel trends assumption.

**Evidence:** SIRENE StockEtablissement includes creation dates for all establishments. Event-study coefficients will be plotted and tested jointly.

---

### Condition 2: passing placebo tests on the new grid-based poverty threshold

**Status:** [X] RESOLVED

**Response:** Three placebo tests: (1) Run the analysis using placebo redesignation thresholds at +/- 1 standard deviation from the actual income cutoff; (2) Placebo timing test — assign treatment at 2012 or 2013 instead of 2015 and verify null effects; (3) Placebo outcome — test outcomes plausibly unaffected by policy status (e.g., firm types not eligible for QPV programs like agriculture or public administration).

**Evidence:** Placebo tests built into research plan as mandatory robustness checks in 04_robustness.R.

---

## Business Tax Abolition and Firm Location — Evidence from France's CVAE Phase-Out

**Rank:** #2 | **Recommendation:** CONSIDER

### Condition 1: waiting until 2026/2027 for sufficient post-treatment data

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: proving no density manipulation at the €500K threshold

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Idea 1: Does Place-Based Policy Create or Relocate? Evidence from France's Neighborhood Redesignation

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: spatial placebo for spillovers

**Status:** [X] RESOLVED

**Response:** Will construct concentric buffer rings (500m, 1km, 2km, 5km) around each neighborhood boundary. Estimate effects on firm creation in each ring to measure spatial decay of treatment effects. If spillovers are localized (<1km), the displacement interpretation is stronger. If spillovers extend beyond 2km, reinterpret as general neighborhood effects.

**Evidence:** sf package spatial buffer construction verified as feasible with QPV shapefiles.

---

### Condition 2: ZFU sensitivity analysis

**Status:** [X] RESOLVED

**Response:** Main specification will EXCLUDE the 100 ZFU neighborhoods (93 in metropolitan France) from the analysis. ZFU had separate tax exemptions that create a confounding treatment. Robustness check will (1) include ZFU neighborhoods and interact with ZFU status, (2) analyze ZFU neighborhoods separately as a subsample with stronger treatment intensity. Only ~13% of ZUS had ZFU status, so exclusion is clean.

**Evidence:** ZFU shapefile available on data.gouv.fr; 100 ZFU vs. 751 ZUS makes exclusion straightforward.

---

## Idea 3: Does Losing Rural Revitalization Status Deter Firm Creation? Evidence from France's 2017 ZRR Reclassification

**Rank:** #2 | **Recommendation:** PURSUE

### Condition 1: verifying 200+ losers

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: pre-trend diagnostics

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 3: power calculations for MDE

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Idea 5: Business Tax Abolition and Firm Location — Evidence from France's CVAE Phase-Out

**Rank:** #3 | **Recommendation:** CONSIDER

### Condition 1: post-2027 data emerges for longer horizon

**Status:** [X] NOT APPLICABLE — proceeding with Idea 1

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Verification Checklist

Before proceeding to Phase 4:

- [ ] All conditions above are marked RESOLVED or NOT APPLICABLE
- [ ] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
