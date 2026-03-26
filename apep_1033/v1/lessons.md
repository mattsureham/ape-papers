## Discovery
- **Idea selected:** idea_1659 — Raw milk legalization and foodborne outbreaks; resolves a cross-sectional vs. panel dispute in the public health literature
- **Data source:** CDC NORS (Socrata API) — clean, 66K records, well-documented fields
- **Key risk:** Sparse outcome data (267 outbreaks, 85% zeros) limits statistical power

## Execution
- **What worked:** The "pasteurization illusion" framing — naming the gap between cross-sectional OR (3.87) and within-state estimate (1.40) — gives the paper a tournament-ready hook. Built-in placebo (pasteurized dairy) is a clean null. Treatment coding from 4 published sources is well-documented.
- **What didn't:** Statistical power is the main limitation. With mean 0.19 outbreaks/state-year, the MDE is ~150%, so we can reject the cross-sectional OR but cannot distinguish modest from null effects. The non-dairy placebo (β=0.21, p=0.14) raises surveillance bias concerns.
- **Review feedback adopted:** Added power discussion with MDE estimate, addressed pre-trend noise in event study, computed triple-difference (0.34 - 0.21 = 0.13) to isolate raw-milk-specific effect from surveillance trend, clarified 30+ states vs 15 identifying states.
- **First idea abandoned:** idea_1735 (SNAP retailers + CDC PLACES) failed due to CDC PLACES having only 5 annual releases — physically impossible to meet n_pre≥5 for DiD. Always check panel length before claiming.
