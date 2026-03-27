## Discovery
- **Idea selected:** idea_1607 — Picture bride system and Japanese immigrant economic mobility using IPUMS full-count census + MLP panel
- **Data source:** IPUMS full-count census (1900-1930) from Azure Blob Storage — flawless access once Azure connection string issue was resolved (shell truncated at semicolons)
- **Key risk:** Parallel trends between Japanese and Chinese men may not hold perfectly due to different immigration histories

## Execution
- **What worked:** The first stage is massive and clean (19.5 pp spouse-present increase, pre-trend = -0.006). Farm ownership result is significant (+1.4 pp). MLP panel linking confirmed the null on OCCSCORE within-person.
- **What didn't:** OCCSCORE pre-trend (1900→1910) is significant at -2.07, reflecting compositional changes from mass Japanese immigration. This weakens the causal claim on OCCSCORE. Also, the heterogeneity regressions on sub-samples (ALI states only) had collinearity issues due to single-state treatment variation.
- **Review feedback adopted:** All three reviewers flagged the OCCSCORE pre-trend as a significant weakness. Adopted: (1) Reframed OCCSCORE estimates as "suggestive rather than causal" with explicit pre-trend acknowledgment, (2) Added clear estimand definition paragraph explaining the reduced-form nature of the cross-race DiD, (3) Added discussion of 1924 Immigration Act as contemporaneous confound, (4) Noted farm ownership estimates are more credible (less compromised pre-trend). Deferred to V2: within-Japanese variation (marriage cohort IV), alternative outcome measures (INCWAGE, property value), children's outcomes.
