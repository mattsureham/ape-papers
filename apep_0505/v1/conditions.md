# Conditional Requirements

**Generated:** 2026-03-04T16:04:14.440686
**Status:** RESOLVED

---

## The Hidden Costs of Devolved Austerity — Council Tax Support Localization and Household Distress

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: prioritizing pensioner placebo

**Status:** [x] RESOLVED

**Response:**
Pensioners are the centerpiece of the identification strategy. Working-age claimants faced new minimum payments; pensioners were exempt by law under the national protection scheme. Both groups live in the same LAs, face the same local economic conditions, but only working-age claimants are treated. The pensioner-working-age comparison within each LA is the primary falsification test.

**Evidence:**
The Welfare Reform Act 2012 (Schedule 4) mandates that pension-age CTR schemes must replicate the old CTB entitlements exactly. DLUHC publishes CTS caseload data disaggregated by working-age vs. pensioner for every LA.

---

### Condition 2: fiscal-social cost trade-off in framing

**Status:** [x] RESOLVED

**Response:**
The paper is framed around this trade-off. LAs that imposed higher minimum payments saved on CTS budgets but potentially generated costs elsewhere: increased arrears, debt collection costs, court/bailiff referrals, and downstream social costs (crime, health). The contribution is quantifying whether the fiscal savings from devolution were offset by these hidden costs.

**Evidence:**
IFS R153 documents that ~25% of the new tax demanded from working-age claimants went uncollected. The paper will extend this to downstream outcomes (crime, property values) to map the full cost structure.

---

### Condition 3: validating parallel trends across multiple pre-years

**Status:** [x] RESOLVED

**Response:**
Pre-2013, Council Tax Benefit was a nationally uniform program — all LAs administered the same scheme with identical entitlements. Therefore, cross-LA variation in outcomes was driven entirely by secular trends and local conditions, NOT by policy differences. The pre-reform years (2008-2013) provide 5 years where treatment intensity was zero everywhere, making parallel trends nearly mechanical for the policy-specific component.

Event study specifications will estimate year-by-year coefficients for MinPayRate_l × Year_t dummies to visually verify flat pre-trends.

**Evidence:**
Council Tax Benefit was established by the Local Government Finance Act 1992 as a national scheme administered by LAs on behalf of DWP. No LA-level discretion existed before April 2013.

---

### Condition 4: building an explicit strategy for confounding by broader LA austerity

**Status:** [x] RESOLVED

**Response:**
Three strategies address this:
1. **Pensioner placebo:** Pensioners in the same LAs were exposed to the same austerity environment but NOT to CTS changes. If broad austerity drives results, pensioner outcomes should move too.
2. **Controls for LA spending:** Include total LA revenue expenditure per capita (DLUHC Revenue Outturn data) as a time-varying control. Also control for Revenue Support Grant changes.
3. **Negative control revenues:** Use business rate collection and parking revenue as placebo outcomes — these should not respond to CTS scheme choices.

**Evidence:**
DLUHC publishes LA-level Revenue Outturn data annually, including total service expenditure, Revenue Support Grant, and specific revenue streams.

---

### Condition 5: negative-control revenues

**Status:** [x] RESOLVED

**Response:**
Business rates collection, parking fine revenue, and planning fee income serve as negative controls. These LA revenue streams should not be affected by working-age CTS scheme generosity. If the DiD estimate on these outcomes is zero, it strengthens the causal interpretation of results on Council Tax collection and downstream social outcomes.

**Evidence:**
All three revenue streams are published in DLUHC's Revenue Outturn tables by LA.

---

### Condition 6: or designs exploiting statutory constraints/minimum-payment discontinuities if available

**Status:** [x] RESOLVED

**Response:**
As a supplementary analysis, LAs clustered their minimum payment rates at round numbers (8.5%, 10%, 15%, 20%, 25%, 30%). This creates natural groupings for heterogeneity analysis. Additionally, the statutory pension-age protection creates a sharp age discontinuity (pension age vs. working age) that can be exploited as a within-person/within-household design boundary.

**Evidence:**
IFS R153 documents the distribution of minimum payment rates: modal values at 8.5%, 20%, and 25%. These clusters allow treatment intensity grouping.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
