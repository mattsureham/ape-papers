## Discovery
- **Policy chosen:** GenAI diffusion as seniority-biased technological change — replication of Hosseini Maasoum & Lichtinger (2025) using independent public data sources
- **Ideas rejected:** (1) QCEW-only approach with AIOE exposure scores — too similar to saturated exposure-DiD literature, lacks occupation-level granularity; (2) Earnings call transcript approach — key data proprietary, shift-share design adds fragility
- **Data source:** SEC EDGAR EFTS API for GenAI adoption (10-K filings), BLS QCEW for quarterly employment, BLS OEWS for occupation structure, O*NET for seniority classification, CPS for demographics
- **Key risk:** OEWS rolling-sample smoothing limits sharp event-study identification; mitigated by using QCEW as primary time-series source. Concurrent 2022-2023 tech recession is the main confounder; planned placebo tests and industry exclusions address this.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-R1 PASS, GPT-R2 PASS, Gemini FAIL, Codex PASS)
- **Top criticism:** All 3 external reviewers flagged that parallel trends fail (event study + placebo) — the paper cannot claim a causal effect of generative AI. Industry-specific linear trends specification confirms the DiD is entirely driven by pre-existing secular trends.
- **Surprise feedback:** The industry-specific trends robustness check (R9) not only eliminates the effect but reverses the sign to positive (+0.009, t=3.45). This was unexpected but internally consistent with the event study's strong pre-trend.
- **What changed:** (1) Added permutation inference (999 permutations) confirming conventional p-values are reliable with 25 clusters; (2) Added industry-specific linear trends specification; (3) Added joint F-test for pre-trends (p=0.013); (4) Softened all causal language throughout abstract, intro, results, and conclusion; (5) Added Cameron et al. (2008) citation for cluster inference; (6) Added event study vs DiD reconciliation paragraph; (7) Removed roadmap paragraph; (8) Active voice in results section.

## Summary
- **Key lesson:** When the event study clearly violates parallel trends, lean into it — honest papers that document the pre-trend transparently and frame results as descriptive associations are more credible than papers that try to explain away identification failures.
- **What worked:** Using multiple data sources (OEWS + QCEW + SEC EDGAR) for triangulation; within-occupation heterogeneity providing the strongest result; transparent reporting of identification failures.
- **What didn't work:** Trying to get 3/4 advisor PASS was surprisingly difficult — each run found different issues. Took 8 rounds. LLM advisors are stochastic.
- **For next time:** Run industry-specific trends early in analysis, not as a late robustness check. If the pre-trend is visible in the event study, the trends specification should be a core result, not an afterthought.
