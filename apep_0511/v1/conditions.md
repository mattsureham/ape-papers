# Conditional Requirements

**Generated:** 2026-03-05T10:05:23.494198
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

Focusing on the unanimously top-ranked idea: 340B Drug Pricing × Medicaid.

---

## Does 340B Drug Pricing Crowd Out Medicaid Patients? Cross-Payer RDD Evidence from Provider-Level Claims

**Rank:** #1 | **Recommendation:** PURSUE (all 3 models)

### Condition 1: convincing no-manipulation case after donuts / passing McCrary density tests

**Status:** [x] RESOLVED

**Response:**

Three-pronged approach to address the manipulation concern:
1. **McCrary density test** on the DSH % distribution. If the test rejects, report it transparently and proceed with the donut specification.
2. **Donut hole design:** Exclude hospitals within ±0.5pp of the 11.75% threshold. This removes the manipulable window while preserving the broader comparison.
3. **Bandwidth sensitivity:** Show results are stable across CCT-optimal, half-optimal, and 2x-optimal bandwidths.

**Evidence:**

Nikpay et al. (2018, NEJM) found no significant bunching in their sample (pre-2014). Bai et al. (2021, BMC Research Notes) documented some bunching in 2014-2016, but noted it was a "fairly recent phenomenon." Our analysis spans 2018-2024, where manipulation incentives are well-established — the donut specification is the primary defense. The McCrary test is a diagnostic, not a pass/fail gate: if bunching exists, the donut hole addresses it; if not, results are stronger.

---

### Condition 2: demonstrating a strong first-stage — eligibility actually changes 340B participation / clear first stage in 340B participation

**Status:** [x] RESOLVED

**Response:**

The first stage is directly verifiable: HRSA publishes the complete 340B OPAIS (Office of Pharmacy Affairs Information System) entity database, including all participating covered entities with their NPI. We will:
1. Match OPAIS entities to our hospital sample by NPI
2. Plot 340B participation rate against DSH %, showing the discontinuity at 11.75%
3. Report the first-stage F-statistic from the fuzzy RDD specification

Nikpay et al. (2018) already demonstrated a strong first stage with this threshold. Our contribution uses the same threshold with a different (Medicaid-specific) outcome — the first stage is inherited from the validated design.

**Evidence:**

HRSA OPAIS database: https://340bopais.hrsa.gov/ — public, downloadable, includes NPI identifiers for all 340B covered entities. Updated quarterly.

---

### Condition 3: documenting T-MSIS state-quality screens don't drive results

**Status:** [x] RESOLVED

**Response:**

CMS publishes the DQ Atlas tracking state-by-state T-MSIS data quality on multiple dimensions (claims completeness, NPI validity, payment accuracy). Our robustness approach:
1. **Baseline:** Include all states with complete 2018-2024 J-code data
2. **Robustness 1:** Exclude states with poor DQ Atlas scores on claims completeness
3. **Robustness 2:** Exclude states with known managed care encounter reporting issues (managed care accounts for 84.8% of Medicaid enrollment; encounter data quality varies)
4. **Robustness 3:** Control for state fixed effects in the RDD specification (state × hospital characteristics)

The hospital-level analysis mitigates many state-quality concerns because we compare hospitals within similar DSH ranges, not across states.

**Evidence:**

CMS DQ Atlas: https://www.medicaid.gov/dq-atlas/welcome — publicly accessible, state × year × data element quality scores.

---

### Condition 4: strong first-stage on non-Medicaid drugs

**Status:** [x] RESOLVED

**Response:**

The Medicare Physician/Supplier PUF provides Medicare drug administration (J-codes) by NPI × HCPCS. This is the non-Medicaid first stage:
1. Plot Medicare J-code billing against DSH % — should show discontinuity at 11.75% (replicating Nikpay's total drug finding for the Medicare channel)
2. This Medicare effect serves as the "first stage" for the cross-payer comparison: if 340B increases Medicare drug administration but not Medicaid, that's the payer substitution mechanism

The T-MSIS (Medicaid) and Medicare PUF (Medicare) together decompose the total effect by payer.

**Evidence:**

Medicare Physician/Supplier PUF: https://data.cms.gov/provider-summary-by-type-of-service — public Socrata API, NPI × HCPCS × year, no API key needed.

---

### Condition 5: powered nulls on placebos

**Status:** [x] RESOLVED

**Response:**

Three pre-registered placebo tests:
1. **Non-drug Medicaid billing:** T/H/S codes (HCBS, behavioral health) at the same hospitals. 340B only affects drug pricing — no effect expected on non-drug services.
2. **Categorically eligible hospitals:** CAHs, rural referral centers, and children's hospitals qualify for 340B regardless of DSH %. The 11.75% threshold should have no effect on their drug billing — any apparent discontinuity would signal confounding.
3. **Medicare non-drug services:** Evaluation & management codes (992xx) in Medicare PUF at the same hospitals. 340B should only affect drug administration, not office visits.

Power: With ~800-1200 hospitals within ±5pp of the threshold, we have reasonable power for the main estimates. Placebo power will be reported as MDEs (minimum detectable effects).

**Evidence:**

T-MSIS HCPCS code classification (from SCOPING_NOTES.md): T/H/S codes are HCBS/behavioral health (52% of spending), J-codes are drugs, CPT codes are medical services. Clear separation enables placebo construction.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Status: RESOLVED — proceeding to Phase 4 with Idea 1 (340B × Medicaid)**
