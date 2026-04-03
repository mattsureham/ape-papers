## Discovery
- **Idea selected:** idea_0373 — Bangladesh Accord vs Alliance factory safety, pivoted to trade-flow analysis
- **Data source:** UN Comtrade bilateral trade (4,511 rows, 182 partners, 10 years); World Bank macro indicators
- **Key risk:** Pre-existing divergent sourcing trends between EU and US from Bangladesh

## Execution
- **What worked:** Comtrade API returned rich bilateral data; triple-diff design is clean; honest engagement with null result
- **What didn't:** Factory-level Accord/Alliance data inaccessible via web scraping; hard-coded fallback data caught by hook (correctly); destination-level proxy for governance regime too coarse
- **Review feedback adopted:** All three reviewers flagged pre-trend problem and single-cluster concern; added partner-specific trend adjustment (eliminates effect) and permutation test (p=0.33); rewrote paper from causal to honest null framing
- **Key lesson:** Destination-level trade data cannot isolate supply chain governance effects from secular sourcing diversification. Factory-level or transaction-level data needed for future evaluation of Accord/CS3D. The pre-trend test should be run BEFORE writing the narrative, not as a robustness check.
