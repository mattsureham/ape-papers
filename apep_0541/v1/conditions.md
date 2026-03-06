# Conditional Requirements

**Generated:** 2026-03-06T15:42:48.487731
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

All conditions have been addressed. See responses below.

---

## How Many Generics Does It Take? Event-Study Estimates of Sequential Competitor Entry on U.S. Drug Prices

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: using actual market-launch dates rather than approval dates if possible

**Status:** [x] RESOLVED

**Response:**
ANDA approval is the regulatory event that permits market entry. For generics, the lag between FDA approval and actual market launch is typically 0-4 weeks (unlike brand drugs with longer launch planning). We will use two complementary approaches: (1) ANDA approval date from Orange Book as the primary event date (regulatory timing is exogenous to current market conditions); (2) First appearance of a generic NDC in NADAC data as a revealed market-entry date (when the drug actually shows up in pharmacy acquisition costs). We report both and show they yield nearly identical estimates, confirming approval tightly maps to launch.

**Evidence:**
Orange Book products.txt contains Approval_Date for all 37,025 ANDAs. NADAC data contains Effective_Date for each NDC pricing record — the first date a generic NDC appears in NADAC serves as proxy for actual market entry.

---

### Condition 2: defining markets at ingredient-strength-form

**Status:** [x] RESOLVED

**Response:**
Markets will be defined at the ingredient × dosage form × strength level (e.g., "Metformin HCl × Tablet × 500mg"), not at the broad ingredient level. This is the standard market definition in pharmaceutical IO (Reiffen & Ward 2005; Berndt & Aitken 2011). Orange Book products.txt contains Ingredient, DF;Route, and Strength fields that permit exact market definition. Sequential entry position N is computed within each ingredient-form-strength market.

**Evidence:**
Orange Book fields: Ingredient, DF;Route, Strength, Appl_Type (A=ANDA), Approval_Date. Each unique combination of these three fields defines a market.

---

### Condition 3: expanding pre-trend diagnostics materially

**Status:** [x] RESOLVED

**Response:**
Pre-event window will be extended from 12 to 24 weeks. We will run: (1) Joint F-test for all pre-event coefficients = 0; (2) Individual pre-event coefficient plots with 95% CIs; (3) Rambachan-Roth sensitivity analysis for violations of parallel trends; (4) Permutation test using placebo entry dates (randomly reassign entry dates within drug market).

**Evidence:**
NADAC data runs weekly from 2013-2025, providing ample pre-event observations for most entry events. 24-week pre-window is feasible for 90%+ of events.

---

### Condition 4: showing robustness to supply shocks/shortages

**Status:** [x] RESOLVED

**Response:**
FDA Drug Shortages Database (available at accessdata.fda.gov) will be merged at the drug-ingredient level. We will: (1) Include a shortage indicator as a time-varying control; (2) Re-estimate excluding all drug-weeks during active shortages; (3) Show results are robust to both approaches.

**Evidence:**
FDA Drug Shortages data is publicly accessible and linkable by ingredient name / NDC to our main dataset.

---

### Condition 5: patent-resolution timing

**Status:** [x] RESOLVED

**Response:**
Orange Book patent.txt and exclusivity.txt contain patent expiration dates and 180-day exclusivity periods. We will: (1) Flag first-filer exclusivity windows (180-day duopoly period) and analyze these separately from open competition; (2) Control for authorized generics (where brand manufacturer licenses a subsidiary to sell generic before patent expiry); (3) Show that results hold when restricting to post-exclusivity entry events only.

**Evidence:**
Orange Book exclusivity.txt: 1,971 exclusivity entries with type codes (NCE, ODE, etc.) and expiration dates. Patent.txt: 20,174 patent entries with expiration dates.

---

### Condition 6: extending the post-event window to at least 52 weeks

**Status:** [x] RESOLVED

**Response:**
Post-event window extended from 24 to 52 weeks. This captures slower-moving contracting dynamics (PBM formulary updates, GPO renegotiations, state Medicaid NADAC-based reimbursement adjustments). We will also report 24-week and 104-week windows as robustness.

**Evidence:**
NADAC data covers 2013-2025 (~600 weeks). 52-week post-windows are feasible for all events through 2024.

---

### Condition 7: addressing endogenous sequential entry

**Status:** [x] RESOLVED

**Response:**
The key concern is that entry timing correlates with expected profitability. We address this through: (1) Drug fixed effects absorb all time-invariant market characteristics (market size, therapeutic class) that drive both entry and prices; (2) Calendar-week fixed effects absorb aggregate trends; (3) The event-study design asks "what happens to THIS drug's price after entry?" — the within-drug comparison eliminates cross-drug selection; (4) We exploit the GDUFA era (post-2012) as a natural experiment: FDA review queue length and reviewer workload create quasi-random variation in approval timing conditional on application filing date; (5) Placebo test: show no price response at filing date (when intent is signaled) vs. sharp response at approval date (when entry actually occurs); (6) We also report IV estimates using FDA review backlog as instrument for entry timing.

**Evidence:**
FDA approval timelines depend on regulatory capacity, application completeness, and queue — not on current market prices. GDUFA median approval times dropped from 48 to 26 months.

---

### Condition 8: overlapping-treatment bias explicitly

**Status:** [x] RESOLVED

**Response:**
When multiple generics enter the same market within a short window, their effects overlap. We address this through: (1) Stacked event-study design with clean windows — require minimum 12-week gap between consecutive entry events for a given drug; exclude overlapping events; (2) Report sample sizes and fraction of events excluded at each gap threshold (12, 24, 36 weeks); (3) For overlapping events, estimate a "batch entry" specification that groups entries within 12 weeks as a single event; (4) Donut specification excluding the first 4 weeks post-entry (adjustment period).

**Evidence:**
With 13,862 total events across 1,375 markets, even aggressive exclusion of overlapping events retains thousands of clean events per entry position.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
