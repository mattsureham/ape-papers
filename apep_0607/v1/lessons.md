## Discovery
- **Idea selected:** idea_0090 — Brazil's 2012 Forest Code amnesty and agricultural expansion. Chosen for vivid hook (amnesty of 21M hectares), first-order stakes (climate, agriculture), and clean continuous-treatment DiD design.
- **Data source:** IBGE SIDRA API (free, no key) for agricultural outcomes; MapBiomas Collection 9 (Google Cloud Storage) for land cover and treatment construction.
- **Key risk:** Pre-trends in soybean area (convergence across municipalities) complicate causal interpretation for crop outcomes; cattle result has clean placebo.

## Execution
- **What worked:** IBGE SIDRA API was reliable with batched requests (50k row limit requires year-group batching). MapBiomas data from Google Cloud Storage was the correct source (original URLs from the website returned 404s). The treatment variable (farming share 2008) mapped cleanly across data sources using 6-digit municipality codes.
- **What didn't:** Initial MapBiomas download URLs all failed (404). Needed to find the Google Cloud Storage URL via the Dataverse page. The soybean area pre-trends complicate the headline crop result, making the paper lean more heavily on the cattle and moral hazard findings.
- **Review feedback adopted:** All three reviewers flagged the treatment variable (farming share vs. amnesty windfall) and soy pre-trends. Adopted: (1) revised abstract to use IQR-scaled 4.3% effect instead of raw 11.3%, (2) added explicit caveats about soy pre-trends and mixed crop evidence, (3) added paragraph on forest loss as alternative treatment, (4) added caveat about cross-sectional moral hazard limitations. Deferred to V2: reconstructing treatment as amnesty windfall, spatial RDD at biome boundary, Conley SEs, welfare cost-benefit table.
