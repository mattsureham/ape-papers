## Discovery
- **Idea selected:** idea_0591 — Singapore EIP and minority housing discount. Chose for RDD design (higher tournament scores), 227K microdata, and testing the contact hypothesis.
- **Data source:** data.gov.sg (HDB resale) + SingStat Table Builder (Census 2020). The data.gov.sg API has aggressive rate limits (~1 req/90s unauthenticated); SingStat has no rate limits.
- **Key risk:** Subzone-vs-block measurement mismatch for RDD running variable.

## Execution
- **What worked:** The hedonic convergence test is the strongest result — a 33% decline in the minority gradient (p=0.004) over 2017-2026. Full 10-year panel was essential; the preliminary 2017-2020 data showed no trend.
- **What didn't:** The RDD at the Indian 10% threshold failed due to discrete running variable (only 24 planning areas). Block-level ethnic data not available via public APIs. Had to abandon RDD and rely on hedonic design.
- **Review feedback adopted:** Tempered causal language (gradient is "descriptive" not causal), acknowledged 24-cluster inference concern, fixed R² display issues in tables, added explicit discussion of omitted variable bias and the preference vs. constraint channel distinction.
- **Key lesson:** When working with Singapore data, start with SingStat Table Builder (no rate limits) and use data.gov.sg as backup. Also: always get the full sample before drawing conclusions — the convergence only showed up with 10 years of data.
