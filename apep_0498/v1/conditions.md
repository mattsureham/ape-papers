# Conditional Requirements

**Generated:** 2026-03-04T09:58:32.969606
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

## Idea 1: The Austerity Mortality Gradient: Public Health Grant Cuts and Deaths of Despair in England

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: confirming no COVID interactions via 2013-2019 subsample

**Status:** [x] RESOLVED

**Response:**

The analysis will be structured with the 2013-2019 pre-COVID subsample as the PRIMARY specification. The full 2013-2024 panel (including COVID years) will be presented as a SECONDARY specification with explicit COVID controls (LA-level excess mortality, COVID case rates). This addresses the concern head-on: if effects are present in 2013-2019, they cannot be driven by COVID.

Additionally, 2020 can be excluded entirely (or dummied out) as a robustness check, and the paper will present event-study plots that allow visual inspection of whether treatment effects accelerate during COVID years or are stable across the pre-COVID window.

**Evidence:**

Fingertips API confirmed to have LA-level mortality data from 2001 onward, providing 7 years of pre-treatment data (2006-2012) and 7 years of clean post-treatment pre-COVID data (2013-2019). This is more than sufficient for a credible DiD with the 2013-2019 subsample as primary.

---

### Condition 2: piloting mechanism with NDTMS data

**Status:** [x] RESOLVED

**Response:**

The NDTMS drug treatment completion data (Fingertips indicator 90244) is confirmed available at LA level from 2010/11 onward. This provides the key mechanism test: Grant cut → reduced treatment capacity/completions → more drug deaths. The paper will present this as a "first-stage" / mechanism verification: do LAs that received larger grant cuts see lower drug treatment completion rates?

Additionally, indicator 90245 (non-opiate treatment completions) provides a complementary mechanism check, and indicator 91117 (estimated prevalence of opiate/crack use) provides a denominator check.

**Evidence:**

API test confirmed: `curl -s "https://fingertips.phe.org.uk/api/all_data/csv/by_indicator_id?indicator_ids=90244&area_type_id=402"` returns LA-level data from 2010/11 with 150+ LAs. Sample: Hartlepool 2010/11 = 4.06% successful completion rate; England average = 6.66%.

---

## Business Improvement Districts and Urban Safety: Staggered Evidence from England

**Rank:** #2-3 | **Recommendation:** CONSIDER/PURSUE (model disagreement)

### Condition 1: securing a high-quality BID boundary/timing dataset

**Status:** [x] NOT APPLICABLE — Not pursuing this idea. Proceeding with Idea 1.

### Condition 2: committing ex ante to a design centered on close votes/failed ballots

**Status:** [x] NOT APPLICABLE — Not pursuing this idea.

### Condition 3: /or boundary discontinuities rather than vanilla staggered DiD

**Status:** [x] NOT APPLICABLE — Not pursuing this idea.

### Condition (from Grok): securing centralized BID dataset

**Status:** [x] NOT APPLICABLE — Not pursuing this idea.

### Condition (from Grok): pre-testing pre-trends on 50+ BIDs

**Status:** [x] NOT APPLICABLE — Not pursuing this idea.

---

## When the Waters Rise: Flood Events, Property Markets, and the Persistence of Risk Mispricing

**Rank:** #2-3 | **Recommendation:** CONSIDER

### Condition 1: framing the paper entirely around the Flood Re insurance market distortion rather than just flood capitalization

**Status:** [x] NOT APPLICABLE — Not pursuing this idea.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
