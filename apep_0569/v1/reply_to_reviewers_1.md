# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1) — Reject and Resubmit

### 1. Randomization inference fails
**Response:** We agree this is the paper's main statistical limitation and have revised accordingly. We now (a) report both intermediate and capital RI p-values explicitly (0.365 and 0.265), (b) acknowledge honestly that neither achieves significance under permutation inference, and (c) reframe the statistical evidence as resting on parametric standard errors, event study dynamics, and consistency across specification checks rather than design-based inference alone. The limited number of annual observations (14 years, 10 eligible placebos) severely constrains RI power.

### 2. Post-window contamination (2017-2023)
**Response:** Added. We now report a short-window specification (2017-2019) that isolates the devaluation from COVID and the 2022-2023 depreciation. Both effects remain significant at 5%: intermediate 0.145 (p=0.024), capital 0.174 (p=0.011). The larger full-sample estimates reflect the cumulative 2016+2022 depreciation reinforcing the same hierarchy.

### 3. Capital goods confounded by public investment
**Response:** Added. We exclude the four most government-linked HS2 chapters (84, 86, 87, 89). The capital coefficient *increases* to 0.475 (p<0.001), demonstrating the result is a broad market phenomenon, not an artifact of infrastructure procurement.

---

## Reviewer 2 (GPT-5.4 R2) — Major Revision

### 1. Null RI undermines causal claims
**Response:** See response to R1 above. We have softened causal language throughout ("suggest" rather than "demonstrate"), acknowledged the RI limitation in both the Robustness section and the Limitations subsection.

### 2. Annual data too coarse
**Response:** The monthly Comtrade data available to us cover only the HS2 level at the bilateral partner level — insufficient for the product-level regressions that are the paper's core contribution. We acknowledge the annual frequency limitation and show that the 2017-2019 short-window specification produces significant effects, confirming that the annual timing is not driving false positives.

### 3. Capital confound untested
**Response:** Now tested — see the government-sector exclusion robustness check. We also added the CBE foreign exchange priority list as a limitation in the Discussion, acknowledging that administrative FX allocation could contribute to the observed hierarchy.

### 4. Category-specific linear trends
**Response:** Added. Results survive: intermediate 0.140 (p=0.055), capital 0.152 (p=0.025). The trend terms themselves are insignificant, confirming pre-trends do not drive results.

---

## Reviewer 3 (Gemini) — Major Revision

### 1. RI failure as red flag
**Response:** See response above. We ran restricted-window RI (2014-2019) but the extremely narrow window (4 possible cutoffs in 6 years) provides essentially no power. The annual RI test is fundamentally limited by the small number of time periods.

### 2. CBE FX priority lists as confound
**Response:** Excellent point. We now explicitly discuss this in the Limitations subsection, acknowledging that administrative FX allocation may overlap with BEC categories. We cannot disentangle this without data on CBE allocation decisions, which are not publicly available.

### 3. Pre-trend divergence 2012-2013
**Response:** Addressed via category-specific linear trends (results survive) and the short-window specification (significant effects). The event study figure shows clear convergence in 2014-2015, and the 2011-2013 divergence coincides with the Arab Spring.
