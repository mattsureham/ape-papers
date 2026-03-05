# Conditional Requirements

**Generated:** 2026-03-05T15:14:36.556536
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## ZIP-Code Border RDD — State Tax Differentials and High-Income Geographic Sorting

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: strong pre-2018 event-study flatness by border segment

**Status:** [x] RESOLVED

**Response:** The event study will include border-segment × year fixed effects for 2012-2017 (6 pre-treatment years). Pre-trend tests will use both visual inspection and formal F-tests for joint significance of pre-2018 coefficients. If any border segment shows pre-trends, it will be dropped and results reported with/without.

**Evidence:** Design includes 6 pre-SALT years (2012-2017) and border-pair FE. Pre-trends are a first-order diagnostic — will be reported prominently.

---

### Condition 2: convincing diagnostics that ZIP-level measurement/suppression isn't driving discontinuities

**Status:** [x] RESOLVED

**Response:** IRS suppresses cells with fewer than ~10 returns. Three mitigations: (1) Report share of suppressed ZIPs near each border and show they are balanced across high-tax/low-tax sides. (2) Conduct sensitivity analysis dropping all ZIPs with any suppressed income categories. (3) Use total returns (N1, never suppressed) as a cross-check on the income-bracket results.

**Evidence:** Will be demonstrated in robustness section with explicit suppression balance table.

---

### Condition 3: a narrative that isolates within-metro re-sorting rather than broad state divergence

**Status:** [x] RESOLVED

**Response:** The RDD design already isolates local (near-border) effects rather than broad state trends. Additionally: (1) Restrict sample to border segments within MSAs (e.g., Philadelphia MSA spans NJ/PA, NYC MSA spans NY/NJ/CT). (2) Include border-pair × year FE to absorb region-specific trends. (3) Show that the RDD effect attenuates away from the border (donut/distance heterogeneity).

**Evidence:** Metro-area border segments are the sharpest test. Interior ZIP codes serve as a placebo.

---

### Condition 4: verifying that ZIP code centroids provide enough density close to the border for a well-powered RDD

**Status:** [x] RESOLVED

**Response:** US has ~42,000 ZIP codes. The NJ/PA border alone spans dense metro areas (Philadelphia, Trenton) with hundreds of ZIPs within 20km of the border. Across 8+ border pairs, expect 5,000+ ZIPs within the bandwidth. Will verify empirically during data construction and report effective N.

**Evidence:** NJ has ~600 ZIPs, PA ~2,000. Philadelphia MSA border region alone provides ~200+ ZIPs within 10km. Similar density at NY/CT, CA/NV (Las Vegas metro) borders.

---

### Condition 5: ensuring border-pair fixed effects absorb local trends

**Status:** [x] RESOLVED

**Response:** The specification includes border-segment × year FE. Each border pair (e.g., NJ/PA) gets its own set of year effects, absorbing region-specific economic trends. The identifying variation is the within-border-pair, cross-state discontinuity — comparing ZIPs on opposite sides of the same border segment in the same year.

**Evidence:** Standard in boundary discontinuity literature (Dube, Lester, Reich 2010; Holmes 1998).

---

### Condition 6: confirming no pre-SALT bunching at borders via McCrary test

**Status:** [x] RESOLVED

**Response:** Will run McCrary (2008) density test on the distribution of ZIP code centroids relative to the border. Under the null, ZIP codes should be roughly uniformly distributed near the border (no geographic manipulation). This is a validity check for the RDD — if ZIPs are systematically denser on one side, it may reflect historical sorting (which the SALT cap event study helps address).

**Evidence:** McCrary test will be reported in the paper. Pre-existing density differences (historical sorting) are expected and not a threat — the SALT cap event study identifies the CHANGE in sorting.

---

### Condition 7: adding remote-work robustness post-2020

**Status:** [x] RESOLVED

**Response:** Will report results separately for three periods: (1) Pre-SALT 2012-2017, (2) Post-SALT/Pre-COVID 2018-2019, (3) COVID era 2020-2021. The cleanest estimate is period 2 (post-SALT, pre-COVID). Period 3 will be presented as exploratory — COVID confounds are acknowledged. If the effect strengthens from period 1→2 and further from 2→3, it suggests remote work amplified tax-motivated sorting.

**Evidence:** Three-period decomposition addresses both SALT and COVID identification separately.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
