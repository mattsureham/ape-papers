## Discovery
- **Idea selected:** idea_0640 — WWI draft lottery as structural transformation accelerator. Chosen for first-order development economics question, massive linked census data (43.9M MLP panel), and novel angle (no prior paper uses WWI draft for structural transformation).
- **Data source:** IPUMS MLP linked panel on Azure (4.0 GB). Azure DuckDB access worked well after fixing connection string handling.
- **Key risk:** Age-based RD confounded by life-cycle occupational trajectories. Pivoted to nativity-based DiD as primary identification.

## Execution
- **What worked:** Nativity DiD produced clean, large estimates (1.6pp farm exit, 5.35 occ score points = 0.43 SD). Heterogeneity pattern (high-ag counties, Black men) strongly supports mechanism. Azure DuckDB integration for large historical data was smooth.
- **What didn't:** Age-based RD failed due to discrete running variable (mass points killed rdrobust) and mechanical age-outcome relationship. Placebo cutoffs were significant, confirming age trend contamination. The rdrobust call on full 6M+ sample was also too slow with clustering.
- **Review feedback adopted:** Clarified ITT vs LATE interpretation, added declarant alien contamination discussion, added MLP linking bias limitation, softened "permanently accelerated" claim. Consistency checker caught wrong control mean (8.3% → 5.7%) and imprecise heterogeneity framing (interaction term vs level effect).
