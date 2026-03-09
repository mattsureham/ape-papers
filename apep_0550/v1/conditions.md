# Conditional Requirements

**Generated:** 2026-03-09T09:39:00.742462
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

All conditions have been addressed. Consolidated across 3 models into 4 unique themes.

---

## Condition 1: First-stage — proving de facto implementation changed trading behavior

**Status:** [x] RESOLVED

**Response:**
The first stage will be tested directly using mandi-level arrivals data (tonnes arriving at mandis). If deregulation allowed trade outside APMC mandis, we should observe: (a) a decline in regulated mandi arrivals in high-APMC-stringency states during the ON phase, and (b) a recovery during the OFF phase. We will also test whether new (unregistered) trading points emerged using e-NAM registration data. The commodity × state × time variation in arrivals serves as our first-stage outcome.

**Evidence:**
- CEDA AGMARKNET API provides both prices AND arrivals (tonnes) at mandi-commodity-day level
- We can directly measure whether trading volume shifted away from regulated mandis
- States that blocked implementation (Punjab, Rajasthan, Chhattisgarh) should show no first-stage — this is a built-in falsification test

---

## Condition 2: COVID-19 contamination — robustly controlling for pandemic disruptions

**Status:** [x] RESOLVED

**Response:**
COVID is the primary identification threat since the ON phase (June 2020–January 2021) overlaps with the pandemic. Our strategy:
1. **State × month FE** absorb all state-level COVID shocks (lockdowns, mobility restrictions)
2. **Commodity × month FE** absorb national-level commodity demand shocks
3. **Bihar placebo:** Bihar abolished APMC in 2006. If our results are driven by COVID, Bihar should show the same patterns — but it should show NO differential effect since it was already deregulated
4. **Within-state cross-commodity comparisons:** Compare highly regulated commodities (wheat, rice with APMC levy) vs. unregulated commodities (fruits, vegetables often exempt from APMC in many states) within the same mandi
5. **The symmetric OFF phase** (post-January 2021) provides a second test in a different COVID environment — if we see reversal, it's not just COVID
6. Agriculture was classified as an essential sector and exempted from most lockdown restrictions after the initial March-May 2020 lockdown

**Evidence:**
- Agricultural markets reopened by April 2020 (MHA guidelines), well before the farm laws (June 2020)
- The identification relies on cross-state variation in APMC stringency, not aggregate time-series — COVID must differentially affect high- vs low-APMC states to confound

---

## Condition 3: Demonstrating symmetric reversal around the stay/repeal

**Status:** [x] RESOLVED

**Response:**
The symmetric reversal IS the central empirical contribution. The event-study design will show:
1. **Baseline:** Pre-June 2020 levels
2. **ON phase:** Price/arrival changes June 2020–January 2021 (deregulation)
3. **OFF phase:** Price/arrival changes post-January 2021 (re-regulation)

If deregulation genuinely affected agricultural markets, we expect: (a) ON-phase coefficients significant and in one direction, (b) OFF-phase coefficients return toward zero or reverse. This is the paper's strongest identification feature — the reversal is a built-in placebo test.

**Evidence:**
- Supreme Court stay (January 12, 2021) and formal repeal (December 1, 2021) are precisely dated exogenous events
- The daily data frequency enables sharp event-study plots showing the ON→OFF transition

---

## Condition 4: Not just generic time-series breaks; state-specific confounds addressed

**Status:** [x] RESOLVED

**Response:**
The design uses CROSS-SECTIONAL variation in APMC stringency, not time-series breaks:
1. **Treatment intensity** = pre-existing state APMC regulation stringency (number of commodities regulated, APMC cess rate, licensing requirements). This varies dramatically: Punjab mandates mandi trading for all notified commodities with 6% commission; Gujarat has private mandi provisions; Bihar has no APMC.
2. **State-specific confounds** (e.g., Punjab's concurrent MSP-linked protests) addressed by: (a) excluding Punjab/Haryana in robustness checks (protests are state-specific), (b) testing whether results change with/without protesting states, (c) using within-state variation where possible (commodity-level APMC regulation varies)
3. **Mandi × commodity FE** absorb all time-invariant market-commodity characteristics
4. **Not a time-series break:** The identifying coefficient is the interaction of APMC stringency × Post, not the Post dummy alone

**Evidence:**
- Chatterjee (2020, EPW) documents state-level APMC stringency index covering all states
- Pre-farm-law APMC cess rates range from 0% (Bihar) to 8.5% (Punjab) — substantial variation

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Status: RESOLVED**
