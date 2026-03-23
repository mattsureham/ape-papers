## Discovery
- **Idea selected:** idea_0286 — El Salvador gang removal, originally proposed nightlights + 2022 crackdown
- **Data source:** Carcach (2025, PLOS ONE) supplementary data — municipality-level homicide rates and gang detentions. ACLED API was unreachable (DNS failure), VIIRS nightlights failed (HDF5 reading issues in blackmarbler/terra, LAADS DAAC returned HTML instead of data)
- **Key risk:** Pre-trends in early years (2009-2014) suggest differential trajectories during violence escalation

## Execution
- **What worked:** The Carcach data provided a clean panel with real administrative records. The continuous intensity DiD with gang detentions as treatment and homicides as outcome produced robust results (β = -0.098, p < 0.001). Joint pre-trend F-test passed (p = 0.119).
- **What didn't:** VIIRS data was completely inaccessible — blackmarbler can't read its own HDF5 downloads on this machine (terra::rast() fails), LAADS DAAC API returns WAF-blocked HTML, EOG requires OAuth, ACLED API hostname doesn't resolve. Major pivot from the original idea was necessary.
- **Review feedback adopted:** Added formal pre-trend F-test (p = 0.119), expanded threats to validity section to address treatment endogeneity (detention rates may reflect police capacity), added explicit limitations section addressing mechanism ambiguity, data cutoff before 2022, and inability to measure economic effects.
