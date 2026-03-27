## Discovery
- **Idea selected:** idea_1916 — E-Verify mandates and Hispanic labor market fluidity (flows, not levels)
- **Data source:** QWI race/ethnicity × 3-digit NAICS from Azure — worked well after fixing connection string parsing
- **Key risk:** DDD comparison group contamination if E-Verify affects Hispanic workers across all industries

## Execution
- **What worked:** QWI data is ideal for flow decomposition (HirN, Sep, EmpS, HirR all available by ethnicity). The DDD design with county×quarter and ethnicity×industry×quarter FEs is very clean. Wild cluster bootstrap confirms DD inference.
- **What didn't:** The DDD returned null — not because there's no effect, but because Hispanic professional services workers are equally affected. This required reframing from "construction-specific freeze" to "ethnicity-wide verification chill."
- **Key learning:** Azure connection string has semicolons that the .env parser truncates. Must use manual parsing. Also, QWI rh panel has race×ethnicity cross, so race="A0" filter is essential to avoid 7x double-counting.
- **Review feedback adopted:** Added discussion of Great Recession confound (late adopters drive results), earnings null interpretation, event study pre-trend results in text, and SB 1070 overlap with leave-one-out evidence.

## Technical Notes
- `siunitx` S columns don't work with comma-formatted numbers or `\$` signs in non-S contexts. Use plain `r` columns for mixed-content tables.
- `adjustbox` wrapper causes `\endgroup` errors when combined with `threeparttable`. Remove `adjustbox` for tables that compile cleanly without it.
- Table placement `[H]` (from `float` package) is essential for V1 papers to keep tables inline with text references.
