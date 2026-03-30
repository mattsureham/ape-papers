## Discovery
- **Idea selected:** idea_2078 — Section 232 tariffs × QWI education panel. Chosen for its triple-diff design with built-in placebo, universe-scale admin data, and political salience.
- **Data source:** QWI (Azure), FRED steel PPI — Azure connection required debugging (shell truncates connection strings at semicolons; must unset env var before R sourcing).
- **Key risk:** Low statistical power for the DDD interaction; county×time FE absorbs the main exposure×post effect.

## Execution
- **What worked:** The DDD design cleanly identifies the education gradient. County-level separation rate shows a significant skill gradient (p=0.03 with state clustering). Event studies show clean pre-trends.
- **What didn't:** Employment and earnings effects are null — the action is in turnover, not headcount. The separation rate result is sensitive to clustering level (insignificant with county clustering).
- **Review feedback adopted:** Added pre-trend discussion, inference sensitivity discussion, and "inverted skill-hoarding" interpretation. Acknowledged magnitude is modest and result is suggestive.
