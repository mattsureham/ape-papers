## Discovery
- **Idea selected:** idea_0782 — QWI race-by-industry data on tipped MW reform, specifically highlighted in tournament lessons as winning data source
- **Data source:** Census QWI LEHD via Azure Blob Storage — Azure DuckDB `az://` path failed (SSL issue with DuckDB 1.4.4), pivoted to Python Azure SDK download
- **Key risk:** Only 3 reform states (AZ, DC, MI) with different timing; mechanism ambiguity between tipping-specific and general MW channels

## Execution
- **What worked:** The DD design in food services is clean — significant B-W convergence (+1.5pp), strong Hispanic convergence (+4.1pp), clear event study with parallel pre-trends. Placebo industries (healthcare, professional services) produce nulls. The named mechanism ("tipping penalty") gives the paper a strong hook.
- **What didn't:** The DDD reveals that the convergence operates through the general MW channel, not food-services-specific tipping. This is an honest finding but undermines the pure "tipping penalty" narrative. Had to reframe as "the tip credit keeps the floor low" rather than "tips transmit discrimination." Also, Hispanic employment decline creates compositional bias concerns that QWI can't resolve without matched employer-employee data.
- **Review feedback adopted:** Strengthened mechanism discussion (general MW vs tipping), added compositional bias caveats, cited Conley-Taber on inference with few clusters, reframed Discussion to be explicit about the wage floor interpretation.
