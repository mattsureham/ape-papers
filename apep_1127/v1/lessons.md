## Discovery
- **Idea selected:** idea_2001 — Oklahoma injection well seismicity regulation. Chose for dramatic effect size (97% decline), clean policy lever, novel economics contribution (geoscience literature only), and staggered DiD design.
- **Data source:** USGS ComCat API — flawless, returned 9,850 Oklahoma events in seconds. Spatial join to counties via Census TIGER worked at 96.5% match rate.
- **Key risk:** Distinguishing regulatory from market forces (oil price collapse). Addressed through WTI interaction, event study persistence test, and Kansas replication.

## Execution
- **What worked:** The TWFE sign flip (+0.14 vs CS -1.18) was an unexpected bonus — it became the paper's methodological contribution. USGS API and FRED data are as clean as it gets. The "regulatory ratchet" mechanism framing gave the paper a memorable name.
- **What didn't:** Binary county treatment is coarser than ideal. Well-level OCC data could construct continuous dose-response, but that's a V2 enhancement. Kansas has only 5 treated counties — too few for CS, so it's qualitative replication only. The SDE table Panel B uses biased TWFE estimates for heterogeneity.
- **Review feedback adopted:** Strengthened pre-trends discussion (reactive regulation framing), added binary-treatment limitation paragraph, clarified monthly vs quarterly aggregation, improved Kansas replication description acknowledging TWFE bias.
