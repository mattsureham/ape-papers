## Discovery
- **Idea selected:** idea_1767 — Chain pharmacy dual SNAP-pharmacy closures and Medicaid utilization
- **Data source:** T-MSIS (227M rows, local Parquet) + NPPES (8.5M providers) — both pre-downloaded
- **Key risk:** J-codes capture injectable drugs, not all prescriptions; pharmacy outcome is partly mechanical

## Execution
- **What worked:** Billing-based closure detection (1,365 NPIs stopped billing) was far more effective than NPPES deactivation dates (only 3 found). Targeted HCPCS-code-first queries for ED visits avoided OOM on full T-MSIS.
- **What didn't:** SNAP retail data not integrated (USDA historical data not readily available via API). Sun-Abraham event study too computationally expensive; switched to binned approach.
- **Review feedback adopted:** Added explicit acknowledgment that pharmacy outcome is partly mechanical (chain billing drops when chain exits). Expanded limitations section to cover J-code specificity, billing ≠ closure, provider vs beneficiary ZIP. Toned down title and abstract claims.

## Key Insight
The asymmetry is the real finding: massive chain pharmacy service disruption with no detectable ED spillover. Reviewers correctly noted this is narrower than "pharmacy deserts don't affect ERs" — it's specifically about chain Medicaid billing cessation and J-code services. A stronger paper would measure total ZIP pharmacy access (all providers) and validate closures against external sources.
