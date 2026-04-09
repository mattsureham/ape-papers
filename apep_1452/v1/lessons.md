## Discovery
- **Idea selected:** idea_2533 — Belgium's automatic wage indexation during the 2022-2023 energy crisis, exploiting cross-sector timing variation from pre-committed collective agreements
- **Data source:** Eurostat LFS (lfsq_egan2) + Statbel quarterly wage index — both open, API worked smoothly
- **Key risk:** Only 19 NACE sections for clustering; energy intensity confounding

## Execution
- **What worked:** The institutional variation is genuine and clean — pre-committed timing rules create as-good-as-random cross-sector variation. The continuous treatment design provided more power than binary specifications. Data fetch was straightforward (Eurostat JSON API, Statbel XLS download).
- **What didn't:** Hours worked data came back empty from Eurostat. Had to iterate on SDE computation (continuous treatment requires β × SD(X)/SD(Y), not just β/SD(Y)). The validator flagged "times" in SDE notes as broken LaTeX (false positive from regex matching "at different times" inside a math span).
- **Review feedback adopted:** Added explicit regime-to-sector mapping table, expanded threats-to-validity on energy intensity confounding, acknowledged clustering limitations more explicitly, added discussion of transitory nature of timing effect vs. permanent policy change.
