## Discovery
- **Policy chosen:** Malaysia's 2018 GST-to-SST switch — uniquely clean sequential tax removal/reimposition with product-level heterogeneity, enabling asymmetric pass-through test
- **Ideas rejected:** N/A (pinned idea from database, idea_0035)
- **Data source:** OpenDOSM CPI 4-digit Parquet files — confirmed accessible, no API key, 19,493 observations
- **Key risk:** Product classification (GST standard-rated vs zero-rated/exempt; SST coverage) must be constructed from legislation, not observed in data. Misclassification would attenuate estimates.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, GPT R2, Codex; Gemini FAIL on product-1321 outlier)
- **Iterations to pass:** 6 rounds — fixed asymmetry ratio (cross-spec mixing), placebo sign contradiction, treatment definition inconsistency, April→June placebo date, Panel C empty cells, pre-trend claim, section cross-reference, SE rounding, table formatting (modelsummary→manual LaTeX)
- **Top criticism:** Asymmetry ratio of 0.50 mixed coefficients from different specifications (DiD Col 1 removal + DDD Col 3 reimposition). Fixed by computing 0.44 within DDD model.
- **Surprise feedback:** Gemini persistently flagged product class 1321 outlier (coefficient >1.0 in Figure 4) as a fatal error across multiple rounds. Also flagged data dates as suspicious (2010-2026 data in a March 2026 paper).
- **Key lesson:** When reporting ratios of coefficients, always use coefficients from the same specification. Cross-specification mixing is a fatal consistency error that multiple reviewers independently catch.

## Revision (Stage C)
- **Referee verdicts:** 2 Reject-and-Resubmit (GPT R1, GPT R2), 1 Major Revision (Gemini)
- **Top concern:** Asymmetry claim overclaiming — all 3 reviewers flagged insignificant SST reimposition coefficient and missing formal symmetry test
- **Pre-trend failures:** All 3 reviewers noted F-tests reject and placebo tests significant; addressed by forthrightly acknowledging and motivating short-window as preferred
- **Key changes:** (1) Added formal Wald symmetry test (p=0.075), (2) Delta-method CIs for asymmetry ratio [-0.16, 1.03], (3) Demoted full-sample 130% PT to "descriptive", (4) Separated zero-rated vs exempt controls, (5) Bootstrap inference for DDD, (6) Added Roth/Rambachan-Roth references, (7) Softened all asymmetry language to "suggestive"
- **Key lesson:** When pre-trends reject, lead with the clean short-window specification as preferred. Frame the full-sample estimate as descriptive context, not the headline finding. This reframing was the single most impactful revision.

## Summary
- **Total production time:** ~4 hours across 2 context windows
- **Biggest bottleneck:** Advisor review (6 rounds). Manual LaTeX table generation was needed after modelsummary/tabularray compatibility issues.
- **What worked well:** OpenDOSM data was clean and required minimal processing. The DDD design is genuinely interesting. Product classification from legislation was tractable.
- **What to improve next time:** (1) Always build tables manually from the start — modelsummary→manual conversion wasted time. (2) Compute all derived quantities (ratios, CIs) within a single specification from the beginning. (3) Be honest about pre-trend failures upfront rather than softening iteratively.
