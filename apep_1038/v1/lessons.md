## Discovery
- **Idea selected:** idea_0744 — The TRI measurement artifact. Selected after idea_0948 (patent examiner IV) failed due to missing BigQuery credentials, and two overlap rejections (E-Verify, Good Samaritan). The measurement artifact framing was compelling: TRI is the most-cited environmental dataset.
- **Data source:** EPA Envirofacts REST API — extremely slow for large paginated downloads (~29MB JSON per 10K row batch, all 100 columns returned with no column selection). Facility table lacks SIC codes entirely.
- **Key risk:** Whether the decomposition would be robust to alternative counterfactual assumptions. It was: all four rates gave 16.7-17.8%.

## Execution
- **What worked:** The aggregate form counts (one COUNT call per year) were fast and reliable. The accounting decomposition turned out cleaner than a DiD for this particular question. The within-facility paired test (t=-5.56) perfectly validated the counterfactual assumption.
- **What didn't:** The EPA API was unreliable for large paginated downloads. Multiple concurrent processes blocked each other. SIC codes are NOT available from the Envirofacts facility table — had to pivot to first-reporting-year treatment classification.
- **Review feedback adopted:** Fixed DiD → decomposition language mismatch in introduction. Acknowledged release quantity limitation. Tightened causal claims to match the accounting nature of the analysis.
