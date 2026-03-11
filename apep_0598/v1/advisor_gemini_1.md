# Advisor Review - Gemini-3-Flash

**Role:** Academic advisor checking for fatal errors
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T14:42:42.234350
**Route:** Direct Google API + PDF
**Paper Hash:** 99c21c6547cfe19a
**Tokens:** 21438 in / 754 out
**Response SHA256:** 37038254c0dc8e19

---

I have reviewed the draft paper "Forced Into the Light: Capital Controls and the Accidental Formalization of Greece’s Shadow Economy" for fatal errors. Below is my assessment.

### 1. DATA-DESIGN ALIGNMENT
*   **Treatment Timing vs Coverage:** The paper studies capital controls imposed in June/July 2015. The Greek data series for retail turnover extends to November 2023 (p. 7, 34). The VAT analysis covers 2008–2022 (p. 10). The data coverage is sufficient to observe both pre-treatment and post-treatment periods.
*   **Post-treatment Observations:** In the SCM analysis (Table 5, Fig 1) and DiD analyses (Table 4, Table 8), there are clear post-treatment observations.
*   **Cutoff Data:** For the SCM (Fig 1), data exists on both sides of the June 2015 boundary.

### 2. REGRESSION SANITY
*   **Standard Errors:** Across Tables 4, 7, and 8, standard errors are proportional to the coefficients (e.g., Table 4: $\hat{\beta} = -61.856$, SE = 10.533). There are no enormous SEs (>1000) or SEs that are 100x the coefficient.
*   **Coefficients:** While the $\hat{\beta}$ of -61.856 in Table 4 (Continuous Cash Share) looks large, the note on p. 16 explains this is evaluated against a 0 to 1 scale (percentage points), and the interquartile range effect (21.7 index points) is within the plausible range for an index base of 100. The VAT/GDP coefficient of 12.4 (Table 8) is also plausible for an index-based outcome.
*   **Impossible Values:** No negative $R^2$ or negative SEs are reported. No "NA" or "Inf" values appear in the result columns.

### 3. COMPLETENESS
*   **Placeholder Values:** I scanned the text and tables for "TBD", "PLACEHOLDER", or "XXX". None were found.
*   **Missing Elements:** All regression tables include N, coefficients, and standard errors. Figures are numbered and correctly referenced in the text.
*   **Analysis reporting:** Robustness checks mentioned (Wild cluster bootstrap, Leave-one-out) are reported in Section 7 and the Appendices (Tables 9 & 10).

### 4. INTERNAL CONSISTENCY
*   **Numbers Match:** The 14.2% drop for fuel retail cited in the Abstract matches the value in Table 2 (p. 12). The SCM gap of 10.43 cited on p. 3 matches Table 5 (p. 19).
*   **Timing Consistency:** Treatment onset is consistently identified as June/July 2015 across all text and figures.
*   **Sample Consistency:** The donor pool (14 countries) is consistent between the Data section (p. 9) and the SCM results. The sector-level panel (501 observations: 3 sectors $\times$ 167 months) is consistent between the Data section (p. 34) and Table 4 (p. 16).

**ADVISOR VERDICT: PASS**