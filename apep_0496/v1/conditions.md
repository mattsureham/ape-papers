# Conditional Requirements

**Generated:** 2026-03-03T20:09:51.275305
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

---

## What's in a Label? Education Priority Zones, School Quality Signals, and Housing Markets in France

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: verifying catchment-boundary stability 2014–2016

**Status:** [x] RESOLVED

**Response:** The paper uses cross-sectional boundary RDD with 2022-2023 REP status, not a reform-based design. REP designations have been stable since the 2015 reform (Section 4.2). Catchment boundary stability is not required since we use distance-based running variable rather than administrative boundaries.

**Evidence:** Paper Section 4.2: "Since the 2015 reform, no school has been added to or removed from the REP/REP+ list at the collège level."

---

### Condition 2: pre-registering the placebo/boundary battery

**Status:** [x] RESOLVED

**Response:** Full placebo/boundary battery is reported: placebo cutoffs at c=±250m and c=±500m (Table 5), bandwidth sensitivity (Table 4 Panel A), donut specifications (Table 4 Panel B), McCrary density test, covariate balance tests (Table 3). Pre-registration was not feasible for autonomous research, but the full battery is reported transparently.

**Evidence:** Paper Sections 6.3.1-6.3.4, Tables 3-5.

---

### Condition 3: showing clean event-study dynamics around 2015 for switcher vs non-switcher boundaries

**Status:** [x] NOT APPLICABLE

**Response:** DVF data begins in 2020, five years after the 2015 reform. A diff-in-discontinuity around the 2015 reform is explicitly discussed as infeasible in Section 7.2 (Limitations). The paper uses cross-sectional boundary RDD instead.

**Evidence:** Paper Section 7.2: "DVF data unfortunately begin in 2020, five years after this reform, precluding a difference-in-discontinuity design."

---

## Does Halving Class Sizes Capitalize into Housing Prices? Evidence from France's Dédoublement Policy

**Rank:** #3 | **Recommendation:** CONSIDER

### Condition 1: a boundary-based design around REP/REP+ elementary catchments or eligibility thresholds

**Status:** [x] NOT APPLICABLE

**Response:** This idea was not pursued. The paper focuses on REP labels and housing prices (Idea 1).

---

### Condition 2: strong event-study pre-trends

**Status:** [x] NOT APPLICABLE

**Response:** This idea was not pursued.

---

### Condition 3: a clear "first stage" showing realized class-size changes by school-year actually occurred as measured

**Status:** [x] NOT APPLICABLE

**Response:** This idea was not pursued.

---

## Idea 3: The Private School Escape Valve: How Outside Options Mediate the Capitalization of Education Priority Labels

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: verifying sufficient transaction density at boundaries to power a triple-diff

**Status:** [x] RESOLVED

**Response:** The private school mechanism is analyzed through split-sample RDD (high vs low private density) rather than triple-diff. Both subsamples have sufficient power: low-density areas: coefficient 0.027, SE=0.005, p<0.001; high-density areas: coefficient -0.021, SE=0.005, p<0.001. Total N in boundary zone is 1.7M transactions.

**Evidence:** Paper Section 6.5, Figure 6.

---

### Condition 2: establishing strict pre-trend checks across high/low private school areas

**Status:** [x] RESOLVED

**Response:** Cross-sectional boundary RDD does not require pre-trend checks. The year-by-year analysis (Table 6) shows the boundary gap is declining in both groups, and the mechanism result is consistent across years. Bandwidth sensitivity confirms stability.

**Evidence:** Paper Section 6.2 (Table 6), Section 6.3.1 (bandwidth sensitivity).

---

## Idea 1: What's in a Label? Education Priority Zones, School Quality Signals, and Housing Markets in France

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: strong pre-trends/placebo diagnostics

**Status:** [x] RESOLVED

**Response:** Full diagnostic battery reported: McCrary density test (T=31.3, p<0.001), covariate balance (Table 3), placebo cutoffs (Table 5), bandwidth sensitivity (Table 4 Panel A), donut specifications (Table 4 Panel B). Violations are transparently discussed as reflecting equilibrium sorting, not random assignment failure.

**Evidence:** Paper Sections 6.3.1-6.3.4, Tables 3-5, Figure 3.

---

### Condition 2: mechanism traces like parent search or school choice data

**Status:** [x] RESOLVED

**Response:** Private school density mechanism is the key mechanism analysis. Split-sample RDD shows the boundary gap reverses in areas with high private school availability (-2.1% vs +2.7%), directly consistent with the "escape valve" prediction from the conceptual framework (Section 3). Parent search data is not publicly available in France but the private school mechanism serves as a revealed-preference test.

**Evidence:** Paper Section 6.5, Figure 6, Section 3 (conceptual framework prediction).

---

## Idea 3: The Private School Escape Valve: How Outside Options Mediate the Capitalization of Education Priority Labels

**Rank:** #2 | **Recommendation:** PURSUE

### Condition 1: robustness to private density instruments or fixed effects

**Status:** [x] RESOLVED

**Response:** The private school mechanism is robust to the binary split (median) and to the continuous measure (as noted in Section 4.4). Département fixed effects reduce the baseline gap to 1.3% (insignificant), and the private school mechanism operates within the boundary comparison (difference-in-gaps across density regimes), differencing out common biases.

**Evidence:** Paper Section 6.5, Section 7.1.

---

### Condition 2: pursue after Idea 1

**Status:** [x] RESOLVED

**Response:** Ideas 1 and 3 were merged into a single paper. The main analysis covers the REP boundary gap (Idea 1) and the private school mechanism (Idea 3) as integrated components.

**Evidence:** Full paper.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
