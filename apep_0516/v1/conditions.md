# Conditional Requirements

**Generated:** 2026-03-05T10:45:44.113495
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

Only Idea 1 (PTZ Reform) conditions addressed — this is the selected idea.

---

## Does Geographic Targeting of Housing Subsidies Matter? Evidence from France's PTZ Reform

**Rank:** #1 | **Recommendation:** PURSUE (all 3 models)

### Condition 1: convincing border-based parallel trends / demonstrating parallel trends prior to 2018

**Status:** [x] RESOLVED

**Response:** The event study will include year-by-year coefficients for 2014-2017 (4 pre-treatment years). For the border analysis, I will identify communes on either side of the B1/B2 boundary within the same département and verify that their price trajectories are parallel in the pre-period. The ABC zone classification is based on housing market tightness indicators set in 2014 — border communes are observably similar. I will also apply Rambachan-Roth (HonestDiD) sensitivity analysis to bound the effect under non-parallel trends assumptions.

**Evidence:** DVF provides ~3.5M transactions/year; there are ~5,000 B1 communes and ~21,000 B2/C communes. The 4-year pre-period (2014-2017) provides ample data for pre-trend verification. Border communes share the same département, similar rural/semi-urban character.

---

### Condition 2: explicit handling of 2019–2021 disruptions / robust COVID sensitivity checks

**Status:** [x] RESOLVED

**Response:** Three approaches: (1) Event study shows year-by-year dynamics, making COVID disruption visible rather than hidden. (2) Robustness check excluding 2020-2021 (COVID years), using only 2014-2019 post-period. (3) Triple-difference using commercial/industrial property transactions as a within-commune control (affected by COVID but NOT by PTZ removal). If PTZ effects appear in 2018-2019 (pre-COVID) and commercial properties show no differential, the COVID confound is neutralized.

**Evidence:** DVF includes property type codes distinguishing residential from commercial. Commercial sales serve as a clean placebo since PTZ applies only to residential purchases.

---

### Condition 3: a demonstrated first-stage "bite" measure

**Status:** [x] RESOLVED

**Response:** First-stage = Sitadel construction permits data showing that new housing starts actually declined in B2/C relative to B1 after 2018. This is the "bite" — did the subsidy removal actually reduce construction? I will present this as the first empirical result before any price analysis. Additionally, aggregate PTZ loan volumes by zone from SGFGAS (Société de Gestion des Financements et de la Garantie de l'Accession Sociale) annual reports, which publish PTZ counts by zone.

**Evidence:** Sitadel commune-level housing starts available from 2013 on data.gouv.fr (SDES). SGFGAS publishes annual PTZ issuance statistics by zone. Both provide direct first-stage measures.

---

### Condition 4: share of eligible new-build purchases/permits shifting as predicted

**Status:** [x] RESOLVED

**Response:** This is the same first-stage test. I will show: (1) new-build starts in B2/C declined relative to B1, (2) share of national PTZ-eligible purchases shifted from B2/C to A/B1, (3) DVF new-build transaction volumes fell in B2/C. These three measures together demonstrate the policy "bit."

**Evidence:** Combined DVF (new-build vs. existing flag in transaction type) + Sitadel + SGFGAS reports.

---

### Condition 5: ensuring the border discontinuity has sufficient transaction density

**Status:** [x] RESOLVED

**Response:** With ~3.5M total transactions/year and ~26,000 B1+B2 communes, the average commune has ~135 transactions/year. Border communes in semi-urban areas will have somewhat fewer, but across ~500-1,000 border commune pairs over 10+ years, the total N will be in the hundreds of thousands. I will verify density in the data and report the exact count. If individual border communes have sparse data, I will aggregate to canton or intercommunalité level.

**Evidence:** DVF covers universe of transactions. Even with conservative assumptions (50 transactions/commune/year × 500 border communes × 10 years = 250,000 border transactions), there is ample power.

---

### Condition 6: full mechanism decomposition in first draft

**Status:** [x] RESOLVED

**Response:** Four mechanisms planned: (1) **Price capitalization**: Did new-build prices fall in B2/C? (subsidy incidence). (2) **Construction supply**: Did new housing starts decline? (real activity effect). (3) **Buyer sorting**: Did first-time/young buyer share decline in B2/C? (DVF has buyer age for some transactions via DGFiP enrichment). (4) **Spatial reallocation**: Did B1 communes near the border see increased transactions? (substitution to subsidy-eligible areas). Each mechanism gets its own figure and table.

**Evidence:** DVF + Sitadel + INSEE demographic data by commune.

---

## Non-selected ideas (Idea 2-5): NOT APPLICABLE

All conditions for Ideas 2-5 are marked NOT APPLICABLE as we are proceeding with Idea 1.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
