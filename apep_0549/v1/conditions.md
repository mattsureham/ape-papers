# Conditional Requirements

**Generated:** 2026-03-09T09:38:51.967529
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## Online Sports Betting and Alcohol-Involved Fatal Traffic Crashes

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: getting post-2022 crash data or narrowing claims to early adopters

**Status:** [X] RESOLVED

**Response:**
FARS 2023 data is confirmed available on data.gov (catalog.data.gov/dataset/fatality-analysis-reporting-system-fars-2023-accidents). This extends coverage to December 2023, providing 5+ years of post-PASPA data and meaningful post-periods for early adopters (NJ 2018, PA/IN 2019, CO/IL 2020, MI 2021). For later adopters (NY 2022, OH/MA 2023), the 2023 data provides at least 1 year post. The sample is strongest for the 2018-2021 cohorts. Additionally, FARS has a preliminary "early" release — 2024 preliminary data may be available from NHTSA's CRSS/GES system for aggregate validation.

**Evidence:**
- data.gov catalog confirms FARS 2023 dataset: https://catalog.data.gov/dataset/fatality-analysis-reporting-system-fars-2023-accidents
- NHTSA file downloads page confirms 2023 availability: https://www.nhtsa.gov/file-downloads

---

### Condition 2: making the game-day design central rather than auxiliary

**Status:** [X] RESOLVED

**Response:**
The paper will be structured with the high-frequency NFL game-day triple-difference as the PRIMARY identification strategy, not a mechanism test. The architecture will be:
- **Main design (Section 4):** State × day-of-week × NFL-season panel. Treatment = legal online sports betting × NFL game day × post-legalization. This triple-diff absorbs: (a) state-level trends from any source (state × year FE), (b) day-of-week patterns (day FE), (c) NFL seasonality (NFL Sunday FE). The identifying variation is: do alcohol-involved crashes on NFL Sundays increase MORE in states after they legalize online betting?
- **Supporting design (Section 5):** Standard state-year staggered DiD (CS 2021) for annual effects.
- **Mechanism tests (Section 6):** Nighttime vs daytime, non-alcohol crash placebo, NFL-market county proximity.

This follows the judge feedback: "put the strongest design in the main text."

**Evidence:**
Tournament feedback: "The strongest designs had an internal counterfactual built into the institution." NFL game days provide exactly this — a within-state, within-year temporal counterfactual.

---

### Condition 3: aggressively addressing COVID/reopening confounds

**Status:** [X] RESOLVED

**Response:**
COVID confounding will be addressed through four strategies:
1. **Exclusion:** Primary specifications exclude March 2020 - December 2020 (COVID lockdown period). Robustness includes full sample.
2. **Triple-diff absorption:** The NFL game-day DDD differences out any state-level COVID trends because COVID affects ALL days of the week within a state — the identifying variation is the differential NFL Sunday effect, which COVID should not affect differentially.
3. **Non-alcohol placebo:** Non-alcohol-involved fatal crashes serve as a within-state-year placebo. If COVID/reopening drives results, we'd see effects on ALL crashes, not just alcohol-involved ones.
4. **Mobility controls:** Google Mobility Reports (county-level, daily, through 2022) can be included as time-varying controls for driving volume changes.
5. **Pre-2020 early adopters:** NJ (June 2018) provides 18 months of pre-COVID post-treatment data for a clean sub-sample analysis.

**Evidence:**
Non-alcohol fatal crashes as placebo is standard in the alcohol/driving literature (e.g., Dee 1999 JHE, Carpenter & Dobkin 2011 AER). If betting → alcohol → crashes, non-alcohol crashes should show null.

---

### Condition 4: testing pre-trends at high frequency

**Status:** [X] RESOLVED

**Response:**
Pre-trends will be tested at monthly and weekly frequency using FARS event-study specifications:
1. **Monthly event study:** State × month panel with leads and lags around legalization date. Standard CS event-study plot with joint test of pre-treatment coefficients = 0.
2. **Weekly NFL Sunday event study:** Within NFL seasons, test whether treated-state NFL Sundays show differential trends BEFORE legalization.
3. **Formal tests:** Joint F-test on all pre-treatment coefficients; Rambachan-Roth (HonestDiD) sensitivity bounds under partial violations.
4. **Goodman-Bacon decomposition:** For the annual specification, to identify which 2×2 comparisons drive the aggregate estimate.

**Evidence:**
FARS records exact crash date (month, day, year) and hour — enabling daily-level panel construction. This is a key advantage over survey data.

---

## Verification Checklist

Before proceeding to Phase 4:

- [X] All conditions above are marked RESOLVED or NOT APPLICABLE
- [X] Evidence is provided for each resolution
- [X] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
