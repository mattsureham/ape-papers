## Discovery
- **Idea selected:** idea_1510 — ULR × Black Healthcare Wage Gap (DDD). Chosen for clean built-in counterfactual (manufacturing placebo, within-race comparison) and novel angle vs existing ULR papers.
- **Data source:** Census LEHD QWI Race-Hispanic panel — downloaded directly from Census endpoint after Azure DuckDB curl issue.
- **Key risk:** COVID overlap with 2020-2021 adoption waves; mitigated by DDD structure and Arizona pre-COVID anchor.

## Execution
- **What worked:** DDD design with full high-dimensional FE cleanly absorbed confounds. Pre-trends are uniformly clean. QWI provides exactly the right disaggregation (race × industry × state × quarter).
- **What didn't:** Azure blob access via DuckDB's `az://` protocol has a curl/libcurl compatibility bug on this machine (both R and Python DuckDB). Workaround: direct LEHD download. Also: `EarnS` in QWI is per-worker average, not total — caught this before analysis.
- **Review feedback adopted:** (1) Moderated rhetorical claims — "definitive null" → "no detectable short-run changes"; "binding constraint doesn't hold" → "channel not operative at sector level." (2) Added NAICS 62 dilution caveat — sector includes unlicensed aides/staff. (3) Translated 0.005 log points to ~$85/month to anchor the null.
