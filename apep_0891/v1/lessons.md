## Discovery
- **Idea selected:** idea_1750 — SNAP EA expiration → eviction filings. Novel outcome in a well-studied policy event.
- **Data source:** Princeton Eviction Lab ETS (S3 bulk download) + Census ACS API. ETS URL was counterintuitive (_2020_2021 suffix for current data).
- **Key risk:** Only 8 treated states had ETS coverage out of 26 early opt-outs. This 8-cluster problem severely limits power.

## Execution
- **What worked:** Data fetch was smooth after finding the correct S3 URL. CS estimator ran without issues. Dose-response analysis showed correct gradient (high-SNAP > low-SNAP).
- **What didn't:** The key finding is a sign reversal between level OLS (positive) and Poisson (negative significant). Winsorizing confirmed outlier influence. This means the "effect" is driven by high-variance Southern tracts, not a systematic causal channel. The design has an MDE of ~10.6% of SD — too large to detect plausible effects of ~$100-250/month benefit cuts.
- **Review feedback adopted:** Added winsorized specification (halves the estimate), strengthened MDE discussion, added ERAP/moratoria confounder language, justified level specification choice. Did not add event study figures (V1 format prohibits).
