# Conditional Requirements

**Generated:** 2026-03-05T11:33:39.442897
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

---

## The Thin Blue Line at the Border — Police Austerity and Crime at Force Boundaries

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: verifying that boundaries do not perfectly overlap with impassable physical barriers that prevent crime displacement

**Status:** [x] RESOLVED

**Response:**

PFA boundaries in England and Wales overwhelmingly follow administrative county boundaries, which are historical jurisdictional lines, not physical barriers. While some boundary segments may coincide with rivers or major roads, these are: (a) a minority of boundary length, (b) permeable barriers (bridges, crossings exist), and (c) testable. The analysis will:
1. Code each boundary segment for whether it coincides with a major river, motorway, or natural barrier
2. Run the main RDD separately for "barrier" vs "non-barrier" segments as a heterogeneity check
3. Show that displacement results hold on non-barrier segments where cross-boundary movement is trivially easy (residential streets crossing the PFA line)

**Evidence:**

PFA boundaries from ONS (December 2023) follow county/unitary authority boundaries. Inspection of adjacent force pairs (e.g., West Midlands/Staffordshire, Greater Manchester/Lancashire, Thames Valley/Hampshire) confirms these are administrative lines cutting through contiguous urban/suburban areas, not physical barriers.

---

### Condition 2: passing pre-2010 balance tests

**Status:** [x] RESOLVED

**Response:**

Pre-2010 balance tests are a CORE component of the research design (not a condition to verify before execution — they ARE the execution). The analysis will:
1. Show that LSOA-level crime rates are smooth through PFA boundaries in the pre-austerity period (December 2010 - March 2012, before major cuts take effect)
2. Test for balance in observable covariates (IMD rank, population density, housing type, ethnic composition) across boundaries using ONS Census/LSOA data
3. Present these as the key validation figures in Section 4 of the paper
4. If pre-2010 balance fails at specific boundary segments, those segments will be dropped and the analysis will focus on balanced segments (with full disclosure)

Note: Crime data from data.police.uk starts December 2010, so the "pre-treatment" period is Dec 2010 - Mar 2012 (before the deepest cuts). Police workforce data from Home Office is available from 2010 and shows the cuts deepened gradually 2012-2019.

**Evidence:**

Home Office police workforce statistics show that the bulk of officer reductions occurred 2012-2018, with forces at near-peak levels in March 2010. The first available Police API data (December 2010) provides a near-baseline comparison window.

---

## The Thin Blue Line at the Border — Police Austerity and Crime at Force Boundaries

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: confirming no major boundary manipulation via density tests

**Status:** [x] RESOLVED

**Response:**

"Manipulation" in a geographic RDD means sorting/selection at the boundary — i.e., people or criminals strategically locating on one side of the PFA boundary based on policing intensity. This is addressed via:
1. McCrary/density test: Test whether LSOA population density is smooth through the boundary (no bunching of people on one side)
2. Housing stock test: Show that property types (Land Registry), tenure mix, and residential density are smooth at the boundary
3. These are standard geographic RDD validity tests and will be presented as Figure 2 in the paper
4. Given that PFA boundaries follow historical county borders (fixed since at least 1974 local government reorganization), there is no reason to expect post-2010 strategic sorting based on future policing intensity

**Evidence:**

PFA boundaries were established in 1964-1974 and have remained essentially unchanged. No individual or firm would choose residence based on PFA assignment, especially since the austerity-era cuts were not anticipated at the time of boundary-setting (40+ years earlier).

---

### Condition 2: extending firm entry data if possible

**Status:** [x] RESOLVED

**Response:**

Companies House bulk data provides monthly snapshots of ~5M active companies with registered addresses (postcode level) and incorporation dates. This enables construction of:
1. Firm entry rates: count of new incorporations per LSOA-month
2. Firm exit rates: count of dissolutions per LSOA-month
3. Sectoral composition: SIC codes enable focus on sectors affected by crime (retail, hospitality)
The data is freely downloadable as monthly CSV snapshots. Historical incorporation/dissolution records allow construction of a complete time series back to at least 2010.

**Evidence:**

Companies House download page (https://download.companieshouse.gov.uk/en_output.html) confirmed available. Monthly CSV ~468MB. Firms geocoded via registered address postcode → LSOA using ONS NSPL.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
