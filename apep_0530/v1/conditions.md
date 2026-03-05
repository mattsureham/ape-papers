# Conditional Requirements

**Generated:** 2026-03-05T17:12:15.343285
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## Idea 2: When Zones Disappear: Priority Neighborhood Redesignation and Property Value Responses in France

**Rank:** #1 (consensus) | **Recommendation:** PURSUE (GPT, Gemini), CONSIDER (Grok)

### Condition 1: proving covariate smoothness at the boundary

**Status:** [X] RESOLVED

**Response:**

Will test covariate smoothness at QPV boundaries using DVF property characteristics (surface area, number of rooms, property type distribution) as covariates. Specifically:
1. Run local polynomial regressions of property characteristics on distance to boundary (should show no discontinuity)
2. Test density of transactions at the boundary (McCrary-style test)
3. Compare pre-2014 transaction density and characteristics across the boundary (before QPV designation, these areas were not differentially treated)

The DDD design further strengthens identification: even if there is a level difference at the boundary (QPV areas are poorer by construction), the *change* at the boundary around 2014 should be smooth in the absence of the policy effect.

**Evidence:**

QPV boundaries are drawn using a 200m-grid income criterion (median income < 11,250 EUR). This creates a clear definition of treatment but also means the boundary is correlated with income. The covariate smoothness test focuses on *housing characteristics* (which are not the assignment variable) and *pre-period* transaction values.

---

### Condition 2: parallel pre-trends

**Status:** [X] RESOLVED

**Response:**

DVF data is available from 2014 onward. For the "gained status" group: these areas were NOT in ZUS before 2014, so there was no policy treatment before the QPV designation. I will:
1. Use 2014-2016 as a pre-period (QPV boundaries were announced in late 2014 but ANRU investments took years to materialize)
2. Show year-by-year event study coefficients at the boundary for 2014-2024
3. For the "lost status" group (former ZUS, not in QPV): the pre-period is before 2014 when they were still ZUS. I can test pre-trends using the boundary discontinuity in levels across time.
4. The "retained zones" placebo provides a natural check: these zones should show NO change in the boundary discontinuity around 2014.

**Evidence:**

The ANRU renovation program (Programme National pour la Renovation Urbaine) was rolled out gradually after QPV designation. Key timeline:
- 2014: New QPV geography announced
- 2015-2016: NPNRU contracts negotiated with local authorities
- 2016-2020: Construction/renovation begins
- 2020-2025: Projects complete

This staggered implementation means effects should appear gradually, providing a clear event-study pattern.

---

## Verification Checklist

- [X] All conditions above are marked RESOLVED or NOT APPLICABLE
- [X] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
