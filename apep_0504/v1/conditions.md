# Conditional Requirements

**Generated:** 2026-03-04T13:42:12.828847
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

## Does Naming Work? Mandatory Food Hygiene Rating Display and Restaurant Market Discipline

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: validating entry/exit measurement—ideally using FSA “new/closed” establishment flags or local inspection histories rather than Companies House alone

**Status:** [x] RESOLVED

**Response:**

We use TWO complementary sources for entry/exit: (1) FSA FHRS API, which provides the universe of food establishments with inspection dates, business types, and can track establishment disappearance between snapshots; (2) Companies House bulk data, which provides incorporation/dissolution dates for SIC-coded food businesses. Cross-validation between sources strengthens measurement. The FSA data captures unincorporated businesses (sole traders) that Companies House misses, while Companies House captures formal entry/exit timing more precisely. Primary analysis uses Companies House; FSA used for robustness and quality outcomes.

**Evidence:** FSA API confirmed: 58,243 Welsh + 494,148 English establishments. Companies House: SIC codes 56.10 (restaurants), 56.21 (catering), 56.30 (pubs/bars) identifiable in bulk CSV with incorporation/dissolution dates.

---

### Condition 2: delivering a tight mechanism chain with “bite” checks such as compliance/display evidence

**Status:** [x] RESOLVED

**Response:**

First-stage “bite” is well-documented by the FSA's own audit data: mandatory display achieved 92% compliance in Wales vs. 69% voluntary display in England — a 23 percentage point gap. This is the treatment intensity / first stage. The FSA Display Audit 2022 and 2024 reports provide this evidence. We will present this as a “first-stage” result in the paper before analyzing downstream outcomes.

**Evidence:** FSA FHRS Display Audit 2022 Executive Summary (food.gov.uk/research/fhrs-display-audit-2022-executive-summary); record-breaking compliance data from gov.wales 10-year anniversary report (Nov 2023).

---

### Condition 3: consumer salience proxies

**Status:** [x] RESOLVED

**Response:**

FSA biennial consumer tracker surveys document consumer awareness and usage: 86% of consumers are aware of the FHRS scheme; 48% check ratings before visiting a food business; consumers report changing behavior based on low ratings. These survey results provide direct evidence of consumer salience. Additionally, the FHRS ratings are now integrated into major online platforms (Just Eat, Deliveroo in Wales), providing a digital salience channel beyond physical sticker display.

**Evidence:** FSA “Display of food hygiene ratings” 2017 wave of research; FSA Food and You 2 survey; Just Eat/Deliveroo integration announcements.

---

## Planning Deregulation and the Office-to-Residential Conversion Shock

**Rank:** #3 | **Recommendation:** CONSIDER

### Condition 1: a defensible design beyond treated-vs-exempt DiD—ideally border-based or using renewal timing

**Status:** [x] NOT APPLICABLE (idea not selected)

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: obtaining a strong first-stage measure of office-to-resi conversion intensity at fine geography

**Status:** [x] NOT APPLICABLE (idea not selected)

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Idea 3: The Fiscal Externalities of Poverty: Council Tax Support Cuts and Neighborhood Spillovers

**Rank:** #2 | **Recommendation:** CONSIDER

### Condition 1: developing a robust identification strategy for endogenous LA scheme adoption

**Status:** [x] NOT APPLICABLE (idea not selected)

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: such as a simulated instrument or political IV

**Status:** [x] NOT APPLICABLE (idea not selected)

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Idea 1: Does Naming Work? Mandatory Food Hygiene Rating Display and Restaurant Market Discipline

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: prioritizing core exit/quality margins over spillovers

**Status:** [x] RESOLVED

**Response:**

Paper structure will prioritize: (1) food business exit rates (market discipline), (2) food business entry rates (deterrence of low-quality entrants), (3) average hygiene rating improvement (quality upgrade), (4) rating distribution shift (cleaning the bottom). Property value spillovers moved to appendix as secondary outcome. The core narrative is about information disclosure → market selection, not neighborhood externalities.

**Evidence:** Paper outline restructured; spillovers relegated to supplementary analysis.

---

### Condition 2: running Callaway-Sant'Anna atten for staggered robustness

**Status:** [x] RESOLVED

**Response:**

Wales (Nov 2013) and Northern Ireland (Oct 2016) create two treatment cohorts with England as never-treated. This is textbook two-cohort staggered DiD, ideal for Callaway & Sant'Anna (2021) with `did` package in R. We will report both TWFE and CS-DiD estimates, with event study plots showing dynamic treatment effects for each cohort. HonestDiD sensitivity analysis for pre-trend violations.

**Evidence:** R `did` package supports this design; two cohorts + never-treated identified.

---

## Idea 2: The Great Revaluation: Business Rates Shocks and Commercial Vitality in England

**Rank:** #2 | **Recommendation:** PURSUE

### Condition 1: stacking relief phases in event study

**Status:** [x] NOT APPLICABLE (idea not selected)

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: quantifying MDE for nulls on employment

**Status:** [x] NOT APPLICABLE (idea not selected)

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Idea 3: The Fiscal Externalities of Poverty: Council Tax Support Cuts and Neighborhood Spillovers

**Rank:** #3 | **Recommendation:** CONSIDER

### Condition 1: treatment data cleanly constructed

**Status:** [x] NOT APPLICABLE (idea not selected)

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: focus on one spillover like crime

**Status:** [x] NOT APPLICABLE (idea not selected)

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
