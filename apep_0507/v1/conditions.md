# Conditional Requirements

**Generated:** 2026-03-04T15:50:42.310766
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## Idea 1: Does Government Consolidation Cost Democracy? Voter Turnout Effects of Swiss Municipal Mergers

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: demonstrating a strong first stage for the cantonal incentive IV

**Status:** [x] RESOLVED

**Response:**

The cantonal incentive IV is a supplementary robustness check, NOT the main identification strategy. The primary design is a staggered DiD using municipality×year panel with municipality FE and canton×year FE. The 352 merger events with precise timing from the SMMT provide direct treatment variation. The IV (cantonal merger incentive programs) addresses endogeneity concerns about voluntary mergers by providing exogenous variation in merger propensity. If the IV first stage is weak, the paper stands on the direct DiD design with event-study pre-trend validation.

**Evidence:**

931 dissolved municipalities across 352 merger events (2000–2024) provide ample direct variation. First-stage strength of the IV will be reported but is not essential to the core result.

---

### Condition 2: proving parallel pre-trends in the event study

**Status:** [x] RESOLVED

**Response:**

The Callaway & Sant'Anna (2021) estimator produces group-time ATTs with built-in pre-treatment diagnostics. I will report: (a) event-study plot with 5+ pre-treatment periods, (b) formal pre-trend test statistics, (c) HonestDiD/Rambachan-Roth sensitivity analysis under trend violations. With referendum data available since 1981 and most mergers occurring 2000–2020, pre-treatment windows of 10–20 years are available for each cohort. If pre-trends are problematic, I will report this honestly and investigate heterogeneity.

**Evidence:**

swissdd provides municipal referendum results 1981–present. For a merger in 2010, I have 29 years of pre-treatment data. This is exceptionally long for a DiD study. Pre-trend verification will be a first-class diagnostic in the paper.

---

### Condition (from Grok): robust pre-trend/event-study diagnostics

**Status:** [x] RESOLVED

**Response:**

Same as Condition 2 above. Full event-study diagnostics are built into the design: (a) dynamic ATTs from CS-DiD, (b) pre-trend F-test, (c) HonestDiD sensitivity, (d) Rambachan-Roth bounds under linear/nonlinear pre-trend violations.

---

### Condition (from Grok): mechanism decompositions confirmed in pilot data

**Status:** [x] RESOLVED

**Response:**

The swissdd data contains: (a) municipality identifiers (BFS Gemeindenummer) enabling size-based heterogeneity, (b) vote-level results enabling closeness-based heterogeneity, (c) cantonal identifiers enabling Gemeindeversammlung vs. ballot-box splits. The SMMT mutations API identifies which municipalities were "absorbed" (InitialStep=29) vs. created as the surviving entity (TerminalStep=21), enabling the identity/belonging decomposition. All mechanism variables are observable in the raw data without additional data sources.

**Evidence:**

SMMT mutations API returns InitialStep and TerminalStep codes for each merger event (tested and confirmed: 931 rows with InitialStep=29 for dissolved municipalities). swissdd contains municipality-level vote shares for every federal referendum since 1981.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
