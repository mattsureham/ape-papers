## Discovery
- **Idea selected:** idea_0076 — Sweden's 2007 RUT household services tax deduction. Chose for vivid question (can you buy your way out of the shadow economy?), confirmed open-access API data (SCB), and novel design (National Audit Office said causation unanswerable).
- **Data source:** SCB PxWeb API — all open-access, no key needed. Income data (SamForvInk1, 1999-2024), employment by sector (RAMS NattSNI07KonK, 2008-2018), employment rates by origin (RAMSForvInt04, 2004-2018).
- **Key risk:** Pre-reform income convergence pattern threatens parallel trends assumption.

## Execution
- **What worked:** SCB API is excellent — well-structured JSON-stat2 format, comprehensive municipality-level coverage. Continuous-treatment DiD across 290 municipalities gives good statistical power. Fisher randomization inference (999 permutations) provides clean non-parametric confirmation. Sector decomposition (M+N vs manufacturing placebo) is the paper's strongest evidence.
- **What didn't:** Using mean income as both treatment intensity and outcome creates endogeneity concerns flagged by all reviewers. The SNI2002→SNI2007 classification break at 2008 prevents pre-reform employment event studies. Immigration and gender mechanism tests lack power at municipality level.
- **Review feedback adopted:** Toned down causal claims from "first causal evidence" to "new quasi-experimental evidence". Fixed Table 4 duplicate coefficient bug. Added fiscal cost back-of-envelope. Strengthened limitations discussion. Did NOT restructure to make employment the headline (too large for V1 — valid suggestion for V2).
- **JSON-stat2 parsing lesson:** The value array uses C-order (last dimension varies fastest), but R's expand.grid uses F-order (first varies fastest). Must reverse dimension order for correct alignment.
