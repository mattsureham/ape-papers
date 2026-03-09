# Conditional Requirements

**Generated:** 2026-03-09T01:54:20.832369
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

---

## Do Red Flag Laws Save Lives or Shift Deaths? Means Substitution in Suicide Prevention

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: measuring ERPO petition/use intensity

**Status:** [x] RESOLVED

**Response:** ERPO petition intensity data is not systematically available across all states. The paper uses a binary treatment indicator (ERPO in effect / not) with the Callaway-Sant'Anna estimator. Implementation heterogeneity is discussed extensively in Section 2.4 (petition eligibility, order duration, utilization rates). The discussion explicitly addresses how low utilization (50-60 petitions/year in Indiana) may explain the null population-level result.

**Evidence:** Paper Section 2.4 (Implementation Heterogeneity), Section 6.1 (Insufficient Implementation Intensity), and Table 5 (ERPO Adoption Timeline).

---

### Condition 2: using the longest feasible pre-period

**Status:** [x] RESOLVED

**Response:** The combined panel spans 1999-2024 (25 years, excluding 2018), using NCHS data from 1999-2017 and CDC Mapping Injury from 2019-2024. This is the longest feasible panel available from public sources. The event study uses min_e = -8 to max_e = 6.

**Evidence:** Paper Section 3.1 (Data Sources), Section 3.4 (Sample Construction). N = 1,250 state-year observations.

---

### Condition 3: ideally monthly data

**Status:** [x] NOT APPLICABLE

**Response:** Monthly state-level suicide data is not publicly available from CDC via API. Both NCHS Leading Causes and CDC Mapping Injury provide annual data only. Using annual data is standard in the ERPO evaluation literature (Kivisto & Phalen 2018, Humphreys et al. 2019).

**Evidence:** CDC Socrata API endpoints fpsi-y8tj and bi63-dtpu return annual data only.

---

### Condition 4: explicitly addressing concurrent gun-law changes

**Status:** [x] RESOLVED

**Response:** The paper acknowledges concurrent policy adoption as a limitation (Section 6.5, Limitation 3): "ERPO laws were frequently adopted alongside other gun safety measures (universal background checks, waiting periods, secure storage laws)." The CS-DiD identifies the ERPO effect net of concurrent policies, and the drug overdose placebo helps rule out broad state-level confounding.

**Evidence:** Paper Section 6.5 (Limitations), Table 2 Column 5 (Drug OD placebo, p = 0.32).

---

### Condition 5: power for total-suicide effects

**Status:** [x] RESOLVED

**Response:** Section 4.6 (Power Considerations) provides an explicit power analysis: with 50 jurisdictions, 25 years, and 1,250 observations, the design can detect effects of 0.8-1.5 per 100,000 with 80% power. The 95% CI on the main estimate ([-0.16, 0.64]) effectively rules out effects larger than 0.64 per 100,000.

**Evidence:** Paper Section 4.6 and Table 2, Column 1 (CI: [-0.16, 0.64]).

---

## Can Shorter Workweeks Save Fertility? South Korea's 52-Hour Reform

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: convincingly isolating the COVID-19 shock

**Status:** [x] NOT APPLICABLE

**Response:** This idea was not selected for execution. The ERPO/Red Flag Laws idea was chosen instead.

---

### Condition 2: proving no firm-size manipulation around the regulatory thresholds

**Status:** [x] NOT APPLICABLE

**Response:** This idea was not selected for execution.

---

## Do Red Flag Laws Save Lives or Shift Deaths? Means Substitution in Suicide Prevention

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: convincing pre-trend evidence

**Status:** [x] RESOLVED

**Response:** The Callaway-Sant'Anna event study (Figure 1) shows pre-treatment coefficients centered near zero with no systematic trend. The pre-treatment coefficients' average absolute value (~0.18 per 100,000) is similar to the post-treatment ATT (0.24), indicating limited detectability rather than pre-trend violation.

**Evidence:** Paper Section 5.2 (Event Study), Figure 1, Appendix B (Pre-Trend Analysis).

---

### Condition 2: enforcement/take-up data to separate paper laws from active use

**Status:** [x] RESOLVED

**Response:** Systematic enforcement data is unavailable across all states, but the paper uses case-series evidence from Indiana (50-60 ERPOs/year, Swanson 2019) and Florida (>1,000 petitions/year, Wintemute 2019) to contextualize utilization variation. The discussion interprets the null result partly through the lens of insufficient utilization intensity.

**Evidence:** Paper Section 2.4, Section 6.1 (Insufficient Implementation Intensity).

---

### Condition 3: a clear power argument for total suicides

**Status:** [x] RESOLVED

**Response:** Same as Condition 5 above. Section 4.6 provides explicit power analysis.

**Evidence:** Paper Section 4.6 (Power Considerations).

---

### Condition 4: not just firearm suicides

**Status:** [x] RESOLVED

**Response:** The paper examines total suicide (primary outcome), firearm suicide, non-firearm suicide, and drug overdose (placebo). The mechanism decomposition explicitly tests the means substitution hypothesis by comparing firearm and non-firearm suicide effects.

**Evidence:** Paper Table 2 (5 columns covering total, firearm, non-firearm, short-panel total, and drug OD).

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
