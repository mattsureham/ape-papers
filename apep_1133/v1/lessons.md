## Discovery
- **Idea selected:** idea_0687 — MSHA's unique triple-tenure data (total/mine/job experience) enables a novel decomposition of firm-specific human capital and safety
- **Data source:** MSHA Open Government Data (5 bulk downloads) — fully public, no API keys needed, clean pipe-delimited files
- **Key risk:** Selection bias in individual-level regressions (workers who stay at mines longer differ on unobservables)

## Execution
- **What worked:** The triple-decomposition is genuinely novel — no other regulatory dataset has individual tenure at three levels. The 222K observation sample is large and well-documented. The quadratic tenure specification revealed an interesting nonlinear pattern.
- **What didn't:** The mine-level panel regressor (new-arrival share among injured workers) is endogenous — it's constructed from outcomes, not the workforce at risk. This was correctly identified by all three reviewers and required substantial reframing from causal to descriptive.
- **Review feedback adopted:** Reframed mine-level results as descriptive; acknowledged FEs are additive not interacted; added multiple mechanisms for the experience paradox; softened policy claims; pointed to IV strategy for future work.

## Key Takeaway
When your key regressor can only be constructed from the selected sample (injured workers), the endogeneity is fundamental. Future versions should pursue the inspection-induced turnover IV or obtain workforce-level tenure data.
