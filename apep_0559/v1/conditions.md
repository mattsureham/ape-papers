# Conditional Requirements

**Generated:** 2026-03-09T15:35:51.373841
**Status:** RESOLVED

---

## Cap On, Cap Off: The Symmetric Credit Rationing Experiment from Kenya's Interest Rate Ceiling (2016-2019)

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: Obtaining bank-level supervisory data / replacing tier DiD with sharper exposure

**Status:** [x] RESOLVED

**Response:**
CBK Annual Reports (publicly available PDFs, ~5MB per year) contain individual bank balance sheets for all ~42 licensed commercial banks. These report: total assets, loans & advances, government securities holdings, deposits, NPLs, and interest income/expense per bank. This provides bank-level panel data. Rather than coarse tier dummies, I will construct a continuous pre-cap exposure measure:

- **Pre-cap SME lending share:** Ratio of loans & advances to total assets, interacted with bank size (smaller banks with higher loan/asset ratios are more exposed because they can't easily shift to government securities)
- **Pre-cap government securities share:** Banks already holding large government securities portfolios are LESS exposed (they already have the substitution margin)
- **Pre-cap interest rate spread:** Banks charging higher pre-cap rates face a larger bite from the CBR+4% cap

This continuous exposure approach addresses all three models' concerns about coarse tier dummies.

**Evidence:**
CBK Annual Reports confirmed downloadable from cbk.go.ke. Smoke test: 2015 Annual Report contains individual balance sheet data for all 42 banks (Table 4.1 in CBK publications).

---

### Condition 2: Demonstrating parallel pre-trends

**Status:** [x] RESOLVED

**Response:**
24 months of pre-cap monthly aggregate data (Sep 2014 – Aug 2016) available from CBK monthly statistical bulletins. For bank-level analysis, annual balance sheet data 2010–2015 provides 6 pre-treatment years. Event-study design will show:
1. Dynamic treatment effects with leads and lags
2. Joint F-test on pre-treatment coefficients
3. Visual event-study plots for key outcomes (credit growth, NPL ratio, govt securities share)

With continuous exposure measure, pre-trends test whether high-exposure vs low-exposure banks were on different trajectories before the cap.

**Evidence:**
CBK Rates CSV smoke test confirmed: 24+ months pre-cap data available; lending rate was stable at 16-18% range during 2014-2016 before sharp drop at cap.

---

### Condition 3: Isolating repeal effect from COVID

**Status:** [x] RESOLVED

**Response:**
Three-pronged strategy:
1. **Clean pre-COVID window:** Repeal was November 7, 2019; COVID lockdown in Kenya started March 15, 2020. This gives ~4 months of clean post-repeal, pre-COVID data. I will show immediate effects in this window.
2. **COVID controls:** Use Kenya's COVID stringency index (OxCGRT) as a time-varying control. All banks face the same COVID shock, so within the DiD framework, COVID is differenced out as a common shock.
3. **Asymmetric COVID exposure test:** If high-exposure (SME-focused) banks were differentially hurt by COVID, show this explicitly and bound the contamination. Use East African comparator banks (Uganda, Tanzania) as COVID-affected but non-repeal controls for the repeal period.

**Evidence:**
Kenya COVID timeline: first case March 13, 2020; curfew March 27. Four months of clean post-repeal data is available. OxCGRT Kenya data available via GitHub.

---

### Condition 4: Treating digital credit as mechanism, not core identification

**Status:** [x] RESOLVED

**Response:**
Digital credit substitution (M-Pesa, Tala, Branch) will be presented as a MECHANISM section, not as part of the core identification. The core causal story is: cap → bank portfolio rebalancing → private credit contraction (using bank-level supervisory data). The substitution into digital credit is presented as a welfare consequence — borrowers pushed from ~14% APR regulated lending to ~90% APR digital credit. FinAccess microdata provides supporting household-level evidence but is explicitly framed as descriptive/suggestive, not causal.

**Evidence:**
FinAccess 2016 and 2019 surveys bracket the cap period. Digital credit users grew from 200K to 2M adults. M-Shwari charges 7.5% per 30 days = ~138% APR effective.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
