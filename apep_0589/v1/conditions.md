# Conditional Requirements

**Generated:** 2026-03-10T16:10:04.172412
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

---

## ERDF Treatment Withdrawal and Regional Convergence: Evidence from Regions Graduating Through the 75% Threshold

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: documenting a large discontinuity in actual payments/co-financing after 2014

**Status:** [x] RESOLVED

**Response:**

The first stage will be documented directly using ERDF payment data from cohesiondata.ec.europa.eu, which provides annual ERDF allocations at NUTS-2 level for both 2007-2013 and 2014-2020 programming periods. The design will show:
- ERDF EUR per capita for graduating regions drops sharply (from Objective 1 rates ~85% co-financing to 50-60%)
- Non-graduating regions (still below 75%) maintain high co-financing
- Always-above regions show no discontinuity

The first-stage plot (ERDF intensity vs. distance from 75% threshold) will be Figure 1. If the first stage is weak, the paper will report this transparently and focus on the reduced-form RDD (which is interesting regardless as an intent-to-treat estimate).

**Evidence:**

- cohesiondata.ec.europa.eu API confirmed: 13,166 ERDF records with NUTS-2 codes, fund amounts, and programming period
- Becker et al. (2010) documented a clear first stage in their original design; the graduation shock should produce an even sharper discontinuity since it involves funding *removal* rather than eligibility
- The paper will present the first-stage regression as Table 1 before any outcome analysis

---

### Condition 2: handling transition/phasing-out exceptions cleanly

**Status:** [x] RESOLVED

**Response:**

EU Structural Funds include "transition regions" (75-90% of EU average) that receive intermediate funding. This is a feature, not a bug: it creates a multi-tier discontinuity that we will exploit rather than ignore.

Strategy:
1. **Primary specification:** Sharp RDD comparing regions just below 75% (still "less developed") to regions just above 75% (now "transition" or "more developed")
2. **Bandwidth sensitivity:** Standard Calonico-Cattaneo-Titiunik (CCT) optimal bandwidth selection, plus manual bandwidths from ±5pp to ±20pp
3. **Donut hole:** Exclude regions within ±2pp of threshold to check sensitivity to manipulation
4. **Transition category coding:** Code all regions by their actual category assignment (less developed / transition / more developed) and document the mapping
5. **Fuzzy specification:** Use actual ERDF EUR per capita as the endogenous variable, instrumented by crossing the threshold

The transition category creates a *multi-cutoff* design (75% and 90% thresholds), which provides additional internal replication.

**Evidence:**

- Regulation (EU) No 1303/2013 defines: <75% = "less developed" (85% co-financing), 75-90% = "transition" (60%), >90% = "more developed" (50%)
- This three-tier structure is well-documented and observable in the data
- Multi-cutoff designs are rewarded by tournament judges

---

### Condition 3: keeping spillover analysis secondary unless it is very convincing

**Status:** [x] RESOLVED

**Response:**

Agreed. The paper's primary contribution is the treatment-withdrawal RDD. The spillover analysis will be demoted to a secondary mechanism test or appendix section, not a co-equal contribution. Structure:

1. **Main text:** Treatment withdrawal RDD → GDP, employment, wages (Sections 4-5)
2. **Mechanism section:** Sectoral reallocation test — did graduating regions shift GVA composition? (Section 6)
3. **Appendix:** Cross-border spillover exploration (distance-weighted ERDF exposure), clearly labeled as suggestive

If spillover results are strong, they can be promoted. If weak, they stay in the appendix without weakening the core paper.

**Evidence:**

- Tournament intelligence confirms: "The strongest papers build from one main causal estimate to one validating mechanism test, not a kitchen sink"
- Spillover is interesting but the treatment-withdrawal question stands alone

---

### Condition 4 (from GPT-5.4 B): documenting a strong first-stage in actual ERDF payments/co-financing

**Status:** [x] RESOLVED

**Response:**

Same as Condition 1 above. First-stage documentation is the first empirical step.

---

### Condition 5 (from GPT-5.4 B): handling transitional-status

**Status:** [x] RESOLVED

**Response:**

Same as Condition 2 above. Transition regions are explicitly modeled.

---

### Condition 6 (from GPT-5.4 B): payment-lag issues explicitly

**Status:** [x] RESOLVED

**Response:**

ERDF payments lag programming period boundaries because projects are approved and disbursed over multi-year cycles (the N+2/N+3 rule). Strategy:

1. **Use actual payment data, not allocation data.** cohesiondata.ec.europa.eu provides realized payments by year, not just commitments
2. **Document the lag structure:** Show the ramp-up/ramp-down of payments around the 2014 transition
3. **Treatment timing:** Define treatment as the programming period transition (2014), not individual payment dates
4. **Robustness:** Test with cumulative payments over rolling 3-year windows to smooth lag noise
5. **Intent-to-treat framing:** The reduced-form RDD (threshold crossing → GDP) is valid regardless of payment lags because the assignment mechanism (GDP/capita relative to 75%) is sharp and predetermined

**Evidence:**

- The N+2 rule means 2007-2013 payments continue until ~2015. This creates an adjustment period that should be modeled.
- The paper will show payment timelines for graduating vs. non-graduating regions

---

### Condition 7 (from GPT-5.4 B): keeping the paper centered on one main outcome chain rather than many parallel outcomes

**Status:** [x] RESOLVED

**Response:**

Primary outcome: GDP per capita (PPS). One number, one graph, one table for the main result.

Secondary outcomes serve a clear hierarchy:
- **Employment rate** — labor market channel
- **GVA composition** — structural transformation mechanism test
- **Compensation of employees** — wage channel (appendix)

The paper will pre-commit to GDP per capita as the primary outcome in Section 3 (Research Design) and explicitly state that employment and sectoral composition are mechanism tests, not co-equal outcomes. Holm correction for multiple testing.

**Evidence:**

- Tournament intelligence: "Judges liked pre-specified primary outcomes, Holm corrections, and clear mechanism sequencing"
- GDP per capita is the natural primary outcome because it is the running variable's numerator — clean symmetry

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
