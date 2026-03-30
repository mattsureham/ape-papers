## Discovery
- **Idea selected:** idea_1929 — Pharmaceutical distributor market concentration and county-level opioid supply; chose for first-order mortality stakes, 178M ARCOS transactions on Azure, and genuinely novel supply-chain angle
- **Data source:** DEA ARCOS (Azure), CDC WONDER (NCHS), ACS — Azure connection required fixing bash semicolon truncation
- **Key risk:** National share changes in the shift-share instrument capture more than just merger variation; exclusion restriction depends on mergers being exogenous to county demand

## Execution
- **What worked:** Predicted HHI instrument (quadratic function of counterfactual shares) gave strong first stage (F=75) after linear Bartik failed. Leave-one-out showed 49/49 negative signs — exceptional stability
- **What didn't:** Log specification flipped sign and was imprecise; population-weighted estimate attenuated. Marginal significance (p=0.085) limits the strength of causal claims
- **Review feedback adopted:** Softened causal language, added PDMP caveat, explained log discrepancy, acknowledged instrument limitations honestly. Did not attempt full IV redesign (V2 task)
- **Surprise finding:** Concentration reduces pills — the competitive flood mechanism inverts the popular narrative about monopoly middlemen
