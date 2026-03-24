## Discovery
- **Idea selected:** idea_0676 — eNLC nursing compact; massive QWI data in Azure, staggered DiD with 25+ treated states
- **Data source:** Census QWI from Azure Blob (derived/qwi/sa/n3 and se/n3); worked after fixing DuckDB Azure connection string quoting (use `CREATE SECRET` with params, not `SET`)
- **Key risk:** COVID shock in post-treatment window; state-level confounders

## Execution
- **What worked:** Triple-DiD design was the decisive diagnostic — revealed that naive DiD was capturing state-level trends, not eNLC-specific effects
- **What didn't:** QWI "44-45" and "72" are sector codes, not 3-digit NAICS; had to use individual 3-digit codes (441-449, 721-722) for placebo sectors
- **Review feedback adopted:** (1) Recentered triple-DiD as primary specification per all 3 reviewers; (2) softened "precisely estimated zero" language per GPT-5.4; (3) noted old NLC→eNLC transition; (4) toned down training pipeline speculation. Not adopted: border county analysis, IPEDS data, event study plots (would exceed V1 scope)
- **Key insight:** The placebo failure (retail shows same employment gain as healthcare) transformed a positive finding into a well-powered null with a stabilization mechanism story. This is exactly the kind of honest reporting the tournament rewards.
