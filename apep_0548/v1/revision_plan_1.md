# Revision Plan (Stage C)

## Key Changes Made

### 1. Reframed Estimand (R1 §1A, R2 §1A, Gemini §6.1)
- Explicitly labeled estimand as "LA-level intention-to-treat effect of first licensing adoption"
- Added new subsection "Estimand and Treatment Coarseness" in methodology
- Acknowledged that LA-level design likely attenuates treatment-on-the-treated for designated neighborhoods
- Noted future work needs sub-LA treatment geography

### 2. Toned Down Parallel Trends Claims (R1 §1B, R2 §2C)
- Changed "strong support" to "consistent with—though does not prove" throughout
- Added Roth (2022) citations on pretest limitations
- Acknowledged limited power with 52 treated units across 17 cohorts
- Noted Rambachan-Roth (2023) sensitivity analysis as priority for future work

### 3. Labeled Heterogeneity as Exploratory (R1 §3B, R2 §3C)
- Flagged PRS 2021 Census measure as post-treatment for most cohorts
- Changed "consistent with capitalization mechanism" to "suggestive cross-sectional pattern"
- Noted need for pre-treatment PRS measures and heterogeneity-robust methods

### 4. Added TWFE Robustness Caveat (R1 §2B, R2 §2B)
- Added explicit note at start of Robustness section acknowledging TWFE-centered exercises
- Stated that CS-DiD variants of these checks are priority for future work

### 5. Calibrated Policy Implications (R1 §5C, R2 §5C)
- Removed strongest claims about "reassuring for policymakers"
- Acknowledged wide confidence intervals and LA-level ITT limitations
- Reframed as "preliminary evidence" rather than definitive conclusion

### 6. Improved Opening (Prose Review)
- Replaced generic first paragraph with Newham hook
- More engaging narrative arc

### 7. Added Missing References
- Roth (2022) "Pretest with Caution" — cited in parallel trends discussion
- Rambachan and Roth (2023) — cited as priority for future sensitivity analysis

### Changes NOT Made (with rationale)
- Sub-LA treatment geography: Requires ward-level designation boundary data not available
- Transaction-level hedonic models: Parquet file too large to deserialize
- Pre-treatment PRS measures: Would require 2011 Census data fetch
- CS-DiD heterogeneity: Requires substantial re-coding of analysis
- Wild cluster bootstrap: Not implemented in current code pipeline
- Proper joint pre-trend test with covariance matrix: Would require changes to R code
