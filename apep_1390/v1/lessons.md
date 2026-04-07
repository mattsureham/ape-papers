# Lessons: apep_1390 — The Visiting Nurse Dividend

## Discovery
- Idea_1880 (Sheppard-Towner Act / MLP linked panel) was well-specified with clear identification strategy and feasibility grade READY.
- The three-state control group (MA, CT, IL) is the design's main vulnerability — every reviewer flagged it.

## Execution
- **Azure connection string parsing** is fragile: the `azure_data.R` helper truncates values containing `=` and `;`. Workaround: read `.env` directly and parse after first `=`.
- **MLP panel schema discovery at runtime**: no `birthyr` column (derive from `1930 - age_1930`), no `urban_1930` (use `farm_1930 == 2`), no `ownershp_1950` (substitute `marst_1950`). Budget time for column exploration.
- **`scales::pvalue()` masks `fixest::pvalue()`** when ggplot2 is loaded. Always namespace-qualify fixest extractors.
- **`iplot(..., plot = FALSE)` is not supported** in fixest. Use `broom::tidy()` or manual coefficient extraction for ggplot event studies.
- **Page count enforcement**: the hook rejects review launch if main text < 25 pages. Expanding Discussion with magnitude comparisons and cross-program context is a natural way to add substance.

## Review
- All 3 reviewers converged on the same three concerns: (1) thin control group, (2) linking/selection bias, (3) mechanism identification beyond null education.
- Exhibit review caught fixest's raw variable names (`I(I(age_1950^2))`) — generate clean labels in R rather than relying on fixest defaults.
- Prose review was light; main text quality was acceptable on first pass.
- Consistency checker caught overclaim language ("I overturn it") and a numeric mismatch (quarter-year vs half-year education threshold).

## Summary
A solid V1 exploiting historical policy variation with linked census microdata. The DDD design is credible but inherently limited by having only 3 control states. The health-productivity channel (positive wages, null education) is the paper's distinctive contribution. Future revision should pursue permutation inference, inverse probability weighting for linking bias, and direct health proxies (disability, weeks worked) to strengthen the mechanism claim.
