## Discovery
- **Idea selected:** idea_0604 — Bankruptcy judge leniency IV for entrepreneurship. Selected for gold-standard judge-IV design, clean random assignment, and novel outcome (post-discharge business formation).
- **Data source:** CourtListener RECAP API (7,980 Ch13 cases, 10 courts) + Census BDS (state-year establishment dynamics). Census BFS has NO state-level data via API — only national. BDS was the right fallback.
- **Key risk:** Aggregation from individual cases to court-year panel reduces power. State-level outcome matching is imprecise for states with multiple districts.

## Execution
- **What worked:** CourtListener API reliable and well-structured. Judge variation visible (94 judges, confirmation rates 0–100%). Case duration as proxy for confirmation is defensible (70.8% confirmed at 730-day threshold). Balance tests pass cleanly.
- **What didn't:** First stage is weak (F≈1 with court clustering) because 10 court clusters absorb most variation. The idea manifest claimed F>100, but that's for individual-level judge IV — at the aggregate panel level with only 10 clusters, power evaporates. The null result is honest but limits the paper's impact.
- **Review feedback adopted:** All three reviewers flagged weak first stage (F=1.1), state-level aggregation attenuation, and noisy confirmation proxy. Added power analysis section discussing minimum detectable effects, timing caveat about measuring outcomes during repayment period, and explicit acknowledgment that the null is "no aggregate effect" not "no individual effect." The core design limitations (state vs county, proxy vs real outcomes) are acknowledged as future work — would require SOS registry matching for a V2.
