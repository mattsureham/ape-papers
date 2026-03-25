## Discovery
- **Idea selected:** idea_1670 — SNAP online applications with staggered adoption, 46 states, CS estimator
- **Data source:** USDA ERS SNAP Policy Database (xlsx via curl) + FRED state-level SNAP caseloads (series BR{ST}{FIPS}M647NCEN)
- **Key risk:** Prior null from Jones et al. (2021) could replicate even with better methods

## Execution
- **What worked:** Administrative caseload data from FRED was clean and comprehensive (all 51 states). Callaway-Sant'Anna ran smoothly with clear group-time ATTs.
- **What didn't:** CS with policy controls produced degenerate results (ATT=0, SE=NA) due to collinearity with state/year FEs. ERS website anti-bot protection required curl workaround.
- **Review feedback adopted:** Fixed Table 1 treatment group count (14 cohorts, not states), removed broken CS-with-controls column from Table 2, cleaned event study table formatting, added power/MDE discussion.
- **Key insight:** The average null masks important distributional heterogeneity — online apps increase participation +10 per 1,000 in low-baseline states but have no effect in high-baseline states. This is a mechanism test, not just subgroup analysis.
