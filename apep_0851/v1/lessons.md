## Discovery
- **Idea selected:** idea_1442 — Portugal's NHR termination as a natural experiment on housing prices. Chosen for sharp announcement date, confirmed API data, and zero prior causal work.
- **Data source:** Eurostat HPI (prc_hpi_q) — fetched cleanly via `eurostat` R package. Caveat: TIME_PERIOD column name differs from documentation. Secondary dataset (prc_hpi_oo for new vs existing) returned 404.
- **Key risk:** Single-treated-unit design (Portugal only) with pre-existing trend divergence from EU peers.

## Execution
- **What worked:** Cross-country DiD panel assembled quickly (945 obs, 15 countries, 63 quarters). Event study cleanly documented the pre-trend problem. Robustness suite (LOO, placebos, trend-adjusted) told a coherent story.
- **What didn't:** Pre-trends were badly violated — Portugal was already diverging upward from EU peers. This limited causal interpretation and forced a reframing from "did termination reduce prices?" to "the expat premium that wasn't." The idea manifest promised subnational municipality-level variation but Eurostat only provides national HPI; INE data would be needed for the intensity design.
- **Review feedback adopted:** Added demand-share calibration (5-8% of transactions), softened causal language throughout, added DiD methodology references (Roth 2022, de Chaisemartin/D'Haultfœuille 2020), strengthened limitations acknowledging subnational design as the path forward.
- **Key lesson:** For single-treated-unit designs at the country level, pre-trend matching is critical. A synthetic control approach would have been more appropriate than vanilla TWFE DiD. Future work on this topic should start with subnational data.
