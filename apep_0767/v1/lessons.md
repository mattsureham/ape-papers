## Discovery
- **Idea selected:** idea_1748 — SNAP simplified reporting and labor market fluidity via QWI
- **Data source:** USDA ERS SNAP Policy Database (clean, well-documented) + Census QWI API
- **Key risk:** All 51 states eventually adopted, so no never-treated; reliance on not-yet-treated controls

## Execution
- **What worked:** QWI API fast once FIPS codes enumerated (Census doesn't support state:* wildcard). fixest + Sun-Abraham provided clean, consistent estimates.
- **What didn't:** `did` R package failed with collinearity errors on this data structure (too many small cohort groups from quarterly treatment timing). Had to switch to fixest.
- **Review feedback adopted:** Fixed Table 1 inconsistency (raw API TurnOvrS ≠ computed turnover). Added MDE calculation to Discussion section to formalize the "precisely estimated null" claim.
- **Key takeaway:** Null result is informative — SNAP administrative burden affects participation but not labor market fluidity. The flat education gradient is the strongest evidence.
