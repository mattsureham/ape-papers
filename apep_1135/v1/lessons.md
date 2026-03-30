## Discovery
- **Idea selected:** idea_2035 — National Sword's labor market effects; chosen for massive trade shock, QWI data in Azure, zero existing papers
- **Data source:** Azure QWI (county × NAICS × quarter) + UN Comtrade API — both worked smoothly
- **Key risk:** Pre-existing growth differential between high/low exposure counties

## Execution
- **What worked:** Azure DuckDB integration for QWI data (460M+ rows); Comtrade API for trade flow documentation; fixest for fast estimation with county-specific trends
- **What didn't:** First idea (patent examiner IV) failed due to BigQuery ADC credentials not being configured; pivoted quickly to waste/trade idea
- **Review feedback adopted:** Added county-specific linear trends to address pre-trend violation identified by all three reviewers; updated paper to present the 3.7-14.2% range transparently rather than claiming the headline 14.2%
