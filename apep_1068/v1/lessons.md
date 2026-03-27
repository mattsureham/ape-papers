## Discovery
- **Idea selected:** idea_2025 — Three-decade linked census panel (MLP) for individual-level Great Migration resilience test. Picked for rich data, strong IV potential, first-order historical stakes.
- **Data source:** Azure MLP panels (derived/mlp_panel/linked_1920_1930_1940.parquet) — 34.7M rows, streamed via DuckDB. Azure connection string requires direct .env parsing in R (shell truncates at semicolons).
- **Key risk:** Instrument exclusion restriction. Geographic distance to Northern cities affects stayer outcomes too.

## Execution
- **What worked:** Shift-share IV with pre-1910 distance × 1910 Black population. First-stage F=152. Leave-one-out IV extremely stable (2.97-3.30). OLS→IV sign reversal tells a compelling selection story.
- **What didn't:** (1) State FE kill the instrument (F=0.3) — instrument varies primarily across states, not within. (2) Stayer placebo fails (0.197***) — proximity spillovers contaminate the exclusion restriction. (3) No literacy variable in the derived MLP panel — had to use school attendance instead.
- **Review feedback adopted:** Added stayer placebo test (transparently), boom-gain control in second stage (5.23***), softened exclusion restriction claims, added caveats about upper-bound interpretation.
