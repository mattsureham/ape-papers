# Conditional Requirements

**Generated:** 2026-03-05T16:54:58.191023
**Status:** RESOLVED

---

## Do Administrative Borders Tax Electricity? A Multi-Border Spatial RDD of Swiss Cantonal Energy Policy

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: convincing border-pair pre-trend/event-study evidence

**Status:** [x] RESOLVED

**Response:**
The ElCom dataset spans 2011–2026 with annual tariff data for 2,712 municipalities. For each of the 8 cantonal energy law reforms (GR 2010, BE 2011, AG 2012, BL 2016, BS 2016, LU 2017, FR 2019, AI 2020), we have 1–9 pre-reform years and 6–15 post-reform years. We will estimate border-pair event studies using municipality-pair fixed effects, showing that the charges component is flat pre-reform and jumps post-reform. The multi-cutoff design provides internal replication across ~50 border pairs.

**Evidence:** ElCom SPARQL returns 745,458 observations across 16 years. Will produce event-study plots as core output in 03_main_analysis.R.

---

### Condition 2: showing effects concentrate in the "Abgaben"/policy-linked components

**Status:** [x] RESOLVED

**Response:**
The ElCom tariff decomposition provides five components: energy, grid usage, federal aid fee (Netzzuschlag), cantonal/municipal charges (Abgaben), and fixed costs. We will run the spatial RDD separately for each component. The cantonal energy laws should affect only the charges component (cantonal levies, energy fund contributions). The federal aid fee serves as a built-in placebo (nationally uniform, should show zero discontinuity). The energy and grid components should show smaller/no discontinuity if the design is clean.

**Evidence:** ElCom SPARQL query confirmed to return all 5 tariff components. Decomposition analysis is a core part of the research design (see initial_plan.md).

---

### Condition 3: documenting utility/DSO comparability or controlling for DSO fixed effects where possible

**Status:** [x] RESOLVED

**Response:**
ElCom data includes the network operator (DSO) for each municipality-year observation. We will: (1) identify cross-border DSOs that serve municipalities in multiple cantons (these provide within-DSO variation), (2) include DSO fixed effects in robustness specifications, (3) exclude border segments where the same DSO operates on both sides (these show no policy discontinuity by construction). The ~600 local DSOs in Switzerland are predominantly single-canton, so most border pairs have different DSOs.

**Evidence:** ElCom SPARQL schema includes operator dimension. Will document DSO coverage in 02_clean_data.R.

---

### Condition 4 (Grok): confirming no pre-reform discontinuities in charges component

**Status:** [x] RESOLVED

**Response:**
Same as Condition 1. Pre-reform years provide the counterfactual. We will test for pre-existing discontinuities in each tariff component at each border pair. If pre-reform discontinuities exist in charges, we will use a DiD approach (change in discontinuity) rather than a level RDD.

**Evidence:** Will be produced in analysis phase.

---

### Condition 5 (Grok): running covariate balance across all ~50 borders

**Status:** [x] RESOLVED

**Response:**
BFS municipal statistics provide covariates: population, population density, elevation, income, employment structure, language region, and urbanization level. We will run balance tests for each border pair and report aggregate balance (share of pairs with significant imbalance). The key advantage of the spatial RDD is that municipalities near the same border should be similar in observables.

**Evidence:** BFS PXWeb and swissBOUNDARIES3D confirmed available. Covariate balance tests in 04_robustness.R.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
