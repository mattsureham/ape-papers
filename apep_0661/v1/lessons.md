## Discovery
- **Idea selected:** idea_0609 — UK asylum dispersal and crime, shift-share IV using Census vacancy
- **Data source:** Home Office Asy_D11 (asylum by LA), Home Office PRC (crime by CSP), NOMIS Census 2011, ONS population
- **Key risk:** Instrument weakness — 2011 vacancy may not predict modern dispersal patterns

## Execution
- **What worked:** Large panel (291 CSPs × 35 quarters = 10,150 obs), comprehensive crime decomposition, honest null result with multiple diagnostic tests
- **What didn't:** Shift-share IV fundamentally weak (F=1.2). The vacancy-dispersal link has been severed by hotel/contingency accommodation expansion post-2019. Placebo tests (leads) failed, revealing confounding in OLS.
- **Data challenges:** Home Office asylum URL changed (dec-2023 → dec-2025). ONS crime data in ODS format required `readODS`. CSP-LA name matching required manual fixes for ~10 combined/renamed CSPs.
- **Key finding:** Pre-COVID OLS is positive, post-COVID is strongly negative — sign reversal undermines causal interpretation. The paper honestly reports a null.
- **Review feedback adopted:** Gemini's key insight — reframed "null effect" as "inability to identify" throughout (weak IV ≠ null effect). Added power analysis, clarified CSP-level choice, deeper discussion of placebo mechanisms (reverse placement selection). All three reviewers flagged the same core issue: weak instruments prevent causal claims.
