## Discovery
- **Idea selected:** idea_1851 — Argentina SAS firm registration ban. Chosen for near-complete regulatory shutdown (14K→near-zero) creating unusually clean variation.
- **Data source:** Registro Nacional de Sociedades (datos.jus.gob.ar) — CKAN API worked perfectly, 13M+ rows across 2019-2026 annual ZIPs.
- **Key risk:** Ban coincided with COVID; needed firm-type placebo to separate effects.

## Execution
- **What worked:** The geographic design (CABA vs. provinces) was cleaner than the original staggered idea. The accounting identity (SAS loss = SA gain + SRL gain + net loss) holds exactly, which is compelling.
- **What didn't:** SAS ramp-up (2017-2019) creates noisy pre-trends in the full sample. Restricting to 2019+ fixes this but shortens the pre-period.
- **Data surprise:** National SAS didn't collapse — only CABA (where IGJ has jurisdiction). Other provinces' registries were unaffected. This turned a weakness into a strength.
- **Review feedback adopted:** Added event study table in appendix, softened overclaiming language ("cleanest experiment" → "compelling"), clarified data construction (cumulative snapshots), documented that other firm types (coops, etc.) show no systematic ban response.
