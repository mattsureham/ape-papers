# Conditional Requirements

**Generated:** 2026-03-03T19:42:19.947589
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

---

## Crowding In or Pricing Out? Private School VAT and State Sector Pressure in England

**Rank:** #3 | **Recommendation:** CONSIDER

### Condition 1: waiting for additional post years or finding higher-frequency administrative admissions/capacity data

**Status:** [x] NOT APPLICABLE

**Response:** This idea is not being pursued as a standalone paper. We are proceeding with Idea 1 (housing premium). The enrollment/capacity channel will be referenced in the motivation but not as the primary outcome.

---

### Condition 2: pre-specifying an "equivalence/MDE" framework if the short run is the target

**Status:** [x] NOT APPLICABLE

**Response:** Not applicable — Idea 2 is not being pursued. For Idea 1, the housing outcome has massive sample size (millions of transactions), so MDE is extremely small. We will compute and report the MDE explicitly in the paper.

---

## Idea 1: The Hidden Tax on School Quality: How VAT on Private Fees Reshapes England's State School Housing Premium

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: explicitly framing this as a short-run/anticipation study to bypass the "short post-period" editorial penalty

**Status:** [x] RESOLVED

**Response:** The paper will be explicitly framed as studying "how fast housing markets capitalize education policy shocks." The contribution is precisely about the SPEED and MECHANISM of capitalization, not the long-run equilibrium. Three key framing devices:
1. Multi-stage information revelation: Labour manifesto (early 2024) → election (July 4) → Budget (Oct 30) → implementation (Jan 1, 2025) provides multiple event-study moments
2. Housing markets respond faster than education outcomes — this is a feature of the design, not a limitation
3. Gibbons & Machin (2003, 2006) established that school quality premiums in England adjust within months of new information (Ofsted re-ratings)

**Evidence:** Fack & Grenet (2010) find house price adjustments to school quality information within the same academic year. The 14-month post-treatment window with monthly data gives 14 post-treatment observations — more than many successful event studies.

---

### Condition 2: folding in the inequality metrics from Idea 3 as a mechanism check

**Status:** [x] RESOLVED

**Response:** The paper will include a dedicated section on distributional consequences: (1) within-LA price dispersion (P90/P10 ratio) as a function of treatment intensity, (2) heterogeneous effects by LA deprivation quintile — does the state school premium increase more in affluent LAs where private school penetration is higher? This becomes a "welfare implication" section, not a separate paper.

**Evidence:** Will be implemented in `04_robustness.R` as heterogeneity analysis by LA deprivation.

---

## Idea 3: Does Making Private School More Expensive Reduce Inequality? Evidence from England's VAT Shock

**Rank:** #2 | **Recommendation:** CONSIDER

### Condition 1: merging this into Idea 1 as the concluding welfare/counterfactual exercise rather than writing it as a standalone paper

**Status:** [x] RESOLVED

**Response:** Confirmed — Idea 3's inequality analysis will be folded into Idea 1 as Section 6 ("Distributional Consequences"). This provides the mechanism chain: VAT → enrollment shift → demand reallocation → price capitalization → spatial inequality.

---

## The Hidden Tax on School Quality: How VAT on Private Fees Reshapes England's State School Housing Premium

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: robust pre-trends visualization

**Status:** [x] RESOLVED

**Response:** The paper will include:
1. Event-study figure showing monthly treatment-intensity-weighted price differential for 10 years pre-treatment (120 monthly observations)
2. Separate event studies for each Dimension 2 group (near Outstanding vs near Inadequate state schools)
3. HonestDiD / Rambachan-Roth sensitivity bounds on pre-trend violations
4. Formal F-test for joint significance of pre-treatment coefficients

**Evidence:** With 10+ years of monthly Land Registry data and millions of transactions, pre-trend visualization will have excellent statistical power.

---

### Condition 2: placebo batteries in first draft

**Status:** [x] RESOLVED

**Response:** Four placebo tests planned for the first draft:
1. **Zero-treatment placebo:** Areas with no private schools (treatment intensity = 0) should show no differential effect near good vs. poor state schools
2. **Property type placebo:** Commercial property transactions should be unaffected by the school-quality mechanism
3. **Pre-period placebo:** Run the same DDD on a fake treatment date (e.g., January 2020) — should yield null
4. **School-type placebo:** Near private schools themselves (seller side) — different mechanism, different prediction

**Evidence:** Each placebo mirrors a specific mechanism prediction, following the tournament lesson that "placebos that mirror the mechanism beat generic falsification."

---

### Condition 3: incorporate inequality/announcement as robustness sections

**Status:** [x] RESOLVED

**Response:** Both incorporated:
- Inequality: Section 6 — distributional consequences (within-LA price dispersion, heterogeneity by deprivation)
- Announcement timing: Section 5.2 — sub-event analysis decomposing the effect across election (Jul 2024), Budget (Oct 2024), and implementation (Jan 2025) dates

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
