## Discovery
- **Idea selected:** idea_1949 — DEA enforcement against Cardinal Health as quasi-experiment for opioid supply chain resilience
- **Data source:** ARCOS 178.6M transactions on Azure — loaded perfectly via DuckDB aggregation queries; no API issues
- **Key risk:** Only 2 years of pre-treatment data (ARCOS covers 2006-2012); quarterly resolution gave 8 pre-periods but pre-trend concern remained

## Execution
- **What worked:** Azure data infrastructure; DuckDB in-place aggregation avoided loading 178M rows into memory; quarterly panel yielded 86K obs with 3,130 counties; waterbed decomposition is the core contribution
- **What didn't:** Census PEP API returned 404 for 2006-2009 vintages (may have changed endpoints); pre-trend in 2006 weakens causal claims; competitor responses directionally correct but not individually significant
- **Review feedback adopted:** Honest treatment of pre-trend (acknowledged as genuine threat, not spun as conservative); expanded limitations section; emphasis on state-quarter FE specification
