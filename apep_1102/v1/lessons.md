## Discovery
- **Idea selected:** idea_1984 — Dosage-strength composition of opioid shipments, a novel empirical object in the ARCOS literature
- **Data source:** DEA ARCOS transaction-level records (178.6M transactions) on Azure — no API issues, pre-processed in Parquet
- **Key risk:** Few clusters (3 states) makes conventional inference challenging; reliance on event study dynamics rather than p-values

## Execution
- **What worked:** Azure data access via Python DuckDB (R's DuckDB had connection string parsing issues). Pill-weighted specification revealed the real story hidden in unweighted results. The weighted vs unweighted comparison is itself a finding — it maps the geographic footprint of diversion.
- **What didn't:** Parallel pre-trends don't hold over the full 2006-2012 period because the pill mill boom itself created divergent composition trends. This is expected and interpretable, but complicates the textbook DiD framing.
- **Review feedback adopted:** (1) Switched from state-level to county-level clustering (3→288 clusters), fixing unreliable SEs. (2) Added county-specific linear trends, which absorb the pill mill boom and show an even larger reversal (-0.212). (3) Added time-placebo test with fake July 2009 treatment. (4) Clarified the pill-weighted estimand in the text. All three reviewers flagged the same core issues; the consistency was reassuring.
