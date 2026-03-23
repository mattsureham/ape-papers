## Discovery
- **Idea selected:** idea_0798 — "Legislating at Midnight" — chosen from random draw of 10 for vivid question, large sample, and accessible data source
- **Data source:** GovTrack API v2 — no API key required, reliable bulk access to 13,330 enacted public laws across 26 Congresses
- **Key risk:** Selection — bills enacted late in session differ systematically from those passed earlier; lifecycle effects explain ~33% of the raw gap

## Execution
- **What worked:** The pivot from "legislative quality" (hard to measure) to "procedural form" (roll-call votes, conference committees) made the paper feasible. Process indicators are directly observable from the API data. The placebo tests (mid-session cutoff, naming bills) came out perfectly clean.
- **What didn't:** Original plan assumed Congress.gov API access (needs API key I didn't have). Pivoted to GovTrack API which worked well. Also, tracking subsequent amendments/corrections proved infeasible with available data — future work.
- **Review feedback adopted:** All three reviewers flagged overclaiming on causality. Softened language from "degrades" to "associated with," added richer controls (deliberation days, major actions), honest about 33% attenuation. GPT-5.4 caught a voice-only inconsistency (raw vs. regression direction) that needed explaining.
- **Key takeaway:** Honesty about attenuation with controls makes the paper more credible, not less. A 7pp controlled estimate is a stronger finding than a 10.5pp headline with unaddressed selection concerns.
