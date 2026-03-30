## Discovery
- **Idea selected:** idea_0227 — El Salvador's 2022 state of exception. Pivoted to 2012 gang truce due to nightlight data access failures.
- **Data source:** PLOS ONE supplementary files (DOI: 10.1371/journal.pone.0330215) — municipality-level homicides 2002-2021 and gang detention data 2011-2018. Downloaded cleanly.
- **Key risk:** Pre-existing differential trends between high-gang and low-gang municipalities.

## Execution
- **What worked:** PLOS ONE data was clean and ready-to-use. The continuous DiD design produced a clear, informative event study. The on-off design (truce start + collapse) was a compelling identification strategy on paper.
- **What didn't:** (1) NASA VIIRS nightlights: bearer token expired, BlackMarbleR couldn't read HDF5 files even though GDAL has HDF5 support (files were HTML error pages), EOG requires auth, GEE requires auth. Total nightlights dead-end forced a pivot from economic outcomes to homicide outcomes. (2) ACLED API unreachable (DNS failure). (3) The identification strategy failed: department × year FE eliminated the effect, revealing that the TWFE result was driven by cross-department trends, not within-department gang-specific dynamics.
- **Review feedback adopted:** Reframed TWFE result as "baseline" (not "preferred") and dept×year FE as the preferred specification. Both reviewers correctly identified the pre-trends issue as central.
- **Tournament lesson confirmed:** "Endogenous treatment with no real solution" is a fatal flaw (lessons_global.md). Gang intensity is correlated with department-level trends, and no specification can cleanly separate the two. The honest null result is the contribution.
