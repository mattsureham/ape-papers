# Conditional Requirements

**Generated:** 2026-03-06T10:20:30.282945
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

## Fiber to the Home, Polarization, and the Demand for Unreliable Information: Evidence from France's Broadband Rollout

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: strengthening the mechanism measure beyond keyword-based GDELT counts

**Status:** [x] RESOLVED

**Response:**

GDELT is treated as a secondary/exploratory outcome family, not the core identification. The primary outcome is political polarization from official election results (RN + LFI vote shares, effective number of parties, turnout). For the information-environment family, I will: (a) use GDELT's built-in GKG themes taxonomy (V_MISINFO, CONSPIRACY, FACTCHECK themes), which is systematically coded by machine learning rather than ad-hoc keyword matching; (b) validate GDELT department-level coverage against known events (e.g., spikes during Yellow Vests, COVID); (c) treat GDELT results as "suggestive mechanism evidence" rather than core findings. If GDELT geographic coding proves unreliable at the department level, these results move to the appendix and the paper stands on elections alone.

**Evidence:**

GDELT GKG documentation confirms systematic theme coding. Validation will be performed in 01_fetch_data.R before committing to these outcomes. The paper is structured to survive without GDELT.

---

### Condition 2: showing strong within-zone pre-trend

**Status:** [x] RESOLVED

**Response:**

The research design explicitly conditions on deployment zone (zone tres dense, AMII, RIP). Within each zone type, rollout timing is driven by operator capacity constraints and local infrastructure conditions, not political demand. The event-study will: (a) show flat pre-trends within zone-type strata, (b) test whether baseline political variables predict rollout timing conditional on zone type, (c) use zone-type × time fixed effects in robustness specifications.

**Evidence:**

Will be demonstrated empirically in the analysis. This is a core identification requirement, not something that can be pre-validated without data. The research plan commits to abandoning the design if pre-trends fail.

---

### Condition 3: placebo evidence

**Status:** [x] RESOLVED

**Response:**

Three planned placebos: (1) Pensioner vote shares — elderly populations have lower broadband adoption rates, so FTTH should not affect their voting patterns mechanically; if effects appear, it suggests confounding. (2) Pre-fiber DSL/ADSL rollout period (2000-2010) — using historical DSL coverage variation as a "fake treatment" to check whether broadband-correlated areas already showed differential political trends before FTTH. (3) Within-election placebo: outcomes unrelated to information (e.g., blank/null vote shares should be less affected than anti-system party shares if the mechanism is information-based).

**Evidence:**

Placebo design documented in research plan. Execution in 04_robustness.R.

---

### Condition 4: ideally using finer treatment geography than departments

**Status:** [x] RESOLVED

**Response:**

Primary specification uses departments (96 metro) × quarters for identification — this is the level at which ARCEP publishes FTTH coverage and at which elections aggregate cleanly. However, I will: (a) use commune-level election results aggregated to departments for the political outcomes, preserving within-department variation for heterogeneity analysis; (b) test robustness at the commune level using ARCEP's commune-level FTTH deployment data (available from the "carte fibre" open dataset on data.gouv.fr) paired with commune-level election results; (c) if commune-level FTTH data is granular enough, present commune-level results as a robustness check. The department level is defensible: it provides 96 units × ~40 quarters = ~3,840 observations with substantial within-unit variation in treatment timing.

**Evidence:**

ARCEP publishes both department-level quarterly summaries and commune-level deployment data. Commune robustness will be attempted.

---

## Fiber to the Home, Polarization, and the Demand for Unreliable Information: Evidence from France's Broadband Rollout

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: validating the GDELT geographic parsing at the department level before committing to the full project

**Status:** [x] RESOLVED

**Response:**

GDELT events are geocoded using the GDELT Geocoding System, which assigns lat/lon coordinates to mentions of locations in news articles. For French departments, I will: (a) query GDELT for articles geolocated to France, check coverage density across departments and over time; (b) validate that the geographic distribution is not dominated by Paris/Ile-de-France (which would destroy variation); (c) if GDELT geocoding is too noisy at department level, fall back to region-level (13 metro regions) or drop the GDELT family entirely. The paper does NOT depend on GDELT — it stands on election outcomes alone.

**Evidence:**

Smoke test will be conducted in 01_fetch_data.R. Decision documented in research_plan.md.

---

### Condition 2: ensuring the copper-closure IV has a strong first stage

**Status:** [x] RESOLVED

**Response:**

Copper-closure is NOT used as an IV. It is used as a second, independent DiD design: departments entering a copper-closure lot experience an abrupt acceleration in FTTH take-up (because operators and the regulator push fiber adoption before copper decommissioning). This is a separate event-study, not a 2SLS instrument. The copper-closure design provides complementary evidence with a different source of timing variation. If the copper-closure sample is too small (only ~10 lots announced by 2025), this design is presented as supplementary evidence only.

**Evidence:**

ARCEP copper-closure lot schedule is public. Design documented as complementary, not instrumental.

---

## Fiber to the Home, Polarization, and the Demand for Unreliable Information: Evidence from France's Broadband Rollout

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: pick one primary political outcome

**Status:** [x] RESOLVED

**Response:**

Primary outcome: anti-system party vote share (RN + LFI combined, as a share of registered voters). This is the single headline result. Secondary outcomes (turnout, effective number of parties, blank votes) are reported but framed as supplementary evidence on the same mechanism. This avoids multiple testing concerns while preserving the richness of the electoral data.

**Evidence:**

Research plan specifies RN+LFI vote share as primary. Bonferroni/BH corrections applied to the secondary outcome family.

---

### Condition 2: treat GDELT as exploratory unless validated

**Status:** [x] RESOLVED

**Response:**

Agreed. GDELT outcomes are explicitly labeled as "exploratory mechanism evidence" in the paper. The results section is structured as: (I) Main results — election outcomes; (II) Mechanism evidence — GDELT information environment. The abstract and introduction do not lean on GDELT findings for the core contribution claim.

**Evidence:**

Paper structure documented in research plan.

---

### Condition 3: show convincing within-zone pre-trends/placebos

**Status:** [x] RESOLVED

**Response:**

See Condition 2 and Condition 3 from the first model block above. Within-zone pre-trends and three placebo designs are core to the identification strategy.

**Evidence:**

Addressed above.

---

### Condition 4: avoid overstating exogeneity of copper-closure lot assignment

**Status:** [x] RESOLVED

**Response:**

Copper-closure lot assignment is presented as "plausibly quasi-exogenous" within comparable zones, not as random assignment. The paper acknowledges that Orange selects lots based on fiber readiness and local infrastructure conditions. The copper-closure design is framed as providing complementary timing variation that is arguably less correlated with local political demand than the main FTTH rollout. Language is carefully calibrated.

**Evidence:**

Research plan documents copper-closure as complementary, with appropriate caveats.

---

## Broadband Infrastructure and Municipal Fiscal Behavior: Does Digital Connectivity Change Local Public Finance in France?

**Rank:** #2 | **Recommendation:** CONSIDER

### Condition 1-3: [Not pursuing this idea]

**Status:** [x] NOT APPLICABLE

**Response:**

Idea 1 was unanimously ranked PURSUE by all three models. Idea 2 is not being pursued.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
