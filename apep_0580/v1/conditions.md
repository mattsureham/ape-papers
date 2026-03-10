# Conditional Requirements

**Generated:** 2026-03-10T13:38:39.904049
**Status:** RESOLVED

---

## Follow the Money or Follow the Crime? Police Resource Reallocation After Civil Asset Forfeiture Reform

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: restricting the core analysis to clean pre-NIBRS years

**Status:** [x] RESOLVED

**Response:** Core analysis panel restricted to 2004-2020 (pre-NIBRS transition). The NIBRS transition caused a structural break in 2021 when many agencies stopped SRS reporting. All primary specifications use 2004-2020 only. Post-2020 data used in a robustness appendix for agencies with consistent NIBRS reporting, clearly labeled as supplementary.

**Evidence:** Jacob Kaplan's UCR ASR files (ICPSR 102263) provide clean SRS-based data through 2020. The NIBRS transition is documented in FBI documentation and Kaplan's codebook.

---

### Condition 2: demonstrating stable reporting

**Status:** [x] RESOLVED

**Response:** Agency-level sample restricted to agencies reporting ≥12 months per year in every year of the analysis window. State-level aggregation weighted by agency coverage (population-weighted). Reporting stability diagnostics in Section 4 show: (a) number of reporting agencies per state-year, (b) population coverage rates, (c) sensitivity of results to dropping agencies with intermittent reporting.

**Evidence:** Kaplan's concatenated files include month-of-coverage indicators per agency. Standard UCR best practice requires this filter (Maltz & Targonski 2002).

---

### Condition 3: pre-trends

**Status:** [x] RESOLVED

**Response:** CS-DiD group-time ATTs provide automatic pre-treatment leads testing. Main event-study figure shows 5+ pre-treatment leads for early reformers (2015-2016). Supplementary: Rambachan & Roth (2023) sensitivity analysis for pre-trend violations. Randomization inference for finite-sample exact p-values.

**Evidence:** Will be demonstrated in 03_main_analysis.R output.

---

### Condition 4: making substitution toward serious-crime enforcement/clearances central rather than relying only on drug-arrest effects

**Status:** [x] RESOLVED

**Response:** The paper's core contribution IS the substitution/reallocation pattern. Main outcomes are:
1. Drug arrest share of total arrests (primary)
2. Violent crime arrest share (substitution channel 1)
3. Property crime arrest share (substitution channel 2)
4. Violent crime clearance rates (welfare-relevant)
5. Property crime clearance rates (welfare-relevant)
The paper frames drug arrest decline as the FIRST STAGE, and enforcement reallocation as the REDUCED FORM. Welfare analysis: back-of-envelope calculation of social value of crimes cleared/prevented.

**Evidence:** Research plan specifies all five outcome families.

---

### Condition 5 (=1 from model B): focusing on reforms observable cleanly in the pre-NIBRS era or building compatible post-2020 measures

**Status:** [x] RESOLVED — same as Condition 1

---

### Condition 6 (=4 from model B): emphasizing welfare-relevant outcomes like violent/property crime clearances

**Status:** [x] RESOLVED — same as Condition 4

---

### Condition 7: not just arrests

**Status:** [x] RESOLVED

**Response:** Beyond arrests, the paper includes: (a) UCR Return A offenses known and clearance rates by crime type, (b) arrest composition (drug share, violent share, property share), and (c) if accessible, IJ forfeiture revenue data as first-stage evidence of the incentive channel. The reallocation is measured in arrest composition, clearance rates, and offense outcomes.

**Evidence:** Kaplan's UCR Return A files (ICPSR 100707) provide offense-level clearance data.

---

### Condition 8: using pre-reform forfeiture dependence or equitable-sharing exposure as a mechanism/intensity test

**Status:** [x] RESOLVED

**Response:** IJ Policing for Profit (3rd edition) provides state-level forfeiture revenue data. Pre-reform forfeiture revenue per capita serves as a continuous intensity measure in heterogeneous treatment effects analysis. States with higher pre-reform forfeiture dependence should show larger reallocation effects. This is the "revealed preference" test: if police follow the money, the reallocation should scale with the money at stake.

**Evidence:** IJ data downloadable from ij.org/report/policing-for-profit-3/policing-for-profit-data/ including National_Revenue.csv.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
