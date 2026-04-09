# Lessons: apep_1442 v1

## Discovery
- Inspector leniency IV in England's planning system is a textbook-promising setting (quasi-random assignment, national pool, binary outcomes) but the publicly scrapable sample is too small for the design to work.
- The PINS Appeal Case Portal yields ~2,500 decided cases from a 140K ID range — the portal is sparse, not dense.

## Execution
- **Save intermediate data immediately.** The first scraping run crashed at MHCLG DNS resolution, losing all in-memory PINS data. Adding `fwrite()` after each phase prevented data loss on the second run.
- **Inspector extraction from PDFs works well** (79% success rate) but yields thin per-inspector samples when the case universe is small.
- **Small-sample mean reversion** in LOO leniency scores is not just a minor bias — it can flip the sign of the first stage entirely. With median 2.2 cases/inspector, the LOO score is noise, not signal.
- **Lagged leniency** is a powerful diagnostic: it aggregates over a full year rather than 2-3 cases, confirming that inspector heterogeneity is real even when contemporaneous LOO fails.
- The LPA-to-Land-Registry merge failed (0% match on district names). Future UK papers should build a crosswalk between LPA names and ONS district codes.

## Review
- All three reviewers flagged the pivot from housing outcomes to methodological diagnostic. The paper's honest framing of a null/negative result was well-received but needed sharper positioning.
- Table 3 (reduced form) had a serious bug — 5× duplicated rows per quintile. Caught during review-driven revision.

## Summary
A well-executed negative result. The contribution is methodological: demonstrating small-sample bias in examiner designs. The setting is promising for future work with the full 100K+ case archive.
