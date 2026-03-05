# Conditional Requirements

**Generated:** 2026-03-05T10:03:52.184214
**Status:** RESOLVED

---

## RESOLVED: All three models recommend merging Ideas 1 and 5

The tri-model panel unanimously recommends combining the taxe d'habitation capitalization (Idea 1) with the fiscal displacement effect (Idea 5) into a single general-equilibrium public finance paper. All conditions below are resolved within this unified design.

---

## Idea 1: Taxe d'Habitation Capitalization

### Condition 1: event-study specs ruling out anticipation/pre-trends

**Status:** [x] RESOLVED

**Response:** The paper will include an event-study specification with year-by-treatment-intensity interactions for 2014-2025, explicitly testing for anticipation effects around the 2017 Macron campaign/legislation. The 4-year pre-period (2014-2017) provides power for detecting differential pre-trends. Additionally, the 2017 announcement vs 2018 implementation timing will be exploited as a separate test.

**Evidence:** DVF data confirmed available from 2014 (cadastre.data.gouv.fr). REI commune tax rates available historically.

---

### Condition 2: old vs new property controls as extra placebo

**Status:** [x] RESOLVED

**Response:** DVF data contains property type and construction era. We will use (1) commercial/industrial properties as placebo (unaffected by TH for main residences), (2) secondary residences (kept the tax — communes with high secondary-residence shares should show attenuated effects), and (3) new-build transactions as an additional control for local demand shocks.

**Evidence:** DVF data structure confirmed to include property type codes.

---

### Condition 3: combining with Idea 5 for net welfare effect / fiscal offset / elevating to GE public finance paper

**Status:** [x] RESOLVED

**Response:** The unified paper will have two empirical parts: (A) demand-side capitalization (TH elimination → property prices) using DVF, and (B) supply-side fiscal displacement (TH elimination → taxe foncière rate increases) using REI data. Part C will compute the net welfare effect: how much of the TH tax cut accrues to property owners vs. is clawed back via higher TF rates. This framing transforms a standard capitalization paper into a general-equilibrium tax incidence study.

**Evidence:** REI data contains both TH and TF rates at commune level over time.

---

## Idea 5: The Fiscal Displacement Effect

### Condition 1: merging with Idea 1 / pairing for joint incidence

**Status:** [x] RESOLVED

**Response:** Merged as Part B of the unified paper. See Idea 1 Condition 3 above.

---

### Condition 2: fiscal offset offsetting capitalization / robustness to compensation formula

**Status:** [x] RESOLVED

**Response:** We will model the state compensation mechanism explicitly. The transfer of the département TF share to communes was meant to fully compensate TH revenue loss. We will (1) compute the predicted compensation shortfall per commune using the statutory formula, (2) test whether shortfall predicts TF rate increases, and (3) show that the net capitalization = gross TH capitalization minus TF offset. Robustness will include: controlling for the compensation formula directly, using pre-reform TF rates as additional controls, and testing whether communes with different fiscal governance structures (EPCI tax integration) respond differently.

**Evidence:** Compensation formula details available from collectivites-locales.gouv.fr and Cour des comptes reports.

---

## Other Ideas (NOT APPLICABLE — not pursuing)

All conditions for Ideas 2, 3, 4 are marked NOT APPLICABLE as the paper pursues the merged Idea 1+5.

---

## Verification Checklist

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git
