## Discovery
- **Idea selected:** idea_2171 — UK FCA payday lending price cap, chosen for portable mechanism ("supply destruction multiplier"), clear institutional shock, and natural two-phase exit separation
- **Data source:** FCA regulatory publications (PSD006, FS17/2, Register), BoE Statistical Bulletin, Companies House — BoE API returned HTML errors, used published table values instead
- **Key risk:** Aggregate time series limits causal inference; only 12 regions × 8 post-cap quarters in PSD006

## Execution
- **What worked:** The supply destruction multiplier (8-13x) is a striking, legible empirical object. Phase separation between cap-driven and compensation-driven exits is clean and intuitive. The story arc — regulatory prediction vs reality — works well for framing.
- **What didn't:** The idea manifest promised a staggered firm-exit event study with regional variation that wasn't feasible with available data. FCA Register API is a Salesforce app, not a clean data API. Regional analysis is underpowered without pre-cap regional data.
- **Review feedback adopted:** Simplified Table 2 specification (removed phase-specific trends that produced confusing positive coefficients), softened causal language throughout, expanded limitations section. Three reviewers all flagged the descriptive vs causal gap — honest about this in the paper.
