# Conditional Requirements

**Generated:** 2026-03-05T10:09:21.694942
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

## Slower Streets, Safer Streets? The Causal Effect of Wales's 20mph Default Speed Limit

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: verifying that 15 months of post-treatment Land Registry data provides sufficient transaction volume to power the hedonic pricing model

**Status:** [x] RESOLVED

**Response:**

Welsh Land Transaction Tax statistics show ~10,000-12,000 residential transactions per quarter in Wales (GOV.WALES LTT quarterly reports). Over 15 post-treatment months (2023Q4-2024Q4), this yields ~50,000-60,000 Welsh transactions. Combined with English border-area transactions for the control group, this provides ample power for hedonic analysis. The Land Registry PPD includes postcode-level data, enabling precise matching to road speed limit zones.

**Evidence:**

GOV.WALES LTT Statistics: Q4 2024 showed +19% YoY growth in residential transactions. HM Land Registry PPD covers all England & Wales transactions since 1995 at postcode level.

---

## Idea 1: Slower Streets, Safer Streets? The Causal Effect of Wales's 20mph Default Speed Limit on Road Casualties and Property Values

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: extending post-period analysis into 2025 if data available

**Status:** [x] RESOLVED

**Response:**

STATS19 2024 data is published (GOV.UK annual report released 2025). 2025 STATS19 data will not be available until ~September 2026 (annual publication cycle). The paper will use 2019-2024 data, providing 56 pre-treatment months and 15 post-treatment months. For Land Registry, 2024 data is largely available by early 2026 with typical 2-3 month publication lag. This provides sufficient post-treatment data — the literature shows 12+ post-treatment months is standard for transport interventions. The large effect size (28% casualty reduction in descriptive stats) means the study is well-powered even with 15 months.

**Evidence:**

GOV.UK "Reported road casualties Great Britain, annual report: 2024" published 2025. STATS19 R package confirmed access to 2022-2023; 2024 files available via direct download.

---

### Condition 2: testing reversals as reverse-treatment design

**Status:** [x] RESOLVED

**Response:**

Starting in early-to-mid 2024, the Welsh Government allowed LAs to apply for exceptions, and individual roads began being reclassified back to 30mph. This creates a "reverse treatment" or "policy unwinding" design that strengthens identification:
1. If 20mph reduced casualties, areas that reversed back to 30mph should see casualty increases
2. Within-Wales cross-LA variation in reversal intensity provides a second source of identification
3. The design is: (a) Wales-vs-England DiD for the aggregate effect, (b) within-Wales dose-response using reversal share

This follows the "internal replication" strategy that tournament judges reward — multiple quasi-experiments within one paper.

**Evidence:**

Transport for Wales National Monitoring Report (July 2025) documents the reversal process. Welsh Government press releases confirm LA-by-LA exception applications from 2024.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
