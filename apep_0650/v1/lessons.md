## Discovery
- **Idea selected:** idea_0040 — Minimum wage effects on firm dynamics using QWI border-county pairs. Chosen for first-order stakes, massive sample, gold-standard identification, and novel decomposition of canonical null.
- **Data source:** QWI via Azure (6.4M rows for border counties), Vaghul-Zipperer MW data (Stata format from GitHub releases), Census county adjacency file
- **Key risk:** QWI noise infusion could attenuate estimates; within-pair MW variation might be limited for some pairs

## Execution
- **What worked:** The QWI data from Azure was clean and ready; the border-pair construction was straightforward; the firm dynamics decomposition yielded genuinely interesting results (net JC decline significant at 5%, hiring/separation rates declining)
- **What didn't:** Census adjacency file URL changed (2024 version 404'd, had to use 2015). Vaghul-Zipperer CSV no longer available (switched to Stata from GitHub releases). DuckDB IN clause failed with 1,186 county FIPS — had to query all counties and filter in R. State-quarter trend specification (state_fips^time_index) was over-saturated in fixest.
- **Review feedback adopted:** Fixed coefficient interpretation in text (0.009 vs 0.0889 confusion resolved with footnote explaining semi-elasticity). Added back-of-envelope magnitude calculation (200 fewer net jobs per county per quarter). Strengthened inference discussion noting 113-cluster limitations. Acknowledged need for event-study as future work.
- **Key lesson:** For V1, the border-pair design with QWI is powerful but reviewers uniformly want pre-trend event studies. Future revisions should include formal event-study plots.
