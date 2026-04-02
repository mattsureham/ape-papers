## Discovery
- **Idea selected:** idea_1377 — Lithuania i.SAF mandatory invoice reporting and VAT compliance
- **Pivoted from:** idea_2103 (patent examiner IV) — BigQuery ADC not configured; Azure QWI also unavailable
- **Data source:** Eurostat (free, no authentication) — VAT revenue, GDP, sector GVA, business demography, I-O tables
- **Key risk:** Few-cluster inference (5 countries, 1 treated) and concurrent reforms (euro adoption 2015)

## Execution
- **What worked:** Eurostat API is reliable and fast; sector-level continuous treatment design adds variation beyond the N=1 cross-country comparison; VAT gap data from CASE/EC reports is well-documented and publicly available
- **What didn't:** B2B intensity from I-O tables is a coarse proxy; pre-trends in placebo test suggest Lithuanian convergence predates the reform; exempt sectors also show positive effects, weakening the mechanism test; wild cluster bootstrap failed (fwildclusterboot type error with factor variables)
- **Review feedback adopted:** Tempered all causal language per reviewer concerns about RI p-value (0.40); added euro adoption confound discussion; acknowledged VAT gap is model-based, not admin data; reframed exempt-sector result as a limitation rather than ignoring it
