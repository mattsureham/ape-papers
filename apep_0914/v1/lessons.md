## Discovery
- **Idea selected:** idea_1342 — AAA cotton displacement and Black occupational mobility, chosen for data-in-hand (Azure MLP panel), massive microdata (2.2M individuals), and DDD design bridging New Deal + Great Migration literatures
- **Data source:** IPUMS MLP triple-linked 1930-1940-1950 panel from Azure — had to fix Azure connection string parsing (semicolons in .env truncated value)
- **Key risk:** Treatment variable (county farm share) is a proxy for AAA exposure, not actual AAA payment data

## Execution
- **What worked:** The MLP panel delivered exactly what was promised — 4.5M linked individuals in cotton-belt states, clean occupational score variables across all three waves. DuckDB + Azure was efficient for out-of-core querying.
- **What didn't:** The original hypothesis was wrong. Expected negative DDD ("occupational scarring") but found a positive, significant coefficient (+0.57, p=0.008). Had to completely reframe the paper from "scarring" to "convergence through migration."
- **Review feedback adopted:** Tempered causal language about AAA specifically (all three reviewers flagged farm share as proxy, not policy shock). Added pre-trend limitation paragraph. Reframed placebo result honestly (could be OVB, not just spillovers). Added migration selection caveat. Paper is epistemically more honest while retaining the compelling core finding.
