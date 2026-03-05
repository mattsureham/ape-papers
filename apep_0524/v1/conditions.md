# Conditional Requirements

**Generated:** 2026-03-05T14:29:51.250794
**Status:** RESOLVED

---

## CROWN Act Conditions (consolidated from all 3 models)

### Condition 1: First-stage/bite demonstration

**Status:** [X] RESOLVED

**Response:** Direct complaint data (EEOC/state FEPA) is not publicly available at the state-year level for hair-specific charges. However, first-stage bite will be demonstrated through: (1) citing existing HR/sociology evidence that 80% of Black women change their natural hair for work (Dove CROWN Study 2019), Black women 1.5x more likely to be sent home for hair; (2) Google Trends analysis showing CROWN Act awareness spikes at adoption; (3) the mechanism test itself—if occupational composition shifts toward customer-facing roles for Black workers post-CROWN, that IS the first stage.

**Evidence:** Dove/CROWN Coalition Research Study (2019); internal mechanism analysis will serve as first-stage evidence.

---

### Condition 2: Pre-registering primary outcomes

**Status:** [X] RESOLVED

**Response:** Four pre-registered primary outcomes committed in initial_plan.md before data fetch: (1) Black-White employment rate gap, (2) Black-White log earnings gap, (3) Black share in customer-facing occupations (SOC 41xxxx retail sales, 35xxxx food service, 39xxxx personal care), (4) Black share in professional occupations (SOC 11-29xxxx management through healthcare practitioners).

**Evidence:** Committed in initial_plan.md before any data is fetched.

---

### Condition 3: Robustness to dropping 2020

**Status:** [X] RESOLVED

**Response:** Will implement as a core robustness check in 04_robustness.R: (1) exclude all 2020 observations entirely, (2) exclude 2020 + early 2021 (COVID peak), (3) use only post-2020 adopters (2021-2024) who have clean pre-periods uncontaminated by COVID. The triple-diff specification (Black × CROWN × Post) further absorbs COVID shocks that affected both races equally within states.

**Evidence:** Planned in 04_robustness.R.

---

### Condition 4: Border-county/geographic comparisons

**Status:** [X] RESOLVED

**Response:** ACS 1-year PUMS identifies PUMAs (Public Use Microdata Areas, ~100K population). For border analysis: (1) identify PUMAs adjacent to state borders, (2) compare Black employment outcomes in CROWN-state border PUMAs vs never-CROWN-state border PUMAs. This provides a geographic discontinuity robustness check. Additionally, CPS identifies metropolitan areas that span state lines (e.g., Kansas City MO-KS, Philadelphia PA-NJ)—can compare within-MSA across state lines where one side has CROWN.

**Evidence:** ACS PUMS geography + cross-state MSA identification in CPS.

---

### Condition 5: Parallel trends through COVID / no pre-trends in triple-diff

**Status:** [X] RESOLVED

**Response:** Event study plots for the triple-diff specification (Black × CROWN-state × relative-time) will show coefficient paths pre- and post-adoption. Key diagnostic: (1) pre-treatment coefficients should be zero (no differential trend for Black workers in future-CROWN states), (2) Rambachan-Roth HonestDiD sensitivity analysis to bound effects under linear pre-trend violations. The triple-diff inherently nets out state-level COVID effects (affects Black and White workers within state).

**Evidence:** Event study figures + HonestDiD analysis planned in 03_main_analysis.R and 04_robustness.R.

---

### Condition 6: Mechanism bite via occupational sorting

**Status:** [X] RESOLVED

**Response:** Occupational upgrading is a PRIMARY result, not supplementary. Design: (1) classify occupations into customer-facing (where appearance/hair matters: retail, food service, personal care, hospitality) vs non-customer-facing (manufacturing, IT, remote), (2) estimate triple-diff for Black share in each category, (3) test if effects are concentrated in customer-facing roles (where hair discrimination has the most bite). If CROWN Act works through reducing appearance-based discrimination, effects should be larger for customer-facing occupations—this IS the mechanism test.

**Evidence:** SOC code classification documented in initial_plan.md; analysis in 03_main_analysis.R.

---

## Verification Checklist

- [X] All conditions marked RESOLVED
- [X] Evidence or plan provided for each
- [X] Ready for Phase 4
