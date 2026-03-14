## Discovery
- **Idea selected:** idea_0049 — Italy Fornero pension reform and capital investment response
- **Pivoted from:** idea_0139 (drug price transparency) — SDUD CSV files too large (~400MB) to download
- **Data source:** Eurostat REST API — fast, reliable, free
- **Key risk:** Only 21 NUTS2 regions; continuous treatment design

## Execution
- **What worked:** Eurostat API dimension order matters (freq, unit, sex, age, geo for employment; freq, sector, currency, nace_r2, geo for GFCF). Strong result: capital-labor complementarity in manufacturing.
- **What didn't:** GFCF services sector (G-Q) not available for this dataset; had to skip. Python 3.9 still blocks review/timing scripts.
- **Key finding:** 2.3% GFCF increase per pp of Fornero bite, concentrated in manufacturing (6.5%). Youth displacement of 0.59pp per pp of bite. Clean placebo at 2006.
