## Discovery
- **Idea selected:** idea_0854 — UK charity bunching at audit thresholds, chosen for clean bunching design with two regulatory discontinuities and publicly downloadable data
- **Data source:** Charity Commission for England & Wales register (Azure blob storage) — download worked perfectly via ZIP files, 228MB annual return history
- **Key risk:** Round-number effects confounding bunching at £25K — confirmed by placebo tests

## Execution
- **What worked:** Data fetch was straightforward (public bulk download). The £1M bunching result is very clean (50% density drop, b̂ = 0.81). Dose-response across thresholds is the strongest identification.
- **What didn't:** OSCR (Scotland) data could not be downloaded programmatically (HTTP error on form-based download). The £25K bunching is confounded by round-number effects (placebos at £20K/£30K produce similar magnitudes). The 2022 reform test is inconclusive — post-reform bunching at £25K actually increased.
- **Review feedback adopted:** (1) Acknowledged round-number confound at £25K honestly; (2) Reframed paper around £1M as primary finding with dose-response as key identification; (3) Added year-by-year evidence; (4) Acknowledged Scotland data limitation; (5) Made reform test discussion more transparent about ambiguity.

## Key Lessons
- For bunching papers, always check placebo thresholds at round numbers FIRST — if they show similar bunching, the regulatory interpretation at the lower threshold is fragile
- The dose-response across thresholds (comparing two regulatory cutoffs with different compliance costs) is a powerful identification strategy that survives the round-number critique
- UK Charity Commission data is excellent: universe coverage, exact £ amounts, daily updates, public download
- Data coverage changes (12K → 155K returns in 2020) must be addressed upfront, not buried in robustness
