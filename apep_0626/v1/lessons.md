## Discovery
- **Idea selected:** idea_0116 — Individual-level occupational mobility after 1924 Immigration Act using IPUMS MLP linked census
- **Data source:** Azure Blob Storage (IPUMS MLP linked 1920-1930 and 1910-1920 panels, full-count 1920 census)
- **Key risk:** Continuous treatment (county-level exposure) rather than sharp discontinuity; potential confounding from industrialization trends correlated with immigrant settlement

## Execution
- **What worked:** Massive sample (10.1M workers, 3,039 counties) gives precise estimates; 1910-1920 placebo supports identification; lean model storage solved disk space constraints
- **What didn't:** 1910-1920 linked panel missing SEI variable (required query fix); fixest `etable(se="cluster")` fails when first model has no FE; modelsummary produces tinytable objects instead of character strings in newer versions
- **Main finding:** Precisely estimated null — immigration restriction did not cause native occupational upgrading (SDE = -0.006). Homeownership significantly reduced (p<0.01).
- **Review feedback adopted:** [pending reviews]

## Technical Notes
- `lean = TRUE` in feols() essential when disk < 2GB and N > 10M — model objects shrink from 100MB to 4KB
- kableExtra `label` prepends `tab:` automatically — use bare label names
- Deleting intermediate .rds files (raw data) after cleaning frees substantial disk space
