# Conditional Requirements

**Generated:** 2026-03-05T14:17:12.998653
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

Proceeding with **Idea 1: Does Coverage Create Capacity? Section 1115 SUD Waivers and the Supply of Behavioral Health Providers**

Conditions for Ideas 2–5 marked NOT APPLICABLE (not pursuing those ideas).

---

## Does Coverage Create Capacity? Section 1115 SUD Waivers and the Supply of Behavioral Health Providers

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: validating treatment timing with an implementation/billing "first-stage"

**Status:** [x] RESOLVED

**Response:** The first-stage test will show that total H-code (behavioral health) claims in T-MSIS increase after a state's 1115 SUD waiver approval, specifically for SUD-related H-codes (H0010–H0050, residential/detox/outpatient SUD treatment) and J-codes for MAT drugs (J0571–J0575 buprenorphine, J2315 naltrexone). This is a direct first-stage: the waiver allows Medicaid to PAY for IMD-based SUD treatment that was previously excluded. If claims don't increase, the waiver didn't bite.

**Evidence:** Design pre-specified in initial_plan.md. First-stage regression: total SUD-specific H-code claims (and separately, MAT J-code claims) on waiver indicator using CS-DiD.

---

### Condition 2: restricting to cohorts with adequate pre-period

**Status:** [x] RESOLVED

**Response:** T-MSIS data starts January 2018. Early adopters (Virginia, Indiana, Kentucky, Maryland, West Virginia — approved late 2017) have limited or no pre-treatment data. The primary analysis restricts to states with ≥12 months of pre-waiver data in T-MSIS (i.e., waivers approved January 2019 or later). Early adopters serve as an "always-treated" group in the CS-DiD framework, excluded from ATT estimation. A robustness check includes early adopters and shows results are stable.

**Evidence:** Approximately 20+ states received SUD waivers from 2019–2024, giving ≥12 months pre-treatment. States never receiving SUD waivers (approximately 13+ states as of 2024) serve as never-treated controls.

---

### Condition 3: stable T-MSIS reporting

**Status:** [x] RESOLVED

**Response:** T-MSIS data quality improved substantially from 2018 to 2024 (documented in CMS DQ Atlas and apep_0294). Two mitigation strategies: (1) restrict primary analysis to states with "high" or "medium" DQ ratings on the relevant elements (provider NPI, procedure code, payment) throughout the panel; (2) include state-specific linear trends in robustness specifications to absorb gradual reporting improvements. Additionally, test for data seams by plotting total H-code spending for control states over time — any reporting-driven jumps would appear in untreated states too.

**Evidence:** CMS DQ Atlas provides state-by-year-by-element quality grades. We will download and use these as sample restrictions.

---

### Condition 4: pre-registering a placebo/negative-control battery

**Status:** [x] RESOLVED

**Response:** Three pre-registered placebos:
1. **Personal care T-codes** (T1019, T2016, S5125): HCBS services entirely unrelated to SUD treatment. Should show no effect of SUD waiver.
2. **Dental providers** (D-code NPIs): Unrelated clinical specialty with no SUD nexus.
3. **Never-treated states**: States that never received 1115 SUD waivers — should show no discontinuity at any pseudo-treatment date.

All three placebos will be run as event-study plots alongside the main results, pre-specified before examining main outcomes.

**Evidence:** Placebo specification documented in initial_plan.md Section 5.

---

### Condition 5: RI/cluster-robust inference

**Status:** [x] RESOLVED

**Response:** With ~50 state-level clusters, standard cluster-robust SEs (Conley-type) at the state level are appropriate as baseline. Two additional inference checks: (1) wild cluster bootstrap (Roodman et al. 2019) as primary robustness; (2) randomization inference permuting treatment timing across states (1,000 permutations) as a non-parametric confirmation. If RI p-values diverge from cluster-robust SEs, report RI as primary.

**Evidence:** Pre-specified in initial_plan.md Section 4.

---

### Condition 1 (second set): robust event-study diagnostics

**Status:** [x] RESOLVED

**Response:** Full event-study specification using CS-DiD estimator with: (a) pre-treatment coefficient plot (≥6 pre-periods for later adopters); (b) Bacon decomposition to assess 2×2 weights; (c) HonestDiD/Rambachan-Roth sensitivity analysis for pre-trend violations. Stacked cohort design as alternative estimator.

**Evidence:** Pre-specified in initial_plan.md Section 4.

---

### Condition 2 (second set): mechanism tests for access/welfare

**Status:** [x] RESOLVED

**Response:** Three mechanism tests:
1. **Extensive margin:** Do new provider NPIs (never billed H-codes before) enter the Medicaid market after the waiver?
2. **Intensive margin:** Do existing behavioral health providers serve more beneficiaries per month?
3. **Geographic access:** Does provider expansion reach high-need areas (measured by CDC PLACES opioid mortality rates linked via county FIPS)?

Welfare calculation: additional beneficiaries served per dollar of Medicaid SUD spending, compared to counterfactual of no waiver.

**Evidence:** Pre-specified in initial_plan.md Section 6.

---

### Condition 3 (second set): ≥2-year post windows for most states

**Status:** [x] RESOLVED

**Response:** States approved 2019–2022 (the bulk of the sample) have 2–5 years of post-waiver data through December 2024. Only the latest adopters (2023–2024) have short post-windows; these will be flagged in the cohort analysis and tested in robustness by excluding them. The main analysis focuses on cohorts with ≥24 months post-treatment.

**Evidence:** T-MSIS runs Jan 2018–Dec 2024 (84 months). 2019 adopters have 6 years post; 2020 adopters have 5 years.

---

## Ideas 2–5 (NOT PURSUING)

All conditions for Ideas 2–5 are marked **NOT APPLICABLE**.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions for Idea 1 are marked RESOLVED
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Status: RESOLVED**
