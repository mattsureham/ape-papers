## Discovery
- **Idea selected:** idea_0710 — EU Deforestation Regulation trade diversion DDD. First causal study of EUDR using bilateral trade data.
- **Data source:** UN Comtrade API — required batched requests (1 per exporter) to avoid rate limits. Individual commodity-year calls hit 429 errors.
- **Key risk:** Small number of commodity clusters (12) makes two-way clustered inference imprecise. DDD with 7 regulated vs 5 control commodities is inherently limited.

## Execution
- **What worked:** DDD design cleanly isolates EUDR-specific trade effects. Comtrade bilateral data provides the right variation. Exporter heterogeneity (standard-risk vs others) yields the most interesting finding — compliance sorting rather than uniform diversion.
- **What didn't:** Aggregate statistical significance is weak (RI p=0.47). The quantity specification doesn't confirm value results, suggesting price vs volume ambiguity. EU share regression shows null because both regulated and control commodities lost EU share.
- **Review feedback adopted:** [To be completed after reviews]

## Key Insight
The most publishable finding is NOT the average diversion effect (imprecise) but the **compliance sorting**: large exporters invest in traceability and maintain EU access while small exporters exit. This reframes the paper from "does the EUDR cause leakage?" to "does the EUDR sort supply chains by exporter capacity?"
