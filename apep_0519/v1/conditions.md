# Conditional Requirements

**Generated:** 2026-03-05T12:04:24.296022
**Status:** RESOLVED

---

## Mandating the Green Transition: Cantonal Building Energy Codes and Heat Pump Adoption in Switzerland

**Rank:** #1 | **Recommendation:** PURSUE (all 3 models)

### Condition 1: Passing pre-trend/event-study diagnostics

**Status:** [x] RESOLVED

**Response:** Event-study plots with leads/lags will be the core identification diagnostic. Pre-treatment data from 2012-2016 (5 years before first adopter) provides sufficient baseline. CS-DiD estimator inherently produces group-time ATTs that visualize pre-trends. Will implement Rambachan & Roth (2023) HonestDiD sensitivity analysis for pre-trend robustness.

**Evidence:** GWR heating data available from 2012+. First MuKEn 2014 adoption ~2017. Design: 5+ pre-treatment years per cohort. Will report event-study in main specification.

---

### Condition 2: Credible strategy for endogenous module selection

**Status:** [x] RESOLVED

**Response:** Three-pronged approach: (a) Primary specification uses binary "any MuKEn 2014 module adopted" to avoid selection on module content. (b) Robustness: analyze individual modules (heating replacement, solar, envelope) separately with CS-DiD. (c) Dose-response: count of modules adopted as continuous treatment intensity. The key insight: cantons didn't cherry-pick modules based on their heat pump stock — they adopted based on political feasibility and parliamentary composition. Will test for pre-trend differences across module combinations.

**Evidence:** ENDK adoption tracker shows module-level adoption. Political composition of cantonal parliaments (available from BFS) can be used as a covariate to control for selection.

---

### Condition 3: Border design

**Status:** [x] RESOLVED

**Response:** Spatial RDD at cantonal borders as robustness check. Municipalities within 10-20km of a cantonal border where one canton adopted MuKEn 2014 and the neighboring canton didn't. SMMT provides municipal boundaries; BFS Gemeindenummer allows spatial matching. This supplements the staggered DiD with a sharp geographic discontinuity. Donut specification (excluding border municipalities themselves) as additional robustness.

**Evidence:** Swiss municipal boundaries are well-documented in SMMT. Multiple canton-pair contrasts available (e.g., adopted vs. non-adopted neighbors).

---

### Condition 4: IV/political instruments

**Status:** [x] RESOLVED

**Response:** In cantons where MuKEn 2014 was put to popular vote (e.g., Solothurn rejected in 2018 referendum), the referendum outcome provides a political instrument. Additionally, cantonal parliamentary composition (share of Green/left seats) predicts adoption timing and can serve as an instrument for adoption. Will report both OLS and IV specifications.

**Evidence:** Swissvotes/cantonal referendum data available. BFS has cantonal parliamentary composition data.

---

### Condition 5: Tight within-canton intensity contrasts

**Status:** [x] RESOLVED

**Response:** Within adopting cantons, exploit heterogeneous exposure: (a) municipalities with older building stock (more oil/gas heating) face higher marginal treatment intensity than municipalities with newer building stock (already heat pump); (b) municipalities with more new construction (growing populations) vs. stable populations; (c) urban vs. rural (different renovation rates). These within-canton contrasts provide a DDD specification: adopted canton × high-exposure municipality × post-adoption.

**Evidence:** GWR data provides pre-treatment building stock composition by municipality. BFS has population growth data.

---

### Condition 6: Careful accounting for concurrent subsidies

**Status:** [x] RESOLVED

**Response:** Switzerland's Gebäudeprogramm (federal building program) provides subsidies for energy renovations. These subsidies are NATIONAL and do not vary by canton — they affect treated and control cantons equally, so they don't confound the DiD. Cantonal subsidy programs (e.g., Kanton Bern's Gebäudesanierung subsidies) DO vary and could confound. Will: (a) document cantonal subsidy programs and their timing; (b) include cantonal subsidy generosity as a time-varying covariate; (c) test robustness to excluding cantons with concurrent large subsidy changes; (d) decompose the "mandate vs. subsidy" channel explicitly.

**Evidence:** Federal Gebäudeprogramm data available from BFE. Cantonal subsidy programs documented on energiefranken.ch.

---

### Condition 7: Energy-price shocks

**Status:** [x] RESOLVED

**Response:** The 2022 energy crisis (Ukraine war) dramatically increased fossil fuel prices, creating a nationwide incentive for heat pump adoption. This is a threat to DiD identification if it coincided with canton-specific adoption timing. Mitigation: (a) include year fixed effects to absorb nationwide energy price shocks; (b) interact canton adoption with pre-treatment fossil dependence to test whether the energy crisis differentially affected treated vs. control cantons; (c) restrict sample to pre-2022 adoptions as robustness check (removes energy crisis from post-treatment window); (d) use energy price index as explicit control variable.

**Evidence:** Swiss energy price indices from BFE/BFS. Year fixed effects standard in CS-DiD.

---

### Condition 8: Robust event-study diagnostics confirming no pre-trends/anticipation (Grok)

**Status:** [x] RESOLVED

**Response:** Same as Condition 1. Additionally: test for anticipation effects by including leads (-3, -2, -1 years before adoption). If anticipation detected, use Sun & Abraham (2021) estimator that explicitly allows for anticipation. The MuKEn parliamentary process is public — announcement dates can be distinguished from implementation dates.

**Evidence:** Parliamentary debate dates available from cantonal legislative records.

---

### Condition 9: Decompose at least two mechanisms for narrative arc (Grok)

**Status:** [x] RESOLVED

**Response:** Four mechanism decompositions planned: (1) New construction vs. renovation (does the code bite through mandated standards for new buildings, voluntary renovation, or both?); (2) Heat pump adoption vs. fossil phase-out (substitution decomposition); (3) Module-specific effects (heating replacement module most directly targets fossil phase-out); (4) Building size heterogeneity (compliance burden differs for single-family vs. multi-family). The narrative arc: First-stage (does the code bind?) → Technology substitution → Heterogeneity → Welfare (carbon abatement cost).

**Evidence:** All decompositions feasible with GWR data (building type, heating source, construction year, municipality).

---

## Verification Checklist

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Status: RESOLVED — Proceed to Phase 4**
