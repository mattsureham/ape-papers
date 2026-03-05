# Revision Plan: apep_0185 v21 — Demographic Heterogeneity

**Parent:** apep_0185/v20
**Goal:** Add demographic heterogeneity analysis (age, education, sector) using QWI bulk data from Azure. Address reviewer feedback from v20.

## Key Changes

### New Analysis (Workstream 1)
1. **Azure QWI pipeline:** Replaced Census API fetch with Azure Blob Storage DuckDB queries for all demographic data (age × 8 groups, education × 4 levels, sector × 20 NAICS)
2. **Stratified 2SLS:** Run baseline specification separately for each demographic group
3. **Dynamic diagnostics:** Added leads/lags of instrument to test for pre-trends
4. **Job-flow subsample robustness:** Confirmed main results hold on non-suppressed subsample

### Key Findings
- **Age gradient:** FLAT (0.83–1.10, all significant) — information updating is not age-selective
- **Education gradient:** CLEAR (non-BA ~1.0 vs BA+ 0.45) — strongest mechanism evidence
- **Industry gradient:** COUNTER-INTUITIVE (retail/food smallest, mining/finance largest)
- **Dynamic diagnostics:** 1-year lead null, 2-year lead marginal (consistent with pre-announcement)

### Paper Restructuring (Workstream 2)
1. Added "Who Responds?" section (Section 9) with age, education, sector heterogeneity
2. Moved robustness tables (inference battery, IRS migration, placebos) to appendix
3. Fixed Panel A/B consistency across all tables (A=Earnings, B=Employment)
4. Updated abstract, intro, conclusion with education gradient finding
5. Softened employment magnitude claims (equilibrium multipliers, LATE caveat)
6. Labeled OLS geographic heterogeneity as descriptive
7. Added AKM inference limitation discussion
8. Removed duplicate bibliography

### Reviewer Feedback Addressed
- Dynamic diagnostics (leads/lags) — GPT, Grok, Gemini all requested
- Job-flow subsample robustness — Gemini must-fix
- Claim calibration / employment magnitude — GPT, Grok
- OLS heterogeneity labeling — GPT
- AKM inference limitation — GPT, Grok
- Mechanism language softened — GPT
