## Discovery
- **Idea selected:** idea_0327 — Fornero pension reform and age-specific mortality. Chose for vivid outcome (mortality), sharp identification (sudden reform, gender dose-response), and publicly available Eurostat data.
- **Data source:** Eurostat REST API (demo_r_magec, demo_r_pjangroup, lfst_r_lfe2emprt). No API keys needed.
- **Key risk:** Only 21 NUTS2 regions → cluster inference concern. Realized employment bite potentially endogenous.

## Execution
- **What worked:** Gender DDD is highly significant (+0.006, p<0.001) and provides within-region identification when simple DiD fails (placebo ages show similar pattern). Eurostat `demo_r_magec` has single-year-of-age data from 1990 — use this, not `demo_r_magec3` which only starts 2013.
- **What didn't:** Simple DiD confounded by regional mortality trends (placebo on 45-54 rejects, p=0.01). This actually makes the paper stronger — it motivates the DDD.
- **Review feedback adopted:** Softened causal language, acknowledged cluster inference concern, noted endogeneity of realized bite, flagged cause-of-death decomposition as missing but addressable in V2.
