# Code Advisor Review - Codex-Mini

**Role:** Code reviewer for academic publication standards
**Model:** openai/gpt-5.1-codex-mini
**Paper:** paper.pdf
**Timestamp:** 2026-04-02T01:51:00.641673
**Route:** OpenRouter + code bundle
**Files reviewed:** 00_packages.R, 01_fetch_data.R, 02_clean_data.R, 03_main_analysis.R, 04_robustness.R, 05_figures.R, 06_tables.R
**Tokens:** 23814 in / 1528 out
**Response SHA256:** 943ccd17033391c9

---

1. **File:** 05_figures.R  
   **Line(s):** 147-167  
   **Code:**
   ```r
   } else {
     # Fallback from analysis output
     es_pooled <- data.table(
       rel_year = c(-5, -4, -3, -2, -1, 0, 1, 2, 3, 4),
       estimate = c(-2.10, 2.23, 0.93, 0.05, 0, 0.07, 0.04, 0.32, 0.82, 3.81),
       se       = c( 1.20, 0.58, 0.48, 0.35, 0, 0.51, 0.48, 0.48, 0.50, 1.24)
     )
   }
   ```
   **Issue:** This block inserts hard-coded event-study coefficients and standard errors instead of deriving them from the actual Callaway–Sant’Anna/Sun‑Abraham model output. The replication standards explicitly forbid using manually entered regression results, because they do not originate from the real observational data and hence cannot be replicated.  
   **Fix:** Remove the hard-coded fallback entirely. Only plot the pooled event study when `sa_es` is non-null (i.e., when the estimation succeeded). If the model cannot be estimated, skip the figure or signal the failure rather than inventing numbers. Ensure all reported coefficients and SEs are extracted directly from the corresponding model objects (`coeftable`, `coef`, `vcov`, etc.).  

**CODE ADVISOR VERDICT: FAIL**