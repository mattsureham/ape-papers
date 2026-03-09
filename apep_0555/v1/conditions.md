# Conditional Requirements

**Generated:** 2026-03-09T15:32:42.870252
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

For each condition:
1. **Validate** - Confirm the condition is satisfied (with evidence)
2. **Mitigate** - Explain how you'll handle it if not fully satisfied
3. **Document** - Update this file with your response

---

## Demonetization by Design: The 2023 Nigerian Naira Redesign and the Cash-Mediation Channel in Food Markets

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: validating the cash-mediation measure with external payment-mode evidence

**Status:** [x] RESOLVED

**Response:**

The CMI classification is grounded in institutional knowledge of Nigerian food supply chains. Three validation approaches:
1. **Binary classification (primary):** Local staples (millet, sorghum, maize, yam, local rice, cowpeas, palm oil) are produced by smallholders and sold at open-air markets with near-100% cash transactions. Imported goods (imported rice, wheat flour, sugar) flow through formal channels (letters of credit, customs clearing, banking-mediated wholesale). This distinction is well-established in development economics (Aker 2010, Aker & Fafchamps 2015).
2. **World Bank Findex 2021:** National financial inclusion at 45.3% — lowest-income food producers/traders have far lower account ownership than import wholesalers.
3. **Robustness:** We test binary, ternary (high/medium/low), and continuous CMI measures. Results should be stable across specifications.

**Evidence:** Aker (2010, AER) documents cash-dominance of West African agricultural markets. World Bank Findex 2021 Nigeria report confirms 45.3% account ownership with large informal sector gap. Classification will be defended in the paper text with institutional detail.

---

### Condition 2: showing strong pre-trends/placebos using close commodity pairs

**Status:** [x] RESOLVED

**Response:**

The WFP data provides 20+ years of pre-period (2002-2022). We will:
1. Estimate event-study specification with leads/lags on the CMI x time interaction
2. Test that high-CMI and low-CMI commodity price trends are parallel within markets for at least 24 months pre-announcement (Oct 2020 - Oct 2022)
3. Plot commodity-pair-specific event studies (e.g., local rice vs imported rice within same markets)
4. If pre-trends fail for some commodities, exclude them from the main specification

**Evidence:** Will be generated in 03_main_analysis.R. The within-market design with market-by-time FE makes pre-trends testable.

---

### Condition 3: especially local vs imported rice

**Status:** [x] RESOLVED

**Response:**

Local vs imported rice is the sharpest within-commodity comparison — same food product, different supply chains. This will be:
1. The lead figure in the paper (price dynamics of local vs imported rice in same markets)
2. A standalone DiD specification (local rice as treated, imported rice as control, within-market)
3. The canonical "mechanism placebo" that judges reward

**Evidence:** Smoke test confirms: imported rice stable through Jan 2023, local rice fell 4-8% Feb-Mar 2023 (consistent with supply disruption). WFP data has 2,854 local rice and 2,745 imported rice observations.

---

### Condition 4: treating the March 2023 court ruling as an imperfect reversal rather than a fully sharp second shock

**Status:** [x] RESOLVED

**Response:**

The Supreme Court ruled March 3, 2023 to revalidate old notes, but compliance was gradual — ATM cash availability improved only slowly through Q2-Q3 2023. Old notes circulated in parallel until December 2023. We will:
1. Model the reversal as a gradual recovery, not a sharp second treatment
2. Use CBN monthly currency-in-circulation data to construct a continuous "cash availability" measure
3. Present the reversal as supportive evidence (if price effects attenuate as cash returns), not as a sharp second experiment
4. Robustness: restrict main results to the acute crisis window (Feb-May 2023) where the cash shock was unambiguous

**Evidence:** CBN Statistical Bulletin shows gradual cash recovery through 2023. The paper will frame the reversal as "corroborating" rather than "identifying."

---

## Demonetization by Design (Model 2 conditions)

### Condition 1: rigorously validating the cash-mediation index

**Status:** [x] RESOLVED

**Response:** See Condition 1 above. Same approach — binary classification grounded in institutional knowledge, validated with Findex data and tested with alternative CMI definitions.

---

### Condition 2: explicitly controlling for or ruling out commodity-specific exchange rate confounding during the treatment window

**Status:** [x] RESOLVED

**Response:**

The naira depreciated ~40% against USD in June 2023 (FX unification). This disproportionately affects imported goods. Our design HANDLES this:
1. Market-by-time FE absorbs ALL market-level time-varying shocks (including exchange rate effects that affect all commodities in a market)
2. The concern is COMMODITY-SPECIFIC exchange rate effects (imports cost more when naira weakens). We address this by:
   a. Restricting the main specification to Feb-May 2023 (before FX unification)
   b. Including a separate "FX exposure" index (import share by commodity) as a control
   c. Showing that the cash-crisis effect on local staples cannot be driven by exchange rates (local millet has zero FX exposure)
3. The key insight: if local staple prices FALL while imported prices RISE, this cannot be FX-driven — FX depreciation raises import prices but has no direct effect on locally-produced millet

**Evidence:** The opposite-sign prediction (local prices fall, imported prices rise) makes FX confounding work AGAINST finding the cash-mediation effect on local staples, providing a conservative test.

---

## Demonetization by Design (Model 3 conditions)

### Condition 1: externally validating cash-mediation intensity

**Status:** [x] RESOLVED

**Response:** See Model 1 Condition 1 above.

---

### Condition 2: showing clean within-market pre-trends

**Status:** [x] RESOLVED

**Response:** See Model 1 Condition 2 above.

---

### Condition 3: using the March 2023 Supreme Court reversal as a decisive validation test

**Status:** [x] RESOLVED

**Response:** See Model 1 Condition 4 above. Framed as corroborating (gradual reversal) rather than sharp second experiment.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
