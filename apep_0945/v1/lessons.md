## Discovery
- **Idea selected:** idea_0473 — EO 13771 two-for-one regulatory budget, clean on/off natural experiment with continuous treatment intensity
- **Data source:** Regulations.gov API v4 — fetched 37K NPRMs + 58K Final Rules + docket metadata. API works well, 1000 req/hr with key, ~25 min total fetch time
- **Key risk:** Only 23 agencies with meaningful rulemaking, limiting cluster count for inference

## Execution
- **What worked:** API data is comprehensive and well-structured. The monthly panel construction is straightforward. The binary treatment specification (Q4 vs Q1) produced cleaner results than continuous treatment.
- **What didn't:** The "ratchet" hypothesis didn't hold — rescission largely reversed the EO's composition effects. Had to pivot from "ratchet" framing to "composition shift" framing after seeing results. Duration analysis was essentially null.
- **Review feedback adopted:** Added discussion of EO 13771 designation field as a direct mechanism test (not yet run — flagged for future revision). Added limitations paragraph about alternative explanations for post-rescission decline (re-regulation crowding out). Tempered "capacity destruction" language per reviewer concerns.
- **Key lesson:** With only 23 clusters, continuous-treatment DiD produces very noisy estimates. The binary Q4-vs-Q1 comparison was both more powerful and more interpretable. For future regulation/agency papers, consider working at the docket level rather than agency level.
