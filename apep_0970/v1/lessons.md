## Discovery
- **Idea selected:** idea_1538 — UI duration cuts × education gradient in QWI
- **Data source:** QWI sex×education panel from Azure Blob Storage; 60M raw rows aggregated to 8,850 state-edu-quarter obs in DuckDB SQL
- **Key risk:** Few treated clusters (7 states), all Southern/Midwest — regional confounders

## Execution
- **What worked:** DuckDB SQL pushdown for Azure aggregation avoided R memory exhaustion on 60M rows. Callaway-Sant'Anna gave clean pre-trends. The education gradient was monotonic and the TWFE triple-diff BA+ interaction was highly significant (p=0.003).
- **What didn't:** First idea (Japan overtime, idea_1030) was already claimed. Second idea (UK alcohol licensing, idea_1027) was already published as apep_0780. Third idea (Gainful Employment, idea_1479) overlapped with apep_0791. Took 3 tries to find an unclaimed, unpublished idea. Azure connectivity required `SET` approach (not `CREATE SECRET`) and `read_parquet()` wrapper.
- **Review feedback adopted:** Softened title and causal language; added measurement caveats for QWI hire rate ≠ job-finding from unemployment; acknowledged new-hire earnings decline; added limitations paragraph on regional clustering and few-cluster inference; excluded territories from sample description.
