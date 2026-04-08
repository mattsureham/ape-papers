# Lessons: apep_1417

## Discovery
- Morocco cannabis/satellite idea (idea_1611) failed due to VIIRS raster data infrastructure (HDF5/GDAL auth). Lesson: avoid satellite raster data for V1 unless pipeline is pre-tested.
- Singapore ABSD (idea_0269) was a clean pivot: tabular API data, sharp policy variation, natural segmentation.

## Execution
- data.gov.sg search API is unreliable (returns same results regardless of query). Must paginate all datasets to find the right IDs. The poll-download endpoint returns S3 pre-signed URLs that work well.
- Few-cluster problem (3 segments) required Driscoll-Kraay SEs throughout. Newey-West failed due to time duplicates across segments.
- HDB placebo initially collinear with quarter FE; resolved by using within-HDB DiD (near-CCR towns vs. others).

## Review
- All three reviewers (codex-mini, gemini-3-flash, mistral-large) independently flagged the same three concerns: concurrent cooling measures, TWFE staggered design limitations, and rental mechanism clarity. High reviewer agreement suggests these are genuine weaknesses.
- Round 5 isolation (no concurrent LTV/TDSR changes) is the strongest single-round test; should have emphasized this earlier.
- Rental mechanism required more nuance: the fact that rents *fell* (rather than rose) is itself evidence against pure displacement, but supply-side channel (fewer investor-owned rental units) also contributes.

## Summary
Singapore ABSD is an excellent V1 topic: clean institutional variation, accessible API data, and a portable mechanism (ownership premium vs. displacement). The 60% rate is genuinely extreme and provides a unique laboratory. Main weakness is the 3-segment panel — future work could use district-level or transaction-level data.
