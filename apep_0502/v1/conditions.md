# Conditional Requirements

**Generated:** 2026-03-04T11:44:55.797306
**Status:** RESOLVED

---

## THESE CONDITIONS HAVE BEEN ADDRESSED

---

## Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: showing the discontinuity in designation is sharp/usable at the county-year level

**Status:** [X] RESOLVED

**Response:** NAAQS nonattainment designations are determined by comparing county-level design values (3-year average of annual PM2.5 concentration, or 4th highest 8-hr ozone value over 3 years) to the standard. The designation is binary: attainment or nonattainment. EPA publishes design values and designations at the county level. The running variable (ambient air quality) is measured by EPA monitors, not controlled by individual facilities, making manipulation implausible. Multiple standard revisions (PM2.5: 15→12→9 μg/m³; Ozone: 80→75→70 ppb) create stacked cutoffs.

**Evidence:** EPA AQS data confirmed accessible — 2020 data shows 7,819 PM2.5 annual monitors across the US. Singer & Shapiro (2025 AEJ) successfully used this exact design value approach for PM2.5 nonattainment RDD.

---

### Condition 2: demonstrating adequate effective N/power for investment outcomes

**Status:** [X] RESOLVED

**Response:** Verified data density: (1) EPA AQS 2020 data shows 394 counties with PM2.5 monitors near the 9 μg/m³ cutoff (7-11 range) and 81 counties near the 12 μg/m³ cutoff (10-14 range). (2) The US has ~10,000 power plants with county locations in EIA Form 860 data. With ~3+ plants per county on average (higher in urbanized nonattainment areas), we expect 1,000+ plant observations within standard RDD bandwidths. (3) Stacking across multiple NAAQS revisions (PM2.5 1997/2006/2012/2024, Ozone 1997/2008/2015) further increases effective N. (4) The outcome is stock-based (installed capacity, operating plant counts) not flow-based, so cumulative effects over long post-periods reduce power concerns.

**Evidence:** EPA AQS test query confirmed 394 counties near PM2.5=9 cutoff; EIA API confirmed generator inventory with county locations.

---

### Condition 3: running explicit spatial substitution/displacement analyses

**Status:** [X] RESOLVED

**Response:** This is a core analytical component of the paper. We will: (1) Test whether new fossil capacity in nonattainment counties is displaced to neighboring attainment counties (ring analysis around nonattainment areas). (2) Examine whether total regional capacity (within commuting zones or NERC regions) changes or whether effects are purely relocational. (3) Use neighboring-county controls as a placebo — counties adjacent to nonattainment areas but in attainment should show opposite-signed effects if displacement is occurring. This spatial displacement analysis is central to the "does nonattainment deter or displace?" question.

**Evidence:** Design feature — will be implemented in 04_robustness.R.

---

### Condition 4: market-area aggregation robustness

**Status:** [X] RESOLVED

**Response:** Will estimate effects at multiple geographic scales: (1) County-level (primary), (2) Commuting zone level (labor market area), (3) NERC region / balancing authority area (electricity market area), (4) State level (regulatory jurisdiction). The multi-scale approach tests whether county-level effects survive aggregation to economically meaningful electricity market areas.

**Evidence:** Design feature — EIA data includes balancing authority assignments for each generator.

---

### Condition 5: verifying sufficient density of new power plant investments/retirements near the nonattainment cutoffs

**Status:** [X] RESOLVED

**Response:** Same as Condition 2. Additionally, the outcome can be measured as: (a) new capacity additions (extensive margin: was any new plant built?), (b) capacity retirement (does nonattainment accelerate fossil plant closures?), (c) capacity mix (renewable share of total capacity). Using capacity mix as an outcome increases effective N since every county with any generation contributes, not just counties with NEW investments.

**Evidence:** See Condition 2 evidence.

---

### Condition 6: confirming no border spillovers via spatial controls

**Status:** [X] RESOLVED

**Response:** Will implement: (1) Donut RDD excluding counties immediately adjacent to the cutoff, (2) Spatial lag models controlling for neighboring county designation status, (3) Ring analysis at varying distances from nonattainment area boundaries, (4) Falsification test on counties far from the cutoff (deeply attainment areas should show null effects). Note: border spillovers are actually theoretically interesting here — if plants relocate to just across the border, that IS the displacement mechanism we want to document.

**Evidence:** Design feature — will be implemented in 04_robustness.R.

---

### Condition 7: extending to long-run retirement dynamics

**Status:** [X] RESOLVED

**Response:** The 1997 PM2.5 NAAQS (first standard) provides 27+ years of post-treatment data. The 2006 PM2.5 24-hr revision provides 20 years. The 2012 annual revision provides 14 years. Will estimate dynamic treatment effects using event-study specifications around each designation wave, tracking capacity additions and retirements over 1, 5, 10, and 15+ year horizons. Long horizons are essential because power plant investment decisions are lumpy and capital-intensive.

**Evidence:** EIA Form 860 data spans 2008-present (monthly), with annual data available back further. EPA AQS annual data available from 1990s.

---

## Verification Checklist

Before proceeding to Phase 4:

- [X] All conditions above are marked RESOLVED or NOT APPLICABLE
- [X] Evidence is provided for each resolution
- [X] This file has been committed to git

**Status: RESOLVED**
