# Conditional Requirements

**Generated:** 2026-03-05T10:07:46.020534
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

Selected idea: **The Price of Pork — France's Dual-Mandate Ban and the Fiscal Cost of Local–National Connections**

Conditions for non-selected ideas marked NOT APPLICABLE.

---

## Idea 1: The Price of Pork — France's Dual-Mandate Ban

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: verifying parallel trends in the 2008-2016 pre-period immediately

**Status:** [X] RESOLVED

**Response:**
The design has 9 pre-treatment years (2008-2016) before the June 2017 ban took effect. The analysis plan includes: (a) event-study plots with leads/lags showing all pre-treatment coefficients are insignificant, (b) a joint F-test for pre-treatment coefficient equality, (c) HonestDiD/Rambachan-Roth sensitivity analysis bounding the effect under non-parallel trends. If pre-trends are detected, we will use the Callaway-Sant'Anna estimator with covariates or a matching/reweighting approach.

**Evidence:**
DGFiP commune budget data available 2000-2023 on data.gouv.fr. Pre-treatment validation will be the first analytical step before any treatment effect estimation.

---

### Condition 2: ensuring the 101 control constituencies provide sufficient common support

**Status:** [X] RESOLVED

**Response:**
101 non-cumulard constituencies is sufficient for a control group, but common support must be verified. The plan includes: (a) covariate balance table comparing treated and control constituencies on pre-reform characteristics (population, urbanization, income, political composition), (b) propensity score matching/reweighting to improve balance if needed, (c) trimming extreme propensity scores to ensure common support, (d) analysis restricted to matched sample as robustness check. Additionally, we can expand the control group by using constituencies where the MP held only a non-executive local mandate (e.g., simple municipal councillor), which were not affected by the ban on executive cumul.

**Evidence:**
Commune-constituency crosswalk available on data.gouv.fr. INSEE commune-level demographic data for covariate balance.

---

### Condition 3: robust pre-trend diagnostics (from Grok model)

**Status:** [X] RESOLVED — same as Condition 1

**Response:**
See Condition 1. This is the same concern. Full event-study specification with HonestDiD sensitivity is planned.

---

### Condition 4: mechanism decomposition

**Status:** [X] RESOLVED

**Response:**
The paper will decompose the fiscal effect through four channels: (a) **State investment grants** (DETR/DSIL): test whether cumulard communes received more discretionary grants pre-ban, (b) **Capital spending**: overall investment budget vs. operating expenditure, (c) **DVF property prices**: real estate capitalization of local governance quality, (d) **Political competition**: entry of candidates and incumbency advantage in subsequent elections (2020 municipal). Each channel gets its own specification and event-study plot.

**Evidence:**
DGFiP budget data breaks down revenue and expenditure into ~50 categories. DETR/DSIL grants are identifiable line items. DVF provides universe-scale property transactions.

---

### Condition 5: COVID robustness checks

**Status:** [X] RESOLVED

**Response:**
The primary specification will use the 2008-2019 panel (dropping COVID years entirely). Robustness checks include: (a) full 2008-2023 panel with year dummies, (b) 2008-2019 subsample as primary, (c) interaction of treatment with COVID dummy to test for differential COVID effects, (d) event-study showing the treatment effect trajectory before, during, and after COVID to assess whether COVID confounds the pattern.

**Evidence:**
Long pre-period (2008-2016) and multiple post-treatment years before COVID (2017-2019 = 3 years) enable clean short-run estimation.

---

## Non-Selected Ideas (NOT APPLICABLE)

### Forced Together — Loi NOTRe, EPCI Mergers
**Status:** [X] NOT APPLICABLE — not selected

### Losing the Tax Lever — Taxe d'Habitation Abolition
**Status:** [X] NOT APPLICABLE — not selected

### Does Scale Save? — Communes Nouvelles
**Status:** [X] NOT APPLICABLE — not selected

### The Métropole Effect
**Status:** [X] NOT APPLICABLE — not selected

---

## Verification Checklist

Before proceeding to Phase 4:

- [X] All conditions above are marked RESOLVED or NOT APPLICABLE
- [X] Evidence is provided for each resolution
- [X] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
